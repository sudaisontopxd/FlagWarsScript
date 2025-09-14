-- Loader.lua
-- Auto re-runs itself every single rejoin / server-hop (infinite)

local SCRIPT_PLACE_ID = 3214114884
local SCRIPT_URL = "https://raw.githubusercontent.com/sudaisontopxd/FlagWarsScript/refs/heads/main/RewriteAutoKill"
local LOADER_URL = "https://raw.githubusercontent.com/sudaisontopxd/FlagWarsScript/refs/heads/main/Loader.lua"

-- debounce: prevent double exec spam in the same session
do
    if getgenv().rz_last_exec and (tick() - getgenv().rz_last_exec) <= 2 then
        return
    end
    getgenv().rz_last_exec = tick()
end

-- small notifier
local function notify(msg)
    print("[Loader] " .. tostring(msg))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "FlagWars Loader",
            Text = msg,
            Duration = 5
        })
    end)
end

-- always queue the loader again (no one-time flag)
do
    local executor = syn or fluxus or {}
    local queueteleport = queue_on_teleport or executor.queue_on_teleport
    if type(queueteleport) == "function" then
        local self_code = ("loadstring(game:HttpGet('%s'))()"):format(LOADER_URL)
        pcall(queueteleport, self_code)
        notify("Loader queued for next server")
    else
        notify("queue_on_teleport not supported by executor")
    end
end

-- fetch + load utility
local function fetchAndLoad(url)
    local ok, res = pcall(game.HttpGet, game, url)
    if not ok or not res or res == "" then
        notify("Failed to fetch: " .. tostring(url))
        return nil
    end
    local fn, err = loadstring(res)
    if not fn then
        notify("Syntax error in: " .. tostring(url) .. "\n" .. tostring(err))
        return nil
    end
    return fn
end

-- run actual script if inside Flag Wars
if game.PlaceId == SCRIPT_PLACE_ID then
    local fn = fetchAndLoad(SCRIPT_URL)
    if fn then
        notify("Running RewriteAutoKill")
        local ok, err = pcall(fn, ...)
        if not ok then
            notify("Runtime error: " .. tostring(err))
        end
    end
end
