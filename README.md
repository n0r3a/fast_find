fast_find

a fast terminal-based file search utility for Linux. it uses lua's speed to search an instant-loading cache of your entire system instead of scanning your hard drive every time


how it works:
the script uses two steps to achieve its speed:
1.) search: the collected data is saved as a special lua data structure (a table)
2.) when you search, lua loads this entire file list instantly into memory using dofile(), making searches almost immediate


arguments

lua fast_find.lua --rebuild | deletes the old cache file and indexes the entire system (/) to create a fresh list (required for first use)

lua fast_find.lua "my_notes" | the string to search for within file paths (case-insensitive)

lua fast_find.lua "conf" 100 | search, but limit the output to a specific number (the default limit is 0 = show all results)
