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
ostree --repo="$ROOT_MOUNT/ostree/repo" remote add --no-gpg-verify linux-universe-local "file://$SRC_REPO"
ostree --repo="$ROOT_MOUNT/ostree/repo" pull-local "$SRC_REPO" "$BRANCH"

echo "Deploying commit..."
ostree admin deploy --sysroot="$ROOT_MOUNT" --os="$OS_NAME" "$BRANCH"

echo "OSTree deployment complete."
