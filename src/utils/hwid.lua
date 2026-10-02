-- ============================================================
-- Infinite Zen - hwid.lua - v1.0
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local LP          = Players.LocalPlayer

local HWID = {}

HWID.CONFIG = {
    HWID_FILE        = "HWID.json",
    BLACKLIST_FILE   = "IZM_Blacklist.json",
    LOG_FILE         = "IZM_HWID_Log.txt",
    WEBHOOK_URL      = "",
    BLACKLIST_BY = {
        hwid        = true,
        ip          = true,
        country     = false,
        city        = false,
        userId      = true,
        fingerprint = true,
    },
    DETECT_MULTI_ACCOUNT  = true,
    MAX_ACCOUNTS_PER_HWID = 2,
    IP_APIS = {
        "http://ip-api.com/json/?fields=status,country,countryCode,regionName,city,zip,isp,org,as,query",
        "https://ipwho.is/",
        "https://api.ipify.org?format=json",
    },
}

function HWID.getHWID()
    if gethwid then
        local ok, id = pcall(gethwid)
        if ok and id and id ~= "" then return tostring(id) end
    end

    if syn and syn.get_hwid then
        local ok, id = pcall(syn.get_hwid)
        if ok and id then return tostring(id) end
    end

    if getgenv and getgenv().HWID then
        return tostring(getgenv().HWID)
    end

    return "fb_" .. tostring(LP.UserId) .. "_" .. tostring(game.PlaceId) .. "_" .. tostring(game.GameId)
end

local function httpGet(url)
    local ok, result = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok then return nil end
    return result
end

local function parseJSON(raw)
    if not raw or raw == "" then return nil end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

function HWID.getIPInfo()
    for i, url in ipairs(HWID.CONFIG.IP_APIS) do
        local raw = httpGet(url)
        local data = parseJSON(raw)

        if data then
            if data.status == "success" and data.query then
                return {
                    ip = data.query,
                    country = data.country or "unknown",
                    countryCode = data.countryCode or "??",
                    region = data.regionName or "unknown",
                    city = data.city or "unknown",
                    isp = data.isp or "unknown",
                    org = data.org or "unknown",
                    source = "ip-api.com",
                }
            end

            if data.ip then
                return {
                    ip = data.ip,
                    country = data.country or "unknown",
                    countryCode = data.country_code or "??",
                    region = data.region or "unknown",
                    city = data.city or "unknown",
                    isp = (data.connection and data.connection.isp) or "unknown",
                    org = (data.connection and data.connection.org) or "unknown",
                    source = "ipwho.is",
                }
            end

            if data.ip then
                return {
                    ip = data.ip,
                    country = "unknown",
                    countryCode = "??",
                    region = "unknown",
                    city = "unknown",
                    isp = "unknown",
                    org = "unknown",
                    source = "ipify",
                }
            end
        end
    end

    return nil
end

function HWID.loadJSON(path, default)
    if not readfile then return default end
    local exists = isfile and isfile(path)
    if not exists then return default end
    local ok, raw = pcall(readfile, path)
    if not ok or not raw or raw == "" then return default end
    local data = parseJSON(raw)
    if type(data) ~= "table" then return default end
    return data
end

function HWID.saveJSON(path, data)
    if not writefile then return false end
    local ok = pcall(function()
        writefile(path, HttpService:JSONEncode(data))
    end)
    return ok
end

function HWID.appendLog(line)
    if not appendfile then return end
    local ts = os.date and os.date("[%Y-%m-%d %H:%M:%S]") or "[" .. tostring(os.time()) .. "]"
    pcall(function()
        appendfile(HWID.CONFIG.LOG_FILE, ts .. " " .. line .. "\n")
    end)
end

