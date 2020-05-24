#!/bin/sh

qemu-system-x86_64 -bios ~/Downloads/OVMF.fd -drive format=raw,file=fat:rw:fs &
