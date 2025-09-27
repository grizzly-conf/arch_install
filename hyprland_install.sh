#!/bin/bash
# Hyprland & Userland Install Script (Root Execution)
set -euo pipefail

USER_NAME="seb"

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
  echo "❌ Bitte direkt als root ausführen (su - oder root login)."
  exit 1
fi

echo "[*] Updating system..."
pacman -Sy --noconfirm

###############################
# 1️⃣ Yay installieren (AUR Helper)
###############################
echo "[*] Installing yay..."
pacman -S --noconfirm --needed git base-devel
sudo -u $USER_NAME git clone https://aur.archlinux.org/yay.git /tmp/yay
(cd /tmp/yay && sudo -u $USER_NAME makepkg -si --noconfirm)
rm -rf /tmp/yay

###############################
# 2️⃣ Basis-Werkzeuge
###############################
echo "[*] Installing core utilities..."
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
    man-pages \
    sudo

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
    mako \
    hyprpicker \
    hypridle \
    hyprlock

# hyprland-community tools (AUR)
sudo -u $USER_NAME yay -S --noconfirm hyprls

###############################
# 5️⃣ Audio (PipeWire + Tools)
###############################
echo "[*] Installing PipeWire audio stack..."
pacman -S --noconfirm \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    wireplumber \
    pavucontrol \
    jack2

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

# impala (AUR)
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
# 🔟 Additional Software (AUR)
###############################
sudo -u $USER_NAME yay -S --noconfirm \
    google-chrome \
    visual-studio-code-bin \
    1password

###############################
# 1️⃣1️⃣ Dotfiles Manager
###############################
echo "[*] Installing dotfiles manager..."
sudo -u $USER_NAME yay -S --noconfirm chezmoi

###############################
# ✅ Done
###############################
echo "🎉 Hyprland environment installation complete!"
echo "Bitte neu starten oder mit systemctl --user enable/start für Services weitermachen."
