-- ============================================================
-- INFINITE ZEN - SISTEMA DE IDIOMAS (EXPANDIDO)
-- ============================================================

local Language = {}

Language.current = "pt-br"
Language.listeners = {}

Language.translations = {
    ["pt-br"] = {
        flag = "BR",
        displayName = "Portugues (BR)",
        shortCode = "BR",

        -- Header
        hub_name = "INFINITE ZEN",
        hub_subtitle = "Arsenal Edition",
        language_label = "Idioma",

        -- Tabs
        tab_combat = "Combat",
        tab_weapon = "Armas",
        tab_movement = "Movimento",
        tab_visuals = "Visual",
        tab_settings = "Config",

        -- Combat
        silent_headshot = "Silent Headshot",
        silent_fov = "FOV do Silent",
        aimbot = "Aimbot (Legit)",
        head_expander = "Head Expander",
        head_size = "Tamanho da Cabeca",
        backstab = "Backstab",

        -- Weapon
        no_recoil = "Sem Recuo",
        rapid_fire = "Tiro Rapido",
        fast_reload = "Recarga Rapida",
        insta_reload = "Recarga Instantanea",
        auto_shoot = "Tiro Automatico",
        auto_shoot_fov = "FOV do Tiro Auto",

        -- Movement
        speed = "Velocidade",
        air_jump = "Pulo no Ar",

        -- Visuals
        esp = "ESP (Tudo)",
        max_distance = "Distancia Maxima",

        -- Settings
        interface_label = "Interface",
        save_config = "Salvar Config",
        load_config = "Carregar Config",
        info_label = "Info",
        key_minimize = "K = Minimizar UI",
        keybind_help1 = "Cada feature tem sua propria keybind",
        keybind_help2 = "Clique no botao de keybind pra gravar",
        unload_script = "Descarregar Script",
        version_text = "Infinite Zen v1.0",

        -- Toggle states
        on = "ON",
        off = "OFF",
        key = "tecla",

        -- Notifications
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

        silent_headshot = "Silent Headshot",
        silent_fov = "Silent FOV",
        aimbot = "Aimbot (Legit)",
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
        air_jump = "Air Jump",

        esp = "ESP (All)",
        max_distance = "Max Distance",

        interface_label = "Interface",
        save_config = "Save Config",
        load_config = "Load Config",
        info_label = "Info",
        key_minimize = "K = Minimize UI",
        keybind_help1 = "Each feature has its own keybind",
        keybind_help2 = "Click the keybind button to record",
        unload_script = "Unload Script",
        version_text = "Infinite Zen v1.0",

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

        silent_headshot = "Headshot Silencioso",
        silent_fov = "FOV Silencioso",
        aimbot = "Aimbot (Legit)",
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
        air_jump = "Salto en el Aire",

        esp = "ESP (Todo)",
        max_distance = "Distancia Maxima",

        interface_label = "Interfaz",
        save_config = "Guardar Config",
        load_config = "Cargar Config",
        info_label = "Info",
        key_minimize = "K = Minimizar UI",
        keybind_help1 = "Cada funcion tiene su propia tecla",
        keybind_help2 = "Haz clic en el boton de tecla para grabar",
        unload_script = "Descargar Script",
        version_text = "Infinite Zen v1.0",

        on = "ON",
        off = "OFF",
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
    },
}

function Language.get(key)
    local t = Language.translations[Language.current]
    if t and t[key] then return t[key] end
    local fb = Language.translations["pt-br"]
    if fb and fb[key] then return fb[key] end
    return key
end

function Language.setLanguage(code)
    if not Language.translations[code] then return false end
    Language.current = code
    for _, callback in ipairs(Language.listeners) do
        task.spawn(callback)
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