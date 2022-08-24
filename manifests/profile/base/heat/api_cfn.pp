# Copyright 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::heat::api_cfn
#
# Heat CloudFormation API profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('heat_api_cfn_short_bootstrap_node_name', undef, undef, undef)
#
# [*certificates_specs*]
#   (Optional) The specifications to give to certmonger for the certificate(s)
#   it will create.
#   Example with hiera:
#     apache_certificates_specs:
#       httpd-internal_api:
#         hostname: <overcloud controller fqdn>
#         service_certificate: <service certificate path>
#         service_key: <service key path>
#         principal: "haproxy/<overcloud controller fqdn>"
#   Defaults to lookup('apache_certificates_specs', undef, undef, {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*heat_api_cfn_network*]
#   (Optional) The network name where the heat cfn endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('heat_api_cfn_network', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*configure_apache*]
#   (Optional) Whether apache is configured via puppet or not.
#   Defaults to lookup('configure_apache', undef, undef, true)
#
class tripleo::profile::base::heat::api_cfn (
  $bootstrap_node                = lookup('heat_api_cfn_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs            = lookup('apache_certificates_specs', undef, undef, {}),
  $enable_internal_tls           = lookup('enable_internal_tls', undef, undef, false),
  $heat_api_cfn_network          = lookup('heat_api_cfn_network', undef, undef, undef),
  $step                          = Integer(lookup('step')),
  $configure_apache              = lookup('configure_apache', undef, undef, true),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $is_bootstrap = true
  } else {
    $is_bootstrap = false
  }

  include tripleo::profile::base::heat

  if $enable_internal_tls {
    if !$heat_api_cfn_network {
      fail('heat_api_cfn_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${heat_api_cfn_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${heat_api_cfn_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  if $step >= 4 or ( $step >= 3 and $is_bootstrap ) {
    include heat::api_cfn
    include heat::healthcheck
    if $configure_apache {
      include tripleo::profile::base::apache
      class { 'heat::wsgi::apache_api_cfn':
        ssl_cert => $tls_certfile,
        ssl_key  => $tls_keyfile,
      }
    }
  }
}

