-- ═══════════════════════════════════════════════════════════
-- INFINITE ZEN — LICENSE / VERIFICATION + HWID GATE
-- ═══════════════════════════════════════════════════════════
-- Usage (at the top of any script):
--   local License = loadstring(game:HttpGet("URL_TO_LICENSE"))()
--   local ok, info = License.check({
--       discord_invite = "https://discord.gg/ScZfU2mAGm",
--   })
--   if not ok then return end
-- ═══════════════════════════════════════════════════════════

local License = {}

local Players      = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LP           = Players.LocalPlayer


-- ─────────────────────────────────────────────
-- CONFIG
-- ─────────────────────────────────────────────
local GIST_URL = "https://gist.githubusercontent.com/qualquerumapessoa913-ops/4e6c1652b989c6fabf7b9977d4035246/raw/verification.json"
local API_URL  = "https://izm.injectcloud.space"


-- ─────────────────────────────────────────────
-- HTTP WRAPPER
-- ─────────────────────────────────────────────
local function httpGet(url)
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

    local ok2, body = pcall(game.HttpGet, game, url)
    if ok2 then return body, 200 end

    return nil, 0
end


local function httpPost(url, body)
    local encoded = HttpService:JSONEncode(body)
    local ok, res = pcall(function()
        if syn and syn.request then
            return syn.request({
                Url = url, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = encoded,
            })
        elseif http_request then
            return http_request({
                Url = url, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = encoded,
            })
        elseif request then
            return request({
                Url = url, Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = encoded,
            })
        end
        return nil
    end)
    if ok and res and res.Body then
        return res.Body, res.StatusCode or 200
    end
    return nil, 0
end


