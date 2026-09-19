-- ═══════════════════════════════════════════════════════════
-- INFINITE ZEN — LICENSE / VERIFICATION GATE
-- ═══════════════════════════════════════════════════════════
-- Usage (no início de qualquer script):
--   local License = loadstring(game:HttpGet("URL_DO_LICENSE"))()
--   local ok, info = License.check({
--       discord_invite = "https://discord.gg/ScZfU2mAGm",
--   })
--   if not ok then return end  -- user não verificado, para aqui
-- ═══════════════════════════════════════════════════════════

local License = {}

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService= game:GetService("TweenService")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer


-- ─────────────────────────────────────────────
-- CONFIG (mude aqui se precisar)
-- ─────────────────────────────────────────────
local GIST_URL = "https://gist.githubusercontent.com/qualquerumapessoa913-ops/4e6c1652b989c6fabf7b9977d4035246/raw/verification.json"
local API_URL  = "https://izm.injectcloud.space/api/verify/check"


-- ─────────────────────────────────────────────
-- HTTP WRAPPER (compatível com vários executors)
-- ─────────────────────────────────────────────
local function httpGet(url)
    -- tenta request (Synapse, Krnl, Fluxus...)
    local ok, res = pcall(function()
        if syn and syn.request then
            return syn.request({ Url = url, Method = "GET" })
        elseif http_request then
            return http_request({ Url = url, Method = "GET" })
        elseif request then
            return request({ Url = url, Method = "GET" })
        end
        return nil
    end)
    if ok and res and res.Body then
        return res.Body, res.StatusCode or 200
    end

    -- fallback: game:HttpGet
    local ok2, body = pcall(game.HttpGet, game, url)
    if ok2 then return body, 200 end

    return nil, 0
end


-- ─────────────────────────────────────────────
-- CHECK VIA GIST
-- ─────────────────────────────────────────────
local function checkGist(username)
    local url = GIST_URL .. "?t=" .. tick()
    local body, code = httpGet(url)
    if not body or code ~= 200 then
        return nil, "network_error"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not ok or type(data) ~= "table" then
        return nil, "parse_error"
    end

    local low = username:lower()
    for _, info in pairs(data) do
        if info.roblox_name and info.roblox_name:lower() == low then
            return info, "ok"
        end
    end

    return nil, "not_linked"
end


-- ─────────────────────────────────────────────
-- CHECK VIA API
-- ─────────────────────────────────────────────
local function checkAPI(username)
    local url = API_URL .. "?roblox_username=" .. HttpService:UrlEncode(username)
    local body, code = httpGet(url)
    if not body or code ~= 200 then
        return nil, "network_error"
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    if not ok or type(data) ~= "table" then
        return nil, "parse_error"
    end

    if data.verified == true then
        return data, "ok"
    end

    return nil, "not_linked"
end


