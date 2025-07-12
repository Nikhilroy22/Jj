TERMUX_PKG_HOMEPAGE=https://www.gnu.org/software/bash/
TERMUX_PKG_DESCRIPTION="My custom Bash build for Termux"
TERMUX_PKG_LICENSE="GPL-3.0"
TERMUX_PKG_MAINTAINER="Nikhil Roy <your@email.com>"

_MAIN_VERSION=5.3
_PATCH_VERSION=0
TERMUX_PKG_VERSION=${_MAIN_VERSION}
TERMUX_PKG_SRCURL=https://mirrors.kernel.org/gnu/bash/bash-${_MAIN_VERSION}.tar.gz
TERMUX_PKG_SHA256=62dd49c44c399ed1b3f7f731e87a782334d834f08e098a35f2c87547d5dbb269

TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libiconv, readline (>= 8.3), termux-tools"
TERMUX_PKG_BREAKS="bash-dev"
TERMUX_PKG_REPLACES="bash-dev"
TERMUX_PKG_ESSENTIAL=true
TERMUX_PKG_BUILD_IN_SRC=true

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
  --enable-multibyte
  --without-bash-malloc
  --with-installed-readline
  --enable-progcomp
  bash_cv_job_control_missing=present
  bash_cv_sys_siglist=yes
  bash_cv_func_sigsetjmp=present
  bash_cv_unusable_rtsigs=no
  ac_cv_func_mbsnrtowcs=no
  bash_cv_dev_fd=whacky
  bash_cv_getcwd_malloc=yes
"

TERMUX_PKG_CONFFILES="etc/bash.bashrc etc/profile"
TERMUX_PKG_RM_AFTER_INSTALL="share/man/man1/bashbug.1 bin/bashbug"

termux_step_pre_configure() {
  (( _PATCH_VERSION == 0 )) && return
  local PATCH_NUM PATCHFILE
  local -A PATCH_CHECKSUMS=()
  for PATCH_NUM in $(seq -f '%03g' "${_PATCH_VERSION}"); do
    PATCHFILE=$TERMUX_PKG_CACHEDIR/bash_patch_${PATCH_NUM}.patch
    termux_download \
      "https://mirrors.kernel.org/gnu/bash/bash-${_MAIN_VERSION}-patches/bash${_MAIN_VERSION/./}-$PATCH_NUM" \
      "$PATCHFILE" \
      "${PATCH_CHECKSUMS[$PATCH_NUM]}"
    patch -p0 -i "$PATCHFILE"
  done
}

termux_step_post_make_install() {
  # Replace bash binary with custom name if needed
  cp $TERMUX_PREFIX/bin/bash $TERMUX_PREFIX/bin/mybash

  # Generate /etc/profile
  sed -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
      "$TERMUX_PKG_BUILDER_DIR/etc-profile" > "$TERMUX_PREFIX/etc/profile"

  # Generate system-wide bashrc
  sed -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" \
      "$TERMUX_PKG_BUILDER_DIR/etc-bash.bashrc" > "$TERMUX_PREFIX/etc/bash.bashrc"
}