require 'spec_helper'
describe 'varnish::vcl' do
  let(:title) { 'rspec-title' }

  describe 'with defaults for all parameters' do
    it 'should fail' do
      expect { should contain_class(subject) }.to raise_error(Puppet::Error, /varnish::vcl::ensure is present but varnish::vcl::content is undef. Please specify content/)
    end
  end

  describe 'with ensure set to valid string <absent>' do
    let(:params) { { :ensure => 'absent' } }
    it { should contain_class('varnish') }
    it { should compile.with_all_deps }

    it do
      should contain_file('/etc/varnish/rspec-title').with({
        'ensure'  => 'absent',
        'content' => nil,
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0644',
      })
    end
  end

  describe 'with content set to valid string <testing>' do
    content = { :content => 'testing' }
    let(:params) { content }

    it do
      should contain_file('/etc/varnish/rspec-title').with({
        'ensure'  => 'present',
        'content' => 'testing',
      })
    end

    context 'when vcl_path set to valid string </opt/varnish/etc>' do
      let(:params) { content.merge({ :vcl_path => '/opt/varnish/etc' }) }
      it { should contain_file('/opt/varnish/etc/rspec-title') }
    end

    context 'when owner set to valid string <varnish>' do
      let(:params) { content.merge({ :owner => 'varnish' }) }
      it { should contain_file('/etc/varnish/rspec-title').with_owner('varnish') }
    end

    context 'when group set to valid string <varnish>' do
      let(:params) { content.merge({ :group => 'varnish' }) }
      it { should contain_file('/etc/varnish/rspec-title').with_group('varnish') }
    end

    context 'when mode set to valid string <242>' do
      let(:params) { content.merge({ :mode => '242' }) }
      it { should contain_file('/etc/varnish/rspec-title').with_mode('242') }
    end
  end
end
