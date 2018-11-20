# Installs rabbitmq repo
class rabbitmq::repo {

  if $::http_proxy and str2bool($::rfc1918_gateway) {
    $key_options = "http-proxy=${::http_proxy}"
  } else {
    $key_options = undef
  }

  apt::key { 'rabbitmq':
    id      => '0A9AF2115F4687BD29803A206B73A36E6026DFCA',
    server  => 'keyserver.ubuntu.com',
    options => $key_options,
  }

  apt::source {'rabbitmq':
    comment  => 'Erlang',
    location => 'http://dl.bintray.com/rabbitmq/debian',
    release  => $::lsbdistcodename,
    repos    => 'erlang-20.x rabbitmq-server'
  }
}
