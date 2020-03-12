#!/bin/sh

qemu-system-x86_64 -bios ovmf/OVMF.fd -drive format=raw,file=fat:rw:fs &
