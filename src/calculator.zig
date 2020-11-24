const math = @import("std").math;

pub const Calculator = struct {
    pub const Operation = enum(u8) {
        None,
        Add,
        Subtract,
        Multiply,
        Divide,

        Sqrt,
        Inverse,
        Percent,
        ToggleSign,

        MemClear,
        MemRecall,
        MemSave,
        MemAdd,
    };

    operation_in_progress: Operation = .None,
    saved_argument: f64 = 0,
    mem: f64 = 0,
    has_error: bool = false,

    pub fn beginOperation(self: *Calculator, operation: Operation, argument: f64) f64 {
        var result: f64 = 0;
        switch (operation) {
            .None => {},

            .Add, .Subtract, .Multiply, .Divide => {
                self.saved_argument = argument;
                self.operation_in_progress = operation;
                return argument;
            },

            .Sqrt => {
                if (argument < 0) {
                    self.has_error = true;
                    return argument;
                }
                result = math.sqrt(argument);
                self.clearOperation();
            },
            .Inverse => {
                if (argument == 0) {
                    self.has_error = true;
                    return argument;
                }
                result = 1 / argument;
                self.clearOperation();
            },
            .Percent => result = argument * 0.01,
            .ToggleSign => result = -argument,

            .MemClear => {
                self.mem = 0;
                result = argument;
            },
            .MemRecall => result = self.mem,
            .MemSave => {
                self.mem = argument;
                result = argument;
            },
            .MemAdd => {
                self.mem += argument;
                result = self.mem;
            },
        }
        return result;
    }

    pub fn finishOperation(self: *Calculator, argument: f64) f64 {
        var result: f64 = 0;
        switch (self.operation_in_progress) {
            .None => result = argument,

            .Add => result = self.saved_argument + argument,
            .Subtract => result = self.saved_argument - argument,
            .Multiply => result = self.saved_argument * argument,
            .Divide => {
                if (argument == 0) {
                    self.has_error = true;
                    return argument;
                }
                result = self.saved_argument / argument;
            },

            .Sqrt, .Inverse, .Percent, .ToggleSign => unreachable,

            .MemClear, .MemRecall, .MemSave, .MemAdd => unreachable,
        }
        self.clearOperation();
        return result;
    }

    pub fn clearError(self: *Calculator) void {
        self.has_error = false;
    }

    pub fn clearOperation(self: *Calculator) void {
        self.operation_in_progress = .None;
        self.saved_argument = 0;
        self.clearError();
    }
};
