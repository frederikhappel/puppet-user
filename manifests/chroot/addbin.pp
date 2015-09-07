# add a binary to chroot
define users::chroot::addbin (
  $chroot
) {
  # validate parameters
  validate_absolute_path($chroot)

  # copy binary to chroot
  exec {
    "${chroot}_${name}":
      command => "jk_cp -j ${chroot} `which --skip-alias --skip-functions ${name}`",
      unless => "test -f ${chroot}`which --skip-alias --skip-functions ${name}`",
      onlyif => "which --skip-alias --skip-functions ${name}",
      path => "/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin",
      require => [
        Package["jailkit"],
        File[$chroot]
      ] ;
  }

  # needed for ssh-package
  if $name == "ssh" {
    exec {
      "${chroot}/dev/urandom" :
        command => "mknod -m444 ${chroot}/dev/urandom c 1 9",
        cwd => "/tmp",
        unless => "test -e ${chroot}/dev/urandom",
        require => File["${chroot}/dev"] ;

      "${chroot}/dev/tty" :
        command => "mknod -m666 ${chroot}/dev/tty c 5 0",
        cwd => "/tmp",
        unless => "test -e ${chroot}/dev/tty",
        require => File["${chroot}/dev"] ;
    }
  }
}
