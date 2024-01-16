const std = @import("std");

/// Contains a single ags table
/// TODO add function to dump to csv
/// TODO add function to check data rows against the types given
const ags_table = struct {
    group: []const u8,
    headings: []const u8,
    types: []const u8,
    data: [][]const u8,

    pub fn print_self(self: ags_table) void {
        std.debug.print("Group - {s}, Headings - {s}\n", .{ self.group, self.headings });
    }
};

/// private enum to store the type of a row for easier if statements
const row_type = enum {
    group,
    heading,
    types,
    data,
    empty,
};

/// Check whether a string starts with a given prefix
/// e.g. startsWith("test", "testing this string") = true
/// e.g. startsWith("test", "grouping this string") = false
fn startsWith(prefix: []const u8, str: []const u8) bool {
    const prefixLength = prefix.len;
    const strLength = str.len;

    if (prefixLength > strLength) {
        return false;
    }

    return std.mem.eql(u8, prefix, str[0..prefixLength]);
}

const returnTuple = std.meta.Tuple(&.{ row_type, []const u8 });

/// helper function to check the type of the current row in the ags file
fn row_processor(row: []const u8) !returnTuple {
    if (startsWith("\"DATA", row)) {
        return .{ row_type.data, row };
    } else if (startsWith("\"HEADING", row)) {
        return .{ row_type.heading, row };
    } else if (startsWith("\"TYPE", row)) {
        return .{ row_type.types, row };
    } else if (startsWith("\"GROUP", row)) {
        return .{ row_type.group, row };
    } else {
        return .{ row_type.empty, row };
    }
}

/// this function takes a link to an AGS File and parses
/// it to a standard struct enabling it to be transformed.
pub fn parse_ags(link: []const u8, gpa: std.mem.Allocator) ![]ags_table {
    var temp_buf: [1024]u8 = undefined;
    const cwd = try std.os.getcwd(&temp_buf);
    std.debug.print("{s}\n\n", .{cwd});
    var file = try std.fs.openFileAbsolute(link, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var output = std.ArrayList(ags_table).init(gpa);
    var data = std.ArrayList([]const u8).init(gpa);
    var temp: ags_table = undefined;
    var first = false;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const typer = try row_processor(line);
        //std.debug.print("{s}\n", .{@tagName(typer)});
        if (typer[0] == row_type.group) {
            //std.debug.print("{s}", .{line});
            if (first) {
                try output.append(temp);
                temp.data = try data.toOwnedSlice();
                temp = undefined;
                data = std.ArrayList([]const u8).init(gpa);
            } else {
                first = true;
            }
            temp.group = typer[1];
        } else if (typer[0] == row_type.types) {
            temp.types = typer[1];
        } else if (typer[0] == row_type.heading) {
            temp.headings = typer[1];
        } else if (typer[0] == row_type.data) {
            try data.append(typer[1]);
        } else if (typer[0] == row_type.empty) {}
    }
    return try output.toOwnedSlice();
}

test "test reading a ags file" {
    const link = "/home/samotron/Projects/agsparse/resources/test-ags.ags";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_ = gpa.allocator();
    var a = try parse_ags(link, gpa_);
    std.debug.print("Tables {}\n", .{a.len});
    for (a) |item| {
        item.print_self();
    }
}
