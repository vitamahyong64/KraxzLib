--[[
    ╔══════════════════════════════════════════════╗
    ║             KraxzUi Library v1.0             ║
    ║              Made by Kraxz Hub               ║
    ║     Professional Dark + Red Theme UI Lib     ║
    ╚══════════════════════════════════════════════╝
]]

local KraxzUi = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

local function GetParent()
    local success, result = pcall(function()
        if gethui then return gethui() end
        if get_hidden_gui then return get_hidden_gui() end
        return CoreGui
    end)
    return success and result or CoreGui
end

local Theme = {
    Background = Color3.fromRGB(13, 13, 17),
    Secondary = Color3.fromRGB(19, 19, 25),
    Tertiary = Color3.fromRGB(28, 28, 36),
    Accent = Color3.fromRGB(220, 45, 45),
    AccentHover = Color3.fromRGB(255, 68, 68),
    Text = Color3.fromRGB(240, 240, 245),
    TextDim = Color3.fromRGB(140, 140, 150),
    TextRed = Color3.fromRGB(255, 110, 110),
    Stroke = Color3.fromRGB(38, 38, 48),
}

local Flags = {}

local function Create(class, props)
    local obj = Instance.new(class)
    for i, v in pairs(props or {}) do
        obj[i] = v
    end
    return obj
end

local function Corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thick)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Stroke
    s.Thickness = thick or 1
    s.Parent = obj
    return s
end

local function Tween(obj, props, time)
    local t = TweenService:Create(obj, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

-- Notification
local NotifHolder
local function Notify(title, text, duration)
    duration = duration or 3.5
    if not NotifHolder or not NotifHolder.Parent then
        NotifHolder = Create("Frame", {
            Name = "KraxzNotifs",
            Parent = GetParent(),
            BackgroundTransparency = 1,
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -14, 1, -14),
            Size = UDim2.new(0, 310, 0, 0),
            ZIndex = 999
        })
        Create("UIListLayout", {
            Parent = NotifHolder,
            Padding = UDim.new(0, 8),
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment = Enum.VerticalAlignment.Bottom
        })
    end

    local n = Create("Frame", {
        Parent = NotifHolder,
        BackgroundColor3 = Theme.Secondary,
        Size = UDim2.new(0, 290, 0, 0),
        ClipsDescendants = true,
        ZIndex = 1000
    })
    Corner(n, 8)
    Stroke(n, Theme.Accent, 1)

    local t = Create("TextLabel", {
        Parent = n,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 16),
        Font = Enum.Font.GothamBold,
        Text = title,
        TextColor3 = Theme.Accent,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001
    })

    local d = Create("TextLabel", {
        Parent = n,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 26),
        Size = UDim2.new(1, -24, 0, 0),
        Font = Enum.Font.Gotham,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001
    })

    local size = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(266, 300))
    d.Size = UDim2.new(1, -24, 0, size.Y)
    n.Size = UDim2.new(0, 290, 0, 40 + size.Y)

    n.BackgroundTransparency = 1
    t.TextTransparency = 1
    d.TextTransparency = 1
    Tween(n, {BackgroundTransparency = 0}, 0.2)
    Tween(t, {TextTransparency = 0}, 0.2)
    Tween(d, {TextTransparency = 0}, 0.2)

    task.delay(duration, function()
        if n and n.Parent then
            Tween(n, {BackgroundTransparency = 1}, 0.25)
            Tween(t, {TextTransparency = 1}, 0.25)
            Tween(d, {TextTransparency = 1}, 0.25)
            task.wait(0.3)
            n:Destroy()
        end
    end)
end

