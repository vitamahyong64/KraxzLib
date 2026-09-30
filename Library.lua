--[[
	RedObsidian UI Library v6.0
	Clean • Compact • Retro

	Tema      : Hitam dengan aksen merah redup
	Font      : Arcade (judul / tombol) + Code (isi)
	Struktur  : Mirip Obsidian UI

	Fitur Bawaan:
	- Floating Toggle (hitam, bisa digeser + lock posisi)
	- Window, Tab, Groupbox
	- Label, Divider, Button + SubButton
	- Toggle, Checkbox, Slider, Input
	- Dropdown (Single / Multi / Player)
	- Keybind, ColorPicker
	- Tooltip, Notify (bertumpuk), WarningBox
	- SaveConfig / LoadConfig
	- Dependency System
	- Tombol Close -> konfirmasi -> Library:Unload()
	  (UI dihapus + semua fitur aktif dimatikan)
	- Theme Accent (SetAccent)
]]

local Library = {
	Version  = "v6.0",
	Flags    = {},
	Toggles  = {},
	Options  = {},
	Unloaded = false,
}

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local HttpService      = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- ===================== THEME =====================
local Theme = {
	Background   = Color3.fromRGB(12, 12, 14),
	Surface      = Color3.fromRGB(18, 18, 21),
	SurfaceLight = Color3.fromRGB(28, 28, 32),
	Border       = Color3.fromRGB(44, 44, 50),
	Accent       = Color3.fromRGB(170, 48, 58),
	AccentSoft   = Color3.fromRGB(198, 88, 96),
	AccentDark   = Color3.fromRGB(102, 30, 36),
	Text         = Color3.fromRGB(236, 236, 240),
	TextDim      = Color3.fromRGB(132, 132, 142),
	Font         = Enum.Font.Code,    -- isi / label
	FontTitle    = Enum.Font.Arcade,  -- judul / tombol (retro)
}

-- ===================== STATE INTERNAL =====================
local Connections = {} -- koneksi global (UserInputService dll) -> diputus saat Unload
local UnloadHooks = {}
local ThemeHooks  = {} -- dipanggil ulang saat SetAccent
local ConfirmOpen = false

-- ===================== UTILS =====================
local function Track(connection)
	table.insert(Connections, connection)
	return connection
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[RedObsidian] " .. tostring(err))
	end
end

local function Create(class, props)
	local obj = Instance.new(class)
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			obj[key] = value
		end
	end
	obj.Parent = parent
	return obj
end

local function Tween(obj, props, duration)
	if duration == 0 then
		for key, value in pairs(props) do
			obj[key] = value
		end
		return
	end
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

-- Set properti warna dari Theme + otomatis ikut berubah saat SetAccent
local function Paint(obj, prop, key)
	obj[prop] = Theme[key]
	table.insert(ThemeHooks, function()
		obj[prop] = Theme[key]
	end)
	return obj
end

local function IsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function Stroke(parent, color, thickness)
	return Create("UIStroke", {
		Color           = color or Theme.Border,
		Thickness       = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent          = parent,
	})
end

local function Padding(parent, top, right, bottom, left)
	return Create("UIPadding", {
		PaddingTop    = UDim.new(0, top or 0),
		PaddingRight  = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft   = UDim.new(0, left or 0),
		Parent        = parent,
	})
end

local function List(parent, gap)
	return Create("UIListLayout", {
		Padding   = UDim.new(0, gap or 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent    = parent,
	})
end

local function NewFrame(props)
	props.BorderSizePixel = 0
	return Create("Frame", props)
end

local function NewLabel(props)
	props.BorderSizePixel = 0
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	props.TextColor3     = props.TextColor3 or Theme.Text
	props.Font           = props.Font or Theme.Font
	props.TextSize       = props.TextSize or 13
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return Create("TextLabel", props)
end

local function NewButton(props)
	props.BorderSizePixel = 0
	props.AutoButtonColor = false
	props.TextColor3      = props.TextColor3 or Theme.Text
	props.Font            = props.Font or Theme.FontTitle
	props.TextSize        = props.TextSize or 13
	return Create("TextButton", props)
end

-- Hover + press effect untuk tombol bergaya retro (border ikut berubah)
local function ButtonStyle(btn, stroke, base, hover)
	btn.MouseEnter:Connect(function()
		Tween(btn, { BackgroundColor3 = hover }, 0.12)
		Tween(stroke, { Color = Theme.Accent }, 0.12)
	end)
	btn.MouseLeave:Connect(function()
		Tween(btn, { BackgroundColor3 = base }, 0.12)
		Tween(stroke, { Color = Theme.Border }, 0.12)
	end)
	btn.MouseButton1Down:Connect(function()
		Tween(btn, { BackgroundColor3 = Theme.AccentDark }, 0.06)
	end)
	btn.MouseButton1Up:Connect(function()
		Tween(btn, { BackgroundColor3 = hover }, 0.1)
	end)
end

-- ===================== SCREEN GUI =====================
local ScreenGui = Create("ScreenGui", {
	Name           = "RedObsidian",
	ResetOnSpawn   = false,
	IgnoreGuiInset = true,
	DisplayOrder   = 999,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

do
	if syn and syn.protect_gui then
		pcall(syn.protect_gui, ScreenGui)
	end

	local parent = CoreGui
	if gethui then
		local ok, result = pcall(gethui)
		if ok and result then
			parent = result
		end
	end

	-- hapus instance lama kalau script dieksekusi ulang
	pcall(function()
		local old = parent:FindFirstChild("RedObsidian")
		if old then old:Destroy() end
	end)

	local ok = pcall(function()
		ScreenGui.Parent = parent
	end)
	if not ok then
		ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
end

-- ===================== TOOLTIP =====================
local function AddTooltip(element, text)
	if not text or text == "" then return end

	local tip

	local function Remove()
		if tip then
			tip:Destroy()
			tip = nil
		end
	end

	local function Move()
		if not tip then return end
		local mouse  = UserInputService:GetMouseLocation()
		local screen = ScreenGui.AbsoluteSize
		local x = math.min(mouse.X + 12, screen.X - tip.AbsoluteSize.X - 4)
		tip.Position = UDim2.fromOffset(x, mouse.Y + 14)
	end

	element.MouseEnter:Connect(function()
		Remove()
		tip = NewLabel({
			Size                   = UDim2.fromOffset(0, 22),
			AutomaticSize          = Enum.AutomaticSize.X,
			BackgroundTransparency = 0,
			BackgroundColor3       = Theme.Surface,
			Text                   = text,
			TextSize               = 12,
			ZIndex                 = 2000,
			Parent                 = ScreenGui,
		})
		Padding(tip, 0, 7, 0, 7)
		Stroke(tip, Theme.Border, 1)
		Move()
	end)

	element.MouseMoved:Connect(Move)
	element.MouseLeave:Connect(Remove)
end

-- ===================== DRAG (dipakai Main & Floating Toggle) =====================
local function MakeDraggable(target, handle, opts)
	opts = opts or {}

	local threshold = opts.Threshold or 0
	local dragging, moved = false, false
	local dragStart, startPos, startAbs, dragInput

	handle.InputBegan:Connect(function(input)
		if not IsPress(input) then return end
		dragging  = true
		moved     = false
		dragInput = input
		dragStart = input.Position
		startPos  = target.Position
		startAbs  = target.AbsolutePosition
	end)

	Track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
		local isTouch = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
		if not (isMouse or isTouch) then return end

		local delta = input.Position - dragStart
		if not moved and delta.Magnitude < threshold then return end
		moved = true

		if opts.IsLocked and opts.IsLocked() then return end

		-- clamp supaya tidak keluar layar
		local screen = ScreenGui.AbsoluteSize
		local size   = target.AbsoluteSize
		local dx = math.clamp(startAbs.X + delta.X, 0, math.max(screen.X - size.X, 0)) - startAbs.X
		local dy = math.clamp(startAbs.Y + delta.Y, 0, math.max(screen.Y - size.Y, 0)) - startAbs.Y

		target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + dx,
			startPos.Y.Scale, startPos.Y.Offset + dy
		)
	end))

	Track(UserInputService.InputEnded:Connect(function(input)
		if not dragging or not IsPress(input) then return end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= dragInput then return end

		dragging = false
		if not moved and opts.OnClick then
			SafeCall(opts.OnClick)
		end
	end))
