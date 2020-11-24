const std = @import("std");
const Allocator = std.mem.Allocator;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_opengl.h");
});
const nvg = @import("nvg.zig");
const gui = @import("gui.zig");
const CalculatorWidget = @import("calculator_widget.zig").CalculatorWidget;

extern fn gladLoadGL() callconv(.C) c_int; // init OpenGL function pointers on Windows and Linux

export fn WinMain() callconv(.C) c_int {
    main() catch return 1; // TODO report error
    return 0;
}

var sdl_window: ?*c.SDL_Window = undefined;
var sdl_gl_context: c.SDL_GLContext = undefined;

var video_width: f32 = 254;
var video_height: f32 = 213;
var video_scale: f32 = 1;

var app: gui.Application = undefined;

fn draw() void {
    sdlSetupFrame();

    c.glClearColor(0.4, 0.6, 0.8, 1);
    c.glClear(c.GL_COLOR_BUFFER_BIT);

    nvg.beginFrame(video_width, video_height, video_scale);
    gui.drawPanel(0, 0, video_width, video_height, 1, false, false);
    app.draw();
    nvg.endFrame();

    c.SDL_GL_SwapWindow(sdl_window);
}

fn sdlProcessMouseMotion(motion_event: c.SDL_MouseMotionEvent) void {
    var mx = motion_event.x;
    var my = motion_event.y;
    if (std.builtin.os.tag != .macos) {
        mx = @floatToInt(i32, @intToFloat(f32, mx) / video_scale);
        my = @floatToInt(i32, @intToFloat(f32, my) / video_scale);
    }
    const me = gui.MouseEvent{
        .event = gui.Event{ .type = .MouseMove },
        .button = .None,
        .pressed = false,
        .x = mx,
        .y = my,
    };
    app.handleEvent(&me.event);
}

fn sdlProcessMouseButton(button_event: c.SDL_MouseButtonEvent) void {
    var mx = button_event.x;
    var my = button_event.y;
    if (std.builtin.os.tag != .macos) {
        mx = @floatToInt(i32, @intToFloat(f32, mx) / video_scale);
        my = @floatToInt(i32, @intToFloat(f32, my) / video_scale);
    }
    const me = gui.MouseEvent{
        .event = gui.Event{ .type = if (button_event.state == c.SDL_PRESSED) .MouseDown else .MouseUp },
        .button = switch (button_event.button) {
            c.SDL_BUTTON_LEFT => .Left,
            c.SDL_BUTTON_MIDDLE => .Middle,
            c.SDL_BUTTON_RIGHT => .Right,
            c.SDL_BUTTON_X1 => .Back,
            c.SDL_BUTTON_X2 => .Forward,
            else => .None,
        },
        .pressed = button_event.state == c.SDL_PRESSED,
        .x = mx,
        .y = my,
    };
    app.handleEvent(&me.event);
}

fn translateSdlKey(sym: c.SDL_Keycode) gui.KeyCode {
    // TODO: Modifier keys
    return switch (sym) {
        c.SDLK_RETURN, c.SDLK_KP_ENTER => .Return,
        c.SDLK_0, c.SDLK_KP_0 => .D0,
        c.SDLK_1, c.SDLK_KP_1 => .D1,
        c.SDLK_2, c.SDLK_KP_2 => .D2,
        c.SDLK_3, c.SDLK_KP_3 => .D3,
        c.SDLK_4, c.SDLK_KP_4 => .D4,
        c.SDLK_5, c.SDLK_KP_5 => .D5,
        c.SDLK_6, c.SDLK_KP_6 => .D6,
        c.SDLK_7, c.SDLK_KP_7 => .D7,
        c.SDLK_8, c.SDLK_KP_8 => .D8,
        c.SDLK_9, c.SDLK_KP_9 => .D9,
        c.SDLK_PERIOD, c.SDLK_KP_DECIMAL => .Period,
        c.SDLK_ESCAPE => .Escape,
        c.SDLK_BACKSPACE => .Backspace,
        c.SDLK_PLUS, c.SDLK_KP_PLUS => .Plus,
        c.SDLK_MINUS, c.SDLK_KP_MINUS => .Minus,
        c.SDLK_ASTERISK, c.SDLK_KP_MULTIPLY => .Asterisk,
        c.SDLK_SLASH, c.SDLK_KP_DIVIDE => .Slash,
        c.SDLK_PERCENT => .Percent,
        else => .Unknown,
    };
}

fn sdlProcessKey(key_event: c.SDL_KeyboardEvent) void {
    const ke = gui.KeyEvent{
        .event = gui.Event{.type = if (key_event.type == c.SDL_KEYDOWN) .KeyDown else .KeyUp},
        .key = translateSdlKey(key_event.keysym.sym),
        .down = key_event.state == c.SDL_PRESSED,
    };
    app.handleEvent(&ke.event);
}

