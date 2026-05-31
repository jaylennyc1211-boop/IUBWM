-- loader.lua
-- Minimal HTTP + loader helpers for common Roblox executors
local Loader = {}

function Loader.httpGet(url)
    -- Try game:HttpGet
    if type(game.HttpGet) == "function" then
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if ok and res then return res end
    end

    -- syn.request or similar
    if type(syn) == "table" and type(syn.request) == "function" then
        local res = syn.request({Url = url, Method = "GET"})
        return res and res.Body
    end

    -- older http_request hooks
    if type(http_request) == "function" then
        local r = http_request({Url = url, Method = "GET"})
        return r and r.Body
    end

    if type(request) == "function" then
        local r = request({Url = url, Method = "GET"})
        return r and r.Body
    end

    error("HTTP GET not available in this executor")
end

function Loader.safeLoadString(code, name)
    name = name or "@loader"
    if type(loadstring) == "function" then
        return assert(loadstring(code, name))
    elseif type(load) == "function" then
        return assert(load(code, name))
    else
        error("no loadstring or load available in this environment")
    end
end

function Loader.fetchAndExecute(url, name)
    local code = Loader.httpGet(url)
    local fn = Loader.safeLoadString(code, name or url)
    return fn()
end

return Loader
