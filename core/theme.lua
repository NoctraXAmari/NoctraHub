-- Noctra Hub | core/theme.lua
-- Theme tokens. Walang logic dito. Pure data.

local Theme = {}

Theme.Colors = {
    Base            = Color3.fromRGB(10, 10, 15),
    Surface         = Color3.fromRGB(26, 26, 36),
    SurfaceElevated = Color3.fromRGB(34, 34, 46),
    SurfaceHover    = Color3.fromRGB(42, 42, 56),

    Accent          = Color3.fromRGB(124, 92, 255),
    AccentDim       = Color3.fromRGB(90, 66, 196),
    AccentGlow      = Color3.fromRGB(155, 124, 255),

    Text            = Color3.fromRGB(232, 232, 240),
    TextDim         = Color3.fromRGB(138, 138, 154),
    TextMuted       = Color3.fromRGB(85, 85, 106),

    Border          = Color3.fromRGB(42, 42, 56),
    BorderBright    = Color3.fromRGB(70, 70, 90),

    Success         = Color3.fromRGB(74, 222, 128),
    Warning         = Color3.fromRGB(250, 204, 21),
    Danger          = Color3.fromRGB(239, 68, 68),

    Shadow          = Color3.fromRGB(0, 0, 0),
}

Theme.Fonts = {
    Regular = Enum.Font.Gotham,
    Bold    = Enum.Font.GothamBold,
}

Theme.Sizes = {
    -- Layout
    SidebarWidth    = 180,
    HeaderHeight    = 52,
    TabHeight       = 44,
    RowHeight       = 38,

    -- Spacing
    Padding         = 12,
    PaddingSmall    = 6,
    PaddingLarge    = 20,

    -- Radii
    CornerSmall     = 6,
    CornerMedium    = 10,
    CornerLarge     = 14,

    -- Stroke
    StrokeThickness = 1,

    -- Touch (mobile-first)
    TouchMin        = 44,
}

Theme.Text = {
    TitleSize       = 18,
    HeaderSize      = 15,
    BodySize        = 13,
    SmallSize       = 11,
    TinySize        = 10,
}

Theme.Anim = {
    TabSwitch       = 0.15,
    ToggleSlide     = 0.12,
    HoverFade       = 0.1,
    GlowPulse       = 1.5,
}

-- Convenience: returns Color3 with applied transparency
function Theme.alpha(color, transparency)
    return color, transparency or 0
end

-- Deep copy so accidental writes don't mutate the original
function Theme.copy(tbl)
    local out = {}
    for k, v in pairs(tbl) do
        out[k] = type(v) == "table" and Theme.copy(v) or v
    end
    return out
end

return Theme
