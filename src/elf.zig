const std = @import("std");
const elf = std.elf;
const mem = std.mem;
const elf_header = elf.Elf64_Ehdr;
const elf_program_header = elf.Elf64_Phdr;
const EI_CLASS = elf.EI_CLASS;
const ELFCLASS64 = elf.ELFCLASS64;
const EI_DATA = elf.EI_DATA;
const ELFDATA2LSB = elf.ELFDATA2LSB;
const EI_VERSION = elf.EI_VERSION;
const ET = elf.ET;
const EM = elf.EM;

fn elf_check(header: *elf_header) isize {
    if (!mem.eql(u8, header.e_ident[0..4], "\x7fELF")) return -1;
    if (header.e_ident[EI_CLASS] != ELFCLASS64) return -1;
    if (header.e_ident[EI_DATA] != ELFDATA2LSB) return -1;
    if (header.e_ident[EI_VERSION] != 1) return -1;
    if (header.e_type != ET.EXEC) return -1;
    if (header.e_machine != EM._X86_64) return -1;
    return 0;
}

fn elf_load_program(header: *elf_header) isize {
    var i: usize = 0;
    pheader: *elf_program_header = undefined;

    while(i < header.
}

test "elf_check_test" {
    var header: elf_header = undefined;
    header.e_ident = [_]u8{ 0x7f, 'E', 'L', 'F', ELFCLASS64, ELFDATA2LSB, 0x01 } ++ [_]u8{0} ** 9;
    header.e_type = ET.EXEC;
    header.e_machine = EM._X86_64;

    std.debug.assert(elf_check(&header) == 0);
}
