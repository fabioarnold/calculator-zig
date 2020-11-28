pub fn Point(comptime T: type) type {
    return struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn make(x: T, y: T) Self {
            return .{ .x = x, .y = y };
        }
    };
}

pub fn Rect(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        w: T,
        h: T,

        const Self = @This();

        pub fn make(x: T, y: T, w: T, h: T) Self {
            return .{ .x = x, .y = y, .w = w, .h = h };
        }

        pub fn contains(self: Self, point: Point(T)) bool {
            return point.x >= self.x and point.x < self.x + self.w and point.y >= self.y and point.y < self.y + self.h;
        }

        pub fn overlaps(self: Self, other: Rect(T)) bool {
            return self.x < other.x + other.w and self.x + self.w > other.x and self.y < other.y + other.h and self.y + self.h > other.y;
        }
    };
}
