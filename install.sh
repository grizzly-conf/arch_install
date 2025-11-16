#!/bin/bash
# Arch Linux Full Installation Script
# !!! ACHTUNG: Dieses Skript löscht alle Daten auf den angegebenen Partitionen !!!

set -euo pipefail

##########################
# ⚠️ CONFIGURATION
##########################

ROOT_DISK="/dev/nvme0n1"
HOME_DISK="/dev/nvme1n1"
EFI_SIZE="2GiB"
USERNAME="seb"
HOSTNAME="archhome"
TIMEZONE="Europe/Berlin"
LANG="en_US.UTF-8"        # Systemsprache
KEYMAP="de-latin1"        # Tastaturlayout
SWAP_SIZE="8G"            # Swapfile

##########################
# 1️⃣ PARTITIONIERUNG
##########################

echo "!!! ⚠️ ACHTUNG: ALLE DATEN AUF $ROOT_DISK UND $HOME_DISK WERDEN GELÖSCHT !!!"

echo "⚠️ Partitionierung startet in 5 Sekunden..."
sleep 5

# ROOT Disk
parted "$ROOT_DISK" --script mklabel gpt
parted "$ROOT_DISK" --script mkpart ESP fat32 1MiB "$EFI_SIZE"
parted "$ROOT_DISK" --script set 1 esp on
parted "$ROOT_DISK" --script mkpart primary ext4 "$EFI_SIZE" 100%

# HOME Disk
parted "$HOME_DISK" --script mklabel gpt
parted "$HOME_DISK" --script mkpart primary ext4 1MiB 100%

# Filesystem erstellen
mkfs.fat -F32 "${ROOT_DISK}p1"
mkfs.ext4 -F "${ROOT_DISK}p2"
mkfs.ext4 -F "${HOME_DISK}p1"

##########################
# 2️⃣ MOUNTEN
##########################

mount "${ROOT_DISK}p2" /mnt
mkdir -p /mnt/boot /mnt/home
mount "${ROOT_DISK}p1" /mnt/boot
mount "${HOME_DISK}p1" /mnt/home

##########################
# 3️⃣ BASIS-SYSTEM INSTALLIEREN
##########################

# Keyring initialisieren in Live-Umgebung
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# Basis installieren
pacstrap /mnt base linux linux-firmware vim efibootmgr base-devel man-db man-pages bash-completion which wget curl htop usbutils pciutils git

# fstab generieren
genfstab -U /mnt >> /mnt/etc/fstab

##########################
# 4️⃣ SYSTEM KONFIGURATION (CHROOT)
##########################

arch-chroot /mnt /bin/bash <<EOF
# Keyring initialisieren innerhalb chroot
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# Zeitzone und Uhr
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true || true

# Locale
echo "LANG=$LANG" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# Keymap
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname & hosts
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Root-Passwort
echo "root:s3bR00T" | chpasswd

# Standarduser mit wheel-Gruppe
useradd -m -G wheel -s /bin/bash $USERNAME
echo "seb:s3b" | chpasswd

# Sudo-Rechte für wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# NetworkManager installieren & aktivieren
pacman -S --noconfirm networkmanager
systemctl enable NetworkManager

# OpenSSH installieren & aktivieren
pacman -S --noconfirm openssh
systemctl enable sshd
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config
echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

# systemd-boot installieren
bootctl --path=/boot install

# Initramfs erstellen
mkinitcpio -P

# Bootloader Einträge
UUID_ROOT=\$(blkid -s UUID -o value ${ROOT_DISK}p2)

cat <<ARCH > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=\$UUID_ROOT rw
ARCH

cat <<FALLBACK > /boot/loader/entries/arch-fallback.conf
title   Arch Linux Fallback
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=UUID=\$UUID_ROOT rw
FALLBACK

# EFI NVRAM Eintrag sichern
efibootmgr -c -d $ROOT_DISK -p 1 -L "Arch Linux" -l '\EFI\systemd\systemd-bootx64.efi' || true
EOF

##########################
# 5️⃣ TREIBER & GAMING
##########################

arch-chroot /mnt /bin/bash <<EOF
# Multilib aktivieren
sed -i '/#\\[multilib\\]/,/#Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# NVIDIA & Vulkan
pacman -S --noconfirm linux-headers nvidia-dkms nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader

# NVIDIA DRM Modeset aktivieren
echo "options nvidia_drm modeset=1" > /etc/modprobe.d/nvidia.conf

# mkinitcpio.conf anpassen
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf

mkinitcpio -P

# Gaming Tools
pacman -S --noconfirm steam steam-native-runtime lutris mangohud vulkan-tools
EOF

##########################
# 6️⃣ SWAPFILE ERSTELLEN
##########################

arch-chroot /mnt /bin/bash <<EOF
fallocate -l $SWAP_SIZE /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
EOF

echo "🎉 Installation abgeschlossen! Bitte neu booten."
