-- ═══════════════════════════════════════════════════════════
-- INFINITE ZEN — LOADER (Powered by FlowAuth) 🎃 HALLOWEEN
-- ═══════════════════════════════════════════════════════════

local FLOWAUTH_LOADER_HASH = "a9c0105cc4be38b6d7f7f676de6ea7dc"
local FLOWAUTH_LOADER_URL  = "https://flowauth.net/v1/loaders/" .. FLOWAUTH_LOADER_HASH .. ".lua"
local DISCORD_INVITE       = "https://discord.gg/ScZfU2mAGm"
local KEY_FILE             = "izm_flowauth_key.txt"

local MAIN_URLS = {
    "https://raw.githubusercontent.com/qualquerumapessoa913-ops/InfiniteZen/Moon-Angel/src/main.lua",
}

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer
local PlayerGui   = LP:WaitForChild("PlayerGui")

-- 🎃 Paleta Halloween
local COLOR = {
    Primary    = Color3.fromRGB(255, 108, 20),
    PrimaryDark= Color3.fromRGB(180, 60, 0),
    Accent     = Color3.fromRGB(155, 60, 220),
    Bg         = Color3.fromRGB(15, 8, 20),
    Surface    = Color3.fromRGB(25, 14, 32),
    SurfaceHover = Color3.fromRGB(40, 24, 52),
    Text       = Color3.fromRGB(245, 230, 240),
    TextDim    = Color3.fromRGB(180, 150, 190),
    TextMuted  = Color3.fromRGB(120, 90, 140),
    Success    = Color3.fromRGB(120, 255, 90),
    Warning    = Color3.fromRGB(255, 190, 50),
    Danger     = Color3.fromRGB(220, 30, 30),
}

local EMOJI = {
    Pumpkin = "🎃",
    Ghost   = "👻",
    Bat     = "🦇",
    Skull   = "☠️",
    Witch   = "🧙",
    Spider  = "🕷️",
    Candle  = "🕯️",
    Candy   = "🍬",
}

-- ─── STORAGE ───
local function getSavedKey()
    if not (readfile and isfile) then return nil end
    local ok1, exists = pcall(isfile, KEY_FILE)
    if not ok1 or not exists then return nil end
    local ok2, content = pcall(readfile, KEY_FILE)
    if not ok2 or not content then return nil end
    content = content:gsub("%s+", "")
    if content == "" then return nil end
    return content
end

local function saveKey(key)
    if writefile then pcall(writefile, KEY_FILE, key) end
end

local function clearSavedKey()
    if delfile then pcall(delfile, KEY_FILE) end
end

