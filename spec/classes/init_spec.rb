require 'spec_helper'
describe 'varnish' do
  let(:facts) do
    { :osfamily                  => 'RedHat',
      :operatingsystemmajrelease => '6',
    }
  end

  context 'with defaults for all parameters' do
    it { should contain_class('varnish') }
    it { should compile.with_all_deps }
    it {
      should contain_package('varnish').with({
        'ensure' => 'present',
        'name'   => 'varnish',
      })
    }
    it {
      should contain_file('varnish_sysconfig').with({
        'ensure' => 'file',
        'path'   => '/etc/sysconfig/varnish',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'notify' => 'Service[varnish]',
      })
    }
    it {
      should contain_file('/etc/varnish/default.vcl').with({
        'ensure' => 'file',
        'path'   => '/etc/varnish/default.vcl',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0644',
        'notify' => 'Exec[reload_vcl]',
      })
    }
    it {
      should contain_exec('reload_vcl').with_command('service varnish reload')
    }
    it {
      should contain_service('varnish').with({
        'ensure' => 'running',
        'name'   => 'varnish',
        'enable' => true,
      })
    }
  end

  describe 'variable type and content validations' do
    let(:validation_params) do
      {
      }
    end

    validations = {
      'absolute_path' => {
        :name    => ['secret_file', 'vcl_conf', 'vcl_path'],
        :valid   => ['/absolute/filepath', '/absolute/directory/'],
        :invalid => ['invalid', 3, 2.42, ['array'], a={'ha'=>'sh'}],
        :message => 'is not an absolute path',
      },
      'array' => {
        :name    => ['varnishd_params'],
        :valid   => [['array']],
        :invalid => ['string', a={'ha'=>'sh'}, 3, 2.42, nil],
        :message => 'is not an Array',
      },
      'boolean' => {
        :name    => ['manage_default_vcl'],
        :valid   => [true,false],
        :invalid => ['string', ['array'], a={'ha'=>'sh'}, 3, 2.42, nil],
        :message => 'is not a boolean',
      },
      'integer_including_zero' => {
        :name    => ['ttl'],
        :valid   => [80, '80',0],
        :invalid => [-1, 'foo', ['array'], a={'ha'=>'sh'}, true],
        :message => 'must be a positive integer or zero',
      },
      'integer_nonzero' => {
        :name    => ['max_threads', 'min_threads', 'thread_timeout'],
        :valid   => [80, '80'],
        :invalid => [0,-1, 'foo', ['array'], a={'ha'=>'sh'}, true],
        :message => 'must be a non-zero integer',
      },
      'ip_address_required' => {
        :name    => ['admin_listen_address'],
        :valid   => ['127.0.0.1'],
        :invalid => ['string', '0.0.0', '0.0.0.0.0', '127.0.0.257', ['array'], a={'ha'=>'sh'}, 3, 2.42, nil],
        :message => 'must be a valid IP address',
      },
      'ip_address_optional' => {
        :name    => ['listen_address'],
        :valid   => ['127.0.0.1'],
        :invalid => ['string', '0.0.0', '0.0.0.0.0', '127.0.0.257', ['array'], a={'ha'=>'sh'}, 3, 2.42],
        :message => 'must be a valid IP address or undef',
      },
      'server_port' => {
        :name    => ['admin_listen_port', 'listen_port'],
        :valid   => [80, '80'],
        :invalid => [0,-1, 'foo',['array'], a={'ha'=>'sh'}, true],
        :message => 'is not a valid server port',
      },
      'storage_types' => {
        :name    => ['storage'],
        :valid   => ['file', 'malloc'],
        :invalid => ['string', [], {'ha'=>'sh'}, 3, 2.42, true, false],
        :message => 'storage type must be either file or malloc',
      },
      'string' => {
        :name    => ['group', 'user'],
        :valid   => ['string'],
        :invalid => [[], {'ha'=>'sh'}, 3, 2.42, true, false],
        :message => 'must be a string',
      },
      'string/integer' => {
        :name    => ['storage_size'],
        :valid   => ['1M', '1024', 1024],
        :invalid => [0, -1, [], {'ha'=>'sh'}, 2.42, true, false],
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
