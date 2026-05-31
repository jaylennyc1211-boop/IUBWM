-- main.lua
-- Bootstrap that loads modules from a hosting base using common executor HTTP methods.
-- Edit `base` to point at your GitHub raw repo (or host the scripts somewhere public).

local base = "https://raw.githubusercontent.com/TNT20002220/IUBWM/master/IUBWM/scripts/"

local function httpGet(url)
    if type(game.HttpGet) == "function" then
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if ok then return res end
    end
    if type(syn) == "table" and type(syn.request) == "function" then
        local res = syn.request({Url = url, Method = "GET"})
        return res and res.Body
    end
    if type(http_request) == "function" then
        local r = http_request({Url = url, Method = "GET"})
        return r and r.Body
    end
    if type(request) == "function" then
        local r = request({Url = url, Method = "GET"})
        return r and r.Body
    end
    error("No HTTP available in executor")
end

local function safeLoad(code, name)
    if type(loadstring) == "function" then
        return assert(loadstring(code, name))
    elseif type(load) == "function" then
        return assert(load(code, name))
    else
        error("no loadstring/load available")
    end
end

local function fetchModule(name)
    local url = base .. name
    local code = httpGet(url)
    return safeLoad(code, name)()
end

-- Example: load and start idle module
local success, err = pcall(function()
    local idle = fetchModule("idle.lua")
    if type(idle) == "table" and idle.start then
        idle.start()
        print("[main] idle started")
    else
        warn("[main] idle module did not return a valid table with start()")
    end
end)
if not success then warn("[main] error loading modules: "..tostring(err)) end

-- Simple console commands
_G.IUBWM = _G.IUBWM or {}
_G.IUBWM.stopAll = function()
    pcall(function()
        local idle = fetchModule("idle.lua")
        if type(idle.stop) == "function" then idle.stop() end
    end)
    print("[main] stopAll invoked")
end

print("[main] bootstrap complete. Use _G.IUBWM.stopAll() to stop modules.")
