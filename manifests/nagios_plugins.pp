# Nagios plugins for rabbitmq
class rabbitmq::nagios_plugins {
  file {
    '/usr/local/lib/nagios/plugins/check_rabbitmq_overview':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/rabbitmq/nagios_plugins/check_rabbitmq_overview',
      require => File['/usr/local/lib/nagios/plugins'];
    '/usr/local/lib/nagios/plugins/check_rabbitmq_aliveness':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      source  => 'puppet:///modules/rabbitmq/nagios_plugins/check_rabbitmq_aliveness',
      require => File['/usr/local/lib/nagios/plugins'];
  }
}
