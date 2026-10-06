-- ============================================================
-- INFINITE ZEN - LANGUAGE v3.7
-- ============================================================

local HttpService = game:GetService("HttpService")

local Language = {}
Language.current = "en"
Language.listeners = {}

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

Language.translations = {}

for _, info in ipairs(Language.languages) do
    Language.translations[info.code] = {
        flag = info.flag,
        displayName = info.displayName,
    }
end

Language.translations["en"] = {
    flag="🇺🇸", displayName="English (US)",
    ["tab.combat"]="Combat", ["tab.weapon"]="Weapon", ["tab.movement"]="Movement",
    ["tab.visuals"]="Visuals", ["tab.settings"]="Settings", ["tab.language"]="Language",
    ["tab.credits"]="Credits", ["tab.skins"]="Skins", ["tab.utils"]="Utils",
    ["tab.sheriff"]="Sheriff", ["tab.murderer"]="Murderer", ["tab.innocent"]="Innocent",
    ["section.aim"]="Aim", ["section.auto"]="Auto", ["section.hitbox"]="Hitbox", ["section.melee"]="Melee",
    ["section.recoil"]="Recoil", ["section.firerate"]="Fire Rate", ["section.reload"]="Reload", ["section.ammo"]="Ammo",
    ["section.bulletmods"]="Bullet Mods", ["section.visualmods"]="Visual Mods",
    ["section.speed"]="Speed", ["section.jump"]="Jump", ["section.fly"]="Fly",
    ["section.esp"]="ESP", ["section.esp_elements"]="ESP Elements", ["section.environment"]="Environment",
    ["section.alert"]="Alert",
    ["section.camera"]="Camera", ["section.utility"]="Utility", ["section.security"]="Security",
    ["section.create_config"]="Create Config", ["section.saved_configs"]="Saved Configs",
    ["section.optimizations"]="Optimizations", ["section.danger"]="Danger Zone",
    ["section.language_select"]="Language", ["section.language_info"]="Info",
    ["section.founder"]="Founder & Developer", ["section.community"]="Community", ["section.version"]="Version",

    ["aimbot.name"]="Aimbot", ["aimbot.desc"]="Camera lock on closest enemy",
    ["aimbotfov.name"]="Aimbot FOV", ["aimbotfov.desc"]="Field of view radius",
    ["aimbotsmooth.name"]="Smoothness", ["aimbotsmooth.desc"]="Lower = faster",
    ["aimbotdist.name"]="Max Distance", ["aimbotdist.desc"]="Maximum range",
    ["aimbotwall.name"]="Wall Check", ["aimbotwall.desc"]="Only aim if visible",
    ["aimbothitbox.name"]="Hitbox", ["aimbothitbox.desc"]="Which part to aim",
    ["wallcheck.name"]="Wall Check", ["wallcheck.desc"]="Only with line of sight",

    ["killaura.name"]="Kill Aura", ["killaura.desc"]="Attacks automatically",
    ["killaurarange.name"]="Aura Range", ["killauradelay.name"]="Aura Delay",
    ["autobackstab.name"]="Auto Backstab", ["autobackstab.desc"]="Attacks when enemy's back is turned",
    ["backstab.name"]="Backstab", ["backstab.desc"]="Teleport behind enemy (E)",

    ["headexp.name"]="Head Expander", ["headexp.desc"]="Enlarge enemy head hitbox",
    ["headsize.name"]="Head Size", ["headsize.desc"]="Size multiplier",

    ["norecoil.name"]="No Recoil", ["norecoil.desc"]="Remove all weapon recoil",
    ["nospread.name"]="No Spread", ["nospread.desc"]="Remove bullet dispersion",
    ["rapidfire.name"]="Rapid Fire", ["rapidfire.desc"]="Reduce fire delay to minimum",
    ["fastreload.name"]="Fast Reload", ["fastreload.desc"]="Faster reload animation",
    ["instareload.name"]="Insta Reload", ["instareload.desc"]="Instant reload",
    ["rainbowgun.name"]="Rainbow Gun", ["rainbowgun.desc"]="Cycles weapon colors like a rainbow",
    ["rainbowspeed.name"]="Rainbow Speed", ["rainbowspeed.desc"]="Delay between color changes",
    ["ghostgun.name"]="Ghost Gun", ["ghostgun.desc"]="Makes weapon semi-transparent",
    ["ghosttrans.name"]="Ghost Transparency", ["ghosttrans.desc"]="0 = invisible, 1 = opaque",

    ["speed.name"]="Speed", ["speed.desc"]="Custom walkspeed",
    ["speedvalue.name"]="Speed Value", ["speedvalue.desc"]="WalkSpeed value",
    ["fly.name"]="Fly", ["fly.desc"]="Free flight (WASD + Space/Ctrl)",
    ["flyspeed.name"]="Fly Speed", ["flyspeed.desc"]="Flight speed",
    ["airjump.name"]="Infinite Jump", ["airjump.desc"]="Jump mid-air infinitely",
    ["jumppower.name"]="Jump Power", ["jumppower.desc"]="Jump velocity",
    ["noclip.name"]="Noclip", ["noclip.desc"]="Walk through walls",
    ["fullbright.name"]="Fullbright", ["fullbright.desc"]="Map always bright",
    ["antiafk.name"]="Anti-AFK", ["antiafk.desc"]="Not kicked for inactivity",
    ["camerafov.name"]="Camera FOV", ["camerafov.desc"]="Field of view",

    ["esp.name"]="Player ESP", ["esp.desc"]="Highlight enemies through walls",
    ["espdist.name"]="Max Distance", ["espdist.desc"]="ESP render range",
    ["espweapon.name"]="Weapon ESP", ["espweapon.desc"]="Show enemy weapons",
    ["esptracer.name"]="Tracer ESP", ["esptracer.desc"]="Draw lines to targets",
    ["damageindicator.name"]="Damage Indicator", ["damageindicator.desc"]="Red arrow on damage",
    ["lowgfx.name"]="Low Graphics", ["lowgfx.desc"]="Reduce rendering quality for FPS",
    ["noshadow.name"]="No Shadows", ["noshadow.desc"]="Remove all shadows",
    ["nofog.name"]="No Fog", ["nofog.desc"]="Remove fog and atmosphere",
    ["nopart.name"]="No Particles", ["nopart.desc"]="Remove all particle effects",
    ["antiflash.name"]="Anti-Flash", ["antiflash.desc"]="Block flashbang effect",

    ["config.placeholder"]="Config name + Enter to save...", ["config.refresh"]="🔄 Refresh List",
    ["config.disable_autoload"]="🚫 Disable Autoload", ["config.fps_boost"]="⚡ Max FPS Boost",
    ["config.reset_opt"]="🔄 Reset Optimizations", ["config.unload"]="Unload Script",
    ["config.empty"]="No configs saved yet.",

    ["lang.current"]="🌐 Current: ", ["lang.hint"]="Choose the hub language",
    ["lang.saved_to"]="Language saved to:", ["lang.auto_restore"]="Auto-restored on open.",

    ["credits.copy_discord"]="📋 Copy Discord Link", ["credits.role"]="Sr Red",

    ["mm2.show.murderer"]="Show Murderer", ["mm2.show.sheriff"]="Show Sheriff", ["mm2.show.innocent"]="Show Innocent",
    ["mm2.murderer.alert"]="Murderer Alert", ["mm2.murderer.alert.desc"]="Alerts when murderer is near",
    ["mm2.murderer.alert.range"]="Alert Range",
    ["mm2.gunlocator.name"]="Gun Locator", ["mm2.gunlocator.desc"]="Tracks Sheriff's dropped gun",
    ["mm2.autocoin.name"]="Auto Coin Farm", ["mm2.autocoin.desc"]="Flies between coins", ["mm2.autocoin.speed"]="Fly Speed",
    ["mm2.autograb.name"]="Auto Grab Gun", ["mm2.autograb.desc"]="Grabs dropped Sheriff gun", ["mm2.autograb.range"]="Grab Range",
    ["mm2.role.murderer"]="Murderer", ["mm2.role.sheriff"]="Sheriff", ["mm2.role.innocent"]="Innocent",

    ["jb.esp.armor"]="Armor ESP", ["jb.esp.armor.desc"]="Show enemy armor value",
    ["jb.esp.grenades"]="Grenade ESP", ["jb.esp.grenades.desc"]="Show nearby grenades",

    ["bs.esp.weapon"]="Weapon ESP", ["bs.esp.armor"]="Armor ESP",
}

