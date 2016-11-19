require 'spec_helper'
describe 'varnish' do
  let(:facts) do
    {
      :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '6',
    }
  end

  context 'with defaults for all parameters' do
    it { should contain_class('varnish') }
    it { should compile.with_all_deps }
    it do
      should contain_package('varnish').with({
        'ensure' => 'present',
        'name'   => 'varnish',
      })
    end

    it do
      should contain_file('varnish_sysconfig').with({
        'ensure' => 'file',
        'path'   => '/etc/sysconfig/varnish',
        'content' => File.read(fixtures('sysconfig.default')),
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'notify' => 'Service[varnish]',
      })
    end

    content = <<-END.gsub(/^\s+\|/, '')
      |# This file is being maintained by Puppet.
      |# DO NOT EDIT
      |#
      |# This is a basic VCL configuration file for varnish.  See the vcl(7)
      |# man page for details on VCL syntax and semantics.
      |#
      |# Default backend definition.  Set this to point to your content
      |# server.
      |#
      |backend default {
      |  .host = "";
      |  .port = "6081";
      |}
    END
    it do
      should contain_file('/etc/varnish/default.vcl').with({
        'ensure' => 'file',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'content' => content,
        'notify' => 'Exec[reload_vcl]',
      })
    end
    it do
      should contain_exec('reload_vcl').with({
        'command'     => 'service varnish reload',
        'path'        => '/bin:/usr/bin:/sbin:/usr/sbin',
        'refreshonly' => true,
      })
    end
    it do
      should contain_service('varnish').with({
        'ensure' => 'running',
        'name'   => 'varnish',
        'enable' => true,
      })
    end
  end

  context 'with manage_default_vcl set to valid false' do
    let(:params) { { :manage_default_vcl => false } }
    it { should_not contain_file('/etc/varnish/default.vcl') }
  end

  # vcl_path does not trigger functionality in varnish class
  context 'with vcl_path set to valid string /opt/varnish/etc' do
    let(:params) { { :vcl_path => '/opt/varnish/etc' } }
    it { should compile.with_all_deps }
  end

  context 'with admin_listen_address set to valid string 2.4.2.242' do
    let(:params) { { :admin_listen_address => '2.4.2.242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_ADMIN_LISTEN_ADDRESS=2.4.2.242$/) }
  end

  context 'with admin_listen_port set to valid string 242' do
    let(:params) { { :admin_listen_port => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_ADMIN_LISTEN_PORT=242$/) }
  end

  context 'with listen_address set to valid string 2.4.2.242' do
    let(:params) { { :listen_address => '2.4.2.242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_LISTEN_ADDRESS=2.4.2.242$/) }
  end

  context 'with listen_port set to valid string 242' do
    let(:params) { { :listen_port => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_LISTEN_PORT=242$/) }
  end

  context 'with min_threads set to valid string 242' do
    let(:params) { { :min_threads => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_MIN_THREADS=242$/) }
  end

  context 'with max_threads set to valid string 242' do
    let(:params) { { :max_threads => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_MAX_THREADS=242$/) }
  end

  context 'with thread_timeout set to valid string 242' do
    let(:params) { { :thread_timeout => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_THREAD_TIMEOUT=242$/) }
  end

  context 'with secret_file set to valid string /opt/varnish/secret' do
    let(:params) { { :secret_file => '/opt/varnish/secret' } }
    it { should contain_file('varnish_sysconfig').with_content(%r{^VARNISH_SECRET_FILE=/opt/varnish/secret$}) }
  end

  context 'with storage set to valid string malloc,100M' do
    let(:params) { { :storage => 'malloc,100M' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_STORAGE="malloc,100M"$/) }
  end

  context 'with storage_size set to valid string 242G' do
    let(:params) { { :storage_size => '242G' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_STORAGE_SIZE=242G$/) }
  end

  context 'with ttl set to valid string 242' do
    let(:params) { { :ttl => '242' } }
    it { should contain_file('varnish_sysconfig').with_content(/^VARNISH_TTL=242$/) }
  end

  context 'with user set to valid string user' do
    let(:params) { { :user => 'user' } }
    it { should contain_file('varnish_sysconfig').with_content(/^\s*-u user -g varnish \\$/) }
  end

  context 'with group set to valid string group' do
    let(:params) { { :group => 'group' } }
    it { should contain_file('varnish_sysconfig').with_content(/^\s*-u varnish -g group \\$/) }
  end

  context 'with varnishd_params set to valid array %w(param1)' do
    let(:params) { { :varnishd_params => %w(param1) } }
    it { should contain_file('varnish_sysconfig').with_content(/^\s*-p param1\"$/) }
  end

  context 'with varnishd_params set to valid array %w(param1 param2 param3)' do
    let(:params) { { :varnishd_params => %w(param1 param2 param3) } }
    it { should contain_file('varnish_sysconfig').with_content(/^\s*-p param1 -p param2 -p param3\"$/) }
  end

  context 'with vcl_conf set to valid string /opt/varnish/etc/default.vcl' do
    let(:params) { { :vcl_conf => '/opt/varnish/etc/default.vcl' } }
    it { should contain_file('/opt/varnish/etc/default.vcl') }
    it { should contain_file('varnish_sysconfig').with_content(%r{^VARNISH_VCL_CONF=/opt/varnish/etc/default.vcl$}) }
  end

  context 'when ith vcl_conf set to valid string /opt/varnish/etc/default.vcl' do
    let(:params) { { :vcl_conf => '/opt/varnish/etc/default.vcl' } }
    it { should contain_file('/opt/varnish/etc/default.vcl') }
    it { should contain_file('varnish_sysconfig').with_content(%r{^VARNISH_VCL_CONF=/opt/varnish/etc/default.vcl$}) }
  end

  context 'with default params on unsupported OS family C64' do
    let(:facts) { { :osfamily => 'C64', :lsbmajdistrelease => nil } }
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /Varnish supports osfamily RedHat with lsbmajdistrelease 6/)
    end
  end

  describe 'variable type and content validations' do
    validations = {
      'absolute_path' => {
        :name    => %w(secret_file vcl_conf vcl_path),
        :valid   => %w(/absolute/filepath /absolute/directory/),
        :invalid => ['invalid', %w(array), { 'ha' => 'sh' }, 3, 2.42],
        :message => 'is not an absolute path',
      },
      'array' => {
        :name    => %w(varnishd_params),
        :valid   => [%w(array)],
        :invalid => ['string', { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => 'is not an Array',
      },
      'boolean' => {
        :name    => %w(manage_default_vcl),
        :valid   => [true, false],
        :invalid => ['string', %w(array), { 'ha' => 'sh' }, 3, 2.42, nil],
        :message => 'is not a boolean',
      },
      'integer_including_zero' => {
        :name    => %w(ttl),
        :valid   => [80, '80', 0],
        :invalid => [-1, 'foo', %w(array), { 'ha' => 'sh' }, true],
        :message => 'must be a positive integer or zero',
      },
      'integer_nonzero' => {
        :name    => %w(max_threads min_threads thread_timeout),
        :valid   => [80, '80'],
        :invalid => [0, -1, 'foo', %w(array), { 'ha' => 'sh' }, true],
        :message => 'must be a non-zero integer',
      },
      'ip_address_required' => {
        :name    => %w(admin_listen_address),
        :valid   => %w(127.0.0.1),
        # /!\ removed fixnum from invalid as Ruby 1.8.7 does accept them as valid IP addresses
        :invalid => ['string', '0.0.0', '0.0.0.0.0', '127.0.0.257', %w(array), { 'ha' => 'sh' }, 2.42, nil],
        :message => 'must be a valid IP address',
      },
      'ip_address_optional' => {
        :name    => %w(listen_address),
        :valid   => %w(127.0.0.1),
        # /!\ removed fixnum from invalid as Ruby 1.8.7 does accept them as valid IP addresses
        :invalid => ['string', '0.0.0', '0.0.0.0.0', '127.0.0.257', %w(array), { 'ha' => 'sh' }, 2.42],
        :message => 'must be a valid IP address or undef',
      },
      'server_port' => {
        :name    => %w(admin_listen_port listen_port),
        :valid   => [80, '80'],
        :invalid => [0, -1, 'foo', %w(array), { 'ha' => 'sh' }, true],
        :message => 'is not a valid server port',
      },
      'storage_types' => {
        :name    => %w(storage),
        :valid   => %w(file malloc),
        :invalid => ['string', [], { 'ha' => 'sh' }, 3, 2.42, true, false],
        :message => 'must be either file or malloc',
      },
      'string' => {
        :name    => %w(group user),
        :valid   => %w(string),
        :invalid => [[], { 'ha' => 'sh' }, 3, 2.42, true, false],
        :message => 'must be a string',
      },
      'string/integer' => {
        :name    => %w(storage_size),
        :valid   => ['1M', '1024', 1024],
        :invalid => [0, -1, [], { 'ha' => 'sh' }, 2.42, true, false],
        :message => 'must be a string or positive integer',
      },
    }

    validations.sort.each do |type, var|
      var[:name].each do |var_name|
        mandatory_params = {} if mandatory_params.nil?
        var[:params] = {} if var[:params].nil?
        var[:valid].each do |valid|
          context "when #{var_name} (#{type}) is set to valid #{valid} (as #{valid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => valid, }].reduce(:merge) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "when #{var_name} (#{type}) is set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { [mandatory_params, var[:params], { :"#{var_name}" => invalid, }].reduce(:merge) }
            it 'should fail' do
              expect { should contain_class(subject) }.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe 'variable type and content validations'
end
