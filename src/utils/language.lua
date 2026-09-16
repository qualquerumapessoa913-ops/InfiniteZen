-- ============================================================
-- INFINITE ZEN - SISTEMA DE IDIOMAS (MULTI-LANG) v3.1
-- ============================================================

local HttpService = game:GetService("HttpService")

local Language = {}

Language.current = "en"
Language.listeners = {}

-- ═══════════════════════════════════════════════════════════
-- REGISTRO DE IDIOMAS (SEMPRE APARECEM NA LISTA)
-- ═══════════════════════════════════════════════════════════
Language.languages = {
    { code="en",    flag="🇺🇸", displayName="English (US)" },
    { code="pt-br", flag="🇧🇷", displayName="Português (BR)" },
    { code="es",    flag="🇪🇸", displayName="Español (ES)" },
    { code="fr",    flag="🇫🇷", displayName="Français (FR)" },
    { code="de",    flag="🇩🇪", displayName="Deutsch (DE)" },
    { code="it",    flag="🇮🇹", displayName="Italiano (IT)" },
    { code="ru",    flag="🇷🇺", displayName="Русский (RU)" },
    { code="pl",    flag="🇵🇱", displayName="Polski (PL)" },
    { code="tr",    flag="🇹🇷", displayName="Türkçe (TR)" },
    { code="id",    flag="🇮🇩", displayName="Bahasa Indonesia (ID)" },
    { code="ph",    flag="🇵🇭", displayName="Filipino (PH)" },
    { code="vn",    flag="🇻🇳", displayName="Tiếng Việt (VN)" },
    { code="jp",    flag="🇯🇵", displayName="日本語 (JP)" },
    { code="kr",    flag="🇰🇷", displayName="한국어 (KR)" },
    { code="cn",    flag="🇨🇳", displayName="中文 (CN)" },
    { code="ar",    flag="🇸🇦", displayName="العربية (SA)" },
    { code="hi",    flag="🇮🇳", displayName="हिन्दी (IN)" },
    { code="nl",    flag="🇳🇱", displayName="Nederlands (NL)" },
    { code="se",    flag="🇸🇪", displayName="Svenska (SE)" },
    { code="ro",    flag="🇷🇴", displayName="Română (RO)" },
}
-- ═══════════════════════════════════════════════════════════
-- TRADUÇÕES (EN + PT-BR HARDCODED)
-- ═══════════════════════════════════════════════════════════
Language.translations = {
    ["en"] = {
        flag = "US", displayName = "English (US)", shortCode = "US",
        hub_name = "INFINITE ZEN", hub_subtitle = "Multi-Game Edition",
        language_label = "Language", unsupported_title = "Unsupported Game",
        unsupported_message_pt = "Este jogo não é suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
        error_title = "Error", load_title = "Load", config_title = "Config",
        no_enemy = "No enemy found", unload_script = "Unload Script", version_text = "Infinite Zen v3.0",

        ["tab.combat"]="Combat", ["tab.weapon"]="Weapon", ["tab.movement"]="Movement",
        ["tab.visuals"]="Visuals", ["tab.settings"]="Settings", ["tab.language"]="Language",
        ["tab.credits"]="Credits", ["tab.skins"]="Skins", ["tab.utils"]="Utils",
        ["tab.sheriff"]="Sheriff", ["tab.murderer"]="Murderer", ["tab.innocent"]="Innocent",

        ["section.aim"]="Aim", ["section.auto"]="Auto", ["section.hitbox"]="Hitbox",
        ["section.melee"]="Melee", ["section.recoil"]="Recoil", ["section.firerate"]="Fire Rate",
        ["section.reload"]="Reload", ["section.ammo"]="Ammo", ["section.bulletmods"]="Bullet Mods",
        ["section.visualmods"]="Visual Mods", ["section.speed"]="Speed", ["section.jump"]="Jump",
        ["section.fly"]="Fly", ["section.esp"]="ESP", ["section.esp_elements"]="ESP Elements",
        ["section.environment"]="Environment", ["section.alert"]="Alert", ["section.utility"]="Utility",
        ["section.security"]="Security", ["section.create_config"]="Create Config",
        ["section.saved_configs"]="Saved Configs", ["section.optimizations"]="Optimizations",
        ["section.danger"]="Danger Zone", ["section.language_select"]="Language",
        ["section.language_info"]="Info", ["section.founder"]="Founder & Developer",
        ["section.community"]="Community", ["section.version"]="Version",

        ["silent.name"]="Silent Aim", ["silent.desc"]="Auto-lock aim when holding click",
        ["silentfov.name"]="Silent FOV", ["silentfov.desc"]="Field of view radius",
        ["aimbot.name"]="Aimbot", ["aimbot.desc"]="Camera lock on closest enemy",
        ["aimbotfov.name"]="Aimbot FOV", ["aimbotfov.desc"]="Field of view radius",
        ["aimbotsmooth.name"]="Smoothness", ["aimbotsmooth.desc"]="Lower = snappier",
        ["aimbotdist.name"]="Max Distance", ["aimbotdist.desc"]="Maximum range",
        ["aimbotwall.name"]="Wall Check", ["aimbotwall.desc"]="Only aim if visible",
        ["aimbothitbox.name"]="Hitbox", ["aimbothitbox.desc"]="Which part to target",
        ["wallcheck.name"]="Wall Check", ["wallcheck.desc"]="Only with line of sight",
        ["triggerbot.name"]="Triggerbot", ["triggerbot.desc"]="Auto-fire on crosshair",
        ["triggerbotdelay.name"]="Triggerbot Delay", ["triggerbotdelay.desc"]="Reaction time (ms)",
        ["autoshot.name"]="Auto Shoot", ["autoshot.desc"]="Auto-fire on visible enemies",
        ["autoshotfov.name"]="Auto Shoot FOV", ["autoshotfov.desc"]="Radius for auto-fire",
        ["killaura.name"]="Kill Aura", ["killaura.desc"]="Auto-attack nearby enemies",
        ["killaurarange.name"]="Kill Aura Range", ["killauradelay.name"]="Kill Aura Delay",
        ["autobackstab.name"]="Auto Backstab", ["autobackstab.desc"]="Strike when enemy back is turned",
        ["backstab.name"]="Backstab", ["backstab.desc"]="Teleport behind enemy (keybind: E)",
        ["headexp.name"]="Head Expander", ["headexp.desc"]="Enlarge enemy head hitbox",
        ["headsize.name"]="Head Size", ["headsize.desc"]="Multiplier for head size",
        ["norecoil.name"]="No Recoil", ["norecoil.desc"]="Remove all weapon recoil",
        ["nospread.name"]="No Spread", ["nospread.desc"]="Remove bullet dispersion",
        ["rapidfire.name"]="Rapid Fire", ["rapidfire.desc"]="Reduce fire delay to minimum",
        ["fastreload.name"]="Fast Reload", ["fastreload.desc"]="Faster reload animation",
        ["instareload.name"]="Insta Reload", ["instareload.desc"]="Instant reload",
        ["infiniteammo.name"]="Infinite Ammo", ["infiniteammo.desc"]="Unlimited ammunition",
        ["speed.name"]="Speed", ["speed.desc"]="Custom walkspeed",
        ["speedvalue.name"]="Speed Value", ["speedvalue.desc"]="WalkSpeed value",
        ["fly.name"]="Fly", ["fly.desc"]="Free-fly (WASD + Space/Ctrl)",
        ["flyspeed.name"]="Fly Speed", ["flyspeed.desc"]="Flight velocity",
        ["airjump.name"]="Infinite Jump", ["airjump.desc"]="Jump mid-air infinitely",
        ["jumppower.name"]="Jump Power", ["jumppower.desc"]="Jump velocity",
        ["autobhop.name"]="Auto Bhop", ["autobhop.desc"]="Auto-jump while holding space",
        ["noclip.name"]="Noclip", ["noclip.desc"]="Walk through walls",
        ["fullbright.name"]="Fullbright", ["fullbright.desc"]="Map always bright",
        ["esp.name"]="Player ESP", ["esp.desc"]="Highlight enemies through walls",
        ["espdist.name"]="Max Distance", ["espdist.desc"]="ESP render range",
        ["espweapon.name"]="Weapon ESP", ["espweapon.desc"]="Show enemy weapons",
        ["esptracer.name"]="Tracer ESP", ["esptracer.desc"]="Draw tracer lines",
        ["damageindicator.name"]="Damage Indicator", ["damageindicator.desc"]="Red arrow when hit",
        ["lowgfx.name"]="Low Graphics", ["lowgfx.desc"]="Reduce rendering quality for FPS",
        ["noshadow.name"]="No Shadows", ["noshadow.desc"]="Remove all shadows",
        ["nofog.name"]="No Fog", ["nofog.desc"]="Remove fog and atmosphere",
        ["nopart.name"]="No Particles", ["nopart.desc"]="Remove all particle effects",
        ["antiflash.name"]="Anti-Flash", ["antiflash.desc"]="Blocks flashbang effect",
        ["antivotekick.name"]="Anti-VoteKick", ["antivotekick.desc"]="Blocks votekick attempts",
        ["config.placeholder"]="Config name + Enter to save...", ["config.refresh"]="🔄 Refresh List",
        ["config.disable_autoload"]="🚫 Disable Autoload", ["config.fps_boost"]="⚡ Max FPS Boost",
        ["config.reset_opt"]="🔄 Reset Optimizations", ["config.unload"]="Unload Script",
        ["config.empty"]="No configs saved yet.",
        ["lang.current"]="🌐 Current: ", ["lang.hint"]="Choose the hub language (applies instantly).",
        ["lang.saved_to"]="Language saved to:", ["lang.auto_restore"]="Auto-restored on open.",
        ["credits.copy_discord"]="📋 Copy Discord Link", ["credits.role"]="Sr Red",

        ["mm2.show.murderer"]="Show Murderer", ["mm2.show.sheriff"]="Show Sheriff", ["mm2.show.innocent"]="Show Innocent",
        ["mm2.murderer.alert"]="Murderer Alert", ["mm2.murderer.alert.desc"]="Alert when killer is nearby",
        ["mm2.murderer.alert.range"]="Alert Range",
        ["mm2.gunlocator.name"]="Gun Locator", ["mm2.gunlocator.desc"]="Track dropped gun",
        ["mm2.autocoin.name"]="Auto Coin Farm", ["mm2.autocoin.desc"]="Fly through coins",
        ["mm2.autocoin.speed"]="Coin Flight Speed",
        ["mm2.autograb.name"]="Auto Grab Gun", ["mm2.autograb.desc"]="Grab dropped gun",
        ["mm2.autograb.range"]="Grab Range",
        ["mm2.role.murderer"]="Murderer", ["mm2.role.sheriff"]="Sheriff", ["mm2.role.innocent"]="Innocent",

        ["jb.esp.armor"]="Armor ESP", ["jb.esp.armor.desc"]="Show enemy armor value",
        ["jb.esp.grenades"]="Grenade ESP", ["jb.esp.grenades.desc"]="Show nearby grenades",
        ["bs.esp.weapon"]="Weapon ESP", ["bs.esp.armor"]="Armor ESP",
    },
    ["pt-br"] = {
        flag = "BR", displayName = "Português (BR)", shortCode = "BR",
        hub_name = "INFINITE ZEN", hub_subtitle = "Edição Multi-Jogos",
        language_label = "Idioma", unsupported_title = "Jogo Não Suportado",
        unsupported_message_pt = "Este jogo não é suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
        error_title = "Erro", load_title = "Carregar", config_title = "Config",
        no_enemy = "Nenhum inimigo", unload_script = "Descarregar Script", version_text = "Infinite Zen v3.0",

        ["tab.combat"]="Combate", ["tab.weapon"]="Arma", ["tab.movement"]="Movimento",
        ["tab.visuals"]="Visual", ["tab.settings"]="Config", ["tab.language"]="Idioma",
        ["tab.credits"]="Créditos", ["tab.skins"]="Skins", ["tab.utils"]="Utils",
        ["tab.sheriff"]="Xerife", ["tab.murderer"]="Assassino", ["tab.innocent"]="Inocente",

        ["section.aim"]="Mira", ["section.auto"]="Auto", ["section.hitbox"]="Hitbox",
        ["section.melee"]="Corpo a corpo", ["section.recoil"]="Recuo", ["section.firerate"]="Cadência",
        ["section.reload"]="Recarga", ["section.ammo"]="Munição", ["section.bulletmods"]="Mods de Bala",
        ["section.visualmods"]="Mods Visuais", ["section.speed"]="Velocidade", ["section.jump"]="Pulo",
        ["section.fly"]="Voo", ["section.esp"]="ESP", ["section.esp_elements"]="Elementos do ESP",
        ["section.environment"]="Ambiente", ["section.alert"]="Alerta", ["section.utility"]="Utilidade",
        ["section.security"]="Segurança", ["section.create_config"]="Criar Config",
        ["section.saved_configs"]="Configs Salvos", ["section.optimizations"]="Otimizações",
        ["section.danger"]="Zona de Perigo", ["section.language_select"]="Idioma",
        ["section.language_info"]="Info", ["section.founder"]="Fundador & Desenvolvedor",
        ["section.community"]="Comunidade", ["section.version"]="Versão",

        ["silent.name"]="Mira Silenciosa", ["silent.desc"]="Trava a mira ao segurar clique",
        ["silentfov.name"]="FOV Silencioso", ["silentfov.desc"]="Raio do campo de visão",
        ["aimbot.name"]="Aimbot", ["aimbot.desc"]="Trava câmera no inimigo mais próximo",
        ["aimbotfov.name"]="FOV do Aimbot", ["aimbotfov.desc"]="Raio do campo de visão",
        ["aimbotsmooth.name"]="Suavidade", ["aimbotsmooth.desc"]="Menor = mais rápido",
        ["aimbotdist.name"]="Distância Máx", ["aimbotdist.desc"]="Alcance máximo",
        ["aimbotwall.name"]="Verificar Parede", ["aimbotwall.desc"]="Só mira se visível",
        ["aimbothitbox.name"]="Hitbox", ["aimbothitbox.desc"]="Qual parte mirar",
        ["wallcheck.name"]="Verificar Parede", ["wallcheck.desc"]="Só com linha de visão",
        ["triggerbot.name"]="Triggerbot", ["triggerbot.desc"]="Atira quando crosshair no alvo",
        ["triggerbotdelay.name"]="Delay do Triggerbot", ["triggerbotdelay.desc"]="Tempo de reação (ms)",
        ["autoshot.name"]="Tiro Automático", ["autoshot.desc"]="Atira sozinho em inimigos visíveis",
        ["autoshotfov.name"]="FOV do Tiro Auto", ["autoshotfov.desc"]="Raio pra atirar automaticamente",
        ["killaura.name"]="Kill Aura", ["killaura.desc"]="Ataca inimigos próximos sozinho",
        ["killaurarange.name"]="Alcance do Kill Aura", ["killauradelay.name"]="Delay do Kill Aura",
        ["autobackstab.name"]="Backstab Auto", ["autobackstab.desc"]="Ataca quando inimigo de costas",
        ["backstab.name"]="Backstab", ["backstab.desc"]="Teleporta atrás do inimigo (tecla: E)",
        ["headexp.name"]="Head Expander", ["headexp.desc"]="Aumenta a hitbox da cabeça",
        ["headsize.name"]="Tamanho da Cabeça", ["headsize.desc"]="Multiplicador do tamanho",
        ["norecoil.name"]="Sem Recuo", ["norecoil.desc"]="Remove todo recuo da arma",
        ["nospread.name"]="Sem Dispersão", ["nospread.desc"]="Remove dispersão das balas",
        ["rapidfire.name"]="Tiro Rápido", ["rapidfire.desc"]="Reduz delay entre tiros",
        ["fastreload.name"]="Reload Rápido", ["fastreload.desc"]="Recarga mais rápida",
        ["instareload.name"]="Reload Instantâneo", ["instareload.desc"]="Recarga na hora",
        ["infiniteammo.name"]="Munição Infinita", ["infiniteammo.desc"]="Munição ilimitada",
        ["speed.name"]="Velocidade", ["speed.desc"]="Velocidade personalizada",
        ["speedvalue.name"]="Valor da Velocidade", ["speedvalue.desc"]="Valor do WalkSpeed",
        ["fly.name"]="Voo", ["fly.desc"]="Voo livre (WASD + Espaço/Ctrl)",
        ["flyspeed.name"]="Velocidade do Voo", ["flyspeed.desc"]="Velocidade de voo",
        ["airjump.name"]="Pulo Infinito", ["airjump.desc"]="Pula no ar infinitamente",
        ["jumppower.name"]="Força do Pulo", ["jumppower.desc"]="Velocidade do pulo",
        ["autobhop.name"]="Auto Bhop", ["autobhop.desc"]="Pula sozinho segurando espaço",
        ["noclip.name"]="Noclip", ["noclip.desc"]="Atravessa paredes",
        ["fullbright.name"]="Fullbright", ["fullbright.desc"]="Mapa sempre claro",
        ["esp.name"]="ESP de Jogador", ["esp.desc"]="Destaca inimigos através das paredes",
        ["espdist.name"]="Distância Máxima", ["espdist.desc"]="Alcance do ESP",
        ["espweapon.name"]="ESP de Arma", ["espweapon.desc"]="Mostra as armas dos inimigos",
        ["esptracer.name"]="ESP de Tracer", ["esptracer.desc"]="Desenha linhas até os alvos",
        ["damageindicator.name"]="Indicador de Dano", ["damageindicator.desc"]="Seta vermelha quando acertado",
        ["lowgfx.name"]="Gráficos Baixos", ["lowgfx.desc"]="Reduz qualidade gráfica pra FPS",
        ["noshadow.name"]="Sem Sombras", ["noshadow.desc"]="Remove todas as sombras",
        ["nofog.name"]="Sem Névoa", ["nofog.desc"]="Remove névoa e atmosfera",
        ["nopart.name"]="Sem Partículas", ["nopart.desc"]="Remove efeitos de partículas",
        ["antiflash.name"]="Anti-Flash", ["antiflash.desc"]="Bloqueia efeito de flashbang",
        ["antivotekick.name"]="Anti-VoteKick", ["antivotekick.desc"]="Bloqueia tentativas de votekick",
        ["config.placeholder"]="Nome do config + Enter pra salvar...", ["config.refresh"]="🔄 Atualizar Lista",
        ["config.disable_autoload"]="🚫 Desativar Autoload", ["config.fps_boost"]="⚡ Boost Máximo de FPS",
        ["config.reset_opt"]="🔄 Resetar Otimizações", ["config.unload"]="Descarregar Script",
        ["config.empty"]="Nenhum config salvo ainda.",
        ["lang.current"]="🌐 Atual: ", ["lang.hint"]="Escolha o idioma do hub (aplica na hora e é salvo).",
        ["lang.saved_to"]="Idioma salvo em:", ["lang.auto_restore"]="É restaurado ao abrir o hub.",
        ["credits.copy_discord"]="📋 Copiar Link do Discord", ["credits.role"]="Sr Red",

        ["mm2.show.murderer"]="Mostrar Assassino", ["mm2.show.sheriff"]="Mostrar Xerife", ["mm2.show.innocent"]="Mostrar Inocente",
        ["mm2.murderer.alert"]="Alerta do Assassino", ["mm2.murderer.alert.desc"]="Avisa quando o assassino tá perto",
        ["mm2.murderer.alert.range"]="Alcance do Alerta",
        ["mm2.gunlocator.name"]="Localizador de Arma", ["mm2.gunlocator.desc"]="Rastreia a arma caída do Xerife",
        ["mm2.autocoin.name"]="Farm Automático de Moedas", ["mm2.autocoin.desc"]="Voa entre as moedas",
        ["mm2.autocoin.speed"]="Velocidade de Voo",
        ["mm2.autograb.name"]="Pegar Arma Auto", ["mm2.autograb.desc"]="Pega a arma do Xerife quando cai",
        ["mm2.autograb.range"]="Alcance de Pegar",
        ["mm2.role.murderer"]="Assassino", ["mm2.role.sheriff"]="Xerife", ["mm2.role.innocent"]="Inocente",

        ["jb.esp.armor"]="ESP de Armadura", ["jb.esp.armor.desc"]="Mostra o valor da armadura do inimigo",
        ["jb.esp.grenades"]="ESP de Granada", ["jb.esp.grenades.desc"]="Mostra granadas próximas",
        ["bs.esp.weapon"]="ESP de Arma", ["bs.esp.armor"]="ESP de Armadura",
    },
}