local function simpleHash(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

function HWID.getFingerprint(hwid, ipInfo, userId)
    local parts = {
        tostring(hwid or "no_hwid"),
        tostring(ipInfo and ipInfo.countryCode or "xx"),
        tostring(ipInfo and ipInfo.city or "unknown"),
        tostring(userId or LP.UserId),
    }
    return simpleHash(table.concat(parts, "|"))
end

local DEFAULT_BLACKLIST = {
    hwids = {}, ips = {}, countries = {}, cities = {},
    userIds = {}, fingerprints = {}, reasons = {},
    blocked_users = {},
}

function HWID.isBlacklisted(hwid, ipInfo, fingerprint)
    local bl = HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)

    local crit = HWID.CONFIG.BLACKLIST_BY
    local userId = tostring(LP.UserId)

    if crit.hwid and hwid and bl.hwids and bl.hwids[hwid] then
        return true, "hwid", bl.reasons and bl.reasons[hwid]
    end
    if crit.ip and ipInfo and ipInfo.ip and bl.ips and bl.ips[ipInfo.ip] then
        return true, "ip", bl.reasons and bl.reasons[ipInfo.ip]
    end
    if crit.country and ipInfo and ipInfo.country and bl.countries and bl.countries[ipInfo.country] then
        return true, "country", bl.reasons and bl.reasons[ipInfo.country]
    end
    if crit.city and ipInfo and ipInfo.city and bl.cities and bl.cities[ipInfo.city] then
        return true, "city", bl.reasons and bl.reasons[ipInfo.city]
    end
    if crit.userId and bl.userIds and bl.userIds[userId] then
        return true, "userId", bl.reasons and bl.reasons[userId]
    end
    if crit.fingerprint and fingerprint and bl.fingerprints and bl.fingerprints[fingerprint] then
        return true, "fingerprint", bl.reasons and bl.reasons[fingerprint]
    end

    return false, nil, nil
end

function HWID.recordBlockedAttempt(hwid, ipInfo, fingerprint, criteria, reason)
    local bl = HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)
    bl.blocked_users = bl.blocked_users or {}

    local userId = tostring(LP.UserId)
    local now = os.time and os.time() or tick()

    if not bl.blocked_users[userId] then
        bl.blocked_users[userId] = {
            userId = LP.UserId,
            username = LP.Name,
            displayName = LP.DisplayName,
            accountAge = LP.AccountAge,
            first_attempt = now,
            last_attempt = now,
            attempts = 1,
            blocked_by = criteria,
            block_reason = reason or "unknown",
            hwids = hwid and { [hwid] = now } or {},
            ips = (ipInfo and ipInfo.ip) and { [ipInfo.ip] = now } or {},
            fingerprints = fingerprint and { [fingerprint] = now } or {},
            country = ipInfo and ipInfo.country,
            countryCode = ipInfo and ipInfo.countryCode,
            city = ipInfo and ipInfo.city,
            region = ipInfo and ipInfo.region,
            isp = ipInfo and ipInfo.isp,
        }
    else
        local entry = bl.blocked_users[userId]
        entry.attempts = (entry.attempts or 0) + 1
        entry.last_attempt = now
        entry.last_username = LP.Name
        entry.last_displayName = LP.DisplayName

        if hwid then
            entry.hwids = entry.hwids or {}
            entry.hwids[hwid] = now
        end
        if ipInfo and ipInfo.ip then
            entry.ips = entry.ips or {}
            entry.ips[ipInfo.ip] = now
            entry.country = ipInfo.country
            entry.countryCode = ipInfo.countryCode
            entry.city = ipInfo.city
            entry.region = ipInfo.region
            entry.isp = ipInfo.isp
        end
        if fingerprint then
            entry.fingerprints = entry.fingerprints or {}
            entry.fingerprints[fingerprint] = now
        end
    end

    HWID.saveJSON(HWID.CONFIG.BLACKLIST_FILE, bl)
    return bl.blocked_users[userId]
end

