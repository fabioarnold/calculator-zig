const std = @import("std");
const fs = std.fs;
const mem = std.mem;
const Builder = std.build.Builder;

fn hasFileExt(filename: []const u8, ext: []const u8) bool {
    return filename.len > ext.len and mem.eql(u8, filename[filename.len - ext.len ..], ext);
}

fn installDllsFromPath(b: *Builder, path: []const u8) !void {
    var dir = try fs.cwd().openDir(path, .{ .iterate = true });
    defer dir.close();
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File and hasFileExt(entry.name, ".dll")) {
            const src_path = try fs.path.join(b.allocator, &[_][]const u8{ path, entry.name });
            const dst_path = try b.allocator.dupe(u8, entry.name);
            b.installBinFile(src_path, dst_path);
        }
    }
}

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("VectorZig", "src/main.zig");
    exe.setBuildMode(mode);
    if (exe.target.isWindows()) {
        try exe.addVcpkgPaths(.Dynamic);
        if (exe.vcpkg_bin_path) |path| {
            //const vcpkg_lib_manual_link_path = try fs.path.join(b.allocator, &[_][]const u8{ path, "..", "lib", "manual-link" });
            //exe.addLibPath(vcpkg_lib_manual_link_path);
            //exe.linkSystemLibrary("SDL2main");
            const src_path = try fs.path.join(b.allocator, &[_][]const u8{ path, "SDL2.dll" });
            b.installBinFile(src_path, "SDL2.dll");
            //try installDllsFromPath(b, path);
        }
        exe.subsystem = .Windows;
        exe.linkSystemLibrary("Shell32");
    }
    exe.addIncludeDir("lib/nanovg/src");
    exe.addCSourceFile("src/c/nanovg_gl2_impl.c", &[_][]const u8{ "-std=c99", "-D_CRT_SECURE_NO_WARNINGS", "-Ilib/gl2/include" });
    //exe.addLibPath("lib/nanovg/build");
    //exe.linkSystemLibrary("nanovg");
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

    const run_step = b.step("run", "Run VectorZig");
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
