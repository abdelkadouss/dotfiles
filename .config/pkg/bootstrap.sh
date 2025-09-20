#!/bin/sh

# Function to download with wget if available, otherwise use curl
download_file() {
    local url="$1"
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O - "$url"
    else
        curl -L "$url"
    fi
}

# Install dependencies
# prompt the user to use sudo
echo "🚧 Make sure u run this script as root 🚧"

# Set target directory
target_dir="/usr/local/bin"
mkdir -p "$target_dir"

# first get the platform and arch
echo "What platform are you on?"
echo "(linux/macos/windows(i mean really bro, windows!?))"
read -p "platform: " platform
echo "What arch are you on?"
echo "(x86_64/aarch64)"
read -p "arch: " arch

if [ "$platform" != "linux" ] && [ "$platform" != "macos" ] && [ "$platform" != "windows" ]; then
  echo "sorry $platform is not an known platform in this script"
  exit 1
fi

if [ "$arch" != "x86_64" ] && [ "$arch" != "aarch64" ]; then
  echo "sorry $arch is not an known arch in this script"
  exit 1
fi

# 1. Eget[] (of the eget bridge)
if ! command -v pkgx &> /dev/null; then
  echo "Will u looks like u don't have pkgx installed?"
  echo "what u wanna do?"
  read -p "install pkgx? (y/n) " yn
  case $yn in
    [Yy]*)
      curl https://pkgx.sh | sh
      ;;
    *)
      echo "ok i'll not install pkgx"
      ;;
  esac
fi

echo "Ok let's add this stuff to the PATH (for this session only)"
export PATH="$target_dir:$PATH"

echo "Done 🌻, thanks to Allah"
echo "Make sure to add $target_dir to the PATH (in ur shell config)"
