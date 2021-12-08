const std = @import("std");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var alloc = &gpa.allocator;

pub fn main() anyerror!void {
    std.log.info("START", .{});
    const file = try std.fs.cwd().openFile("input_real.txt", .{ .read = true });
    defer file.close();
    const contents = try file.reader().readAllAlloc(alloc, 1024 * 1024);
    defer alloc.free(contents);

    var lines = std.ArrayList([]const u8).init(alloc);
    defer lines.deinit();
    var splitIterator = std.mem.split(contents, "\n");
    while (splitIterator.next()) |line| {
        try lines.append(line);
    }
    std.debug.assert(lines.items.len > 1);

    var bitSets = try std.ArrayList(std.DynamicBitSet).initCapacity(alloc, lines.items[0].len);
    var bitSetCount: usize = 0;
    while (bitSetCount < lines.items[0].len) : (bitSetCount += 1) {
        const bs = try std.DynamicBitSet.initEmpty(lines.items.len, alloc);
        try bitSets.append(bs);
    }

    for (lines.items) |line, lineIdx| {
        for (line) |c, cIdx| {
            if (c == '1') {
                var bs = &bitSets.items[cIdx];
                bs.set(lineIdx);
            }
        }
    }

    try part1(lines.items.len, bitSets);
    try part2(lines, bitSets);

    std.log.info("END", .{});
}

fn part1(lineCount: usize, bitSets: std.ArrayList(std.DynamicBitSet)) !void {
    var gammaRate: usize = 0;
    var epsilonRate: usize = 0;
    for (bitSets.items) |bs, i| {
        const shift = std.math.shl(usize, 1, bitSets.items.len - i - 1);
        if (bs.count() > lineCount / 2) {
            gammaRate |= shift;
        } else {
            epsilonRate |= shift;
        }
    }
    std.log.info("power: {d} * {d}: {d}", .{ gammaRate, epsilonRate, gammaRate * epsilonRate });
}

fn part2(lines: std.ArrayList([]const u8), bitSets: std.ArrayList(std.DynamicBitSet)) !void {
    var o2Set = try std.DynamicBitSet.initFull(lines.items.len, alloc);
    var co2Set = try std.DynamicBitSet.initFull(lines.items.len, alloc);
    defer o2Set.deinit();
    defer co2Set.deinit();
    for (bitSets.items) |bs, bsi| {
        if (o2Set.count() > 1) {
            const o2New = try calculateNarrowedSet(o2Set, bs, false);
            o2Set.deinit();
            o2Set = o2New;
        }
        if (co2Set.count() > 1) {
            const co2New = try calculateNarrowedSet(co2Set, bs, true);
            co2Set.deinit();
            co2Set = co2New;
        }
    }
    const o2i = o2Set.findFirstSet() orelse unreachable;
    const o2int = try std.fmt.parseInt(usize, lines.items[o2i], 2);
    std.log.info("o2: {any} {s} {d}", .{ o2i, lines.items[o2i], o2int });
    const co2i = co2Set.findFirstSet() orelse unreachable;
    const co2int = try std.fmt.parseInt(usize, lines.items[co2i], 2);
    std.log.info("co2: {any} {s} {d}", .{ co2i, lines.items[co2i], co2int });
    std.log.info("life support: {d}", .{o2int * co2int});
}

fn calculateNarrowedSet(indexSet: std.DynamicBitSet, comparisonSet: std.DynamicBitSet, invert: bool) !std.DynamicBitSet {
    var normal = try comparisonSet.clone(alloc);
    var inverted = try comparisonSet.clone(alloc);
    inverted.toggleAll();
    normal.setIntersection(indexSet);
    inverted.setIntersection(indexSet);
    if ((!invert and normal.count() >= inverted.count()) or (invert and inverted.count() > normal.count())) {
        inverted.deinit();
        return normal;
    } else {
        normal.deinit();
        return inverted;
    }
}