end

-- ===================== NOTIFY =====================
local NotifyHolders = {}

local function GetNotifyHolder(side)
	local existing = NotifyHolders[side]
	if existing and existing.Parent then
		return existing
	end

	local isLeft = side == "Left"
	local holder = NewFrame({
		Name                   = "Notifications" .. side,
		Size                   = UDim2.new(0, 240, 1, -16),
		Position               = UDim2.new(isLeft and 0 or 1, isLeft and 10 or -10, 0, 0),
		AnchorPoint            = Vector2.new(isLeft and 0 or 1, 0),
		BackgroundTransparency = 1,
		ZIndex                 = 900,
		Parent                 = ScreenGui,
	})
	Create("UIListLayout", {
		Padding             = UDim.new(0, 6),
		SortOrder           = Enum.SortOrder.LayoutOrder,
		VerticalAlignment   = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = isLeft and Enum.HorizontalAlignment.Left or Enum.HorizontalAlignment.Right,
		Parent              = holder,
	})

	NotifyHolders[side] = holder
	return holder
end

function Library:Notify(text, duration, side)
	if Library.Unloaded then return end

	duration = duration or 3
	side = side == "Left" and "Left" or "Right"
	local isLeft  = side == "Left"
	local hiddenX = isLeft and -1.3 or 1.3

	local Wrapper = NewFrame({
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent                 = GetNotifyHolder(side),
	})

	local Card = NewFrame({
		Size             = UDim2.new(1, 0, 0, 0),
		AutomaticSize    = Enum.AutomaticSize.Y,
		Position         = UDim2.new(hiddenX, 0, 0, 0),
		BackgroundColor3 = Theme.Surface,
		Parent           = Wrapper,
	})
	Stroke(Card, Theme.Border, 1)

	local Bar = NewFrame({
		Size   = UDim2.new(0, 2, 1, 0),
		Parent = Card,
	})
	Paint(Bar, "BackgroundColor3", "Accent")

	local Message = NewLabel({
		Size          = UDim2.new(1, -18, 0, 0),
		Position      = UDim2.fromOffset(12, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text          = tostring(text),
		TextSize      = 12,
		TextWrapped   = true,
		Parent        = Card,
	})
	Padding(Message, 8, 0, 8, 0)

	Tween(Card, { Position = UDim2.new(0, 0, 0, 0) }, 0.25)

	task.delay(duration, function()
		if not Card.Parent then return end
		Tween(Card, { Position = UDim2.new(hiddenX, 0, 0, 0) }, 0.25)
		task.wait(0.3)
		Wrapper:Destroy()
	end)
end

-- ===================== KONFIRMASI (POPUP) =====================
local function ShowConfirm(opts)
	if ConfirmOpen or Library.Unloaded then return end
	ConfirmOpen = true

	local Overlay = NewButton({
		Name                   = "ConfirmOverlay",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		Text                   = "",
		ZIndex                 = 1000,
		Parent                 = ScreenGui,
	})

	local Dialog = NewFrame({
		Name             = "ConfirmDialog",
		Size             = UDim2.fromOffset(280, 128),
		Position         = UDim2.fromScale(0.5, 0.5),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		ZIndex           = 1001,
		Parent           = Overlay,
	})
	Stroke(Dialog, Theme.Border, 1)

	local Scale = Create("UIScale", { Scale = 0.92, Parent = Dialog })

	local TopLine = NewFrame({
		Size   = UDim2.new(1, 0, 0, 2),
		ZIndex = 1002,
		Parent = Dialog,
	})
	Paint(TopLine, "BackgroundColor3", "Accent")

	NewLabel({
		Size           = UDim2.new(1, -20, 0, 20),
		Position       = UDim2.fromOffset(10, 10),
		Text           = opts.Title or "CONFIRM",
		Font           = Theme.FontTitle,
		TextSize       = 14,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex         = 1002,
		Parent         = Dialog,
	})

	NewLabel({
		Size           = UDim2.new(1, -28, 0, 36),
		Position       = UDim2.fromOffset(14, 36),
		Text           = opts.Text or "Are you sure?",
		TextColor3     = Theme.TextDim,
		TextSize       = 13,
		TextWrapped    = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex         = 1002,
		Parent         = Dialog,
	})

	local YesBtn = NewButton({
		Size             = UDim2.fromOffset(110, 28),
		Position         = UDim2.new(0.5, -116, 1, -38),
		BackgroundColor3 = Theme.AccentDark,
		Text             = opts.Yes or "Yes",
		ZIndex           = 1002,
		Parent           = Dialog,
	})
	local YesStroke = Stroke(YesBtn, Theme.Accent, 1)

	local NoBtn = NewButton({
		Size             = UDim2.fromOffset(110, 28),
		Position         = UDim2.new(0.5, 6, 1, -38),
		BackgroundColor3 = Theme.SurfaceLight,
		Text             = opts.No or "No",
		ZIndex           = 1002,
		Parent           = Dialog,
	})
	local NoStroke = Stroke(NoBtn, Theme.Border, 1)

	YesBtn.MouseEnter:Connect(function()
		Tween(YesBtn, { BackgroundColor3 = Theme.Accent }, 0.12)
	end)
	YesBtn.MouseLeave:Connect(function()
		Tween(YesBtn, { BackgroundColor3 = Theme.AccentDark }, 0.12)
	end)
	ButtonStyle(NoBtn, NoStroke, Theme.SurfaceLight, Color3.fromRGB(38, 38, 44))

	-- animasi masuk
	Tween(Overlay, { BackgroundTransparency = 0.45 }, 0.15)
	Tween(Scale, { Scale = 1 }, 0.15)

	YesBtn.MouseButton1Click:Connect(function()
		ConfirmOpen = false
		SafeCall(opts.OnYes)
	end)

	NoBtn.MouseButton1Click:Connect(function()
		Tween(Overlay, { BackgroundTransparency = 1 }, 0.12)
		Tween(Scale, { Scale = 0.92 }, 0.12)
		task.delay(0.13, function()
			Overlay:Destroy()
			ConfirmOpen = false
			SafeCall(opts.OnNo)
		end)
	end)
end

-- ===================== FLOATING TOGGLE =====================
--[[
	- Teks tetap "Toggle" (bawaan library)
	- Hitam polos, teks putih polos
	- Klik  = buka/tutup MainFrame
	- Drag  = pindah posisi (ada threshold supaya klik tidak salah trigger)
	- Lock  = kunci posisi (klik tetap berfungsi)
]]
local function CreateFloatingToggle(Main, startPos)
	local locked = false

	local Holder = NewFrame({
		Name                   = "FloatingToggle",
		Size                   = UDim2.fromOffset(88, 30),
		Position               = startPos,
		BackgroundTransparency = 1,
		ZIndex                 = 100,
		Parent                 = ScreenGui,
	})

	local Btn = NewButton({
		Name             = "Toggle",
		Size             = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		Text             = "Toggle",
		TextColor3       = Color3.new(1, 1, 1),
		TextSize         = 14,
		ZIndex           = 100,
		Parent           = Holder,
	})
	Padding(Btn, 0, 16, 0, 0) -- ruang untuk ikon lock
	local BtnStroke = Stroke(Btn, Theme.Border, 1)

	local LockBtn = NewButton({
		Name                   = "Lock",
		Size                   = UDim2.fromOffset(16, 16),
		Position               = UDim2.new(1, -19, 0.5, 0),
		AnchorPoint            = Vector2.new(0, 0.5),
		BackgroundTransparency = 1,
		Text                   = "🔓",
		TextColor3             = Color3.new(1, 1, 1),
		Font                   = Theme.Font,
		TextSize               = 11,
		ZIndex                 = 101,
		Parent                 = Holder,
	})

	-- border merah tipis saat MainFrame sedang terbuka
	local function RefreshStroke()
		Tween(BtnStroke, { Color = Main.Visible and Theme.Accent or Theme.Border }, 0.15)
	end
	Main:GetPropertyChangedSignal("Visible"):Connect(RefreshStroke)
	table.insert(ThemeHooks, RefreshStroke)
	RefreshStroke()

	MakeDraggable(Holder, Btn, {
		Threshold = 6,
		IsLocked  = function() return locked end,
		OnClick   = function() Main.Visible = not Main.Visible end,
	})

	LockBtn.MouseButton1Click:Connect(function()
		locked = not locked
		LockBtn.Text = locked and "🔒" or "🔓"
		Library:Notify(locked and "Toggle button locked" or "Toggle button unlocked", 1.5)
	end)

	return Btn
end

-- ===================== SHARED ELEMENT HELPERS =====================
local function MakeDependency(element, flag)
	if not flag then return end

	local toggle = Library.Toggles[flag]
	if not toggle then return end

	local function Update()
		local show = toggle:GetValue()
		if element.SetVisible then
			element:SetVisible(show)
		elseif element.Instance then
			element.Instance.Visible = show
		end
	end

	toggle:OnChanged(Update)
	Update()
end

-- Dipakai Toggle & Checkbox supaya logika state tidak dobel
local function NewToggleObject(id, opts, holder, render)
	local state     = opts.Default == true
	local callbacks = {}
	local Obj       = { Value = state }

	local function Set(value, silent)
		state     = value and true or false
		Obj.Value = state
		Library.Flags[id] = state
		render(state, false)

		if not silent then
			SafeCall(opts.Callback, state)
			for _, cb in ipairs(callbacks) do
				SafeCall(cb, state)
			end
		end
	end

	function Obj:SetValue(value, silent) Set(value, silent) end
	function Obj:GetValue() return state end
	function Obj:OnChanged(cb) table.insert(callbacks, cb) end
	function Obj:SetVisible(v) holder.Visible = v end

	Library.Toggles[id] = Obj
	Library.Flags[id]   = state

	render(state, true)
	table.insert(ThemeHooks, function()
		render(state, true)
	end)

	return Obj, Set
end

-- ===================== WINDOW =====================
function Library:CreateWindow(options)
	options = options or {}

	local title      = options.Title or "RedObsidian"
	local footerText = options.Footer or Library.Version
	local size       = options.Size or UDim2.fromOffset(460, 310)
	local toggleKey  = options.ToggleKeybind or Enum.KeyCode.RightControl
	local floatPos   = options.FloatPosition or UDim2.new(0, 16, 0.42, 0)

	local Window = {
		Tabs       = {},
		CurrentTab = nil,
	}

	-- Main Frame
	local Main = NewFrame({
		Name             = "Main",
		Size             = size,
		Position         = UDim2.fromScale(0.5, 0.5),
		AnchorPoint      = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		Parent           = ScreenGui,
	})
	Stroke(Main, Theme.Border, 1)

	-- Title Bar
	local TitleBar = NewFrame({
		Name             = "TitleBar",
		Size             = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Theme.Surface,
		Parent           = Main,
	})

	local TitleLine = NewFrame({
		Size     = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		Parent   = TitleBar,
	})
	Paint(TitleLine, "BackgroundColor3", "Accent")

	local TitleDot = NewFrame({
		Size     = UDim2.fromOffset(6, 6),
		Position = UDim2.fromOffset(10, 12),
		Parent   = TitleBar,
	})
	Paint(TitleDot, "BackgroundColor3", "Accent")

	local TitleLabel = NewLabel({
		Size     = UDim2.new(1, -60, 1, 0),
		Position = UDim2.fromOffset(24, 0),
		Text     = title,
		Font     = Theme.FontTitle,
		TextSize = 14,
		Parent   = TitleBar,
	})

	local CloseBtn = NewButton({
		Name             = "Close",
		Size             = UDim2.fromOffset(22, 22),
		Position         = UDim2.new(1, -28, 0.5, -11),
		BackgroundColor3 = Theme.SurfaceLight,
		Text             = "X",
		TextSize         = 13,
		Parent           = TitleBar,
	})
	local CloseStroke = Stroke(CloseBtn, Theme.Border, 1)
	ButtonStyle(CloseBtn, CloseStroke, Theme.SurfaceLight, Theme.AccentDark)

	CloseBtn.MouseButton1Click:Connect(function()
		ShowConfirm({
			Title = "CONFIRM",
			Text  = "Are you sure you want to delete this UI?",
			Yes   = "Yes",
			No    = "No",
			OnYes = function()
				Library:Unload()
			end,
		})
	end)

	MakeDraggable(Main, TitleBar)

	-- Sidebar
	local Sidebar = NewFrame({
		Name             = "Sidebar",
		Size             = UDim2.new(0, 112, 1, -30),
		Position         = UDim2.fromOffset(0, 30),
		BackgroundColor3 = Theme.Surface,
		Parent           = Main,
	})
	NewFrame({
		Size             = UDim2.new(0, 1, 1, 0),
		Position         = UDim2.new(1, -1, 0, 0),
		BackgroundColor3 = Theme.Border,
		Parent           = Sidebar,
	})

	local TabList = Create("ScrollingFrame", {
		Size                = UDim2.new(1, -1, 1, -22),
		BackgroundTransparency = 1,
		BorderSizePixel     = 0,
		ScrollBarThickness  = 2,
		ScrollingDirection  = Enum.ScrollingDirection.Y,
		CanvasSize          = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent              = Sidebar,
	})
	Paint(TabList, "ScrollBarImageColor3", "Accent")
	List(TabList, 3)
	Padding(TabList, 6, 6, 6, 6)

	local FooterLabel = NewLabel({
		Size           = UDim2.new(1, -1, 0, 22),
		Position       = UDim2.new(0, 0, 1, -22),
		Text           = footerText,
		TextColor3     = Theme.TextDim,
		TextSize       = 11,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent         = Sidebar,
	})
	NewFrame({
		Size             = UDim2.new(1, -1, 0, 1),
		Position         = UDim2.new(0, 0, 1, -22),
		BackgroundColor3 = Theme.Border,
		Parent           = Sidebar,
	})

	-- Content
	local Content = NewFrame({
		Name                   = "Content",
		Size                   = UDim2.new(1, -128, 1, -46),
		Position               = UDim2.fromOffset(120, 38),
		BackgroundTransparency = 1,
		Parent                 = Main,
	})

	-- Keyboard toggle
	Track(UserInputService.InputBegan:Connect(function(input, processed)
		if processed or ConfirmOpen then return end
		if input.KeyCode == toggleKey then
			Main.Visible = not Main.Visible
		end
	end))

	-- Floating Toggle
	local FloatBtn = CreateFloatingToggle(Main, floatPos)

	function Window:SetFooter(text) FooterLabel.Text = tostring(text) end
	function Window:SetTitle(text) TitleLabel.Text = tostring(text) end
	function Window:GetFloatingButton() return FloatBtn end
	function Window:SetVisible(v) Main.Visible = v and true or false end
	function Window:Toggle() Main.Visible = not Main.Visible end
	function Window:Unload() Library:Unload() end

	-- ===================== TAB =====================
	function Window:AddTab(name)
		local Tab        = { Name = name }
		local groupOrder = 0

		local TabBtn = NewButton({
			Size                   = UDim2.new(1, 0, 0, 26),
			BackgroundColor3       = Theme.SurfaceLight,
			BackgroundTransparency = 1,
			Text                   = "  " .. name,
			TextColor3             = Theme.TextDim,
			TextSize               = 13,
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			LayoutOrder            = #Window.Tabs + 1,
			Parent                 = TabList,
		})

		local Indicator = NewFrame({
			Size    = UDim2.new(0, 2, 1, 0),
			Visible = false,
			Parent  = TabBtn,
		})
		Paint(Indicator, "BackgroundColor3", "Accent")

		local Page = Create("ScrollingFrame", {
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			ScrollBarThickness     = 3,
			ScrollingDirection     = Enum.ScrollingDirection.Y,
			CanvasSize             = UDim2.new(),
			AutomaticCanvasSize    = Enum.AutomaticSize.Y,
			Visible                = false,
			Parent                 = Content,
		})
		Paint(Page, "ScrollBarImageColor3", "Accent")
		List(Page, 8)
		Padding(Page, 0, 6, 4, 0)

		-- Warning Box
		local WarningBox = NewFrame({
			Size             = UDim2.new(1, 0, 0, 0),
			AutomaticSize    = Enum.AutomaticSize.Y,
			BackgroundColor3 = Color3.fromRGB(30, 17, 19),
			LayoutOrder      = 0,
			Visible          = false,
			Parent           = Page,
		})
		Stroke(WarningBox, Theme.AccentDark, 1)
		List(WarningBox, 2)
		Padding(WarningBox, 8, 10, 8, 10)

		local WarningTitle = NewLabel({
			Size        = UDim2.new(1, 0, 0, 16),
			Text        = "WARNING",
			Font        = Theme.FontTitle,
			LayoutOrder = 1,
			Parent      = WarningBox,
		})
		Paint(WarningTitle, "TextColor3", "AccentSoft")

		local WarningText = NewLabel({
			Size          = UDim2.new(1, 0, 0, 14),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text          = "",
			TextSize      = 12,
			TextWrapped   = true,
			LayoutOrder   = 2,
			Parent        = WarningBox,
		})

		function Tab:UpdateWarningBox(data)
			if data and data.Visible then
				WarningBox.Visible = true
				WarningTitle.Text  = string.upper(data.Title or "Warning")
				WarningText.Text   = data.Text or ""
			else
				WarningBox.Visible = false
			end
		end

		local function SetSelected(on)
			Page.Visible                   = on
			Indicator.Visible              = on
			TabBtn.BackgroundTransparency  = on and 0 or 1
			TabBtn.TextColor3              = on and Theme.Text or Theme.TextDim
		end

		TabBtn.MouseButton1Click:Connect(function()
			for _, t in ipairs(Window.Tabs) do
				t._SetSelected(false)
			end
			SetSelected(true)
			Window.CurrentTab = Tab
		end)

		TabBtn.MouseEnter:Connect(function()
			if Window.CurrentTab ~= Tab then
				TabBtn.TextColor3 = Theme.Text
			end
		end)
		TabBtn.MouseLeave:Connect(function()
			if Window.CurrentTab ~= Tab then
				TabBtn.TextColor3 = Theme.TextDim
			end
		end)

		Tab.Page         = Page
		Tab.Button       = TabBtn
		Tab.Indicator    = Indicator
		Tab._SetSelected = SetSelected
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			SetSelected(true)
			Window.CurrentTab = Tab
		end

		-- ===================== GROUPBOX =====================
		function Tab:AddGroupbox(groupTitle)
			groupOrder = groupOrder + 1

			local Box = NewFrame({
				Name             = "Groupbox",
				Size             = UDim2.new(1, 0, 0, 0),
				AutomaticSize    = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Surface,
				LayoutOrder      = groupOrder,
				Parent           = Page,
			})
			Stroke(Box, Theme.Border, 1)
			List(Box, 0)

			local Header = NewFrame({
				Size                   = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				LayoutOrder            = 1,
				Parent                 = Box,
			})
			local HeaderDot = NewFrame({
				Size     = UDim2.fromOffset(4, 4),
				Position = UDim2.fromOffset(9, 10),
				Parent   = Header,
			})
			Paint(HeaderDot, "BackgroundColor3", "Accent")
			NewLabel({
				Size     = UDim2.new(1, -24, 1, 0),
				Position = UDim2.fromOffset(20, 0),
				Text     = groupTitle,
				Font     = Theme.FontTitle,
				TextSize = 13,
				Parent   = Header,
			})
			NewFrame({
				Size             = UDim2.new(1, 0, 0, 1),
				Position         = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.Border,
				Parent           = Header,
			})

			local Container = NewFrame({
				Size                   = UDim2.new(1, 0, 0, 0),
				AutomaticSize          = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder            = 2,
				Parent                 = Box,
			})
			List(Container, 6)
			Padding(Container, 8, 8, 8, 8)

			local Group = {}

			-- ---------- Label ----------
			function Group:AddLabel(text)
				local label = NewLabel({
					Size          = UDim2.new(1, 0, 0, 14),
					AutomaticSize = Enum.AutomaticSize.Y,
					Text          = tostring(text),
					TextColor3    = Theme.TextDim,
					TextSize      = 12,
					TextWrapped   = true,
					Parent        = Container,
				})
				return {
					Instance   = label,
					SetText    = function(_, t) label.Text = tostring(t) end,
					SetVisible = function(_, v) label.Visible = v end,
				}
			end

			-- ---------- Divider ----------
			function Group:AddDivider()
				return NewFrame({
					Size             = UDim2.new(1, 0, 0, 1),
					BackgroundColor3 = Theme.Border,
					Parent           = Container,
				})
			end

			-- ---------- Button (+ SubButton) ----------
			function Group:AddButton(opts)
				opts = type(opts) == "table" and opts or { Text = tostring(opts) }

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 0),
					AutomaticSize          = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent                 = Container,
				})
				List(Holder, 4)

				local Btn = NewButton({
					Size             = UDim2.new(1, 0, 0, 26),
					BackgroundColor3 = Theme.SurfaceLight,
					Text             = opts.Text or "Button",
					LayoutOrder      = 1,
					Parent           = Holder,
				})
				local BtnStroke = Stroke(Btn, Theme.Border, 1)
				ButtonStyle(Btn, BtnStroke, Theme.SurfaceLight, Color3.fromRGB(38, 38, 44))
				AddTooltip(Btn, opts.Tooltip)

				Btn.MouseButton1Click:Connect(function()
					SafeCall(opts.Func or opts.Callback)
				end)

				local ButtonObj = { Instance = Holder }
				local subCount  = 1

				function ButtonObj:AddButton(subOpts)
					subOpts  = type(subOpts) == "table" and subOpts or { Text = tostring(subOpts) }
					subCount = subCount + 1

					local Sub = NewButton({
						Size             = UDim2.new(1, 0, 0, 22),
						BackgroundColor3 = Theme.Background,
						Text             = subOpts.Text or "Sub",
						TextSize         = 12,
						LayoutOrder      = subCount,
						Parent           = Holder,
					})
					local SubStroke = Stroke(Sub, Theme.Border, 1)
					ButtonStyle(Sub, SubStroke, Theme.Background, Theme.SurfaceLight)
					AddTooltip(Sub, subOpts.Tooltip)

					Sub.MouseButton1Click:Connect(function()
						SafeCall(subOpts.Func or subOpts.Callback)
					end)

					return Sub
				end

				function ButtonObj:SetText(t) Btn.Text = tostring(t) end
				function ButtonObj:SetVisible(v) Holder.Visible = v end

				MakeDependency(ButtonObj, opts.Flag)
				return ButtonObj
			end

			-- ---------- Toggle ----------
			function Group:AddToggle(id, opts)
				opts = opts or {}

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Parent                 = Container,
				})
				NewLabel({
					Size   = UDim2.new(1, -44, 1, 0),
					Text   = opts.Text or id,
					Parent = Holder,
				})

				local Rail = NewFrame({
					Size             = UDim2.fromOffset(32, 16),
					Position         = UDim2.new(1, -32, 0.5, -8),
					BackgroundColor3 = Theme.Background,
					Parent           = Holder,
				})
				local RailStroke = Stroke(Rail, Theme.Border, 1)

				local Knob = NewFrame({
					Size             = UDim2.fromOffset(12, 12),
					Position         = UDim2.fromOffset(2, 2),
					BackgroundColor3 = Theme.TextDim,
					Parent           = Rail,
				})

				local Hit = NewButton({
					Size                   = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text                   = "",
					ZIndex                 = 2,
					Parent                 = Holder,
				})

				local Obj, Set = NewToggleObject(id, opts, Holder, function(state, instant)
					local d = instant and 0 or 0.15
					Tween(Rail, { BackgroundColor3 = state and Theme.Accent or Theme.Background }, d)
					Tween(RailStroke, { Color = state and Theme.Accent or Theme.Border }, d)
					Tween(Knob, {
						Position         = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2),
						BackgroundColor3 = state and Theme.Text or Theme.TextDim,
					}, d)
				end)

				Hit.MouseButton1Click:Connect(function()
					Set(not Obj.Value)
				end)

				AddTooltip(Hit, opts.Tooltip)
				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- Checkbox ----------
			function Group:AddCheckbox(id, opts)
				opts = opts or {}

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Parent                 = Container,
				})

				local Box = NewFrame({
					Size             = UDim2.fromOffset(16, 16),
					Position         = UDim2.new(0, 0, 0.5, -8),
					BackgroundColor3 = Theme.Background,
					Parent           = Holder,
				})
				local BoxStroke = Stroke(Box, Theme.Border, 1)

				local Mark = NewFrame({
					Size             = UDim2.fromOffset(8, 8),
					Position         = UDim2.fromOffset(4, 4),
					BackgroundColor3 = Theme.Accent,
					Visible          = false,
					Parent           = Box,
				})

				NewLabel({
					Size     = UDim2.new(1, -26, 1, 0),
					Position = UDim2.fromOffset(24, 0),
					Text     = opts.Text or id,
					Parent   = Holder,
				})

				local Hit = NewButton({
					Size                   = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text                   = "",
					ZIndex                 = 2,
					Parent                 = Holder,
				})

				local Obj, Set = NewToggleObject(id, opts, Holder, function(state)
					Mark.Visible      = state
					Mark.BackgroundColor3 = Theme.Accent
					Tween(BoxStroke, { Color = state and Theme.Accent or Theme.Border }, 0.12)
				end)

				Hit.MouseButton1Click:Connect(function()
					Set(not Obj.Value)
				end)

				AddTooltip(Hit, opts.Tooltip)
				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- Slider ----------
			function Group:AddSlider(id, opts)
				opts = opts or {}

				local min      = opts.Min or 0
				local max      = opts.Max or 100
				local rounding = opts.Rounding or 0
				local suffix   = opts.Suffix or ""
				local mult     = 10 ^ rounding
				local value    = math.clamp(opts.Default or min, min, max)

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 38),
					BackgroundTransparency = 1,
					Parent                 = Container,
				})

				NewLabel({
					Size   = UDim2.new(1, -70, 0, 16),
					Text   = opts.Text or id,
					Parent = Holder,
				})

				local ValueLabel = NewLabel({
					Size           = UDim2.fromOffset(66, 16),
					Position       = UDim2.new(1, -66, 0, 0),
					Text           = "",
					Font           = Theme.FontTitle,
					TextSize       = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
					Parent         = Holder,
				})

				local Hit = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 18),
					Position               = UDim2.fromOffset(0, 20),
					BackgroundTransparency = 1,
					Parent                 = Holder,
				})

				local Rail = NewFrame({
					Size             = UDim2.new(1, 0, 0, 6),
					Position         = UDim2.new(0, 0, 0.5, -3),
					BackgroundColor3 = Theme.Background,
					Parent           = Hit,
				})
				Stroke(Rail, Theme.Border, 1)

				local Fill = NewFrame({
					Size   = UDim2.fromScale(0, 1),
					Parent = Rail,
				})
				Paint(Fill, "BackgroundColor3", "Accent")

				local function Format(v)
					local s = rounding > 0 and string.format("%." .. rounding .. "f", v) or tostring(v)
					return s .. suffix
				end

				local function Set(v, silent)
					v = math.clamp(tonumber(v) or min, min, max)
					v = math.floor(v * mult + 0.5) / mult

					local changed = v ~= value
					value = v

					Fill.Size       = UDim2.new((v - min) / math.max(max - min, 1e-9), 0, 1, 0)
					ValueLabel.Text = Format(v)
					Library.Flags[id] = v

					if changed and not silent then
						SafeCall(opts.Callback, v)
					end
				end

				local sliding, dragInput = false, nil

				local function FromX(x)
					local relative = math.clamp((x - Rail.AbsolutePosition.X) / math.max(Rail.AbsoluteSize.X, 1), 0, 1)
					Set(min + (max - min) * relative)
				end

				Hit.InputBegan:Connect(function(input)
					if IsPress(input) then
						sliding   = true
						dragInput = input
						FromX(input.Position.X)
					end
				end)

				Track(UserInputService.InputChanged:Connect(function(input)
					if not sliding then return end
					local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
					local isTouch = input.UserInputType == Enum.UserInputType.Touch and input == dragInput
					if isMouse or isTouch then
						FromX(input.Position.X)
					end
				end))

				Track(UserInputService.InputEnded:Connect(function(input)
					if sliding and IsPress(input) then
						sliding = false
					end
				end))

				Set(value, true)

				local Obj = {}
				function Obj:SetValue(v, silent) Set(v, silent) end
				function Obj:GetValue() return value end
				function Obj:SetVisible(v) Holder.Visible = v end

				Library.Options[id] = Obj
				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- Input ----------
			function Group:AddInput(id, opts)
				opts = opts or {}

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 0),
					AutomaticSize          = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent                 = Container,
				})
				List(Holder, 4)

				NewLabel({
					Size        = UDim2.new(1, 0, 0, 14),
					Text        = opts.Text or id,
					TextSize    = 12,
					LayoutOrder = 1,
					Parent      = Holder,
				})

				local Box = Create("TextBox", {
					Size              = UDim2.new(1, 0, 0, 24),
					BackgroundColor3  = Theme.Background,
					BorderSizePixel   = 0,
					Text              = opts.Default or "",
					PlaceholderText   = opts.Placeholder or "Type here...",
					PlaceholderColor3 = Theme.TextDim,
					TextColor3        = Theme.Text,
					Font              = Theme.Font,
					TextSize          = 13,
					TextXAlignment    = Enum.TextXAlignment.Left,
					ClearTextOnFocus  = opts.ClearTextOnFocus ~= false,
					LayoutOrder       = 2,
					Parent            = Holder,
				})
				Padding(Box, 0, 8, 0, 8)
				local BoxStroke = Stroke(Box, Theme.Border, 1)

				Box.Focused:Connect(function()
					Tween(BoxStroke, { Color = Theme.Accent }, 0.12)
				end)

				Box.FocusLost:Connect(function()
					Tween(BoxStroke, { Color = Theme.Border }, 0.12)
					Library.Flags[id] = Box.Text
					SafeCall(opts.Callback, Box.Text)
				end)

				local Obj = {}
				function Obj:SetValue(v, silent)
					Box.Text = tostring(v)
					Library.Flags[id] = Box.Text
					if not silent then
						SafeCall(opts.Callback, Box.Text)
					end
				end
				function Obj:GetValue() return Box.Text end
				function Obj:SetVisible(v) Holder.Visible = v end

				Library.Flags[id]   = Box.Text
				Library.Options[id] = Obj

				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- Dropdown ----------
			function Group:AddDropdown(id, opts)
				opts = opts or {}

				local multi  = opts.Multi == true
				local isPlayer = opts.SpecialType == "Player"
				local values = {}

				local function CollectPlayers()
					values = {}
					for _, player in ipairs(Players:GetPlayers()) do
						if not (opts.ExcludeLocalPlayer and player == LocalPlayer) then
							table.insert(values, player.Name)
						end
					end
				end

				if isPlayer then
					CollectPlayers()
				else
					for _, v in ipairs(opts.Values or { "Option 1", "Option 2" }) do
						table.insert(values, v)
					end
				end

				local selected
				if multi then
					selected = {}
					if type(opts.Default) == "table" then
						for _, v in ipairs(opts.Default) do
							table.insert(selected, v)
						end
					end
				else
					selected = opts.Default or values[1]
				end

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 0),
					AutomaticSize          = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent                 = Container,
				})
				List(Holder, 4)

				NewLabel({
					Size        = UDim2.new(1, 0, 0, 14),
					Text        = opts.Text or id,
					TextSize    = 12,
					LayoutOrder = 1,
					Parent      = Holder,
				})

				local Row = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					LayoutOrder            = 2,
					Parent                 = Holder,
				})

				local DropBtn = NewButton({
					Size             = UDim2.fromScale(1, 1),
					BackgroundColor3 = Theme.Background,
					Text             = "",
					Font             = Theme.Font,
					TextSize         = 12,
					TextXAlignment   = Enum.TextXAlignment.Left,
					TextTruncate     = Enum.TextTruncate.AtEnd,
					Parent           = Row,
				})
				Padding(DropBtn, 0, 24, 0, 8)
				local DropStroke = Stroke(DropBtn, Theme.Border, 1)
				ButtonStyle(DropBtn, DropStroke, Theme.Background, Theme.SurfaceLight)

				local Arrow = NewLabel({
					Size           = UDim2.new(0, 14, 1, 0),
					Position       = UDim2.new(1, -18, 0, 0),
					Text           = "+",
					TextColor3     = Theme.TextDim,
					Font           = Theme.FontTitle,
					TextSize       = 13,
					TextXAlignment = Enum.TextXAlignment.Center,
					ZIndex         = 2,
					Parent         = Row,
				})

				local ListFrame = Create("ScrollingFrame", {
					Size                = UDim2.new(1, 0, 0, 0),
					BackgroundColor3    = Theme.Background,
					BorderSizePixel     = 0,
					ScrollBarThickness  = 3,
					ScrollingDirection  = Enum.ScrollingDirection.Y,
					CanvasSize          = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					Visible             = false,
					LayoutOrder         = 3,
					Parent              = Holder,
				})
				Paint(ListFrame, "ScrollBarImageColor3", "Accent")
				Stroke(ListFrame, Theme.Border, 1)
				List(ListFrame, 2)
				Padding(ListFrame, 3, 3, 3, 3)

				local open = false

				local function DisplayText()
					if multi then
						return #selected > 0 and table.concat(selected, ", ") or "None"
					end
					return selected ~= nil and tostring(selected) or "None"
				end

				local function ListHeight()
					if #values == 0 then return 28 end
					return math.min(#values * 24 + 8, 128)
				end

				local function SetOpen(state)
					open = state
					Arrow.Text = open and "-" or "+"

					if open then
						ListFrame.Size = UDim2.new(1, 0, 0, 0)
						ListFrame.Visible = true
						Tween(ListFrame, { Size = UDim2.new(1, 0, 0, ListHeight()) }, 0.15)
					else
						Tween(ListFrame, { Size = UDim2.new(1, 0, 0, 0) }, 0.12)
						task.delay(0.13, function()
							if not open then
								ListFrame.Visible = false
							end
						end)
					end
				end

				local function Refresh()
					for _, child in ipairs(ListFrame:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end

					for index, value in ipairs(values) do
						local isSelected
						if multi then
							isSelected = table.find(selected, value) ~= nil
						else
							isSelected = selected == value
						end

						local Opt = NewButton({
							Size                   = UDim2.new(1, -4, 0, 22),
							BackgroundColor3       = isSelected and Theme.AccentDark or Theme.SurfaceLight,
							BackgroundTransparency = isSelected and 0 or 1,
							Text                   = tostring(value),
							TextColor3             = isSelected and Theme.Text or Theme.TextDim,
							Font                   = Theme.Font,
							TextSize               = 12,
							TextXAlignment         = Enum.TextXAlignment.Left,
							TextTruncate           = Enum.TextTruncate.AtEnd,
							LayoutOrder            = index,
							Parent                 = ListFrame,
						})
						Padding(Opt, 0, 4, 0, 8)

						Opt.MouseEnter:Connect(function()
							if not isSelected then
								Tween(Opt, { BackgroundTransparency = 0 }, 0.1)
							end
						end)
						Opt.MouseLeave:Connect(function()
							if not isSelected then
								Tween(Opt, { BackgroundTransparency = 1 }, 0.1)
							end
						end)

						Opt.MouseButton1Click:Connect(function()
							if multi then
								local idx = table.find(selected, value)
								if idx then
									table.remove(selected, idx)
								else
									table.insert(selected, value)
								end
							else
								selected = value
								SetOpen(false)
							end

							DropBtn.Text = DisplayText()
							Library.Flags[id] = selected
							Refresh()
							SafeCall(opts.Callback, selected)
						end)
					end

					if open then
						ListFrame.Size = UDim2.new(1, 0, 0, ListHeight())
					end
				end

				DropBtn.MouseButton1Click:Connect(function()
					SetOpen(not open)
				end)

				if isPlayer then
					local function Rebuild()
						CollectPlayers()
						Refresh()
					end
					Track(Players.PlayerAdded:Connect(function()
						task.delay(0.1, Rebuild)
					end))
					Track(Players.PlayerRemoving:Connect(function()
						task.delay(0.2, Rebuild)
					end))
				end

				DropBtn.Text = DisplayText()
				Library.Flags[id] = selected
				Refresh()

				local Obj = {}

				function Obj:SetValues(newValues)
					values = {}
					for _, v in ipairs(newValues or {}) do
						table.insert(values, v)
					end
					Refresh()
				end

				function Obj:SetValue(v, silent)
					if multi then
						selected = {}
						if type(v) == "table" then
							for _, item in ipairs(v) do
								table.insert(selected, item)
							end
						end
					else
						selected = v
					end
					DropBtn.Text = DisplayText()
					Library.Flags[id] = selected
					Refresh()
					if not silent then
						SafeCall(opts.Callback, selected)
					end
				end

				function Obj:GetValue() return selected end
				function Obj:SetVisible(v) Holder.Visible = v end

				Library.Options[id] = Obj
				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- Keybind ----------
			function Group:AddKeybind(id, opts)
				opts = opts or {}

				local currentKey = opts.Default or Enum.KeyCode.E
				local listening  = false

				local function ResolveKey(v)
					if typeof(v) == "EnumItem" then
						return v
					end
					if type(v) == "string" then
						local ok, key = pcall(function()
							return Enum.KeyCode[v]
						end)
						if ok then return key end
					end
					return nil
				end

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					Parent                 = Container,
				})

				NewLabel({
					Size   = UDim2.new(1, -78, 1, 0),
					Text   = opts.Text or id,
					Parent = Holder,
				})

				local KeyBtn = NewButton({
					Size             = UDim2.fromOffset(70, 20),
					Position         = UDim2.new(1, -70, 0.5, -10),
					BackgroundColor3 = Theme.Background,
					Text             = currentKey.Name,
					TextSize         = 12,
					TextTruncate     = Enum.TextTruncate.AtEnd,
					Parent           = Holder,
				})
				local KeyStroke = Stroke(KeyBtn, Theme.Border, 1)

				local function Set(key, silent)
					key = ResolveKey(key)
					if not key then return end
					currentKey = key
					KeyBtn.Text = key.Name
					Library.Flags[id] = key.Name
					if not silent then
						SafeCall(opts.Callback, key)
					end
				end

				KeyBtn.MouseButton1Click:Connect(function()
					listening = true
					KeyBtn.Text = "..."
					Tween(KeyStroke, { Color = Theme.Accent }, 0.12)
				end)

				Track(UserInputService.InputBegan:Connect(function(input, processed)
					if listening then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							listening = false
							Tween(KeyStroke, { Color = Theme.Border }, 0.12)
							if input.KeyCode == Enum.KeyCode.Escape then
								KeyBtn.Text = currentKey.Name -- batal
							else
								Set(input.KeyCode)
							end
						end
						return
					end

					if not processed and opts.Pressed and input.KeyCode == currentKey then
						SafeCall(opts.Pressed, currentKey)
					end
				end))

				local Obj = {}
				function Obj:SetValue(key, silent) Set(key, silent) end
				function Obj:GetValue() return currentKey end
				function Obj:SetVisible(v) Holder.Visible = v end

				Library.Flags[id]   = currentKey.Name
				Library.Options[id] = Obj

				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			-- ---------- ColorPicker ----------
			function Group:AddColorPicker(id, opts)
				opts = opts or {}

				local color = opts.Default or Theme.Accent

				local palette = {
					Color3.fromRGB(170, 48, 58),
					Color3.fromRGB(214, 120, 52),
					Color3.fromRGB(222, 190, 70),
					Color3.fromRGB(96, 180, 110),
					Color3.fromRGB(60, 170, 170),
					Color3.fromRGB(60, 120, 220),
					Color3.fromRGB(150, 90, 220),
					Color3.fromRGB(220, 100, 170),
					Color3.fromRGB(240, 240, 240),
					Color3.fromRGB(130, 130, 136),
					Color3.fromRGB(60, 60, 66),
					Color3.fromRGB(12, 12, 14),
				}

				local Holder = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 0),
					AutomaticSize          = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent                 = Container,
				})
				List(Holder, 4)

				local Row = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 22),
					BackgroundTransparency = 1,
					LayoutOrder            = 1,
					Parent                 = Holder,
				})

				NewLabel({
					Size   = UDim2.new(1, -40, 1, 0),
					Text   = opts.Text or id,
					Parent = Row,
				})

				local Preview = NewButton({
					Size             = UDim2.fromOffset(28, 14),
					Position         = UDim2.new(1, -28, 0.5, -7),
					BackgroundColor3 = color,
					Text             = "",
					Parent           = Row,
				})
				Stroke(Preview, Theme.Border, 1)

				local Palette = NewFrame({
					Size                   = UDim2.new(1, 0, 0, 0),
					AutomaticSize          = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Visible                = false,
					LayoutOrder            = 2,
					Parent                 = Holder,
				})
				Create("UIGridLayout", {
					CellSize    = UDim2.fromOffset(20, 20),
					CellPadding = UDim2.fromOffset(4, 4),
					SortOrder   = Enum.SortOrder.LayoutOrder,
					Parent      = Palette,
				})

				local function Set(c, silent)
					if type(c) == "table" then
						c = Color3.new(c.R or 0, c.G or 0, c.B or 0)
					end
					if typeof(c) ~= "Color3" then return end

					color = c
					Preview.BackgroundColor3 = c
					Library.Flags[id] = { R = c.R, G = c.G, B = c.B }
					if not silent then
						SafeCall(opts.Callback, c)
					end
				end

				for index, c in ipairs(palette) do
					local Swatch = NewButton({
						BackgroundColor3 = c,
						Text             = "",
						LayoutOrder      = index,
						Parent           = Palette,
					})
					Stroke(Swatch, Theme.Border, 1)
					Swatch.MouseButton1Click:Connect(function()
						Set(c)
						Palette.Visible = false
					end)
				end

				Preview.MouseButton1Click:Connect(function()
					Palette.Visible = not Palette.Visible
				end)

				local Obj = {}
				function Obj:SetValue(c, silent) Set(c, silent) end
				function Obj:GetValue() return color end
				function Obj:SetVisible(v) Holder.Visible = v end

				Library.Flags[id]   = { R = color.R, G = color.G, B = color.B }
				Library.Options[id] = Obj

				MakeDependency(Obj, opts.Flag)
				return Obj
			end

			return Group
		end

		function Tab:AddLeftGroupbox(groupTitle)
			return self:AddGroupbox(groupTitle)
		end

		function Tab:AddRightGroupbox(groupTitle)
			return self:AddGroupbox(groupTitle)
		end

		return Tab
	end

	return Window
