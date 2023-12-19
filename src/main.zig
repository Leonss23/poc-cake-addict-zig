const std = @import("std");
const c = @cImport({
    @cInclude("ncurses.h");
});

var rand: std.rand.Random = undefined;

pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(blk: {
        var buf: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&buf));
        break :blk buf;
    });
    rand = prng.random();

    const window = c.initscr();
    _ = c.keypad(window, true);
    _ = c.nodelay(window, true);
    _ = c.curs_set(0);
    var player = PlayerCharacter.init();
    var food = Food.init();
    var score: usize = 0;

    while (true) {
        const pressed = c.wgetch(window);
        switch (pressed) {
            c.KEY_UP => player.direction = Direction.up,
            c.KEY_RIGHT => player.direction = Direction.right,
            c.KEY_DOWN => player.direction = Direction.down,
            c.KEY_LEFT => player.direction = Direction.left,
            else => {},
        }
        switch (player.direction) {
            .up => player.position.y -= 1,
            .down => player.position.y += 1,
            .right => player.position.x += 1,
            .left => player.position.x -= 1,
        }

        if (Position.eql(player.position, food.position)) {
            score += 1;
            food.randomize_pos();
        }

        _ = c.erase();
        var buf: [16]u8 = undefined;
        draw_str(.{ .x = 60, .y = 0 }, try std.fmt.bufPrint(&buf, "score: {}", .{score}));
        player.draw();
        food.draw();
        std.time.sleep(1_000_000_000 * 0.2);
    }

    defer _ = c.endwin();
}

const Position = struct {
    x: isize = 0,
    y: isize = 0,

    fn eql(a: Position, b: Position) bool {
        if (a.x == b.x and a.y == b.y) {
            return true;
        }
        return false;
    }
};

const Direction = enum {
    up,
    right,
    down,
    left,
};

const PlayerCharacter = struct {
    const char = "*";
    position: Position = Position{},
    direction: Direction = Direction.right,

    fn init() PlayerCharacter {
        return PlayerCharacter{};
    }

    fn draw(self: PlayerCharacter) void {
        draw_str(self.position, char);
    }
};

const Food = struct {
    const char = "&";
    position: Position = Position{},

    fn init() Food {
        var new = Food{};
        new.randomize_pos();
        return new;
    }

    fn randomize_pos(self: *Food) void {
        self.position.x = @mod(rand.int(isize), 20);
        self.position.y = @mod(rand.int(isize), 20);
    }

    fn draw(self: Food) void {
        draw_str(self.position, char);
    }
};

fn draw_str(pos: Position, str: []const u8) void {
    _ = c.mvaddstr(@intCast(pos.y), @intCast(pos.x), @ptrCast(str));
}
