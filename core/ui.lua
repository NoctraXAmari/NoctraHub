-- Noctra Hub | core/ui.lua
-- Shared GUI framework. Lahat ng game modules dito naka-base.

local Theme = _G.NoctraTheme 

local UI = {}

-- =========================================================
-- INTERNAL STATE
-- =========================================================

local State = {
    ScreenGui       = nil,
    MainFrame       = nil,
    Sidebar         = nil,
    SidebarTabs     = nil,
    ContentPanel    = nil,
    HeaderFrame     = nil,
    SearchBox       = nil,
    SearchQuery     = "",
    ActiveTab       = nil,
    Tabs            = {},       -- {name -> {button, panel, scroll}}
    Elements        = {},       -- searchable registry
    Connections     = {},
    DragConnection  = nil,
    Minimized       = false,
    Destroyed       = false,
}

-- =========================================================
-- UTIL
-- =========================================================

local function new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, c in ipairs(children or {}) do
        c.Parent = inst
    end
    return inst
end

local function corner(radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

local function padding(top, right, bottom, left)
    return new("UIPadding", {
        PaddingTop    = UDim.new(0, top or 0),
        PaddingRight  = UDim.new(0, right or top or 0),
        PaddingBottom = UDim.new(0, bottom or top or 0),
        PaddingLeft   = UDim.new(0, left or right or top or 0),
    })
end

local function listLayout(props)
    local base = {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    }
    for k, v in pairs(props or {}) do base[k] = v end
    return new("UIListLayout", base)
end

local function tween(inst, time, props)
    local TweenService = game:GetService("TweenService")
    local t = TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function getParentGui()
    -- Executor-safe parent resolution
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if game:GetService("CoreGui") then
        local ok, res = pcall(function() return game:GetService("CoreGui") end)
        if ok and res then return res end
    end
    return game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
end

-- =========================================================
-- KEY PROMPT
-- =========================================================

function UI.showKeyPrompt(opts)
    opts = opts or {}
    local discord = opts.discord or "https://discord.gg/Cfa5JdrWar"
    local onSubmit = opts.onSubmit or function() end

    local gui = new("ScreenGui", {
        Name = "NoctraKeyPrompt",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
    })
    gui.Parent = getParentGui()

    local backdrop = new("Frame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Colors.Base,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
    }, { gui })

    local card = new("Frame", {
        Size = UDim2.fromOffset(320, 260),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, {
        gui,
        corner(Theme.Sizes.CornerLarge),
        stroke(Theme.Colors.AccentDim, 1, 0.4),
    })

    new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "NOCTRA HUB",
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Bold,
        TextSize = 20,
    }, { card })

    new("TextLabel", {
        Size = UDim2.new(1, -40, 0, 20),
        Position = UDim2.new(0, 20, 0, 54),
        BackgroundTransparency = 1,
        Text = "Enter your key to continue",
        TextColor3 = Theme.Colors.TextDim,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
    }, { card })

    local input = new("TextBox", {
        Size = UDim2.new(1, -40, 0, 42),
        Position = UDim2.new(0, 20, 0, 90),
        BackgroundColor3 = Theme.Colors.SurfaceElevated,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = "Paste key here...",
        PlaceholderColor3 = Theme.Colors.TextMuted,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        ClearTextOnFocus = false,
    }, {
        card,
        corner(Theme.Sizes.CornerSmall),
        stroke(Theme.Colors.Border, 1),
        padding(0, 12, 0, 12),
    })

    local submit = new("TextButton", {
        Size = UDim2.new(1, -40, 0, 42),
        Position = UDim2.new(0, 20, 0, 144),
        BackgroundColor3 = Theme.Colors.Accent,
        BorderSizePixel = 0,
        Text = "Submit",
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Bold,
        TextSize = Theme.Text.BodySize,
        AutoButtonColor = false,
    }, {
        card,
        corner(Theme.Sizes.CornerSmall),
    })

    local getKey = new("TextButton", {
        Size = UDim2.new(1, -40, 0, 34),
        Position = UDim2.new(0, 20, 0, 196),
        BackgroundTransparency = 1,
        Text = "Get Key → " .. discord,
        TextColor3 = Theme.Colors.Accent,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.SmallSize,
        AutoButtonColor = false,
    }, { card })

    submit.Activated = nil
    getKey.MouseButton1Click:Connect(function()
        pcall(function()
            if setclipboard then setclipboard(discord) end
        end)
        getKey.Text = "Copied! Opening Discord..."
        if setclipboard and syn and syn.request and syn.request then
            -- fallback optional
        end
        task.wait(0.4)
        -- open discord via executor if supported
        if request and http_request then
            -- no direct open; user copies
        end
        getKey.Text = "Discord: " .. discord
    end)

    submit.MouseButton1Click:Connect(function()
        local key = input.Text
        if key == nil or key == "" then
            input.PlaceholderText = "Key required"
            input.PlaceholderColor3 = Theme.Colors.Danger
            return
        end
        local ok, result = pcall(onSubmit, key)
        if ok and result then
            gui:Destroy()
        else
            input.Text = ""
            input.PlaceholderText = "Invalid key"
            input.PlaceholderColor3 = Theme.Colors.Danger
        end
    end)

    return gui
