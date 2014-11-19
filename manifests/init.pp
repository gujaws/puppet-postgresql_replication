class postgresql_replication (
  $server_type          = undef,
  $replication_master   = undef,
  $replication_user     = undef,
  $replication_password = undef,
  $hba_allow_address    = undef,
) inherits role {
  validate_re($server_type, '^(master|slave)$', "${server_type} is not supported for server_type. Allowed values are 'master' and 'slave'.")
  validate_string($replication_user)
  validate_string($replication_password)

  if $server_type == 'master' {
    validate_string($hba_allow_address)
  } else {
    validate_string($replication_master)
  }

  File {
    mode   => 0600,
  }

  if $server_type == 'master' {
    class { 'postgresql::server':
      listen_addresses => '*',
      ipv4acls         => [
        "host replication ${replication_user} ${hba_allow_address} md5",
        "host postgres    ${replication_user} ${hba_allow_address} md5"
      ],
    }

    $tempdir       = dirname($postgresql::server::datadir)
    $archive_path  = "${tempdir}/archive"

    postgresql::server::role { $replication_user:
      password_hash => postgresql_password($replication_user, $replication_password),
      replication   => true,
      login         => true,
    }

    postgresql::server::config_entry { 'log_line_prefix':
      value => '%t ',
    }

    postgresql::server::config_entry { 'wal_level':
      value => 'hot_standby',
    }

    postgresql::server::config_entry { 'max_wal_senders':
      value => '5',
    }

    postgresql::server::config_entry { 'wal_keep_segments':
      value => '32',
    }

    postgresql::server::config_entry { 'archive_mode':
      value => 'on',
    }

    postgresql::server::config_entry { 'archive_command':
      value => "test -f %p && cp %p ${archive_path}/%f",
    }

    Class['postgresql::server'] -> File[$archive_path]
  } else {
    # slave

    class { 'postgresql::server':
      listen_addresses => '*',
      service_ensure   => $postgresql_bootstrapping_done,
      service_enable   => $postgresql_bootstrapping_done,
    }

    $tempdir       = dirname($postgresql::server::datadir)
    $archive_path  = "${tempdir}/archive"
    $recovery_conf = "${postgresql::server::datadir}/recovery.conf"

    file { $recovery_conf:
      owner  => $postgresql::server::user,
      group  => $postgresql::server::group,
    }

    if $postgresql_bootstrapping_done == 'false' {
      file { 'postgresql_replication_setup':
        path   => '/usr/local/bin/postgresql_replication_setup.sh',
        source => 'puppet:///modules/postgresql_replication/postgresql_replication_setup.sh',
        owner  => 0,
        group  => 0,
        mode   => '0755',
      }

      exec { 'bootstrap-postgresql-slave':
        command => "/bin/su -c \"/usr/local/bin/postgresql_replication_setup.sh ${postgresql::server::user} ${postgresql::server::group} ${replication_master} ${postgresql::server::port} ${replication_user} ${replication_password} ${postgresql::server::datadir}\" ${postgresql::server::user}",
        notify  => Exec['start-postgresql-slave'],
      }

      exec { 'start-postgresql-slave':
        command     => '/sbin/service postgresql start',
        refreshonly => true,
      }

      Class['postgresql_replication::slave_config'] -> File['postgresql_replication_setup'] -> Exec['bootstrap-postgresql-slave']
    }

    Class['postgresql::server'] -> File[$archive_path] -> File[$recovery_conf]

    class { 'postgresql_replication::slave_config':
      recovery_conf        => $recovery_conf,
      archive_path         => $archive_path,
      replication_master   => $replication_master,
      replication_port     => $postgresql::server::port,
      replication_user     => $replication_user,
      replication_password => $replication_password,
    }
  }

  file { $archive_path:
    ensure => directory,
    owner  => $postgresql::server::user,
    group  => $postgresql::server::group,
  }
}
