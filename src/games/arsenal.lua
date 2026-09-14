-- ============================================================
-- ARSENAL MINIMAL TEST v1.0 — só pra ver se abre
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    ctx = ctx or {}
    local gameName = ctx.gameName or "Arsenal"
    print("[ARSENAL TEST] Init começou")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    print("[ARSENAL TEST] Services OK")

    local UNLOADED = false
    local Theme = {
        Bg = Color3.fromRGB(8, 4, 6),
        Surface = Color3.fromRGB(18, 8, 12),
        Surface2 = Color3.fromRGB(35, 12, 18),
        Primary = Color3.fromRGB(255, 30, 40),
        Success = Color3.fromRGB(0, 220, 130),
        Text = Color3.fromRGB(255, 245, 245),
        TextDim = Color3.fromRGB(160, 120, 130),
        Font = Enum.Font.GothamMedium,
        FontBold = Enum.Font.GothamBlack,
    }

    local oldMenu = PlayerGui:FindFirstChild("InfiniteZen")
    if oldMenu then oldMenu:Destroy() end

    local GUI = Instance.new("ScreenGui")
    GUI.Name = "InfiniteZen"
    GUI.ResetOnSpawn = false
    GUI.Parent = PlayerGui

    print("[ARSENAL TEST] GUI criada")

    local Main = Instance.new("Frame", GUI)
    Main.Size = UDim2.new(0, 400, 0, 300)
    Main.Position = UDim2.new(0.5, -200, 0.5, -150)
    Main.BackgroundColor3 = Theme.Bg
    Main.BorderSizePixel = 0
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = Theme.Primary
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", Main)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Theme.Surface
    title.BorderSizePixel = 0
    title.Text = "∞ ARSENAL TEST"
    title.Font = Theme.FontBold
    title.TextSize = 18
    title.TextColor3 = Theme.Primary
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

    print("[ARSENAL TEST] Header OK")

    local info = Instance.new("TextLabel", Main)
    info.Size = UDim2.new(1, -20, 0, 60)
    info.Position = UDim2.new(0, 10, 0, 50)
    info.BackgroundColor3 = Theme.Surface2
    info.BorderSizePixel = 0
    info.Text = "Jogo: " .. gameName .. "\nJogadores: " .. #Players:GetPlayers() .. "\nTime: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "nil")
    info.Font = Theme.Font
    info.TextSize = 12
    info.TextColor3 = Theme.Text
    info.TextWrapped = true
    Instance.new("UICorner", info).CornerRadius = UDim.new(0, 6)

    print("[ARSENAL TEST] Info criada")

    -- Botão de teste
    local testBtn = Instance.new("TextButton", Main)
    testBtn.Size = UDim2.new(1, -20, 0, 40)
    testBtn.Position = UDim2.new(0, 10, 0, 120)
    testBtn.BackgroundColor3 = Theme.Success
    testBtn.BorderSizePixel = 0
    testBtn.Text = "TEST: Fullbright + Speed"
    testBtn.Font = Theme.FontBold
    testBtn.TextSize = 14
    testBtn.TextColor3 = Theme.Text
    Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 6)

    local testOn = false
    local origBrightness = Lighting.Brightness
    local origAmbient = Lighting.Ambient
    local origOutdoorAmbient = Lighting.OutdoorAmbient
    local origClockTime = Lighting.ClockTime

    testBtn.MouseButton1Click:Connect(function()
        testOn = not testOn
        if testOn then
            testBtn.BackgroundColor3 = Theme.Primary
            testBtn.Text = "TEST: ON (clica pra desligar)"
            pcall(function()
                Lighting.Brightness = 3
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
                Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
                Lighting.ClockTime = 14
            end)
        else
            testBtn.BackgroundColor3 = Theme.Success
            testBtn.Text = "TEST: Fullbright + Speed"
            pcall(function()
                Lighting.Brightness = origBrightness
                Lighting.Ambient = origAmbient
                Lighting.OutdoorAmbient = origOutdoorAmbient
                Lighting.ClockTime = origClockTime
            end)
        end
    end)

    print("[ARSENAL TEST] Botão OK")

    -- Botão de speed
    local speedBtn = Instance.new("TextButton", Main)
    speedBtn.Size = UDim2.new(1, -20, 0, 40)
    speedBtn.Position = UDim2.new(0, 10, 0, 170)
    speedBtn.BackgroundColor3 = Theme.Success
    speedBtn.BorderSizePixel = 0
    speedBtn.Text = "TEST: Speed (caminha com WASD)"
    speedBtn.Font = Theme.FontBold
    speedBtn.TextSize = 14
    speedBtn.TextColor3 = Theme.Text
    Instance.new("UICorner", speedBtn).CornerRadius = UDim.new(0, 6)

    local speedOn = false
    speedBtn.MouseButton1Click:Connect(function()
        speedOn = not speedOn
        if speedOn then
            speedBtn.BackgroundColor3 = Theme.Primary
            speedBtn.Text = "SPEED: ON"
        else
            speedBtn.BackgroundColor3 = Theme.Success
            speedBtn.Text = "TEST: Speed (caminha com WASD)"
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not speedOn then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= 50 then hum.WalkSpeed = 50 end
        end
    end)

    print("[ARSENAL TEST] Speed loop OK")

    -- Botão de ESP simples
    local espBtn = Instance.new("TextButton", Main)
    espBtn.Size = UDim2.new(1, -20, 0, 40)
    espBtn.Position = UDim2.new(0, 10, 0, 220)
    espBtn.BackgroundColor3 = Theme.Success
    espBtn.BorderSizePixel = 0
    espBtn.Text = "TEST: ESP (Highlight nos inimigos)"
    espBtn.Font = Theme.FontBold
    espBtn.TextSize = 14
    espBtn.TextColor3 = Theme.Text
    Instance.new("UICorner", espBtn).CornerRadius = UDim.new(0, 6)

    local espOn = false
    local espHighlights = {}

    local function isEnemy(p)
        if p == LocalPlayer then return false end
        if not p.Character then return false end
        local hum = p.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local myTeam = LocalPlayer.Team
        if myTeam == nil then return true end
        if p.Team == nil then return false end
        return p.Team ~= myTeam
    end

    local function createESP(p)
        if espHighlights[p] then return end
        if not p.Character then return end
        local h = Instance.new("Highlight")
        h.Adornee = p.Character
        h.FillColor = Theme.Primary
        h.OutlineColor = Color3.fromRGB(255, 255, 255)
        h.FillTransparency = 0.5
        h.Parent = p.Character
        espHighlights[p] = h
    end

    local function removeESP(p)
        if espHighlights[p] then
            pcall(function() espHighlights[p]:Destroy() end)
            espHighlights[p] = nil
        end
    end

    espBtn.MouseButton1Click:Connect(function()
        espOn = not espOn
        if espOn then
            espBtn.BackgroundColor3 = Theme.Primary
            espBtn.Text = "ESP: ON"
        else
            espBtn.BackgroundColor3 = Theme.Success
            espBtn.Text = "TEST: ESP (Highlight nos inimigos)"
            for p, _ in pairs(espHighlights) do removeESP(p) end
        end
    end)

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not espOn then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if isEnemy(p) and p.Character then
                    if not espHighlights[p] then createESP(p) end
                    if espHighlights[p] then espHighlights[p].Enabled = true end
                else
                    if espHighlights[p] then espHighlights[p].Enabled = false end
                end
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

    print("[ARSENAL TEST] ESP loop OK")
    print("[ARSENAL TEST] ✅ TUDO CARREGADO!")
end

return Arsenal