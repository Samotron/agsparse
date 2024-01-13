const std = @import("std");

const ags_table = struct {
    group: []u8,
    headings: [][]u8,
    types: [][]u8,
    data: [][][]u8,
};

const row_type = enum {
    group,
    heading,
    types,
    data,
    empty,
};

fn row_processor(row: []const u8) !void {
    var split = std.mem.split(u8, row, ",");
    std.debug.print("{}", split.next().?);
}

/// this function takes a link to an AGS File and parses
/// it to a standard struct enabling it to be transformed.
pub fn parse_ags(link: []const u8) !void {
    var temp_buf: [1024]u8 = undefined;
    const cwd = try std.os.getcwd(&temp_buf);
    std.debug.print("{s}\n\n", .{cwd});
    var file = try std.fs.openFileAbsolute(link, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        try row_processor(line);
        //std.debug.print("{s}", .{line});
    }
}

test "test reading a ags file" {
    const link = "/home/samotron/Projects/agsparse/resources/test-ags.ags";
    try parse_ags(link);
}
