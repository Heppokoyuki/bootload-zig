const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("test", "src/main.zig");
    exe.setTarget(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .gnu,
    });
    exe.setLinkerScriptPath("src/linker.ld");
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
