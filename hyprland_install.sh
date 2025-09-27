#!/bin/bash
# Hyprland & Userland Install Script
# Fortführung nach Arch Basisinstallation (arch-chroot /mnt)


# Check if root
if [ "$EUID" -eq 0 ]; then
  echo "❌ Bitte nicht als root starten. Melde dich als dein User an und führe das Script dort aus."
  exit 1
fi

set -euo pipefail

USER_NAME=$(logname)

echo "[*] Updating package databases..."
pacman -Sy --noconfirm

###############################
# 1️⃣ Yay installieren (AUR Helper)
###############################
echo "[*] Installing yay (AUR helper)..."
pacman -S --noconfirm --needed git base-devel
sudo -u $USER_NAME git clone https://aur.archlinux.org/yay.git /tmp/yay
(cd /tmp/yay && sudo -u $USER_NAME makepkg -si --noconfirm)
rm -rf /tmp/yay

###############################
# 2️⃣ Basis-Werkzeuge
###############################
echo "[*] Installing base tools..."
pacman -S --noconfirm \
    zsh \
    alacritty \
    ripgrep \
    fd \
    bat \
    exa \
    vim \
    wget \
    curl \
    unzip \
    zip \
    gzip \
    tar \
    openssh \
    htop \
    btop \
    man-db \
    man-pages

chsh -s /bin/zsh $USER_NAME

###############################
# 3️⃣ Fonts
###############################
echo "[*] Installing fonts..."
pacman -S --noconfirm \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-nerd-fonts-symbols

###############################
# 4️⃣ Hyprland & Ecosystem
###############################
echo "[*] Installing Hyprland + ecosystem..."
pacman -S --noconfirm \
    hyprland \
    xdg-desktop-portal-hyprland \
    qt5-wayland \
    qt6-wayland \
    waybar \
    rofi \
    rofi-emoji \
    dunst \
    wl-clipboard \
    cliphist \
    grim \
    slurp \
    hyprpicker \
    mako \
    hypridle \
    hyprlock

# hyprland-community tools (AUR)
sudo -u $USER_NAME yay -S --noconfirm hyprls

###############################
# 5️⃣ Audio (PipeWire + Tools)
###############################
echo "[*] Installing PipeWire..."
pacman -S --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    wireplumber \
    pavucontrol

# wiremix (AUR)
sudo -u $USER_NAME yay -S --noconfirm wiremix

###############################
# 6️⃣ Network & Wireless
###############################
echo "[*] Installing network utilities..."
pacman -S --noconfirm \
    networkmanager \
    nm-connection-editor \
    iwd \
    bluez \
    bluez-utils

systemctl enable NetworkManager
systemctl enable bluetooth.service

# impala (AUR - minimal GUI für NetworkManager)
sudo -u $USER_NAME yay -S --noconfirm impala

###############################
# 7️⃣ Authentication Agent
###############################
echo "[*] Installing polkit..."
pacman -S --noconfirm \
    polkit \
    lxqt-policykit

###############################
# 8️⃣ Extras: Screenshots, Sharing, Wallpaper
###############################
echo "[*] Installing screenshot/recording tools..."
pacman -S --noconfirm \
    obs-studio

# Wallpapers (AUR)
sudo -u $USER_NAME yay -S --noconfirm wallrizz

###############################
# 9️⃣ Virtualization / Container
###############################
echo "[*] Installing virtualization tools..."
pacman -S --noconfirm \
    docker \
    docker-compose

sudo -u $USER_NAME yay -S --noconfirm lazydocker

systemctl enable docker
usermod -aG docker $USER_NAME

###############################
# 🔟 Dotfiles Manager
###############################
echo "[*] Installing dotfiles manager..."
sudo -u $USER_NAME yay -S --noconfirm chezmoi

###############################
# ✅ Done
###############################
echo "🎉 Hyprland environment installation complete!"
echo "Bitte neu starten oder mit systemctl --user enable/start für Services weitermachen."
