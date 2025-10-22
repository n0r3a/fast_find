 Fast Find (lua_fast_find.lua)

A lightning-fast, terminal-based file search utility for Linux. It uses Lua's unique speed advantage to search an instant-loading cache of your entire system instead of scanning your hard drive every time.

How It Works (The Speed Secret)

The script uses a simple two-step process to achieve its speed:

Build (Slow, Once): When you run --rebuild, the script runs a standard system find command to collect all file paths on your system.

Search (Instant, Every Time): The collected data is saved as a special Lua data structure (a table). When you search, Lua loads this entire file list instantly into memory using dofile(), making searches near-immediate.

usage and commands

command structure

argument

purpose

example

lua lua_fast_find.lua

--rebuild (Required for first use)

slow, one-time setup. indexes the entire system (/) and saves the fast cache file.

lua lua_fast_find.lua --rebuild

lua lua_fast_find.lua

<query>

The string to search for within file paths (case-insensitive).

lua lua_fast_find.lua "my_notes"

lua lua_fast_find.lua

<query> [limit]

Search, but limit the output to a specific number. The default limit is 0 (show all results).

lua lua_fast_find.lua "config" 100
