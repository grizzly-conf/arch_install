#!/bin/bash
# Arch Linux Full Installation Script
# !!! ACHTUNG: Dieses Skript löscht alle Daten auf den angegebenen Partitionen !!!

set -euo pipefail

##########################
# ⚠️ CONFIGURATION
##########################

ROOT_DISK="/dev/nvme0n1"
HOME_DISK="/dev/nvme1n1"
EFI_SIZE="512MiB"
USERNAME="seb"
HOSTNAME="archhome"
TIMEZONE="Europe/Berlin"
LANG="en_US.UTF-8"
LOCALE="en_US.UTF-8"
KEYMAP="de-latin1"        # Tastaturlayout
SWAP_SIZE="8G"            # Größe des Swapfiles

##########################
# 1️⃣ PARTITIONIERUNG
##########################

echo "!!! ACHTUNG: ALLE DATEN WERDEN GELÖSCHT !!!"
read -p "Willst du fortfahren? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Abgebrochen"
    exit 1
fi

# ROOT Disk
parted $ROOT_DISK --script mklabel gpt
parted $ROOT_DISK --script mkpart ESP fat32 1MiB $EFI_SIZE
parted $ROOT_DISK --script set 1 esp on
parted $ROOT_DISK --script mkpart primary ext4 $EFI_SIZE 100%

# HOME Disk
parted $HOME_DISK --script mklabel gpt
parted $HOME_DISK --script mkpart primary ext4 1MiB 100%

# Filesystem
mkfs.fat -F32 "${ROOT_DISK}p1"
mkfs.ext4 "${ROOT_DISK}p2"
mkfs.ext4 "${HOME_DISK}p1"

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

pacstrap /mnt base linux linux-firmware vim

genfstab -U /mnt >> /mnt/etc/fstab

##########################
# 4️⃣ SYSTEM KONFIGURATION
##########################
arch-chroot /mnt /bin/bash <<EOF
# Keyring initialisieren innerhalb chroot
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# Zeitzone
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale
echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LANG" > /etc/locale.conf

# Tastaturlayout
localectl set-keymap $KEYMAP

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Root-Passwort
echo "root:archlinux" | chpasswd

# Standarduser
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:archlinux" | chpasswd

# Sudo Gruppe erstellen und Benutzer hinzufügen
groupadd sudo
usermod -aG sudo $USERNAME
pacman -S --noconfirm sudo
echo "%sudo ALL=(ALL) ALL" > /etc/sudoers.d/sudo-group
chmod 440 /etc/sudoers.d/sudo-group

# systemd-boot installieren
bootctl --path=/boot install

# Haupt-Entry
UUID_ROOT=\$(blkid -s UUID -o value ${ROOT_DISK}p2)
cat <<ARCH > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=\$UUID_ROOT rw
ARCH

# Fallback-Entry
cat <<FALLBACK > /boot/loader/entries/arch-fallback.conf
title   Arch Linux Fallback
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options root=UUID=\$UUID_ROOT rw
FALLBACK

EOF

##########################
# 5️⃣ TREIBER & GAMING
##########################
arch-chroot /mnt /bin/bash <<EOF

# Multilib aktivieren
sed -i '/#\\[multilib\\]/,/#Include/ s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

# NVIDIA & Vulkan
pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils vulkan-icd-loader lib32-vulkan-icd-loader

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

# Persistente Eintragung in fstab
echo "/swapfile none swap defaults 0 0" >> /etc/fstab

EOF

echo "🎉 Installation abgeschlossen! Bitte chroot verlassen und neu booten."
