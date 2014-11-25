puppet-postgresql_replication
=============================

Setup master slave streaming replication with postgresql

Setup
-----

The postgresql_replication module uses [puppetlabs/puppetlabs-postgresql](https://github.com/puppetlabs/puppetlabs-postgresql) to install and configure postgresql. To have a basic setup use for example:

    mkdir -p puppet/modules
    git submodule add https://github.com/puppetlabs/puppetlabs-postgresql.git puppet/modules/postgresql
    git submodule add https://github.com/puppetlabs/puppetlabs-stdlib.git puppet/modules/stdlib
    git submodule add https://github.com/puppetlabs/puppetlabs-concat.git puppet/modules/concat
    git submodule add https://github.com/gujaws/puppet-postgresql_replication.git puppet/modules/postgresql_replication

Quick usage
-----------

On postgresql master:

    class { 'postgresql_replication':
      server_type          => 'master',
      replication_user     => 'replication_user',
      replication_password => 'secret_password,
      hba_allow_address    => '192.168.1.0/24',
    }

On postgresql slave(s):

    class { 'postgresql_replication':
      server_type          => 'slave',
      replication_master   => '192.168.1.1',
      replication_user     => 'replication_user',
      replication_password => 'secret_password',
    }
    
The example given assumes the master is running on 192.168.1.1 and the slave is running on some ip address within 192.168.1.0/24.

Attributes
----------

####`server_type`
`server_type` can be `master` or `slave`. There has to be one master. You can have multiple slaves.

####`replication_user`
Name of the postgresql user used for replication authentication.

Has to be set on master and slave(s) with the same value.

####`replication_password`
Password of the postgresql user used for replication authentication.

Has to be set on master and slave(s) with the same value.

####`hba_allow_address`
`address` of `pg_hba.conf` entry. Can be hostname, ip address, or network. See [manpage of `pg_hba.conf`](http://www.postgresql.org/docs/9.1/static/auth-pg-hba-conf.html) for details.

Has to be given on master.

####`replication_master`
Hostname or ip address of postgresql master.

Specify on slave(s).
