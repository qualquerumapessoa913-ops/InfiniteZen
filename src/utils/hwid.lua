-- ============================================================
-- Infinite Zen - hwid.lua - v1.0
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalizationService = game:GetService("LocalizationService")
local LP = Players.LocalPlayer

local HWID = {}

HWID.CONFIG = {
    API_URL = "https://izm.injectcloud.space",
    VERSION = "2.1.0",
    IP_APIS = {
        "http://ip-api.com/json/?fields=status,country,countryCode,regionName,city,zip,isp,org,as,query",
        "https://ipwho.is/",
    },
}

-- ═══════════════════════════════════════════
-- HWID
-- ═══════════════════════════════════════════
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

-- ═══════════════════════════════════════════
-- SYSTEM INFO (trust signals)
-- ═══════════════════════════════════════════
function HWID.getTimezone()
    local ok, tz = pcall(function()
        return os.date("%z")
    end)
    if ok and tz and tz ~= "" then return tz end
    return nil
end

function HWID.getLanguage()
    local ok, lang = pcall(function()
        return LocalizationService.RobloxLocaleId
    end)
    if ok and lang and lang ~= "" then return lang end

    ok, lang = pcall(function()
        return LocalizationService.SystemLocaleId
    end)
    if ok and lang and lang ~= "" then return lang end

    return nil
end

-- ═══════════════════════════════════════════
-- HTTP HELPERS
-- ═══════════════════════════════════════════
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if not ok then return nil end
    return res
end

local function httpPost(url, body)
    local jsonBody = HttpService:JSONEncode(body)

    -- Try request() first (better executors)
    local ok, res = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonBody,
        })
    end)

    if ok and res then
        if type(res) == "table" then
            if res.Body then return res.Body end
            if res.body then return res.body end
        end
        return res
    end

    -- Fallback: syn.request
    if syn and syn.request then
        local ok2, res2 = pcall(function()
            return syn.request({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = jsonBody,
            })
        end)
        if ok2 and res2 then
            if res2.Body then return res2.Body end
            if res2.body then return res2.body end
            return res2
        end
    end

    -- Fallback: game:HttpPost
    local ok3, res3 = pcall(function()
        return game:HttpPost(url, jsonBody, "application/json")
    end)
    if ok3 then return res3 end

    return nil
end

local function parseJSON(raw)
    if not raw or raw == "" then return nil end
    if type(raw) == "table" then return raw end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return nil end
    return data
end

-- ═══════════════════════════════════════════
-- IP INFO
-- ═══════════════════════════════════════════
function HWID.getIPInfo()
    for _, url in ipairs(HWID.CONFIG.IP_APIS) do
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
                }
            end
        end
    end

    return nil
end

-- ═══════════════════════════════════════════
-- FINGERPRINT
-- ═══════════════════════════════════════════
local function simpleHash(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = bit32.bxor(hash, string.byte(str, i))
        hash = bit32.band(hash * 16777619, 0xFFFFFFFF)
    end
    return string.format("%08x", hash)
end

function HWID.getFingerprint(hwid, ipInfo, userId)
    return simpleHash(table.concat({
        tostring(hwid or "no_hwid"),
        tostring(ipInfo and ipInfo.countryCode or "xx"),
        tostring(ipInfo and ipInfo.city or "unknown"),
        tostring(userId or LP.UserId),
        tostring(HWID.getTimezone() or "no_tz"),
        tostring(HWID.getLanguage() or "no_lang"),
    }, "|"))
end

-- ═══════════════════════════════════════════
-- PAYLOAD
-- ═══════════════════════════════════════════
local function buildPayload()
    local hwid = HWID.getHWID()
    local ipInfo = HWID.getIPInfo()
    local fingerprint = HWID.getFingerprint(hwid, ipInfo, LP.UserId)

    return {
        hwid = hwid,
        fingerprint = fingerprint,
        userId = LP.UserId,
        username = LP.Name,
        displayName = LP.DisplayName,
        accountAge = LP.AccountAge,
        ip = ipInfo and ipInfo.ip,
        country = ipInfo and ipInfo.country,
        countryCode = ipInfo and ipInfo.countryCode,
        city = ipInfo and ipInfo.city,
        region = ipInfo and ipInfo.region,
        isp = ipInfo and ipInfo.isp,
        org = ipInfo and ipInfo.org,
        timezone = HWID.getTimezone(),
        language = HWID.getLanguage(),
        clientVersion = HWID.CONFIG.VERSION,
    }
end

-- ═══════════════════════════════════════════
-- CHECK (main entry)
-- ═══════════════════════════════════════════
function HWID.check()
    local payload = buildPayload()
    local url = HWID.CONFIG.API_URL .. "/hwid/check"
    local raw = httpPost(url, payload)

    if not raw then
        warn("[IZM] HWID check failed (network) — allowing")
        return true, nil, { payload = payload }
    end

    local data = parseJSON(raw)
    if not data then
        warn("[IZM] HWID check invalid response — allowing")
        return true, nil, { payload = payload }
    end

    if data.allowed == false then
        return false, "BLACKLISTED:" .. tostring(data.criteria or "unknown"), {
            reason = data.reason,
            criteria = data.criteria,
            payload = payload,
        }
    end

    return true, nil, {
        executions = data.executions,
        suspicious = data.suspicious,
        trust = data.trust,
        payload = payload,
    }
end

function HWID.register()
    local payload = buildPayload()
    local url = HWID.CONFIG.API_URL .. "/hwid/register"
    httpPost(url, payload)
end

return HWID