-- ─────────────────────────────────────────────
-- HWID (multi-executor fallback chain)
-- ─────────────────────────────────────────────
local function getHWID()
    local id

    -- Synapse
    local ok = pcall(function() id = syn and syn.get_hwid and syn.get_hwid() end)
    if ok and id and id ~= "" then return "syn_" .. id end

    -- Script-Ware, KRNL, Fluxus
    ok = pcall(function() id = gethwid and gethwid() end)
    if ok and id and id ~= "" then return "gh_" .. id end

    -- Other executors
    ok = pcall(function() id = get_hwid and get_hwid() end)
    if ok and id and id ~= "" then return "hh_" .. id end

    -- Delta / Codex (mobile)
    ok = pcall(function() id = getdeviceid and getdeviceid() end)
    if ok and id and id ~= "" then return "dev_" .. id end

    -- Fallback: Roblox ClientId (stable per installation)
    ok = pcall(function()
        id = game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if ok and id and id ~= "" then return "rbx_" .. id end

    -- Last resort
    return "fallback_" .. tostring(LP.UserId) .. "_" .. tostring(game.PlaceId)
end


-- ─────────────────────────────────────────────
-- GIST CHECK (basic verification)
-- ─────────────────────────────────────────────
local function checkGist(username)
    local body, code = httpGet(GIST_URL .. "?t=" .. tick())
    if not body or code ~= 200 then return nil, "network_error" end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then return nil, "parse_error" end

    local low = username:lower()
    for _, info in pairs(data) do
        if info.roblox_name and info.roblox_name:lower() == low then
            return info, "ok"
        end
    end
    return nil, "not_linked"
end


-- ─────────────────────────────────────────────
-- HWID CHECK (via bot API)
-- ─────────────────────────────────────────────
local function checkHWID(robloxId, hwid)
    local body, code = httpPost(API_URL .. "/api/hwid/check", {
        roblox_id = robloxId,
        hwid = hwid,
    })
    if not body or code ~= 200 then
        return nil, "api_error"
    end
    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or type(data) ~= "table" then
        return nil, "parse_error"
    end
    return data, "ok"
end


-- ─────────────────────────────────────────────
-- LOCK UI
-- ─────────────────────────────────────────────
local function buildUI(opts)
    local playerGui = LP:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild("IZM_LicenseUI")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "IZM_LicenseUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 9999
    sg.Parent = playerGui

    -- Backdrop
    local backdrop = Instance.new("Frame", sg)
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    backdrop.BackgroundTransparency = 0.35
    backdrop.BorderSizePixel = 0

    -- Card
    local card = Instance.new("Frame", sg)
    card.Size = UDim2.new(0, 500, 0, 360)
    card.Position = UDim2.new(0.5, -250, 0.5, -180)
    card.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(230, 40, 40)
    stroke.Thickness = 1.5

    -- Top bar
    local top = Instance.new("Frame", card)
    top.Size = UDim2.new(1, 0, 0, 50)
    top.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    top.BorderSizePixel = 0
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 14)
    local topFix = Instance.new("Frame", top)
    topFix.Size = UDim2.new(1, 0, 0, 20)
    topFix.Position = UDim2.new(0, 0, 1, -20)
    topFix.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
    topFix.BorderSizePixel = 0

    local title = Instance.new("TextLabel", top)
    title.Size = UDim2.new(1, -30, 1, 0)
    title.Position = UDim2.new(0, 20, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "🔒  INFINITE ZEN"

    -- Subtitle
    local sub = Instance.new("TextLabel", card)
    sub.Size = UDim2.new(1, -40, 0, 30)
    sub.Position = UDim2.new(0, 20, 0, 65)
    sub.BackgroundTransparency = 1
    sub.Font = Enum.Font.GothamMedium
    sub.TextSize = 13
    sub.TextColor3 = Color3.fromRGB(200, 200, 210)
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = "Verification Required"

    -- Description
    local desc = Instance.new("TextLabel", card)
    desc.Size = UDim2.new(1, -40, 0, 80)
    desc.Position = UDim2.new(0, 20, 0, 100)
    desc.BackgroundTransparency = 1
    desc.Font = Enum.Font.Gotham
    desc.TextSize = 13
    desc.TextColor3 = Color3.fromRGB(160, 160, 175)
    desc.TextWrapped = true
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.TextYAlignment = Enum.TextYAlignment.Top
    desc.Text = "To use this script, you need to be in our Discord server and have your Roblox account verified."

    -- Status box
    local statusBox = Instance.new("Frame", card)
    statusBox.Size = UDim2.new(1, -40, 0, 40)
    statusBox.Position = UDim2.new(0, 20, 0, 190)
    statusBox.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    statusBox.BorderSizePixel = 0
    Instance.new("UICorner", statusBox).CornerRadius = UDim.new(0, 8)

    local status = Instance.new("TextLabel", statusBox)
    status.Size = UDim2.new(1, -20, 1, 0)
    status.Position = UDim2.new(0, 10, 0, 0)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.GothamMedium
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(255, 200, 100)
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Text = "⏳  Checking..."

    -- User label
    local userLabel = Instance.new("TextLabel", card)
    userLabel.Size = UDim2.new(1, -40, 0, 20)
    userLabel.Position = UDim2.new(0, 20, 0, 240)
    userLabel.BackgroundTransparency = 1
    userLabel.Font = Enum.Font.Code
    userLabel.TextSize = 11
    userLabel.TextColor3 = Color3.fromRGB(120, 120, 135)
    userLabel.TextXAlignment = Enum.TextXAlignment.Left
    userLabel.Text = "Roblox: " .. LP.Name

    -- Join button
    local joinBtn = Instance.new("TextButton", card)
    joinBtn.Size = UDim2.new(1, -40, 0, 42)
    joinBtn.Position = UDim2.new(0, 20, 1, -120)
    joinBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 14
    joinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinBtn.Text = "💬  Join Discord Server"
    joinBtn.AutoButtonColor = false
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 8)

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
        if setclipboard then pcall(setclipboard, opts.discord_invite) end
        pcall(function()
            if syn and syn.request then
                syn.request({ Url = opts.discord_invite, Method = "GET" })
            elseif request then
                request({ Url = opts.discord_invite, Method = "GET" })
            elseif http_request then
                http_request({ Url = opts.discord_invite, Method = "GET" })
            end
        end)
        status.Text = "📋  Invite link copied! Opening browser..."
        status.TextColor3 = Color3.fromRGB(100, 255, 100)
    end)

    -- Retry button
    local retryBtn = Instance.new("TextButton", card)
    retryBtn.Size = UDim2.new(1, -40, 0, 34)
    retryBtn.Position = UDim2.new(0, 20, 1, -70)
    retryBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    retryBtn.Font = Enum.Font.GothamMedium
    retryBtn.TextSize = 12
    retryBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
    retryBtn.Text = "🔄  I've verified — check again"
    retryBtn.AutoButtonColor = false
    Instance.new("UICorner", retryBtn).CornerRadius = UDim.new(0, 6)

    local manualRetry = false
    retryBtn.MouseButton1Click:Connect(function()
        manualRetry = true
        status.Text = "🔄  Re-checking..."
        status.TextColor3 = Color3.fromRGB(255, 200, 100)
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
        destroy = function() pcall(function() sg:Destroy() end) end,
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
-- MAIN CHECK
-- ─────────────────────────────────────────────
function License.check(opts)
    opts = opts or {}
    local invite       = opts.discord_invite or "https://discord.gg/ScZfU2mAGm"
    local interval     = opts.interval or 5
    local timeout      = opts.timeout or 300
    local hwid_enabled = opts.hwid_enabled ~= false       -- default: true
    local fail_mode    = opts.hwid_fail_mode or "open"    -- "open" | "closed"

    local ui = buildUI({ discord_invite = invite })
    local start = tick()

    -- Step 1: wait for gist verification
    local info = nil
    while not info do
        local data, reason = checkGist(LP.Name)
        if data then
            info = data
            break
        end

        if reason == "network_error" then
            ui.setStatus("⚠️  Can't reach server — retrying...", Color3.fromRGB(255, 150, 100))
        elseif reason == "parse_error" then
            ui.setStatus("⚠️  Parse error — retrying...", Color3.fromRGB(255, 150, 100))
        else
            ui.setStatus("⏳  Waiting for Discord verification...", Color3.fromRGB(255, 200, 100))
        end

        if tick() - start > timeout then
            ui.setStatus("❌  Timed out. Restart the script.", Color3.fromRGB(255, 80, 80))
            return false, "timeout"
        end

        task.wait(interval)
    end

    ui.setStatus("✅  Verified! Validating device...", Color3.fromRGB(100, 255, 100))

    -- Step 2: HWID check
    if hwid_enabled then
        local roblox_id = info.roblox_id or LP.UserId
        local hwid = getHWID()
        local hwidResp, hwidErr = checkHWID(roblox_id, hwid)

        if not hwidResp then
            -- API unreachable
            if fail_mode == "open" then
                ui.setStatus("⚠️  HWID check unavailable — allowing access.", Color3.fromRGB(255, 200, 100))
                task.wait(1.5)
                ui.destroy()
                return true, info
            else
                ui.setStatus("❌  HWID server offline. Try again later.", Color3.fromRGB(255, 80, 80))
                return false, "api_offline"
            end
        end

        if not hwidResp.allowed then
            local reason = hwidResp.reason or "unknown"
            if reason == "hwid_limit" then
                ui.setStatus(
                    string.format("❌  Device limit reached (%d/%d).\nUse /hwid_reset in Discord.",
                        hwidResp.current or 0, hwidResp.max or 0),
                    Color3.fromRGB(255, 80, 80)
                )
            elseif reason == "not_verified" then
                ui.setStatus("❌  Account not verified on Discord.", Color3.fromRGB(255, 80, 80))
            else
                ui.setStatus("❌  Access denied: " .. reason, Color3.fromRGB(255, 80, 80))
            end
            return false, reason
        end

        local reason = hwidResp.reason or ""
        if reason == "new_device" then
            ui.setStatus(
                string.format("✅  Device registered (%d/%d).",
                    hwidResp.current or 1, hwidResp.max or 2),
                Color3.fromRGB(100, 255, 100)
            )
        else
            ui.setStatus("✅  Device recognized!", Color3.fromRGB(100, 255, 100))
        end
        task.wait(1)
    end

    ui.setStatus("✅  Loading script...", Color3.fromRGB(100, 255, 100))
    task.wait(0.5)
    ui.destroy()
    return true, info
end


return License