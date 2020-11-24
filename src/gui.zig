const nvg = @import("nvg.zig");
const Rect = @import("geometry.zig").Rect;
const Point = @import("geometry.zig").Point;
const std = @import("std");
const ArrayList = std.ArrayList;
const ArrayListSentineled = std.ArrayListSentineled;
const Allocator = std.mem.Allocator;

var gui_color_bg: nvg.Color = undefined;
var gui_color_shadow: nvg.Color = undefined;
var gui_color_light: nvg.Color = undefined;
var gui_color_border: nvg.Color = undefined;
var gui_color_select: nvg.Color = undefined;

pub fn init() void {
    gui_color_bg = nvg.RGB(224, 224, 224);
    gui_color_shadow = nvg.RGB(170, 170, 170);
    gui_color_light = nvg.RGB(255, 255, 255);
    gui_color_border = nvg.RGB(85, 85, 85);
    gui_color_select = nvg.RGB(90, 140, 240);
}

fn pixelsToPoints(pixel_size: f32) f32 {
    return pixel_size * 96.0 / 72.0;
}

pub fn drawPanel(x: f32, y: f32, w: f32, h: f32, depth: f32, hovered: bool, pressed: bool) void {
    var color_bg = gui_color_bg;
    var color_shadow = gui_color_shadow;
    var color_light = gui_color_light;

    if (pressed) {
        color_bg = nvg.RGB(204, 204, 204);
        color_shadow = gui_color_bg;
        color_light = gui_color_shadow;
    } else if (hovered) {
        color_bg = nvg.RGB(240, 240, 240);
    }

    // background
    nvg.beginPath();
    nvg.rect(x, y, w, h);
    nvg.fillColor(color_bg);
    nvg.fill();

    // shadow
    nvg.beginPath();
    nvg.moveTo(x, y + h);
    nvg.lineTo(x + w, y + h);
    nvg.lineTo(x + w, y);
    nvg.lineTo(x + w - depth, y + depth);
    nvg.lineTo(x + w - depth, y + h - depth);
    nvg.lineTo(x + depth, y + h - depth);
    nvg.closePath();
    nvg.fillColor(color_shadow);
    nvg.fill();

    // light
    nvg.beginPath();
    nvg.moveTo(x + w, y);
    nvg.lineTo(x, y);
    nvg.lineTo(x, y + h);
    nvg.lineTo(x + depth, y + h - depth);
    nvg.lineTo(x + depth, y + depth);
    nvg.lineTo(x + w - depth, y + depth);
    nvg.closePath();
    nvg.fillColor(color_light);
    nvg.fill();
}

pub fn drawPanelInset(x: f32, y: f32, w: f32, h: f32, depth: f32) void {
    var color_shadow = gui_color_shadow;
    var color_light = gui_color_light;

    // light
    nvg.beginPath();
    nvg.moveTo(x, y + h);
    nvg.lineTo(x + w, y + h);
    nvg.lineTo(x + w, y);
    nvg.lineTo(x + w - depth, y + depth);
    nvg.lineTo(x + w - depth, y + h - depth);
    nvg.lineTo(x + depth, y + h - depth);
    nvg.closePath();
    nvg.fillColor(color_light);
    nvg.fill();

    // shadow
    nvg.beginPath();
    nvg.moveTo(x + w, y);
    nvg.lineTo(x, y);
    nvg.lineTo(x, y + h);
    nvg.lineTo(x + depth, y + h - depth);
    nvg.lineTo(x + depth, y + depth);
    nvg.lineTo(x + w - depth, y + depth);
    nvg.closePath();
    nvg.fillColor(color_shadow);
    nvg.fill();
}

pub const EventType = enum(u8) {
    MouseMove,
    MouseDown,
    MouseUp,
    KeyDown,
    KeyUp,
};

pub const Event = struct {
    type: EventType,
};

pub const MouseButton = enum(u8) {
    None,
    Left,
    Right,
    Middle,
    Back,
    Forward,
};

pub const MouseEvent = struct {
    event: Event,
    button: MouseButton,
    pressed: bool,
    x: i32,
    y: i32,
};

pub const KeyCode = enum(u8) {
    Return,
    D0,
    D1,
    D2,
    D3,
    D4,
    D5,
    D6,
    D7,
    D8,
    D9,
    Period,
    Escape,
    Backspace,
    Plus,
    Minus,
    Asterisk,
    Slash,
    Percent,
    Unknown,
};

pub const KeyEvent = struct {
    event: Event,
    key: KeyCode,
    down: bool,
};

