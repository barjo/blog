I spend most of my day in terminals, browsers, video calls and Slack. I have a rough sense of where my hours go, but I wanted cold hard data to back it up.

So I wrote a small Zig program called [ebyt](https://github.com/barjo/ebyt) (Every Byte You Track). It runs as a daemon, polls X11 every few seconds to see which window is focused, and logs everything to SQLite.

I like having my own activity data. And Zig is the first new language I've picked up since coding assistants got actually good.

It's also the first time I've written low-level code in a long while. The last time was [a paper](https://dl.acm.org/doi/10.5555/2694476.2694487) over a decade ago, also SQLite adjacent. Funny how things come back around.

## Why track your own activity

Plenty of tools do this already. [ActivityWatch](https://activitywatch.net/) and [arbtt](https://arbtt.nomeata.de/) are both excellent. ActivityWatch felt a bit heavy for what I wanted, arbtt is great but the data lives in a custom format. What I really wanted was:

- An X11 daemon that polls every few seconds and writes to a database I already know how to query.
- AFK detection so idle time doesn't pollute the numbers.
- A small TUI to glance at the day or week.
- That's it. No plugins, no config, no external services.

SQLite was the obvious storage. Once activity is in a table, anything is one query away:

```sql
SELECT window_class, SUM(end_time - start_time) AS seconds
FROM activities
WHERE afk = 0 AND start_time > unixepoch('now', '-7 days')
GROUP BY window_class
ORDER BY seconds DESC;
```

Knowing where my hours go has been quietly useful. Not to convince myself to procrastinate less, more to notice patterns. When context switches spike. What a focused day actually looks like.

It's also a way to keep myself honest about what's sustainable. When a week is actually too much, the data says so. Nicer thing to push back with than a feeling.

## Why Zig

I'd been wanting to try [Zig](https://ziglang.org/) for a while. The pitch is "C, with the rough edges sanded down", which fits a tracker like this. Tiny binary, libc-friendly, talks to X11 and sqlite3 directly.

A few things I really liked.

**Explicit allocators.** Functions that allocate take an `std.mem.Allocator` parameter. No global heap hiding behind the scenes. The daemon's hot loop allocates exactly once at startup (the database path) and reuses fixed-size 256-byte buffers afterwards. You can see, in code, where memory comes from.

**`defer` for cleanup.** No try/finally, no destructors with implicit ordering. The cleanup sits right next to the resource:

```zig
const db_path = try getDbPath(allocator);
defer allocator.free(db_path);
```

**Optionals replace nulls.** `?*c.Display` is "pointer or none", and the compiler refuses to let you forget the "none" case. Same idea as `Maybe` in Elm or `Option` in Rust, but it falls out of pointer types naturally.

**`@cImport` is magic.** You point Zig at C headers and it generates bindings on the fly:

```zig
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("sqlite3.h");
});
```

That's the entire C interop layer. No bindings crate, no header parsing dance. The build script does `linkSystemLibrary("sqlite3", .{})` and you're done.

Not everything translates cleanly though. `XISetMask` is a C macro, not a function, so `@cImport` silently skips it. I had to reimplement it as a Zig fn, which is its own little lesson in how thin C macros really are.

## The build is also Zig

Two things in Zig really surprised me: the build system and how tests work.

`build.zig` is a Zig program. No Makefile, no JSON, no DSL. You import `std.Build`, write Zig that builds a graph of steps, and `zig build` runs it. For ebyt the whole script is about 50 lines and looks like the rest of the code:

```zig
mod.linkSystemLibrary("x11", .{});
mod.linkSystemLibrary("xi", .{});
mod.linkSystemLibrary("sqlite3", .{});
```

Cross-compiling, custom run steps, dependency fetching, all the same language and compiler. Modern languages seem to lean this way, making the build a first-class citizen (Elixir's `mix.exs` is in the same vein, Haskell and OCaml have done it for years). Makefiles still earn their place orchestrating across these builds, but inside a project, "the build is just code" feels really nice.

Tests are just as unceremonious. There is no test framework, `test` is a keyword. You drop a block at the bottom of any file, right next to the function it exercises:

```zig
test "xiSetMask sets correct bits" {
    var mask = [_]u8{0} ** 4;
    xiSetMask(&mask, 0);
    try std.testing.expectEqual(@as(u8, 0x01), mask[0]);
}
```

`zig build test` runs every test block in the project. Tests sit in the same file as the code they test, which means no `tests/` mirroring `src/`, and you can test private functions without exporting them. After Elixir/JS/Python muscle memory, that took a minute to get used to.

## Picking up Zig with an assistant

Zig is the first language I've learned since coding assistants stopped being toys. A few notes.

The good. When I asked *"how do I select XInput2 raw events from Zig"*, I got a working snippet in seconds. Stack Overflow has roughly zero hits for Zig + X11. The assistant filled the gap nicely and pointed me at idioms I would have spent hours grepping for.

The catch. Zig is moving fast (the project went from 0.14 to 0.15 mid-development) and assistants happily produce code for whatever version they were trained on. I had a stretch where every other suggestion used a removed `std.io.getStdOut()` API. The fix was pinning the language version in `.tool-versions`, sharing recent reference code, and trusting the compiler over the suggestion.

The bonus. Compilers with good error messages pair really well with coding assistants. Elixir and Elm have taught me this for a while, Zig fits the same mold. When the assistant was wrong, the compiler told me exactly why, and I learned more from chasing those errors than from any tutorial.

So overall, an assistant is a great way to bootstrap. It gets you past the "I don't even know what to type" wall in a few hours. After that, it's still useful but you're learning the language, not the assistant. Don't ship anything you haven't read line by line.

## Wrap up

Well, ebyt is around 1800 lines, opinionated, and exactly what I wanted. The repo is on [GitHub](https://github.com/barjo/ebyt). If you're on Arch, `yay -S ebyt-bin` 🎉.
