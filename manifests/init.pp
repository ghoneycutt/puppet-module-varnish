# == Class: varnish
#
# $listen_address
#   Blank address means all IPv4 and IPv6 interfaces, otherwise specify
#   a host name, an IPv4 dotted quad, or an IPv6 address in brackets.
#
# $manage_default_vcl
#   true by default. This gives you a very minimal working config. You will
#   likely change set to false and provide your own template.
#
#  $varnishd_params
#    extra params to pass daemon - if defined, must be array
#
#  $storage_size - notes on validation
#    /(\d+(G|T|M|k)|\d+%)/  perhaps this is cleaner though not tested
#    /^\d+((G|T|M|k)|%)$/
#    if ends in % then need to see that number is > 1 and <= 100
#
class varnish(
  $manage_default_vcl   = true,
  $vcl_path             = '/etc/varnish',
  $admin_listen_address = '127.0.0.1',
  $admin_listen_port    = '6082',
  $listen_address       = undef,
  $listen_port          = '6081',
  $min_threads          = 50,
  $max_threads          = 1000,
  $thread_timeout       = 120,
  $secret_file          = '/etc/varnish/secret',
  $storage              = 'file,${VARNISH_STORAGE_FILE},${VARNISH_STORAGE_SIZE}', #'
  $storage_size         = '1G',
  $ttl                  = '120',
  $user                 = 'varnish',
  $group                = 'varnish',
  $varnishd_params      = undef, # extra params to pass daemon - if defined, must be array
  $vcl_conf             = '/etc/varnish/default.vcl',
) {

  # validate parameters
  validate_bool($manage_default_vcl)

  validate_absolute_path($vcl_path)

  if is_ip_address($admin_listen_address) == false {
    fail('must be a valid IP address')
  }

  validate_re("${admin_listen_port}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  if $listen_address != undef {
    if is_ip_address($listen_address) == false {
      fail('must be a valid IP address or undef')
    }
  }

  validate_re("${listen_port}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  validate_re("${min_threads}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  validate_re("${max_threads}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  validate_re("${thread_timeout}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  validate_absolute_path($secret_file)

  if is_string($storage) == false {
    fail('must be a string')
  }

  if is_string($storage_size) == false {
    fail('must be a string')
  }

  validate_re("${ttl}", '^\d+$', 'did not match regex pattern for an integer') # lint:ignore:only_variable_string

  if is_string($user) == false {
    fail('must be a string')
  }

  if is_string($group) == false {
    fail('must be a string')
  }

  validate_string($varnishd_params)

  validate_absolute_path($vcl_conf)

  #
  if $::osfamily != 'RedHat' and $::lsbmajdistrelease != '6' {
    fail("Varnish supports osfamily RedHat with lsbmajdistrelease 6. Detected osfamily is <${::osfamily}> and lsbmajdistrelease is <${::lsbmajdistrelease}>.")
  }

  package { 'varnish':
    ensure => 'present',
    name   => 'varnish',
  }

  file { 'varnish_sysconfig':
    ensure  => 'file',
    path    => '/etc/sysconfig/varnish',
    content => template('varnish/sysconfig.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service['varnish'],
  }

  if $manage_default_vcl == true {
    file { $::varnish::vcl_conf:
      ensure  => 'file',
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('varnish/default.vcl.erb'),
      notify  => Exec['reload_vcl'],
    }
  }

  exec { 'reload_vcl':
    command     => 'service varnish reload',
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    refreshonly =>  true,
  }

  service { 'varnish':
    ensure => 'running',
    name   => 'varnish',
    enable => true,
  }
}