function HWID.registerExecution(hwid, ipInfo, fingerprint)
    local db = HWID.loadJSON(HWID.CONFIG.HWID_FILE, {
        users = {},
        hwid_index = {},
        ip_index = {},
        stats = { total_executions = 0, unique_users = 0, unique_hwids = 0, unique_ips = 0 },
        created_at = os.time and os.time() or tick(),
    })

    db.users = db.users or {}
    db.hwid_index = db.hwid_index or {}
    db.ip_index = db.ip_index or {}
    db.stats = db.stats or { total_executions = 0, unique_users = 0, unique_hwids = 0, unique_ips = 0 }

    local userId = tostring(LP.UserId)
    local now = os.time and os.time() or tick()

    if not db.users[userId] then
        db.users[userId] = {
            userId = LP.UserId,
            username = LP.Name,
            displayName = LP.DisplayName,
            accountAge = LP.AccountAge,
            first_seen = now,
            executions = 0,
            hwids = {},
            ips = {},
            countries = {},
            cities = {},
            fingerprints = {},
            suspicious = false,
            suspicion_reasons = {},
        }
        db.stats.unique_users = db.stats.unique_users + 1
    end

    local user = db.users[userId]
    user.last_seen = now
    user.username = LP.Name
    user.displayName = LP.DisplayName
    user.executions = (user.executions or 0) + 1
    user.last_hwid = hwid
    user.last_fingerprint = fingerprint

    db.stats.total_executions = db.stats.total_executions + 1

    if hwid then
        if not user.hwids[hwid] then
            user.hwids[hwid] = { first_seen = now, count = 0 }
        end
        user.hwids[hwid].last_seen = now
        user.hwids[hwid].count = user.hwids[hwid].count + 1

        if not db.hwid_index[hwid] then
            db.hwid_index[hwid] = { userIds = {}, first_seen = now, count = 0 }
            db.stats.unique_hwids = db.stats.unique_hwids + 1
        end
        db.hwid_index[hwid].last_seen = now
        db.hwid_index[hwid].count = db.hwid_index[hwid].count + 1
        db.hwid_index[hwid].userIds[userId] = true
    end

    if ipInfo and ipInfo.ip then
        if not user.ips[ipInfo.ip] then
            user.ips[ipInfo.ip] = { first_seen = now, count = 0 }
        end
        user.ips[ipInfo.ip].last_seen = now
        user.ips[ipInfo.ip].count = user.ips[ipInfo.ip].count + 1

        user.last_ip = ipInfo.ip
        user.last_country = ipInfo.country
        user.last_countryCode = ipInfo.countryCode
        user.last_city = ipInfo.city
        user.last_region = ipInfo.region
        user.last_isp = ipInfo.isp

        user.countries[ipInfo.country] = (user.countries[ipInfo.country] or 0) + 1
        user.cities[ipInfo.city] = (user.cities[ipInfo.city] or 0) + 1

        if not db.ip_index[ipInfo.ip] then
            db.ip_index[ipInfo.ip] = { userIds = {}, first_seen = now, count = 0 }
            db.stats.unique_ips = db.stats.unique_ips + 1
        end
        db.ip_index[ipInfo.ip].last_seen = now
        db.ip_index[ipInfo.ip].count = db.ip_index[ipInfo.ip].count + 1
        db.ip_index[ipInfo.ip].userIds[userId] = true
    end

    if fingerprint then
        if not user.fingerprints[fingerprint] then
            user.fingerprints[fingerprint] = { first_seen = now, count = 0 }
        end
        user.fingerprints[fingerprint].last_seen = now
        user.fingerprints[fingerprint].count = user.fingerprints[fingerprint].count + 1
    end

    if HWID.CONFIG.DETECT_MULTI_ACCOUNT and hwid and db.hwid_index[hwid] then
        local accountCount = 0
        for _ in pairs(db.hwid_index[hwid].userIds) do accountCount = accountCount + 1 end
        if accountCount > HWID.CONFIG.MAX_ACCOUNTS_PER_HWID then
            user.suspicious = true
            local reason = "multi_account: " .. accountCount .. " accounts on same HWID"
            if not user.suspicion_reasons[reason] then
                user.suspicion_reasons[reason] = now
                HWID.appendLog("[SUSPICIOUS] " .. LP.Name .. " (" .. userId .. ") - " .. reason)
            end
        end
    end

    HWID.saveJSON(HWID.CONFIG.HWID_FILE, db)
    return db, user
end

function HWID.sendWebhook(title, description, color)
    local url = HWID.CONFIG.WEBHOOK_URL
    if not url or url == "" then return end

    local payload = {
        embeds = {{
            title = title,
            description = description,
            color = color or 0xE62828,
            footer = { text = "IZM" },
            timestamp = os.date and os.date("!%Y-%m-%dT%H:%M:%SZ") or nil,
        }}
    }

    local body = HttpService:JSONEncode(payload)
    pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
end

