#!/bin/bash
# Script: EFI/Boot Partition vergrößern (NVMe, FAT32)
# !!! Backup vorher erstellen !!!

set -euo pipefail

ROOT_DISK="/dev/nvme1n1"
EFI_PART="1"      # Nummer der EFI-Partition
NEW_SIZE="2GiB"   # Neue Größe der EFI-Partition (mind. 1GiB empfohlen)

echo "💡 Prüfe aktuelle Partitionen..."
lsblk -f $ROOT_DISK

echo "💡 Prüfe freien Platz direkt nach EFI..."
parted $ROOT_DISK print free

read -p "Willst du die EFI-Partition $EFI_PART auf $NEW_SIZE vergrößern? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Abgebrochen"
    exit 1
fi

echo "🔧 Resize Partition..."
sudo parted $ROOT_DISK --script resizepart $EFI_PART $NEW_SIZE

echo "💾 Resize FAT32 Dateisystem..."
sudo fatresize -s $NEW_SIZE "${ROOT_DISK}p${EFI_PART}"

echo "✅ Fertig! Prüfe die Partition..."
lsblk -f $ROOT_DISK
df -h /boot || echo "/boot nicht gemountet – mounten und prüfen"

echo "🔧 Optional: Initramfs neu bauen und Bootloader prüfen:"
echo "sudo mkinitcpio -P"
echo "sudo bootctl update"
echo "sudo efibootmgr -v"
