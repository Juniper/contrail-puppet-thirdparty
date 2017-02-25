require 'spec_helper'

describe 'heat::api_cloudwatch' do

  let :params do
    { :enabled        => true,
      :manage_service => true,
      :bind_host      => '127.0.0.1',
      :bind_port      => '1234',
      :workers        => '0' }
  end


  shared_examples_for 'heat-api-cloudwatch' do
    let :pre_condition do
      "class { 'heat::keystone::authtoken':
           password => 'a_big_secret',
       }"
    end

    context 'config params' do

      it { is_expected.to contain_class('heat') }
      it { is_expected.to contain_class('heat::params') }
      it { is_expected.to contain_class('heat::policy') }

      it { is_expected.to contain_heat_config('heat_api_cloudwatch/bind_host').with_value( params[:bind_host] ) }
      it { is_expected.to contain_heat_config('heat_api_cloudwatch/bind_port').with_value( params[:bind_port] ) }
      it { is_expected.to contain_heat_config('heat_api_cloudwatch/workers').with_value( params[:workers] ) }

    end

    context 'with SSL socket options set' do
      let :params do
        {
          :use_ssl   => true,
          :cert_file => '/path/to/cert',
          :key_file  => '/path/to/key'
        }
      end

      it { is_expected.to contain_heat_config('heat_api_cloudwatch/cert_file').with_value('/path/to/cert') }
      it { is_expected.to contain_heat_config('heat_api_cloudwatch/key_file').with_value('/path/to/key') }
    end

    context 'with SSL socket options set with wrong parameters' do
      let :params do
        {
          :use_ssl   => true,
          :key_file  => '/path/to/key'
        }
      end

      it_raises 'a Puppet::Error', /The cert_file parameter is required when use_ssl is set to true/
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures heat-api-cloudwatch service' do

          is_expected.to contain_service('heat-api-cloudwatch').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:api_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :tag        => 'heat-service',
          )
          is_expected.to contain_service('heat-api-cloudwatch').that_subscribes_to(nil)
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures heat-api-cloudwatch service' do

        is_expected.to contain_service('heat-api-cloudwatch').with(
          :ensure     => nil,
          :name       => platform_params[:api_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :tag        => 'heat-service',
        )
        is_expected.to contain_service('heat-api-cloudwatch').that_subscribes_to(nil)
      end
    end

    context 'with $sync_db set to false in ::heat' do
      let :pre_condition do
        "class {'heat':
           keystone_password => 'password',
           sync_db => false
         }"
      end

      it 'configures heat-api-cloudwatch service to not subscribe to the dbsync resource' do
        is_expected.to contain_service('heat-api-cloudwatch').that_subscribes_to(nil)
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      @default_facts.merge({
        :osfamily => 'Debian',
      })
    end

    let :platform_params do
      { :api_service_name => 'heat-api-cloudwatch' }
    end

    it_configures 'heat-api-cloudwatch'
  end

  context 'on RedHat platforms' do
    let :facts do
      @default_facts.merge({
        :osfamily => 'RedHat',
      })
    end

    let :platform_params do
      { :api_service_name => 'openstack-heat-api-cloudwatch' }
    end

    it_configures 'heat-api-cloudwatch'
  end

end
