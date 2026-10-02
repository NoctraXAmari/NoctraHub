-- Noctra Hub | loader.lua
-- Entry point. Ito yung tinatawag ng loadstring.

local BASE = "https://raw.githubusercontent.com/NoctraXAmari/NoctraHub/main/"
local DISCORD = "https://discord.gg/Cfa5JdrWar"

-- =========================================================
-- KEY VALIDATION
-- =========================================================

-- Manual keys muna. Idagdag mo dito yung mga keys na ibibigay mo.
-- Format: ["KEY-CODE"] = true
local VALID_KEYS = {
    -- ["NOCTRA-TEST"] = true,
}

local function isValidKey(key)
    if key == nil or key == "" then return false end
    if VALID_KEYS[key] then return true end
    return false
end

-- =========================================================
-- CACHE SAVED KEY
-- =========================================================

local KEY_FILE = "noctra_key.txt"

local function loadSavedKey()
    if not (isfile and readfile) then return nil end
    local ok, data = pcall(function()
        if isfile(KEY_FILE) then
            return readfile(KEY_FILE)
        end
        return nil
    end)
    if ok and data and data ~= "" then return data end
    return nil
end

local function saveKey(key)
    if not (writefile) then return end
    pcall(writefile, KEY_FILE, key)
end

-- =========================================================
-- FETCH HELPER
-- =========================================================

local function fetch(path)
    local url = BASE .. path
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or not res then
        error("[Noctra] Failed to fetch: " .. path)
    end
    return res
end

-- =========================================================
-- BOOT
-- =========================================================

local function boot()
    -- Load core modules
    local themeSrc = fetch("core/theme.lua")
    local uiSrc = fetch("core/ui.lua")

    local themeChunk = loadstring(themeSrc)
    local uiChunk = loadstring(uiSrc)

    if not themeChunk or not uiChunk then
        error("[Noctra] Failed to compile core modules.")
    end

    -- Shared registry so modules can `require` by name
    local registry = {}
    local function fakeRequire(name)
        local key = name:match("([^/]+)%.lua$") or name
        if registry[key] then return registry[key] end
        error("[Noctra] Module not found: " .. name)
    end

    local Theme = themeChunk()
    registry["theme"] = Theme

    local UI = uiChunk()
    registry["ui"] = UI

    -- Key gate
    local function proceed()
        -- Load router
        local routerSrc = fetch("router.lua")
        local routerChunk = loadstring(routerSrc)
        if not routerChunk then
            error("[Noctra] Failed to compile router.")
        end
        local router = routerChunk()
        router.init(UI, Theme, fetch, registry)
    end

    local savedKey = loadSavedKey()
    if savedKey and isValidKey(savedKey) then
        proceed()
        return
    end

    UI.showKeyPrompt({
        discord = DISCORD,
        onSubmit = function(key)
            if isValidKey(key) then
                saveKey(key)
                task.spawn(proceed)
                return true
            end
            return false
        end,
    })
end

boot()
