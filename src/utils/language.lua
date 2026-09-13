-- ============================================================
-- INFINITE ZEN - SISTEMA DE IDIOMAS
-- ============================================================

local Language = {}

Language.current = "en"
Language.listeners = {}

Language.translations = {
    ["pt-br"] = {
        flag = "BR",
        displayName = "Portugues (BR)",
        shortCode = "BR",

        hub_name = "INFINITE ZEN",
        hub_subtitle = "Arsenal Edition",
        language_label = "Idioma",

        tab_combat = "Combat",
        tab_weapon = "Armas",
        tab_movement = "Movimento",
        tab_visuals = "Visual",
        tab_settings = "Config",
        tab_credits = "Creditos",

        silent_headshot = "Silent Headshot",
        silent_fov = "FOV do Silent",
        aimbot = "Aimbot (Legit)",
        aimbot_fov = "FOV do Aimbot",
        aimbot_smooth = "Suavidade do Aimbot",
        head_expander = "Head Expander",
        head_size = "Tamanho da Cabeca",
        backstab = "Backstab",

        no_recoil = "Sem Recuo",
        rapid_fire = "Tiro Rapido",
        fast_reload = "Recarga Rapida",
        insta_reload = "Recarga Instantanea",
        auto_shoot = "Tiro Automatico",
        auto_shoot_fov = "FOV do Tiro Auto",

        speed = "Velocidade",
        speed_value = "Valor da Velocidade",
        air_jump = "Pulo no Ar",
        fullbright = "Fullbright",

        esp = "ESP (Tudo)",
        max_distance = "Distancia Maxima",

        low_graphics = "Graficos Baixos",
        no_shadows = "Sem Sombras",
        no_fog = "Sem Nevoeiro",
        no_particles = "Sem Particulas",

        interface_label = "Interface",
        save_config = "Salvar Config",
        load_config = "Carregar Config",
        info_label = "Info",
        key_minimize = "K = Minimizar UI",
        keybind_help1 = "Cada feature tem sua propria keybind",
        keybind_help2 = "Clique no botao de keybind pra gravar",
        unload_script = "Descarregar Script",
        version_text = "Infinite Zen v1.3",

        on = "Ligado",
        off = "Desligado",
        key = "tecla",

        config_saved = "Configuracoes salvas com sucesso",
        config_loaded = "Configuracoes carregadas",
        config_error_save = "Executor nao suporta writefile",
        config_error_load = "Nenhum config salvo",
        config_error_corrupt = "Arquivo corrompido",
        keybind_locked = "Keybind Bloqueada",
        keybind_locked_desc = "K ja esta reservada para Minimize UI",
        keybind_inuse = "Keybind em Uso",
        keybind_inuse_desc = " ja esta sendo usada por: ",
        backstab_target = "Backstab em: ",
        no_enemy = "Nenhum inimigo encontrado",
        config_title = "Config",
        error_title = "Erro",
        load_title = "Carregar",
        unsupported_title = "Jogo Nao Suportado",
        unsupported_message_pt = "Este jogo nao e suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },

    ["en"] = {
        flag = "US",
        displayName = "English (US)",
        shortCode = "US",

        hub_name = "INFINITE ZEN",
        hub_subtitle = "Arsenal Edition",
        language_label = "Language",

        tab_combat = "Combat",
        tab_weapon = "Weapon",
        tab_movement = "Movement",
        tab_visuals = "Visuals",
        tab_settings = "Settings",
        tab_credits = "Credits",

        silent_headshot = "Silent Headshot",
        silent_fov = "Silent FOV",
        aimbot = "Aimbot (Legit)",
        aimbot_fov = "Aimbot FOV",
        aimbot_smooth = "Aimbot Smoothness",
        head_expander = "Head Expander",
        head_size = "Head Size",
        backstab = "Backstab",

        no_recoil = "No-Recoil",
        rapid_fire = "Rapid Fire",
        fast_reload = "Fast Reload",
        insta_reload = "Insta-Reload",
        auto_shoot = "Auto Shoot",
        auto_shoot_fov = "Auto Shoot FOV",

        speed = "Speed",
        speed_value = "Speed Value",
        air_jump = "Air Jump",
        fullbright = "Fullbright",

        esp = "ESP (All)",
        max_distance = "Max Distance",

        low_graphics = "Low Graphics",
        no_shadows = "No Shadows",
        no_fog = "No Fog",
        no_particles = "No Particles",

        interface_label = "Interface",
        save_config = "Save Config",
        load_config = "Load Config",
        info_label = "Info",
        key_minimize = "K = Minimize UI",
        keybind_help1 = "Each feature has its own keybind",
        keybind_help2 = "Click the keybind button to record",
        unload_script = "Unload Script",
        version_text = "Infinite Zen v1.3",

        on = "ON",
        off = "OFF",
        key = "key",

        config_saved = "Config saved successfully",
        config_loaded = "Config loaded",
        config_error_save = "Executor doesn't support writefile",
        config_error_load = "No config saved",
        config_error_corrupt = "Corrupted file",
        keybind_locked = "Keybind Blocked",
        keybind_locked_desc = "K is reserved for Minimize UI",
        keybind_inuse = "Keybind in Use",
        keybind_inuse_desc = " is already being used by: ",
        backstab_target = "Backstab at: ",
        no_enemy = "No enemy found",
        config_title = "Config",
        error_title = "Error",
        load_title = "Load",
        unsupported_title = "Unsupported Game",
        unsupported_message_pt = "Este jogo nao e suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },

    ["es"] = {
        flag = "ES",
        displayName = "Espanol (ES)",
        shortCode = "ES",

        hub_name = "INFINITE ZEN",
        hub_subtitle = "Arsenal Edition",
        language_label = "Idioma",

        tab_combat = "Combate",
        tab_weapon = "Armas",
        tab_movement = "Movimiento",
        tab_visuals = "Visuales",
        tab_settings = "Ajustes",
        tab_credits = "Creditos",

        silent_headshot = "Headshot Silencioso",
        silent_fov = "FOV Silencioso",
        aimbot = "Aimbot (Legit)",
        aimbot_fov = "FOV del Aimbot",
        aimbot_smooth = "Suavidad del Aimbot",
        head_expander = "Expansor de Cabeza",
        head_size = "Tamano de Cabeza",
        backstab = "Apunalar por Detras",

        no_recoil = "Sin Retroceso",
        rapid_fire = "Disparo Rapido",
        fast_reload = "Recarga Rapida",
        insta_reload = "Recarga Instantanea",
        auto_shoot = "Disparo Automatico",
        auto_shoot_fov = "FOV del Disparo Auto",

        speed = "Velocidad",
        speed_value = "Valor de Velocidad",
        air_jump = "Salto en el Aire",
        fullbright = "Fullbright",

        esp = "ESP (Todo)",
        max_distance = "Distancia Maxima",

        low_graphics = "Graficos Bajos",
        no_shadows = "Sin Sombras",
        no_fog = "Sin Niebla",
        no_particles = "Sin Particulas",

        interface_label = "Interfaz",
        save_config = "Guardar Config",
        load_config = "Cargar Config",
        info_label = "Info",
        key_minimize = "K = Minimizar UI",
        keybind_help1 = "Cada funcion tiene su propia tecla",
        keybind_help2 = "Haz clic en el boton de tecla para grabar",
        unload_script = "Descargar Script",
        version_text = "Infinite Zen v1.3",

        on = "Encendido",
        off = "Apagado",
        key = "tecla",

        config_saved = "Configuracion guardada",
        config_loaded = "Configuracion cargada",
        config_error_save = "El ejecutor no soporta writefile",
        config_error_load = "No hay config guardada",
        config_error_corrupt = "Archivo corrupto",
        keybind_locked = "Tecla Bloqueada",
        keybind_locked_desc = "K esta reservada para Minimizar UI",
        keybind_inuse = "Tecla en Uso",
        keybind_inuse_desc = " ya esta siendo usada por: ",
        backstab_target = "Backstab en: ",
        no_enemy = "Ningun enemigo encontrado",
        config_title = "Config",
        error_title = "Error",
        load_title = "Cargar",
        unsupported_title = "Juego No Soportado",
        unsupported_message_pt = "Este jogo nao e suportado pelo Infinite Zen.",
        unsupported_message_en = "This game is not supported by Infinite Zen.",
    },
}

function Language.get(key)
    local t = Language.translations[Language.current]
    if t and t[key] then return t[key] end
    local fb = Language.translations["en"]
    if fb and fb[key] then return fb[key] end
    return key
end

-- ============================================================
-- FUNÇÃO DE REFRESH GLOBAL (FORÇA ATUALIZAÇÃO DE TODA UI)
-- ============================================================
function Language.setLanguage(code)
    if not Language.translations[code] then
        print("[LANG] Codigo nao encontrado: " .. tostring(code))
        return false
    end
    Language.current = code
    print("[LANG] Idioma alterado para: " .. code)

    -- 1) Chama a função global (se existir)
    if _G.IZ_RefreshLanguage then
        pcall(_G.IZ_RefreshLanguage)
    end

    -- 2) Chama todos os listeners registrados
    for _, callback in ipairs(Language.listeners) do
        pcall(callback)
    end

    return true
end

function Language.getCurrent()
    return Language.current
end

function Language.getCurrentData()
    return Language.translations[Language.current]
end

function Language.getAvailable()
    local list = {}
    for code, data in pairs(Language.translations) do
        table.insert(list, {
            code = code,
            flag = data.flag,
            displayName = data.displayName,
            shortCode = data.shortCode,
        })
    end
    table.sort(list, function(a, b) return a.code < b.code end)
    return list
end

function Language.onChange(callback)
    table.insert(Language.listeners, callback)
end

return Language