function HWID.check()
    local hwid = HWID.getHWID()
    local ipInfo = HWID.getIPInfo()
    local fingerprint = HWID.getFingerprint(hwid, ipInfo, LP.UserId)

    local blacklisted, crit, reason = HWID.isBlacklisted(hwid, ipInfo, fingerprint)
    if blacklisted then
        HWID.recordBlockedAttempt(hwid, ipInfo, fingerprint, crit, reason)

        HWID.appendLog("[BLOCKED] " .. LP.Name .. " (" .. LP.UserId .. ") - " .. tostring(crit) .. " - " .. tostring(reason or "no reason"))
        HWID.sendWebhook(
            "User Blocked",
            "**User:** " .. LP.Name .. " (`" .. LP.UserId .. "`)\n" ..
            "**Criteria:** `" .. tostring(crit) .. "`\n" ..
            "**Reason:** " .. tostring(reason or "-") .. "\n" ..
            "**HWID:** `" .. tostring(hwid) .. "`\n" ..
            "**IP:** `" .. tostring(ipInfo and ipInfo.ip or "?") .. "`\n" ..
            "**Location:** " .. tostring(ipInfo and (ipInfo.city .. ", " .. ipInfo.country) or "?"),
            0xE62828
        )
        return false, "BLACKLISTED:" .. tostring(crit), { hwid = hwid, ip = ipInfo, fingerprint = fingerprint }
    end

    local db, user = HWID.registerExecution(hwid, ipInfo, fingerprint)

    HWID.appendLog(
        "[EXEC] " .. LP.Name .. " (" .. LP.UserId .. ") | " ..
        "HWID=" .. tostring(hwid) .. " | " ..
        "IP=" .. tostring(ipInfo and ipInfo.ip or "?") .. " | " ..
        "Loc=" .. tostring(ipInfo and (ipInfo.city .. "/" .. ipInfo.country) or "?") .. " | " ..
        "FP=" .. tostring(fingerprint) .. " | " ..
        "Exec=" .. tostring(user.executions)
    )

    if user.suspicious then
        local reasons = {}
        for k in pairs(user.suspicion_reasons or {}) do table.insert(reasons, k) end

        HWID.sendWebhook(
            "Multi-Account Detected",
            "**User:** " .. LP.Name .. " (`" .. LP.UserId .. "`)\n" ..
            "**HWID:** `" .. tostring(hwid) .. "`\n" ..
            "**IP:** `" .. tostring(ipInfo and ipInfo.ip or "?") .. "`\n" ..
            "**Location:** " .. tostring(ipInfo and (ipInfo.city .. ", " .. ipInfo.country) or "?") .. "\n" ..
            "**Reasons:** " .. table.concat(reasons, ", "),
            0xFFAA00
        )
    end

    return true, nil, {
        hwid = hwid,
        ip = ipInfo,
        fingerprint = fingerprint,
        user = user,
        database = db,
    }
end

function HWID.addToBlacklist(criteria, value, reason)
    local bl = HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)
    bl.blocked_users = bl.blocked_users or {}

    criteria = criteria:lower()
    value = tostring(value)

    if criteria == "hwid" then bl.hwids[value] = true
    elseif criteria == "ip" then bl.ips[value] = true
    elseif criteria == "country" then bl.countries[value] = true
    elseif criteria == "city" then bl.cities[value] = true
    elseif criteria == "userid" then bl.userIds[value] = true
    elseif criteria == "fingerprint" then bl.fingerprints[value] = true
    else return false, "invalid criteria" end

    bl.reasons[value] = reason or "No reason given"
    HWID.saveJSON(HWID.CONFIG.BLACKLIST_FILE, bl)
    return true
end

function HWID.removeFromBlacklist(criteria, value)
    local bl = HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)
    criteria = criteria:lower()
    value = tostring(value)

    if bl[criteria .. "s"] then bl[criteria .. "s"][value] = nil end
    if bl.reasons then bl.reasons[value] = nil end
    if bl.blocked_users then bl.blocked_users[value] = nil end

    HWID.saveJSON(HWID.CONFIG.BLACKLIST_FILE, bl)
    return true
end

function HWID.getDatabase()
    return HWID.loadJSON(HWID.CONFIG.HWID_FILE, {})
end

function HWID.getBlacklist()
    return HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)
end

function HWID.getBlockedUsers()
    local bl = HWID.loadJSON(HWID.CONFIG.BLACKLIST_FILE, DEFAULT_BLACKLIST)
    return bl.blocked_users or {}
end

return HWID