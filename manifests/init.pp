class rabbitmq {

  package { 'rabbitmq-server':
    ensure => present,
  }

  user { 'rabbitmq':
    groups  => $ssl_group,
    require => Package['rabbitmq'],
  }

  service { 'rabbitmq-server':
    ensure  => running,
    enable  => true,
    require => Package['rabbitmq-server'],
  }

  file {'/etc/rabbitmq/ssl':
    ensure  => directory,
    require => Package['rabbitmq-server'],
  }
  
  file {'/etc/rabbitmq/rabbitmq.config':
    ensure  => present,
    content => template("rabbitmq/rabbitmq.config.erb"),
    notify  => Service['rabbitmq-server'],
    require => Package['rabbitmq-server'],
  }

  File <| tag == 'sslcert' |> {
    notify +> Service['rabbitmq-server'],
  }

}
