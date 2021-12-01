const std = @import("std");

const alloc = std.heap.page_allocator;

pub fn main() anyerror!void {
    const file = try std.fs.cwd().openFile("input_real.txt", .{ .read = true });
    defer file.close();

    const contents = try file.reader().readAllAlloc(alloc, 1024 * 1024);
    defer alloc.free(contents);

    var depths = std.ArrayList(u32).init(alloc);
    defer depths.deinit();
    var splits = std.mem.split(contents, "\n");
    while (splits.next()) |split| {
        const v = try std.fmt.parseInt(u32, split, 10);
        try depths.append(v);
    }

    // try one(depths.items);
    try two(depths.items);
}

fn one(depths: []u32) anyerror!void {
    var increase_count: u32 = 0;
    var previous_depth: ?u32 = null;
    for (depths) |d| {
        if (previous_depth == null) {
            std.log.info("{d} (N/A)", .{d});
        } else if (previous_depth.? < d) {
            std.log.info("{d} (increased)", .{d});
            increase_count += 1;
        } else if (previous_depth.? == d) {
            std.log.info("{d} (same)", .{d});
        } else {
            std.log.info("{d} (decreased)", .{d});
        }
        previous_depth = d;
    }

    std.log.info("depth increases: {d}", .{increase_count});
}

fn two(depths: []u32) anyerror!void {
    var increase_count: u32 = 0;
    var previous_sum: ?u32 = null;
    var windows = [3]u32{ 0, 0, 0 };
    for (depths) |d, i| {
        if (i > 2) {
            const sum = windows[i % 3];
            if (should_increase(previous_sum, sum)) {
                increase_count += 1;
            }
            previous_sum = sum;
            windows[i % 3] = 0;
        }
        var wi: u8 = 0;
        while (wi < std.math.min(3, i + 1)) : (wi += 1) {
            windows[wi] += d;
        }
    }
    const sum = windows[depths.len % 3];
    if (should_increase(previous_sum, sum)) {
        increase_count += 1;
    }
    std.log.info("increase count: {any}", .{increase_count});
}

fn should_increase(previous_sum: ?u32, sum: u32) bool {
    if (previous_sum == null) {
        std.log.info("{any} (NA)", .{sum});
    } else if (previous_sum.? < sum) {
        std.log.info("{any} (increased)", .{sum});
        return true;
    } else if (previous_sum.? == sum) {
        std.log.info("{any} (same)", .{sum});
    } else {
        std.log.info("{any} (decreased)", .{sum});
    }
    return false;
}
