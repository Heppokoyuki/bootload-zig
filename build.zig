const std = @import("std");
const Builder = std.build.Builder;
const Target = std.build.Target;
const builtin = @import("builtin");

pub fn build(b: *Builder) !void {
    //    const target = Target.parse("x86_64-uefi-msvc") catch |e| {
    //        std.debug.warn("wrong target triple!\n", .{});
    //        return e;
    //    };
    const exe = b.addExecutable("BOOTX64", "src/main.zig");
    exe.setBuildMode(builtin.Mode.Debug);
    //    exe.setTheTarget(target);
    exe.setTarget(.{
        .cpu_arch = .x86_64,
        .os_tag = .uefi,
        .abi = .msvc,
    });
    exe.setOutputDir("fs/EFI/BOOT");
    b.default_step.dependOn(&exe.step);

    const run = b.step("run", "Run the bootloader on QEMU");
    var qemu_args = std.ArrayList([]const u8).init(b.allocator);
    try qemu_args.appendSlice(&[_][]const u8{
        "qemu-system-x86_64",
        "-nographic",
        "-bios",
        "ovmf/OVMF.fd",
        "-drive",
        "format=raw,file=fat:rw:fs",
    });
    const run_qemu = b.addSystemCommand(qemu_args.toSlice());
    run_qemu.step.dependOn(&exe.step);
    run.dependOn(&run_qemu.step);
}
