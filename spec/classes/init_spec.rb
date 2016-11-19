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
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'notify' => 'Service[varnish]',
      })
    end
    it do
      should contain_file('/etc/varnish/default.vcl').with({
        'ensure' => 'file',
        'path'   => '/etc/varnish/default.vcl',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'notify' => 'Exec[reload_vcl]',
      })
    end
    it do
      should contain_exec('reload_vcl').with_command('service varnish reload')
    end
    it do
      should contain_service('varnish').with({
        'ensure' => 'running',
        'name'   => 'varnish',
        'enable' => true,
      })
    end
  end

  describe 'variable type and content validations' do
    let(:validation_params) do
      {
      }
    end

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
        var[:valid].each do |valid|
          context "with #{var_name} (#{type}) set to valid #{valid} (as #{valid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => valid, }) }
            it { should compile }
          end
        end

        var[:invalid].each do |invalid|
          context "with #{var_name} (#{type}) set to invalid #{invalid} (as #{invalid.class})" do
            let(:params) { validation_params.merge({ :"#{var_name}" => invalid, }) }
            it 'should fail' do
              expect do
                should contain_class(subject)
              end.to raise_error(Puppet::Error, /#{var[:message]}/)
            end
          end
        end
      end # var[:name].each
    end # validations.sort.each
  end # describe
end
