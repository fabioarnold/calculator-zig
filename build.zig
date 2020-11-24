const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Builder = std.build.Builder;

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("calculator-zig", "src/main.zig");
    exe.setBuildMode(mode);
    if (exe.target.isWindows()) {
        try exe.addVcpkgPaths(.Dynamic);
        if (exe.vcpkg_bin_path) |path| {
            const src_path = try fs.path.join(b.allocator, &[_][]const u8{ path, "SDL2.dll" });
            b.installBinFile(src_path, "SDL2.dll");
        }
        exe.subsystem = .Windows;
        exe.linkSystemLibrary("Shell32");
    }
    exe.addIncludeDir("lib/nanovg/src");
    exe.addCSourceFile("src/c/nanovg_gl2_impl.c", &[_][]const u8{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS", "-Ilib/gl2/include" });
    exe.linkSystemLibrary("SDL2");
    if (exe.target.isDarwin()) {
        exe.linkFramework("OpenGL");
    } else if (exe.target.isWindows()) {
        exe.linkSystemLibrary("opengl32");
    } else {
        exe.linkSystemLibrary("gl");
    }
    exe.linkLibC();
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run calculator-zig");
    run_step.dependOn(&run_cmd.step);

    if (exe.target.isWindows()) {
        const outputresource = try std.mem.join(b.allocator, "", &[_][]const u8{"-outputresource:", "zig-cache\\bin\\", exe.out_filename, ";1"});
        const mt_exe = "C:\\Program Files (x86)\\Windows Kits\\10\\bin\\10.0.18362.0\\x64\\mt.exe";
        const manifest_cmd = b.addSystemCommand(&[_][]const u8{ mt_exe, "-manifest", "app.manifest", outputresource });
        manifest_cmd.step.dependOn(b.getInstallStep());
        const manifest_step = b.step("manifest", "Embed manifest");
        manifest_step.dependOn(&manifest_cmd.step);
        run_cmd.step.dependOn(&manifest_cmd.step);
    }
}