end

-- =========================================================
-- MAIN WINDOW
-- =========================================================

function UI.createWindow(opts)
    opts = opts or {}
    local title     = opts.title or "Noctra Hub"
    local tabs      = opts.tabs or { "Home", "Settings" }
    local onTab     = opts.onTab or function() end
    local minimized = false

    if State.Destroyed then return State end

    -- Screen
    State.ScreenGui = new("ScreenGui", {
        Name = "NoctraHub",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 50,
    })
    State.ScreenGui.Parent = getParentGui()

    -- Main frame
    State.MainFrame = new("Frame", {
        Name = "Main",
        Size = UDim2.fromOffset(640, 420),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Colors.Base,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, {
        State.ScreenGui,
        corner(Theme.Sizes.CornerLarge),
        stroke(Theme.Colors.BorderBright, 1, 0.5),
    })

    -- Header
    State.HeaderFrame = new("Frame", {
        Size = UDim2.new(1, 0, 0, Theme.Sizes.HeaderHeight),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, {
        State.MainFrame,
        corner(Theme.Sizes.CornerLarge),
        stroke(Theme.Colors.Border, 1, 0.6),
    })

    -- Title
    new("TextLabel", {
        Size = UDim2.new(0, 180, 1, 0),
        Position = UDim2.new(0, Theme.Sizes.Padding + 4, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Bold,
        TextSize = Theme.Text.HeaderSize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { State.HeaderFrame })

    -- Search
    local searchWrap = new("Frame", {
        Size = UDim2.new(0, 240, 0, 32),
        Position = UDim2.new(1, -320, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Colors.SurfaceElevated,
        BorderSizePixel = 0,
    }, {
        State.HeaderFrame,
        corner(Theme.Sizes.CornerSmall),
        stroke(Theme.Colors.Border, 1),
    })

    State.SearchBox = new("TextBox", {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.Colors.TextMuted,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }, { searchWrap })

    -- Minimize button
    local minBtn = new("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -76, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Colors.SurfaceElevated,
        BorderSizePixel = 0,
        Text = "—",
        TextColor3 = Theme.Colors.TextDim,
        Font = Theme.Fonts.Bold,
        TextSize = 14,
        AutoButtonColor = false,
    }, { State.HeaderFrame, corner(Theme.Sizes.CornerSmall) })

    -- Close button
    local closeBtn = new("TextButton", {
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, -40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Colors.SurfaceElevated,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Theme.Colors.TextDim,
        Font = Theme.Fonts.Bold,
        TextSize = 16,
        AutoButtonColor = false,
    }, { State.HeaderFrame, corner(Theme.Sizes.CornerSmall) })

    -- Sidebar
    State.Sidebar = new("Frame", {
        Size = UDim2.new(0, Theme.Sizes.SidebarWidth, 1, -Theme.Sizes.HeaderHeight),
        Position = UDim2.new(0, 0, 0, Theme.Sizes.HeaderHeight),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, {
        State.MainFrame,
        stroke(Theme.Colors.Border, 1, 0.7),
    })

    State.SidebarTabs = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Colors.AccentDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, {
        State.Sidebar,
        padding(Theme.Sizes.PaddingSmall),
        listLayout({ Padding = UDim.new(0, 4) }),
    })

    -- Content panel
    State.ContentPanel = new("Frame", {
        Size = UDim2.new(1, -Theme.Sizes.SidebarWidth, 1, -Theme.Sizes.HeaderHeight),
        Position = UDim2.new(0, Theme.Sizes.SidebarWidth, 0, Theme.Sizes.HeaderHeight),
        BackgroundColor3 = Theme.Colors.Base,
        BorderSizePixel = 0,
    }, { State.MainFrame })

    -- =========================================================
    -- TAB CREATION
    -- =========================================================
    for _, tabName in ipairs(tabs) do
        UI.addTab(tabName, onTab)
    end

    -- Auto-select first tab
    if #tabs > 0 then
        UI.selectTab(tabs[1])
    end

    -- Search wiring
    State.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        State.SearchQuery = string.lower(State.SearchBox.Text)
        UI._applySearch()
    end)

    -- Minimize
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        local targetH = minimized and Theme.Sizes.HeaderHeight or 420
        tween(State.MainFrame, 0.2, { Size = UDim2.fromOffset(640, targetH) })
        State.Sidebar.Visible = not minimized
        State.ContentPanel.Visible = not minimized
    end)

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        State.ScreenGui:Destroy()
        State.Destroyed = true
    end)

    -- =========================================================
    -- DRAG (mobile + desktop)
    -- =========================================================
    local dragging, dragStart, startPos = false, nil, nil

    State.HeaderFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = State.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    State.HeaderFrame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            State.MainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    return State
end

-- =========================================================
-- TAB API
-- =========================================================

function UI.addTab(name, onTab)
    if State.Tabs[name] then return State.Tabs[name] end

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, Theme.Sizes.TabHeight),
        BackgroundColor3 = Theme.Colors.Surface,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
    }, {
        State.SidebarTabs,
        corner(Theme.Sizes.CornerSmall),
    })

    local label = new("TextLabel", {
        Size = UDim2.new(1, -Theme.Sizes.Padding * 2, 1, 0),
        Position = UDim2.new(0, Theme.Sizes.Padding, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Theme.Colors.TextDim,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { btn })

    local panel = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Colors.AccentDim,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, {
        State.ContentPanel,
        padding(Theme.Sizes.Padding),
        listLayout({ Padding = UDim.new(0, 6) }),
    })

    local tab = {
        name = name,
        button = btn,
        label = label,
        panel = panel,
        onOpen = onTab,
    }
    State.Tabs[name] = tab

    btn.MouseButton1Click:Connect(function()
        UI.selectTab(name)
    end)

    return tab
end

function UI.selectTab(name)
    local tab = State.Tabs[name]
    if not tab then return end

    for n, t in pairs(State.Tabs) do
        local active = (n == name)
        t.panel.Visible = active
        tween(t.button, Theme.Anim.TabSwitch, {
            BackgroundTransparency = active and 0 or 1,
            BackgroundColor3 = active and Theme.Colors.Accent or Theme.Colors.Surface,
        })
        tween(t.label, Theme.Anim.TabSwitch, {
            TextColor3 = active and Theme.Colors.Text or Theme.Colors.TextDim,
        })
    end

    State.ActiveTab = name
    if tab.onOpen then
        task.spawn(tab.onOpen, tab.panel)
    end
end

-- =========================================================
-- SEARCH
-- =========================================================

function UI.registerSearchable(inst, labelText)
    table.insert(State.Elements, { inst = inst, label = string.lower(labelText or "") })
end

function UI._applySearch()
    local q = State.SearchQuery
    for _, e in ipairs(State.Elements) do
        if e.inst and e.inst.Parent then
            if q == "" then
                e.inst.Visible = true
            else
                e.inst.Visible = string.find(e.label, q, 1, true) ~= nil
            end
        end
    end
end

-- =========================================================
-- COMPONENT: SECTION HEADER
-- =========================================================

function UI.section(parent, text)
    local wrap = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundTransparency = 1,
    }, { parent, listLayout({ Padding = UDim.new(0, 0) }) })

    new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = string.upper(text),
        TextColor3 = Theme.Colors.TextMuted,
        Font = Theme.Fonts.Bold,
        TextSize = Theme.Text.TinySize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { wrap })

    return wrap