pub const Widget = struct {
    parent: ?*Widget = null,
    children: ArrayList(*Widget),

    drawFn: fn (*Widget) void = drawChildren,

    onMouseMoveFn: fn (*Widget, *const MouseEvent) void = onMouseMove,
    onMouseDownFn: fn (*Widget, *const MouseEvent) void = onMouseDown,
    onMouseUpFn: fn (*Widget, *const MouseEvent) void = onMouseUp,
    onKeyDownFn: fn (*Widget, *const KeyEvent) void = onKeyDown,

    pub fn init(allocator: *Allocator) Widget {
        return Widget{ .children = ArrayList(*Widget).init(allocator) };
    }

    pub fn addChild(self: *Widget, child: *Widget) void {
        std.debug.assert(child.parent == null);
        child.parent = self;
        self.children.append(child) catch unreachable;
    }

    fn drawChildren(self: *Widget) void {
        for (self.children.items) |child| {
            child.draw();
        }
    }

    pub fn draw(self: *Widget) void {
        self.drawFn(self);
    }

    fn onMouseMove(self: *Widget, event: *const MouseEvent) void {
        for (self.children.items) |child| {
            child.onMouseMoveFn(child, event);
        }
    }

    fn onMouseDown(self: *Widget, event: *const MouseEvent) void {
        for (self.children.items) |child| {
            child.onMouseDownFn(child, event);
        }
    }

    fn onMouseUp(self: *Widget, event: *const MouseEvent) void {
        for (self.children.items) |child| {
            child.onMouseUpFn(child, event);
        }
    }

    fn onKeyDown(self: *Widget, event: *const KeyEvent) void {
        for (self.children.items) |child| {
            child.onKeyDownFn(child, event);
        }
    }

    pub fn handleEvent(self: *Widget, event: *const Event) void {
        const mouse_event = @fieldParentPtr(MouseEvent, "event", event);
        const key_event = @fieldParentPtr(KeyEvent, "event", event);
        switch (event.type) {
            .MouseMove => self.onMouseMoveFn(self, mouse_event),
            .MouseDown => self.onMouseDownFn(self, mouse_event),
            .MouseUp => self.onMouseUpFn(self, mouse_event),
            .KeyDown => self.onKeyDownFn(self, key_event),
            else => {},
        }
    }
};

pub const Application = struct {
    main_widget: ?*Widget = null,

    pub fn handleEvent(self: Application, event: *const Event) void {
        if (self.main_widget) |widget| {
            widget.handleEvent(event);
        }
    }

    pub fn draw(self: Application) void {
        if (self.main_widget) |widget| {
            widget.draw();
        }
    }
};

pub fn makePoint(x: i32, y: i32) Point(f32) {
    return Point(f32){ .x = @intToFloat(f32, x), .y = @intToFloat(f32, y) };
}

pub const Button = struct {
    widget: Widget,
    rect: Rect(f32),
    text: [:0]const u8,
    hovered: bool = false,
    pressed: bool = false,
    onClickFn: ?fn (*Button) void = null,

    pub fn create(allocator: *Allocator, rect: Rect(f32), text: [:0]const u8) !*Button {
        var self = try allocator.create(Button);
        self.* = Button{
            .widget = Widget.init(allocator),
            .rect = rect,
            .text = text,
        };
        self.widget.drawFn = draw;
        self.widget.onMouseMoveFn = onMouseMove;
        self.widget.onMouseDownFn = onMouseDown;
        self.widget.onMouseUpFn = onMouseUp;
        return self;
    }

    fn onMouseMove(widget: *Widget, event: *const MouseEvent) void {
        const self = @fieldParentPtr(Button, "widget", widget);
        self.hovered = self.rect.contains(makePoint(event.x, event.y));
    }

    fn onMouseDown(widget: *Widget, event: *const MouseEvent) void {
        const self = @fieldParentPtr(Button, "widget", widget);
        if (event.button == .Left) {
            if (self.hovered) {
                self.pressed = true;
            }
        }
    }

    fn onMouseUp(widget: *Widget, event: *const MouseEvent) void {
        const self = @fieldParentPtr(Button, "widget", widget);
        if (event.button == .Left) {
            self.pressed = false;
            if (self.hovered) {
                if (self.onClickFn) |clickFn| {
                    clickFn(self);
                }
            }
        }
    }

    pub fn draw(widget: *Widget) void {
        const self = @fieldParentPtr(Button, "widget", widget);

        if (true) {
            drawPanel(self.rect.x + 1, self.rect.y + 1, self.rect.w - 2, self.rect.h - 2, 2, self.hovered, self.pressed);

            // border
            nvg.beginPath();
            nvg.rect(self.rect.x + 0.5, self.rect.y + 0.5, self.rect.w - 1, self.rect.h - 1);
            nvg.strokeColor(gui_color_border);
            nvg.stroke();
        } else {
            nvg.beginPath();
            nvg.roundedRect(self.rect.x + 1.5, self.rect.y + 1.5, self.rect.w - 3, self.rect.h - 3, 1);
            nvg.fillColor(gui_color_bg);
            nvg.fill();
            nvg.strokeColor(gui_color_light);
            nvg.stroke();
            nvg.beginPath();
            nvg.roundedRect(self.rect.x + 0.5, self.rect.y + 0.5, self.rect.w - 1, self.rect.h - 1, 2);
            nvg.strokeColor(gui_color_border);
            nvg.stroke();
        }

        nvg.fontFace("guifont");
        nvg.fontSize(pixelsToPoints(9));
        nvg.textAlign(@intToEnum(nvg.TextAlign, @enumToInt(nvg.TextAlign.center) | @enumToInt(nvg.TextAlign.middle)));
        nvg.fillColor(nvg.RGB(0, 0, 0));
        _ = nvg.text(self.rect.x + 0.5 * self.rect.w, self.rect.y + 0.5 * self.rect.h, self.text);
    }
};

