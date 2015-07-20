# Cluster config for rabbit
class rabbitmq::cluster(
  $cookie,
  $nodes,
  $partition_handling=undef
) inherits rabbitmq {

  File['/etc/rabbitmq/rabbitmq.config'] {
    content => template('rabbitmq/rabbitmq-cluster.config.erb'),
  }

  file {'/etc/rabbitmq/rabbitmq.conf.d/cluster-ports.conf':
    ensure  => present,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0644',
    source  => 'puppet:///modules/rabbitmq/cluster-ports.conf',
    require => Package['rabbitmq-server'],
  }

  file {'/var/lib/rabbitmq/.erlang.cookie':
    ensure  => present,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0400',
    content => $cookie,
    require => Package['rabbitmq-server'],
  }

  $cluster_hosts = hiera('firewall::rabbit_cluster_hosts', [])

  nectar::firewall::multisource {[ prefix($cluster_hosts, '200 rabbitcluster,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => '4369',
  }
  nectar::firewall::multisource {[ prefix($cluster_hosts, '200 rabbitcluster-multi,') ]:
    action => 'accept',
    proto  => 'tcp',
    dport  => '40000-41000',
  }
}
