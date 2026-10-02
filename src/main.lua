-- ============================================================
-- INFINITE ZEN - MAIN LOADER (v2.2 — Cache + Bilingual)
-- ============================================================

print("============================================")
print("  🌌 INFINITE ZEN HUB")
print("  🇧🇷 Versão: 2.2")
print("  🇺🇸 Version: 2.2")
print("============================================")

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local CONFIG = {
    REPO = "https://raw.githubusercontent.com/qualquerumapessoa913-ops/InfiniteZen/Moon-Angel",
    DEFAULT_LANG = "en",
    CACHE_DIR = "InfiniteZen_Cache",
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
-- CACHE SETUP
-- ═══════════════════════════════════════════════

local function ensureCacheDir()
    if not makefolder then return end
    if isfolder and isfolder(CONFIG.CACHE_DIR) then return end
    pcall(makefolder, CONFIG.CACHE_DIR)
end

ensureCacheDir()

local function cachePathFor(path)
    -- "src/utils/hwid.lua" -> "InfiniteZen_Cache/src_utils_hwid.lua"
    local safe = path:gsub("[/\\]", "_")
    return CONFIG.CACHE_DIR .. "/" .. safe
end

local function readCache(path)
    if not readfile then return nil end
    local cp = cachePathFor(path)
    local ok, raw = pcall(readfile, cp)
    if ok and raw and raw ~= "" then return raw end
    return nil
end

local function writeCache(path, raw)
    if not writefile then return end
    local cp = cachePathFor(path)
    pcall(writefile, cp, raw)
end

-- ═══════════════════════════════════════════════
-- CARREGAMENTO / LOADING (com cache)
-- ═══════════════════════════════════════════════

local function loadModule(path)
    local url = CONFIG.REPO .. "/" .. path

    -- ─── Camada 1: rede ───
    local okNet, result = pcall(function() return game:HttpGet(url, true) end)

    local validNet = okNet
        and result
        and result ~= ""
        and not result:find("^404")
        and not result:find("Not Found")
        and not result:find("^<!DOCTYPE")

    if validNet then
        writeCache(path, result)
        local fn, err = loadstring(result)
        if not fn then
            warn("[Infinite Zen] ❌ Sintaxe em / Syntax in " .. path .. ": " .. tostring(err))
            return nil
        end
        return fn, "network"
    end

    -- ─── Camada 2: cache local ───
    local cached = readCache(path)
    if cached then
        local fn, err = loadstring(cached)
        if fn then
            print("[Infinite Zen] 📦 Cache usado / using cache: " .. path)
            return fn, "cache"
        end
        warn("[Infinite Zen] ❌ Cache corrompido / corrupt cache: " .. path .. " — " .. tostring(err))
    end

    -- ─── Camada 3: nada ───
    warn("[Infinite Zen] ❌ Falha total / total failure: " .. path)
    return nil, "none"
end

-- ═══ COMPAT ═══
local Compat
local CompatFn = loadModule("src/utils/compat.lua")

if CompatFn then
    local ok, CompatResult = pcall(CompatFn)
    if ok and CompatResult then
        Compat = CompatResult
        print("[Infinite Zen] ✅ Compat layer carregada / loaded")
        if Compat.report then pcall(Compat.report) end
    end
end

if not Compat then
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

-- ═══ HWID CHECK ═══
local HWIDModule = loadModule("src/utils/hwid.lua")
if HWIDModule then
    local okHwid, HWID = pcall(HWIDModule)
    if okHwid and HWID and type(HWID.check) == "function" then
        local okCheck, allowed, reason, data = pcall(HWID.check)

        if not okCheck then
            warn("[IZM] HWID check exception — allowing: " .. tostring(allowed))
        elseif allowed then
            print("[IZM] ✅ HWID check passed")
            if data and data.payload and data.payload.ip then
                print("[IZM] HWID:", data.payload.hwid)
                print("[IZM] IP:", data.payload.ip, "-", data.payload.city, "/", data.payload.country)
                print("[IZM] Fingerprint:", data.payload.fingerprint)
            end
        else
            warn("[IZM] 🚫 BLOCKED: " .. tostring(reason))

            local sg = Instance.new("ScreenGui")
            sg.Name = "IZM_Blocked"
            sg.ResetOnSpawn = false
            sg.Parent = PlayerGui

            local frame = Instance.new("Frame", sg)
            frame.Size = UDim2.new(0, 420, 0, 160)
            frame.Position = UDim2.new(0.5, -210, 0.5, -80)
            frame.BackgroundColor3 = Color3.fromRGB(20, 10, 15)
            frame.BorderSizePixel = 0
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

            local stroke = Instance.new("UIStroke", frame)
            stroke.Color = Color3.fromRGB(230, 40, 40)
            stroke.Thickness = 1.5

            local title = Instance.new("TextLabel", frame)
            title.Size = UDim2.new(1, -20, 0, 32)
            title.Position = UDim2.new(0, 10, 0, 15)
            title.BackgroundTransparency = 1
            title.Font = Enum.Font.GothamBlack
            title.TextSize = 18
            title.TextColor3 = Color3.fromRGB(255, 60, 60)
            title.Text = "ACCESS DENIED"

            local msg = Instance.new("TextLabel", frame)
            msg.Size = UDim2.new(1, -20, 0, 90)
            msg.Position = UDim2.new(0, 10, 0, 55)
            msg.BackgroundTransparency = 1
            msg.Font = Enum.Font.Gotham
            msg.TextSize = 13
            msg.TextColor3 = Color3.fromRGB(220, 220, 220)
            msg.TextWrapped = true
            msg.TextYAlignment = Enum.TextYAlignment.Top
            msg.Text = "You have been banned from Infinite Zen.\n\n" ..
                        "Reason: " .. tostring(reason) .. "\n\n" ..
                        "Join the Discord to appeal: discord.gg/ScZfU2mAGm"

            return
        end
    else
        warn("[IZM] ⚠️ hwid.lua inválido / invalid — pulando check / skipping check")
    end
else
    warn("[IZM] ⚠️ hwid.lua não encontrado / not found — pulando check / skipping check")
end
-- ═══ FIM HWID CHECK ═══

-- ═══ UI LIBRARY ═══
local UI = loadModule("InfiniteZen_UI.lua")
if UI then
    local okUI, UIResult = pcall(UI)
    if okUI and UIResult then
        UI = UIResult
        print("[Infinite Zen] ✅ UI Library carregada / loaded")
    else
        warn("[Infinite Zen] ❌ UI Library erro / error: " .. tostring(UIResult))
        UI = nil
    end
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
    else
        warn("[Infinite Zen] ❌ language.lua erro / error: " .. tostring(result))
    end
end

if not Language then
    warn("[Infinite Zen] ⚠️ Language fallback (JSON direto)")

    local HttpService = game:GetService("HttpService")
    local JSON_URL = CONFIG.REPO .. "/InfiniteZen_Translations.json"
    local LANG_FILE = "InfiniteZen_Language.txt"
    local JSON_CACHE = CONFIG.CACHE_DIR .. "/InfiniteZen_Translations.json"

    local translations = {}
    local current = "en"

    -- tenta rede
    local okGet, raw = pcall(function() return game:HttpGet(JSON_URL, true) end)
    if okGet and raw and raw ~= "" and #raw > 100 and not raw:find("^404") then
        if writefile then pcall(writefile, JSON_CACHE, raw) end
        local okDec, data = pcall(function() return HttpService:JSONDecode(raw) end)
        if okDec and type(data) == "table" then
            translations = data
            print("[Infinite Zen] ✅ JSON via rede / via network")
        end
    end

    -- fallback: cache local do JSON
    if not next(translations) and readfile then
        local okR, cached = pcall(readfile, JSON_CACHE)
        if okR and cached and cached ~= "" then
            local okDec, data = pcall(function() return HttpService:JSONDecode(cached) end)
            if okDec and type(data) == "table" then
                translations = data
                print("[Infinite Zen] 📦 JSON via cache")
            end
        end
    end

    -- restaura idioma salvo
    if readfile then
        local okR, content = pcall(readfile, LANG_FILE)
        if okR and content and content ~= "" then
            local code = content:gsub("%s+", "")
            if translations[code] then current = code end
        end
    end

    Language = {
        current = current,
        translations = translations,
        get = function(key)
            local t = translations[current]
            if t and t[key] then return t[key] end
            local en = translations["en"]
            if en and en[key] then return en[key] end
            return key
        end,
        setLanguage = function(code)
            if translations[code] then current = code; return true end
            return false
        end,
        getCurrent = function() return current end,
        getCurrentData = function() return translations[current] end,
        getFlag = function()
            local t = translations[current]
            return (t and t.flag) or "🌐"
        end,
        getAvailable = function()
            local list = {}
            for code, tbl in pairs(translations) do
                if type(tbl) == "table" then
                    table.insert(list, {
                        code = code,
                        flag = tbl.flag or "🌐",
                        displayName = tbl.displayName or code,
                    })
                end
            end
            return list
        end,
        onChange = function() return function() end end,
    }
end

-- ═══════════════════════════════════════════════
-- UNIVERSAL — SÓ RODA EM JOGO NÃO SUPORTADO
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