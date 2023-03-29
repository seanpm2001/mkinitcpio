#!/usr/bin/env bats
# SPDX-License-Identifier: GPL-2.0-only

shopt -s extglob

load '/usr/lib/bats-assert/load'
load '/usr/lib/bats-support/load'

setup() {
    return
}

@test "run qemu" {

    dd if=/dev/zero of="$BATS_TEST_TMPDIR"/marker.img bs=1MiB count=1
    dd if=/dev/zero of="$BATS_TEST_TMPDIR"/root.img bs=1MiB count=80

    mkfs.ext4 "$BATS_TEST_TMPDIR"/root.img

    echo "MODULES=(ext4)" >> "$BATS_RUN_TMPDIR/mkinitcpio.conf"
    echo "HOOKS=(base test)" >> "$BATS_RUN_TMPDIR/mkinitcpio.conf"

    export INIT_BINARY="$BATS_TEST_DIRNAME/test_init"

    ./mkinitcpio \
        -c "$BATS_RUN_TMPDIR/mkinitcpio.conf" \
        -g "$BATS_RUN_TMPDIR/initramfs.img"

    test/integration/run-qemu \
        -append "root=/dev/sdb rootfstype=ext4 rw quiet console=ttyS0,115200n81" \
        -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/marker.img,id=drive-sata0" \
        -device "ide-hd,bus=ide.0,drive=drive-sata0,id=sata0,model=disk,serial=marker" \
        -drive "if=none,format=raw,file=$BATS_TEST_TMPDIR/root.img,id=drive-sata1" \
        -device "ide-hd,bus=ide.1,drive=drive-sata1,id=sata1,model=disk,serial=root" \
        -initrd "$BATS_RUN_TMPDIR/initramfs.img" || return 1

    grep -U -m 1 -q "hello world" ./marker.img || return 1
}
