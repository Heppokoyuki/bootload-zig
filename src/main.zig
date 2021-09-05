const uefi = @import("std").os.uefi;
const FileInfo = uefi.protocols.FileInfo;
const FileProtocol = uefi.protocols.FileProtocol;
const MemoryDescriptor = uefi.tables.MemoryDescriptor;
const GraphicsOutputProtocolMode = uefi.protocols.GraphicsOutputProtocolMode;
const EFI = @import("efi.zig");
const ELF = @import("elf.zig");
const Zigsaw = @import("zigsaw.zig").Zigsaw;
const FrameBuffer = @import("zigsaw.zig").FrameBuffer;
const MemoryMap = @import("zigsaw.zig").MemoryMap;
const builtin = @import("std").builtin;

const page_size: u64 = 1 << 12;
const kernel_stack_size: u64 = 4;

var zigsaw: *Zigsaw = undefined;
var fb: *FrameBuffer = undefined;
var mmap: *MemoryMap = undefined;

const PixelFormat = struct {
    b: u8,
    g: u8,
    r: u8,
    _reserved: u8,
};

fn init_graphics() void {
    const mode: *GraphicsOutputProtocolMode = EFI.get_graphics_mode();
    fb = @ptrCast(*FrameBuffer, EFI.allocate_pool(@sizeOf(FrameBuffer)));
    fb.* = FrameBuffer.init(mode.frame_buffer_base, mode.frame_buffer_size, mode.info.horizontal_resolution, mode.info.vertical_resolution);
    zigsaw.frame_buffer = fb;
}

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    _ = error_return_trace;
    EFI.puts("PANIC: ");
    EFI.puts(msg);
    EFI.puts("\r\n");
    while (true) {}
}

pub fn main() void {
    var file_info: FileInfo = undefined;
    var text: *FileProtocol = undefined;
    var buf_pages: [*]align(4096) u8 = undefined;
    var kernel_stack_pages: [*]align(4096) u8 = undefined;
    var buf: [1000]u8 = undefined;
    var kernel_start_address: u64 = undefined;
    var kernel_end_address: u64 = undefined;

    EFI.init();
    EFI.puts("Hello, UEFI!\r\n");

    zigsaw = @ptrCast(*Zigsaw, EFI.allocate_pool(@sizeOf(Zigsaw)));
    init_graphics();
    mmap = @ptrCast(*MemoryMap, EFI.allocate_pool(@sizeOf(MemoryMap)));

    text = EFI.open_file(&[_:0]u16{ 'z', 'i', 'g', 's', 'a', 'w' });
    EFI.read_file_info(text, &file_info);
    EFI.puts("opening file: /");
    EFI.puts_multi(file_info.getFileName());
    EFI.puts("\r\n");
    buf_pages = EFI.allocate_pages((file_info.file_size + page_size - 1) >> 12);
    if (text.read(&file_info.file_size, buf_pages) != uefi.Status.Success) {
        @panic("file read error!!\r\n");
    }
    if (ELF.hdr_check(buf_pages) < 0) {
        @panic("elf header is incorrect!!\r\n");
    }
    ELF.get_address(buf_pages, &kernel_start_address, &kernel_end_address);
    EFI.printf(buf[0..], "kernel start: 0x{x}, end: 0x{x}\r\n", .{ kernel_start_address, kernel_end_address });
    zigsaw.kernel_start_address = kernel_start_address;
    zigsaw.kernel_end_address = kernel_end_address;
    EFI.printf(buf[0..], "kernel entrypoint: 0x{x}\r\n", .{ELF.get_entrypoint(buf_pages)});
    kernel_stack_pages = EFI.allocate_pages(kernel_stack_size);

    EFI.get_memory_map_and_exit_boot_services(mmap);
    zigsaw.memory_map = mmap;
    _ = ELF.load(buf_pages, zigsaw, kernel_stack_pages);

    while (true) {}
}
