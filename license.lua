-- ═══════════════════════════════════════════════════════════
-- INFINITE ZEN — LOADER (Powered by FlowAuth)
-- ═══════════════════════════════════════════════════════════

local FLOWAUTH_LOADER_HASH = "530fbe83145609971c18e015a321916a"
local FLOWAUTH_LOADER_URL  = "https://flowauth.net/v1/loaders/" .. FLOWAUTH_LOADER_HASH .. ".lua"
local DISCORD_INVITE       = "https://discord.gg/ScZfU2mAGm"
local KEY_FILE             = "izm_flowauth_key.txt"

local Players     = game:GetService("Players")
local UIS         = game:GetService("UserInputService")
local LP          = Players.LocalPlayer
local PlayerGui   = LP:WaitForChild("PlayerGui")

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

-- ─── UI ───
local function buildUI()
    local old = PlayerGui:FindFirstChild("IZM_LoaderUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "IZM_LoaderUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 9999
    sg.Parent = PlayerGui

    local backdrop = Instance.new("Frame", sg)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.4
    backdrop.BorderSizePixel = 0

    local card = Instance.new("Frame", sg)
    card.Size = UDim2.new(0, 600, 0, 460)
    card.Position = UDim2.new(0.5, -300, 0.5, -230)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(88, 101, 242)
    stroke.Thickness = 1.5

    local top = Instance.new("Frame", card)
    top.Size = UDim2.new(1, 0, 0, 50)
    top.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    top.BorderSizePixel = 0
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)
    local topFix = Instance.new("Frame", top)
    topFix.Size = UDim2.new(1, 0, 0, 20)
    topFix.Position = UDim2.new(0, 0, 1, -20)
    topFix.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    topFix.BorderSizePixel = 0

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🔑  INFINITE ZEN"

    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 24)
    sub.Position = UDim2.new(0, 20, 0, 65)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(200, 200, 210)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Enter your script key to continue"

    local boxFrame = Instance.new("Frame", card)
    boxFrame.Size = UDim2.new(1, -40, 0, 40)
    boxFrame.Position = UDim2.new(0, 20, 0, 100)
    boxFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    boxFrame.BorderSizePixel = 0
    Instance.new("UICorner", boxFrame).CornerRadius = UDim.new(0, 8)

    local box = Instance.new("TextBox", boxFrame)
    box.Size = UDim2.new(1, -20, 1, 0)
    box.Position = UDim2.new(0, 10, 0, 0)
    box.BackgroundTransparency = 1
    box.Font = Enum.Font.Code
    box.TextSize = 13
    box.TextColor3 = Color3.fromRGB(240, 240, 245)
    box.PlaceholderText = "Paste your key here..."
    box.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
    box.Text = ""
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left

    local statusFrame = Instance.new("Frame", card)
    statusFrame.Size = UDim2.new(1, -40, 0, 140)
    statusFrame.Position = UDim2.new(0, 20, 0, 150)
    statusFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    statusFrame.BorderSizePixel = 0
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel", statusFrame)
    status.Size = UDim2.new(1, -20, 1, -20)
    status.Position = UDim2.new(0, 10, 0, 10)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(255, 200, 100)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextWrapped = true
    status.Text = ""

    local confirmBtn = Instance.new("TextButton", card)
    confirmBtn.Size = UDim2.new(1, -40, 0, 42)
    confirmBtn.Position = UDim2.new(0, 20, 1, -110)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.TextSize = 14
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.Text = "🚀  LOAD SCRIPT"
    confirmBtn.AutoButtonColor = false
    Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0, 8)

    local discordBtn = Instance.new("TextButton", card)
    discordBtn.Size = UDim2.new(1, -40, 0, 34)
    discordBtn.Position = UDim2.new(0, 20, 1, -60)
    discordBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    discordBtn.Font = Enum.Font.GothamMedium
    discordBtn.TextSize = 12
    discordBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    discordBtn.Text = "💬  Join Discord for a key"
    discordBtn.AutoButtonColor = false
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)

    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then pcall(setclipboard, DISCORD_INVITE) end
        pcall(function()
            if syn and syn.request then syn.request({ Url = DISCORD_INVITE, Method = "GET" })
            elseif request then request({ Url = DISCORD_INVITE, Method = "GET" })
            elseif http_request then http_request({ Url = DISCORD_INVITE, Method = "GET" }) end
        end)
        statusFrame.Visible = true
        status.Text = "📋  Invite copied to clipboard!"
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)

    local dragging, dragStart, startPos
    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = card.Position
        end
    end)
    card.InputEnded:Connect(function()
        dragging = false
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            card.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    local submittedKey = nil
    confirmBtn.MouseButton1Click:Connect(function()
        local key = box.Text:gsub("%s+", "")
        if key == "" then
            status.Text = "⚠️  Enter a valid key."
            status.TextColor3 = Color3.fromRGB(255, 150, 100)
            return
        end
        if #key < 12 or #key > 64 then
            status.Text = "⚠️  Invalid key format. Keys are usually 32 characters."
            status.TextColor3 = Color3.fromRGB(255, 150, 100)
            return
        end
        status.Text = "🔄  Validating..."
        status.TextColor3 = Color3.fromRGB(200, 200, 210)
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
            status.TextColor3 = color or Color3.fromRGB(255, 200, 100)
        end,
        destroy = function() pcall(function() sg:Destroy() end) end,
    }
end

-- ─── LOADER ───
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

-- ─── MAIN ───
local function main()
    local savedKey = getSavedKey()
    if savedKey then
        print("[IZM] Trying saved key...")
        local ok, errType, errMsg = runLoader(savedKey)
        if ok then
            print("[IZM] ✅ Loaded")
            return
        end
        print("[IZM] ⚠️ Saved key failed: " .. tostring(errType) .. " - " .. tostring(errMsg))
        clearSavedKey()
    end

    local ui = buildUI()
    local key = ui.waitForKey()

    ui.setStatus("🔄  Contacting FlowAuth...", Color3.fromRGB(200, 200, 210))
    task.wait(0.3)

    local ok, errType, errMsg = runLoader(key)
    if ok then
        ui.setStatus("✅  Loaded successfully!", Color3.fromRGB(100, 255, 100))
        saveKey(key)
        task.wait(0.5)
        ui.destroy()
        return
    end

    local msg = "❌ Error [" .. tostring(errType) .. "]:\n" .. tostring(errMsg)
    if errType == "EXEC_ERROR" and errMsg and errMsg:lower():find("invalid") then
        msg = "❌ Invalid key.\nJoin Discord and verify to get a new one."
    elseif errType == "HTTP_ERROR" then
        msg = "❌ Could not reach FlowAuth.\nCheck your connection or try again later."
    end

    ui.setStatus(msg, Color3.fromRGB(255, 80, 80))
    print("[IZM] ❌ Loader failed: " .. tostring(errType) .. " - " .. tostring(errMsg))
end

main()