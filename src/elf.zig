const std = @import("std");
const mem = std.mem;
const elf = std.elf;
const Zigsaw = @import("zigsaw.zig").Zigsaw;

pub fn elf_hdr_check(file: [*]const u8) isize {
    if (!mem.eql(u8, file[0..4], "\x7fELF")) return -1;
    return 0;
}

pub fn elf_get_address(file: [*]u8, start: *u64, end: *u64) void {
    const ehdr: *elf.Elf64_Ehdr = @ptrCast(*elf.Elf64_Ehdr, @alignCast(8, file));
    var ph: [*]elf.Elf64_Phdr = @intToPtr([*]elf.Elf64_Phdr, @ptrToInt(file) + ehdr.e_phoff);
    var i: usize = 0;
    start.* = std.math.inf_u64;
    end.* = 0;
    while (i < ehdr.e_phnum) {
        if (ph[i].p_type != elf.PT_LOAD) {
            i += 1;
            continue;
        }
        start.* = std.math.min(start.*, ph[i].p_paddr);
        end.* = std.math.max(end.*, ph[i].p_paddr + ph[i].p_memsz);
        i += 1;
    }
}

pub fn elf_load(file: [*]u8, kernel_param: *Zigsaw) isize {
    const ehdr: *elf.Elf64_Ehdr = @ptrCast(*elf.Elf64_Ehdr, @alignCast(8, file));
    var ph: [*]elf.Elf64_Phdr = @intToPtr([*]elf.Elf64_Phdr, @ptrToInt(file) + ehdr.e_phoff);
    const entry = @intToPtr(fn (*Zigsaw) void, ehdr.e_entry);
    var i: usize = 0;
    while (i < ehdr.e_phnum) {
        if (ph[i].p_type != elf.PT_LOAD) {
            i += 1;
            continue;
        }
        @memcpy(@intToPtr([*]u8, ph[i].p_paddr), @intToPtr([*]u8, @ptrToInt(ehdr) + ph[i].p_offset), ph[i].p_filesz);
        i += 1;
    }
    entry(kernel_param);
    return 0;
}