-- ─────────────────────────────────────────────
-- UI (tela de bloqueio)
-- ─────────────────────────────────────────────
local function buildUI(opts)
    local playerGui = LP:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("IZM_LicenseUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "IZM_LicenseUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 9999
    sg.Parent = playerGui

    -- fundo escuro
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.35
    backdrop.BorderSizePixel = 0
    backdrop.Parent = sg

    -- card
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0, 500, 0, 340)
    card.Position = UDim2.new(0.5, -250, 0.5, -170)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    card.BorderSizePixel = 0
    card.Parent = sg
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(230, 40, 40)
    stroke.Thickness = 1.5
    stroke.Parent = card

    -- topbar colorida
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 50)
    top.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    top.BorderSizePixel = 0
    top.Parent = card
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)

    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 20)
    topFix.Position = UDim2.new(0, 0, 1, -20)
    topFix.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    topFix.BorderSizePixel = 0
    topFix.Parent = top

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🔒  INFINITE ZEN"
    title.Parent = top

    -- subtítulo
    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -40, 0, 30)
    sub.Position = UDim2.new(0, 20, 0, 65)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(200, 200, 210)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Verification Required"
    sub.Parent = card

    -- descrição
    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -40, 0, 60)
    desc.Position = UDim2.new(0, 20, 0, 100)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.TextColor3 = Color3.fromRGB(160, 160, 175)
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Text = "Para usar este script, você precisa estar no nosso servidor do Discord e ter vinculado sua conta do Roblox."
    desc.Parent = card

    -- box de status
    local statusBox = Instance.new("Frame")
    statusBox.Size = UDim2.new(1, -40, 0, 40)
    statusBox.Position = UDim2.new(0, 20, 0, 175)
    statusBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    statusBox.BorderSizePixel = 0
    statusBox.Parent = card
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 1, 0)
    status.Position = UDim2.new(0, 10, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(255, 200, 100)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "⏳  Verificando..."
    status.Parent = statusBox

    -- nome do user Roblox
    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, -40, 0, 20)
    userLabel.Position = UDim2.new(0, 20, 0, 222)
    userLabel.BackgroundTransparency = 1
    userLabel.Font = Enum.Font.Code
    userLabel.TextSize = 11
    userLabel.TextColor3 = Color3.fromRGB(120, 120, 135)
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.Text = "Roblox: " .. LP.Name
    userLabel.Parent = card

    -- botão principal — entrar no Discord
    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(1, -40, 0, 42)
    joinBtn.Position = UDim2.new(0, 20, 1, -120)
    joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 14
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Text = "💬  Entrar no Discord"
    joinBtn.AutoButtonColor = false
    joinBtn.Parent = card
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 8)

    local joinStroke = Instance.new("UIStroke")
    joinStroke.Color = Color3.fromRGB(120, 130, 250)
    joinStroke.Thickness = 1
    joinStroke.Parent = joinBtn

    joinBtn.MouseEnter:Connect(function()
        TweenService:Create(joinBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(105, 118, 250)
        }):Play()
    end)
    joinBtn.MouseLeave:Connect(function()
        TweenService:Create(joinBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        }):Play()
    end)

    joinBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            pcall(setclipboard, opts.discord_invite)
        end
        pcall(function()
            if syn and syn.request then
                syn.request({ Url = opts.discord_invite, Method = "GET" })
            elseif request then
                request({ Url = opts.discord_invite, Method = "GET" })
            elseif http_request then
                http_request({ Url = opts.discord_invite, Method = "GET" })
            end
        end)
        status.Text = "📋  Link copiado! Abrindo no navegador..."
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)

    -- botão de retry
    local retryBtn = Instance.new("TextButton")
    retryBtn.Size = UDim2.new(1, -40, 0, 34)
    retryBtn.Position = UDim2.new(0, 20, 1, -70)
    retryBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    retryBtn.Font = Enum.Font.GothamMedium
    retryBtn.TextSize = 12
    retryBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    retryBtn.Text = "🔄  Já verifiquei — checar de novo"
    retryBtn.AutoButtonColor = false
    retryBtn.Parent = card
    Instance.new("UICorner", retryBtn).CornerRadius = UDim.new(0, 6)

    local manualRetry = false
    retryBtn.MouseButton1Click:Connect(function()
        manualRetry = true
        status.Text = "🔄  Re-verificando..."
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
    end)

    -- drag da janela
    local dragging, dragStart, startPos
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
        end
    end)
    card.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
           or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                         or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            card.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    return {
        destroy = function()
            pcall(function() sg:Destroy() end)
        end,
        setStatus = function(text, color)
            status.Text = text
            status.TextColor3 = color or Color3.fromRGB(255, 200, 100)
        end,
        shouldRetry = function()
            if manualRetry then manualRetry = false; return true end
            return false
        end,
    }
end


-- ─────────────────────────────────────────────
-- CHECK PRINCIPAL
-- ─────────────────────────────────────────────
function License.check(opts)
    opts = opts or {}
    local invite  = opts.discord_invite or "https://discord.gg/ScZfU2mAGm"
    local method  = opts.method or "gist"       -- "gist" ou "api"
    local interval= opts.interval or 5
    local timeout = opts.timeout or 300          -- 5 min máximo

    local ui = buildUI({ discord_invite = invite })

    local start = tick()
    local attempts = 0

    while true do
        attempts = attempts + 1

        -- tenta verificar
        local info, reason
        if method == "api" then
            info, reason = checkAPI(LP.Name)
        else
            info, reason = checkGist(LP.Name)
        end

        if info then
            ui.setStatus("✅  Verificado! Carregando script...", Color3.fromRGB(100, 255, 100))
            task.wait(1)
            ui.destroy()
            return true, info
        end

        -- status baseado no motivo
        if reason == "network_error" then
            ui.setStatus("⚠️  Sem conexão com o servidor — tentando...", Color3.fromRGB(255, 150, 100))
        elseif reason == "parse_error" then
            ui.setStatus("⚠️  Erro ao processar resposta — tentando...", Color3.fromRGB(255, 150, 100))
        else
            ui.setStatus("⏳  Aguardando verificação no Discord...", Color3.fromRGB(255, 200, 100))
        end

        -- checa timeout
        if tick() - start > timeout then
            ui.setStatus("❌  Tempo esgotado. Reinicie o script.", Color3.fromRGB(255, 80, 80))
            return false, "timeout"
        end

        -- espera
        task.wait(interval)
    end
end


return License