-- ─── UI HALLOWEEN ───
local function buildUI()
    local old = PlayerGui:FindFirstChild("IZM_LoaderUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "IZM_LoaderUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 9999
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = PlayerGui

    -- Backdrop (bem atrás)
    local backdrop = Instance.new("Frame", sg)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.3
    backdrop.BorderSizePixel = 0
    backdrop.ZIndex = 0

    -- 🎃 Emojis decorativos flutuando no fundo
    local bgDecos = {"🎃", "👻", "🦇", "🕷️", "🧙", "💀", "🎃", "👻"}
    for i, emoji in ipairs(bgDecos) do
        local e = Instance.new("TextLabel", sg)
        e.Size = UDim2.new(0, 40, 0, 40)
        e.Position = UDim2.new(math.random(), 0, math.random(), 0)
        e.BackgroundTransparency = 1
        e.Font = Enum.Font.GothamBlack
        e.Text = emoji
        e.TextSize = 24
        e.TextTransparency = 0.7
        e.TextColor3 = (i % 2 == 0) and COLOR.Primary or COLOR.Accent
        e.Rotation = math.random(-30, 30)
        e.ZIndex = 1

        task.spawn(function()
            while e.Parent do
                local floatY = math.sin(tick() * 0.8 + i) * 15
                local floatX = math.cos(tick() * 0.5 + i) * 10
                e.Position = UDim2.new(
                    e.Position.X.Scale,
                    e.Position.X.Offset + floatX * 0.02,
                    e.Position.Y.Scale,
                    e.Position.Y.Offset + floatY * 0.02
                )
                task.wait(0.05)
            end
        end)
    end

    -- Card principal
    local card = Instance.new("Frame", sg)
    card.Size = UDim2.new(0, 600, 0, 460)
    card.Position = UDim2.new(0.5, -300, 0.5, -230)
    card.BackgroundColor3 = COLOR.Bg
    card.BorderSizePixel = 0
    card.ZIndex = 10
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)

    -- 🎃 Glow roxo atrás do card
    local glow = Instance.new("Frame", card)
    glow.Size = UDim2.new(1, 30, 1, 30)
    glow.Position = UDim2.new(0, -15, 0, -15)
    glow.BackgroundColor3 = COLOR.Accent
    glow.BackgroundTransparency = 0.85
    glow.BorderSizePixel = 0
    glow.ZIndex = 9
    Instance.new("UICorner", glow).CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", card)
    stroke.Color = COLOR.Primary
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    -- Header
    local top = Instance.new("Frame", card)
    top.Size = UDim2.new(1, 0, 0, 55)
    top.BackgroundColor3 = COLOR.Primary
    top.BorderSizePixel = 0
    top.ZIndex = 11
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)
    local topFix = Instance.new("Frame", top)
    topFix.Size = UDim2.new(1, 0, 0, 20)
    topFix.Position = UDim2.new(0, 0, 1, -20)
    topFix.BackgroundColor3 = COLOR.Primary
    topFix.BorderSizePixel = 0
    topFix.ZIndex = 11

    local icon = Instance.new("TextLabel", top)
    icon.Size = UDim2.new(0, 40, 1, 0)
    icon.Position = UDim2.new(0, 15, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Font = Enum.Font.GothamBlack
    icon.Text = EMOJI.Pumpkin
    icon.TextSize = 26
    icon.TextXAlignment = Enum.TextXAlignment.Left
    icon.ZIndex = 12

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -70, 1, 0)
    title.Position = UDim2.new(0, 60, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 19
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "INFINITE ZEN  " .. EMOJI.Bat
    title.ZIndex = 12

    -- Subtitle
    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 26)
    sub.Position = UDim2.new(0, 20, 0, 68)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 13
    sub.TextColor3 = COLOR.TextDim
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = EMOJI.Ghost .. "  Digite sua key para continuar / Enter your key to continue"
    sub.ZIndex = 11

    -- Input box
    local boxFrame = Instance.new("Frame", card)
    boxFrame.Size = UDim2.new(1, -40, 0, 42)
    boxFrame.Position = UDim2.new(0, 20, 0, 105)
    boxFrame.BackgroundColor3 = COLOR.Surface
    boxFrame.BorderSizePixel = 0
    boxFrame.ZIndex = 11
    Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0, 8)
    local boxStroke = Instance.new("UIStroke", boxFrame)
    boxStroke.Color = COLOR.Primary
    boxStroke.Thickness = 1
    boxStroke.Transparency = 0.5

    local boxKeyIcon = Instance.new("TextLabel", boxFrame)
    boxKeyIcon.Size = UDim2.new(0, 30, 1, 0)
    boxKeyIcon.Position = UDim2.new(0, 5, 0, 0)
    boxKeyIcon.BackgroundTransparency = 1
    boxKeyIcon.Font = Enum.Font.GothamBold
    boxKeyIcon.Text = "🔑"
    boxKeyIcon.TextSize = 14
    boxKeyIcon.TextColor3 = COLOR.Primary
    boxKeyIcon.ZIndex = 12

    local box = Instance.new("TextBox", boxFrame)
    box.Size = UDim2.new(1, -45, 1, 0)
    box.Position = UDim2.new(0, 35, 0, 0)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.TextColor3 = COLOR.Text
    box.PlaceholderText = "Cole sua key aqui... / Paste your key here..."
    box.PlaceholderColor3 = COLOR.TextMuted
    box.Text = ""
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ZIndex = 12

    -- Status frame
    local statusFrame = Instance.new("Frame", card)
    statusFrame.Size = UDim2.new(1, -40, 0, 140)
    statusFrame.Position = UDim2.new(0, 20, 0, 155)
    statusFrame.BackgroundColor3 = COLOR.Surface
    statusFrame.BorderSizePixel = 0
    statusFrame.ZIndex = 11
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 8)

    local statusDeco = Instance.new("TextLabel", statusFrame)
    statusDeco.Size = UDim2.new(0, 30, 0, 30)
    statusDeco.Position = UDim2.new(1, -35, 0, 10)
    statusDeco.BackgroundTransparency = 1
    statusDeco.Font = Enum.Font.GothamBlack
    statusDeco.Text = EMOJI.Candle
    statusDeco.TextSize = 20
    statusDeco.TextTransparency = 0.4
    statusDeco.ZIndex = 12

    local status = Instance.new("TextLabel", statusFrame)
    status.Size = UDim2.new(1, -50, 1, -20)
    status.Position = UDim2.new(0, 10, 0, 10)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextColor3 = COLOR.Warning
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = ""
    status.ZIndex = 12

    -- Botão Load
    local confirmBtn = Instance.new("TextButton", card)
    confirmBtn.Size = UDim2.new(1, -40, 0, 42)
    confirmBtn.Position = UDim2.new(0, 20, 1, -110)
    confirmBtn.BackgroundColor3 = COLOR.Primary
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 14
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.Text = EMOJI.Pumpkin .. "  CARREGAR SCRIPT / LOAD SCRIPT"
    confirmBtn.AutoButtonColor = false
    confirmBtn.ZIndex = 11
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

    confirmBtn.MouseEnter:Connect(function()
        confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 40)
    end)
    confirmBtn.MouseLeave:Connect(function()
        confirmBtn.BackgroundColor3 = COLOR.Primary
    end)

    -- Botão Discord
    local discordBtn = Instance.new("TextButton", card)
    discordBtn.Size = UDim2.new(1, -40, 0, 34)
    discordBtn.Position = UDim2.new(0, 20, 1, -60)
    discordBtn.BackgroundColor3 = COLOR.Surface
    discordBtn.Font = Enum.Font.GothamMedium
    discordBtn.TextSize = 12
    discordBtn.TextColor3 = COLOR.TextDim
    discordBtn.Text = "💬  Entrar no Discord / Join Discord"
    discordBtn.AutoButtonColor = false
    discordBtn.ZIndex = 11
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)
    local dStroke = Instance.new("UIStroke", discordBtn)
    dStroke.Color = COLOR.Accent
    dStroke.Thickness = 1
    dStroke.Transparency = 0.6

    discordBtn.MouseEnter:Connect(function()
        discordBtn.BackgroundColor3 = COLOR.SurfaceHover
    end)
    discordBtn.MouseLeave:Connect(function()
        discordBtn.BackgroundColor3 = COLOR.Surface
    end)

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then pcall(setclipboard, DISCORD_INVITE) end
        pcall(function()
            if syn and syn.request then
                syn.request({ Url = DISCORD_INVITE, Method = "GET" })
            elseif request then
                request({ Url = DISCORD_INVITE, Method = "GET" })
            elseif http_request then
                http_request({ Url = DISCORD_INVITE, Method = "GET" })
            end
        end)
        statusFrame.Visible = true
        status.Text = "📋  " .. EMOJI.Candy .. " Convite copiado / Invite copied!"
        status.TextColor3 = COLOR.Success
    end)

    -- Drag
    local dragging, dragStart, startPos
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = card.Position
        end
    end)
    card.InputEnded:Connect(function()
        dragging = false
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            card.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + d.X,
                startPos.Y.Scale,
                startPos.Y.Offset + d.Y
            )
        end
    end)

    local submittedKey = nil
    confirmBtn.MouseButton1Click:Connect(function()
        local key = box.Text:gsub("%s+", "")
        if key == "" then
            statusFrame.Visible = true
            status.Text = "⚠️  Digite uma key válida / Enter a valid key."
            status.TextColor3 = COLOR.Warning
            return
        end
        if #key < 12 or #key > 64 then
            statusFrame.Visible = true
            status.Text = "⚠️  Formato inválido / Invalid key format. (32 chars)"
            status.TextColor3 = COLOR.Warning
            return
        end
        statusFrame.Visible = true
        status.Text = "🔄  " .. EMOJI.Ghost .. " Validando... / Validating..."
        status.TextColor3 = COLOR.TextDim
        submittedKey = key
    end)

    return {
        waitForKey = function()
            while not submittedKey do task.wait(0.1) end
            return submittedKey
        end,
        setStatus = function(text, color)
            statusFrame.Visible = true
            status.Text = text
            status.TextColor3 = color or COLOR.Warning
        end,
        destroy = function() pcall(function() sg:Destroy() end) end,
    }