end

-- =========================================================
-- COMPONENT: TOGGLE
-- =========================================================

function UI.toggle(parent, opts)
    opts = opts or {}
    local label = opts.label or "Toggle"
    local default = opts.default or false
    local callback = opts.callback or function() end
    local state = default

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, Theme.Sizes.RowHeight),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, { parent, corner(Theme.Sizes.CornerSmall) })

    new("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, Theme.Sizes.Padding, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { row })

    local track = new("Frame", {
        Size = UDim2.fromOffset(40, 22),
        Position = UDim2.new(1, -Theme.Sizes.Padding - 40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = state and Theme.Colors.Accent or Theme.Colors.SurfaceHover,
        BorderSizePixel = 0,
    }, { row, corner(11) })

    local knob = new("Frame", {
        Size = UDim2.fromOffset(16, 16),
        Position = state and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Theme.Colors.Text,
        BorderSizePixel = 0,
    }, { track, corner(8) })

    local btn = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
    }, { row })

    local function set(v)
        state = v
        tween(track, Theme.Anim.ToggleSlide, {
            BackgroundColor3 = v and Theme.Colors.Accent or Theme.Colors.SurfaceHover,
        })
        tween(knob, Theme.Anim.ToggleSlide, {
            Position = v and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        })
    end

    btn.MouseButton1Click:Connect(function()
        set(not state)
        pcall(callback, state)
    end)

    UI.registerSearchable(row, label)

    return {
        row = row,
        set = set,
        get = function() return state end,
    }
end

