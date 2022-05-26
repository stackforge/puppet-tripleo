# Copyright 2017 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Unit tests for tripleo::profile::base::sshd
#

require 'spec_helper'

describe 'tripleo::profile::base::sshd' do

  shared_examples_for 'tripleo::profile::base::sshd' do

    context 'it should do nothing' do
      it do
        is_expected.to contain_class('ssh').with({
          'storeconfigs_enabled' => false,
          'server_options' => {
            'Port'    => [22],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
            'PasswordAuthentication' => 'no',
          },
          'client_options' => {},
        })
      end
    end

    context 'with port and paswword_authentification configured' do
      let(:params) {{ :port => 123, :password_authentication => 'yes' }}
      it do
        is_expected.to contain_class('ssh').with({
          'storeconfigs_enabled' => false,
          'server_options' => {
            'Port' => [123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
            'PasswordAuthentication' => 'yes',
          },
          'client_options' => {},
        })
      end
    end

    context 'with port configured and port option' do
      let(:params) {{ :port => 123, :options => {'Port' => 456}  }}
      it do
        is_expected.to contain_class('ssh').with({
          'storeconfigs_enabled' => false,
          'server_options' => {
            'Port' => [456, 123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
            'PasswordAuthentication' => 'no',
          },
          'client_options' => {},
        })
      end
    end

    context 'with port configured and same port option' do
      let(:params) {{ :port => 123, :options => {'Port' => 123}  }}
      it do
        is_expected.to contain_class('ssh').with({
          'storeconfigs_enabled' => false,
          'server_options' => {
            'Port' => [123],
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
            'PasswordAuthentication' => 'no',
          },
          'client_options' => {},
        })
      end
    end

    context 'with options configured' do
      let(:params) {{ :options => {'X11Forwarding' => 'no'} }}
      it do
        is_expected.to contain_class('ssh').with({
          'storeconfigs_enabled' => false,
          'server_options' => {
            'Port' => [22],
            'X11Forwarding' => 'no',
            'HostKey' => [
              '/etc/ssh/ssh_host_rsa_key',
              '/etc/ssh/ssh_host_ecdsa_key',
              '/etc/ssh/ssh_host_ed25519_key',
            ],
            'PasswordAuthentication' => 'no',
          },
          'client_options' => {},
        })
      end
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::sshd'
    end
  end
end
