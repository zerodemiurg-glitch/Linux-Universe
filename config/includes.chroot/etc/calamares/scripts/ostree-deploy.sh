#!/bin/bash
set -e

ROOT_MOUNT="/tmp/calamares-root"
SRC_REPO="/usr/share/linux-universe/ostree-repo"
BRANCH="linux-universe/1.0/x86_64"
OS_NAME="linux-universe"

echo "=== Linux-Universe OSTree deployment ==="

if [ ! -d "$ROOT_MOUNT" ]; then
    echo "ERROR: target root mount not found at $ROOT_MOUNT"
    exit 1
fi

echo "Initializing OSTree sysroot..."
ostree admin init-fs --sysroot="$ROOT_MOUNT" --modern "$ROOT_MOUNT"
ostree admin os-init "$OS_NAME" --sysroot="$ROOT_MOUNT"

echo "Setting up local repo alias and pulling commit..."
ostree --repo="$ROOT_MOUNT/ostree/repo" remote add --no-gpg-verify --if-not-exists linux-universe-local "file://$SRC_REPO"
ostree --repo="$ROOT_MOUNT/ostree/repo" pull-local "$SRC_REPO" "$BRANCH"

echo "Deploying commit..."
ostree admin deploy --sysroot="$ROOT_MOUNT" --os="$OS_NAME" --karg="lockdown=integrity" "$BRANCH"

echo "Installing GRUB bootloader for OSTree..."
EFI_MOUNT="$ROOT_MOUNT/boot/efi"

grub-install --target=x86_64-efi --efi-directory="$EFI_MOUNT" \
    --boot-directory="$ROOT_MOUNT/boot" --bootloader-id=linux-universe \
    --root-directory="$ROOT_MOUNT" || echo "WARNING: grub-install reported an issue"

ostree admin instutil grub2-generate --sysroot="$ROOT_MOUNT" || echo "WARNING: grub2-generate reported an issue"

echo "OSTree deployment complete."
