# == Define: varnish::vcl
#
# Manage Varnish VCL's
#
define varnish::vcl (
  $ensure   = 'present',
  $content  = undef,
  $vcl_path = undef,
  $owner    = 'root',
  $group    = 'root',
  $mode     = '0644',
) {

  include ::varnish

  $vcl_path_real = $vcl_path ? {
    undef   => $::varnish::vcl_path,
    default => $vcl_path,
  }

  if $ensure == 'present' and $content == undef {
    fail('varnish::vcl::ensure is present but varnish::vcl::content is undef. Please specify content.')
  }

  file { "${vcl_path_real}/${name}":
    ensure  => $ensure,
    content => $content,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    notify  => Exec['reload_vcl'],
  }
}
