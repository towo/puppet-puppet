# == Class: puppet::server::puppetserver
#
# Configures the puppetserver jvm configuration file using augeas.
#
# === Parameters:
#
# * `java_bin`
# Path to the java executable to use
#
# * `config`
# Path to the jvm configuration file.
# This file is usually either /etc/default/puppetserver or
# /etc/sysconfig/puppetserver depending on your *nix flavor.
#
# * `jvm_min_heap_size`
# Translates into the -Xms option and is added to the JAVA_ARGS
#
# * `jvm_max_heap_size`
# Translates into the -Xmx option and is added to the JAVA_ARGS
#
# * `jvm_extra_args`
# Custom options to pass through to the java binary. These get added to
# the end of the JAVA_ARGS variable
#
# * `jvm_cli_args`
# Custom options to pass through to the java binary when using a
# puppetserver subcommand, (eg puppetserver gem). These get used
# in the JAVA_ARGS_CLI variable.
#
# * `server_puppetserver_dir`
# Puppetserver config directory
#
# * `server_puppetserver_vardir`
# Puppetserver var directory
#
# * `server_jruby_gem_home`
# Puppetserver jruby gemhome
#
# * `server_cipher_suites`
# Puppetserver array of acceptable ciphers
#
# * `server_ssl_protocols`
# Puppetserver array of acceptable ssl protocols
#
# * `server_max_active_instances`
# Puppetserver number of max jruby instances
#
# * `server_max_requests_per_instance`
# Puppetserver number of max requests per jruby instance
#
# === Example
#
# @example
#
#   # configure memory for java < 8
#   class {'::puppet::server::puppetserver':
#     jvm_min_heap_size => '1G',
#     jvm_max_heap_size => '3G',
#     jvm_extra_args    => '-XX:MaxPermSize=256m',
#   }
#
class puppet::server::puppetserver (
  $config                                 = $::puppet::server::jvm_config,
  $java_bin                               = $::puppet::server::jvm_java_bin,
  $jvm_extra_args                         = $::puppet::server::jvm_extra_args,
  $jvm_cli_args                           = $::puppet::server::jvm_cli_args,
  $jvm_min_heap_size                      = $::puppet::server::jvm_min_heap_size,
  $jvm_max_heap_size                      = $::puppet::server::jvm_max_heap_size,
  $server_puppetserver_dir                = $::puppet::server::puppetserver_dir,
  $server_puppetserver_vardir             = $::puppet::server::puppetserver_vardir,
  $server_puppetserver_rundir             = $::puppet::server::puppetserver_rundir,
  $server_puppetserver_logdir             = $::puppet::server::puppetserver_logdir,
  $server_jruby_gem_home                  = $::puppet::server::jruby_gem_home,
  $server_ruby_load_paths                 = $::puppet::server::ruby_load_paths,
  $server_cipher_suites                   = $::puppet::server::cipher_suites,
  $server_max_active_instances            = $::puppet::server::max_active_instances,
  $server_max_requests_per_instance       = $::puppet::server::max_requests_per_instance,
  $server_ssl_protocols                   = $::puppet::server::ssl_protocols,
  $server_ssl_ca_crl                      = $::puppet::server::ssl_ca_crl,
  $server_ssl_ca_cert                     = $::puppet::server::ssl_ca_cert,
  $server_ssl_cert                        = $::puppet::server::ssl_cert,
  $server_ssl_cert_key                    = $::puppet::server::ssl_cert_key,
  $server_ssl_chain                       = $::puppet::server::ssl_chain,
  $server_crl_enable                      = $::puppet::server::crl_enable_real,
  $server_ip                              = $::puppet::server::ip,
  $server_port                            = $::puppet::server::port,
  $server_http                            = $::puppet::server::http,
  $server_http_allow                      = $::puppet::server::http_allow,
  $server_http_port                       = $::puppet::server::http_port,
  $server_ca                              = $::puppet::server::ca,
  $server_dir                             = $::puppet::server::dir,
  $codedir                                = $::puppet::server::codedir,
  $server_idle_timeout                    = $::puppet::server::idle_timeout,
  $server_web_idle_timeout                = $::puppet::server::web_idle_timeout,
  $server_connect_timeout                 = $::puppet::server::connect_timeout,
  $server_ca_auth_required                = $::puppet::server::ca_auth_required,
  $server_ca_client_whitelist             = $::puppet::server::ca_client_whitelist,
  $server_admin_api_whitelist             = $::puppet::server::admin_api_whitelist,
  $server_puppetserver_version            = $::puppet::server::puppetserver_version,
  $server_use_legacy_auth_conf            = $::puppet::server::use_legacy_auth_conf,
  $server_check_for_updates               = $::puppet::server::check_for_updates,
  $server_environment_class_cache_enabled = $::puppet::server::environment_class_cache_enabled,
  $server_jruby9k                         = $::puppet::server::puppetserver_jruby9k,
  $server_metrics                         = $::puppet::server::puppetserver_metrics,
  $metrics_jmx_enable                     = $::puppet::server::metrics_jmx_enable,
  $metrics_graphite_enable                = $::puppet::server::metrics_graphite_enable,
  $metrics_graphite_host                  = $::puppet::server::metrics_graphite_host,
  $metrics_graphite_port                  = $::puppet::server::metrics_graphite_port,
  $metrics_server_id                      = $::puppet::server::metrics_server_id,
  $metrics_graphite_interval              = $::puppet::server::metrics_graphite_interval,
  $metrics_allowed                        = $::puppet::server::metrics_allowed,
  $server_experimental                    = $::puppet::server::puppetserver_experimental,
  $server_trusted_agents                  = $::puppet::server::puppetserver_trusted_agents,
  $allow_header_cert_info                 = $::puppet::server::allow_header_cert_info,
) {
  include ::puppet::server

  if versioncmp($server_puppetserver_version, '2.2') < 0 {
    fail('puppetserver <2.2 is not supported by this module version')
  }

  if !(empty($server_http_allow)) {
    fail('setting $server_http_allow is not supported for puppetserver as it would have no effect')
  }

  $puppetserver_package = pick($::puppet::server::package, 'puppetserver')

  $jvm_cmd_arr = ["-Xms${jvm_min_heap_size}", "-Xmx${jvm_max_heap_size}", $jvm_extra_args]
  $jvm_cmd = strip(join(flatten($jvm_cmd_arr), ' '))

  if $::osfamily == 'FreeBSD' {
    augeas { 'puppet::server::puppetserver::jvm':
      context => '/files/etc/rc.conf',
      changes => [ "set puppetserver_java_opts '\"${jvm_cmd}\"'" ],
    }
  } else {
    if $jvm_cli_args {
      $changes = [
        "set JAVA_ARGS '\"${jvm_cmd}\"'",
        "set JAVA_BIN ${java_bin}",
        "set JAVA_ARGS_CLI '\"${jvm_cli_args}\"'",
      ]
    } else {
      $changes = [
        "set JAVA_ARGS '\"${jvm_cmd}\"'",
        "set JAVA_BIN ${java_bin}",
      ]
    }
    augeas { 'puppet::server::puppetserver::jvm':
      lens    => 'Shellvars.lns',
      incl    => $config,
      context => "/files${config}",
      changes => $changes,
    }

    if versioncmp($server_puppetserver_version, '2.4.99') == 0 {
      $bootstrap_paths = "${server_puppetserver_dir}/bootstrap.cfg,${server_puppetserver_dir}/services.d/,/opt/puppetlabs/server/apps/puppetserver/config/services.d/"
    } elsif versioncmp($server_puppetserver_version, '2.5') >= 0 {
      $bootstrap_paths = "${server_puppetserver_dir}/services.d/,/opt/puppetlabs/server/apps/puppetserver/config/services.d/"
    } else { # 2.4
      $bootstrap_paths = "${server_puppetserver_dir}/bootstrap.cfg"
    }

    augeas { 'puppet::server::puppetserver::bootstrap':
      lens    => 'Shellvars.lns',
      incl    => $config,
      context => "/files${config}",
      changes => "set BOOTSTRAP_CONFIG '\"${bootstrap_paths}\"'",
    }

    if versioncmp($server_puppetserver_version, '5.0') >= 0 {
      $jruby_jar_changes = $server_jruby9k ? {
        true    => "set JRUBY_JAR '\"/opt/puppetlabs/server/apps/puppetserver/jruby-9k.jar\"'",
        default => 'rm JRUBY_JAR'
      }

      augeas { 'puppet::server::puppetserver::jruby_jar':
        lens    => 'Shellvars.lns',
        incl    => $config,
        context => "/files${config}",
        changes => $jruby_jar_changes,
      }
    }
  }

  # 2.4.99 configures for both 2.4 and 2.5 making upgrades and new installations easier when the
  # precise version available isn't known
  if versioncmp($server_puppetserver_version, '2.4.99') >= 0 {
    $servicesd = "${server_puppetserver_dir}/services.d"
    file { $servicesd:
      ensure => directory,
    }
    file { "${servicesd}/ca.cfg":
      ensure  => file,
      content => template('puppet/server/puppetserver/services.d/ca.cfg.erb'),
    }

    unless $::osfamily == 'FreeBSD' {
      file { '/opt/puppetlabs/server/apps/puppetserver/config':
        ensure => directory,
      }
      file { '/opt/puppetlabs/server/apps/puppetserver/config/services.d':
        ensure => directory,
      }
    }
  }

  if versioncmp($server_puppetserver_version, '2.5') < 0 {
    $bootstrapcfg = "${server_puppetserver_dir}/bootstrap.cfg"
    file { $bootstrapcfg:
      ensure => file,
    }

    $ca_enabled_ensure = $server_ca ? {
      true    => present,
      default => absent,
    }

    $ca_disabled_ensure = $server_ca ? {
      false   => present,
      default => absent,
    }

    file_line { 'ca_enabled':
      ensure  => $ca_enabled_ensure,
      path    => $bootstrapcfg,
      line    => 'puppetlabs.services.ca.certificate-authority-service/certificate-authority-service',
      require => File[$bootstrapcfg],
    }

    file_line { 'ca_disabled':
      ensure  => $ca_disabled_ensure,
      path    => $bootstrapcfg,
      line    => 'puppetlabs.services.ca.certificate-authority-disabled-service/certificate-authority-disabled-service',
      require => File[$bootstrapcfg],
    }

    if versioncmp($server_puppetserver_version, '2.3') >= 0 {
      $versioned_code_service_ensure = present
    } else {
      $versioned_code_service_ensure = absent
    }

    file_line { 'versioned_code_service':
      ensure  => $versioned_code_service_ensure,
      path    => $bootstrapcfg,
      line    => 'puppetlabs.services.versioned-code-service.versioned-code-service/versioned-code-service',
      require => File[$bootstrapcfg],
    }
  }

  file { "${server_puppetserver_dir}/conf.d/ca.conf":
    ensure => absent,
  }

  file { "${server_puppetserver_dir}/conf.d/puppetserver.conf":
    ensure  => file,
    content => template('puppet/server/puppetserver/conf.d/puppetserver.conf.erb'),
  }

  $auth_conf = "${server_puppetserver_dir}/conf.d/auth.conf"

  file { $auth_conf:
    ensure  => file,
  }

  hocon_setting { 'authorization.version':
    ensure  => present,
    path    => $auth_conf,
    setting => 'authorization.version',
    value   => 1,
    require => File[$auth_conf],
  }

  hocon_setting { 'authorization.allow-header-cert-info':
    ensure  => present,
    path    => $auth_conf,
    setting => 'authorization.allow-header-cert-info',
    value   => $allow_header_cert_info or $server_http,
    require => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs catalog':
    match_request_path   => '^/puppet/v3/catalog/([^/]+)$',
    match_request_type   => 'regex',
    match_request_method => ['get', 'post'],
    allow                => flatten(['$1', $server_trusted_agents]),
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs certificate':
    match_request_path    => '/puppet-ca/v1/certificate/',
    match_request_type    => 'path',
    match_request_method  => 'get',
    allow_unauthenticated => true,
    sort_order            => 500,
    path                  => $auth_conf,
    require               => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs crl':
    match_request_path    => '/puppet-ca/v1/certificate_revocation_list/ca',
    match_request_type    => 'path',
    match_request_method  => 'get',
    allow_unauthenticated => true,
    sort_order            => 500,
    path                  => $auth_conf,
    require               => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs csr':
    match_request_path    => '/puppet-ca/v1/certificate_request',
    match_request_type    => 'path',
    match_request_method  => ['get', 'put'],
    allow_unauthenticated => true,
    sort_order            => 500,
    path                  => $auth_conf,
    require               => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs environments':
    match_request_path   => '/puppet/v3/environments',
    match_request_type   => 'path',
    match_request_method => 'get',
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs environment classes':
    match_request_path   => '/puppet/v3/environment_classes',
    match_request_type   => 'path',
    match_request_method => 'get',
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs node':
    match_request_path   => '^/puppet/v3/node/([^/]+)$',
    match_request_type   => 'regex',
    match_request_method => 'get',
    allow                => '$1',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs report':
    match_request_path   => '^/puppet/v3/report/([^/]+)$',
    match_request_type   => 'regex',
    match_request_method => 'put',
    allow                => '$1',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs status':
    match_request_path    => '/puppet/v3/status',
    match_request_type    => 'path',
    match_request_method  => 'get',
    allow_unauthenticated => true,
    sort_order            => 500,
    path                  => $auth_conf,
    require               => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs static file content':
    match_request_path   => '/puppet/v3/static_file_content',
    match_request_type   => 'path',
    match_request_method => 'get',
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'environment-cache':
    match_request_path   => '/puppet-admin-api/v1/environment-cache',
    match_request_type   => 'path',
    match_request_method => 'delete',
    allow                => $server_admin_api_whitelist,
    sort_order           => 200,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'jruby-pool':
    match_request_path   => '/puppet-admin-api/v1/jruby-pool',
    match_request_type   => 'path',
    match_request_method => 'delete',
    allow                => $server_admin_api_whitelist,
    sort_order           => 200,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs deny all':
    match_request_path => '/',
    match_request_type => 'path',
    deny               => '*',
    sort_order         => 999,
    path               => $auth_conf,
    require            => File[$auth_conf],
  }

  $auth_conf_setting_ensure = $server_ca ? {
    true    => present,
    default => absent,
  }

  if $server_ca_auth_required {
    puppet_authorization::rule { 'certificate_status':
      ensure               => $auth_conf_setting_ensure,
      match_request_path   => '/puppet-ca/v1/certificate_status/',
      match_request_type   => 'path',
      match_request_method => [ 'get', 'put', 'delete' ],
      allow                => $server_ca_client_whitelist,
      sort_order           => 200,
      path                 => $auth_conf,
      require              => File[$auth_conf],
    }

    puppet_authorization::rule { 'certificate_statuses':
      ensure               => $auth_conf_setting_ensure,
      match_request_path   => '/puppet-ca/v1/certificate_statuses/',
      match_request_type   => 'path',
      match_request_method => 'get',
      allow                => $server_ca_client_whitelist,
      sort_order           => 200,
      path                 => $auth_conf,
      require              => File[$auth_conf],
    }
  } else {
    puppet_authorization::rule { 'certificate_status':
      ensure                => $auth_conf_setting_ensure,
      match_request_path    => '/puppet-ca/v1/certificate_status/',
      match_request_type    => 'path',
      match_request_method  => [ 'get', 'put', 'delete' ],
      allow_unauthenticated => true,
      sort_order            => 200,
      path                  => $auth_conf,
      require               => File[$auth_conf],
    }

    puppet_authorization::rule { 'certificate_statuses':
      ensure                => $auth_conf_setting_ensure,
      match_request_path    => '/puppet-ca/v1/certificate_statuses/',
      match_request_type    => 'path',
      match_request_method  => 'get',
      allow_unauthenticated => true,
      sort_order            => 200,
      path                  => $auth_conf,
      require               => File[$auth_conf],
    }
  }

  $is_puppetserver2 = versioncmp($server_puppetserver_version, '5.0') < 0
  $is_puppetserver5 = versioncmp($server_puppetserver_version, '5.0') >= 0

  $auth_conf_puppetserver_2_settings_ensure = $is_puppetserver2 ? {
    true    => present,
    default => absent,
  }

  $auth_conf_puppetserver_5_settings_ensure = $is_puppetserver5 ? {
    true    => present,
    default => absent,
  }

  puppet_authorization::rule { 'puppetlabs file bucket file':
    ensure               => $auth_conf_puppetserver_5_settings_ensure,
    match_request_path   => '/puppet/v3/file_bucket_file',
    match_request_type   => 'path',
    match_request_method => ['get', 'head', 'post', 'put'],
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs file content':
    ensure               => $auth_conf_puppetserver_5_settings_ensure,
    match_request_path   => '/puppet/v3/file_content',
    match_request_type   => 'path',
    match_request_method => ['get', 'post'],
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs file metadata':
    ensure               => $auth_conf_puppetserver_5_settings_ensure,
    match_request_path   => '/puppet/v3/file_metadata',
    match_request_type   => 'path',
    match_request_method => ['get', 'post'],
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  if $is_puppetserver2 or ($is_puppetserver5 and !$server_experimental) {
    $auth_conf_experimental_ensure = absent
  } else {
    $auth_conf_experimental_ensure = present
  }

  puppet_authorization::rule { 'puppetlabs experimental':
    ensure                => $auth_conf_experimental_ensure,
    match_request_path    => '/puppet/experimental',
    match_request_type    => 'path',
    allow_unauthenticated => true,
    sort_order            => 500,
    path                  => $auth_conf,
    require               => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs resource type':
    ensure               => $auth_conf_puppetserver_2_settings_ensure,
    match_request_path   => '/puppet/v3/resource_type',
    match_request_type   => 'path',
    match_request_method => ['get', 'post'],
    allow                => '*',
    sort_order           => 500,
    path                 => $auth_conf,
    require              => File[$auth_conf],
  }

  puppet_authorization::rule { 'puppetlabs file':
    ensure             => $auth_conf_puppetserver_2_settings_ensure,
    match_request_path => '/puppet/v3/file',
    match_request_type => 'path',
    allow              => '*',
    sort_order         => 500,
    path               => $auth_conf,
    require            => File[$auth_conf],
  }

  if versioncmp($server_puppetserver_version, '5.1') >= 0 {
    $auth_conf_tasks_ensure = present
  } else {
    $auth_conf_tasks_ensure = absent
  }

  puppet_authorization::rule { 'puppet tasks information':
    ensure             => $auth_conf_tasks_ensure,
    match_request_path => '/puppet/v3/tasks',
    match_request_type => 'path',
    allow              => '*',
    sort_order         => 500,
    path               => $auth_conf,
    require            => File[$auth_conf],
  }

  $webserver_conf = "${server_puppetserver_dir}/conf.d/webserver.conf"

  file { $webserver_conf:
    ensure  => file,
  }

  $webserver_general_settings = {
    'webserver.access-log-config'         => "${server_puppetserver_dir}/request-logging.xml",
    'webserver.client-auth'               => 'want',
    'webserver.ssl-host'                  => $server_ip,
    'webserver.ssl-port'                  => $server_port,
    'webserver.ssl-cert'                  => $server_ssl_cert,
    'webserver.ssl-key'                   => $server_ssl_cert_key,
    'webserver.ssl-ca-cert'               => $server_ssl_ca_cert,
    'webserver.idle-timeout-milliseconds' => $server_web_idle_timeout,
  }

  $webserver_general_settings.each |$setting, $value| {
    hocon_setting { $setting:
      ensure  => present,
      path    => $webserver_conf,
      setting => $setting,
      value   => $value,
      require => File[$webserver_conf],
    }
  }

  $webserver_http_settings_ensure = $server_http ? {
    true    => present,
    default => absent,
  }

  $webserver_http_settings = {
    'webserver.host' => $server_ip,
    'webserver.port' => $server_http_port,
  }

  $webserver_http_settings.each |$setting, $value| {
    hocon_setting { $setting:
      ensure  => $webserver_http_settings_ensure,
      path    => $webserver_conf,
      setting => $setting,
      value   => $value,
      require => File[$webserver_conf],
    }
  }

  $webserver_crl_settings_ensure = $server_crl_enable ? {
    true    => present,
    default => absent,
  }

  hocon_setting { 'webserver.ssl-crl-path':
    ensure  => $webserver_crl_settings_ensure,
    path    => $webserver_conf,
    setting => 'webserver.ssl-crl-path',
    value   => $server_ssl_ca_crl,
    require => File[$webserver_conf],
  }

  $webserver_ca_settings_ensure = $server_ca ? {
    true    => present,
    default => absent,
  }

  hocon_setting { 'webserver.ssl-cert-chain':
    ensure  => $webserver_ca_settings_ensure,
    path    => $webserver_conf,
    setting => 'webserver.ssl-cert-chain',
    value   => $server_ssl_chain,
    require => File[$webserver_conf],
  }

  $product_conf = "${server_puppetserver_dir}/conf.d/product.conf"

  if versioncmp($server_puppetserver_version, '2.7') >= 0 {
    $product_conf_ensure = file

    hocon_setting { 'product.check-for-updates':
      ensure  => present,
      path    => $product_conf,
      setting => 'product.check-for-updates',
      value   => $server_check_for_updates,
      require => File[$product_conf],
    }
  } else {
    $product_conf_ensure = absent
  }

  file { $product_conf:
    ensure => $product_conf_ensure,
  }

  if versioncmp($server_puppetserver_version, '5.0') >= 0 {
    $metrics_conf = "${server_puppetserver_dir}/conf.d/metrics.conf"

    $metrics_conf_ensure = $server_metrics ? {
      true    => file,
      default => absent
    }

    file { $metrics_conf:
      ensure  => $metrics_conf_ensure,
    }

    $metrics_general_settings = {
      'metrics.server-id'                                          => $metrics_server_id,
      'metrics.registries.puppetserver.reporters.jmx.enabled'      => $metrics_jmx_enable,
      'metrics.registries.puppetserver.reporters.graphite.enabled' => $metrics_graphite_enable,
      'metrics.reporters.graphite.host'                            => $metrics_graphite_host,
      'metrics.reporters.graphite.port'                            => $metrics_graphite_port,
      'metrics.reporters.graphite.update-interval-seconds'         => $metrics_graphite_interval,
    }

    $metrics_general_settings.each |$setting, $value| {
      hocon_setting { $setting:
        ensure  => present,
        path    => $metrics_conf,
        setting => $setting,
        value   => $value,
        require => File[$metrics_conf],
      }
    }

    $metrics_allowed_settings = $metrics_allowed ? {
      undef   => absent,
      default => present,
    }

    hocon_setting { 'metrics.registries.puppetserver.metrics-allowed':
      ensure  => $metrics_allowed_settings,
      path    => $metrics_conf,
      setting => 'metrics.registries.puppetserver.metrics-allowed',
      value   => $metrics_allowed,
      type    => 'array',
      require => File[$metrics_conf],
    }
  }
}
