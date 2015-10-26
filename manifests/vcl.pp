# == Define: varnish::vcl
#
# Manage Varnish VCL's
#
define varnish::vcl (
  $ensure   = 'present',
  $content  = undef,
  $vcl_path = $::varnish::vcl_path,
  $owner    = 'root',
  $group    = 'root',
  $mode     = '0644',
) {

  if $ensure == 'present' and $content == undef {
    fail('varnish::vcl::ensure is present but varnish::vcl::content is undef. Please specify content.')
  }

  include ::varnish

  file { "${vcl_path}/${name}":
    ensure  => $ensure,
    content => $content,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    notify  => Exec['reload_vcl'],
  }
}
