if Facter::Util::Resolution.which('varnishstat')
  output = Facter::Util::Resolution.exec('varnishstat -V 2>&1')
  ver = output.match(/\(varnish-(\d+\.\d+\.\d+).*\)/)[1]

  if ver
    Facter.add('varnish_version') do
      setcode do
        ver
      end
    end
  end
end
