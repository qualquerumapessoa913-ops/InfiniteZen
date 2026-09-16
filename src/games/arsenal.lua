-- ============================================================
-- INFINITE ZEN - ARSENAL v1.5 (Tradução Completa)
-- ============================================================

local Arsenal = {}

function Arsenal.Init(ctx)
    local Language = ctx.Language
    local UI = ctx.UI
    local Compat = ctx.Compat
    local gameName = ctx.gameName

    local GAME_VERSION = "1.4"
    local FULL_VERSION = "Infinite Zen V" .. GAME_VERSION .. " - " .. gameName
    local SHORT_VERSION = "V" .. GAME_VERSION .. " - " .. gameName

    print("[Infinite Zen] Inicializando " .. FULL_VERSION .. "...")

    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualInput = game:GetService("VirtualInputManager")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local Camera = workspace.CurrentCamera

    local UNLOADED = false
    local IS_MOBILE = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

    -- ═══════════════════════════════════════════════
    -- TRADUÇÕES (EN + PT-BR)
    -- ═══════════════════════════════════════════════
    local TRANSLATIONS = {
        en = {
            ["tab.combat"] = "Combat",
            ["tab.weapon"] = "Weapon",
            ["tab.movement"] = "Movement",
            ["tab.visuals"] = "Visuals",
            ["tab.settings"] = "Settings",
            ["tab.language"] = "Language",
            ["tab.credits"] = "Credits",

            ["section.aim"] = "Aim",
            ["section.hitbox"] = "Hitbox",
            ["section.melee"] = "Melee",
            ["section.recoil"] = "Recoil",
            ["section.firerate"] = "Fire Rate",
            ["section.auto"] = "Auto",
            ["section.speed"] = "Speed",
            ["section.jump"] = "Jump",
            ["section.esp"] = "ESP",
            ["section.environment"] = "Environment",
            ["section.create_config"] = "Create Config",
            ["section.saved_configs"] = "Saved Configs",
            ["section.optimizations"] = "Optimizations",
            ["section.danger"] = "Danger Zone",
            ["section.language_select"] = "Idioma / Language",
            ["section.language_info"] = "Info",
            ["section.founder"] = "Founder & Developer",
            ["section.community"] = "Community",
            ["section.version"] = "Version",

            ["silent.name"] = "Silent Headshot",
            ["silent.desc"] = "Auto-lock aim on enemy head when holding click",
            ["silentfov.name"] = "Silent FOV",
            ["silentfov.desc"] = "Field of view radius for silent aim",
            ["aimbot.name"] = "Aimbot",
            ["aimbot.desc"] = "Continuous camera lock on closest enemy",
            ["headexp.name"] = "Head Expander",
            ["headexp.desc"] = "Enlarge enemy head hitbox (easier to hit)",
            ["headsize.name"] = "Head Size",
            ["headsize.desc"] = "Multiplier for head size",
            ["backstab.name"] = "Backstab",
            ["backstab.desc"] = "Teleport behind closest enemy and attack (keybind: E)",

            ["norecoil.name"] = "No Recoil",
            ["norecoil.desc"] = "Remove all weapon recoil",
            ["rapidfire.name"] = "Rapid Fire",
            ["rapidfire.desc"] = "Reduce fire delay to minimum",
            ["fastreload.name"] = "Fast Reload",
            ["fastreload.desc"] = "Faster reload animation",
            ["instareload.name"] = "Insta Reload",
            ["instareload.desc"] = "Instant reload",
            ["autoshoot.name"] = "Auto Shoot",
            ["autoshoot.desc"] = "Auto-fire when enemy enters FOV",
            ["autoshootfov.name"] = "Auto Shoot FOV",
            ["autoshootfov.desc"] = "Radius for auto-fire",

            ["speed.name"] = "Speed",
            ["speed.desc"] = "Custom walkspeed",
            ["speedvalue.name"] = "Speed Value",
            ["speedvalue.desc"] = "WalkSpeed value",
            ["airjump.name"] = "Infinite Jump",
            ["airjump.desc"] = "Jump mid-air infinitely",

            ["esp.name"] = "Player ESP",
            ["esp.desc"] = "Highlight enemies through walls",
            ["espdist.name"] = "Max Distance",
            ["espdist.desc"] = "ESP render range",
            ["lowgfx.name"] = "Low Graphics",
            ["lowgfx.desc"] = "Reduce rendering quality for FPS",
            ["noshadow.name"] = "No Shadows",
            ["noshadow.desc"] = "Remove all shadows",
            ["nofog.name"] = "No Fog",
            ["nofog.desc"] = "Remove fog and atmosphere",
            ["nopart.name"] = "No Particles",
            ["nopart.desc"] = "Remove all particle effects",

            ["config.placeholder"] = "Config name + Enter to save...",
            ["config.refresh"] = "🔄 Refresh List",
            ["config.disable_autoload"] = "🚫 Disable Autoload",
            ["config.fps_boost"] = "⚡ Max FPS Boost",
            ["config.reset_opt"] = "🔄 Reset Optimizations",
            ["config.unload"] = "Unload Script",
            ["config.empty"] = "No configs saved yet.",

            ["lang.current"] = "🌐 Current: ",
            ["lang.hint"] = "Choose the hub language (applies instantly and is saved).",
            ["lang.saved_to"] = "Language is saved to:",
            ["lang.auto_restore"] = "It is restored automatically when opening the hub.",

            ["credits.copy_discord"] = "📋 Copy Discord Link",
            ["credits.role"] = "Sr Red",
        },
        ["pt-br"] = {
            ["tab.combat"] = "Combate",
            ["tab.weapon"] = "Arma",
            ["tab.movement"] = "Movimento",
            ["tab.visuals"] = "Visual",
            ["tab.settings"] = "Config",
            ["tab.language"] = "Idioma",
            ["tab.credits"] = "Créditos",

            ["section.aim"] = "Mira",
            ["section.hitbox"] = "Hitbox",
            ["section.melee"] = "Corpo a corpo",
            ["section.recoil"] = "Recuo",
            ["section.firerate"] = "Cadência",
            ["section.auto"] = "Auto",
            ["section.speed"] = "Velocidade",
            ["section.jump"] = "Pulo",
            ["section.esp"] = "ESP",
            ["section.environment"] = "Ambiente",
            ["section.create_config"] = "Criar Config",
            ["section.saved_configs"] = "Configs Salvos",
            ["section.optimizations"] = "Otimizações",
            ["section.danger"] = "Zona de Perigo",
            ["section.language_select"] = "Idioma / Language",
            ["section.language_info"] = "Info",
            ["section.founder"] = "Fundador & Desenvolvedor",
            ["section.community"] = "Comunidade",
            ["section.version"] = "Versão",

            ["silent.name"] = "Headshot Silencioso",
            ["silent.desc"] = "Trava a mira na cabeça ao segurar o clique",
            ["silentfov.name"] = "FOV Silencioso",
            ["silentfov.desc"] = "Raio do campo de visão da mira silenciosa",
            ["aimbot.name"] = "Aimbot",
            ["aimbot.desc"] = "Trava a câmera no inimigo mais próximo",
            ["headexp.name"] = "Head Expander",
            ["headexp.desc"] = "Aumenta a hitbox da cabeça (mais fácil de acertar)",
            ["headsize.name"] = "Tamanho da Cabeça",
            ["headsize.desc"] = "Multiplicador do tamanho",
            ["backstab.name"] = "Backstab",
            ["backstab.desc"] = "Teleporta atrás do inimigo e ataca (tecla: E)",

            ["norecoil.name"] = "Sem Recuo",
            ["norecoil.desc"] = "Remove todo o recuo da arma",
            ["rapidfire.name"] = "Tiro Rápido",
            ["rapidfire.desc"] = "Reduz o delay entre tiros ao mínimo",
            ["fastreload.name"] = "Reload Rápido",
            ["fastreload.desc"] = "Recarga mais rápida",
            ["instareload.name"] = "Reload Instantâneo",
            ["instareload.desc"] = "Recarga na hora",
            ["autoshoot.name"] = "Tiro Automático",
            ["autoshoot.desc"] = "Atira sozinho quando o inimigo entra no FOV",
            ["autoshootfov.name"] = "FOV do Tiro Auto",
            ["autoshootfov.desc"] = "Raio pra atirar automaticamente",

            ["speed.name"] = "Velocidade",
            ["speed.desc"] = "Velocidade personalizada",
            ["speedvalue.name"] = "Valor da Velocidade",
            ["speedvalue.desc"] = "Valor do WalkSpeed",
            ["airjump.name"] = "Pulo Infinito",
            ["airjump.desc"] = "Pula no ar infinitamente",

            ["esp.name"] = "ESP de Jogador",
            ["esp.desc"] = "Destaca inimigos através das paredes",
            ["espdist.name"] = "Distância Máxima",
            ["espdist.desc"] = "Alcance do ESP",
            ["lowgfx.name"] = "Gráficos Baixos",
            ["lowgfx.desc"] = "Reduz qualidade gráfica pra FPS",
            ["noshadow.name"] = "Sem Sombras",
            ["noshadow.desc"] = "Remove todas as sombras",
            ["nofog.name"] = "Sem Névoa",
            ["nofog.desc"] = "Remove névoa e atmosfera",
            ["nopart.name"] = "Sem Partículas",
            ["nopart.desc"] = "Remove efeitos de partículas",

            ["config.placeholder"] = "Nome do config + Enter pra salvar...",
            ["config.refresh"] = "🔄 Atualizar Lista",
            ["config.disable_autoload"] = "🚫 Desativar Autoload",
            ["config.fps_boost"] = "⚡ Boost Máximo de FPS",
            ["config.reset_opt"] = "🔄 Resetar Otimizações",
            ["config.unload"] = "Descarregar Script",
            ["config.empty"] = "Nenhum config salvo ainda.",

            ["lang.current"] = "🌐 Atual: ",
            ["lang.hint"] = "Escolha o idioma do menu (aplica na hora e é salvo).",
            ["lang.saved_to"] = "A linguagem é salva em:",
            ["lang.auto_restore"] = "É restaurada automaticamente ao abrir o hub.",

            ["credits.copy_discord"] = "📋 Copiar Link do Discord",
            ["credits.role"] = "Sr Red",
        },
    }

    -- Idiomas extras carregados do arquivo externo (opcional)
    local EXTRA_TR_FILE = "InfiniteZen_Translations.json"
    if readfile and isfile and isfile(EXTRA_TR_FILE) then
        pcall(function()
            local raw = readfile(EXTRA_TR_FILE)
            local extra = HttpService:JSONDecode(raw)
            for code, tbl in pairs(extra) do
                TRANSLATIONS[code] = TRANSLATIONS[code] or {}
                for k, v in pairs(tbl) do
                    TRANSLATIONS[code][k] = v
                end
            end
            print("[IZ Lang] Traduções extras carregadas: " .. EXTRA_TR_FILE)
        end)
    end

    local CURRENT_LANG = "en"

    local function T(key)
        local tbl = TRANSLATIONS[CURRENT_LANG]
        if tbl and tbl[key] then return tbl[key] end
        local fallback = TRANSLATIONS.en
        if fallback and fallback[key] then return fallback[key] end
        return key
    end

    -- ═══════════════════════════════════════════════
    -- UI ELEMENTS REGISTRY
    -- ═══════════════════════════════════════════════
    local Elements = {}

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

    -- ═══════════════════════════════════════════════
    -- TEAM CHECK
    -- ═══════════════════════════════════════════════
    local function isEnemy(player)
        if player == LocalPlayer then return false end
        if not player.Character then return false end
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then return false end
        local myTeam = LocalPlayer.Team
        if myTeam == nil then return true end
        if player.Team == nil then return false end
        return player.Team ~= myTeam
    end

    -- ═══════════════════════════════════════════════
    -- STATE
    -- ═══════════════════════════════════════════════
    local State = {
        silentHeadshot = false, silentFov = 120,
        aimbot = false,
        headExpander = false, headExpanderSize = 3,
        backstab = false,
        noRecoil = false, rapidFire = false,
        fastReload = false, instaReload = false,
        autoShoot = false, autoShootFov = 100,
        speed = false, speedValue = 50,
        airJump = false,
        esp = false, espMaxDistance = 500,
        lowGraphics = false, noShadows = false, noFog = false, noParticles = false,
        keybinds = {
            silentHeadshot = "X", aimbot = nil, headExpander = nil,
            backstab = "E", noRecoil = nil, rapidFire = nil,
            fastReload = nil, instaReload = nil, autoShoot = nil,
            speed = nil, airJump = nil, esp = nil,
        },
    }

    -- ═══════════════════════════════════════════════
    -- LANGUAGE SYSTEM
    -- ═══════════════════════════════════════════════
    local LANG_FILE = "InfiniteZen_Language.txt"

    local LANGUAGES = {
        { code = "en",    name = "English",            flag = "🇺🇸" },
        { code = "pt-br", name = "Português (BR)",     flag = "🇧🇷" },
        { code = "es",    name = "Español",            flag = "🇪🇸" },
        { code = "fr",    name = "Français",           flag = "🇫🇷" },
        { code = "de",    name = "Deutsch",            flag = "🇩🇪" },
        { code = "it",    name = "Italiano",           flag = "🇮🇹" },
        { code = "ru",    name = "Русский",            flag = "🇷🇺" },
        { code = "pl",    name = "Polski",             flag = "🇵🇱" },
        { code = "tr",    name = "Türkçe",             flag = "🇹🇷" },
        { code = "id",    name = "Bahasa Indonesia",   flag = "🇮🇩" },
        { code = "ph",    name = "Filipino",           flag = "🇵🇭" },
        { code = "vn",    name = "Tiếng Việt",         flag = "🇻🇳" },
        { code = "jp",    name = "日本語",             flag = "🇯🇵" },
        { code = "kr",    name = "한국어",             flag = "🇰🇷" },
        { code = "cn",    name = "中文",               flag = "🇨🇳" },
        { code = "ar",    name = "العربية",            flag = "🇸🇦" },
        { code = "hi",    name = "हिन्दी",              flag = "🇮🇳" },
        { code = "nl",    name = "Nederlands",         flag = "🇳🇱" },
        { code = "se",    name = "Svenska",            flag = "🇸🇪" },
        { code = "ro",    name = "Română",             flag = "🇷🇴" },
    }

    local function saveLanguage(code)
        if not writefile then return false end
        return pcall(function() writefile(LANG_FILE, code) end)
    end

    local function loadSavedLanguage()
        if not readfile or not isfile then return nil end
        local ok, content = pcall(function() return readfile(LANG_FILE) end)
        if ok and type(content) == "string" and content ~= "" then
            content = content:gsub("%s+", "")
            return content
        end
        return nil
    end

    -- Aplica o idioma salvo IMEDIATAMENTE
    local savedLangCode = loadSavedLanguage()
    if savedLangCode and TRANSLATIONS[savedLangCode] then
        CURRENT_LANG = savedLangCode
        print("[IZ Lang] Idioma restaurado: " .. savedLangCode)
    end

    -- Chama o módulo Language do hub (se existir)
    local function applyHubLanguage(code)
        if not Language then return end
        local attempts = {
            function() return Language.SetLanguage(code) end,
            function() return Language:SetLanguage(code) end,
            function() return Language.Set(code) end,
            function() return Language:Set(code) end,
            function() return Language.ChangeLanguage(code) end,
            function() return Language:ChangeLanguage(code) end,
        }
        for _, fn in ipairs(attempts) do
            if pcall(fn) then return true end
        end
        return false
    end

    if savedLangCode then pcall(applyHubLanguage, savedLangCode) end

    -- ═══════════════════════════════════════════════
    -- HELPERS
    -- ═══════════════════════════════════════════════
    local function getBasePart(parent, ...)
        if not parent then return nil end
        for _, name in ipairs({...}) do
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == name and child:IsA("BasePart") then return child end
            end
        end
        return nil
    end

    local function hasLineOfSight(fromPos, targetPart)
        if not targetPart or not targetPart.Parent then return false end
        if not targetPart:IsA("BasePart") then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local exclusions = {}
        if LocalPlayer.Character then table.insert(exclusions, LocalPlayer.Character) end
        table.insert(exclusions, targetPart.Parent)
        params.FilterDescendantsInstances = exclusions
        local direction = targetPart.Position - fromPos
        local distance = direction.Magnitude
        if distance < 0.1 then return true end
        local unitDir = direction.Unit
        local origin = fromPos + unitDir * 2
        local rayLength = distance - 2
        if rayLength <= 0 then return true end
        return workspace:Raycast(origin, unitDir * rayLength, params) == nil
    end

    -- ═══════════════════════════════════════════════
    -- WINDOW
    -- ═══════════════════════════════════════════════
    local Window = UI:CreateWindow({
        Title = "INFINITE ZEN",
        Subtitle = SHORT_VERSION,
        ToggleKey = Enum.KeyCode.K,
    })

    -- Registra a função tradutora na UI Library
    if type(UI.SetTranslator) == "function" then
        UI:SetTranslator(T)
    end

    -- ═══════════════════════════════════════════════
    -- FOV CIRCLE
    -- ═══════════════════════════════════════════════
    local fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 30, 40); fovCircle.Thickness = 1.5
    fovCircle.Filled = false; fovCircle.NumSides = 100; fovCircle.Transparency = 1
    fovCircle.Radius = 25; fovCircle.Visible = false

    RunService.RenderStepped:Connect(function()
        if UNLOADED then return end
        local mouse = UserInputService:GetMouseLocation()
        fovCircle.Position = Vector2.new(mouse.X, mouse.Y)
        if State.silentHeadshot then
            fovCircle.Visible = true; fovCircle.Radius = State.silentFov / 6
        elseif State.autoShoot then
            fovCircle.Visible = true; fovCircle.Radius = State.autoShootFov / 6
        elseif State.aimbot then
            fovCircle.Visible = true; fovCircle.Radius = 25
        else fovCircle.Visible = false end
    end)

    -- ═══════════════════════════════════════════════
    -- AIMBOT
    -- ═══════════════════════════════════════════════
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.aimbot then return end
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, 25
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < minDist then minDist = d; closest = p end
                    end
                end
            end
        end
        if closest and closest.Character then
            local head = closest.Character:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- SILENT HEADSHOT
    -- ═══════════════════════════════════════════════
    local silentHolding, silentTarget, silentOriginalCam = false, nil, nil

    local function getClosestHeadInFov()
        local mouse = UserInputService:GetMouseLocation()
        local closest, minDist = nil, State.silentFov
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < minDist then minDist = d; closest = p end
                    end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not silentHolding then return end
        if not silentTarget or not silentTarget.Character then silentHolding = false; return end
        local head = silentTarget.Character:FindFirstChild("Head")
        if not head or not head:IsA("BasePart") then silentHolding = false; return end
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp or not State.silentHeadshot then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        silentOriginalCam = Camera.CFrame
        local target = getClosestHeadInFov()
        if not target or not target.Character then return end
        silentTarget = target
        silentHolding = true
        local head = target.Character:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position + Vector3.new(0, 0.15, 0))
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if silentHolding then
            silentHolding = false; silentTarget = nil
            if silentOriginalCam then
                Camera.CFrame = silentOriginalCam
                silentOriginalCam = nil
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AUTO SHOOT
    -- ═══════════════════════════════════════════════
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.autoShoot then return end
        local mouse = UserInputService:GetMouseLocation()
        local targetInFov = false
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local head = p.Character:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local sp, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
                    if onScreen and depth and depth > 0 then
                        local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
                        if d and d < State.autoShootFov and hasLineOfSight(Camera.CFrame.Position, head) then
                            targetInFov = true; break
                        end
                    end
                end
            end
        end
        if targetInFov then
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.01)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
        end
    end)

    -- ═══════════════════════════════════════════════
    -- HEAD EXPANDER
    -- ═══════════════════════════════════════════════
    local hitboxSaved = {}

    local function saveOriginal(player, part)
        if not player or not part or not part:IsA("BasePart") then return end
        if not hitboxSaved[player] then hitboxSaved[player] = {} end
        if not hitboxSaved[player][part] then
            local ok, sz = pcall(function() return part.Size end)
            if ok and sz then hitboxSaved[player][part] = sz end
        end
    end

    local function restorePlayer(player)
        if not hitboxSaved[player] then return end
        for part, size in pairs(hitboxSaved[player]) do
            if part and part.Parent and part:IsA("BasePart") then
                pcall(function() part.Size = size end)
            end
        end
        hitboxSaved[player] = nil
    end

    local function restoreAll()
        for player, _ in pairs(hitboxSaved) do restorePlayer(player) end
        hitboxSaved = {}
    end

    local function expandPlayer(p, size)
        if not p.Character then return end
        local head = getBasePart(p.Character, "Head")
        if head then
            saveOriginal(p, head)
            local base = hitboxSaved[p] and hitboxSaved[p][head]
            if base then
                pcall(function()
                    head.Size = Vector3.new(base.X * size, base.Y * math.min(size, 4), base.Z * size)
                    head.Transparency = 0.7; head.CanCollide = false; head.Massless = true
                end)
            end
        end
        local headHB = getBasePart(p.Character, "HeadHB")
        if headHB then
            saveOriginal(p, headHB)
            local base = hitboxSaved[p] and hitboxSaved[p][headHB]
            if base then
                local hbMult = math.min(size * 1.5, 12)
                pcall(function()
                    headHB.Size = Vector3.new(base.X * hbMult, base.Y * hbMult, base.Z * hbMult)
                    headHB.Transparency = 1; headHB.CanCollide = false; headHB.Massless = true
                end)
            end
        end
        local torso = getBasePart(p.Character, "Torso", "UpperTorso")
        if torso then
            saveOriginal(p, torso)
            local base = hitboxSaved[p] and hitboxSaved[p][torso]
            if base then
                local tMult = math.min(size * 0.7, 3)
                pcall(function()
                    torso.Size = Vector3.new(base.X * tMult, base.Y * tMult, base.Z * tMult)
                    torso.Transparency = 0.7; torso.CanCollide = false; torso.Massless = true
                end)
            end
        end
    end

    local heTick = 0
    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.headExpander then return end
        heTick = heTick + 1
        if heTick % 3 ~= 0 then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p == LocalPlayer then
                elseif isEnemy(p) then
                    if p.Character then expandPlayer(p, State.headExpanderSize) end
                else
                    if hitboxSaved[p] then restorePlayer(p) end
                end
            end
        end)
    end)

    -- ═══════════════════════════════════════════════
    -- BACKSTAB
    -- ═══════════════════════════════════════════════
    local backstabLock = {active = false, target = nil, endTime = 0}

    local function getClosestEnemyAnywhere()
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return nil end
        local closest, closestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if isEnemy(p) and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:IsA("BasePart") then
                    local d = (hrp.Position - myHRP.Position).Magnitude
                    if d and d < closestDist then closestDist = d; closest = p end
                end
            end
        end
        return closest
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not backstabLock.active then return end
        if tick() >= backstabLock.endTime then
            backstabLock.active = false; backstabLock.target = nil; return
        end
        local target = backstabLock.target
        if target and target.Character then
            local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
            local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and mHRP and tHRP:IsA("BasePart") and mHRP:IsA("BasePart") then
                Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
            end
        end
    end)

    local function doBackstab()
        if UNLOADED then return end
        local target = getClosestEnemyAnywhere()
        if not target or not target.Character then return end
        local tHRP = target.Character:FindFirstChild("HumanoidRootPart")
        local mHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not tHRP or not mHRP then return end
        if not tHRP:IsA("BasePart") or not mHRP:IsA("BasePart") then return end
        mHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 2)
        backstabLock.active = true; backstabLock.target = target; backstabLock.endTime = tick() + 0.5
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.08)
        Camera.CFrame = CFrame.new(mHRP.Position, tHRP.Position)
        task.wait(0.02)
        for _ = 1, 3 do
            pcall(function()
                VirtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 0)
                task.wait(0.02)
                VirtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 0)
            end)
            pcall(function() mouse1click() end)
            task.wait(0.05)
        end
    end

    -- ═══════════════════════════════════════════════
    -- WEAPON MODS
    -- ═══════════════════════════════════════════════
    local reloadOriginals = {}

    RunService.Heartbeat:Connect(function()
        if UNLOADED then return end
        if not (State.rapidFire or State.noRecoil or State.fastReload or State.instaReload) then return end
        local char = LocalPlayer.Character
        if not char then return end
        local containers = {char}
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then table.insert(containers, backpack) end
        for _, container in ipairs(containers) do
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") then
                    if State.rapidFire then
                        pcall(function()
                            for _, name in ipairs({"FireRate", "BFireRate", "RateOfFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = 0.03
                                elseif typeof(tool[name]) == "number" then tool[name] = 0.03 end
                            end
                            for _, name in ipairs({"Cooldown", "EquipTime", "EquipCooldown", "SwapCooldown", "NextFire"}) do
                                local f = tool:FindFirstChild(name)
                                if f and (f:IsA("NumberValue") or f:IsA("IntValue")) then f.Value = 0
                                elseif typeof(tool[name]) == "number" then tool[name] = 0 end
                            end
                        end)
                    end
                    if State.noRecoil then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    local n = d.Name:lower()
                                    if n:find("recoil") or n:find("kick") or n:find("spread") then d.Value = 0 end
                                end
                            end
                        end)
                    end
                    if State.fastReload and not State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then
                                        if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                        d.Value = reloadOriginals[d] * 0.3
                                    end
                                end
                            end
                        end)
                    end
                    if State.instaReload then
                        pcall(function()
                            for _, d in ipairs(tool:GetDescendants()) do
                                if d:IsA("NumberValue") or d:IsA("IntValue") then
                                    if d.Name:lower():find("reload") then d.Value = 0 end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)

    coroutine.wrap(function()
        while true do
            if UNLOADED then return end
            if State.rapidFire or State.noRecoil or State.fastReload or State.instaReload then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild("Weapons") then
                        for _, d in ipairs(ReplicatedStorage.Weapons:GetDescendants()) do
                            if d:IsA("NumberValue") or d:IsA("IntValue") then
                                local n = d.Name:lower()
                                if State.rapidFire and (n == "firerate" or n == "bfirerate" or n == "rateoffire") then d.Value = 0.03
                                elseif State.rapidFire and (n:find("cooldown") or n:find("equip") or n:find("swap")) then d.Value = 0
                                elseif State.noRecoil and (n == "recoilcontrol" or n:find("recoil")) then d.Value = 0
                                elseif State.fastReload and not State.instaReload and n:find("reload") then
                                    if not reloadOriginals[d] then reloadOriginals[d] = d.Value end
                                    d.Value = reloadOriginals[d] * 0.3
                                elseif State.instaReload and n:find("reload") then d.Value = 0 end
                            end
                        end
                    end
                end)
            end
            task.wait(1)
        end
    end)()

    -- ═══════════════════════════════════════════════
    -- SPEED
    -- ═══════════════════════════════════════════════
    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.speed then return end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed ~= State.speedValue then hum.WalkSpeed = State.speedValue end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AIR JUMP
    -- ═══════════════════════════════════════════════
    local airJumpConn = nil

    local function startAirJump()
        if airJumpConn then airJumpConn:Disconnect() end
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = char:WaitForChild("Humanoid")
        hum.JumpPower = 70
        airJumpConn = UserInputService.JumpRequest:Connect(function()
            if UNLOADED or not State.airJump then return end
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Dead then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
    end

    local function stopAirJump()
        if airJumpConn then airJumpConn:Disconnect(); airJumpConn = nil end
    end

    -- ═══════════════════════════════════════════════
    -- ESP
    -- ═══════════════════════════════════════════════
    local ESP = {data = {}}

    local function createESP(p)
        if ESP.data[p] or not p.Character then return end
        local chams = Instance.new("Highlight")
        chams.Adornee = p.Character
        chams.FillColor = Color3.fromRGB(255, 30, 40); chams.FillTransparency = 0.6
        chams.OutlineColor = Color3.fromRGB(255, 255, 255); chams.OutlineTransparency = 0.3
        chams.Parent = p.Character

        local data = {chams = chams}
        local function newDrawing(class, props)
            local d = Drawing.new(class)
            for k, v in pairs(props) do d[k] = v end
            d.Visible = false
            return d
        end
        data.box = newDrawing("Square", {Thickness = 1.5, Color = Color3.fromRGB(255, 30, 40), Filled = false, Transparency = 1})
        data.name = newDrawing("Text", {Size = 14, Center = true, Outline = true, Color = Color3.fromRGB(255, 255, 255)})
        data.distance = newDrawing("Text", {Size = 12, Center = true, Outline = true, Color = Color3.fromRGB(255, 80, 80)})
        data.health = newDrawing("Line", {Thickness = 3, Color = Color3.fromRGB(0, 255, 0)})
        data.tracer = newDrawing("Line", {Thickness = 1.2, Color = Color3.fromRGB(255, 30, 40)})
        data.headDot = newDrawing("Circle", {Radius = 4, NumSides = 20, Thickness = 1, Filled = false, Color = Color3.fromRGB(255, 255, 255)})
        ESP.data[p] = data
    end

    local function removeESP(p)
        local d = ESP.data[p]
        if not d then return end
        if d.chams then d.chams:Destroy() end
        for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
            if d[key] and d[key].Remove then d[key]:Remove() end
        end
        ESP.data[p] = nil
    end

    local function clearAllESP()
        for p, _ in pairs(ESP.data) do removeESP(p) end
    end

    local function updateESP(p, char)
        local d = ESP.data[p]
        if not d then return end
        if not State.esp or not isEnemy(p) then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            if d.chams then d.chams.Enabled = false end
            return
        end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end
        if not head:IsA("BasePart") or not hrp:IsA("BasePart") then return end
        if d.chams then d.chams.Enabled = true end
        local headSp, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local hrpSp, hrpOn = Camera:WorldToViewportPoint(hrp.Position)
        local footPos = hrp.Position - Vector3.new(0, 3, 0)
        local footSp, footOn = Camera:WorldToViewportPoint(footPos)
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        local dist = math.floor((head.Position - myHRP.Position).Magnitude)
        if dist > State.espMaxDistance then
            for _, key in ipairs({"box", "name", "distance", "health", "tracer", "headDot"}) do
                if d[key] then d[key].Visible = false end
            end
            return
        end
        if headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local w = h * 0.6
            local cx = (headSp.X + footSp.X) / 2
            local cy = (headSp.Y + footSp.Y) / 2
            d.box.Position = Vector2.new(cx - w / 2, cy - h / 2)
            d.box.Size = Vector2.new(w, h)
            d.box.Visible = true
        else d.box.Visible = false end
        if headOn then
            d.name.Position = Vector2.new(headSp.X, headSp.Y - 20)
            d.name.Text = p.Name; d.name.Visible = true
            d.distance.Position = Vector2.new(headSp.X, headSp.Y - 6)
            d.distance.Text = dist .. "m"; d.distance.Visible = true
        else
            d.name.Visible = false; d.distance.Visible = false
        end
        if headOn and footOn then
            local h = math.abs(footSp.Y - headSp.Y)
            local maxHP = hum.MaxHealth
            local hr = 1
            if maxHP and maxHP > 0 then hr = math.clamp(hum.Health / maxHP, 0, 1) end
            local bx = headSp.X + (h * 0.6) / 2 + 5
            local by = headSp.Y + h
            local fy = by - (h * hr)
            d.health.From = Vector2.new(bx, fy)
            d.health.To = Vector2.new(bx, by)
            if hr > 0.6 then d.health.Color = Color3.fromRGB(0, 255, 0)
            elseif hr > 0.3 then d.health.Color = Color3.fromRGB(255, 200, 0)
            else d.health.Color = Color3.fromRGB(255, 40, 40) end
            d.health.Visible = true
        else d.health.Visible = false end
        if hrpOn then
            d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            d.tracer.To = Vector2.new(hrpSp.X, hrpSp.Y)
            d.tracer.Visible = true
        else d.tracer.Visible = false end
        if headOn then
            d.headDot.Position = Vector2.new(headSp.X, headSp.Y)
            d.headDot.Visible = true
        else d.headDot.Visible = false end
    end

    RunService.RenderStepped:Connect(function()
        if UNLOADED or not State.esp then return end
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    if not ESP.data[p] then createESP(p) end
                    updateESP(p, p.Character)
                end
            end
        end)
    end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

    -- ═══════════════════════════════════════════════
    -- OPTIMIZATIONS
    -- ═══════════════════════════════════════════════
    local optBackup = {
        fogEnd = Lighting.FogEnd, fogStart = Lighting.FogStart,
        globalShadows = Lighting.GlobalShadows, qualityLevel = nil,
        atmosphereData = {}, particles = {},
    }
    for _, c in ipairs(Lighting:GetChildren()) do
        if c:IsA("Atmosphere") then
            table.insert(optBackup.atmosphereData, {obj = c, D = c.Density, H = c.Haze, G = c.Glare})
        end
    end
    pcall(function() optBackup.qualityLevel = settings().Rendering.QualityLevel end)

    local function applyLowGraphics(v)
        if v then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        elseif optBackup.qualityLevel then pcall(function() settings().Rendering.QualityLevel = optBackup.qualityLevel end) end
    end

    local function applyNoShadows(v)
        pcall(function() Lighting.GlobalShadows = not v end)
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
                pcall(function() d.CastShadow = not v end)
            end
        end
    end

    local function applyNoFog(v)
        if v then
            Lighting.FogEnd = 100000; Lighting.FogStart = 0
            for _, c in ipairs(Lighting:GetChildren()) do
                if c:IsA("Atmosphere") then c.Density = 0; c.Haze = 0; c.Glare = 0 end
            end
        else
            Lighting.FogEnd = optBackup.fogEnd; Lighting.FogStart = optBackup.fogStart
            for _, data in ipairs(optBackup.atmosphereData) do
                if data.obj and data.obj.Parent then
                    pcall(function()
                        data.obj.Density = data.D; data.obj.Haze = data.H; data.obj.Glare = data.G
                    end)
                end
            end
        end
    end

    local function applyNoParticles(v)
        if v then
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") or d:IsA("Trail") then
                    if optBackup.particles[d] == nil then optBackup.particles[d] = d.Enabled end
                    pcall(function() d.Enabled = false end)
                end
            end
        else
            for obj, orig in pairs(optBackup.particles) do
                if obj and obj.Parent then pcall(function() obj.Enabled = orig end) end
            end
            optBackup.particles = {}
        end
    end

    RunService.Heartbeat:Connect(function()
        if UNLOADED or not State.noParticles then return end
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                pcall(function() d.Enabled = false end)
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- CONFIG SYSTEM
    -- ═══════════════════════════════════════════════
    local BASE_FOLDER = "InfiniteZen_Configs"
    local CONFIG_FOLDER = BASE_FOLDER .. "/Arsenal"
    local AUTOLOAD_FILE = "InfiniteZen_Arsenal_Autoload.txt"

    local function ensureFolder()
        if makefolder then
            if not isfolder(BASE_FOLDER) then pcall(function() makefolder(BASE_FOLDER) end) end
            if not isfolder(CONFIG_FOLDER) then pcall(function() makefolder(CONFIG_FOLDER) end) end
        end
    end

    local function getConfigPath(name) return CONFIG_FOLDER .. "/" .. name .. ".json" end
    local function getAutoloadPath() return AUTOLOAD_FILE end

    local function syncUIFromState()
        local okCount, failCount = 0, 0
        local toggles = {
            "silentHeadshot", "aimbot", "headExpander", "backstab",
            "noRecoil", "rapidFire", "fastReload", "instaReload",
            "autoShoot", "speed", "airJump", "esp",
            "lowGraphics", "noShadows", "noFog", "noParticles",
        }
        for _, key in ipairs(toggles) do
            local el = Elements[key]
            if el and State[key] ~= nil then
                if setToggle(el, State[key]) then okCount = okCount + 1
                else failCount = failCount + 1 end
            end
        end
        local sliders = {
            "silentFov", "headExpanderSize", "autoShootFov",
            "speedValue", "espMaxDistance",
        }
        for _, key in ipairs(sliders) do
            local el = Elements[key]
            if el and State[key] ~= nil then
                if setSlider(el, State[key]) then okCount = okCount + 1
                else failCount = failCount + 1 end
            end
        end
        print(string.format("[IZ Sync] UI sincronizada: %d OK, %d falhas", okCount, failCount))
    end

    local function saveConfigNamed(name)
        ensureFolder()
        local data = {version = GAME_VERSION, state = {}, keybinds = State.keybinds}
        for k, v in pairs(State) do if k ~= "keybinds" then data.state[k] = v end end
        local json = HttpService:JSONEncode(data)
        local ok = pcall(function() writefile(getConfigPath(name), json) end)
        if ok then Window:Notify("💾 Config", "Saved: " .. name, 3, "success"); return true
        else Window:Notify("⚠️ Error", "Failed to save", 4, "error"); return false end
    end

    local function loadConfigNamed(name)
        local ok, content = pcall(function() return readfile(getConfigPath(name)) end)
        if not ok or not content then Window:Notify("⚠️ Error", "Config not found", 4, "error"); return false end
        local success, data = pcall(function() return HttpService:JSONDecode(content) end)
        if not success or not data then Window:Notify("⚠️ Error", "Corrupted", 4, "error"); return false end
        if data.state then for k, v in pairs(data.state) do State[k] = v end end
        if data.keybinds then for k, v in pairs(data.keybinds) do State.keybinds[k] = v end end
        if State.lowGraphics then applyLowGraphics(true) end
        if State.noShadows then applyNoShadows(true) end
        if State.noFog then applyNoFog(true) end
        if State.noParticles then applyNoParticles(true) end
        syncUIFromState()
        Window:Notify("📂 Load", "Loaded: " .. name, 3, "info")
        return true
    end

    local function deleteConfigNamed(name)
        local path = getConfigPath(name)
        if isfile and isfile(path) then
            pcall(function() delfile(path) end)
            Window:Notify("🗑️ Delete", "Deleted: " .. name, 3, "info")
            return true
        end
        return false
    end

    local function listConfigs()
        local list = {}
        if listfiles and isfolder and isfolder(CONFIG_FOLDER) then
            for _, file in ipairs(listfiles(CONFIG_FOLDER)) do
                if file:sub(-5) == ".json" then
                    local name = file:match("([^/\\]+)%.json$")
                    if name then table.insert(list, name) end
                end
            end
        end
        return list
    end

    local function setAutoload(name)
        ensureFolder()
        local ok = pcall(function() writefile(getAutoloadPath(), name) end)
        if ok then Window:Notify("⚡ Autoload", "Set: " .. name, 3, "success") end
    end

    local function clearAutoload()
        pcall(function()
            if isfile(getAutoloadPath()) then delfile(getAutoloadPath()) end
        end)
        Window:Notify("🚫 Autoload", "Disabled", 3, "info")
    end

    local function getAutoload()
        local ok, content = pcall(function() return readfile(getAutoloadPath()) end)
        if ok and content and content ~= "" then return content end
        return nil
    end

    -- ═══════════════════════════════════════════════
    -- ABA: COMBAT
    -- ═══════════════════════════════════════════════
    local CombatTab = Window:CreateTab(T("tab.combat"), "⚔️")
    CombatTab:CreateSection(T("section.aim"), "section.aim")

    reg("silentHeadshot", CombatTab:CreateToggle({
        Name = T("silent.name"), NameKey = "silent.name",
        Description = T("silent.desc"), DescKey = "silent.desc",
        Icon = "🎯", Default = false,
        Callback = function(v) State.silentHeadshot = v end,
    }))

    reg("silentFov", CombatTab:CreateSlider({
        Name = T("silentfov.name"), NameKey = "silentfov.name",
        Description = T("silentfov.desc"), DescKey = "silentfov.desc",
        Icon = "📐", Min = 30, Max = 300, Default = 120,
        Callback = function(v) State.silentFov = v end,
    }))

    reg("aimbot", CombatTab:CreateToggle({
        Name = T("aimbot.name"), NameKey = "aimbot.name",
        Description = T("aimbot.desc"), DescKey = "aimbot.desc",
        Icon = "🤖", Default = false,
        Callback = function(v) State.aimbot = v end,
    }))

    CombatTab:CreateSection(T("section.hitbox"), "section.hitbox")

    reg("headExpander", CombatTab:CreateToggle({
        Name = T("headexp.name"), NameKey = "headexp.name",
        Description = T("headexp.desc"), DescKey = "headexp.desc",
        Icon = "🔴", Default = false,
        Callback = function(v) State.headExpander = v; if not v then restoreAll() end end,
    }))

    reg("headExpanderSize", CombatTab:CreateSlider({
        Name = T("headsize.name"), NameKey = "headsize.name",
        Description = T("headsize.desc"), DescKey = "headsize.desc",
        Icon = "📏", Min = 1, Max = 8, Default = 3,
        Callback = function(v) State.headExpanderSize = v end,
    }))

    CombatTab:CreateSection(T("section.melee"), "section.melee")

    reg("backstab", CombatTab:CreateToggle({
        Name = T("backstab.name"), NameKey = "backstab.name",
        Description = T("backstab.desc"), DescKey = "backstab.desc",
        Icon = "🗡️", Default = false,
        Callback = function(v) State.backstab = v end,
    }))

    -- ═══════════════════════════════════════════════
    -- ABA: WEAPON
    -- ═══════════════════════════════════════════════
    local WeaponTab = Window:CreateTab(T("tab.weapon"), "🔫")
    WeaponTab:CreateSection(T("section.recoil"), "section.recoil")

    reg("noRecoil", WeaponTab:CreateToggle({
        Name = T("norecoil.name"), NameKey = "norecoil.name",
        Description = T("norecoil.desc"), DescKey = "norecoil.desc",
        Icon = "🎯", Default = false,
        Callback = function(v) State.noRecoil = v end,
    }))

    WeaponTab:CreateSection(T("section.firerate"), "section.firerate")

    reg("rapidFire", WeaponTab:CreateToggle({
        Name = T("rapidfire.name"), NameKey = "rapidfire.name",
        Description = T("rapidfire.desc"), DescKey = "rapidfire.desc",
        Icon = "⚡", Default = false,
        Callback = function(v) State.rapidFire = v end,
    }))

    reg("fastReload", WeaponTab:CreateToggle({
        Name = T("fastreload.name"), NameKey = "fastreload.name",
        Description = T("fastreload.desc"), DescKey = "fastreload.desc",
        Icon = "🔄", Default = false,
        Callback = function(v)
            State.fastReload = v
            if not v then
                for value, original in pairs(reloadOriginals) do
                    pcall(function() value.Value = original end)
                end
                reloadOriginals = {}
            end
        end,
    }))

    reg("instaReload", WeaponTab:CreateToggle({
        Name = T("instareload.name"), NameKey = "instareload.name",
        Description = T("instareload.desc"), DescKey = "instareload.desc",
        Icon = "💨", Default = false,
        Callback = function(v) State.instaReload = v end,
    }))

    WeaponTab:CreateSection(T("section.auto"), "section.auto")

    reg("autoShoot", WeaponTab:CreateToggle({
        Name = T("autoshoot.name"), NameKey = "autoshoot.name",
        Description = T("autoshoot.desc"), DescKey = "autoshoot.desc",
        Icon = "🔥", Default = false,
        Callback = function(v) State.autoShoot = v end,
    }))

    reg("autoShootFov", WeaponTab:CreateSlider({
        Name = T("autoshootfov.name"), NameKey = "autoshootfov.name",
        Description = T("autoshootfov.desc"), DescKey = "autoshootfov.desc",
        Icon = "📐", Min = 30, Max = 300, Default = 100,
        Callback = function(v) State.autoShootFov = v end,
    }))

    -- ═══════════════════════════════════════════════
    -- ABA: MOVEMENT
    -- ═══════════════════════════════════════════════
    local MoveTab = Window:CreateTab(T("tab.movement"), "🏃")
    MoveTab:CreateSection(T("section.speed"), "section.speed")

    reg("speed", MoveTab:CreateToggle({
        Name = T("speed.name"), NameKey = "speed.name",
        Description = T("speed.desc"), DescKey = "speed.desc",
        Icon = "⚡", Default = false,
        Callback = function(v)
            State.speed = v
            if not v then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
                end
            end
        end,
    }))

    reg("speedValue", MoveTab:CreateSlider({
        Name = T("speedvalue.name"), NameKey = "speedvalue.name",
        Description = T("speedvalue.desc"), DescKey = "speedvalue.desc",
        Icon = "📏", Min = 16, Max = 300, Default = 50,
        Callback = function(v) State.speedValue = v end,
    }))

    MoveTab:CreateSection(T("section.jump"), "section.jump")

    reg("airJump", MoveTab:CreateToggle({
        Name = T("airjump.name"), NameKey = "airjump.name",
        Description = T("airjump.desc"), DescKey = "airjump.desc",
        Icon = "🦘", Default = false,
        Callback = function(v) State.airJump = v; if v then startAirJump() else stopAirJump() end end,
    }))

    -- ═══════════════════════════════════════════════
    -- ABA: VISUALS
    -- ═══════════════════════════════════════════════
    local VisualsTab = Window:CreateTab(T("tab.visuals"), "👁️")
    VisualsTab:CreateSection(T("section.esp"), "section.esp")

    reg("esp", VisualsTab:CreateToggle({
        Name = T("esp.name"), NameKey = "esp.name",
        Description = T("esp.desc"), DescKey = "esp.desc",
        Icon = "👤", Default = false,
        Callback = function(v)
            State.esp = v
            if v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then createESP(p) end
                end
            else clearAllESP() end
        end,
    }))

    reg("espMaxDistance", VisualsTab:CreateSlider({
        Name = T("espdist.name"), NameKey = "espdist.name",
        Description = T("espdist.desc"), DescKey = "espdist.desc",
        Icon = "📐", Min = 100, Max = 10000, Default = 500,
        Callback = function(v) State.espMaxDistance = v end,
    }))

    VisualsTab:CreateSection(T("section.environment"), "section.environment")

    reg("lowGraphics", VisualsTab:CreateToggle({
        Name = T("lowgfx.name"), NameKey = "lowgfx.name",
        Description = T("lowgfx.desc"), DescKey = "lowgfx.desc",
        Icon = "📉", Default = false,
        Callback = function(v) State.lowGraphics = v; applyLowGraphics(v) end,
    }))

    reg("noShadows", VisualsTab:CreateToggle({
        Name = T("noshadow.name"), NameKey = "noshadow.name",
        Description = T("noshadow.desc"), DescKey = "noshadow.desc",
        Icon = "🌑", Default = false,
        Callback = function(v) State.noShadows = v; applyNoShadows(v) end,
    }))

    reg("noFog", VisualsTab:CreateToggle({
        Name = T("nofog.name"), NameKey = "nofog.name",
        Description = T("nofog.desc"), DescKey = "nofog.desc",
        Icon = "🌫️", Default = false,
        Callback = function(v) State.noFog = v; applyNoFog(v) end,
    }))

    reg("noParticles", VisualsTab:CreateToggle({
        Name = T("nopart.name"), NameKey = "nopart.name",
        Description = T("nopart.desc"), DescKey = "nopart.desc",
        Icon = "✨", Default = false,
        Callback = function(v) State.noParticles = v; applyNoParticles(v) end,
    }))

    -- ═══════════════════════════════════════════════
    -- ABA: SETTINGS
    -- ═══════════════════════════════════════════════
    local SettingsTab = Window:CreateTab(T("tab.settings"), "⚙️")
    SettingsTab:CreateSection(T("section.create_config"), "section.create_config")

    local configInputFrame = Instance.new("Frame", SettingsTab.container)
    configInputFrame.Size = UDim2.new(1, 0, 0, 40)
    configInputFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    configInputFrame.BorderSizePixel = 0
    configInputFrame.LayoutOrder = #SettingsTab.container:GetChildren()
    Instance.new("UICorner", configInputFrame).CornerRadius = UDim.new(0, 8)

    local cInput = Instance.new("TextBox", configInputFrame)
    cInput.Size = UDim2.new(1, -20, 1, -10)
    cInput.Position = UDim2.new(0, 10, 0, 5)
    cInput.BackgroundTransparency = 1
    cInput.Font = Enum.Font.GothamMedium
    cInput.TextSize = 12
    cInput.TextColor3 = Color3.fromRGB(240, 240, 245)
    cInput.PlaceholderText = T("config.placeholder")
    cInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 105)
    cInput.Text = ""
    cInput.ClearTextOnFocus = false
    cInput.TextXAlignment = Enum.TextXAlignment.Left

    SettingsTab:CreateSection(T("section.saved_configs"), "section.saved_configs")

    local configListFrame = Instance.new("Frame", SettingsTab.container)
    configListFrame.Size = UDim2.new(1, 0, 0, 160)
    configListFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    configListFrame.BorderSizePixel = 0
    configListFrame.LayoutOrder = #SettingsTab.container:GetChildren()
    Instance.new("UICorner", configListFrame).CornerRadius = UDim.new(0, 8)

    local configScroll = Instance.new("ScrollingFrame", configListFrame)
    configScroll.Size = UDim2.new(1, -12, 1, -12)
    configScroll.Position = UDim2.new(0, 6, 0, 6)
    configScroll.BackgroundTransparency = 1
    configScroll.BorderSizePixel = 0
    configScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    configScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    configScroll.ScrollBarThickness = 3
    configScroll.ScrollBarImageColor3 = Color3.fromRGB(230, 40, 40)

    local configListLayout = Instance.new("UIListLayout", configScroll)
    configListLayout.Padding = UDim.new(0, 4)

    local function refreshConfigList()
        for _, child in ipairs(configScroll:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
        end
        local configs = listConfigs()
        local currentAutoload = getAutoload()
        if #configs == 0 then
            local empty = Instance.new("TextLabel", configScroll)
            empty.Size = UDim2.new(1, 0, 0, 30)
            empty.BackgroundTransparency = 1
            empty.Font = Enum.Font.Gotham
            empty.TextSize = 11
            empty.TextColor3 = Color3.fromRGB(90, 90, 105)
            empty.Text = T("config.empty")
            return
        end
        for _, name in ipairs(configs) do
            local entry = Instance.new("Frame", configScroll)
            entry.Size = UDim2.new(1, -4, 0, 32)
            entry.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
            entry.BorderSizePixel = 0
            Instance.new("UICorner", entry).CornerRadius = UDim.new(0, 6)
            local nameLbl = Instance.new("TextLabel", entry)
            nameLbl.Size = UDim2.new(0.5, 0, 1, 0)
            nameLbl.Position = UDim2.new(0, 10, 0, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Enum.Font.GothamBold
            nameLbl.TextSize = 11
            nameLbl.TextColor3 = (currentAutoload == name) and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(240, 240, 245)
            nameLbl.Text = (currentAutoload == name and "⚡ " or "") .. name
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            local loadBtn = Instance.new("TextButton", entry)
            loadBtn.Size = UDim2.new(0, 50, 0, 22)
            loadBtn.Position = UDim2.new(1, -110, 0.5, -11)
            loadBtn.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
            loadBtn.Text = "Load"
            loadBtn.Font = Enum.Font.GothamBold
            loadBtn.TextSize = 10
            loadBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
            loadBtn.AutoButtonColor = false
            Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 4)
            loadBtn.MouseButton1Click:Connect(function()
                loadConfigNamed(name); refreshConfigList()
            end)
            local autoBtn = Instance.new("TextButton", entry)
            autoBtn.Size = UDim2.new(0, 22, 0, 22)
            autoBtn.Position = UDim2.new(1, -55, 0.5, -11)
            autoBtn.BackgroundColor3 = (currentAutoload == name) and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(35, 35, 45)
            autoBtn.Text = "⚡"
            autoBtn.Font = Enum.Font.GothamBold
            autoBtn.TextSize = 11
            autoBtn.TextColor3 = Color3.fromRGB(240, 240, 245)
            autoBtn.AutoButtonColor = false
            Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0, 4)
            autoBtn.MouseButton1Click:Connect(function()
                if currentAutoload == name then clearAutoload() else setAutoload(name) end
                refreshConfigList()
            end)
            local delBtn = Instance.new("TextButton", entry)
            delBtn.Size = UDim2.new(0, 22, 0, 22)
            delBtn.Position = UDim2.new(1, -28, 0.5, -11)
            delBtn.BackgroundColor3 = Color3.fromRGB(60, 15, 20)
            delBtn.Text = "×"
            delBtn.Font = Enum.Font.GothamBold
            delBtn.TextSize = 14
            delBtn.TextColor3 = Color3.fromRGB(255, 40, 40)
            delBtn.AutoButtonColor = false
            Instance.new("UICorner", delBtn).CornerRadius = UDim.new(0, 4)
            delBtn.MouseButton1Click:Connect(function()
                deleteConfigNamed(name); refreshConfigList()
            end)
        end
    end

    cInput.FocusLost:Connect(function(enterPressed)
        if enterPressed and cInput.Text ~= "" then
            saveConfigNamed(cInput.Text)
            cInput.Text = ""
            refreshConfigList()
        end
    end)

    SettingsTab:CreateButton({
        Name = T("config.refresh"), NameKey = "config.refresh",
        Callback = function()
            refreshConfigList()
            Window:Notify("🔄 Refresh", "Config list updated", 2, "info")
        end,
    })

    SettingsTab:CreateButton({
        Name = T("config.disable_autoload"), NameKey = "config.disable_autoload",
        Callback = function()
            clearAutoload(); refreshConfigList()
        end,
    })

    refreshConfigList()

    SettingsTab:CreateSection(T("section.optimizations"), "section.optimizations")
    SettingsTab:CreateButton({
        Name = T("config.fps_boost"), NameKey = "config.fps_boost",
        Callback = function()
            State.lowGraphics = true; applyLowGraphics(true)
            State.noShadows = true; applyNoShadows(true)
            State.noFog = true; applyNoFog(true)
            State.noParticles = true; applyNoParticles(true)
            syncUIFromState()
            Window:Notify("⚡ Boost", "All optimizations ON", 3, "success")
        end,
    })

    SettingsTab:CreateButton({
        Name = T("config.reset_opt"), NameKey = "config.reset_opt",
        Callback = function()
            State.lowGraphics = false; applyLowGraphics(false)
            State.noShadows = false; applyNoShadows(false)
            State.noFog = false; applyNoFog(false)
            State.noParticles = false; applyNoParticles(false)
            syncUIFromState()
            Window:Notify("Reset", "Optimizations reset", 3, "info")
        end,
    })

    SettingsTab:CreateSection(T("section.danger"), "section.danger")
    SettingsTab:CreateButton({
        Name = T("config.unload"), NameKey = "config.unload",
        Danger = true,
        Callback = function()
            UNLOADED = true
            restoreAll(); clearAllESP(); stopAirJump()
            if fovCircle then fovCircle:Remove() end
            applyLowGraphics(false); applyNoShadows(false); applyNoFog(false); applyNoParticles(false)
            Window:Notify("Unload", "Script unloaded", 2, "warning")
            task.wait(0.3); Window:Destroy()
        end,
    })

    -- ═══════════════════════════════════════════════
    -- ABA: LANGUAGE 🌍
    -- ═══════════════════════════════════════════════
    local LanguageTab = Window:CreateTab(T("tab.language"), "🌍")
    LanguageTab:CreateSection(T("section.language_select"), "section.language_select")

    local currentLangObj = nil
    for _, l in ipairs(LANGUAGES) do
        if l.code == CURRENT_LANG then currentLangObj = l; break end
    end

    local currentLangLabel = LanguageTab:CreateLabel(
        T("lang.current") .. (currentLangObj and (currentLangObj.flag .. " " .. currentLangObj.name) or CURRENT_LANG:upper()),
        Color3.fromRGB(230, 40, 40)
    )

    LanguageTab:CreateLabel(T("lang.hint"), Color3.fromRGB(140, 140, 155))

    local langOptions = {}
    local defaultIdx = 1
    for i, l in ipairs(LANGUAGES) do
        table.insert(langOptions, l.flag .. " " .. l.name)
        if l.code == CURRENT_LANG then defaultIdx = i end
    end

    LanguageTab:CreateDropdown({
        Name = "Idioma / Language",
        Description = T("lang.hint"),
        Icon = "🌍",
        Options = langOptions,
        Default = defaultIdx,
        Callback = function(opt, idx)
            local lang = LANGUAGES[idx]
            if not lang then return end
            CURRENT_LANG = lang.code
            saveLanguage(lang.code)
            applyHubLanguage(lang.code)
            if currentLangLabel then
                pcall(function()
                    currentLangLabel.Text = T("lang.current") .. lang.flag .. " " .. lang.name
                end)
            end
            if type(UI.RefreshTranslations) == "function" then
                UI:RefreshTranslations()
            end
            Window:Notify("🌍 Language", "→ " .. lang.name, 3, "success")
        end,
    })

    LanguageTab:CreateSection(T("section.language_info"), "section.language_info")
    LanguageTab:CreateLabel(T("lang.saved_to"), Color3.fromRGB(140, 140, 155))
    LanguageTab:CreateLabel(LANG_FILE, Color3.fromRGB(230, 40, 40))
    LanguageTab:CreateLabel(T("lang.auto_restore"), Color3.fromRGB(90, 90, 105))
    LanguageTab:CreateLabel("External translations: " .. EXTRA_TR_FILE, Color3.fromRGB(90, 90, 105))

    -- ═══════════════════════════════════════════════
    -- ABA: CREDITS
    -- ═══════════════════════════════════════════════
    local CreditsTab = Window:CreateTab(T("tab.credits"), "➕")
    CreditsTab:CreateSection(T("section.founder"), "section.founder")
    CreditsTab:CreateLabel(T("credits.role"), Color3.fromRGB(255, 50, 50))

    CreditsTab:CreateSection(T("section.community"), "section.community")
    CreditsTab:CreateLabel("discord.gg/ScZfU2mAGm", Color3.fromRGB(88, 101, 242))
    CreditsTab:CreateButton({
        Name = T("credits.copy_discord"), NameKey = "credits.copy_discord",
        Callback = function()
            if setclipboard then
                setclipboard("https://discord.gg/ScZfU2mAGm")
                Window:Notify("📋 Copied", "Discord link copied!", 3, "success")
            end
        end,
    })

    CreditsTab:CreateSection(T("section.version"), "section.version")
    CreditsTab:CreateLabel(FULL_VERSION, Color3.fromRGB(140, 140, 155))
    CreditsTab:CreateLabel("© 2026 Sr Red", Color3.fromRGB(90, 90, 105))

    -- ═══════════════════════════════════════════════
    -- KEYBIND SYSTEM
    -- ═══════════════════════════════════════════════
    UserInputService.InputBegan:Connect(function(input, gp)
        if UNLOADED or gp then return end
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local keyName = input.KeyCode.Name
        for featId, key in pairs(State.keybinds) do
            if key and key == keyName then
                if featId == "backstab" and State.backstab then doBackstab() end
            end
        end
    end)

    -- ═══════════════════════════════════════════════
    -- AUTOLOAD
    -- ═══════════════════════════════════════════════
    task.defer(function()
        local autoloadName = getAutoload()
        if autoloadName then
            task.wait(1)
            local ok = loadConfigNamed(autoloadName)
            if ok then
                task.wait(0.1)
                pcall(syncUIFromState)
                Window:Notify("⚡ Autoload", "Config aplicado: " .. autoloadName, 3, "success")
            end
        end
    end)

    Window:Notify("✅ " .. SHORT_VERSION, "Arsenal loaded successfully", 4, "success")
    print("[Infinite Zen] ✅ " .. FULL_VERSION .. " carregado!")
end

return Arsenal