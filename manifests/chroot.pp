# create a chrooted local user
define users::chroot (
  $guid,
  $binaries = [],
  $paths = [],
  $xterm = false,
  $sshppk = undef,
  $ensure = present
) {
  # validate parameters
  validate_integer($guid)
  validate_array($binaries, $paths)
  validate_bool($xterm)
  validate_string($sshppk)
  validate_re($ensure, '^(present|absent)$')

  # define variables
  $userhome = "/home/${name}"
  $chroot = "${userhome}/chroot"
  $chrooteduserhome = "${chroot}${userhome}"
  $default_binaries = ['bash', 'ls', 'cat', 'less', 'tail', 'more', '/lib64/libnss_files.so.2']

  # package management
  # TODO: yum repo ['dag']
  package {
    'jailkit' :
      ensure => latest ; # repo dag
  }

  case $ensure {
    present: {
      file {
        [ $userhome, $chroot ] :
          ensure  => directory,
          mode => '0555' ;
      }

      # home-structure
      exec {
        "recursivelyCreate_${chrooteduserhome}" :
          command => "mkdir -p ${chrooteduserhome}",
          unless => "test -d ${chrooteduserhome}" ;
      }

      # create user
      users::local {
        $name :
          uid => $guid,
          gid => $guid,
          shell => '/usr/sbin/jk_chrootsh',
          home => "${chroot}/.${userhome}",
          require => Exec["recursivelyCreate_${chrooteduserhome}"] ;
      }

      file {
        $chrooteduserhome :
          ensure => directory,
          owner => $guid,
          group => $guid,
          mode => '0755',
          require => [
            Exec["recursivelyCreate_${chrooteduserhome}"],
            Users::Local[$name]
          ] ;
      }

      # ssh configuration
      if $sshppk != undef {
        # define ssh private key if given
        file {
          "${chrooteduserhome}/.ssh" :
            ensure => directory,
            owner => $guid,
            group => $guid,
            mode => '0700',
            require => Users::Local[$name] ;

          "${chrooteduserhome}/.ssh/id_rsa" :
            content => $sshppk,
            owner => $guid,
            group => $guid,
            mode => '0600',
            require => Users::Local[$name] ;
        }
      }

      file {
        "${chrooteduserhome}/.bashrc" :
          content => template('user/bashrc.erb'),
          require => Users::Local[$name] ;
      }

      # dev-structure
      file { "${chroot}/dev":
        ensure  => directory,
        mode    => '0555',
        require => File[$chroot]
      }

      exec {
        "${chroot}/dev/null" :
          command => "mknod -m666 ${chroot}/dev/null c 1 3",
          cwd => '/tmp',
          unless => "test -e ${chroot}/dev/null",
          require => File["${chroot}/dev"] ;

        "${chroot}/dev/zero" :
          command => "mknod -m666 ${chroot}/dev/zero c 1 5",
          cwd => '/tmp',
          unless => "test -e ${chroot}/dev/zero",
          require => File["${chroot}/dev"] ;
      }

      # etc-structure
      file {
        "${chroot}/etc" :
          ensure => directory,
          mode => '0755',
          require => File[$chroot] ;

        "${chroot}/etc/passwd" :
          content => template('user/passwd.erb') ;

        "${chroot}/etc/group" :
          content => template('user/group.erb') ;
      }

      # add binaries to CHROOT
      users::chroot::addbin {
        $default_binaries :
          chroot => $chroot
      }
      if !empty($binaries) {
        users::chroot::addbin {
          $binaries :
            chroot => $chroot
        }
      }

      # add paths to CHROOT
      if !empty($paths) {
        users::chroot::addpath {
          $paths :
            chroot => $chroot ;
        }
      }

      # XTERM
      if $xterm {
        file {
          "${chroot}/usr/share/terminfo/x" :
            ensure  => directory,
            mode    => '0755',
            recurse => true ;
        }

        exec {
          "${chroot}/usr/share/terminfo/x/xterm" :
            command => "jk_cp -j ${chroot} /usr/share/terminfo/x/xterm",
            unless  => "test -f ${chroot}/usr/share/terminfo/x/xterm",
            require => [
              Package['jailkit'],
              File[$chroot]
            ] ;
        }
      }
    }

    absent: {
      # delete user
      users::local {
        $name :
          ensure => absent,
          uid => $guid,
          gid => $guid,
          home => $chrooteduserhome ;
      }

      # remove everything
      file {
        $userhome :
          ensure => absent,
          recurse => true,
          force => true ;
      }
    }
  }
}
