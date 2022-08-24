# Copyright 2014 Red Hat, Inc.
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
# == Class: tripleo::profile::base::neutron::server
#
# Neutron server profile for tripleo
#
# === Parameters
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to lookup('neutron_api_short_bootstrap_node_name', undef, undef, undef)
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
# [*dvr_enabled*]
#   (Optional) Is dvr enabled, used when no override is passed to
#   l3_ha_override to calculate enabling l3 HA.
#   Defaults to lookup('neutron::server::router_distributed', undef, undef, false)
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to lookup('enable_internal_tls', undef, undef, false)
#
# [*l3_ha_override*]
#   (Optional) Override the calculated value for neutron::server::l3_ha
#   by default this is calculated to enable when DVR is not enabled
#   and the number of nodes running neutron api is more than one.
#   Defaults to '' which aligns with the t-h-t default, and means use
#   the calculated value.  Other possible values are 'true' or 'false'
#
# [*l3_nodes*]
#   (Optional) List of nodes running the l3 agent, used when no override
#   is passed to l3_ha_override to calculate enabling l3 HA.
#   Defaults to lookup('neutron_l3_short_node_names', undef, undef, [])
#   (we need to default neutron_l3_short_node_names to an empty list
#   because some neutron backends disable the l3 agent)
#
# [*neutron_network*]
#   (Optional) The network name where the neutron endpoint is listening on.
#   This is set by t-h-t.
#   Defaults to lookup('neutron_api_network', undef, undef, undef)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to Integer(lookup('step'))
#
# [*tls_proxy_bind_ip*]
#   IP on which the TLS proxy will listen on. Required only if
#   enable_internal_tls is set.
#   Defaults to undef
#
# [*tls_proxy_fqdn*]
#   fqdn on which the tls proxy will listen on. required only used if
#   enable_internal_tls is set.
#   defaults to undef
#
# [*tls_proxy_port*]
#   port on which the tls proxy will listen on. Only used if
#   enable_internal_tls is set.
#   defaults to 9696
#
# [*designate_api_enabled*]
#   (Optional) Indicate whether Designate is available in the deployment.
#   Defaults to lookup('designate_api_enabled', undef, undef, false)
#
# [*configure_apache*]
#   (Optional) Whether apache is configured via puppet or not.
#   Defaults to lookup('configure_apache', undef, undef, true)
#
class tripleo::profile::base::neutron::server (
  $bootstrap_node        = lookup('neutron_api_short_bootstrap_node_name', undef, undef, undef),
  $certificates_specs    = lookup('apache_certificates_specs', undef, undef, {}),
  $dvr_enabled           = lookup('neutron::server::router_distributed', undef, undef, false),
  $enable_internal_tls   = lookup('enable_internal_tls', undef, undef, false),
  $l3_ha_override        = '',
  $l3_nodes              = lookup('neutron_l3_short_node_names', undef, undef, []),
  $neutron_network       = lookup('neutron_api_network', undef, undef, undef),
  $step                  = Integer(lookup('step')),
  $tls_proxy_bind_ip     = undef,
  $tls_proxy_fqdn        = undef,
  $tls_proxy_port        = 9696,
  $designate_api_enabled = lookup('designate_api_enabled', undef, undef, false),
  $configure_apache      = lookup('configure_apache', undef, undef, true),
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $sync_db = true
  } else {
    $sync_db = false
  }

  include tripleo::profile::base::neutron
  include tripleo::profile::base::neutron::authtoken

  if $enable_internal_tls {
    if !$neutron_network {
      fail('neutron_api_network is not set in the hieradata.')
    }
    $tls_certfile = $certificates_specs["httpd-${neutron_network}"]['service_certificate']
    $tls_keyfile = $certificates_specs["httpd-${neutron_network}"]['service_key']
  } else {
    $tls_certfile = undef
    $tls_keyfile = undef
  }

  # Calculate neutron::server::l3_ha based on the number of API nodes
  # combined with if DVR is enabled.
  if $l3_ha_override != '' {
    $l3_ha = str2bool($l3_ha_override)
  } elsif ! str2bool($dvr_enabled) {
    $l3_ha = size($l3_nodes) > 1
  } else {
    $l3_ha = false
  }

  if $step >= 4 or ($step >= 3 and $sync_db) {
    if $configure_apache {
      include tripleo::profile::base::apache
      if $enable_internal_tls {
        ::tripleo::tls_proxy { 'neutron-api':
          servername => $tls_proxy_fqdn,
          ip         => $tls_proxy_bind_ip,
          port       => $tls_proxy_port,
          tls_cert   => $tls_certfile,
          tls_key    => $tls_keyfile,
        }
        Tripleo::Tls_proxy['neutron-api'] ~> Anchor<| title == 'neutron::service::begin' |>
      } else {
        class { 'neutron::wsgi::apache':
          ssl_cert => $tls_certfile,
          ssl_key  => $tls_keyfile,
        }
      }
    }
    if $designate_api_enabled {
      include neutron::designate
    }
  }
  # We start neutron-server on the bootstrap node first, because
  # it will try to populate tables and we need to make sure this happens
  # before it starts on other nodes
  if $step >= 4 and $sync_db or $step >= 5 and !$sync_db {

    include neutron::server::notifications
    include neutron::server::notifications::nova
    include neutron::server::placement
    # We need to override the hiera value neutron::server::sync_db which is set
    # to true
    class { 'neutron::server':
      sync_db => $sync_db,
      l3_ha   => $l3_ha,
    }
    include neutron::db
    include neutron::healthcheck
    include neutron::quota
  }
}
