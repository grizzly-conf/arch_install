#!/bin/bash
set -e

echo "[*] Updating system..."
pacman -Syu --noconfirm

echo "[*] Installing core environment..."
pacman -S --noconfirm \
    base-devel \
    git \
    wget \
    curl \
    unzip \
    zip \
    man-db \
    man-pages \
    sudo \
    vim

echo "[*] Installing fonts..."
pacman -S --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-dejavu \
    ttf-jetbrains-mono-nerd \
    ttf-fira-code-nerd

echo "[*] Installing terminal + shell utilities..."
pacman -S --noconfirm \
    alacritty \
    zsh \
    zsh-completions \
    tmux \
    fzf \
    ripgrep \
    fd \
    bat \
    exa \
    neovim

chsh -s /bin/zsh

echo "[*] Installing file manager..."
# Yazi wird über AUR installiert
pacman -S --noconfirm \
    ueberzugpp \
    imagemagick

# AUR: yazi
if ! command -v yay &>/dev/null; then
  echo "[*] Installing yay (AUR helper)..."
  cd /opt
  git clone https://aur.archlinux.org/yay-bin.git
  chown -R $(logname):$(logname) yay-bin
  cd yay-bin
  sudo -u $(logname) makepkg -si --noconfirm
  cd ..
fi

sudo -u $(logname) yay -S --noconfirm yazi

echo "[*] Installing Wayland + Hyprland stack..."
pacman -S --noconfirm \
    wayland \
    wlroots \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal-hyprland \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle

echo "[*] Installing notification daemon..."
pacman -S --noconfirm \
    mako \
    libnotify

echo "[*] Installing status bar..."
pacman -S --noconfirm \
    waybar

# Eww (optional, AUR)
sudo -u $(logname) yay -S --noconfirm eww

echo "[*] Installing audio stack..."
pacman -S --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol

# wiremix (AUR)
sudo -u $(logname) yay -S --noconfirm wiremix

echo "[*] Installing polkit agent..."
pacman -S --noconfirm \
    polkit \
    lxqt-policykit

# (Hyprpolkitagent wenn du unbedingt Hypr-eigen willst, sonst lxqt-policykit ist stabiler)
# sudo -u $(logname) yay -S --noconfirm hyprpolkitagent

echo "[*] Installing blue light filter..."
pacman -S --noconfirm \
    wlsunset

# Hyprsunset (AUR optional)
# sudo -u $(logname) yay -S --noconfirm hyprsunset

echo "[*] Installing clipboard manager..."
pacman -S --noconfirm \
    wl-clipboard \
    cliphist

echo "[*] Installing launcher..."
pacman -S --noconfirm \
    rofi \
    rofi-emoji

# Optional: wofi
# pacman -S --noconfirm wofi

echo "[*] Installing dotfiles manager..."
sudo -u $(logname) yay -S --noconfirm chezmoi

echo "[*] Installing wireless utilities..."
pacman -S --noconfirm \
    networkmanager \
    network-manager-applet \
    nm-connection-editor \
    iwd

# Optional: Overskride (AUR, experimentell)
# sudo -u $(logname) yay -S --noconfirm overskride

echo "[*] Enabling services..."
systemctl enable NetworkManager
systemctl enable bluetooth.service || true
systemctl enable systemd-timesyncd

echo "[*] Done!"
