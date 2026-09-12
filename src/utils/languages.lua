-- ============================================================
-- INFINITE ZEN - SISTEMA DE IDIOMAS
-- ============================================================

local Language = {}
local currentLang = "en"

local translations = {
    ["pt-br"] = {
        unsupported_title = "Jogo Não Suportado",
        unsupported_message_pt = "Este jogo não é suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },
    ["en"] = {
        unsupported_title = "Unsupported Game",
        unsupported_message_pt = "Este jogo não é suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },
    ["es"] = {
        unsupported_title = "Juego No Soportado",
        unsupported_message_pt = "Este jogo não é suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },
}

function Language.setLanguage(lang)
    if translations[lang] then
        currentLang = lang
    else
        currentLang = "pt-br"
    end
end

function Language.get(key)
    local t = translations[currentLang]
    if t and t[key] then return t[key] end
    local f = translations["pt-br"]
    if f and f[key] then return f[key] end
    return key
end

return Language