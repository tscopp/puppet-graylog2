# == Class: graylog
#
# Full description of class graylog here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { graylog:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ]
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2013 Tim Scoppetta, unless otherwise noted.
#


class graylog::server($version         = '0.20.0-preview.7',
                      $path            = '/opt/graylog2/',
                      $is_master       = True,
                      $rest_uri        = 'http://127.0.0.1:12900/',
                      $es_cluster_name = 'graylog2',
                      $es_version      = '0.90.7',
                      $es_maxdocs      = '20000000',
                      $es_prefix       = 'graylog2',
                      $es_maxind       = '20',
                      $es_shards       = '4',
                      $es_replicas     = '0',
                      $mongo_user      = 'grayloguser',
                      $mongo_pw        = '123',
                      $mongo_host      = '127.0.0.1',
                      $mongo_db        = 'graylog2',
                      $mongo_port      = '27017',
                      )
                      {
  $pgkname = "graylog2-server-${version}"
  $url = "https://github.com/Graylog2/graylog2-server/releases/download/${version}/${pgkname}.tgz"
  $pw_secret = 'liVZUzBSUeHZ0Wt5MfyNaF0VRRdlrWdABopxrJjaQbfcLMsKMCYH279KZhJdArKqlsx2a0enGavoZndof81q'

  $graylog_preqs= ["git", "apache2", "libcurl4-openssl-dev", "apache2-prefork-dev", "libapr1-dev", "build-essential", "openssl", "libreadline6", "libreadline6-dev", "curl", "git-core", "zlib1g", "zlib1g-dev", "libssl-dev", "libyaml-dev", "libsqlite3-dev", "sqlite3", "libxml2-dev", "autoconf", "libc6-dev", "automake", "libtool", "bison", "subversion", "pkg-config", "python-software-properties", "software-properties-common", "openjdk-7-jre"]

  package{ $graylog_preqs:
    ensure => present,
  }

  # Graylog2 Stuff
  wget::fetch{ 'fetch graylog_server':
    source      => $url,
    destination => '/tmp/graylog2-server.tgz',
    timeout     => 0,
    verbose     => true,
    before      => Exec['expand_graylog2'],
  }
  wget::fetch{ 'fetch_elasticsearch':
    source      => "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-${es_version}.deb",
    destination => "/tmp/elasticsearch-${es_version}.deb",
    timeout     => 0,
    verbose     => true,
    notify      => Exec['expand_graylog2'],
    before      => Class['elasticsearch'],
  }
  exec{'expand_graylog2':
    command     => 'tar xvzf /tmp/graylog2-server.tgz -C /tmp/',
    path        => '/usr/local/bin/:/bin/',
    refreshonly => true,
    notify      => Exec['mv_graylog'],
    creates     => "/tmp/graylog2-server-${version}",
  }
  exec{'mv_graylog':
    command     => "mv /tmp/graylog2-server-${version} /opt/graylog2/",
    path        => '/usr/local/bin/:/bin/',
    creates     => '/opt/graylog2',
    refreshonly => true,
    require     => Exec['expand_graylog2'],
    }
  file{'/etc/graylog2.conf':
    content => template('graylog/graylog2.conf.erb'),
  }

  # MongoDB Stuff
  class {'mongodb':
    ulimit_nofile => '20000',
  }
  file{'/etc/mongodb.conf':
    content => template('graylog/mongodb.conf.erb'),
    notify  => Service['mongodb'],
  }
  exec{'add_graylog_user':
    command     => "mongo graylog2 --eval \"db.addUser(\'${mongo_user}\',\'${mongo_pw}\')\" ",
    path        => '/usr/local/bin/:/usr/bin/:/bin/',
    subscribe   => [File['/etc/mongodb.conf'],
                    File['/etc/graylog2.conf']],
                    #refreshonly => true,
    require     => [Class['mongodb'],
                    File['/etc/mongodb.conf']],
  }
  exec{'auth_graylog_user':
    command     => "mongo graylog2 --eval \"db.auth(\'${mongo_user}\',\'${mongo_pw}\')\" ",
    path        => '/usr/local/bin/:/usr/bin/:/bin/',
    subscribe   => [File['/etc/mongodb.conf'],
                    File['/etc/graylog2.conf']],
                    #refreshonly => true,
    require     => [Class['mongodb'],
                  File['/etc/mongodb.conf'],
                  Exec['add_graylog_user']],
  }

  class { 'elasticsearch':
    pkg_source  => "/tmp/elasticsearch-${es_version}.deb",
    config      => {
      'cluster' => {
        'name'  => $es_cluster_name,
      }
    }
  }

  file{'/etc/init/graylog2-server.conf':
    content => template('graylog/graylog2-server.conf.erb'),
    notify  => Service['graylog2-server'],
    require => [Exec['auth_graylog_user'],
                Class['elasticsearch']],
  }

  service { 'graylog2-server':
    ensure  => 'running',
    require => File['/etc/graylog2.conf'],
  }

}
