const std = @import("std");
const fmt = std.fmt;
const io = std.io;

pub const Keypad = struct {
    // Internal representation of the current decimal value.
    negative: bool = false,
    int_value: u64 = 0,
    frac_value: u64 = 0,
    frac_length: u8 = 0,
    // E.g. for -35.004200,
    // negative = true
    // int_value = 35
    // frac_value = 4200
    // frac_length = 6

    state: State = .External,

    buffer: [200]u8 = undefined,

    const State = enum(u8) {
        External,
        TypingInteger,
        TypingDecimal,
    };

    pub fn typeDigit(self: *Keypad, digit: u8) void {
        switch (self.state) {
            .External => {
                self.state = .TypingInteger;
                self.negative = false;
                self.int_value = digit;
                self.frac_value = 0;
                self.frac_length = 0;
            },
            .TypingInteger => {
                std.debug.assert(self.frac_value == 0);
                std.debug.assert(self.frac_length == 0);
                self.int_value *= 10;
                self.int_value += digit;
            },
            .TypingDecimal => {
                if (self.frac_length < 6) {
                    self.frac_value *= 10;
                    self.frac_value += digit;
                    self.frac_length += 1;
                }
            },
        }
    }

    pub fn typeDecimalPoint(self: *Keypad) void {
        switch (self.state) {
            .External => {
                self.negative = false;
                self.int_value = 0;
                self.frac_value = 0;
                self.frac_length = 0;
            },
            .TypingInteger => {
                std.debug.assert(self.frac_value == 0);
                std.debug.assert(self.frac_length == 0);
                self.state = .TypingDecimal;
            },
            .TypingDecimal => {}, // Ignore
        }
    }

    pub fn typeBackspace(self: *Keypad) void {
        switch (self.state) {
            .External => {
                self.state = .TypingInteger;
                self.negative = false;
                self.int_value = 0;
                self.frac_value = 0;
                self.frac_length = 0;
            },
            .TypingInteger => {
                std.debug.assert(self.frac_value == 0);
                std.debug.assert(self.frac_length == 0);
                self.int_value = @divTrunc(self.int_value, 10);
                if (self.int_value == 0)
                    self.negative = false;
            },
            .TypingDecimal => {
                if (self.frac_length > 0) {
                    self.frac_value = @divTrunc(self.frac_value, 10);
                    self.frac_length -= 1;
                    if (self.frac_length == 0) {
                        self.state = .TypingInteger;
                    }
                }
            },
        }
    }

    pub fn getValue(self: *Keypad) f64 {
        var res: f64 = 0.0;

        var frac: u64 = self.frac_value;
        var i: u8 = 0;
        while (i < self.frac_length) : (i += 1) {
            var digit: u64 = frac % 10;
            res += @intToFloat(f64, digit);
            res /= 10.0;
            frac = @divTrunc(frac, 10);
        }

        res += @intToFloat(f64, self.int_value);
        if (self.negative)
            res = -res;

        return res;
    }

    pub fn setValue(self: *Keypad, value: f64) void {
        self.state = .External;

        var in_value = value;

        if (in_value < 0.0) {
            self.negative = true;
            in_value = -in_value;
        } else
            self.negative = false;

        self.int_value = @floatToInt(u64, in_value);
        in_value -= @intToFloat(f64, self.int_value);

        self.frac_value = 0;
        self.frac_length = 0;
        while (in_value != 0) {
            in_value *= 10.0;
            var digit: u64 = @floatToInt(u64, in_value);
            self.frac_value *= 10;
            self.frac_value += digit;
            self.frac_length += 1;
            in_value -= @intToFloat(f64, digit);

            if (self.frac_length > 6)
                break;
        }
    }

    pub fn toString(self: *Keypad) []const u8 {
        var fbs = io.fixedBufferStream(&self.buffer);

        if (self.negative)
            _ = fbs.write("-") catch unreachable;
        fmt.formatIntValue(self.int_value, "", fmt.FormatOptions{}, fbs.writer()) catch unreachable;

        if (self.frac_length > 0) {
            _ = fbs.write(".") catch unreachable;
            fmt.formatIntValue(self.frac_value, "", fmt.FormatOptions{ .width = @intCast(usize, self.frac_length), .fill = '0' }, fbs.writer()) catch unreachable;
        }

        return fbs.getWritten();
    }
};
