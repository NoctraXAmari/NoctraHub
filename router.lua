-- Noctra Hub | router.lua
-- Detects PlaceId, maps to game module, executes it.

local Router = {}

-- =========================================================
-- CONFIG
-- =========================================================

local DISCORD = "https://discord.gg/Cfa5JdrWar"

-- Set to true kung gusto mong i-kick yung user pag unsupported.
-- Default: false — nagpapakita lang ng overlay message.
local KICK_ON_UNSUPPORTED = true
local KICK_MESSAGE = "[Noctra Hub] Game not supported."

-- =========================================================
-- GAME MAP
-- =========================================================

Router.MAP = {
    [13379208636] = "games/aotr.lua",
}

Router.NAMES = {
    [13379208636] = "Attack on Titan Revolution",
}

-- =========================================================
-- UNSUPPORTED OVERLAY
-- =========================================================

local function showUnsupported(UI, Theme)
    if KICK_ON_UNSUPPORTED then
        pcall(function()
            game:GetService("Players").LocalPlayer:Kick(KICK_MESSAGE)
        end)
        return
    end

    local parent = (gethui and gethui()) or game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "NoctraUnsupported"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 200
    gui.Parent = parent

    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Theme.Colors.Base
    bg.BackgroundTransparency = 0.1
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(340, 240)
    card.Position = UDim2.fromScale(0.5, 0.5)
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.BackgroundColor3 = Theme.Colors.Surface
    card.BorderSizePixel = 0
    card.Parent = gui

    local c1 = Instance.new("UICorner", card)
    c1.CornerRadius = UDim.new(0, Theme.Sizes.CornerLarge)

    local s1 = Instance.new("UIStroke", card)
    s1.Color = Theme.Colors.AccentDim
    s1.Thickness = 1
    s1.Transparency = 0.4

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 32)
    title.Position = UDim2.new(0, 20, 0, 24)
    title.BackgroundTransparency = 1
    title.Text = "NOCTRA HUB"
    title.TextColor3 = Theme.Colors.Text
    title.Font = Theme.Fonts.Bold
    title.TextSize = 20
    title.Parent = card

    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -40, 0, 24)
    msg.Position = UDim2.new(0, 20, 0, 62)
    msg.BackgroundTransparency = 1
    msg.Text = "Game not supported"
    msg.TextColor3 = Theme.Colors.Danger
    msg.Font = Theme.Fonts.Bold
    msg.TextSize = 15
    msg.Parent = card

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -40, 0, 60)
    info.Position = UDim2.new(0, 20, 0, 92)
    info.BackgroundTransparency = 1
    info.Text = "This game isn't in Noctra Hub's supported list yet. Join our Discord to request support."
    info.TextColor3 = Theme.Colors.TextDim
    info.Font = Theme.Fonts.Regular
    info.TextSize = 12
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -40, 0, 40)
    btn.Position = UDim2.new(0, 20, 0, 170)
    btn.BackgroundColor3 = Theme.Colors.Accent
    btn.BorderSizePixel = 0
    btn.Text = "Copy Discord Link"
    btn.TextColor3 = Theme.Colors.Text
    btn.Font = Theme.Fonts.Bold
    btn.TextSize = 13
    btn.AutoButtonColor = false
    btn.Parent = card

    local c2 = Instance.new("UICorner", btn)
    c2.CornerRadius = UDim.new(0, Theme.Sizes.CornerSmall)

    btn.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(DISCORD) end
        end)
        btn.Text = "Copied: " .. DISCORD
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(28, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = Theme.Colors.SurfaceElevated
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Theme.Colors.TextDim
    closeBtn.Font = Theme.Fonts.Bold
    closeBtn.TextSize = 16
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = card

    local c3 = Instance.new("UICorner", closeBtn)
    c3.CornerRadius = UDim.new(0, Theme.Sizes.CornerSmall)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
end

-- =========================================================
-- INIT
-- =========================================================

function Router.init(UI, Theme, fetch, registry)
    local placeId = game.PlaceId
    local modulePath = Router.MAP[placeId]

    if not modulePath then
        showUnsupported(UI, Theme)
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
        registry.gameName = Router.NAMES[placeId] or "Unknown"
        module.run(UI, Theme, fetch, registry)
    end
end

return Router
