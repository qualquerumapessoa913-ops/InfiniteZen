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
        [142823291] = {name = "Murder Mystery 2", module = "mm2"},
        [114234929420007] = {name = "BloxStrike", module = "bloxstrike"},
        [72920620366355] = {name = "Operation One", module = "operationone"},
    }
}

local placeId = game.PlaceId
local gameInfo = CONFIG.SUPPORTED_GAMES[placeId]

local function loadModule(path)
    local url = CONFIG.REPO .. "/" .. path
    local success, result = pcall(function()
        return game:HttpGet(url)
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

-- Carrega UI Library (NOVO)
local UI = loadModule("InfiniteZen_UI.lua")
if UI then
    UI = UI()
    print("[Infinite Zen] ✅ UI Library carregada")
else
    warn("[Infinite Zen] ⚠️ Falha ao carregar UI Library")
end

-- Carrega Language
local Language = loadModule("src/utils/language.lua")()
Language.setLanguage(CONFIG.DEFAULT_LANG)

-- Jogo não suportado
if not gameInfo then
    warn("[Infinite Zen] Jogo não suportado! PlaceId: " .. placeId)

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
    pid.Text = "PlaceId: " .. placeId
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

local gameModule = loadModule("src/games/" .. gameInfo.module .. ".lua")()
if not gameModule then
    warn("[Infinite Zen] ⚠️ Falha ao carregar módulo do jogo.")
    return
end

if gameModule.Init then
    gameModule.Init({
        Language = Language,
        UI = UI,  -- ⬅️ passa a UI
        gameName = gameInfo.name,
        placeId = placeId,
    })
end

print("[Infinite Zen] ✅ Carregado para: " .. gameInfo.name)
print("============================================")