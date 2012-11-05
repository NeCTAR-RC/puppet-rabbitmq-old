class rabbitmq::cluster inherits rabbitmq {

  File['/etc/rabbitmq/rabbitmq.config'] {
    content => template('rabbitmq/rabbitmq-cluster.config.erb'),
  }

  file {'/etc/rabbitmq/rabbitmq.conf.d/cluster-ports.conf':
    ensure => present,
    owner => rabbitmq,
    group => rabbitmq,
    source => 'puppet:///modules/rabbitmq/cluster-ports.conf',
    notify => Service['rabbitmq-server'],
    require => Package['rabbitmq-server'],
  }
  
}