Language.translations["pt-br"] = {
    flag="🇧🇷", displayName="Português (BR)",
    ["tab.combat"]="Combate", ["tab.weapon"]="Arma", ["tab.movement"]="Movimento",
    ["tab.visuals"]="Visual", ["tab.settings"]="Config", ["tab.language"]="Idioma",
    ["tab.credits"]="Créditos", ["tab.skins"]="Skins", ["tab.utils"]="Utils",
    ["tab.sheriff"]="Xerife", ["tab.murderer"]="Assassino", ["tab.innocent"]="Inocente",
    ["section.aim"]="Mira", ["section.auto"]="Auto", ["section.hitbox"]="Hitbox", ["section.melee"]="Corpo a corpo",
    ["section.recoil"]="Recuo", ["section.firerate"]="Cadência", ["section.reload"]="Recarga", ["section.ammo"]="Munição",
    ["section.bulletmods"]="Mods de Bala", ["section.visualmods"]="Mods Visuais",
    ["section.speed"]="Velocidade", ["section.jump"]="Pulo", ["section.fly"]="Voo",
    ["section.esp"]="ESP", ["section.esp_elements"]="Elementos ESP", ["section.environment"]="Ambiente",
    ["section.alert"]="Alerta",
    ["section.camera"]="Câmera", ["section.utility"]="Utilidade", ["section.security"]="Segurança",
    ["section.create_config"]="Criar Config", ["section.saved_configs"]="Configs Salvos",
    ["section.optimizations"]="Otimizações", ["section.danger"]="Zona de Perigo",
    ["section.language_select"]="Idioma", ["section.language_info"]="Info",
    ["section.founder"]="Fundador & Desenvolvedor", ["section.community"]="Comunidade", ["section.version"]="Versão",

    ["aimbot.name"]="Aimbot", ["aimbot.desc"]="Trava câmera no inimigo mais próximo",
    ["aimbotfov.name"]="FOV do Aimbot", ["aimbotfov.desc"]="Raio do campo de visão",
    ["aimbotsmooth.name"]="Suavidade", ["aimbotsmooth.desc"]="Menor = mais rápido",
    ["aimbotdist.name"]="Distância Máx", ["aimbotdist.desc"]="Alcance máximo",
    ["aimbotwall.name"]="Verificar Parede", ["aimbotwall.desc"]="Só mirar se estiver visível",
    ["aimbothitbox.name"]="Hitbox", ["aimbothitbox.desc"]="Qual parte mirar",
    ["wallcheck.name"]="Verificar Parede", ["wallcheck.desc"]="Só com linha de visão",

    ["killaura.name"]="Aura de Morte", ["killaura.desc"]="Ataca automaticamente",
    ["killaurarange.name"]="Alcance da Aura", ["killauradelay.name"]="Atraso da Aura",
    ["autobackstab.name"]="Facada Automática", ["autobackstab.desc"]="Ataca quando o inimigo vira as costas",
    ["backstab.name"]="Backstab", ["backstab.desc"]="Teleporta atrás do inimigo (E)",

    ["headexp.name"]="Head Expander", ["headexp.desc"]="Aumenta a hitbox da cabeça",
    ["headsize.name"]="Tamanho da Cabeça", ["headsize.desc"]="Multiplicador do tamanho",

    ["norecoil.name"]="Sem Recuo", ["norecoil.desc"]="Remove todo recuo",
    ["nospread.name"]="Sem Dispersão", ["nospread.desc"]="Remove dispersão das balas",
    ["rapidfire.name"]="Tiro Rápido", ["rapidfire.desc"]="Reduz delay entre tiros",
    ["fastreload.name"]="Reload Rápido", ["fastreload.desc"]="Recarga mais rápida",
    ["instareload.name"]="Reload Instantâneo", ["instareload.desc"]="Recarga na hora",
    ["rainbowgun.name"]="Arma Arco-Íris", ["rainbowgun.desc"]="Muda a cor da arma em ciclo arco-íris",
    ["rainbowspeed.name"]="Velocidade do Arco-Íris", ["rainbowspeed.desc"]="Delay entre trocas de cor",
    ["ghostgun.name"]="Arma Fantasma", ["ghostgun.desc"]="Deixa a arma semi-transparente",
    ["ghosttrans.name"]="Transparência Fantasma", ["ghosttrans.desc"]="0 = invisível, 1 = opaca",

    ["speed.name"]="Velocidade", ["speed.desc"]="Velocidade personalizada",
    ["speedvalue.name"]="Valor da Velocidade", ["speedvalue.desc"]="Valor do WalkSpeed",
    ["fly.name"]="Voar", ["fly.desc"]="Voo livre (WASD + Espaço/Ctrl)",
    ["flyspeed.name"]="Velocidade de Voo", ["flyspeed.desc"]="Velocidade de voo",
    ["airjump.name"]="Pulo Infinito", ["airjump.desc"]="Pula no ar infinitamente",
    ["jumppower.name"]="Força do Pulo", ["jumppower.desc"]="Velocidade do pulo",
    ["noclip.name"]="Noclip", ["noclip.desc"]="Atravessa paredes",
    ["fullbright.name"]="Fullbright", ["fullbright.desc"]="Mapa sempre claro",
    ["antiafk.name"]="Anti-AFK", ["antiafk.desc"]="Não é kickado por inatividade",
    ["camerafov.name"]="FOV da Câmera", ["camerafov.desc"]="Campo de visão",

    ["esp.name"]="ESP de Jogador", ["esp.desc"]="Destaca inimigos através das paredes",
    ["espdist.name"]="Distância Máxima", ["espdist.desc"]="Alcance do ESP",
    ["espweapon.name"]="ESP de Arma", ["espweapon.desc"]="Mostra armas dos inimigos",
    ["esptracer.name"]="ESP de Tracer", ["esptracer.desc"]="Linhas até os alvos",
    ["damageindicator.name"]="Indicador de Dano", ["damageindicator.desc"]="Seta vermelha ao levar dano",
    ["lowgfx.name"]="Gráficos Baixos", ["lowgfx.desc"]="Reduz qualidade gráfica pra FPS",
    ["noshadow.name"]="Sem Sombras", ["noshadow.desc"]="Remove todas as sombras",
    ["nofog.name"]="Sem Névoa", ["nofog.desc"]="Remove névoa e atmosfera",
    ["nopart.name"]="Sem Partículas", ["nopart.desc"]="Remove efeitos de partículas",
    ["antiflash.name"]="Anti-Flash", ["antiflash.desc"]="Bloqueia flashbang",

    ["config.placeholder"]="Nome do config + Enter pra salvar...", ["config.refresh"]="🔄 Atualizar Lista",
    ["config.disable_autoload"]="🚫 Desativar Autoload", ["config.fps_boost"]="⚡ Boost Máximo de FPS",
    ["config.reset_opt"]="🔄 Resetar Otimizações", ["config.unload"]="Descarregar Script",
    ["config.empty"]="Nenhum config salvo ainda.",

    ["lang.current"]="🌐 Atual: ", ["lang.hint"]="Escolha o idioma do hub",
    ["lang.saved_to"]="Idioma salvo em:", ["lang.auto_restore"]="É restaurado ao abrir o hub.",

    ["credits.copy_discord"]="📋 Copiar Link do Discord", ["credits.role"]="Sr Red",

    ["mm2.show.murderer"]="Mostrar Assassino", ["mm2.show.sheriff"]="Mostrar Xerife", ["mm2.show.innocent"]="Mostrar Inocente",
    ["mm2.murderer.alert"]="Alerta do Assassino", ["mm2.murderer.alert.desc"]="Avisa quando o assassino está perto",
    ["mm2.murderer.alert.range"]="Alcance do Alerta",
    ["mm2.gunlocator.name"]="Localizador de Arma", ["mm2.gunlocator.desc"]="Rastreia a arma do Xerife caída",
    ["mm2.autocoin.name"]="Farm Automático de Moedas", ["mm2.autocoin.desc"]="Voa entre moedas", ["mm2.autocoin.speed"]="Velocidade de Voo",
    ["mm2.autograb.name"]="Pegar Arma Auto", ["mm2.autograb.desc"]="Pega arma caída do Xerife", ["mm2.autograb.range"]="Alcance de Pegar",
    ["mm2.role.murderer"]="Assassino", ["mm2.role.sheriff"]="Xerife", ["mm2.role.innocent"]="Inocente",

    ["jb.esp.armor"]="ESP de Armadura", ["jb.esp.armor.desc"]="Mostra valor de armadura do inimigo",
    ["jb.esp.grenades"]="ESP de Granada", ["jb.esp.grenades.desc"]="Mostra granadas próximas",

    ["bs.esp.weapon"]="ESP de Arma", ["bs.esp.armor"]="ESP de Armadura",
}

