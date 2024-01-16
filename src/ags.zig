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

fn startsWith(prefix: []const u8, str: []const u8) bool {
    const prefixLength = prefix.len;
    const strLength = str.len;

    if (prefixLength > strLength) {
        return false;
    }

    return std.mem.eql(u8, prefix, str[0..prefixLength]);
}

fn row_processor(row: []const u8) !row_type {
    if (startsWith("\"DATA", row)) {
        return row_type.data;
    } else if (startsWith("\"HEADING", row)) {
        return row_type.heading;
    } else if (startsWith("\"TYPE", row)) {
        return row_type.types;
    } else if (startsWith("\"GROUP", row)) {
        return row_type.group;
    } else {
        return row_type.empty;
    }
}

/// this function takes a link to an AGS File and parses
/// it to a standard struct enabling it to be transformed.
pub fn parse_ags(link: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const gpa_ = gpa.allocator();
    var temp_buf: [1024]u8 = undefined;
    const cwd = try std.os.getcwd(&temp_buf);
    std.debug.print("{s}\n\n", .{cwd});
    var file = try std.fs.openFileAbsolute(link, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var output = std.ArrayList(ags_table).init(gpa_);
    var temp: ags_table = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const typer = try row_processor(line);
        std.debug.print("{s}\n", .{@tagName(typer)});
        if (typer == row_type.group) {
            temp.group = line;
        } else if (typer == row_type.empty) {
            try output.append(temp);
            temp = undefined;
        }
    }
}

test "test reading a ags file" {
    const link = "/home/samotron/Projects/agsparse/resources/test-ags.ags";
    try parse_ags(link);
}
