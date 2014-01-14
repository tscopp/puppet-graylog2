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
# Copyright 2013 Your name here, unless otherwise noted.
#
include wget

class graylog::web_interface($version          = '0.20.0-preview.7',
                              $web_secret      = 'superdupersecret',
                              $rest_uri        = 'http://127.0.0.1:12900/',
                              $graylog_web_uri = 'http://127.0.0.1:80/',) {
  wget::fetch{ 'fetch graylog-web-interface':
    source      => "https://github.com/Graylog2/graylog2-web-interface/releases/download/${version}/graylog2-web-interface-${version}.tgz",
    destination => '/tmp/graylog2-web-interface.tgz',
    notify      => Exec['expand_graylog2_web'],
    timeout     => 0,
    verbose     => true,
  }
  exec{'expand_graylog2_web':
    command     => 'tar xvzf /tmp/graylog2-web-interface.tgz -C /tmp/',
    path        => '/usr/local/bin/:/bin/',
    refreshonly => true,
    notify      => Exec['mv_graylog2_web'],
    creates     => "/tmp/graylog2-web-interface-${version}",
  }
  exec{'mv_graylog2_web':
    command     => "mv /tmp/graylog2-web-interface-${version} /opt/graylog2-web/",
    path        => '/usr/local/bin/:/bin/',
    creates     => '/opt/graylog2-web',
    refreshonly => true,
    require     => Exec['expand_graylog2_web'],
  }
  package{['libgdbm-dev', 'libffi-dev', 'ruby1.9.3']:
    ensure => present,
  }
  file{'/etc/graylog2-web-interface.conf':
    content => template('graylog/graylog2-web-interface.conf.erb'),
  }
  file{'/opt/graylog2-web/conf/graylog2-web-interface.conf':
    ensure  => 'link',
    target  => '/etc/graylog2-web-interface.conf',
    require => File['/etc/graylog2-web-interface.conf'],
  }
  exec{'/opt/graylog2-web/bin/graylog2-web-interface':
    command => '/opt/graylog2-web/bin/graylog2-web-interface',
    path    => '/opt/graylog2-web/bin/:/usr/local/bin/:/bin/',
  }
}