local function ensureLanguageRegistered(code)
    for _, info in ipairs(Language.languages) do
        if info.code == code then return end
    end
    local tbl = Language.translations[code]
    table.insert(Language.languages, {
        code = code,
        flag = (tbl and tbl.flag) or "🌐",
        displayName = (tbl and tbl.displayName) or code,
    })
end

local EXTRA_FILE = "InfiniteZen_Translations.json"
local JSON_URL = "https://raw.githubusercontent.com/qualquerumapessoa913-ops/InfiniteZen/Moon-Angel/InfiniteZen_Translations.json"

local function tryReadLocal()
    if not readfile then return nil end
    local paths = { EXTRA_FILE, "workspace/" .. EXTRA_FILE, "InfiniteZen/" .. EXTRA_FILE, "/" .. EXTRA_FILE }
    for _, path in ipairs(paths) do
        local ok, raw = pcall(readfile, path)
        if ok and raw and raw ~= "" then
            print("[IZ Lang] ✅ JSON lido de: " .. path)
            return raw
        end
    end
    return nil
end

local function tryDownload()
    if type(game.HttpGet) ~= "function" then return nil end
    local ok, raw = pcall(function() return game:HttpGet(JSON_URL, true) end)
    if ok and raw and raw ~= "" and #raw > 100 and not raw:find("^404") and not raw:find("^Not Found") then
        print("[IZ Lang] ✅ JSON baixado do GitHub (" .. #raw .. " bytes)")
        if writefile then pcall(writefile, EXTRA_FILE, raw) end
        return raw
    end
    return nil
end

local REMOVED_KEYS = {
    ["silent.name"] = true, ["silent.desc"] = true,
    ["silentfov.name"] = true, ["silentfov.desc"] = true,
    ["triggerbot.name"] = true, ["triggerbot.desc"] = true,
    ["triggerbotdelay.name"] = true, ["triggerbotdelay.desc"] = true,
    ["autoshot.name"] = true, ["autoshot.desc"] = true,
    ["autoshotfov.name"] = true, ["autoshotfov.desc"] = true,
    ["infiniteammo.name"] = true, ["infiniteammo.desc"] = true,
    ["autobhop.name"] = true, ["autobhop.desc"] = true,
    ["antivotekick.name"] = true, ["antivotekick.desc"] = true,
}

local function loadExtraTranslations()
    local raw = tryReadLocal() or tryDownload()

    if not raw then
        warn("[IZ Lang] ⚠️ Não consegui obter o JSON — usando hardcoded")
        return
    end

    local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok2 or type(data) ~= "table" then
        warn("[IZ Lang] ❌ JSON corrompido ou inválido: " .. tostring(data))
        return
    end

    local META = { flag = true, displayName = true, shortCode = true }

    local count, newLangs = 0, 0
    for code, tbl in pairs(data) do
        if type(code) == "string" and type(tbl) == "table" then
            if not Language.translations[code] then
                Language.translations[code] = {}
                newLangs = newLangs + 1
            end

            for k, v in pairs(tbl) do
                if type(k) == "string" and (type(v) == "string" or type(v) == "number") then
                    if REMOVED_KEYS[k] then
                    elseif META[k] and Language.translations[code][k] then
                    else
                        Language.translations[code][k] = v
                    end
                end
            end
            count = count + 1
            ensureLanguageRegistered(code)
        end
    end
    print("[IZ Lang] ✅ " .. count .. " idiomas carregados do JSON (" .. newLangs .. " novos)")
end

local okLoad, errLoad = pcall(loadExtraTranslations)
if not okLoad then
    warn("[IZ Lang] ❌ loadExtraTranslations falhou: " .. tostring(errLoad))
end

local LANG_FILE = "InfiniteZen_Language.txt"
pcall(function()
    if not readfile then return end
    local ok, content = pcall(readfile, LANG_FILE)
    if ok and content and content ~= "" then
        local code = content:gsub("%s+", "")
        if Language.translations[code] then
            Language.current = code
            print("[IZ Lang] Idioma restaurado: " .. code)
        end
    end
end)

function Language.get(key)
    if type(key) ~= "string" then return key end
    local t = Language.translations[Language.current]
    if t and t[key] then return t[key] end
    local fb = Language.translations["en"]
    if fb and fb[key] then return fb[key] end
    return key
end

function Language.setLanguage(code)
    if not code or type(code) ~= "string" then return false end
    if not Language.translations[code] then return false end
    Language.current = code
    if writefile then pcall(writefile, LANG_FILE, code) end
    if _G.IZ_RefreshLanguage then pcall(_G.IZ_RefreshLanguage, code) end
    for _, callback in ipairs(Language.listeners) do
        pcall(function()
            if type(callback) == "function" then callback(code) end
        end)
    end
    return true
end

function Language.getCurrent() return Language.current end
function Language.getCurrentData() return Language.translations[Language.current] end
function Language.getFlag()
    local data = Language.translations[Language.current]
    return (data and data.flag) or "🌐"
end

function Language.getAvailable()
    local list = {}
    local seen = {}

    for _, info in ipairs(Language.languages) do
        table.insert(list, {
            code = info.code,
            flag = info.flag,
            displayName = info.displayName,
            shortCode = info.code:upper(),
        })
        seen[info.code] = true
    end

    for code, tbl in pairs(Language.translations) do
        if not seen[code] and type(tbl) == "table" then
            table.insert(list, {
                code = code,
                flag = tbl.flag or "🌐",
                displayName = tbl.displayName or code,
                shortCode = code:upper(),
            })
        end
    end

    return list
end

function Language.onChange(callback)
    if type(callback) ~= "function" then return function() end end
    table.insert(Language.listeners, callback)
    return function()
        for i, cb in ipairs(Language.listeners) do
            if cb == callback then
                table.remove(Language.listeners, i)
                break
            end
        end
    end
end

return Language