end

-- ─── FLOWAUTH LOADER ───
local function runLoader(key)
    local fetchOk, loaderCode = pcall(function()
        return game:HttpGet(FLOWAUTH_LOADER_URL)
    end)

    if not fetchOk then
        return false, "HTTP_ERROR", "Failed to reach FlowAuth server: " .. tostring(loaderCode)
    end

    if not loaderCode or loaderCode == "" then
        return false, "EMPTY_RESPONSE", "FlowAuth returned an empty loader."
    end

    local compileOk, loaderFn = pcall(function()
        return loadstring(loaderCode)
    end)

    if not compileOk or not loaderFn then
        return false, "COMPILE_ERROR", "Failed to compile loader: " .. tostring(loaderFn)
    end

    local execOk, execErr = pcall(function()
        loaderFn(key)
    end)

    if not execOk then
        return false, "EXEC_ERROR", tostring(execErr)
    end

    return true, nil, nil
end

-- ─── CARREGA MAIN.LUA ───
local function is404Response(code)
    if type(code) ~= "string" then return false end
    local first = code:sub(1, 30)
    return first:find("^404") ~= nil
        or first:find("^Not Found") ~= nil
        or first:find("^<!DOCTYPE") ~= nil
        or first:find("^<html") ~= nil
end

local function loadMainScript()
    print("[IZM] " .. EMOJI.Pumpkin .. " Carregando main.lua... / Loading main.lua...")

    for i, url in ipairs(MAIN_URLS) do
        print("[IZM] === Fonte " .. i .. " / Source " .. i .. " ===")

        local fetchOk, code = pcall(function()
            return game:HttpGet(url, true)
        end)

        if not fetchOk then
            print("[IZM] Fonte " .. i .. " HTTP FALHOU / HTTP FAILED: " .. tostring(code))
        elseif type(code) ~= "string" then
            print("[IZM] Fonte " .. i .. " retornou tipo errado / wrong type: " .. tostring(type(code)))
        elseif #code == 0 then
            print("[IZM] Fonte " .. i .. " retornou vazio / returned empty")
        elseif is404Response(code) then
            print("[IZM] Fonte " .. i .. " 404 (resposta HTTP / HTTP response)")
        else
            print("[IZM] Fonte " .. i .. " OK (" .. #code .. " bytes). Tentando loadstring...")

            local fn, err = loadstring(code)
            if not fn then
                print("[IZM] ❌ SINTAXE / SYNTAX: " .. tostring(err))
            else
                print("[IZM] Executando / Executing...")
                local runOk, runErr = pcall(fn)
                if runOk then
                    print("[IZM] ✅ main.lua executado / executed (fonte/source " .. i .. ")")
                    return true
                else
                    print("[IZM] ❌ ERRO EXEC / EXEC ERROR: " .. tostring(runErr))
                end
            end
        end
    end

    print("[IZM] ❌ Todas as fontes falharam / All sources failed")
    return false
end

-- ─── MAIN ───
local function main()
    local savedKey = getSavedKey()
    if savedKey then
        print("[IZM] " .. EMOJI.Ghost .. " Trying saved key...")
        local ok, errType, errMsg = runLoader(savedKey)
        if ok then
            print("[IZM] ✅ Loaded")
            task.wait(0.5)
            loadMainScript()
            return
        end
        print("[IZM] ⚠️ Saved key failed: " .. tostring(errType) .. " - " .. tostring(errMsg))
        clearSavedKey()
    end

    local ui = buildUI()
    local key = ui.waitForKey()

    ui.setStatus("🔄  " .. EMOJI.Witch .. " Contacting FlowAuth...", COLOR.TextDim)
    task.wait(0.3)

    local ok, errType, errMsg = runLoader(key)
    if ok then
        ui.setStatus("✅  " .. EMOJI.Pumpkin .. " Loaded successfully!", COLOR.Success)
        saveKey(key)
        task.wait(0.5)
        ui.destroy()
        loadMainScript()
        return
    end

    local msg = "❌ Error [" .. tostring(errType) .. "]:\n" .. tostring(errMsg)
    if errType == "EXEC_ERROR" and errMsg and errMsg:lower():find("invalid") then
        msg = "❌ Key inválida / Invalid key.\n" .. EMOJI.Skull .. " Entre no Discord / Join Discord"
    elseif errType == "HTTP_ERROR" then
        msg = "❌ Erro de conexão / Connection error.\n" .. EMOJI.Ghost .. " Tente de novo / Try again later."
    end

    ui.setStatus(msg, COLOR.Danger)
    print("[IZM] ❌ Loader failed: " .. tostring(errType) .. " - " .. tostring(errMsg))
end

main()