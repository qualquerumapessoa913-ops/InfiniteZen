-- ============================================================
-- INFINITE ZEN - COMPATIBILITY LAYER v1.1
-- Auto-detects executor capabilities and provides fallbacks
-- ============================================================

local Compat = {}

-- ═══════════════════════════════════════════════
-- SAFE LOOKUP (CORRIGIDO)
-- ═══════════════════════════════════════════════
local function safeGet(name)
    -- 1. _G direto
    if _G and _G[name] ~= nil then return _G[name] end

    -- 2. getgenv (Real, Delta, Xeno, Synapse)
    if getgenv then
        local ok, genv = pcall(getgenv)
        if ok and genv and genv[name] ~= nil then return genv[name] end
    end

    -- 3. getfenv(0) — env global do executor
    local ok, val = pcall(function() return getfenv(0)[name] end)
    if ok and val ~= nil then return val end

    -- 4. getfenv() — env atual
    ok, val = pcall(function() return getfenv()[name] end)
    if ok and val ~= nil then return val end

    -- 5. loadstring("return " .. name) — último recurso
    if loadstring then
        ok, val = pcall(function() return loadstring("return " .. name)() end)
        if ok and val ~= nil then return val end
    end

    return nil
end

-- ═══════════════════════════════════════════════
-- IDENTIFY
-- ═══════════════════════════════════════════════
function Compat.getExecutor()
    local fn = safeGet("identifyexecutor") or safeGet("getexecutorname")
    if type(fn) == "function" then
        local ok, name = pcall(fn)
        if ok and name then return tostring(name) end
    end
    return "Unknown"
end

function Compat.getIdentity()
    local fn = safeGet("getidentity") or safeGet("getthreadidentity")
    if type(fn) == "function" then
        local ok, id = pcall(fn)
        if ok and id then return id end
    end
    return 2
end

-- ═══════════════════════════════════════════════
-- HWID
-- ═══════════════════════════════════════════════
function Compat.getHWID()
    local fn = safeGet("gethwid")
    if type(fn) == "function" then
        local ok, hwid = pcall(fn)
        if ok and hwid and #tostring(hwid) > 0 then return tostring(hwid) end
    end
    if syn and syn.get_hwid then
        local ok, hwid = pcall(syn.get_hwid)
        if ok and hwid then return tostring(hwid) end
    end
    local plr = game:GetService("Players").LocalPlayer
    if plr then return tostring(plr.UserId) .. "_" .. plr.Name end
    return "unknown"
end

-- ═══════════════════════════════════════════════
-- HTTP
-- ═══════════════════════════════════════════════
function Compat.httpGet(url)
    if type(url) ~= "string" then return nil end
    if game.HttpGet then
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if ok and res then return res end
    end
    if game.HttpGetAsync then
        local ok, res = pcall(function() return game:HttpGetAsync(url) end)
        if ok and res then return res end
    end
    local fn = safeGet("HttpGet")
    if type(fn) == "function" then
        local ok, res = pcall(fn, url)
        if ok and res then return res end
    end
    return nil
end

-- ═══════════════════════════════════════════════
-- MOUSE
-- ═══════════════════════════════════════════════
function Compat.mouseClick()
    local fn = safeGet("mouse1click")
    if type(fn) == "function" then
        local ok = pcall(fn)
        if ok then return true end
    end
    local vim = game:GetService("VirtualInputManager")
    if vim then
        pcall(function()
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.01)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
        return true
    end
    return false
end

function Compat.mousePress()
    local fn = safeGet("mouse1press")
    if type(fn) == "function" then pcall(fn); return true end
    return false
end

function Compat.mouseRelease()
    local fn = safeGet("mouse1release")
    if type(fn) == "function" then pcall(fn); return true end
    return false
end

function Compat.mouseMove(dx, dy)
    local fn = safeGet("mousemoverel")
    if type(fn) == "function" then
        local ok = pcall(fn, dx, dy)
        if ok then return true end
    end
    return false
end

function Compat.mouseMoveAbs(x, y)
    local fn = safeGet("mousemoveabs")
    if type(fn) == "function" then
        local ok = pcall(fn, x, y)
        if ok then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════
-- KEYBOARD
-- ═══════════════════════════════════════════════
function Compat.keyPress(key)
    local fn = safeGet("keypress")
    if type(fn) == "function" then pcall(fn, key); return true end
    return false
