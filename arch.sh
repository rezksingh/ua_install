#!/bin/bash

# Set environment variables
export HOSTNAME="your_hostname"
export ROOT_PASSWORD="your_root_password"
export USERNAME="your_username"
export USER_PASSWORD="your_user_password"

# Partition the disk (assuming /dev/sda)
parted /dev/sda mklabel gpt
parted /dev/sda mkpart primary ext4 1MiB 512MiB    # Boot partition
parted /dev/sda mkpart primary ext4 513MiB 80GiB   # Root partition
parted /dev/sda mkpart primary ext4 80GiB 100%     # Home partition

# Format the partitions
mkfs.fat -F32 /dev/sda1  # Boot partition
mkfs.ext4 /dev/sda2      # Root partition
mkfs.ext4 /dev/sda3      # Home partition

# Mount the root partition
mount /dev/sda2 /mnt

# Create /home directory on the home partition and mount it
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Create /home directory on the home partition and mount it
mkdir /mnt/home
mount /dev/sda3 /mnt/home

# Install essential packages and tools
pacstrap /mnt base base-devel linux linux-firmware linux-headers sudo vi vim grub efibootmgr os-prober mtools dosfstools git openssh samba networkmanager docker

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt /bin/bash <<EOF

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Calcutta /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

mkinitcpio -P

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create a new user
useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Install and configure bootloader (e.g., GRUB) including os-prober
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable NetworkManager, SSH
systemctl enable NetworkManager
systemctl enable sshd

EOF

# Unmount partitions
umount -R /mnt

# Reboot
reboot
