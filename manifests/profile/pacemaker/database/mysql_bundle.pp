# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::pacemaker::mysql_bundle
#
# Containerized Mysql Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*mysql_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to undef
#
# [*control_port*]
#   (Optional) The bundle's pacemaker_remote control port on the host
#   Defaults to 3123
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('mysql_short_bootstrap_node_name')
#
# [*bind_address*]
#   (Optional) The address that the local mysql instance should bind to.
#   Defaults to $::hostname
#
# [*ca_file*]
#   (Optional) The path to the CA file that will be used for the TLS
#   configuration. It's only used if internal TLS is enabled.
#   Defaults to undef
#
# [*certificate_specs*]
#   (Optional) The specifications to give to certmonger for the certificate
#   it will create. Note that the certificate nickname must be 'mysql' in
#   the case of this service.
#   Example with hiera:
#     tripleo::profile::base::database::mysql::certificate_specs:
#       hostname: <overcloud controller fqdn>
#       service_certificate: <service certificate path>
#       service_key: <service key path>
#       principal: "mysql/<overcloud controller fqdn>"
#   Defaults to hiera('tripleo::profile::base::database::mysql::certificate_specs', {}).
#
# [*enable_internal_tls*]
#   (Optional) Whether TLS in the internal network is enabled or not.
#   Defaults to hiera('enable_internal_tls', false)
#
# [*gmcast_listen_addr*]
#   (Optional) This variable defines the address on which the node listens to
#   connections from other nodes in the cluster.
#   Defaults to hiera('mysql_bind_host')
#
# [*innodb_flush_log_at_trx_commit*]
#   (Optional) Disk flush behavior for MySQL under Galera.  A value of
#   '1' indicates flush to disk per transaction.   A value of '2' indicates
#   flush to disk every second, flushing all unflushed transactions in
#   one step.
#   Defaults to hiera('innodb_flush_log_at_trx_commit', '1')
#
# [*clustercheck_user*]
#   (Optional) The name of the clustercheck user.
#   Defaults to 'clustercheck'
#
# [*clustercheck_password*]
#   (Optional) The password for the clustercheck user.
#   Defaults to hiera('mysql_clustercheck_password')
#
# [*sst_method*]
#   (Optional) Method used by galera to perform State Snapshot Transfers
#   Defaults to 'rsync'
#
# [*mariabackup_user*]
#   (Optional) When sst_method is set to mariabackup, the name of the
#   mariabackup user
#   Defaults to 'mariabackup'
#
# [*mariabackup_password*]
#   (Optional) When sst_method is set to mariabackup, the password for
#   the mariabackup user
#   Defaults to ''
#
# [*cipher_list*]
#   (Optional) When enable_internal_tls is true, defines the list of allowed
#   ciphers for the mysql server and Galera (including SST).
#   Defaults to '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1'
#
# [*gcomm_cipher*]
#   (Optional) When enable_internal_tls is true, defines the cipher
#   used by Galera for the gcomm replication traffic.
#   Defaults to 'AES128-SHA256'
#
# [*sst_tls_cipher*]
#   (Optional) When enable_internal_tls is true, defines the list of
#   ciphers that the socat may use to tunnel SST connections. Deprecated,
#   now socat is configured based on option cipher_list.
#   Defaults to undef
#
# [*sst_tls_options*]
#   (Optional) When enable_internal_tls is true, defines additional
#   parameters to be passed to socat for tunneling SST connections.
#   Defaults to undef
#
# [*two_node_mode*]
#   (Optional) Whether to configure the resource agent in special
#   2-node cluster mode, to allow recovering from a network partition.
#   Defaults to false
#
# [*ipv6*]
#   (Optional) Whether to deploy MySQL on IPv6 network.
#   Defaults to str2bool(hiera('mysql_ipv6', false))
#
# [*mysql_server_options*]
#   (Optional) Extras options to deploy MySQL. Useful when deploying Galera cluster.
#   Should be an hash.
#   Defaults to hiera('tripleo::profile::base::database::mysql::mysql_server_options', {}
#
# [*mysql_auth_ed25519*]
#   (Optional) Use MariaDB's ed25519 authentication plugin to authenticate
#   a user when connecting to the server
#   Defaults to hiera('mysql_auth_ed25519', false)
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*container_backend*]
#   (optional) Container backend to use when creating the bundle
#   Defaults to 'podman'
#
# [*log_driver*]
#   (optional) Container log driver to use.
#   Defaults to 'k8s-file'
#
# [*log_file*]
#   (optional) Container log file to use. Only relevant when log_driver is
#   set to 'k8s-file'.
#   Defaults to '/var/log/containers/stdouts/galera-bundle.log'
#
# [*tls_priorities*]
#   (optional) Sets PCMK_tls_priorities in /etc/sysconfig/pacemaker when set
#   Defaults to hiera('tripleo::pacemaker::tls_priorities', undef)
#
# [*bundle_user*]
#   (optional) Set the --user= switch to be passed to pcmk
#   Defaults to 'root'
#
# [*open_files_limit*]
#   (Optional) Maximum value for open-files-limit
#   Defaults to 16384
#
# [*start_timeout*]
#   (Optional) Maximum time in second for initializing a galera server
#   before pacemaker considers the operation timed out.
#   Defaults to undef (use the default value in resource agent)
#
# [*promote_timeout*]
#   (Optional) Maximum time in second for starting up a galera server
#   before pacemaker considers the operation timed out.
#   Defaults to 300
#
# [*monitor_timeout*]
#   (Optional) Maximum time in second for monitoring a galera server
#   before pacemaker considers the operation timed out.
#   Defaults to undef (use the default value in resource agent)
#
# [*demote_timeout*]
#   (Optional) Maximum time in second for stopping a galera server
#   before pacemaker considers the operation timed out.
#   Defaults to undef (use the default value in resource agent)
#
# [*stop_timeout*]
#   (Optional) Maximum time in second for ensuring a galera server is stopped
#   before pacemaker considers the operation timed out.
#   Defaults to undef (use the default value in resource agent)
#
# [*force_ocf*]
#   (optional) Use --force when creating the ocf resource via pcs
#   Defaults to false
#
# [*gcache_size*]
#   (optional) Controls the gcache size.
#   Defaults to undef
#
# [*gcache_recover*]
#   (optional) Recover gcache on galera startup.
#   Defaults to false
#
class tripleo::profile::pacemaker::database::mysql_bundle (
  $mysql_docker_image             = undef,
  $control_port                   = 3123,
  $bootstrap_node                 = hiera('mysql_short_bootstrap_node_name'),
  $bind_address                   = $::hostname,
  $ca_file                        = undef,
  $cipher_list                    = '!SSLv2:kEECDH:kRSA:kEDH:kPSK:+3DES:!aNULL:!eNULL:!MD5:!EXP:!RC4:!SEED:!IDEA:!DES:!SSLv3:!TLSv1',
  $gcomm_cipher                   = 'AES128-SHA256',
  $certificate_specs              = hiera('tripleo::profile::base::database::mysql::certificate_specs', {}),
  $enable_internal_tls            = hiera('enable_internal_tls', false),
  $gmcast_listen_addr             = hiera('mysql_bind_host'),
  $innodb_flush_log_at_trx_commit = hiera('innodb_flush_log_at_trx_commit', '1'),
  $clustercheck_user              = 'clustercheck',
  $clustercheck_password          = hiera('mysql_clustercheck_password'),
  $sst_method                     = 'rsync',
  $mariabackup_user               = 'mariabackup',
  $mariabackup_password           = '',
  $sst_tls_cipher                 = undef,
  $sst_tls_options                = undef,
  $ipv6                           = str2bool(hiera('mysql_ipv6', false)),
  $mysql_server_options           = hiera('tripleo::profile::base::database::mysql::mysql_server_options', {}),
  $mysql_auth_ed25519             = hiera('mysql_auth_ed25519', false),
  $two_node_mode                  = false,
  $container_backend              = 'podman',
  $log_driver                     = 'k8s-file',
  $log_file                       = '/var/log/containers/stdouts/galera-bundle.log',
  $tls_priorities                 = hiera('tripleo::pacemaker::tls_priorities', undef),
  $bundle_user                    = 'root',
  $pcs_tries                      = hiera('pcs_tries', 20),
  $step                           = Integer(hiera('step')),
  $open_files_limit               = 16384,
  $start_timeout                  = undef,
  $promote_timeout                = 300,
  $monitor_timeout                = undef,
  $demote_timeout                 = undef,
  $stop_timeout                   = undef,
  $force_ocf                      = false,
  $gcache_size                    = undef,
  $gcache_recover                 = false,
) {
  if $bootstrap_node and $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  if $log_driver == 'k8s-file' {
    $log_file_real = " --log-opt path=${log_file}"
  } else {
    $log_file_real = ''
  }
  # FQDN are lowercase in /etc/hosts, so are pacemaker node names
  $galera_node_names_lookup = downcase(hiera('mysql_short_node_names_override',
                                              hiera('mysql_short_node_names', $::hostname)))
  if (hiera('mysql_node_names_override', undef)) {
    $galera_fqdns_names_lookup = downcase(hiera('mysql_node_names_override'))
  } else {
    # is this an additional nova cell?
    if hiera('nova_is_additional_cell', undef) {
      $galera_fqdns_names_lookup = downcase(hiera('mysql_cell_node_names', $::hostname))
    } else {
      $galera_fqdns_names_lookup = downcase(hiera('mysql_node_names', $::hostname))
    }
  }

  $galera_nodes = join(any2array($galera_fqdns_names_lookup), ',')
  $galera_nodes_array = split($galera_nodes, ',')
  $galera_nodes_count = count($galera_nodes_array)

  # construct a galera-pacemaker name mapping for the resource agent
  # [galera-0:galera-0.internalapi.local, ...]
  $host_map_array_tmp = zip($galera_node_names_lookup, $galera_fqdns_names_lookup)
  $host_map_array = $host_map_array_tmp.map |$i| {
    "${i[0]}:${i[1]}"
  }
  $cluster_host_map_string = join($host_map_array, ';')

  if $gcache_size {
    $gcache_size_opt = "gcache.size=${gcache_size};"
  } else {
    $gcache_size_opt = ''
  }
  $gcache_recover_opt = "gcache.recover=${$gcache_recover ? { false => 'no', default => 'yes' }};"
  $gcache_options = "${gcache_size_opt}${gcache_recover_opt}"

  if $sst_method == 'mariabackup' {
    $wsrep_sst_method = 'mariabackup'
    $mysqld_sst_auth = {
      'mysqld' => { 'wsrep_sst_auth' => "${mariabackup_user}:${mariabackup_password}" }
    }
  } else {
    if $enable_internal_tls {
      $wsrep_sst_method = 'rsync_tunnel'
    } else {
      $wsrep_sst_method = 'rsync'
    }
    $mysqld_sst_auth = {}
  }
  if $enable_internal_tls {
    if $sst_method == 'mariabackup' {
      $tcert = 'ssl-cert'
      $tkey = 'ssl-key'
      $tca = 'ssl-ca'
    } else {
      $tcert = 'tcert'
      $tkey = 'tkey'
      $tca = 'tca'
    }
    $tls_certfile = $certificate_specs['service_certificate']
    $tls_keyfile = $certificate_specs['service_key']
    $sst_tls = {
      $tcert => $tls_certfile,
      $tkey => $tls_keyfile,
    }
    if $ca_file {
      $tls_ca_options = "socket.ssl_ca=${ca_file}"
      $sst_tca = { $tca => $ca_file }
    } else {
      $tls_ca_options = ''
      $sst_tca = {}
    }
    $tls_options = "socket.ssl_key=${tls_keyfile};socket.ssl_cert=${tls_certfile};socket.ssl_cipher=${gcomm_cipher};${tls_ca_options};"
    if $sst_method == 'mariabackup' {
      $sst_encrypt = { 'encrypt' => 3 }
    } else {
      $sst_encrypt = {}
    }
    if $ipv6 {
      $sst_ipv6 = 'pf=ip6'
    } else {
      $sst_ipv6 = undef
    }
    if defined(sst_tls_cipher) {
      warning('The sst_tls_cipher parameter is deprecated, use cipher_list')
      $sst_cipher = $sst_tls_cipher
    } else {
      $sst_cipher = $cipher_list
    }
    $all_sst_options = ["cipher=${sst_cipher}", $sst_tls_options, $sst_ipv6]
    $sst_sockopt = {
      'sockopt' => join(delete_undef_values($all_sst_options), ',')
    }
    $mysqld_options_sst = { 'sst' => merge($sst_tls, $sst_tca, $sst_sockopt, $sst_encrypt) }
  } else {
    $tls_options = ''
    if $sst_method == 'mariabackup' {
      if $ipv6 {
        $mysqld_options_sst = { 'sst' => { 'sockopt' => 'pf=ip6' } }
      } else {
        $mysqld_options_sst = {}
      }
    } else {
      $mysqld_options_sst = {}
    }
  }
  if $ipv6 {
    $wsrep_provider_options = "${gcache_options}gmcast.listen_addr=tcp://[::]:4567;${tls_options}"
  } else {
    $wsrep_provider_options = "${gcache_options}gmcast.listen_addr=tcp://${gmcast_listen_addr}:4567;${tls_options}"
  }

  $mysqld_options_mysqld = {
    'mysqld' => {
      'pid-file'                       => '/var/lib/mysql/mariadb.pid',
      'skip-name-resolve'              => '1',
      'binlog_format'                  => 'ROW',
      'default-storage-engine'         => 'innodb',
      'innodb_autoinc_lock_mode'       => '2',
      'innodb_locks_unsafe_for_binlog' => '1',
      'innodb_flush_log_at_trx_commit' => $innodb_flush_log_at_trx_commit,
      'wsrep_on'                       => 'ON',
      'wsrep_provider'                 => '/usr/lib64/galera/libgalera_smm.so',
      'wsrep_cluster_name'             => 'galera_cluster',
      'wsrep_cluster_address'          => "gcomm://${galera_nodes}",
      'wsrep_slave_threads'            => '1',
      'wsrep_certify_nonPK'            => '1',
      'wsrep_debug'                    => '0',
      'wsrep_convert_LOCK_to_trx'      => '0',
      'wsrep_retry_autocommit'         => '1',
      'wsrep_auto_increment_control'   => '1',
      'wsrep_drupal_282555_workaround' => '0',
      'wsrep_causal_reads'             => '0',
      'wsrep_sst_method'               => $wsrep_sst_method,
      'wsrep_provider_options'         => $wsrep_provider_options,
    },
    'mysqld_safe' => {
      'pid-file'                       => '/var/lib/mysql/mariadb.pid',
    }
  }

  $mysqld_options = deep_merge($mysqld_options_mysqld, $mysqld_options_sst,
                                  $mysqld_sst_auth, $mysql_server_options)

  # remove_default_accounts parameter will execute some mysql commands
  # to remove the default accounts created by MySQL package.
  # We need MySQL running to run the commands successfully, so better to
  # wait step 2 before trying to run the commands.
  if $step >= 2 and $pacemaker_master {
    $remove_default_accounts = true
  } else {
    $remove_default_accounts = false
  }

  $mysql_root_password = hiera('mysql::server::root_password')

  if $step >= 1 {
    # Kolla sets the root password, expose it to the MySQL package
    # so that it can initialize the database (e.g. create users)
    file { '/root/.my.cnf' :
      ensure  => file,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "[client]
user=root
password=\"${mysql_root_password}\"

[mysql]
user=root
password=\"${mysql_root_password}\"",
    }

    # Resource agent uses those credentials to poll galera state
    file { '/etc/sysconfig/clustercheck' :
      ensure  => file,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "MYSQL_USERNAME=${clustercheck_user}\n
MYSQL_PASSWORD='${clustercheck_password}'\n
MYSQL_HOST=localhost\n",
    }
  }

  if $step >= 2 {
    # need that class to create all openstack credentials
    # we don't include it in step 1 because the kolla bootstrap
    # happens after step 1 baremetal
    class { 'tripleo::profile::base::database::mysql':
      bind_address            => $bind_address,
      bootstrap_node          => $bootstrap_node,
      manage_resources        => false,
      remove_default_accounts => $remove_default_accounts,
      mysql_server_options    => $mysqld_options,
      cipher_list             => $cipher_list
    }

    if $pacemaker_master {
      if (hiera('mysql_short_node_names_override', undef)) {
        $mysql_short_node_names = hiera('mysql_short_node_names_override')
      } else {
        $mysql_short_node_names = hiera('mysql_short_node_names')
      }

      $mysql_short_node_names.each |String $node_name| {
        # lint:ignore:puppet-lint-2.0.1 does not work with multiline strings
        # and blocks (remove this when we move to 2.2.0 where this works)
        pacemaker::property { "galera-role-${node_name}":
          property => 'galera-role',
          value    => true,
          tries    => $pcs_tries,
          node     => downcase($node_name),
          before   => Pacemaker::Resource::Bundle['galera-bundle'],
        }
        # lint:endignore
      }

      $storage_maps = {
        'mysql-cfg-files'   => {
          'source-dir' => '/var/lib/kolla/config_files/mysql.json',
          'target-dir' => '/var/lib/kolla/config_files/config.json',
          'options'    => 'ro',
        },
        'mysql-cfg-data'    => {
          'source-dir' => '/var/lib/config-data/puppet-generated/mysql/',
          'target-dir' => '/var/lib/kolla/config_files/src',
          'options'    => 'ro',
        },
        'mysql-hosts'       => {
          'source-dir' => '/etc/hosts',
          'target-dir' => '/etc/hosts',
          'options'    => 'ro',
        },
        'mysql-localtime'   => {
          'source-dir' => '/etc/localtime',
          'target-dir' => '/etc/localtime',
          'options'    => 'ro',
        },
        'mysql-lib'         => {
          'source-dir' => '/var/lib/mysql',
          'target-dir' => '/var/lib/mysql',
          'options'    => 'rw,z',
        },
        # NOTE: we cannot remove this bind mount until the resource-agent
        # can use the configured log-file for initial bootstrap operations
        'mysql-log-mariadb' => {
          'source-dir' => '/var/log/mariadb',
          'target-dir' => '/var/log/mariadb',
          'options'    => 'rw,z',
        },
        'mysql-log'         => {
          'source-dir' => '/var/log/containers/mysql',
          'target-dir' => '/var/log/mysql',
          'options'    => 'rw,z',
        },
        'mysql-dev-log'     => {
          'source-dir' => '/dev/log',
          'target-dir' => '/dev/log',
          'options'    => 'rw',
        },
      }

      if $enable_internal_tls {
        $mysql_storage_maps_tls = {
          'mysql-pki-gcomm-key'  => {
            'source-dir' => '/etc/pki/tls/private/mysql.key',
            'target-dir' => '/var/lib/kolla/config_files/src-tls/etc/pki/tls/private/mysql.key',
            'options'    => 'ro',
          },
          'mysql-pki-gcomm-cert' => {
            'source-dir' => '/etc/pki/tls/certs/mysql.crt',
            'target-dir' => '/var/lib/kolla/config_files/src-tls/etc/pki/tls/certs/mysql.crt',
            'options'    => 'ro',
          },
        }
        if $ca_file {
          $ca_storage_maps_tls = {
            'mysql-pki-gcomm-ca' => {
              'source-dir' => $ca_file,
              'target-dir' => "/var/lib/kolla/config_files/src-tls${ca_file}",
              'options'    => 'ro',
            },
          }
        } else {
          $ca_storage_maps_tls = {}
        }
        $storage_maps_tls = merge($mysql_storage_maps_tls, $ca_storage_maps_tls)
      } else {
        $storage_maps_tls = {}
      }
      if $tls_priorities != undef {
        $tls_priorities_real = " -e PCMK_tls_priorities=${tls_priorities}"
      } else {
        $tls_priorities_real = ''
      }
      if $two_node_mode == true {
        $two_node_mode_opt = ' two_node_mode=true'
      } else {
        $two_node_mode_opt = ''
      }

      pacemaker::resource::bundle { 'galera-bundle':
        image             => $mysql_docker_image,
        replicas          => $galera_nodes_count,
        masters           => $galera_nodes_count,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['galera-role eq true'],
        },
        container_options => 'network=host',
        # lint:ignore:140chars
        options           => "--user=${bundle_user} --log-driver=${log_driver}${log_file_real} -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS${tls_priorities_real}",
        # lint:endignore
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${control_port}",
        storage_maps      => merge($storage_maps, $storage_maps_tls),
        container_backend => $container_backend,
        tries             => $pcs_tries,
        before            => Exec['galera-ready'],
      }

      $op_start_params = $start_timeout ? {
        undef   => undef,
        default => "start timeout=${start_timeout}s"
      }
      $op_promote_params = $promote_timeout ? {
        undef   => 'promote on-fail=block',
        default => "promote timeout=${promote_timeout}s on-fail=block"
      }
      $op_monitor_params = $monitor_timeout ? {
        undef   => undef,
        default => "monitor timeout=${monitor_timeout}s"
      }
      $op_demote_params = $demote_timeout ? {
        undef   => undef,
        default => "demote timeout=${demote_timeout}s"
      }
      $op_stop_params = $stop_timeout ? {
        undef   => undef,
        default => "stop timeout=${stop_timeout}s"
      }
      # lint:ignore:140chars
      $op_params = join(delete_undef_values([$op_start_params, $op_promote_params, $op_monitor_params, $op_demote_params, $op_stop_params]), ' ')
      # lint:endignore

      pacemaker::resource::ocf { 'galera':
        ocf_agent_name  => 'heartbeat:galera',
        master_params   => '',
        meta_params     => "master-max=${galera_nodes_count} ordered=true container-attribute-target=host",
        op_params       => $op_params,
        resource_params => "log='/var/log/mysql/mysqld.log' additional_parameters='--open-files-limit=${open_files_limit}' enable_creation=true wsrep_cluster_address='gcomm://${galera_nodes}' cluster_host_map='${cluster_host_map_string}'${two_node_mode_opt}",
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['galera-role eq true'],
        },
        bundle          => 'galera-bundle',
        require         => [Class['mysql::server']],
        before          => Exec['galera-ready'],
        force           => $force_ocf,
      }

      # Resource relation: we normally want the bundle resource to
      # be run before the OCF one, as the latter depends on the former
      # at creation time.
      # However during scale up, both resources change, and the bundle
      # one shouldn't be updated prior to the OCF one, otherwise
      # pacemaker could spawn additional replicas before the necessary
      # info is updated in the OCF resource, which would confuse the
      # galera resource agent and cause spurious errors.
      $replicas=pacemaker_bundle_replicas('galera-bundle')
      if ($replicas > 0) and ($galera_nodes_count > $replicas) {
        Pacemaker::Resource::Ocf['galera'] -> Pacemaker::Resource::Bundle['galera-bundle']
      } else {
        Pacemaker::Resource::Bundle['galera-bundle'] -> Pacemaker::Resource::Ocf['galera']
      }

      exec { 'galera-ready' :
        command     => '/usr/bin/clustercheck >/dev/null',
        timeout     => 30,
        tries       => 180,
        try_sleep   => 10,
        environment => ['AVAILABLE_WHEN_READONLY=0'],
        tag         => 'galera_ready'
      }
      File['/etc/sysconfig/clustercheck'] -> Exec['galera-ready']

      # If the root password is to be updated:
      #   . hiera contains the new password
      #   . .my.cnf still contains the current root credentials
      # so changing the root password can only happen before
      # .my.cnf is re-generated by puppet
      mysql_user { 'root@localhost':
        ensure        => present,
        password_hash => mysql::password($mysql_root_password),
      }
      Mysql_user['root@localhost'] -> File['/root/.my.cnf']

      # make sure to update all root users in the mysql DB
      mysql_user { 'root@%':
        ensure        => present,
        password_hash => mysql::password($mysql_root_password),
      }

      # declare the clustercheck user resource to configure
      # ed25519 authentication on stack creation or update.
      if ($mysql_auth_ed25519) {
        $clustercheck_resource_config = {
          plugin        => 'ed25519',
          password_hash => mysql_ed25519_password($clustercheck_password),
        }
      } else {
        $clustercheck_resource_config = {
          password_hash => mysql::password($clustercheck_password),
        }
      }
      mysql_user { 'clustercheck@localhost':
        ensure => present,
        *      => $clustercheck_resource_config,
      }

      # We create databases and users for services at step 2 as well. This ensures
      # Galera is up and ready before those get created
      File['/root/.my.cnf'] -> Mysql_database<||>
      File['/root/.my.cnf'] -> Mysql_user<|title!='root@localhost'|>
      File['/root/.my.cnf'] -> Mysql_grant<||>
      Exec['galera-ready'] -> Mysql_database<||>
      Exec['galera-ready'] -> Mysql_user<||>
      Exec['galera-ready'] -> Mysql_grant<||>
    }
  }
}
