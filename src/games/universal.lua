-- ============================================================
-- INFINITE ZEN - UNIVERSAL FEATURES v2.0
-- ============================================================

local Universal = {}

function Universal.Init(ctx)
    local Language = ctx.Language
    local UI       = ctx.UI
    local Compat   = ctx.Compat
    local gameName = ctx.gameName or "Universal"
    local loadModule = ctx.loadModule

    local function T(key)
        if Language and Language.get then return Language.get(key) end
        return key
    end

    local GAME_VERSION = "1.0"
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - Universal"

    print("[Infinite Zen] [Universal] Inicializando v2.0...")

    local Players           = game:GetService("Players")
    local RunService        = game:GetService("RunService")
    local UserInputService  = game:GetService("UserInputService")
    local HttpService       = game:GetService("HttpService")
    local TeleportService   = game:GetService("TeleportService")
    local SoundService      = game:GetService("SoundService")
    local Lighting          = game:GetService("Lighting")
    local LocalPlayer       = Players.LocalPlayer
    local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
    local Camera            = workspace.CurrentCamera

    local UNLOADED = false
    local Elements = {}
    local Window = nil

    local function setToggle(el, val)
        if not el or type(el.SetState) ~= "function" then return false end
        return pcall(function() el.SetState(val) end)
    end
    local function setSlider(el, val)
        if not el or type(el.SetValue) ~= "function" then return false end
        return pcall(function() el.SetValue(val) end)
    end
    local function reg(id, el)
        if id and el then Elements[id] = el end
        return el
    end

    local function getChar() return LocalPlayer.Character end
    local function getHRP()
        local c = getChar(); if not c then return nil end
        return c:FindFirstChild("HumanoidRootPart")
    end
    local function getHumanoid()
        local c = getChar(); if not c then return nil end
        return c:FindFirstChildOfClass("Humanoid")
    end

    local function findPlayerByName(name)
        if not name or name == "" then return nil end
        local low = name:lower()
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == low or p.DisplayName:lower() == low then return p end
        end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower():find(low, 1, true) then return p end
        end
        return nil
    end

    local State = {
        speedEnabled = false, speedValue = 50,
        jumpEnabled = false, jumpPower = 50,
        infJump = false,
        flyEnabled = false, flySpeed = 60,
        noclip = false,
        autoBhop = false,
        hipEnabled = false, hipValue = 2,
        antiFall = false,
        fullbright = false,
        customFov = false, fovValue = 90,
        headless = false,
        rgbChar = false,
        freecam = false, freecamSpeed = 2,
        flingAll = false,
        sitAll = false,
        freezeAll = false,
        spin = false,
    }

    -- FLING
    local function flingTarget(targetPlayer)
        if not targetPlayer or targetPlayer == LocalPlayer then return end
        local char = targetPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local bav = Instance.new("BodyAngularVelocity")
        bav.AngularVelocity = Vector3.new(999999, 999999, 999999)
        bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bav.P = 999999
        bav.Parent = hrp
        task.delay(0.2, function() if bav and bav.Parent then bav:Destroy() end end)
    end

    local function forceSit(targetPlayer, sit)
        if not targetPlayer then return end
        local char = targetPlayer.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        pcall(function() hum.Sit = sit end)
    end

    local function freezeTarget(targetPlayer, freeze)
        if not targetPlayer then return end
        local char = targetPlayer.Character; if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.Anchored = freeze end)
            end
        end
    end

    local function bringPlayer(targetPlayer)
        if not targetPlayer or targetPlayer == LocalPlayer then return end
        local myHRP = getHRP(); if not myHRP then return end
        local targetChar = targetPlayer.Character; if not targetChar then return end
        local tHRP = targetChar:FindFirstChild("HumanoidRootPart"); if not tHRP then return end
        local ok = pcall(function()
            tHRP.CFrame = myHRP.CFrame + myHRP.CFrame.LookVector * -5
            tHRP.Velocity = Vector3.zero
        end)
        return ok
    end

    -- MOVEMENT
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        local hum = getHumanoid()
        if hum then
            if State.speedEnabled and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
            if State.jumpEnabled then
                if hum.UseJumpPower then
                    if hum.JumpPower ~= State.jumpPower then hum.JumpPower = State.jumpPower end
                else
                    local nh = State.jumpPower / 7.5
                    if math.abs(hum.JumpHeight - nh) > 0.5 then hum.JumpHeight = nh end
                end
            end
            if State.hipEnabled and hum.HipHeight ~= State.hipValue then hum.HipHeight = State.hipValue end
        end
    end)

    local infJumpConn = nil
    local function startInfJump()
        if infJumpConn then infJumpConn:Disconnect() end
        infJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.infJump then return end
            local hum = getHumanoid(); local hrp = getHRP()
            if hum and hrp and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hrp.Velocity = Vector3.new(hrp.Velocity.X, State.jumpPower, hrp.Velocity.Z)
            end
        end)
    end
    local function stopInfJump() if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end end

    RunService:BindToRenderStep("IZ_UniFly", Enum.RenderPriority.Character.Value + 1, function()
        if UNLOADED or not State.flyEnabled then return end
        local hum = getHumanoid(); local hrp = getHRP()
        if not hum or not hrp then return end
        hum.PlatformStand = true
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
        hrp.Velocity = move.Magnitude > 0 and (move.Unit * State.flySpeed) or Vector3.zero
    end)

    local lastFly = false
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if lastFly and not State.flyEnabled then
            local hum = getHumanoid(); if hum then hum.PlatformStand = false end
        end
        lastFly = State.flyEnabled
    end)

    RunService.Stepped:Connect(function()
        if UNLOADED or not State.noclip then return end
        local char = getChar(); if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoBhop then return end
        local hum = getHumanoid(); if not hum then return end
        local st = hum:GetState()
        if (st == Enum.HumanoidStateType.Landed or st == Enum.HumanoidStateType.Running)
           and UserInputService:IsKeyDown(Enum.KeyCode.Space) then hum.Jump = true end
    end)

    local lastSafePos = Vector3.new(0, 50, 0)
    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        local hrp = getHRP(); local hum = getHumanoid()
        if not hrp or not hum then return end
        if hum.FloorMaterial ~= Enum.Material.Air and hrp.Position.Y > -50 then
            lastSafePos = hrp.Position
        end
        if State.antiFall and hrp.Position.Y < -100 then
            pcall(function() hrp.CFrame = CFrame.new(lastSafePos + Vector3.new(0, 5, 0)) end)
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.spin then return end
        local hrp = getHRP()
        if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(25), 0) end
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.T then
            local mouse = UserInputService:GetMouseLocation()
            local ray = Camera:ViewportPointToRay(mouse.X, mouse.Y)
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = { getChar() }
            local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
            if result then
                local hrp = getHRP()
                if hrp then hrp.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0)) end
            end
        end
    end)

    -- FULLBRIGHT / FOV / HEADLESS
    local origBright = Lighting.Brightness
    local origAmb = Lighting.Ambient
    local origOutAmb = Lighting.OutdoorAmbient
    local origClock = Lighting.ClockTime
    local origShadow = Lighting.GlobalShadows
    local origFov = Camera.FieldOfView

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if State.fullbright then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200,200,200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200,200,200)
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density = 0; c.Haze = 0; c.Glare = 0 end
            end
        end
    end)
    local function disableFullbright()
        Lighting.Brightness = origBright
        Lighting.Ambient = origAmb
        Lighting.OutdoorAmbient = origOutAmb
        Lighting.ClockTime = origClock
        Lighting.GlobalShadows = origShadow
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        if State.customFov then Camera.FieldOfView = State.fovValue
        elseif Camera.FieldOfView ~= origFov then Camera.FieldOfView = origFov end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        local char = getChar(); if not char then return end
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then head.LocalTransparencyModifier = State.headless and 1 or 0 end
        for _, acc in ipairs(char:GetChildren()) do
            if acc:IsA("Accessory") then
                local h = acc:FindFirstChild("Handle")
                if h and h:IsA("BasePart") then h.LocalTransparencyModifier = State.headless and 1 or 0 end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.rgbChar then return end
        local char = getChar(); if not char then return end
        local hue = (tick() * 0.5) % 1
        local color = Color3.fromHSV(hue, 1, 1)
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.Color = color end
        end
    end)

    -- MASS ACTIONS
    task.spawn(function()
        while not UNLOADED do
            task.wait(0.15)
            if State.flingAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then pcall(flingTarget, p) end
                end
            end
            if State.sitAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then pcall(forceSit, p, true) end
                end
            end
            if State.freezeAll then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then pcall(freezeTarget, p, true) end
                end
            end
        end
    end)

    -- FREECAM
    local freecamActive = false
    local fcConn, fcBody, fcBodyGyro
    local function startFreecam()
        if freecamActive then return end
        freecamActive = true
        local hrp = getHRP(); local hum = getHumanoid()
        if not hrp or not hum then return end
        hum.PlatformStand = true
        fcBody = Instance.new("BodyVelocity")
        fcBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        fcBody.Velocity = Vector3.zero
        fcBody.Parent = hrp
        fcBodyGyro = Instance.new("BodyGyro")
        fcBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        fcBodyGyro.P = 10000
        fcBodyGyro.CFrame = CFrame.new(hrp.Position, hrp.Position + Camera.CFrame.LookVector)
        fcBodyGyro.Parent = hrp
        fcConn = RunService.Heartbeat:Connect(function()
            if not freecamActive then return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
            if fcBody then fcBody.Velocity = move.Unit * State.freecamSpeed * 30 end
        end)
    end
    local function stopFreecam()
        freecamActive = false
        if fcConn then fcConn:Disconnect(); fcConn = nil end
        if fcBody then fcBody:Destroy(); fcBody = nil end
        if fcBodyGyro then fcBodyGyro:Destroy(); fcBodyGyro = nil end
        local hum = getHumanoid(); if hum then hum.PlatformStand = false end
    end

    -- MUSIC
    local currentSound = nil
    local function playMusic(id)
        if not id or id == "" then return end
        if currentSound then currentSound:Destroy(); currentSound = nil end
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://" .. id
        sound.Volume = 1
        sound.Parent = SoundService
        sound:Play()
        currentSound = sound
    end
    local function stopMusic()
        if currentSound then currentSound:Destroy(); currentSound = nil end
    end

    -- SKYBOX
    local SKYBOXES = {
        ["Default"]      = nil,
        ["Night Sky"]    = "rbxassetid://159454299",
        ["Red Nebula"]   = "rbxassetid://159454296",
        ["Purple"]       = "rbxassetid://159454289",
        ["Space"]        = "rbxassetid://159454299",
        ["Retro Wave"]   = "rbxassetid://6848392381",
        ["Purple Haze"]  = "rbxassetid://6848365234",
        ["Cartoon"]      = "rbxassetid://6848390553",
    }
    local function applySkybox(id)
        for _, c in ipairs(Lighting:GetChildren()) do
            if c:IsA("Sky") then c:Destroy() end
        end
        if id then
            local sky = Instance.new("Sky")
            sky.SkyboxBk = id; sky.SkyboxDn = id; sky.SkyboxFt = id
            sky.SkyboxLf = id; sky.SkyboxRt = id; sky.SkyboxUp = id
            sky.Parent = Lighting
        end
    end

    -- SERVER HELPERS
    local function getServers()
        local ok, result = pcall(function()
            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            return HttpService:JSONDecode(game:HttpGet(url))
        end)
        if ok and result and result.data then return result.data end
        return {}
    end

    -- BUILD UI
    local function buildUI()
        Window = UI:CreateWindow({
            Title = "INFINITE ZEN",
            Subtitle = SHORT_VERSION,
            ToggleKey = Enum.KeyCode.K,
        })
        Elements = {}

        -- PLAYERS
        local PlayerTab = Window:CreateTab("Players", "🎯")
        PlayerTab:CreateSection("Target Player")
        PlayerTab:CreateLabel("Type a username, then click the action.", Color3.fromRGB(140,140,155))

        local inputFrame = Instance.new("Frame", PlayerTab.container)
        inputFrame.Size = UDim2.new(1, 0, 0, 40)
        inputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        inputFrame.BorderSizePixel = 0
        inputFrame.LayoutOrder = #PlayerTab.container:GetChildren()
        Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

        local targetInput = Instance.new("TextBox", inputFrame)
        targetInput.Size = UDim2.new(1, -20, 1, -10)
        targetInput.Position = UDim2.new(0, 10, 0, 5)
        targetInput.BackgroundTransparency = 1
        targetInput.Font = Enum.Font.GothamMedium
        targetInput.TextSize = 12
        targetInput.TextColor3 = Color3.fromRGB(240,240,245)
        targetInput.PlaceholderText = "Username..."
        targetInput.PlaceholderColor3 = Color3.fromRGB(90,90,105)
        targetInput.Text = ""
        targetInput.ClearTextOnFocus = false
        targetInput.TextXAlignment = Enum.TextXAlignment.Left

        PlayerTab:CreateButton({
            Name = "🌀 Fling Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                flingTarget(t)
                Window:Notify("🌀", "Flinging " .. t.Name, 2, "success")
            end,
        })
        PlayerTab:CreateButton({
            Name = "🧊 Freeze Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                freezeTarget(t, true)
                Window:Notify("🧊", "Froze " .. t.Name, 2, "success")
            end,
        })
        PlayerTab:CreateButton({
            Name = "🔥 Unfreeze Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                freezeTarget(t, false)
                Window:Notify("🔥", "Unfroze " .. t.Name, 2, "success")
            end,
        })
        PlayerTab:CreateButton({
            Name = "🪑 Sit Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                forceSit(t, true)
                Window:Notify("🪑", "Sat " .. t.Name, 2, "success")
            end,
        })
        PlayerTab:CreateButton({
            Name = "🚶 Stand Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                forceSit(t, false)
                Window:Notify("🚶", "Stood " .. t.Name, 2, "success")
            end,
        })
        PlayerTab:CreateButton({
            Name = "🧲 Bring Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                local ok = bringPlayer(t)
                if ok then Window:Notify("🧲", "Brought " .. t.Name, 2, "success")
                else Window:Notify("❌", "Failed (no net owner)", 2, "error") end
            end,
        })
        PlayerTab:CreateButton({
            Name = "👁️ Spectate Player",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                local c = t.Character
                if c then
                    Camera.CameraSubject = c:FindFirstChildOfClass("Humanoid")
                    Camera.CameraType = Enum.CameraType.Follow
                    Window:Notify("👁️", "Spectating " .. t.Name, 2, "success")
                end
            end,
        })
        PlayerTab:CreateButton({
            Name = "🚶 Stop Spectate",
            Callback = function()
                local c = getChar()
                if c then
                    Camera.CameraSubject = c:FindFirstChildOfClass("Humanoid")
                    Camera.CameraType = Enum.CameraType.Custom
                end
            end,
        })
        PlayerTab:CreateButton({
            Name = "📋 Copy Profile Link",
            Callback = function()
                local t = findPlayerByName(targetInput.Text)
                if not t then Window:Notify("❌", "Not found", 2, "error"); return end
                if setclipboard then
                    setclipboard("https://www.roblox.com/users/" .. t.UserId .. "/profile")
                    Window:Notify("📋", "Copied!", 2, "success")
                end
            end,
        })

        -- CHAOS
        local ChaosTab = Window:CreateTab("Chaos", "💀")
        ChaosTab:CreateSection("⚠️ Mass Actions")
        reg("flingAll", ChaosTab:CreateToggle({
            Name = "Fling All Players", Description = "Continuous fling",
            Icon = "🌀", Default = false,
            Callback = function(v) State.flingAll = v end,
        }))
        reg("sitAll", ChaosTab:CreateToggle({
            Name = "Sit All", Icon = "🪑", Default = false,
            Callback = function(v)
                State.sitAll = v
                if not v then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then pcall(forceSit, p, false) end
                    end
                end
            end,
        }))
        reg("freezeAll", ChaosTab:CreateToggle({
            Name = "Freeze All", Icon = "🧊", Default = false,
            Callback = function(v)
                State.freezeAll = v
                if not v then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer then pcall(freezeTarget, p, false) end
                    end
                end
            end,
        }))
        ChaosTab:CreateButton({
            Name = "🧲 Bring All",
            Callback = function()
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer then pcall(bringPlayer, p) end
                end
                Window:Notify("🧲", "Bringing all", 2, "success")
            end,
        })
        ChaosTab:CreateButton({
            Name = "💀 Explode Local",
            Callback = function()
                local hrp = getHRP()
                if hrp then
                    local e = Instance.new("Explosion")
                    e.Position = hrp.Position
                    e.BlastRadius = 10
                    e.BlastPressure = 0
                    e.Parent = workspace
                end
            end,
        })

        -- MOVEMENT
        local MoveTab = Window:CreateTab("Movement", "💠")
        MoveTab:CreateSection("Speed")
        reg("speedEnabled", MoveTab:CreateToggle({
            Name = "Speed", Icon = "⚡", Default = false,
            Callback = function(v) State.speedEnabled = v end,
        }))
        reg("speedValue", MoveTab:CreateSlider({
            Name = "Speed Value", Icon = "📏", Min = 16, Max = 250, Default = 50,
            Callback = function(v) State.speedValue = v end,
        }))

        MoveTab:CreateSection("Jump")
        reg("jumpEnabled", MoveTab:CreateToggle({
            Name = "Jump Power", Icon = "🦘", Default = false,
            Callback = function(v) State.jumpEnabled = v end,
        }))
        reg("jumpPower", MoveTab:CreateSlider({
            Name = "Jump Value", Icon = "📏", Min = 30, Max = 300, Default = 50,
            Callback = function(v) State.jumpPower = v end,
        }))
        reg("infJump", MoveTab:CreateToggle({
            Name = "Infinite Jump", Icon = "🌌", Default = false,
            Callback = function(v) State.infJump = v; if v then startInfJump() else stopInfJump() end end,
        }))

        MoveTab:CreateSection("Fly / Noclip")
        reg("flyEnabled", MoveTab:CreateToggle({
            Name = "Fly", Description = "WASD + Space/Ctrl",
            Icon = "🕊️", Default = false,
            Callback = function(v) State.flyEnabled = v end,
        }))
        reg("flySpeed", MoveTab:CreateSlider({
            Name = "Fly Speed", Icon = "📏", Min = 20, Max = 300, Default = 60,
            Callback = function(v) State.flySpeed = v end,
        }))
        reg("noclip", MoveTab:CreateToggle({
            Name = "Noclip", Icon = "👻", Default = false,
            Callback = function(v) State.noclip = v end,
        }))
        reg("autoBhop", MoveTab:CreateToggle({
            Name = "Auto Bhop", Icon = "🏃", Default = false,
            Callback = function(v) State.autoBhop = v end,
        }))
        reg("hipEnabled", MoveTab:CreateToggle({
            Name = "Hip Height", Icon = "📐", Default = false,
            Callback = function(v) State.hipEnabled = v end,
        }))
        reg("hipValue", MoveTab:CreateSlider({
            Name = "Hip Value", Icon = "📏", Min = 0, Max = 20, Default = 2,
            Callback = function(v) State.hipValue = v end,
        }))
        reg("antiFall", MoveTab:CreateToggle({
            Name = "Anti-Fall", Icon = "🪂", Default = false,
            Callback = function(v) State.antiFall = v end,
        }))
        reg("spin", MoveTab:CreateToggle({
            Name = "Spin", Icon = "💫", Default = false,
            Callback = function(v) State.spin = v end,
        }))
        MoveTab:CreateSection("Teleport")
        MoveTab:CreateLabel("Press T to teleport to cursor", Color3.fromRGB(140,140,155))

        -- FUN
        local FunTab = Window:CreateTab("Fun", "😭")
        FunTab:CreateSection("Camera")
        reg("freecam", FunTab:CreateToggle({
            Name = "Freecam", Description = "WASD + Space/Ctrl",
            Icon = "🎥", Default = false,
            Callback = function(v) State.freecam = v; if v then startFreecam() else stopFreecam() end end,
        }))
        reg("freecamSpeed", FunTab:CreateSlider({
            Name = "Freecam Speed", Icon = "📏", Min = 1, Max = 10, Default = 2,
            Callback = function(v) State.freecamSpeed = v end,
        }))
        reg("customFov", FunTab:CreateToggle({
            Name = "Custom FOV", Icon = "🎥", Default = false,
            Callback = function(v) State.customFov = v end,
        }))
        reg("fovValue", FunTab:CreateSlider({
            Name = "FOV Value", Icon = "📐", Min = 40, Max = 160, Default = 90,
            Callback = function(v) State.fovValue = v end,
        }))
        FunTab:CreateSection("Visual")
        reg("fullbright", FunTab:CreateToggle({
            Name = "Fullbright", Icon = "💡", Default = false,
            Callback = function(v) State.fullbright = v; if not v then disableFullbright() end end,
        }))
        reg("headless", FunTab:CreateToggle({
            Name = "Headless", Icon = "👤", Default = false,
            Callback = function(v) State.headless = v end,
        }))
        reg("rgbChar", FunTab:CreateToggle({
            Name = "RGB Character", Icon = "🌈", Default = false,
            Callback = function(v) State.rgbChar = v end,
        }))
        FunTab:CreateSection("Skybox")
        local skyboxOptions = {}
        for name, _ in pairs(SKYBOXES) do table.insert(skyboxOptions, name) end
        table.sort(skyboxOptions)
        FunTab:CreateDropdown({
            Name = "Skybox", Icon = "🌌", Options = skyboxOptions, Default = 1,
            Callback = function(option) applySkybox(SKYBOXES[option]) end,
        })
        FunTab:CreateSection("Music")
        local musicInput = Instance.new("Frame", FunTab.container)
        musicInput.Size = UDim2.new(1, 0, 0, 40)
        musicInput.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
        musicInput.BorderSizePixel = 0
        musicInput.LayoutOrder = #FunTab.container:GetChildren()
        Instance.new("UICorner", musicInput).CornerRadius = UDim.new(0, 8)
        local musicBox = Instance.new("TextBox", musicInput)
        musicBox.Size = UDim2.new(1, -20, 1, -10)
        musicBox.Position = UDim2.new(0, 10, 0, 5)
        musicBox.BackgroundTransparency = 1
        musicBox.Font = Enum.Font.GothamMedium
        musicBox.TextSize = 12
        musicBox.TextColor3 = Color3.fromRGB(240,240,245)
        musicBox.PlaceholderText = "Roblox Audio ID..."
        musicBox.PlaceholderColor3 = Color3.fromRGB(90,90,105)
        musicBox.Text = ""
        musicBox.ClearTextOnFocus = false
        musicBox.TextXAlignment = Enum.TextXAlignment.Left
        FunTab:CreateButton({
            Name = "🎵 Play Music",
            Callback = function() playMusic(musicBox.Text) end,
        })
        FunTab:CreateButton({
            Name = "⏹️ Stop Music",
            Callback = function() stopMusic() end,
        })

        -- SERVER
        local ServerTab = Window:CreateTab("Server", "🎯")
        ServerTab:CreateSection("Info")
        local fpsLabel    = ServerTab:CreateLabel("FPS: --", Color3.fromRGB(140,140,155))
        local pingLabel   = ServerTab:CreateLabel("Ping: --", Color3.fromRGB(140,140,155))
        local timeLabel   = ServerTab:CreateLabel("Session: --", Color3.fromRGB(140,140,155))
        local playerLabel = ServerTab:CreateLabel("Players: --", Color3.fromRGB(140,140,155))
        ServerTab:CreateLabel("Job ID: " .. game.JobId:sub(1, 12) .. "...", Color3.fromRGB(140,140,155))

        local fps = 0
        local frames = 0
        RunService.RenderStepped:Connect(function() frames = frames + 1 end)
        task.spawn(function()
            local joinTime = tick()
            while not UNLOADED do
                fps = frames; frames = 0
                if fpsLabel and fpsLabel.Parent then fpsLabel.Text = "FPS: " .. fps end
                if pingLabel and pingLabel.Parent then
                    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                    pingLabel.Text = "Ping: " .. ping .. "ms"
                end
                if timeLabel and timeLabel.Parent then
                    local e = math.floor(tick() - joinTime)
                    timeLabel.Text = string.format("Session: %dm %ds", math.floor(e/60), e%60)
                end
                if playerLabel and playerLabel.Parent then
                    playerLabel.Text = "Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
                end
                task.wait(1)
            end
        end)

        ServerTab:CreateSection("Actions")
        ServerTab:CreateButton({
            Name = "🔄 Rejoin Server",
            Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end,
        })
        ServerTab:CreateButton({
            Name = "📡 Server Hop (Random)",
            Callback = function()
                local servers = getServers()
                for _, srv in ipairs(servers) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                        return
                    end
                end
                Window:Notify("❌", "No servers", 2, "error")
            end,
        })
        ServerTab:CreateButton({
            Name = "🎯 Server Hop (Empty)",
            Callback = function()
                local servers = getServers()
                local best = nil
                for _, srv in ipairs(servers) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        if not best or srv.playing < best.playing then best = srv end
                    end
                end
                if best then TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
                else Window:Notify("❌", "No servers", 2, "error") end
            end,
        })
        ServerTab:CreateButton({
            Name = "👥 Server Hop (Full)",
            Callback = function()
                local servers = getServers()
                local best = nil
                for _, srv in ipairs(servers) do
                    if srv.id ~= game.JobId and srv.playing < srv.maxPlayers then
                        if not best or srv.playing > best.playing then best = srv end
                    end
                end
                if best then TeleportService:TeleportToPlaceInstance(game.PlaceId, best.id, LocalPlayer)
                else Window:Notify("❌", "No servers", 2, "error") end
            end,
        })
        ServerTab:CreateSection("Copy")
        ServerTab:CreateButton({
            Name = "📋 Copy Job ID",
            Callback = function()
                if setclipboard then
                    pcall(setclipboard, game.JobId)
                    Window:Notify("📋", "Copied!", 2, "success")
                end
            end,
        })
        ServerTab:CreateButton({
            Name = "🔗 Copy Server Link",
            Callback = function()
                if setclipboard then
                    local link = "roblox://experiences/start?placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId
                    pcall(setclipboard, link)
                    Window:Notify("🔗", "Copied!", 2, "success")
                end
            end,
        })
        ServerTab:CreateButton({
            Name = "🌐 Copy Game Link",
            Callback = function()
                if setclipboard then
                    setclipboard("https://www.roblox.com/games/" .. game.PlaceId)
                    Window:Notify("🌐", "Copied!", 2, "success")
                end
            end,
        })
    end

    buildUI()

    -- ═══════════════════════════════════════════════
    -- LOAD WEAPONS MODULE
    -- ═══════════════════════════════════════════════
    if loadModule then
        local WeaponsFn = loadModule("src/games/weapons.lua")
        if WeaponsFn then
            local okW, WModule = pcall(WeaponsFn)
            if okW and WModule and type(WModule.Init) == "function" then
                local okRunW = pcall(WModule.Init, {
                    UI = UI,
                    Compat = Compat,
                    Window = Window,
                    Language = Language,
                })
                if okRunW then
                    print("[Infinite Zen] [Universal] ✅ Weapons integrado")
                else
                    warn("[Infinite Zen] [Universal] ❌ Weapons.Init falhou")
                end
            end
        else
            warn("[Infinite Zen] [Universal] ❌ weapons.lua não encontrado")
        end
    end

    Window:Notify("✅ " .. SHORT_VERSION, "Universal v1.0 loaded", 4, "success")
    print("[Infinite Zen] [Universal] ✅ Carregado!")
end

return Universal