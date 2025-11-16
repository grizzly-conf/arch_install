#!/usr/bin/env bash
set -euo pipefail

# Configuration
EFI_SIZE="1GiB"
USERNAME="seb"
HOSTNAME="anyLAPTOP-62"
TIMEZONE="Europe/Berlin"
LANG="en_US.UTF-8"
KEYMAP="de-latin1"
SWAP_SIZE="8G"

# allow override: ./install.sh /dev/sda
ROOT_DISK="/dev/nvme0n1"

# Partitioning (single NVMe: EFI / ROOT / HOME)
parted "$ROOT_DISK" --script mklabel gpt
parted "$ROOT_DISK" --script mkpart ESP fat32 1MiB "$EFI_SIZE"
parted "$ROOT_DISK" --script set 1 esp on
parted "$ROOT_DISK" --script mkpart primary ext4 "$EFI_SIZE" 40%
parted "$ROOT_DISK" --script mkpart primary ext4 40% 100%

# Filesystems
mkfs.fat -F32 "${ROOT_DISK}p1"
mkfs.ext4 -F "${ROOT_DISK}p2"
mkfs.ext4 -F "${ROOT_DISK}p3"

# Mount
mount "${ROOT_DISK}p2" /mnt
mkdir -p /mnt/boot /mnt/home
mount "${ROOT_DISK}p1" /mnt/boot
mount "${ROOT_DISK}p3" /mnt/home

# Keyring & basic packages in live environment
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

pacstrap /mnt base linux linux-firmware amd-ucode vim efibootmgr base-devel man-db man-pages bash-completion which wget curl htop usbutils pciutils git

genfstab -U /mnt >> /mnt/etc/fstab

# Chroot configuration
arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# timezone & clock
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc --utc
timedatectl set-ntp true || true

# locale
echo "LANG=$LANG" > /etc/locale.conf
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# keymap
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# hostname & hosts
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME.localdomain $HOSTNAME
HOSTS

# passwords (replace if needed)
echo "root:s3b" | chpasswd
useradd -m -G wheel -s /bin/bash $USERNAME
echo "s3b" | chpasswd

# sudo wheel
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# network & ssh
pacman -S --noconfirm networkmanager openssh
systemctl enable NetworkManager
systemctl enable sshd
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config || true
sed -i 's/^PasswordAuthentication no/#PasswordAuthentication no/' /etc/ssh/sshd_config || true
echo "AllowUsers $USERNAME" >> /etc/ssh/sshd_config

# bootloader: systemd-boot with amd microcode
bootctl --path=/boot install

UUID_ROOT=\$(blkid -s UUID -o value ${ROOT_DISK}p2)

cat <<ARCH > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux.img
options root=UUID=\$UUID_ROOT rw
ARCH

cat <<FALLBACK > /boot/loader/entries/arch-fallback.conf
title   Arch Linux Fallback
linux   /vmlinuz-linux
initrd  /amd-ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID=\$UUID_ROOT rw
FALLBACK

efibootmgr -c -d $ROOT_DISK -p 1 -L "Arch Linux" -l '\EFI\systemd\systemd-bootx64.efi' || true

# mkinitcpio (generate with amd microcode)
mkinitcpio -P

EOF

# Graphics/Multimedia & laptop-specific packages (AMD integrated GPU)
arch-chroot /mnt /bin/bash <<EOF
set -euo pipefail

# enable multilib if needed
sed -i '/#\\[multilib\\]/,/#Include/ s/^#//' /etc/pacman.conf || true
pacman -Sy --noconfirm

# GPU, Vulkan, audio, and laptop firmware
pacman -S --noconfirm mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon libdrm mesa-vdpau sof-firmware linux-headers

# gaming stack (optional in original script; adapted for AMD)
pacman -S --noconfirm steam lutris mangohud vulkan-tools

# power and ACPI helpers
pacman -S --noconfirm tlp acpid
systemctl enable tlp
systemctl enable acpid

# regenerate initramfs to include AMD microcode already handled; ensure amd-ucode present
mkinitcpio -P
EOF

# swapfile
arch-chroot /mnt /bin/bash <<EOF
fallocate -l $SWAP_SIZE /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile none swap defaults 0 0" | tee -a /etc/fstab
EOF

echo "Installation script completed."
