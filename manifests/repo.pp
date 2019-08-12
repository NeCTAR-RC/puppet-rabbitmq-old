# Installs rabbitmq repo
class rabbitmq::repo(
  $use_https = false,
  $erlang_version = '20',
){

  if $::http_proxy and str2bool($::rfc1918_gateway) {
    $key_options = "http-proxy=${::http_proxy}"
  } else {
    $key_options = undef
  }

  if $use_https {
    $proto = 'https'

    package { 'apt-transport-https':
      ensure => present,
    }

  } else {
    $proto = 'http'
  }

  apt::key { 'rabbitmq':
    id      => '0A9AF2115F4687BD29803A206B73A36E6026DFCA',
    server  => 'keyserver.ubuntu.com',
    options => $key_options,
  }

  apt::source {'rabbitmq':
    comment  => 'RabbitMQ',
    location => "${proto}://dl.bintray.com/rabbitmq/debian",
    release  => $::lsbdistcodename,
    repos    => 'main'
  }

  apt::source {'rabbitmq-erlang':
    comment  => 'Erlang',
    location => "${proto}://dl.bintray.com/rabbitmq-erlang/debian",
    release  => $::lsbdistcodename,
    repos    => "erlang-${erlang_version}.x"
  }
}
