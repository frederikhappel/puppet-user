# class for user management
class users {
  # package management
  package {
    "sudo" :
      ensure => latest ;
  }

  # create sudo related file resources
  File {
    owner => 0,
    group => 0,
  }
  file {
    "/etc/sudoers" :
      content => template("user/sudoers.erb"),
      mode => "0440" ;

    "/etc/sudoers.d" :
      ensure => directory,
      mode => "0770" ;
  }
}
