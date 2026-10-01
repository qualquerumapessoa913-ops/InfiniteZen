-- ============================================================
-- INFINITE ZEN - MAIN LOADER (v2.1 — Bilingual)
-- ============================================================

print("============================================")
print("  🌌 INFINITE ZEN HUB")
print("  🇧🇷 Versão: 2.1")
print("  🇺🇸 Version: 2.1")
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
-- CARREGAMENTO / LOADING
-- ═══════════════════════════════════════════════

local function loadModule(path)
    local url = CONFIG.REPO .. "/" .. path
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)

    if not success or not result or result == "" then
        warn("[Infinite Zen] ❌ Falha ao baixar / Failed to download: " .. path)
        return nil
    end

    if result:find("^404") or result:find("Not Found") then
        warn("[Infinite Zen] ❌ 404 em / on: " .. path)
        return nil
    end

    local fn, err = loadstring(result)
    if not fn then
        warn("[Infinite Zen] ❌ Erro de sintaxe / Syntax error em/on " .. path .. ": " .. tostring(err))
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
    print("[Infinite Zen] ✅ Compat layer carregada / loaded")
    if Compat.report then pcall(Compat.report) end
else
    warn("[Infinite Zen] ⚠️ Compat fallback")
    Compat = {
        getExecutor = function() return "Unknown" end,
        getHWID = function() return tostring(LocalPlayer.UserId) end,
        mouseClick = function() if mouse1click then pcall(mouse1click) end end,
        mouseMove = function(dx, dy) if mousemoverel then pcall(mousemoverel, dx, dy) end end,
        fireTouch = function(p, t, toggle) if firetouchinterest then pcall(firetouchinterest, p, t, toggle) end end,
        writeFile = function(p, c) if writefile then pcall(writefile, p, c) end end,
        readFile = function(p)
            if readfile then local ok, r = pcall(readfile, p); return ok and r or nil end
        end,
        fileExists = function(p)
            if isfile then local ok, r = pcall(isfile, p); return ok and r or false end
            return false
        end,
        folderExists = function(p)
            if isfolder then local ok, r = pcall(isfolder, p); return ok and r or false end
            return false
        end,
        makeFolder = function(p) if makefolder then pcall(makefolder, p) end end,
        deleteFile = function(p) if delfile then pcall(delfile, p) end end,
        listFiles = function(p)
            if listfiles then local ok, r = pcall(listfiles, p); return ok and r or {} end
            return {}
        end,
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
    print("[Infinite Zen] ✅ UI Library carregada / loaded")
else
    warn("[Infinite Zen] ❌ Falha ao carregar UI Library / Failed to load UI Library")
end

-- ═══ LANGUAGE ═══
local LanguageFn = loadModule("src/utils/language.lua")
local Language
if LanguageFn then
    local okLang, result = pcall(LanguageFn)
    if okLang and result then
        Language = result
    end
end

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
-- UNIVERSAL — ONLY RUNS IN UNSUPPORTED GAMES
-- ═══════════════════════════════════════════════
if not gameInfo then
    print("[Infinite Zen] ⚠️ Jogo não suportado / Unsupported game (PlaceId: " .. placeId .. ")")
    print("[Infinite Zen] 📦 Tentando carregar Universal Features / Trying to load Universal Features...")

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
                print("[Infinite Zen] ✅ Universal Features carregadas / loaded")
            else
                warn("[Infinite Zen] ❌ Universal.Init erro / error: " .. tostring(errRun))
            end
        end
    else
        warn("[Infinite Zen] ❌ universal.lua não encontrado / not found — sem features pra esse jogo / no features for this game")
    end

    return
end

-- ═══════════════════════════════════════════════
-- JOGO SUPORTADO → CARREGA SÓ O MÓDULO DO JOGO
-- SUPPORTED GAME → LOADS ONLY THE GAME MODULE
-- ═══════════════════════════════════════════════
print("[Infinite Zen] 🎮 Jogo / Game: " .. gameInfo.name)
print("[Infinite Zen] 📦 Módulo / Module: " .. gameInfo.module)

local gameModuleFn = loadModule("src/games/" .. gameInfo.module .. ".lua")
if not gameModuleFn then
    warn("[Infinite Zen] ❌ Falha ao carregar módulo do jogo / Failed to load game module.")
    return
end

local okMod, gameModule = pcall(gameModuleFn)
if not okMod or not gameModule then
    warn("[Infinite Zen] ❌ Erro ao executar módulo / Error running module: " .. tostring(gameModule))
    return
end

if gameModule.Init then
    local okInit, errInit = pcall(gameModule.Init, {
        Language = Language,
        UI = UI,
        Compat = Compat,
        gameName = gameInfo.name,
        placeId = placeId,
    })
    if not okInit then
        warn("[Infinite Zen] ❌ Init erro / error: " .. tostring(errInit))
        return
    end
end

print("[Infinite Zen] ✅ Carregado para / Loaded for: " .. gameInfo.name)
print("============================================")