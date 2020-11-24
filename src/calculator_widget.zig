const std = @import("std");
const Allocator = std.mem.Allocator;

const gui = @import("gui.zig");
const Rect = @import("geometry.zig").Rect;
const Calculator = @import("calculator.zig").Calculator;
const Keypad = @import("keypad.zig").Keypad;

pub const CalculatorWidget = struct {
    widget: gui.Widget,

    calculator: Calculator,
    keypad: Keypad,

    entry_textbox: *gui.TextBox,
    error_label: *gui.Label,

    digit_buttons: [10]*gui.Button,
    mem_add_button: *gui.Button,
    mem_save_button: *gui.Button,
    mem_recall_button: *gui.Button,
    mem_clear_button: *gui.Button,
    clear_button: *gui.Button,
    clear_error_button: *gui.Button,
    backspace_button: *gui.Button,
    decimal_point_button: *gui.Button,
    sign_button: *gui.Button,
    add_button: *gui.Button,
    subtract_button: *gui.Button,
    multiply_button: *gui.Button,
    divide_button: *gui.Button,
    sqrt_button: *gui.Button,
    inverse_button: *gui.Button,
    percent_button: *gui.Button,
    equals_button: *gui.Button,

    pub fn create(allocator: *Allocator) !*CalculatorWidget {
        var self = try allocator.create(CalculatorWidget);
        self.widget = gui.Widget.init(allocator);
        self.widget.onKeyDownFn = onKeyDown;
        self.calculator = Calculator{};
        self.keypad = Keypad{};

        self.entry_textbox = try gui.TextBox.create(allocator, Rect(f32).make(5, 5, 244, 26));
        self.entry_textbox.text_alignment = .Right;
        self.widget.addChild(&self.entry_textbox.widget);

        self.error_label = try gui.Label.create(allocator, Rect(f32).make(12, 42, 27, 27), "");
        self.error_label.text_alignment = .Center;
        self.error_label.draw_border = true;
        self.widget.addChild(&self.error_label.widget);

        self.updateDisplay();

        const digit_labels = "0\x001\x002\x003\x004\x005\x006\x007\x008\x009\x00";
        for (self.digit_buttons) |_, i| {
            const p = if (i != 0) i + 2 else 0;
            const x = @intToFloat(f32, 55 + (p % 3) * 39);
            const y = @intToFloat(f32, 177 - (p / 3) * 33);
            const text = digit_labels[2 * i .. 2 * i + 1 :0];
            self.digit_buttons[i] = try self.addButton(allocator, x, y, text, digitButtonClick);
        }

        self.mem_add_button = try self.addButton(allocator, 9, 177, "M+", makeOperationClick(.MemAdd).click);
        self.mem_save_button = try self.addButton(allocator, 9, 144, "MS", makeOperationClick(.MemSave).click);
        self.mem_recall_button = try self.addButton(allocator, 9, 111, "MR", makeOperationClick(.MemRecall).click);
        self.mem_clear_button = try self.addButton(allocator, 9, 78, "MC", makeOperationClick(.MemClear).click);

        self.clear_button = try self.addButton(allocator, 187, 40, "C", clearButtonClick);
        self.clear_button.rect.w = 60;
        self.clear_button.rect.h = 28;

        self.clear_error_button = try self.addButton(allocator, 124, 40, "CE", clearErrorButtonClick);
        self.clear_error_button.rect.w = 59;
        self.clear_error_button.rect.h = 28;

        self.backspace_button = try self.addButton(allocator, 55, 40, "Backspace", backspaceButtonClick);
        self.backspace_button.rect.w = 65;
        self.backspace_button.rect.h = 28;

        self.decimal_point_button = try self.addButton(allocator, 133, 177, ".", decimalPointButtonClick);

        self.sign_button = try self.addButton(allocator, 94, 177, "+/-", makeOperationClick(.ToggleSign).click);
        self.add_button = try self.addButton(allocator, 172, 177, "+", makeOperationClick(.Add).click);
        self.subtract_button = try self.addButton(allocator, 172, 144, "-", makeOperationClick(.Subtract).click);
        self.multiply_button = try self.addButton(allocator, 172, 111, "*", makeOperationClick(.Multiply).click);
        self.divide_button = try self.addButton(allocator, 172, 78, "/", makeOperationClick(.Divide).click);
        self.sqrt_button = try self.addButton(allocator, 211, 78, "sqrt", makeOperationClick(.Sqrt).click);
        self.inverse_button = try self.addButton(allocator, 211, 144, "1/x", makeOperationClick(.Inverse).click);
        self.percent_button = try self.addButton(allocator, 211, 111, "%", makeOperationClick(.Percent).click);
        self.equals_button = try self.addButton(allocator, 211, 177, "=", equalsButtonClick);

        return self;
    }

    fn addButton(self: *CalculatorWidget, allocator: *Allocator, x: f32, y: f32, text: [:0]const u8, on_click: fn (*gui.Button) void) !*gui.Button {
        var button = try gui.Button.create(allocator, Rect(f32).make(x, y, 35, 28), text);
        button.onClickFn = on_click;
        self.widget.addChild(&button.widget);
        return button;
    }

    fn getSelfFromChild(child: *gui.Widget) ?*CalculatorWidget {
        if (child.parent) |parent| return @fieldParentPtr(CalculatorWidget, "widget", parent);
        return null;
    }

    fn makeOperationClick(comptime operation: Calculator.Operation) type {
        return struct {
            fn click(button: *gui.Button) void {
                if (getSelfFromChild(&button.widget)) |self| {
                    const argument = self.keypad.getValue();
                    const result = self.calculator.beginOperation(operation, argument);
                    self.keypad.setValue(result);
                    self.updateDisplay();
                }
            }
        };
    }

    fn digitButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            self.keypad.typeDigit(button.text[0] - '0');
            self.updateDisplay();
        }
    }

    fn clearButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            self.keypad.setValue(0);
            self.calculator.clearOperation();
            self.updateDisplay();
        }
    }

    fn clearErrorButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            self.calculator.clearError();
            self.updateDisplay();
        }
    }

    fn backspaceButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            self.keypad.typeBackspace();
            self.updateDisplay();
        }
    }

    fn decimalPointButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            self.keypad.typeDecimalPoint();
            self.updateDisplay();
        }
    }

    fn equalsButtonClick(button: *gui.Button) void {
        if (getSelfFromChild(&button.widget)) |self| {
            const argument = self.keypad.getValue();
            const result = self.calculator.finishOperation(argument);
            self.keypad.setValue(result);
            self.updateDisplay();
        }
    }

    fn updateDisplay(self: *CalculatorWidget) void {
        self.entry_textbox.text.replaceContents(self.keypad.toString()) catch unreachable;
        self.error_label.text = if (self.calculator.has_error) "E" else "";
    }

    fn onKeyDown(widget: *gui.Widget, event: *const gui.KeyEvent) void {
        const self = @fieldParentPtr(CalculatorWidget, "widget", widget);
        
        switch (event.key) {
            .Return => self.keypad.setValue(self.calculator.finishOperation(self.keypad.getValue())),
            .D0, .D1, .D2, .D3, .D4, .D5, .D6, .D7, .D8, .D9 => self.keypad.typeDigit(@enumToInt(event.key) - @enumToInt(gui.KeyCode.D0)),
            .Period => self.keypad.typeDecimalPoint(),
            .Escape => {
                self.keypad.setValue(0);
                self.calculator.clearOperation();
            },
            .Backspace => self.keypad.typeBackspace(),
            .Plus, .Minus, .Asterisk, .Slash, .Percent => {
                const operation: Calculator.Operation = switch (event.key) {
                    .Plus => .Add,
                    .Minus => .Subtract,
                    .Asterisk => .Multiply,
                    .Slash => .Divide,
                    .Percent => .Percent,
                    else => unreachable,
                };
                self.keypad.setValue(self.calculator.beginOperation(operation, self.keypad.getValue()));
            },
            else => {}
        }

        self.updateDisplay();
    }
};
