const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc = &gpa.allocator;

const Op = struct { direction: Direction, units: u8 };

const Direction = enum { up, down, forward };

pub fn main() anyerror!void {
    const file = try std.fs.cwd().openFile("input_real.txt", .{ .read = true });
    defer file.close();
    const contents = try file.reader().readAllAlloc(alloc, 1024 * 1024);
    defer alloc.free(contents);

    const instructions = try parse(contents);
    defer instructions.deinit();

    // try one(instructions);
    try two(instructions);
}

fn one(instructions: std.ArrayList(Op)) !void {
    var depth: u32 = 0;
    var horiz: u32 = 0;
    for (instructions.items) |item| {
        switch (item.direction) {
            Direction.down => depth += item.units,
            Direction.up => depth -= item.units,
            Direction.forward => horiz += item.units,
        }
    }

    std.log.info("depth: {d}, horiz: {d}, mult: {d}", .{ depth, horiz, depth * horiz });
}

fn two(instructions: std.ArrayList(Op)) !void {
    var depth: u32 = 0;
    var horiz: u32 = 0;
    var aim: u32 = 0;
    for (instructions.items) |item| {
        switch (item.direction) {
            Direction.down => aim += item.units,
            Direction.up => aim -= item.units,
            Direction.forward => {
                horiz += item.units;
                depth += aim * item.units;
            },
        }
    }

    std.log.info("depth: {d}, horiz: {d}, mult: {d}", .{ depth, horiz, depth * horiz });
}

fn parse(contents: []const u8) !std.ArrayList(Op) {
    var instructions = std.ArrayList(Op).init(alloc);
    var tokenIterator = std.mem.tokenize(contents, " \n");
    var direction: ?Direction = null;
    while (tokenIterator.next()) |token| {
        if (direction == null) {
            if (std.mem.eql(u8, token, "forward")) {
                direction = Direction.forward;
            } else if (std.mem.eql(u8, token, "up")) {
                direction = Direction.up;
            } else if (std.mem.eql(u8, token, "down")) {
                direction = Direction.down;
            } else {
                std.log.err("Encountered unexpected direction: {s}", .{token});
                return error.ParseError;
            }
        } else {
            const units = try std.fmt.parseInt(u8, token, 10);
            try instructions.append(.{ .direction = direction.?, .units = units });
            direction = null;
        }
    }
    return instructions;
}
