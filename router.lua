-- Noctra Hub | router.lua
-- Detects PlaceId, maps to game module, executes it.

local Router = {}

-- =========================================================
-- GAME MAP
-- =========================================================

-- Idagdag mo yung PlaceId dito. Kunin sa Roblox URL.
-- Format: [PlaceId] = "games/<filename>.lua"
Router.MAP = {
    -- [PLACEID_AOTR] = "games/aotr.lua",
}

-- =========================================================
-- INIT
-- =========================================================

function Router.init(UI, Theme, fetch, registry)
    local placeId = game.PlaceId
    local modulePath = Router.MAP[placeId]

    if not modulePath then
        UI.showKeyPrompt({
            discord = "https://discord.gg/Cfa5JdrWar",
            onSubmit = function() return false end,
        })
        -- Replace prompt with unsupported message
        task.wait(0.1)
        local gui = game:GetService("CoreGui"):FindFirstChild("NoctraKeyPrompt")
        if gui then
            local card = gui:FindFirstChildWhichIsA("Frame")
            if card then
                local lbl = card:FindFirstChildWhichIsA("TextLabel")
                if lbl then lbl.Text = "GAME NOT SUPPORTED" end
            end
        end
        return
    end

    local src = fetch(modulePath)
    local chunk = loadstring(src)
    if not chunk then
        error("[Noctra] Failed to compile module: " .. modulePath)
    end

    local module = chunk()
    if type(module) == "table" and module.run then
        registry.game = modulePath
        module.run(UI, Theme, fetch, registry)
    end
end

return Router
