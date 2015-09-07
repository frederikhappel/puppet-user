# manage a local system user
define users::local (
  $uid,
  $gid,
  $shell = "/bin/bash",
  $home  = undef,
  $managehome = true,
  $password = undef,
  $ensure = present
) {
  # validate parameters
  validate_integer($uid, $gid)
  validate_absolute_path($shell)
  if $home != undef {
    validate_absolute_path($home)
  }
  validate_bool($managehome)
  validate_string($password)
  validate_re($ensure, '^(present|absent)$')

  # determine home directory
  if $home == undef {
    $userhome = "/home/${name}"
  } else {
    $userhome = $home
  }

  case $ensure {
    present: {
      # create group
      group {
        $name :
          ensure => present,
          gid => $gid,
      }

      # create user
      user {
        $name :
          ensure => present,
          provider => useradd,
          comment => "Puppet ${name}",
          uid => $uid,
          gid => $gid,
          membership => minimum,
          home => $userhome,
          shell => $shell,
          managehome => $managehome,
          password => $password,
          require => Group[$name] ;
      }
    }

    absent: {
      # remove user
      user {
        $name :
          ensure => absent,
          provider => useradd,
          uid => $uid,
          managehome => $managehome ;
      }

      # delete home restlessly
      if $managehome {
        file {
          $userhome :
            ensure => absent,
            recurse => true,
            force => true
        }
      }

      # remove group
      group {
        $name :
          ensure => absent,
          gid => $gid,
          require => User[$name] ;
      }
    }
  }
}