end

function Compat.keyRelease(key)
    local fn = safeGet("keyrelease")
    if type(fn) == "function" then pcall(fn, key); return true end
    return false
end

-- ═══════════════════════════════════════════════
-- PHYSICS
-- ═══════════════════════════════════════════════
function Compat.fireTouch(part, target, toggle)
    local fn = safeGet("firetouchinterest")
    if type(fn) == "function" then pcall(fn, part, target, toggle); return true end
    return false
end

function Compat.fireClick(detector)
    local fn = safeGet("fireclickdetector")
    if type(fn) == "function" then pcall(fn, detector); return true end
    return false
end

function Compat.firePrompt(prompt)
    local fn = safeGet("fireproximityprompt")
    if type(fn) == "function" then pcall(fn, prompt); return true end
    return false
end

-- ═══════════════════════════════════════════════
-- FILES
-- ═══════════════════════════════════════════════
function Compat.writeFile(path, content)
    local fn = safeGet("writefile")
    if type(fn) == "function" then
        local ok = pcall(fn, path, content)
        if ok then return true end
    end
    return false
end

function Compat.readFile(path)
    local fn = safeGet("readfile")
    if type(fn) == "function" then
        local ok, res = pcall(fn, path)
        if ok and res then return res end
    end
    return nil
end

function Compat.fileExists(path)
    local fn = safeGet("isfile")
    if type(fn) == "function" then
        local ok, res = pcall(fn, path)
        if ok then return res end
    end
    return false
end

function Compat.folderExists(path)
    local fn = safeGet("isfolder")
    if type(fn) == "function" then
        local ok, res = pcall(fn, path)
        if ok then return res end
    end
    return false
end

function Compat.makeFolder(path)
    local fn = safeGet("makefolder")
    if type(fn) == "function" then pcall(fn, path); return true end
    return false
end

function Compat.deleteFile(path)
    local fn = safeGet("delfile")
    if type(fn) == "function" then pcall(fn, path); return true end
    return false
end

function Compat.listFiles(path)
    local fn = safeGet("listfiles")
    if type(fn) == "function" then
        local ok, res = pcall(fn, path)
        if ok and res then return res end
    end
    return {}
end

-- ═══════════════════════════════════════════════
-- CLIPBOARD
-- ═══════════════════════════════════════════════
function Compat.setClipboard(text)
    local fn = safeGet("setclipboard") or safeGet("toclipboard")
    if type(fn) == "function" then
        local ok = pcall(fn, text)
        if ok then return true end
    end
    return false
end

-- ═══════════════════════════════════════════════
-- DRAWING
-- ═══════════════════════════════════════════════
function Compat.hasDrawing()
    return type(Drawing) == "table" and type(Drawing.new) == "function"
end

function Compat.newDrawing(class, props)
    if not Compat.hasDrawing() then return nil end
    local ok, d = pcall(Drawing.new, class)
    if not ok or not d then return nil end
    if props then
        for k, v in pairs(props) do
            pcall(function() d[k] = v end)
        end
    end
    return d
end

-- ═══════════════════════════════════════════════
-- CAPABILITY REPORT
-- ═══════════════════════════════════════════════
function Compat.report()
    local caps = {
        Executor = Compat.getExecutor(),
        Identity = Compat.getIdentity(),
        HWID = #Compat.getHWID() > 0,
        Drawing = Compat.hasDrawing(),
        mouse1click = type(safeGet("mouse1click")) == "function",
        mousemoverel = type(safeGet("mousemoverel")) == "function",
        firetouchinterest = type(safeGet("firetouchinterest")) == "function",
        setclipboard = type(safeGet("setclipboard")) == "function",
        writefile = type(safeGet("writefile")) == "function",
        readfile = type(safeGet("readfile")) == "function",
        HttpGet = type(game.HttpGet) == "function",
    }
    print("═══════════════════════════════════════")
    print("  IZM COMPATIBILITY REPORT")
    print("═══════════════════════════════════════")
    for k, v in pairs(caps) do
        if type(v) == "boolean" then
            print(string.format("  %-22s %s", k, v and "✅" or "❌"))
        else
            print(string.format("  %-22s %s", k, tostring(v)))
        end
    end
    print("═══════════════════════════════════════")
    return caps
end

return Compat