-- ═══════════════════════════════════════════════════════════
-- CARREGA JSON EXTERNO
-- ═══════════════════════════════════════════════════════════
local EXTRA_FILE = "InfiniteZen_Translations.json"

local function loadExtraTranslations()
    if not readfile or not isfile then
        warn("[IZ Lang] readfile/isfile indisponível — só EN + PT-BR")
        return
    end
    if not isfile(EXTRA_FILE) then
        warn("[IZ Lang] " .. EXTRA_FILE .. " não encontrado — só EN + PT-BR")
        return
    end

    local ok, raw = pcall(readfile, EXTRA_FILE)
    if not ok or not raw or raw == "" then
        warn("[IZ Lang] Falha ao ler " .. EXTRA_FILE)
        return
    end

    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then
        warn("[IZ Lang] JSON corrompido: " .. EXTRA_FILE)
        return
    end

    local count = 0
    for code, tbl in pairs(data) do
        Language.translations[code] = Language.translations[code] or {}
        for k, v in pairs(tbl) do
            Language.translations[code][k] = v
        end
        count = count + 1
    end
    print("[IZ Lang] ✅ " .. count .. " idiomas extras carregados do JSON")
end

loadExtraTranslations()

-- ═══════════════════════════════════════════════════════════
-- CARREGA IDIOMA SALVO
-- ═══════════════════════════════════════════════════════════
local LANG_FILE = "InfiniteZen_Language.txt"

