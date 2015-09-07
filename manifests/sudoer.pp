# define a sudoer
define users::sudoer (
  $user,
  $host = 'ALL',
  $command = 'ALL',
  $tag = 'NOPASSWD',
  $runas = 'ALL',
  $defaults = undef,
  $ensure = present
) {
  # validate parameters
  if $user == undef or (!is_string($user) and !is_array($user)) {
    fail('parameter $user has to be of type string or array')
  } elsif $host == undef or (!is_string($host) and !is_array($host)) {
    fail('parameter $host has to be of type string or array')
  } elsif $command == undef or (!is_string($command) and !is_array($command)) {
    fail('parameter $command has to be of type string or array')
  } elsif $runas == undef or (!is_string($runas) and !is_array($runas)) {
    fail('parameter $runas has to be of type string or array')
  }
  validate_string($defaults)
  validate_re($tag, '^(NO|)(PASSWD|EXEC|SETENV|LOG_INPUT|LOG_OUTPUT)$')
  validate_re($ensure, '^(present|absent)$')

  # include baseclass
  include users

  # create sudoers file
  file {
    "/etc/sudoers.d/${name}" :
      ensure => $ensure,
      content => template('user/sudoers.d.erb'),
      owner => 0,
      group => 0,
      mode => '0440' ;
  }
}