fn sdlSetupFrame() void {
    const default_dpi: f32 = switch (std.builtin.os.tag) {
        .windows => 96,
        .macos => 72,
        else => 96, // TODO
    };
    const display = c.SDL_GetWindowDisplayIndex(sdl_window);
    var dpi: f32 = undefined;
    _ = c.SDL_GetDisplayDPI(display, &dpi, null, null);
    const new_video_scale = dpi / default_dpi;
    if (new_video_scale != video_scale) { // DPI change
        video_scale = new_video_scale;
        var window_width: i32 = undefined;
        var window_height: i32 = undefined;
        if (std.builtin.os.tag == .macos) {
            window_width = @floatToInt(i32, video_width);
            window_height = @floatToInt(i32, video_height);
        } else {
            window_width = @floatToInt(i32, video_scale * video_width);
            window_height = @floatToInt(i32, video_scale * video_height);
        }
        c.SDL_SetWindowSize(sdl_window, window_width, window_height);
    }

    var drawable_width: i32 = undefined;
    var drawable_height: i32 = undefined;
    c.SDL_GL_GetDrawableSize(sdl_window, &drawable_width, &drawable_height);
    c.glViewport(0, 0, drawable_width, drawable_height);

    // only when window is resizable
    //video_width = @intToFloat(f32, drawable_width) / video_scale;
    //video_height = @intToFloat(f32, drawable_height) / video_scale;
}

fn sdlEventWatch(userdata: ?*c_void, sdl_event: [*c]c.SDL_Event) callconv(.C) c_int {
    if (sdl_event[0].type == c.SDL_WINDOWEVENT and sdl_event[0].window.event == c.SDL_WINDOWEVENT_RESIZED) {
        draw();
        //draw((Editor*)userdata);
        return 0;
    }
    return 1; // unhandled
}

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    _ = c.SDL_GL_SetAttribute(.SDL_GL_STENCIL_SIZE, 1);
    _ = c.SDL_GL_SetAttribute(.SDL_GL_MULTISAMPLEBUFFERS, 1);
    _ = c.SDL_GL_SetAttribute(.SDL_GL_MULTISAMPLESAMPLES, 4);
    const window_flags = c.SDL_WINDOW_OPENGL | c.SDL_WINDOW_ALLOW_HIGHDPI; // | c.SDL_WINDOW_RESIZABLE;
    var window_width: i32 = undefined;
    var window_height: i32 = undefined;
    if (std.builtin.os.tag == .macos) {
        window_width = @floatToInt(i32, video_width);
        window_height = @floatToInt(i32, video_height);
    } else {
        window_width = @floatToInt(i32, video_scale * video_width);
        window_height = @floatToInt(i32, video_scale * video_height);
    }
    sdl_window = c.SDL_CreateWindow("Calculator", c.SDL_WINDOWPOS_CENTERED, c.SDL_WINDOWPOS_CENTERED, window_width, window_height, window_flags);
    if (sdl_window == null) {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLCreateWindowFailed;
    }
    defer c.SDL_DestroyWindow(sdl_window);

    sdl_gl_context = c.SDL_GL_CreateContext(sdl_window);
    if (sdl_gl_context == null) {
        c.SDL_Log("Unable to create gl context: %s", c.SDL_GetError());
        return error.SDLCreateGLContextFailed;
    }
    defer c.SDL_GL_DeleteContext(sdl_gl_context);

    if (std.builtin.os.tag == .windows or std.builtin.os.tag == .linux) {
        _ = gladLoadGL();
    }

    c.SDL_AddEventWatch(sdlEventWatch, null);

    nvg.init();
    defer nvg.quit();

    if (std.builtin.os.tag == .windows) {
        _ = nvg.createFont("guifont", "C:\\Windows\\Fonts\\segoeui.ttf");
    } else if (std.builtin.os.tag == .macos) {
        _ = nvg.createFont("guifont", "/System/Library/Fonts/SFNS.ttf");
    } else if (std.builtin.os.tag == .linux) {
        _ = nvg.createFont("guifont", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf");
    }

    gui.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var calc = try CalculatorWidget.create(&gpa.allocator);

    app = gui.Application{
        .main_widget = &calc.widget,
    };

    var running = true;
    while (running) {
        var sdl_event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdl_event) != 0) {
            switch (sdl_event.type) {
                c.SDL_QUIT => running = false,
                c.SDL_MOUSEMOTION => sdlProcessMouseMotion(sdl_event.motion),
                c.SDL_MOUSEBUTTONDOWN, c.SDL_MOUSEBUTTONUP => sdlProcessMouseButton(sdl_event.button),
                c.SDL_KEYDOWN, c.SDL_KEYUP => sdlProcessKey(sdl_event.key),
                else => {},
            }
        }

        draw();
    }
}
