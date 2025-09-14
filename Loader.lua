-- Loader.lua
-- Auto-requeueing loader for Flag Wars (always re-runs after every join / server-hop)
-- Put this file at:
-- https://raw.githubusercontent.com/sudaisontopxd/FlagWarsScript/refs/heads/main/Loader.lua

local _ENV = (getgenv or getrenv or getfenv)()

-- CONFIG
local SCRIPT_PLACE_ID = 3214114884
local SCRIPT_URL = "https://raw.githubusercontent.com/sudaisontopxd/FlagWarsScript/refs/heads/main/RewriteAutoKill"
local LOADER_URL = "https://raw.githubusercontent.com/sudaisontopxd/FlagWarsScript/refs/heads/main/Loader.lua"

-- short debounce so the loader doesn't re-run immediately multiple times
do
    local last_exec = _ENV.rz_execute_debounce
    if last_exec and (tick() - last_exec) <= 2 then
        return nil
    end
    _ENV.rz_execute_debounce = tick()
end

-- helper: show a tiny Message in workspace so you can see loader ran
local function notify(text)
    pcall(function()
        if _ENV.rz_loader_message and _ENV.rz_loader_message.Parent then
            _ENV.rz_loader_message:Destroy()
            _ENV.rz_loader_message = nil
        end
        local m = Instance.new("Message", workspace)
        m.Text = "[Loader] " .. tostring(text)
        _ENV.rz_loader_message = m
        -- destroy after 4 seconds
        task.delay(4, function()
            pcall(function() if m and m.Parent then m:Destroy() end end)
        end)
    end)
end

-- error helper
local function create_error(msg)
    notify("Error: " .. tostring(msg))
    error(msg, 2)
end

-- fetch + compile
local function fetchAndCompile(url)
    local ok, res = pcall(game.HttpGet, game, url)
    if not ok or not res or res == "" then
        return nil, ("failed to fetch: %s (ok=%s)"):format(tostring(url), tostring(ok))
    end
    local fn, err = loadstring(res)
    if not fn then
        return nil, ("loadstring error: %s"):format(tostring(err))
    end
    return fn
end

-- ALWAYS queue the loader itself for the next teleport/hop
do
    local executor = (syn and syn) or (fluxus and fluxus) or {}
    local queueteleport = queue_on_teleport or executor.queue_on_teleport

    if type(queueteleport) == "function" then
        -- code to be queued: re-download & run loader on next join
        local queue_code = ("loadstring(game:HttpGet('%s'))()"):format(LOADER_URL)
        -- pcall in case executor denies or errors
        pcall(function()
            queueteleport(queue_code)
        end)
        -- small notify so you know the loader queued itself
        notify("Queued loader for next hop")
    else
        -- executor doesn't support queue_on_teleport
        notify("queue_on_teleport not found — teleport re-run unavailable")
    end
end

-- If we are in the Flag Wars place, fetch & run the actual script
if game.PlaceId == SCRIPT_PLACE_ID then
    -- fetch the actual script
    local fn, err = fetchAndCompile(SCRIPT_URL)
    if not fn then
        create_error(err)
    end

    notify("Running RewriteAutoKill now")
    -- run protected so errors from the user's script don't break queueing behavior next time
    local ok, run_err = pcall(fn, fetchAndCompile, ...)
    if not ok then
        create_error("RewriteAutoKill runtime error: " .. tostring(run_err))
    end
end
