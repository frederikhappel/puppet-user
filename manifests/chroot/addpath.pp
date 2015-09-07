# add a bind mount in chroot
define users::chroot::addpath (
  $chroot
) {
  # validate parameters
  validate_absolute_path($name)
  validate_absolute_path($chroot)

  # define variables
  $nameClean = regsubst($name, '#', '\\043', 'G')
  $target = "${chroot}${name}"
  $targetClean = "${chroot}${nameClean}"

  # create bind mount in fstab
  augeas {
    "userChrootAddpath_${target}_to_${chroot}" :
      context => "/files/etc/fstab",
      changes => [
          "set 01/spec ${nameClean}",
          "set 01/file ${targetClean}",
          "set 01/vfstype none",
          "set 01/opt[1] bind",
          "set 01/dump 0",
          "set 01/passno 0"
        ],
      onlyif => "match *[file='${targetClean}'] size == 0" ;
  }

  # create and mount mountpoint
  exec {
    "userChrootAddpathMkdir_${target}" :
      command => "mkdir -p ${target}",
      creates => $target,
      require => File[$chroot] ;

    "userChrootAddpathMount_${target}" :
      command => "mount ${target}",
      unless => "mount | grep '[[:blank:]]${target}[[:blank:]]'",
      onlyif => "test -e ${name}",
      require => [
        Exec["userChrootAddpathMkdir_${target}"],
        Augeas["userChrootAddpath_${target}_to_${chroot}"]
      ] ;
  }
}