end

-- ===================== CONFIG =====================
function Library:SaveConfig(name)
	name = name or "default"

	local data = {}
	for flag, value in pairs(Library.Flags) do
		data[flag] = value
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then
		Library:Notify("Failed to encode config", 2)
		return
	end

	if writefile then
		writefile("RedObsidian_" .. name .. ".json", encoded)
		Library:Notify("Config \"" .. name .. "\" saved!", 2)
	else
		print("[RedObsidian] Config JSON:")
		print(encoded)
		Library:Notify("writefile not available (check F9)", 3)
	end
end

function Library:LoadConfig(name)
	name = name or "default"
	local path = "RedObsidian_" .. name .. ".json"

	if not (isfile and isfile(path)) then
		Library:Notify("Config not found", 2)
		return
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	if not (ok and type(data) == "table") then
		Library:Notify("Config is corrupted", 2)
		return
	end

	for flag, value in pairs(data) do
		local toggle = Library.Toggles[flag]
		local option = Library.Options[flag]
		if toggle then
			pcall(function() toggle:SetValue(value) end)
		elseif option then
			pcall(function() option:SetValue(value) end)
		end
	end

	Library:Notify("Config \"" .. name .. "\" loaded!", 2)
end

-- ===================== THEME ACCENT =====================
function Library:SetAccent(color)
	Theme.Accent     = color
	Theme.AccentSoft = color:Lerp(Color3.new(1, 1, 1), 0.25)
	Theme.AccentDark = color:Lerp(Color3.new(0, 0, 0), 0.4)

	for _, hook in ipairs(ThemeHooks) do
		pcall(hook)
	end

	Library:Notify("Accent color updated", 2)
