# Maintainer: Vítor Vasconcellos <vasconcellos.dev@gmail.com>
pkgname=toggle-git
pkgver=r1.e08f5ea
pkgrel=1
pkgdesc="Simple Bash scripts for toggling camera and mic on/off"
arch=('any')
url="https://github.com/HeavenVolkoff/toggle"
license=('MIT')
depends=('bash>=4' 'libpulse')
optdepends=(
    'libnotify: Notification support'
    'mktrayicon-git: Tray icon support'
)
makedepends=('git')
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
source=("${pkgname}::git+https://github.com/HeavenVolkoff/toggle")
md5sums=('SKIP')

pkgver() {
  cd "$pkgname"
  ( set -o pipefail
    git describe --long 2>/dev/null | sed 's/\([^-]*-g\)/r\1/;s/-/./g' ||
    printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
  )
}

package() {
  local install_dir="${pkgdir}/opt/${pkgname%-git}"

  cd "$pkgname"
  mkdir -p "$install_dir"
  find -type -name "*.sh" -print0 | xargs -r0 -n 1 -I {} cp --parents {} "$install_dir"
  find "$install_dir" -type f -print0 | xargs -r0 chmod 644
  chmod a+x "${install_dir}/mic-toggle.sh" "${install_dir}/camera-toggle.sh"
  ln -s "${install_dir}/mic-toggle.sh" /usr/sbin/mic-toggle
  ln -s "${install_dir}/camera-toggle.sh" /usr/sbin/camera-toggle
  install -Dm644 LICENSE -t "${pkgdir}/usr/share/licenses/$pkgname"
}