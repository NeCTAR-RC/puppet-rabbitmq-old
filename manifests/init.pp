# RabbitMQ server
class rabbitmq(
  $manage_repo=false,
  $mgmt_port=15672,
  $mgmt_ssl=false,
  $max_conns=1024,
  $nagios_critical='1000,20,1000',
  $nagios_warning='500,1,500',
  $insecure_ssl=true)
{

  if $manage_repo {
    include ::rabbitmq::repo
    Apt::Source <| title == 'rabbitmq' |> -> Class['apt::update'] -> Package <| tag == 'rabbitmq' |>
  }

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

}
