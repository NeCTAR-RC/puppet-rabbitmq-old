class rabbitmq::cluster($cookie, $nodes) inherits rabbitmq {

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

  file {'/var/lib/rabbitmq/.erlang.cookie':
    ensure  => present,
    owner   => rabbitmq,
    group   => rabbitmq,
    mode    => '0400',
    content => $cookie,
    notify  => Service['rabbitmq-server'],
    require => Package['rabbitmq-server'],
  }

  $cluster_hosts = hiera('firewall::rabbit_cluster_hosts', [])
  
  firewall::multisource {[ prefix($cluster_hosts, '200 rabbitcluster,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => '4369',
  }
  firewall::multisource {[ prefix($cluster_hosts, '200 rabbitcluster-multi,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => '40000-41000',
  }
}
