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


class graylog::server($version     = '0.20.0-preview.7',
                      $path        = '/opt/graylog2/',
                      $is_master   = True,
                      $rest_uri    = 'http://127.0.0.1:12900/',
                      $es_maxdocs  = '20000000',
                      $es_prefix   = 'graylog2',
                      $es_maxind   = '20',
                      $es_shards   = '4',
                      $es_replicas = '0',
                      $mongo_user  = 'grayloguser',
                      $mongo_pw    = '123',
                      $mongo_host  = '127.0.0.1',
                      $mongo_db    = 'graylog2',
                      $mongo_port  = '27017',
                      )
                      {
  $pgkname = "graylog2-server-${version}"
  $url = "https://github.com/Graylog2/graylog2-server/releases/download/${version}/${pgkname}.tgz"
  $pw_secret = 'liVZUzBSUeHZ0Wt5MfyNaF0VRRdlrWdABopxrJjaQbfcLMsKMCYH279KZhJdArKqlsx2a0enGavoZndof81q'

  # Graylog2 Stuff
  wget::fetch{ 'fetch graylog_server':
    source      => $url,
    destination => '/tmp/graylog2-server.tgz',
    timeout     => 0,
    verbose     => true,
    before      => Exec['expand_graylog2'],
  }
  exec{'expand_graylog2':
    command => 'tar xvzf /tmp/graylog2-server.tgz -C /tmp/',
    path    => '/usr/local/bin/:/bin/',
    creates => "/tmp/graylog2-server-${version}",
  }
  exec{'mv_graylog':
    command   => "mv /tmp/graylog2-server-${version} /opt/graylog2/",
    path      => '/usr/local/bin/:/bin/',
    creates   => '/opt/graylog2',
    require   => Exec['expand_graylog2'],
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
    command => "mongo 127.0.0.1 --eval \'db.addUser({user:\"${mongo_user}\",pwd: \"${mongo_pw}\",roles: [ \"readWrite\", \"dbAdmin\"]})\'",
    path    => '/usr/local/bin/:/usr/bin/:/bin/',
  }


}
