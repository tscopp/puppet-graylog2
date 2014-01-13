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

class graylog::web_interface($server_version = '0.20.0-preview.7') {
  wget::fetch{ 'fetch graylog_server':
    source      => "https://github.com/Graylog2/graylog2-web-interface/releases/download/${server_version}/graylog2-web-interface-${server_version}.tgz",
    destination => '/tmp/graylog2-web-interface.tgz',
    timeout     => 0,
    verbose     => true,
  }
}
