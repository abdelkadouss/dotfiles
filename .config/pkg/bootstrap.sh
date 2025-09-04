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
if ! command -v eget &> /dev/null; then
  echo "Will u looks like u don't have eget installed?"
  echo "what u wanna do?"
  read -p "install eget? (y/n) " yn
  case $yn in
    [Yy]*)
      case $platform in
        linux)
          if [ "$arch" = "x86_64" ]; then
            download_file "https://github.com/zyedidia/eget/releases/download/v1.3.4/eget-1.3.4-linux_amd64.tar.gz" | tar -xz
          else
            download_file "https://github.com/zyedidia/eget/releases/download/v1.3.4/eget-1.3.4-linux_arm64.tar.gz" | tar -xz
          fi
          ;;
        macos)
          if [ "$arch" = "x86_64" ]; then
            download_file "https://github.com/zyedidia/eget/releases/download/v1.3.4/eget-1.3.4-darwin_amd64.tar.gz" | tar -xz
          else
            download_file "https://github.com/zyedidia/eget/releases/download/v1.3.4/eget-1.3.4-darwin_arm64.tar.gz" | tar -xz
          fi
          ;;
        windows)
          if [ "$arch" = "x86_64" ]; then
            download_file "https://github.com/zyedidia/eget/releases/download/v1.3.4/eget-1.3.4-windows_amd64.zip" | unzip - 
          else
            echo "sorry windows arm64 is not supported"
          fi
          ;;
      esac
      local os
      if [ "$platform" = "linux" ]; then
        os="linux"
      elif [ "$platform" = "macos" ]; then
        os="darwin"
      elif [ "$platform" = "windows" ]; then
        os="windows"
      fi
      local art
      if [ "$arch" = "x86_64" ]; then
        arch="amd64"
      elif [ "$arch" = "aarch64" ]; then
        arch="arm64"
      fi
      mv "eget-1.3.4-$os_$art" "$target_dir/eget"
      rm -rf "eget-1.3.4-$os_$art"
      ;;
    *)
      echo "ok i'll not install eget"
      ;;
  esac
fi

# 2. Install Rust toolchain
if ! command -v rustup &> /dev/null; then
  echo -e "Will u looks like u don't have rust installed?\n"
  echo "what u wanna do?"
  read -p "install rust? (y/n) " yn
  case $yn in
    [Yy]*)
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      ;;
    *)
      echo "ok i'll not install rust"
      ;;
  esac
fi

# 3. cargo-binstall[] (of the cargo bridge)
if ! command -v cargo &> /dev/null; then
  echo "where u installed cargo ?"
  read -p "(default: ~/.cargo/bin/cargo) " cargo_path
  if [ -z "$cargo_path" ]; then
    cargo_path="$HOME/.cargo/bin/cargo"
  fi
else 
  cargo_path=$(command -v cargo)
fi

if ! command -v "$cargo_path" &> /dev/null; then
  echo "Will u looks like u just pass a wrong path, check the path and try again?"
else
  echo "Will u looks like u don't have cargo-binstall installed?"
  echo "what u wanna do?"
  read -p "install cargo-binstall? (y/n) " yn
  case $yn in
    [Yy]*)
      "$cargo_path" install cargo-binstall --root "$target_dir"
      if [ -f "$target_dir/bin/cargo-binstall" ]; then
        mv "$target_dir/bin/cargo-binstall" "$target_dir/cargo-binstall"
      fi
      ;;
    *)
      echo "ok i'll not install cargo-binstall"
      ;;
  esac
fi

echo "Ok let's add this stuff to the PATH (for this session only)"
export PATH="$target_dir:$PATH"

echo "Done 🌻, thanks to Allah"
echo "Make sure to add $target_dir to the PATH (in ur shell config)"
