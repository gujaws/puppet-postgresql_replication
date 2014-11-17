class postgresql_replication::slave_config (
  $recovery_path        = undef,
  $archive_path         = undef,
  $replication_master   = undef,
  $replication_port     = undef,
  $replication_user     = undef,
  $replication_password = undef,
) {
  postgresql::server::config_entry { 'log_line_prefix':
    value => '%t ',
  }

  postgresql::server::config_entry { 'hot_standby':
    value => 'on',
  }

  postgresql::server::config_entry { 'standby_mode':
    path   => $recovery_path,
    value  => 'on',
  }

  postgresql::server::config_entry { 'primary_conninfo':
    path   => $recovery_path,
    value  => "host=${replication_master} port=${replication_port} user=${replication_user} password=${replication_password}",
  }

  postgresql::server::config_entry { 'trigger_file':
    path   => $recovery_path,
    value  => "${datadir}/trigger",
  }

  postgresql::server::config_entry { 'restore_command':
    path   => $recovery_path,
    value  => "test -f %p && cp %p ${archive_path}/%f",
  }
}
