-- ============================================================
-- INFINITE ZEN - MAIN LOADER
-- ============================================================

print("============================================")
print("  🌌 INFINITE ZEN HUB")
print("  Versão: 2.0")
print("============================================")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    REPO = "https://raw.githubusercontent.com/qualquerumapessoa913-ops/InfiniteZen/Moon-Angel",
    DEFAULT_LANG = "en",
    SUPPORTED_GAMES = {
        [286090429]   = {name = "Arsenal",       module = "arsenal"},
        [14939963714] = {name = "Jailbird",      module = "jailbird"},
        [8307114974]  = {name = "Operation One", module = "operationone"},
    }
}

local placeId = game.PlaceId
local gameId = game.GameId
local gameInfo = CONFIG.SUPPORTED_GAMES[placeId] or CONFIG.SUPPORTED_GAMES[gameId]

-- ═══════════════════════════════════════════════
-- CARREGAMENTO
-- ═══════════════════════════════════════════════

local function loadModule(path)
    local cacheBuster = "?t=" .. tostring(math.floor(tick() * 1000))
    local url = CONFIG.REPO .. "/" .. path .. cacheBuster
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not success or not result or result == "" then
        warn("[Infinite Zen] ❌ Falha ao baixar: " .. path)
        return nil
    end
    if result:find("^404") or result:find("Not Found") then
        warn("[Infinite Zen] ❌ 404 em: " .. path)
        return nil
    end
    local fn, err = loadstring(result)
    if not fn then
        warn("[Infinite Zen] ❌ Erro de sintaxe em " .. path .. ": " .. tostring(err))
        return nil
    end
    return fn
end

-- ═══ COMPAT ═══
local Compat
local okCompat, CompatResult = pcall(function()
    return loadModule("src/utils/compat.lua")()
end)
if okCompat and CompatResult then
    Compat = CompatResult
    print("[Infinite Zen] ✅ Compat layer carregada")
    Compat.report()
else
    warn("[Infinite Zen] ⚠️ Compat fallback")
    Compat = {
        getExecutor = function() return "Unknown" end,
        getHWID = function() return tostring(LocalPlayer.UserId) end,
        mouseClick = function() if mouse1click then pcall(mouse1click) end end,
        mouseMove = function(dx, dy) if mousemoverel then pcall(mousemoverel, dx, dy) end end,
        fireTouch = function(p, t, toggle) if firetouchinterest then pcall(firetouchinterest, p, t, toggle) end end,
        writeFile = function(p, c) if writefile then pcall(writefile, p, c) end end,
        readFile = function(p) if readfile then local ok, r = pcall(readfile, p); return ok and r or nil end end,
        fileExists = function(p) if isfile then local ok, r = pcall(isfile, p); return ok and r or false end end,
        folderExists = function(p) if isfolder then local ok, r = pcall(isfolder, p); return ok and r or false end end,
        makeFolder = function(p) if makefolder then pcall(makefolder, p) end end,
        deleteFile = function(p) if delfile then pcall(delfile, p) end end,
        listFiles = function(p) if listfiles then local ok, r = pcall(listfiles, p); return ok and r or {} end end,
        setClipboard = function(t) if setclipboard then pcall(setclipboard, t) end end,
        hasDrawing = function() return Drawing ~= nil end,
        newDrawing = function(class, props)
            if not Drawing then return nil end
            local d = Drawing.new(class)
            if props then for k, v in pairs(props) do d[k] = v end end
            return d
        end,
        report = function() return {} end,
    }
end

-- ═══ UI LIBRARY ═══
local UI = loadModule("InfiniteZen_UI.lua")
if UI then
    UI = UI()
    print("[Infinite Zen] ✅ UI Library carregada")
else
    warn("[Infinite Zen] ❌ Falha ao carregar UI Library")
end

-- ═══ LANGUAGE ═══
local Language = loadModule("src/utils/language.lua")()
if not Language then
    warn("[Infinite Zen] ⚠️ Language fallback")
    Language = {
        get = function(k) return k end,
        setLanguage = function() end,
        getCurrent = function() return "en" end,
        getAvailable = function() return {{code="en", flag="🇺🇸", displayName="English"}} end,
        onChange = function() end,
    }
end

-- ═══════════════════════════════════════════════
-- UNIVERSAL — SÓ RODA EM JOGO NÃO SUPORTADO
-- ═══════════════════════════════════════════════
if not gameInfo then
    print("[Infinite Zen] ⚠️ Jogo não suportado (PlaceId: " .. placeId .. ")")
    print("[Infinite Zen] 📦 Carregando Universal Features...")

    local UniversalFn = loadModule("src/games/universal.lua")

    if UniversalFn then
        local okInit, UniversalModule = pcall(UniversalFn)
        if okInit and UniversalModule and type(UniversalModule.Init) == "function" then
            local okRun, errRun = pcall(UniversalModule.Init, {
                Language = Language,
                UI = UI,
                Compat = Compat,
                gameName = "Universal",
                placeId = placeId,
                loadModule = loadModule,
            })
            if okRun then
                print("[Infinite Zen] ✅ Universal Features carregadas")
            else
                warn("[Infinite Zen] ❌ Universal.Init erro: " .. tostring(errRun))
            end
        end
    else
        warn("[Infinite Zen] ❌ universal.lua não encontrado")
    end

    return
end

-- ═══════════════════════════════════════════════
-- JOGO SUPORTADO → CARREGA SÓ O MÓDULO DO JOGO
-- ═══════════════════════════════════════════════
print("[Infinite Zen] 🎮 Jogo: " .. gameInfo.name)
print("[Infinite Zen] 📦 Módulo: " .. gameInfo.module)

local gameModule = loadModule("src/games/" .. gameInfo.module .. ".lua")()
if not gameModule then
    warn("[Infinite Zen] ❌ Falha ao carregar módulo do jogo.")
    return
end

if gameModule.Init then
    gameModule.Init({
        Language = Language,
        UI = UI,
        Compat = Compat,
        gameName = gameInfo.name,
        placeId = placeId,
    })
end

print("[Infinite Zen] ✅ Carregado para: " .. gameInfo.name)
print("============================================")