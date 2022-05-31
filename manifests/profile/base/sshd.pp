# Copyright 2016 Red Hat, Inc.
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
# == Class: tripleo::profile::base::sshd
#
# SSH composable service for TripleO
#
# === Parameters
#
# [*options*]
#   Hash of SSHD options to set. See the puppet-ssh module documentation for
#   details.
#   Defaults to {}
#
# [*listen*]
#   List of addresses to which sshd daemon listens.
#   Defaults to []
#
# [*port*]
#   SSH port or list of ports to bind to
#   Defaults to [22]
#
# [*password_authentication*]
#   Whether or not disable password authentication
#   Defaults to 'no'

class tripleo::profile::base::sshd (
  $options                 = {},
  $listen                  = [],
  $port                    = [22],
  $password_authentication = 'no',
) {

  if $options['ListenAddress'] {
    $sshd_options_listen = {'ListenAddress' => unique(concat(any2array($options['ListenAddress']), $listen))}
  } elsif !empty($listen) {
    $sshd_options_listen = {'ListenAddress' => unique(any2array($listen))}
  } else {
    $sshd_options_listen = {}
  }

  if $options['Port'] {
    $sshd_options_port = {'Port' => unique(concat(any2array($options['Port']), $port))}
  } else {
    $sshd_options_port = {'Port' => unique(any2array($port))}
  }

  # Prevent error messages on sshd startup
  $basic_options = {
    'HostKey' => [
      '/etc/ssh/ssh_host_rsa_key',
      '/etc/ssh/ssh_host_ecdsa_key',
      '/etc/ssh/ssh_host_ed25519_key',
    ]
  }

  $password_auth_options = {
    'PasswordAuthentication' => $password_authentication
  }

  $sshd_options = merge(
    $options,
    $basic_options,
    $sshd_options_port,
    $sshd_options_listen,
    $password_auth_options,
  )

  # NB (owalsh) in puppet-ssh hiera takes precedence over the class param
  # we need to control this, so error if it's set in hiera
  if lookup('ssh::server::options', undef, undef, undef) {
    err('ssh::server::options must not be set, use tripleo::profile::base::sshd::options')
  }
  class { 'ssh':
    storeconfigs_enabled => false,
    server_options       => $sshd_options,
    # NOTE: Force disabling client configuration.
    client_options       => {},
  }
}
