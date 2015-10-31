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
  end
end
