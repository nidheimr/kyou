const std = @import("std");

const IN_CHUNK_SIZE = 4096;
const OUT_CHUNK_SIZE = 16;

fn output_file(file_name: []const u8) !void {
    const stdout = std.io.getStdOut().writer();

    // open the file
    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    defer file.close();

    // read the file
    var byte_buffer: [IN_CHUNK_SIZE]u8 = undefined;
    var file_size: usize = 0;
    var total_prints: usize = 0;

    while (true) {
        // read the next IN_CHUNK_SIZE bytes from the file
        const byte_count = try file.read(&byte_buffer);
        if (byte_count == 0) break;

        // print the read bytes in OUT_CHUNK_SIZE portions
        var i: usize = 0;
        while (i < byte_count) {
            // get the next OUT_CHUNK_SIZE bytes from the buffer
            const end = if (i + OUT_CHUNK_SIZE > byte_count) byte_count else i + OUT_CHUNK_SIZE;
            const part = byte_buffer[i..end];

            // print prefix
            try stdout.print("{X:0>7}0      ", .{total_prints});

            // print hex
            for (0..OUT_CHUNK_SIZE) |idx| {
                if (idx >= part.len) {
                    try stdout.print("   ", .{});
                } else {
                    try stdout.print("{X:0>2} ", .{part[idx]});
                }
            }

            // print spacer
            try stdout.print("     ", .{});

            // print ascii or a dot if its not a readable character
            for (part) |byte| {
                if (byte < 0x20 or byte > 0x7E) {
                    try stdout.print(". ", .{});
                } else {
                    try stdout.print("{c} ", .{byte});
                }
            }

            // print newline
            try stdout.print("\n", .{});

            i += OUT_CHUNK_SIZE;
            total_prints += 1;
        }

	file_size += byte_count;
    }

    // print some stats about the file
    try stdout.print("\nFILE: {s}\nSIZE: {d} bytes\n", .{ file_name, file_size });
}

pub fn main() !void {
    // get args
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) {
        std.log.err("kyou <file>", .{});
        return;
    }

    // print the file as hex and ascii
    output_file(args[1]) catch |err| {
        switch (err) {
            error.FileNotFound => {
                std.log.err("file not found", .{});
            },
            else => {
                std.log.err("something went wrong", .{});
            },
        }
    };
}
