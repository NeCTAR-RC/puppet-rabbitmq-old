# RabbitMQ server
class rabbitmq(
  $mgmt_port=15672,
  $mgmt_ssl=false,
  $max_conns=1024,
  $nagios_critical='1000,20,1000',
  $nagios_warning='500,1,500')
{

  package { 'rabbitmq-server':
    ensure => present,
  }

  user { 'rabbitmq':
    groups  => $::ssl_group,
    require => Package['rabbitmq-server'],
  }

  service { 'rabbitmq-server':
    ensure  => running,
    enable  => true,
    require => Package['rabbitmq-server'],
  }

  if str2bool($::systemd) {
    include ::systemd
    file { '/etc/systemd/system/rabbitmq-server.service.d':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
    }

    file { '/etc/systemd/system/rabbitmq-server.service.d/limits.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('rabbitmq/rabbitmq-server.service.d-limits.conf.erb'),
      require => File['/etc/systemd/system/rabbitmq-server.service.d'],
      notify  => Exec['systemctl-daemon-reload']
    }
  }

  file { '/etc/default/rabbitmq-server':
    ensure  => present,
    content => template('rabbitmq/etc-default-rabbitmq-server.erb'),
    require => Package['rabbitmq-server'],
  }

  file {['/etc/rabbitmq/ssl', '/etc/rabbitmq/rabbitmq.conf.d']:
    ensure  => directory,
    require => Package['rabbitmq-server'],
  }

  file {'/etc/rabbitmq/rabbitmq.config':
    ensure  => present,
    content => template("rabbitmq/rabbitmq.config-${::lsbdistcodename}.erb"),
    require => Package['rabbitmq-server'],
  }

  file {'/etc/rabbitmq/rabbitmq-env.conf':
    ensure  => present,
    source  => 'puppet:///modules/rabbitmq/rabbitmq-env.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['rabbitmq-server'],
  }

  File <| tag == 'sslcert' |>

  exec {'/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management':
    unless      => '/bin/grep rabbitmq_management /etc/rabbitmq/enabled_plugins',
    environment => 'HOME=/root',
    notify      => Service['rabbitmq-server'],
    require     => Package['rabbitmq-server'],
  }

  $admin_hosts = hiera('firewall::admin_hosts', [])
  $infra_hosts = hiera('firewall::infra_hosts', [])

  nectar::firewall::multisource {[ prefix($admin_hosts, '200 rabbit mgmt,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => [5671, 5672, $mgmt_port,],
  }
  nectar::firewall::multisource {[ prefix($infra_hosts, '200 rabbit ssl,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => 5671,
  }

  $user = hiera('nagios::rabbit_user', 'guest')
  $password = hiera('nagios::rabbit_pass', 'guest')
  $vhost = hiera('nagios::rabbit_vhost', '/')
  $ssl = $mgmt_ssl ? {
    true  => '--ssl',
    false => '',
  }

  nagios::nrpe::service {
    'rabbitmq_overview':
      servicegroups => 'message-queues',
      check_command => "/usr/local/lib/nagios/plugins/check_rabbitmq_overview -H ${::fqdn} --port ${mgmt_port} -c ${nagios_critical} -w ${nagios_warning} -u ${user} -p ${password} ${ssl}",
      nrpe_command  => 'check_nrpe_really_slow_1arg';
    'rabbitmq_aliveness':
      servicegroups => 'message-queues',
      check_command => "/usr/local/lib/nagios/plugins/check_rabbitmq_aliveness -H ${::fqdn} --port ${mgmt_port} --vhost ${vhost} -u ${user} -p ${password} ${ssl}";
  }

  ensure_packages(['libnagios-plugin-perl', 'libwww-perl', 'libjson-perl', 'python-requests'])

  file {
    '/usr/local/lib/nagios/plugins/check_rabbitmq_overview':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/rabbitmq/check_rabbitmq_overview',
      require => File['/usr/local/lib/nagios/plugins'];
    '/usr/local/lib/nagios/plugins/check_rabbitmq_aliveness':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/rabbitmq/check_rabbitmq_aliveness',
      require => File['/usr/local/lib/nagios/plugins'];
  }
}
