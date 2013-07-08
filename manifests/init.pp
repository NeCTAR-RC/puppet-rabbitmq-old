class rabbitmq($mgmt_port=55672) {

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

  file {['/etc/rabbitmq/ssl', '/etc/rabbitmq/rabbitmq.conf.d']:
    ensure  => directory,
    require => Package['rabbitmq-server'],
  }

  file {'/etc/rabbitmq/rabbitmq.config':
    ensure  => present,
    content => template('rabbitmq/rabbitmq.config.erb'),
    notify  => Service['rabbitmq-server'],
    require => Package['rabbitmq-server'],
  }

  File <| tag == 'sslcert' |> {
    notify +> Service['rabbitmq-server'],
  }

  exec {'/usr/lib/rabbitmq/bin/rabbitmq-plugins enable rabbitmq_management':
    unless  => '/bin/grep rabbitmq_management /etc/rabbitmq/enabled_plugins',
    notify  => Service['rabbitmq-server'],
    require => Package['rabbitmq-server'],
  }

  $user = hiera('nagios::rabbit_user', 'guest')
  $password = hiera('nagios::rabbit_pass', 'guest')
  $vhost = hiera('nagios::rabbit_vhost', '/')

  nagios::nrpe::service {
    'rabbitmq_overview':
      servicegroups => 'message-queues',
      check_command => "/usr/local/lib/nagios/plugins/check_rabbitmq_overview -H ${fqdn} --port ${mgmt_port} -c -1,1,-1 -u ${user} -p ${password}";
    'rabbitmq_aliveness':
      servicegroups => 'message-queues',
      check_command => "/usr/local/lib/nagios/plugins/check_rabbitmq_aliveness -H ${fqdn} --port ${mgmt_port} --vhost ${vhost} -u ${user} -p ${password}";
  }

  package { ['libnagios-plugin-perl', 'libwww-perl', 'libjson-perl']:
    ensure => installed;
  }

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
