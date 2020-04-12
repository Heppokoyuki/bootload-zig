const uefi = @import("std").os.uefi;
const FileInfo = uefi.protocols.FileInfo;
const FileProtocol = uefi.protocols.FileProtocol;
const EFI = @import("efi.zig");

const page_size: u64 = 1 << 12;

pub fn main() void {
    var file_info: *FileInfo = undefined;
    var text: *FileProtocol = undefined;
    var key: uefi.protocols.InputKey = undefined;
    var str: [3:0]u16 = undefined;
    var buf_pages: [*]align(4096) u8 = undefined;
    var buf: [100]u8 = undefined;

    EFI.init();
    EFI.puts("Hello, UEFI!\r\n");

    text = EFI.open_file(&[_:0]u16{ 't', 'e', 'x', 't', '.', 't', 'x', 't' });
    EFI.read_file_info(text, &file_info);
    EFI.puts_multi(file_info.getFileName());
    EFI.printf(buf[0..], "file_info.file_size: {}", .{file_info.size});
    buf_pages = EFI.allocate_pages(1); //(file_info.file_size + page_size - 1) >> 12);
    //if (text.read(&file_info.file_size, buf_pages) != uefi.Status.Success) {
    //    EFI.puts("file read error!!\r\n");
    //}

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