-- =========================================================
-- COMPONENT: BUTTON
-- =========================================================

function UI.button(parent, opts)
    opts = opts or {}
    local label = opts.label or "Button"
    local callback = opts.callback or function() end
    local color = opts.color or Theme.Colors.SurfaceElevated

    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, Theme.Sizes.RowHeight),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Text = label,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        AutoButtonColor = false,
    }, {
        parent,
        corner(Theme.Sizes.CornerSmall),
        stroke(Theme.Colors.Border, 1, 0.5),
    })

    btn.MouseEnter:Connect(function()
        tween(btn, Theme.Anim.HoverFade, { BackgroundColor3 = Theme.Colors.SurfaceHover })
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, Theme.Anim.HoverFade, { BackgroundColor3 = color })
    end)
    btn.MouseButton1Click:Connect(function()
        pcall(callback)
    end)

    UI.registerSearchable(btn, label)
    return btn
end

-- =========================================================
-- COMPONENT: SLIDER
-- =========================================================

function UI.slider(parent, opts)
    opts = opts or {}
    local label = opts.label or "Slider"
    local min = opts.min or 0
    local max = opts.max or 100
    local default = opts.default or min
    local callback = opts.callback or function() end
    local value = default

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, { parent, corner(Theme.Sizes.CornerSmall) })

    local titleLbl = new("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 24),
        Position = UDim2.new(0, Theme.Sizes.Padding, 0, 4),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { row })

    local valueLbl = new("TextLabel", {
        Size = UDim2.new(0.3, -Theme.Sizes.Padding, 0, 24),
        Position = UDim2.new(0.7, 0, 0, 4),
        BackgroundTransparency = 1,
        Text = tostring(value),
        TextColor3 = Theme.Colors.Accent,
        Font = Theme.Fonts.Bold,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, { row })

    local bar = new("Frame", {
        Size = UDim2.new(1, -Theme.Sizes.Padding * 2, 0, 6),
        Position = UDim2.new(0, Theme.Sizes.Padding, 1, -14),
        BackgroundColor3 = Theme.Colors.SurfaceHover,
        BorderSizePixel = 0,
    }, { row, corner(3) })

    local fill = new("Frame", {
        Size = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = Theme.Colors.Accent,
        BorderSizePixel = 0,
    }, { bar, corner(3) })

    local hit = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 1, -24),
        BackgroundTransparency = 1,
        Text = "",
    }, { row })

    local function setFromX(x)
        local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        value = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valueLbl.Text = tostring(value)
        pcall(callback, value)
    end

    local dragging = false
    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    hit.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    hit.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UI.registerSearchable(row, label)

    return {
        row = row,
        set = function(v)
            v = math.clamp(v, min, max)
            value = v
            fill.Size = UDim2.new((v - min) / math.max(max - min, 1), 0, 1, 0)
            valueLbl.Text = tostring(v)
        end,
        get = function() return value end,
    }
end

-- =========================================================
-- COMPONENT: TEXT INPUT
-- =========================================================

function UI.input(parent, opts)
    opts = opts or {}
    local label = opts.label or "Input"
    local default = opts.default or ""
    local callback = opts.callback or function() end

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Colors.Surface,
        BorderSizePixel = 0,
    }, { parent, corner(Theme.Sizes.CornerSmall) })

    new("TextLabel", {
        Size = UDim2.new(0.45, 0, 1, 0),
        Position = UDim2.new(0, Theme.Sizes.Padding, 0, 0),
        BackgroundTransparency = 1,
        Text = label,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, { row })

    local box = new("TextBox", {
        Size = UDim2.new(0.5, -Theme.Sizes.Padding, 1, -8),
        Position = UDim2.new(0.5, 0, 0, 4),
        BackgroundColor3 = Theme.Colors.SurfaceElevated,
        BorderSizePixel = 0,
        Text = default,
        PlaceholderText = "...",
        PlaceholderColor3 = Theme.Colors.TextMuted,
        TextColor3 = Theme.Colors.Text,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.BodySize,
        ClearTextOnFocus = false,
    }, { row, corner(Theme.Sizes.CornerSmall), padding(0, 8, 0, 8) })

    box.FocusLost:Connect(function()
        pcall(callback, box.Text)
    end)

    UI.registerSearchable(row, label)
    return box
end

-- =========================================================
-- COMPONENT: LABEL
-- =========================================================

function UI.label(parent, text, color)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or Theme.Colors.TextDim,
        Font = Theme.Fonts.Regular,
        TextSize = Theme.Text.SmallSize,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, { parent })
    return lbl
end

-- =========================================================
-- COMPONENT: DIVIDER
-- =========================================================

function UI.divider(parent)
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Colors.Border,
        BorderSizePixel = 0,
    }, { parent })
end

return UI
