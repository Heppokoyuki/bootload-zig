const uefi = @import("std").os.uefi;
const FileInfo = uefi.protocols.FileInfo;
const FileProtocol = uefi.protocols.FileProtocol;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const EFI = @import("efi.zig");
const ELF = @import("elf.zig");

const page_size: u64 = 1 << 12;
const kernel_stack_size: u64 = 4;

const memory_map = extern struct {
    mmap_size: usize,
    mmap: [*]MemoryDescriptor,
    mmap_key: usize,
};

pub fn main() void {
    var file_info: FileInfo = undefined;
    var text: *FileProtocol = undefined;
    var key: uefi.protocols.InputKey = undefined;
    var str: [3:0]u16 = undefined;
    var buf_pages: [*]align(4096) u8 = undefined;
    var kernel_stack_pages: [*]align(4096) u8 = undefined;
    var buf: [100]u8 = undefined;
    var kernel_start_address: u64 = undefined;
    var kernel_end_address: u64 = undefined;

    EFI.init();
    EFI.puts("Hello, UEFI!\r\n");

    text = EFI.open_file(&[_:0]u16{ 't', 'e', 's', 't' });
    EFI.read_file_info(text, &file_info);
    EFI.puts_multi(file_info.getFileName());
    EFI.puts("\r\n");
    EFI.printf(buf[0..], "file_info.file_size: 0x{x}\r\n", .{file_info.file_size});
    buf_pages = EFI.allocate_pages((file_info.file_size + page_size - 1) >> 12);
    if (text.read(&file_info.file_size, buf_pages) != uefi.Status.Success) {
        EFI.puts("file read error!!\r\n");
    }
    if (ELF.elf_hdr_check(buf_pages) < 0) {
        EFI.puts("elf header is incorrect!!\r\n");
    }
    kernel_stack_pages = EFI.allocate_pages(kernel_stack_size);

    EFI.exit_boot_services();

    ELF.elf_get_address(buf_pages, &kernel_start_address, &kernel_end_address);
    EFI.printf(buf[0..], "kernel start: 0x{x}, end: 0x{x}\r\n", .{ kernel_start_address, kernel_end_address });

    EFI.init_memory_map();
    EFI.dump_memory_map();
    _ = ELF.elf_load(buf_pages);

    while (true) {
        if (uefi.system_table.con_in.?.readKeyStroke(&key) == uefi.Status.Success) {
            if (key.unicode_char != '\r') {
                str[0] = key.unicode_char;
                str[1] = 0;
            } else {
                str[0] = '\r';
                str[1] = '\n';
                str[2] = 0;
            }
            _ = EFI.puts_raw(&str);
        }
    }
}