end

-- ===================== UNLOAD =====================
-- Daftarkan fungsi cleanup milik script kamu (loop, connection, dll)
function Library:OnUnload(fn)
	table.insert(UnloadHooks, fn)
end

-- Hapus seluruh UI + reset semua fitur yang sedang aktif
function Library:Unload()
	if Library.Unloaded then return end
	Library.Unloaded = true

	-- 1) Matikan semua toggle/checkbox yang aktif (callback dipanggil dengan false)
	for _, toggle in pairs(Library.Toggles) do
		if toggle:GetValue() then
			pcall(function() toggle:SetValue(false) end)
		end
	end

	-- 2) Cleanup dari script pemakai
	for _, fn in ipairs(UnloadHooks) do
		SafeCall(fn)
	end

	-- 3) Putus semua koneksi milik library
	for _, connection in ipairs(Connections) do
		pcall(function() connection:Disconnect() end)
	end

	-- 4) Hapus semua GUI (MainFrame, floating toggle, notif, popup)
	ScreenGui:Destroy()

	-- 5) Bersihkan state
	table.clear(Connections)
	table.clear(UnloadHooks)
	table.clear(ThemeHooks)
	table.clear(Library.Toggles)
	table.clear(Library.Options)
	table.clear(Library.Flags)
	table.clear(NotifyHolders)
end

return Library
