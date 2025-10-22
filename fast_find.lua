-- lua_fast_find.lua: A fast, cached file search utility for Linux.
-- made by n0r3a

-- configuration
local TARGET_DIR = "/"
local CACHE_FILE = os.getenv("HOME") .. "/.lua_find_cache.lua"
local DEFAULT_MAX_RESULTS = 0 -- CHANGED: Default is now 0 (NO LIMIT)

-- utility Functions

-- function to save the file list as a valid Lua table file
local function print_table_to_file(t)
    local f = io.open(CACHE_FILE, "w")
    if not f then
        io.stderr:write("error: could not open " .. CACHE_FILE .. " for writing.\n")
        return
    end

    f:write("return {\n")
    for _, path in ipairs(t) do
        -- escape single quotes to ensure the path is a valid lua string
        local escaped_path = string.gsub(path, "'", "\\'")
        f:write(string.format("  '%s',\n", escaped_path))
    end
    f:write("}\n")
    f:close()
    print("cache saved successfully to: " .. CACHE_FILE)
end

-- loads the file index directly from the cache file using dofile
local function load_cache()
    if not io.open(CACHE_FILE, "r") then
        return nil
    end

    -- pcall protects against errors if the cache file is corrupted
    local status, cache_data = pcall(dofile, CACHE_FILE)
    if not status then
        io.stderr:write("Warning: cache file is corrupted. deleting and forcing rebuild.\n")
        os.remove(CACHE_FILE)
        return nil
    end
    return cache_data
end

-- builds the file list using the unix 'find' command
local function build_cache()
    print("\n--- cache build in process ---")
    print("warning: indexing the whole system (/) is slow and requires skipping many directories.")
    print("building index of all files in: " .. TARGET_DIR)
    local start_time = os.clock()

    -- skip: /proc, /sys, /dev, /run, /tmp, /mnt, /media, or a .git/.cache
    local find_cmd = string.format(
        'find %s -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -path /run -prune -o -path /tmp -prune -o -path /mnt -prune -o -path /media -prune -o -path "*/.git" -prune -o -path "*/.cache" -prune -o -type f -print 2>/dev/null',
        TARGET_DIR
    )
    
    local pipe = io.popen(find_cmd, "r")
    if not pipe then
        io.stderr:write("fatal: failed to run 'find'. check permissions or path.\n")
        return nil
    end

    local file_list = {}
    for line in pipe:lines() do
        table.insert(file_list, line)
    end
    pipe:close()

    local total_time = os.clock() - start_time
    print(string.format("indexed %d files in %.2f seconds.", #file_list, total_time))
    print("-------------------------------\n")

    print_table_to_file(file_list)
    return file_list
end

-- main search

-- the max_results argument defaults to the global DEFAULT_MAX_RESULTS if nil
local function fast_search(query, max_results, force_rebuild)
    local limit = max_results or DEFAULT_MAX_RESULTS
    local file_index = nil
    
    if not force_rebuild then
        file_index = load_cache()
    end

    if not file_index then
        file_index = build_cache()
    end

    -- exit if index failed or query is empty
    if not file_index or query == "" then
        return
    end

    local start_search = os.clock()
    local matches = 0
    local query_lower = query:lower()

    -- limit status
    local is_limited = limit > 0
    local display_limit_text = is_limited and limit or "NO LIMIT"

    print("\n--- search results ---")
    print(string.format("searching %d cached paths for '%s' (limit: %s)...", #file_index, query, display_limit_text))

    -- in-memory search
    for _, path in ipairs(file_index) do
        if string.find(path:lower(), query_lower, 1, true) then
            print(path)
            matches = matches + 1
            -- check if we hit the limit, but only if a limit is set (limit > 0)
            if is_limited and matches >= limit then
                print(string.format("... showing first %d results. there may be more.", limit))
                break
            end
        end
    end

    local total_time = os.clock() - start_search
    print(string.format("\nfound %d total matches in %.4f seconds (on cached data).", matches, total_time))
end

-- program entry
local function show_help()
    print("fast lua file search utility")
    print("----------------------------")
    print("usage: lua lua_fast_find.lua <search_query> [max_results]")
    print("       lua lua_fast_find.lua --rebuild")
    print(string.format("\nnow indexing files starting from: %s (system root)", TARGET_DIR))
    -- Updated help message to reflect new default
    print("pass a positive number e.g. 100 to set a result limit.") 
    print(string.format("cache file location: %s", CACHE_FILE))
end

-- process arguments and search
local function main()
    local query = arg[1]
    local limit_arg = arg[2]
    local force_rebuild = false

    if query == "--rebuild" then
        -- rebuild cached file
        print("Forcing full system cache rebuild...")
        fast_search("", 0, true)
        return
    end

    if not query then
        show_help()
        return
    end

    -- search
    local limit = DEFAULT_MAX_RESULTS -- start with default (which is now 0)
    
    local custom_limit = tonumber(limit_arg)
    if custom_limit ~= nil then
        -- if a valid number is passed as arg[2], use it.
        limit = custom_limit
    elseif limit_arg then
        query = query .. " " .. limit_arg
        limit = DEFAULT_MAX_RESULTS -- Revert to default limit (0)
    end

    fast_search(query, limit, false)
end

main()

