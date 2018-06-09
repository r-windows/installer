#!/usr/bin/env bash

_thisdir="$(dirname $0)"
test "${_thisdir}" = "." && _thisdir=${PWD}
_arch=$(uname -m)
_date=$(date +'%Y%m%d')
_version=${_date}
_filename2=msys2-base-${_arch}-${_date}.tar.xz
_log=/tmp/installer-${_arch}-${_date}.log
if [ "${_arch}" = "x86_64" ]; then
  _bitness=64
else
  _bitness=32
fi
_newmsysbase=/tmp/newmsys
_newmsys=${_newmsysbase}/msys"${_bitness}"

create_archives() {
  local _dirs=
  for curr_dir in /etc /var /tmp /usr /mingw32 /mingw64 /msys2_shell.cmd /msys2.exe /mingw32.exe /mingw64.exe /msys2.ini /mingw32.ini /mingw64.ini /msys2.ico /autorebase.bat autorebasebase1st.bat; do
    if [[ -d ${_newmsys}${curr_dir} || -f ${_newmsys}${curr_dir} ]]; then
      _dirs="${_dirs} ${_newmsys}$curr_dir"
    fi
  done

  if [ -n "${_dirs}" ]; then
    pushd ${_newmsysbase} > /dev/null
      local _compress_cmd2="/usr/bin/tar --transform='s/:/_/g' --dereference --hard-dereference -cJf ${_thisdir}/${_filename2} msys${_bitness}"
      echo "Run: ${_compress_cmd2} ..." | tee -a ${_log}
      eval "${_compress_cmd2}" 2>&1 | tee -a ${_log}
      _result=$?
      if [ "${_result}" -eq "0" ]; then
            echo " tar succeeded. Created " | tee -a ${_log}
      else
            die "MSYS2 compressing fail. See ${_log}"
      fi
    popd > /dev/null
  fi
}

create_chroot_system() {
  [ -d ${_newmsysbase} ] && rm -rf ${_newmsysbase}
  mkdir -p "${_newmsys}"
  pushd "${_newmsys}" > /dev/null

    mkdir -p var/lib/pacman
    mkdir -p var/log
    mkdir -p tmp

    eval "pacman -Syu --root \"${_newmsys}\"" | tee -a ${_log}
    eval "pacman -S pacman make tar texinfo texinfo-tex patch diffutils gawk zip unzip gzip mingw-w64-{i686,x86_64}-gcc-fortran --noconfirm --root \"${_newmsys}\"" | tee -a ${_log}
    _result=$?
    if [ "${_result}" -ne "0" ]; then
      exit_cleanly "1" "failed to create newmsys2 via command 'pacman -S base --noconfirm --root ${_newmsys}'"
    fi
  popd > /dev/null
}

rm -f "${_log}"
echo "Creating MSYS2 chroot system ${_newmsys}" | tee -a ${_log}
create_chroot_system
create_archives
exit 0