pub const TextAlignment = enum(u8) {
    Left,
    Center,
    Right,
};

pub const Label = struct {
    widget: Widget,
    rect: Rect(f32),
    text: [:0]const u8,
    text_alignment: TextAlignment = .Left,
    draw_border: bool = false,

    pub fn create(allocator: *Allocator, rect: Rect(f32), text: [:0]const u8) !*Label {
        var self = try allocator.create(Label);
        self.* = Label{
            .widget = Widget.init(allocator),
            .rect = rect,
            .text = text,
        };
        self.widget.drawFn = draw;
        return self;
    }

    pub fn draw(widget: *Widget) void {
        const self = @fieldParentPtr(Label, "widget", widget);

        if (self.draw_border) {
            drawPanelInset(self.rect.x - 1, self.rect.y - 1, self.rect.w + 2, self.rect.h + 2, 1);
        }

        nvg.fontFace("guifont");
        nvg.fontSize(pixelsToPoints(9));
        var text_align = @enumToInt(nvg.TextAlign.middle);
        var x = self.rect.x;
        switch (self.text_alignment) {
            .Left => {
                text_align |= @enumToInt(nvg.TextAlign.left);
                x += 5;
            },
            .Center => {
                text_align |= @enumToInt(nvg.TextAlign.center);
                x += 0.5 * self.rect.w;
            },
            .Right => {
                text_align |= @enumToInt(nvg.TextAlign.right);
                x += self.rect.w - 5;
            },
        }
        nvg.textAlign(@intToEnum(nvg.TextAlign, text_align));
        nvg.fillColor(nvg.RGB(0, 0, 0));
        _ = nvg.text(x, self.rect.y + 0.5 * self.rect.h, self.text);
    }
};

pub const TextBox = struct {
    widget: Widget,
    rect: Rect(f32),
    text: ArrayListSentineled(u8, 0),
    text_alignment: TextAlignment = .Left,
    //font_name: [:0]const u8,

    pub fn create(allocator: *Allocator, rect: Rect(f32)) !*TextBox {
        var self = try allocator.create(TextBox);
        self.* = TextBox{
            .widget = Widget.init(allocator),
            .rect = rect,
            .text = try ArrayListSentineled(u8, 0).init(allocator, ""),
        };
        self.widget.drawFn = draw;
        return self;
    }

    pub fn draw(widget: *Widget) void {
        const self = @fieldParentPtr(TextBox, "widget", widget);
        drawPanelInset(self.rect.x - 1, self.rect.y - 1, self.rect.w + 2, self.rect.h + 2, 1);

        // background
        nvg.beginPath();
        nvg.rect(self.rect.x + 1, self.rect.y + 1, self.rect.w - 2, self.rect.h - 2);
        nvg.fillColor(gui_color_light);
        nvg.fill();

        // border
        nvg.beginPath();
        nvg.rect(self.rect.x + 0.5, self.rect.y + 0.5, self.rect.w - 1, self.rect.h - 1);
        nvg.strokeColor(gui_color_border);
        nvg.stroke();

        nvg.fontFace("guifont");
        nvg.fontSize(pixelsToPoints(9));
        var text_align = @enumToInt(nvg.TextAlign.middle);
        var x = self.rect.x;
        switch (self.text_alignment) {
            .Left => {
                text_align |= @enumToInt(nvg.TextAlign.left);
                x += 5;
            },
            .Center => {
                text_align |= @enumToInt(nvg.TextAlign.center);
                x += 0.5 * self.rect.w;
            },
            .Right => {
                text_align |= @enumToInt(nvg.TextAlign.right);
                x += self.rect.w - 5;
            },
        }
        nvg.textAlign(@intToEnum(nvg.TextAlign, text_align));
        nvg.fillColor(nvg.RGB(0, 0, 0));
        _ = nvg.text(x, self.rect.y + 0.5 * self.rect.h, self.text.span());
    }
};
