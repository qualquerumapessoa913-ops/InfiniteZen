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
        [286090429] = {name = "Arsenal", module = "arsenal"},
        [14939963714] = {name = "Jailbird", module = "jailbird"},
        [114234929420007] = {name = "BloxStrike", module = "BloxStrike"},
        [8307114974] = {name = "Operation One", module = "OperationOne"},
    }
}

local placeId = game.PlaceId
local gameId = game.GameId
local gameInfo = CONFIG.SUPPORTED_GAMES[placeId] or CONFIG.SUPPORTED_GAMES[gameId]

local function loadModule(path)
    local cacheBuster = "?t=" .. tostring(math.floor(tick() * 1000))
    local url = CONFIG.REPO .. "/" .. path .. cacheBuster
    local success, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not success or not result or result == "" then
        warn("[Infinite Zen] Falha ao carregar: " .. path)
        return nil
    end
    local fn = loadstring(result)
    if not fn then
        warn("[Infinite Zen] Erro de sintaxe em: " .. path)
        return nil
    end
    return fn
end

-- ═══ LOAD COMPAT LAYER ═══
local Compat
local okCompat, CompatResult = pcall(function()
    return loadModule("src/utils/compat.lua")()
end)
if okCompat and CompatResult then
    Compat = CompatResult
    print("[Infinite Zen] ✅ Compat layer carregada")
    Compat.report()
else
    warn("[Infinite Zen] ⚠️ Compat layer falhou, usando fallbacks internos")
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

-- ═══ LOAD UI LIBRARY ═══
local UI = loadModule("InfiniteZen_UI.lua")
if UI then
    UI = UI()
    print("[Infinite Zen] ✅ UI Library carregada")
else
    warn("[Infinite Zen] ⚠️ Falha ao carregar UI Library")
end

-- ═══ LOAD LANGUAGE ═══
local Language = loadModule("src/utils/language.lua")()

-- ═══ UNSUPPORTED GAME ═══
if not gameInfo then
    warn("[Infinite Zen] Jogo não suportado! PlaceId: " .. placeId .. " | GameId: " .. gameId)
    local gui = Instance.new("ScreenGui")
    gui.Name = "InfiniteZen_Unsupported"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 420, 0, 200)
    frame.Position = UDim2.new(0.5, -210, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(255, 70, 70)
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, -40, 0, 30)
    title.Position = UDim2.new(0, 20, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = Language.get("unsupported_title")
    title.TextColor3 = Color3.fromRGB(255, 70, 70)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold

    local msg1 = Instance.new("TextLabel", frame)
    msg1.Size = UDim2.new(1, -40, 0, 25)
    msg1.Position = UDim2.new(0, 20, 0, 65)
    msg1.BackgroundTransparency = 1
    msg1.Text = Language.get("unsupported_message_pt")
    msg1.TextColor3 = Color3.fromRGB(220, 220, 230)
    msg1.TextSize = 14
    msg1.Font = Enum.Font.Gotham

    local msg2 = Instance.new("TextLabel", frame)
    msg2.Size = UDim2.new(1, -40, 0, 25)
    msg2.Position = UDim2.new(0, 20, 0, 90)
    msg2.BackgroundTransparency = 1
    msg2.Text = Language.get("unsupported_message_en")
    msg2.TextColor3 = Color3.fromRGB(150, 155, 170)
    msg2.TextSize = 13
    msg2.Font = Enum.Font.Gotham

    local pid = Instance.new("TextLabel", frame)
    pid.Size = UDim2.new(1, -40, 0, 16)
    pid.Position = UDim2.new(0, 20, 0, 120)
    pid.BackgroundTransparency = 1
    pid.Text = "PlaceId: " .. placeId .. " | GameId: " .. gameId
    pid.TextColor3 = Color3.fromRGB(100, 105, 120)
    pid.TextSize = 11
    pid.Font = Enum.Font.Gotham

    local closeBtn = Instance.new("TextButton", frame)
    closeBtn.Size = UDim2.new(0, 100, 0, 30)
    closeBtn.Position = UDim2.new(0.5, -50, 1, -45)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeBtn.Text = "OK"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 14
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.AutoButtonColor = false
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    return
end

print("[Infinite Zen] 🎮 Jogo detectado: " .. gameInfo.name)
print("[Infinite Zen] 📦 Carregando módulo: " .. gameInfo.module)
print("============================================")

-- ═══ LOAD GAME MODULE ═══
local gameModule = loadModule("src/games/" .. gameInfo.module .. ".lua")()
if not gameModule then
    warn("[Infinite Zen] ⚠️ Falha ao carregar módulo do jogo.")
    return
end

if gameModule.Init then
    gameModule.Init({
        Language = Language,
        UI = UI,
        Compat = Compat,   -- ⬅️ NOVO
        gameName = gameInfo.name,
        placeId = placeId,
    })
end

print("[Infinite Zen] ✅ Carregado para: " .. gameInfo.name)
print("============================================")