function KraxzUi:CreateWindow(cfg)
    cfg = cfg or {}
    local Title = cfg.Title or "Kraxz Hub"
    local Version = cfg.Version or "v1.0"
    local ToggleKey = cfg.ToggleKey or Enum.KeyCode.RightControl
    local ConfigFolder = cfg.ConfigFolder or "KraxzHub"
    local ConfigName = cfg.ConfigName or "config"

    local parent = GetParent()
    if parent:FindFirstChild("KraxzUi_Main") then
        parent.KraxzUi_Main:Destroy()
    end

    local ScreenGui = Create("ScreenGui", {
        Name = "KraxzUi_Main",
        Parent = parent,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 9999
    })

    local DefaultSize = UDim2.new(0, 720, 0, 460)
    local MaximizedSize = UDim2.new(0, 940, 0, 600)

    local Main = Create("Frame", {
        Name = "Main",
        Parent = ScreenGui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, -360, 0.5, -230),
        Size = DefaultSize,
        ClipsDescendants = true,
        BackgroundTransparency = 1
    })
    Corner(Main, 10)
    Stroke(Main, Theme.Stroke, 1)
    Tween(Main, {BackgroundTransparency = 0}, 0.35)

    -- Title Bar
    local TitleBar = Create("Frame", {
        Parent = Main,
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38)
    })
    Corner(TitleBar, 10)

    Create("TextLabel", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 0),
        Size = UDim2.new(0.4, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        Text = Title .. "  |  " .. Version,
        TextColor3 = Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local SearchBox = Create("TextBox", {
        Parent = TitleBar,
        BackgroundColor3 = Theme.Tertiary,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -320, 0.5, -12),
        Size = UDim2.new(0, 150, 0, 24),
        Font = Enum.Font.Gotham,
        PlaceholderText = "Search...",
        PlaceholderColor3 = Theme.TextDim,
        Text = "",
        TextColor3 = Theme.Text,
        TextSize = 12,
        ClearTextOnFocus = false
    })
    Corner(SearchBox, 6)

    -- Window Controls
    local ControlFrame = Create("Frame", {
        Parent = TitleBar,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -115, 0, 0),
        Size = UDim2.new(0, 110, 1, 0)
    })

    local function MakeBtn(text, x)
        local b = Create("TextButton", {
            Parent = ControlFrame,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, x, 0, 0),
            Size = UDim2.new(0, 32, 1, 0),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Theme.TextDim,
            TextSize = 16,
            AutoButtonColor = false
        })
        b.MouseEnter:Connect(function() Tween(b, {TextColor3 = Theme.Text}, 0.12) end)
        b.MouseLeave:Connect(function() Tween(b, {TextColor3 = Theme.TextDim}, 0.12) end)
        return b
    end

    local MinBtn = MakeBtn("–", 0)
    local MaxBtn = MakeBtn("□", 36)
    local CloseBtn = MakeBtn("×", 72)

    local IsMinimized, IsMaximized = false, false
    local SavedPos, SavedSize = Main.Position, DefaultSize

    MinBtn.MouseButton1Click:Connect(function()
        IsMinimized = not IsMinimized
        if IsMinimized then
            SavedPos = Main.Position
            SavedSize = Main.Size
            Tween(Main, {Size = UDim2.new(0, Main.Size.X.Offset, 0, 38)}, 0.22)
        else
            Tween(Main, {Size = IsMaximized and MaximizedSize or DefaultSize}, 0.22)
        end
    end)

    MaxBtn.MouseButton1Click:Connect(function()
        if IsMinimized then return end
        IsMaximized = not IsMaximized
        if IsMaximized then
            SavedPos = Main.Position
            SavedSize = Main.Size
            Tween(Main, {
                Size = MaximizedSize,
                Position = UDim2.new(0.5, -MaximizedSize.X.Offset/2, 0.5, -MaximizedSize.Y.Offset/2)
            }, 0.25)
            MaxBtn.Text = "❐"
        else
            Tween(Main, {Size = DefaultSize, Position = SavedPos}, 0.25)
            MaxBtn.Text = "□"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        Tween(Main, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.22)
        ScreenGui:Destroy()
    end)

    -- Sidebar
    local Sidebar = Create("Frame", {
        Parent = Main,
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 38),
        Size = UDim2.new(0, 52, 1, -38)
    })
    local SideList = Create("UIListLayout", {
        Parent = Sidebar,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {Parent = Sidebar, PaddingTop = UDim.new(0, 12)})

    -- Content
    local Content = Create("Frame", {
        Parent = Main,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 52, 0, 38),
        Size = UDim2.new(1, -52, 1, -38)
    })

    local TabBar = Create("Frame", {
        Parent = Content,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 40)
    })
    local TabList = Create("UIListLayout", {
        Parent = TabBar,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    Create("UIPadding", {
        Parent = TabBar,
        PaddingLeft = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 7)
    })

    local Pages = Create("Folder", {Name = "Pages", Parent = Content})

    -- Dragging
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not IsMaximized then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local Window = {
        ScreenGui = ScreenGui,
        Main = Main,
        Tabs = {},
        Flags = Flags,
        Visible = true
    }

    function Window:Notify(title, text, dur)
        Notify(title, text, dur)
    end

    function Window:Destroy()
        ScreenGui:Destroy()
    end

    function Window:SetVisible(state)
        Window.Visible = state
        Main.Visible = state
    end

    function Window:Toggle()
        Window:SetVisible(not Window.Visible)
    end

    local CurrentToggleKey = ToggleKey
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == CurrentToggleKey then
            Window:Toggle()
        end
    end)

    function Window:SetToggleKey(key)
        CurrentToggleKey = key
    end

    function Window:SaveConfig()
        pcall(function()
            if writefile then
                if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
                writefile(ConfigFolder .. "/" .. ConfigName .. ".json", HttpService:JSONEncode(Flags))
                Notify("Config", "Saved successfully!")
            end
        end)
    end

    function Window:LoadConfig()
        pcall(function()
            if readfile and isfile then
                local path = ConfigFolder .. "/" .. ConfigName .. ".json"
                if isfile(path) then
                    local data = HttpService:JSONDecode(readfile(path))
                    for k, v in pairs(data) do Flags[k] = v end
                    Notify("Config", "Loaded successfully!")
                end
            end
        end)
    end

    function Window:CreateTab(name, icon)
        icon = icon or string.sub(name, 1, 1)

        local TabBtn = Create("TextButton", {
            Parent = TabBar,
            BackgroundColor3 = Theme.Tertiary,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 94, 0, 28),
            Font = Enum.Font.GothamMedium,
            Text = name,
            TextColor3 = Theme.TextDim,
            TextSize = 13,
            AutoButtonColor = false
        })
        Corner(TabBtn, 6)

        local Page = Create("ScrollingFrame", {
            Name = name,
            Parent = Pages,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(1, 0, 1, -40),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y
        })

        local PageLayout = Create("UIListLayout", {
            Parent = Page,
            Padding = UDim.new(0, 11),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Create("UIPadding", {
            Parent = Page,
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 14)
        })

        local SideIcon = Create("TextButton", {
            Parent = Sidebar,
            BackgroundColor3 = Theme.Tertiary,
            BorderSizePixel = 0,
            Size = UDim2.new(0, 36, 0, 36),
            Font = Enum.Font.GothamBold,
            Text = icon,
            TextColor3 = Theme.TextDim,
            TextSize = 14,
            AutoButtonColor = false
        })
        Corner(SideIcon, 8)

        local Tab = {Button = TabBtn, Page = Page, SideIcon = SideIcon}

        local function Select()
            for _, t in pairs(Window.Tabs) do
                t.Page.Visible = false
                Tween(t.Button, {BackgroundColor3 = Theme.Tertiary, TextColor3 = Theme.TextDim}, 0.15)
                Tween(t.SideIcon, {BackgroundColor3 = Theme.Tertiary, TextColor3 = Theme.TextDim}, 0.15)
            end
            Page.Visible = true
            Tween(TabBtn, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}, 0.15)
            Tween(SideIcon, {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text}, 0.15)
        end

        TabBtn.MouseButton1Click:Connect(Select)
        SideIcon.MouseButton1Click:Connect(Select)

        if #Window.Tabs == 0 then Select() end
        table.insert(Window.Tabs, Tab)

        function Tab:CreateSection(secName)
            local Section = Create("Frame", {
                Parent = Page,
                BackgroundColor3 = Theme.Secondary,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                AutomaticSize = Enum.AutomaticSize.Y
            })
            Corner(Section, 8)
            Stroke(Section, Theme.Stroke, 1)

            local SecLayout = Create("UIListLayout", {
                Parent = Section,
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder
            })
            Create("UIPadding", {
                Parent = Section,
                PaddingLeft = UDim.new(0, 13),
                PaddingRight = UDim.new(0, 13),
                PaddingTop = UDim.new(0, 11),
                PaddingBottom = UDim.new(0, 11)
            })

            Create("TextLabel", {
                Parent = Section,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 17),
                Font = Enum.Font.GothamBold,
                Text = secName,
                TextColor3 = Theme.Accent,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left
            })

            local Sec = {}

            function Sec:AddLabel(text, red)
                return Create("TextLabel", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 17),
                    Font = Enum.Font.Gotham,
                    Text = tostring(text),
                    TextColor3 = red and Theme.TextRed or Theme.TextDim,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
            end

            function Sec:AddParagraph(text)
                return Create("TextLabel", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    Font = Enum.Font.Gotham,
                    Text = tostring(text),
                    TextColor3 = Theme.TextDim,
                    TextSize = 12,
                    TextWrapped = true,
                    AutomaticSize = Enum.AutomaticSize.Y
                })
            end

            function Sec:AddDivider()
                return Create("Frame", {
                    Parent = Section,
                    BackgroundColor3 = Theme.Stroke,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 1)
                })
            end

            function Sec:AddToggle(opts)
                opts = opts or {}
                local name = opts.Name or "Toggle"
                local default = opts.Default or false
                local flag = opts.Flag
                local callback = opts.Callback or function() end

                if flag and Flags[flag] \~= nil then default = Flags[flag] end

                local Row = Create("Frame", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -55, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local ToggleBG = Create("Frame", {
                    Parent = Row,
                    BackgroundColor3 = default and Theme.Accent or Theme.Tertiary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(1, -48, 0.5, -10),
                    Size = UDim2.new(0, 44, 0, 20)
                })
                Corner(ToggleBG, 10)

                local Circle = Create("Frame", {
                    Parent = ToggleBG,
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    BorderSizePixel = 0,
                    Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
                    Size = UDim2.new(0, 16, 0, 16)
                })
                Corner(Circle, 8)

                local state = default
                local function Set(v, fire)
                    state = v
                    if flag then Flags[flag] = v end
                    Tween(ToggleBG, {BackgroundColor3 = state and Theme.Accent or Theme.Tertiary}, 0.15)
                    Tween(Circle, {Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}, 0.15)
                    if fire \~= false then callback(state) end
                end

                ToggleBG.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        Set(not state)
                    end
                end)

                return {Set = Set, Get = function() return state end}
            end

            function Sec:AddSlider(opts)
                opts = opts or {}
                local name = opts.Name or "Slider"
                local min, max = opts.Min or 0, opts.Max or 100
                local default = math.clamp(opts.Default or min, min, max)
                local suffix = opts.Suffix or ""
                local flag = opts.Flag
                local callback = opts.Callback or function() end

                if flag and Flags[flag] \~= nil then default = Flags[flag] end

                local Row = Create("Frame", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 46)
                })

                Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.65, 0, 0, 18),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Val = Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.65, 0, 0, 0),
                    Size = UDim2.new(0.35, 0, 0, 18),
                    Font = Enum.Font.GothamMedium,
                    Text = math.floor(default) .. suffix,
                    TextColor3 = Theme.Accent,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right
                })

                local Bar = Create("Frame", {
                    Parent = Row,
                    BackgroundColor3 = Theme.Tertiary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 0, 0, 26),
                    Size = UDim2.new(1, 0, 0, 7)
                })
                Corner(Bar, 4)

                local Fill = Create("Frame", {
                    Parent = Bar,
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0)
                })
                Corner(Fill, 4)

                local sliding = false
                local function Update(v)
                    v = math.clamp(v, min, max)
                    if flag then Flags[flag] = v end
                    Fill.Size = UDim2.new((v - min) / math.max(max - min, 1), 0, 1, 0)
                    Val.Text = math.floor(v) .. suffix
                    callback(v)
                end

                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        Update(min + (max - min) * rel)
                    end
                end)

                Update(default)
                return {Set = Update}
            end

            function Sec:AddButton(opts)
                opts = opts or {}
                local Btn = Create("TextButton", {
                    Parent = Section,
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 32),
                    Font = Enum.Font.GothamMedium,
                    Text = opts.Name or "Button",
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    AutoButtonColor = false
                })
                Corner(Btn, 6)
                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.AccentHover}, 0.12) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.12) end)
                Btn.MouseButton1Click:Connect(opts.Callback or function() end)
                return Btn
            end

            function Sec:AddDropdown(opts)
                opts = opts or {}
                local name = opts.Name or "Dropdown"
                local options = opts.Options or {"Option 1"}
                local default = opts.Default or options[1]
                local flag = opts.Flag
                local multi = opts.Multi or false
                local callback = opts.Callback or function() end

                if flag and Flags[flag] \~= nil then default = Flags[flag] end

                local Row = Create("Frame", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.42, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local DropBtn = Create("TextButton", {
                    Parent = Row,
                    BackgroundColor3 = Theme.Tertiary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.42, 0, 0, 0),
                    Size = UDim2.new(0.58, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = "  " .. (type(default) == "table" and table.concat(default, ", ") or tostring(default)) .. "  ▼",
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false
                })
                Corner(DropBtn, 6)

                local DropFrame = Create("Frame", {
                    Parent = Section,
                    BackgroundColor3 = Theme.Tertiary,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 0),
                    Visible = false,
                    ClipsDescendants = true,
                    ZIndex = 50
                })
                Corner(DropFrame, 6)
                Stroke(DropFrame, Theme.Stroke, 1)
                Create("UIListLayout", {Parent = DropFrame, SortOrder = Enum.SortOrder.LayoutOrder})

                local open = false
                local current = multi and (type(default) == "table" and default or {default}) or default

                local function Refresh()
                    if multi then
                        DropBtn.Text = "  " .. (#current > 0 and table.concat(current, ", ") or "None") .. "  ▼"
                    else
                        DropBtn.Text = "  " .. tostring(current) .. "  ▼"
                    end
                end

                local function Toggle()
                    open = not open
                    if open then
                        DropFrame.Visible = true
                        Tween(DropFrame, {Size = UDim2.new(1, 0, 0, #options * 26)}, 0.2)
                    else
                        Tween(DropFrame, {Size = UDim2.new(1, 0, 0, 0)}, 0.2)
                        task.delay(0.22, function() if not open then DropFrame.Visible = false end end)
                    end
                end

                DropBtn.MouseButton1Click:Connect(Toggle)

                for _, opt in ipairs(options) do
                    local b = Create("TextButton", {
                        Parent = DropFrame,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 26),
                        Font = Enum.Font.Gotham,
                        Text = "  " .. opt,
                        TextColor3 = Theme.Text,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 51,
                        AutoButtonColor = false
                    })
                    b.MouseButton1Click:Connect(function()
                        if multi then
                            local idx = table.find(current, opt)
                            if idx then table.remove(current, idx) else table.insert(current, opt) end
                            if flag then Flags[flag] = current end
                            callback(current)
                        else
                            current = opt
                            if flag then Flags[flag] = opt end
                            callback(opt)
                            Toggle()
                        end
                        Refresh()
                    end)
                end

                Refresh()
                return {
                    Set = function(v) current = v if flag then Flags[flag] = v end Refresh() end,
                    Get = function() return current end
                }
            end

            function Sec:AddKeybind(opts)
                opts = opts or {}
                local name = opts.Name or "Keybind"
                local default = opts.Default or Enum.KeyCode.E
                local flag = opts.Flag
                local callback = opts.Callback or function() end
                local isToggleUI = opts.IsToggleUI or false

                if flag and Flags[flag] then
                    local ok, key = pcall(function() return Enum.KeyCode[Flags[flag]] end)
                    if ok and key then default = key end
                end

                local Row = Create("Frame", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.55, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local KeyBtn = Create("TextButton", {
                    Parent = Row,
                    BackgroundColor3 = Theme.Tertiary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.55, 0, 0, 0),
                    Size = UDim2.new(0.45, 0, 1, 0),
                    Font = Enum.Font.GothamMedium,
                    Text = default.Name,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    AutoButtonColor = false
                })
                Corner(KeyBtn, 6)

                local listening = false
                local currentKey = default

                KeyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KeyBtn.Text = "..."
                    KeyBtn.TextColor3 = Theme.Accent
                end)

                UserInputService.InputBegan:Connect(function(input, gp)
                    if listening and input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode
                        if flag then Flags[flag] = input.KeyCode.Name end
                        KeyBtn.Text = input.KeyCode.Name
                        KeyBtn.TextColor3 = Theme.Text
                        listening = false
                        if isToggleUI then
                            Window:SetToggleKey(input.KeyCode)
                        end
                    elseif not gp and not listening and input.KeyCode == currentKey then
                        callback()
                    end
                end)

                return {
                    Get = function() return currentKey end,
                    Set = function(key)
                        currentKey = key
                        KeyBtn.Text = key.Name
                        if flag then Flags[flag] = key.Name end
                        if isToggleUI then Window:SetToggleKey(key) end
                    end
                }
            end

            function Sec:AddTextBox(opts)
                opts = opts or {}
                local name = opts.Name or "TextBox"
                local placeholder = opts.Placeholder or "Type here..."
                local default = opts.Default or ""
                local flag = opts.Flag
                local callback = opts.Callback or function() end

                if flag and Flags[flag] then default = Flags[flag] end

                local Row = Create("Frame", {
                    Parent = Section,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28)
                })

                Create("TextLabel", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.38, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = name,
                    TextColor3 = Theme.Text,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left
                })

                local Box = Create("TextBox", {
                    Parent = Row,
                    BackgroundColor3 = Theme.Tertiary,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0.38, 0, 0, 0),
                    Size = UDim2.new(0.62, 0, 1, 0),
                    Font = Enum.Font.Gotham,
                    Text = default,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Theme.TextDim,
                    TextColor3 = Theme.Text,
                    TextSize = 12,
                    ClearTextOnFocus = false
                })
                Corner(Box, 6)

                Box.FocusLost:Connect(function(enter)
                    if flag then Flags[flag] = Box.Text end
                    if enter then callback(Box.Text) end
                end)

                return {
                    Set = function(t) Box.Text = t if flag then Flags[flag] = t end end,
                    Get = function() return Box.Text end
                }
            end

            return Sec
        end

        return Tab
    end

    task.defer(function()
        task.wait(0.5)
        Window:LoadConfig()
    end)

    return Window
end

return KraxzUi