local function loadSavedLanguage()
    if not readfile or not isfile then return end
    if not isfile(LANG_FILE) then return end
    local ok, content = pcall(readfile, LANG_FILE)
    if ok and content and content ~= "" then
        local code = content:gsub("%s+", "")
        if Language.translations[code] then
            Language.current = code
            print("[IZ Lang] Idioma restaurado: " .. code)
        end
    end
end

loadSavedLanguage()

-- ═══════════════════════════════════════════════════════════
-- API
-- ═══════════════════════════════════════════════════════════
function Language.get(key)
    local t = Language.translations[Language.current]
    if t and t[key] then return t[key] end
    local fb = Language.translations["en"]
    if fb and fb[key] then return fb[key] end
    return key
end

function Language.setLanguage(code)
    if not Language.translations[code] then
        print("[LANG] Código não encontrado: " .. tostring(code))
        return false
    end
    Language.current = code
    print("[LANG] Idioma alterado para: " .. code)
    if writefile then pcall(writefile, LANG_FILE, code) end
    if _G.IZ_RefreshLanguage then pcall(_G.IZ_RefreshLanguage) end
    for _, callback in ipairs(Language.listeners) do
        pcall(callback)
    end
    return true
end

function Language.getCurrent() return Language.current end
function Language.getCurrentData() return Language.translations[Language.current] end

-- ⭐ Retorna SEMPRE os 20 idiomas registrados (mesmo se o JSON falhou)
function Language.getAvailable()
    local list = {}
    for _, info in ipairs(Language.languages) do
        table.insert(list, {
            code = info.code,
            flag = info.flag,
            displayName = info.displayName,
            shortCode = info.flag,
            -- Avisa se tem tradução carregada (JSON merge) ou só fallback EN
            hasTranslation = (Language.translations[info.code] ~= nil),
        })
    end
    return list
end

function Language.onChange(callback)
    table.insert(Language.listeners, callback)
end

return Language