--[[
	RedObsidian UI Library v5.2
	Professional • Clean • Stable

	Warna     : Merah Merona
	Font      : Gotham
	Struktur  : Mirip Obsidian UI

	Fitur Bawaan:
	- Floating Toggle Button (teks default = "Toggle")
	- Lock pada Floating Button (🔓/🔒) → kunci posisi agar tidak bisa digeser
	- Window, Tab, Groupbox
	- Label, Divider, Button + SubButton
	- Toggle, Checkbox, Slider, Input
	- Dropdown (Single / Multi / Player)
	- Keybind, ColorPicker
	- Tooltip, Notify, WarningBox
	- SaveManager / LoadConfig
	- Dependency System
	- Theme Accent (SetAccent)
]]

local Library = {}
Library.__index = Library

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ===================== THEME =====================
local Theme = {
	Background   = Color3.fromRGB(18, 10, 12),
	Surface      = Color3.fromRGB(28, 15, 18),
	SurfaceLight = Color3.fromRGB(40, 22, 26),
	Accent       = Color3.fromRGB(220, 55, 75),
	AccentSoft   = Color3.fromRGB(255, 115, 135),
	AccentDark   = Color3.fromRGB(150, 30, 50),
	Text         = Color3.fromRGB(245, 235, 235),
	TextDim      = Color3.fromRGB(175, 145, 150),
	Border       = Color3.fromRGB(55, 28, 35),
	Font         = Enum.Font.Gotham,
	FontBold     = Enum.Font.GothamBold,
}

Library.Flags   = {}
Library.Toggles = {}
Library.Options = {}

-- ===================== UTILS =====================
local function Create(class, props)
	local obj = Instance.new(class)
	for key, value in pairs(props or {}) do
		if key ~= "Parent" then
			obj[key] = value
		end
	end
	if props and props.Parent then
		obj.Parent = props.Parent
	end
	return obj
end

local function Tween(obj, props, duration)
	local tw = TweenService:Create(
		obj,
		TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function AddTooltip(element, text)
	if not text or text == "" then return end

	local tip
	element.MouseEnter:Connect(function()
		tip = Create("TextLabel", {
			Size               = UDim2.fromOffset(0, 24),
			AutomaticSize      = Enum.AutomaticSize.X,
			BackgroundColor3   = Theme.SurfaceLight,
			Text               = "  " .. text .. "  ",
			TextColor3         = Theme.Text,
			Font               = Theme.Font,
			TextSize           = 12,
			ZIndex             = 2000,
			Parent             = ScreenGui
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = tip })
		Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = tip })
	end)

	element.MouseMoved:Connect(function()
		if tip then
			tip.Position = UDim2.fromOffset(Mouse.X + 14, Mouse.Y + 14)
		end
	end)

	element.MouseLeave:Connect(function()
		if tip then
			tip:Destroy()
			tip = nil
		end
	end)
end

-- ===================== SCREEN GUI =====================
local ScreenGui = Create("ScreenGui", {
	Name               = "RedObsidian",
	ResetOnSpawn       = false,
	ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
	Parent             = (gethui and gethui()) or CoreGui
})

-- ===================== FLOATING TOGGLE BUTTON =====================
--[[
	Floating Toggle Button adalah bawaan library.
	- Teks default: "Toggle"
	- Klik = buka/tutup MainFrame
	- Bisa digeser
	- Ada tombol Lock kecil (🔓/🔒) untuk mengunci posisi
	- Drag vs Click dipisah dengan movement threshold (lebih stabil)
]]
local function CreateFloatingToggle(MainFrame, opts)
	opts = opts or {}

	local buttonText = opts.Text or "Toggle"
	local startPos   = opts.Position or UDim2.new(0, 20, 0.42, 0)

	local isLocked     = false
	local isDragging   = false
	local hasMoved     = false
	local dragStart    = nil
	local startPosition = nil
	local dragInput    = nil
	local DRAG_THRESHOLD = 6 -- pixel, biar klik tidak ketigger saat drag kecil

	-- Main Floating Button
	local FloatBtn = Create("TextButton", {
		Name             = "FloatingToggle",
		Size             = UDim2.fromOffset(72, 32),
		Position         = startPos,
		BackgroundColor3 = Theme.AccentDark,
		Text             = buttonText,
		TextColor3       = Theme.Text,
		Font             = Theme.FontBold,
		TextSize         = 13,
		AutoButtonColor  = false,
		ZIndex           = 100,
		Parent           = ScreenGui
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = FloatBtn })
	Create("UIStroke", { Color = Theme.Accent, Thickness = 1.4, Parent = FloatBtn })

	-- Small Lock Button
	local LockBtn = Create("TextButton", {
		Name             = "LockBtn",
		Size             = UDim2.fromOffset(18, 18),
		Position         = UDim2.new(1, -5, 0, -5),
		AnchorPoint      = Vector2.new(1, 0),
		BackgroundColor3 = Theme.SurfaceLight,
		Text             = "🔓",
		TextColor3       = Theme.Text,
		Font             = Theme.Font,
		TextSize         = 10,
		ZIndex           = 101,
		Parent           = FloatBtn
	})
	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = LockBtn })

	-- Hover effect
	FloatBtn.MouseEnter:Connect(function()
		if not isLocked then
			Tween(FloatBtn, { BackgroundColor3 = Theme.Accent }, 0.15)
		end
	end)

	FloatBtn.MouseLeave:Connect(function()
		Tween(FloatBtn, { BackgroundColor3 = Theme.AccentDark }, 0.15)
	end)

	-- Drag logic (dengan threshold)
	FloatBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isLocked then return end

			isDragging = true
			hasMoved = false
			dragStart = input.Position
			startPosition = FloatBtn.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					-- biarkan hasMoved tetap sampai click handler selesai
					task.defer(function()
						isDragging = false
						hasMoved = false
					end)
				end
			end)
		end
	end)

	FloatBtn.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and isDragging and not isLocked and dragStart then
			local delta = input.Position - dragStart
			local distance = math.sqrt(delta.X * delta.X + delta.Y * delta.Y)

			if distance > DRAG_THRESHOLD then
				hasMoved = true
				FloatBtn.Position = UDim2.new(
					startPosition.X.Scale,
					startPosition.X.Offset + delta.X,
					startPosition.Y.Scale,
					startPosition.Y.Offset + delta.Y
				)
			end
		end
	end)

	-- Click = Toggle MainFrame (hanya jika TIDAK digeser)
	FloatBtn.MouseButton1Click:Connect(function()
		if hasMoved or isLocked then return end
		MainFrame.Visible = not MainFrame.Visible
	end)

	-- Lock / Unlock
	LockBtn.MouseButton1Click:Connect(function()
		isLocked = not isLocked

		if isLocked then
			LockBtn.Text = "🔒"
			LockBtn.BackgroundColor3 = Theme.Accent
			Library:Notify("Floating Toggle dikunci", 1.5)
		else
			LockBtn.Text = "🔓"
			LockBtn.BackgroundColor3 = Theme.SurfaceLight
			Library:Notify("Floating Toggle dibuka", 1.5)
		end
	end)

	return FloatBtn
end

-- ===================== WINDOW =====================
function Library:CreateWindow(options)
	options = options or {}

	local title       = options.Title or "RedObsidian"
	local footerText  = options.Footer or "v5.2"
	local size        = options.Size or UDim2.fromOffset(660, 480)
	local toggleKey   = options.ToggleKeybind or Enum.KeyCode.RightControl
	local floatText   = options.FloatText or "Toggle"
	local floatPos    = options.FloatPosition or UDim2.new(0, 20, 0.42, 0)

	local Window = {
		Tabs = {},
		CurrentTab = nil
	}

	-- Main Frame
	local Main = Create("Frame", {
		Name               = "Main",
		Size               = size,
		Position           = UDim2.fromScale(0.5, 0.5),
		AnchorPoint        = Vector2.new(0.5, 0.5),
		BackgroundColor3   = Theme.Background,
		BorderSizePixel    = 0,
		Visible            = true,
		Parent             = ScreenGui
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Main })
	Create("UIStroke", { Color = Theme.Border, Thickness = 1.2, Parent = Main })

	-- Title Bar
	local TitleBar = Create("Frame", {
		Size               = UDim2.new(1, 0, 0, 40),
		BackgroundColor3   = Theme.Surface,
		BorderSizePixel    = 0,
		Parent             = Main
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = TitleBar })

	local TitleLabel = Create("TextLabel", {
		Size               = UDim2.new(1, -50, 1, 0),
		Position           = UDim2.fromOffset(14, 0),
		BackgroundTransparency = 1,
		Text               = title,
		TextColor3         = Theme.Text,
		Font               = Theme.FontBold,
		TextSize           = 15,
		TextXAlignment     = Enum.TextXAlignment.Left,
		Parent             = TitleBar
	})

	local CloseBtn = Create("TextButton", {
		Size               = UDim2.fromOffset(28, 28),
		Position           = UDim2.new(1, -34, 0.5, 0),
		AnchorPoint        = Vector2.new(0, 0.5),
		BackgroundColor3   = Theme.AccentDark,
		Text               = "×",
		TextColor3         = Theme.Text,
		Font               = Theme.FontBold,
		TextSize           = 18,
		Parent             = TitleBar
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })

	CloseBtn.MouseButton1Click:Connect(function()
		Main.Visible = false
	end)

	-- Drag Main Frame
	do
		local dragging, dragStart, startPos, dragInput

		TitleBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = input.Position
				startPos = Main.Position

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		TitleBar.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		UserInputService.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - dragStart
				Main.Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
			end
		end)
	end

	-- Sidebar
	local Sidebar = Create("Frame", {
		Size               = UDim2.new(0, 150, 1, -40),
		Position           = UDim2.fromOffset(0, 40),
		BackgroundColor3   = Theme.Surface,
		BorderSizePixel    = 0,
		Parent             = Main
	})

	local TabList = Create("ScrollingFrame", {
		Size               = UDim2.new(1, 0, 1, -34),
		BackgroundTransparency = 1,
		BorderSizePixel    = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize         = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent             = Sidebar
	})
	Create("UIListLayout", {
		Padding            = UDim.new(0, 4),
		SortOrder          = Enum.SortOrder.LayoutOrder,
		Parent             = TabList
	})
	Create("UIPadding", {
		PaddingTop         = UDim.new(0, 8),
		PaddingLeft        = UDim.new(0, 8),
		PaddingRight       = UDim.new(0, 8),
		Parent             = TabList
	})

	local FooterLabel = Create("TextLabel", {
		Size               = UDim2.new(1, 0, 0, 30),
		Position           = UDim2.new(0, 0, 1, -30),
		BackgroundColor3   = Theme.Surface,
		BorderSizePixel    = 0,
		Text               = footerText,
		TextColor3         = Theme.TextDim,
		Font               = Theme.Font,
		TextSize           = 11,
		Parent             = Sidebar
	})

	-- Content
	local Content = Create("Frame", {
		Size               = UDim2.new(1, -160, 1, -50),
		Position           = UDim2.fromOffset(155, 45),
		BackgroundTransparency = 1,
		Parent             = Main
	})

	-- Keyboard toggle
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == toggleKey then
			Main.Visible = not Main.Visible
		end
	end)

	-- Floating Toggle Button (bawaan, teks "Toggle")
	local FloatBtn = CreateFloatingToggle(Main, {
		Text     = floatText,
		Position = floatPos
	})

	function Window:SetFooter(text)
		FooterLabel.Text = tostring(text)
	end

	function Window:SetTitle(text)
		TitleLabel.Text = tostring(text)
	end

	function Window:GetFloatingButton()
		return FloatBtn
	end

	-- ===================== TAB =====================
	function Window:AddTab(name)
		local Tab = { Name = name }

		local TabBtn = Create("TextButton", {
			Size               = UDim2.new(1, 0, 0, 34),
			BackgroundColor3   = Theme.SurfaceLight,
			BackgroundTransparency = 1,
			Text               = "  " .. name,
			TextColor3         = Theme.TextDim,
			Font               = Theme.Font,
			TextSize           = 13,
			TextXAlignment     = Enum.TextXAlignment.Left,
			Parent             = TabList
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabBtn })

		local Indicator = Create("Frame", {
			Size               = UDim2.new(0, 3, 0.55, 0),
			Position           = UDim2.new(0, 0, 0.225, 0),
			BackgroundColor3   = Theme.Accent,
			BorderSizePixel    = 0,
			Visible            = false,
			Parent             = TabBtn
		})
		Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Indicator })

		local Page = Create("ScrollingFrame", {
			Size               = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel    = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = Theme.Accent,
			CanvasSize         = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Visible            = false,
			Parent             = Content
		})
		Create("UIListLayout", {
			Padding            = UDim.new(0, 10),
			SortOrder          = Enum.SortOrder.LayoutOrder,
			Parent             = Page
		})
		Create("UIPadding", {
			PaddingTop         = UDim.new(0, 4),
			PaddingBottom      = UDim.new(0, 12),
			PaddingLeft        = UDim.new(0, 2),
			PaddingRight       = UDim.new(0, 6),
			Parent             = Page
		})

		-- Warning Box
		local WarningBox = Create("Frame", {
			Size               = UDim2.new(1, 0, 0, 0),
			AutomaticSize      = Enum.AutomaticSize.Y,
			BackgroundColor3   = Color3.fromRGB(60, 20, 25),
			BorderSizePixel    = 0,
			Visible            = false,
			Parent             = Page
		})
		Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = WarningBox })
		Create("UIStroke", { Color = Theme.Accent, Thickness = 1, Parent = WarningBox })

		local WarningTitle = Create("TextLabel", {
			Size               = UDim2.new(1, -16, 0, 20),
			Position           = UDim2.fromOffset(10, 6),
			BackgroundTransparency = 1,
			Text               = "Warning",
			TextColor3         = Theme.AccentSoft,
			Font               = Theme.FontBold,
			TextSize           = 13,
			TextXAlignment     = Enum.TextXAlignment.Left,
			Parent             = WarningBox
		})

		local WarningText = Create("TextLabel", {
			Size               = UDim2.new(1, -16, 0, 0),
			Position           = UDim2.fromOffset(10, 26),
			AutomaticSize      = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Text               = "",
			TextColor3         = Theme.Text,
			Font               = Theme.Font,
			TextSize           = 12,
			TextXAlignment     = Enum.TextXAlignment.Left,
			TextWrapped        = true,
			Parent             = WarningBox
		})
		Create("UIPadding", { PaddingBottom = UDim.new(0, 8), Parent = WarningBox })

		function Tab:UpdateWarningBox(data)
			if data and data.Visible then
				WarningBox.Visible = true
				WarningTitle.Text = data.Title or "Warning"
				WarningText.Text  = data.Text or ""
			else
				WarningBox.Visible = false
			end
		end

		local function SelectTab()
			for _, t in pairs(Window.Tabs) do
				t.Page.Visible = false
				t.Button.BackgroundTransparency = 1
				t.Button.TextColor3 = Theme.TextDim
				t.Indicator.Visible = false
			end
			Page.Visible = true
			TabBtn.BackgroundTransparency = 0
			TabBtn.BackgroundColor3 = Theme.SurfaceLight
			TabBtn.TextColor3 = Theme.Text
			Indicator.Visible = true
			Window.CurrentTab = Tab
		end

		TabBtn.MouseButton1Click:Connect(SelectTab)

		Tab.Page = Page
		Tab.Button = TabBtn
		Tab.Indicator = Indicator
		table.insert(Window.Tabs, Tab)

		if #Window.Tabs == 1 then
			SelectTab()
		end

		-- ===================== GROUPBOX =====================
		function Tab:AddGroupbox(title)
			local Box = Create("Frame", {
				Size               = UDim2.new(1, 0, 0, 0),
				AutomaticSize      = Enum.AutomaticSize.Y,
				BackgroundColor3   = Theme.Surface,
				BorderSizePixel    = 0,
				Parent             = Page
			})
			Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Box })
			Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Box })

			Create("TextLabel", {
				Size               = UDim2.new(1, -16, 0, 28),
				Position           = UDim2.fromOffset(12, 4),
				BackgroundTransparency = 1,
				Text               = title,
				TextColor3         = Theme.AccentSoft,
				Font               = Theme.FontBold,
				TextSize           = 13,
				TextXAlignment     = Enum.TextXAlignment.Left,
				Parent             = Box
			})

			local Container = Create("Frame", {
				Size               = UDim2.new(1, -16, 0, 0),
				Position           = UDim2.fromOffset(8, 32),
				AutomaticSize      = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Parent             = Box
			})
			Create("UIListLayout", {
				Padding            = UDim.new(0, 7),
				SortOrder          = Enum.SortOrder.LayoutOrder,
				Parent             = Container
			})
			Create("UIPadding", { PaddingBottom = UDim.new(0, 10), Parent = Container })

			local Group = {}

			local function MakeDependency(element, flag)
				if not flag then return end
				local function Update()
					local toggle = Library.Toggles[flag]
					if toggle then
						local show = toggle.Value
						if element.SetVisible then
							element:SetVisible(show)
						elseif element.Instance then
							element.Instance.Visible = show
						end
					end
				end
				if Library.Toggles[flag] then
					Library.Toggles[flag]:OnChanged(Update)
					Update()
				end
			end

			function Group:AddLabel(text)
				local label = Create("TextLabel", {
					Size               = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Text               = text,
					TextColor3         = Theme.TextDim,
					Font               = Theme.Font,
					TextSize           = 12,
					TextXAlignment     = Enum.TextXAlignment.Left,
					TextWrapped        = true,
					Parent             = Container
				})
				return {
					Instance = label,
					SetVisible = function(_, v) label.Visible = v end
				}
			end

			function Group:AddDivider()
				return Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 1),
					BackgroundColor3   = Theme.Border,
					BorderSizePixel    = 0,
					Parent             = Container
				})
			end

			function Group:AddButton(opts)
				opts = type(opts) == "table" and opts or { Text = tostring(opts), Func = function() end }

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 0),
					AutomaticSize      = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Parent             = Container
				})
				Create("UIListLayout", { Padding = UDim.new(0, 4), Parent = Holder })

				local Btn = Create("TextButton", {
					Size               = UDim2.new(1, 0, 0, 32),
					BackgroundColor3   = Theme.AccentDark,
					Text               = opts.Text or "Button",
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Btn })
				AddTooltip(Btn, opts.Tooltip)

				Btn.MouseEnter:Connect(function()
					Tween(Btn, { BackgroundColor3 = Theme.Accent }, 0.15)
				end)
				Btn.MouseLeave:Connect(function()
					Tween(Btn, { BackgroundColor3 = Theme.AccentDark }, 0.15)
				end)
				Btn.MouseButton1Click:Connect(function()
					if opts.Func then
						opts.Func()
					end
				end)

				local ButtonObj = { Instance = Holder }

				function ButtonObj:AddButton(subOpts)
					subOpts = type(subOpts) == "table" and subOpts or { Text = tostring(subOpts), Func = function() end }

					local Sub = Create("TextButton", {
						Size               = UDim2.new(1, 0, 0, 28),
						BackgroundColor3   = Theme.SurfaceLight,
						Text               = subOpts.Text or "Sub",
						TextColor3         = Theme.Text,
						Font               = Theme.Font,
						TextSize           = 12,
						Parent             = Holder
					})
					Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Sub })

					Sub.MouseEnter:Connect(function()
						Tween(Sub, { BackgroundColor3 = Theme.AccentDark }, 0.15)
					end)
					Sub.MouseLeave:Connect(function()
						Tween(Sub, { BackgroundColor3 = Theme.SurfaceLight }, 0.15)
					end)
					Sub.MouseButton1Click:Connect(function()
						if subOpts.Func then
							subOpts.Func()
						end
					end)

					return Sub
				end

				function ButtonObj:SetVisible(v)
					Holder.Visible = v
				end

				if opts.Flag then
					MakeDependency(ButtonObj, opts.Flag)
				end

				return ButtonObj
			end

			function Group:AddToggle(id, opts)
				opts = opts or {}
				local state = opts.Default or false

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, -50, 1, 0),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local ToggleBg = Create("Frame", {
					Size               = UDim2.fromOffset(42, 22),
					Position           = UDim2.new(1, -42, 0.5, 0),
					AnchorPoint        = Vector2.new(0, 0.5),
					BackgroundColor3   = state and Theme.Accent or Theme.SurfaceLight,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleBg })

				local Circle = Create("Frame", {
					Size               = UDim2.fromOffset(16, 16),
					Position           = state and UDim2.new(1, -19, 0.5, 0) or UDim2.fromOffset(3, 3),
					AnchorPoint        = state and Vector2.new(0, 0.5) or Vector2.new(0, 0),
					BackgroundColor3   = Color3.new(1, 1, 1),
					Parent             = ToggleBg
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Circle })

				local callbacks = {}

				local function Set(value, silent)
					state = value
					Tween(ToggleBg, {
						BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight
					}, 0.18)
					Tween(Circle, {
						Position     = state and UDim2.new(1, -19, 0.5, 0) or UDim2.fromOffset(3, 3),
						AnchorPoint  = state and Vector2.new(0, 0.5) or Vector2.new(0, 0)
					}, 0.18)

					Library.Flags[id] = state

					if not silent then
						if opts.Callback then
							opts.Callback(state)
						end
						for _, cb in ipairs(callbacks) do
							cb(state)
						end
					end
				end

				ToggleBg.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Set(not state)
					end
				end)

				AddTooltip(Holder, opts.Tooltip)

				local ToggleObj = {
					Value = state,
					SetValue = function(_, value, silent)
						Set(value, silent)
					end,
					GetValue = function()
						return state
					end,
					OnChanged = function(_, cb)
						table.insert(callbacks, cb)
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Toggles[id] = ToggleObj
				Library.Flags[id] = state

				if opts.Flag then
					MakeDependency(ToggleObj, opts.Flag)
				end

				return ToggleObj
			end

			function Group:AddCheckbox(id, opts)
				opts = opts or {}
				local state = opts.Default or false

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 26),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				local Box = Create("Frame", {
					Size               = UDim2.fromOffset(18, 18),
					Position           = UDim2.fromOffset(0, 4),
					BackgroundColor3   = state and Theme.Accent or Theme.SurfaceLight,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Box })

				local Check = Create("TextLabel", {
					Size               = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text               = state and "✓" or "",
					TextColor3         = Theme.Text,
					Font               = Theme.FontBold,
					TextSize           = 14,
					Parent             = Box
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, -28, 1, 0),
					Position           = UDim2.fromOffset(26, 0),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local function Set(value)
					state = value
					Tween(Box, {
						BackgroundColor3 = state and Theme.Accent or Theme.SurfaceLight
					}, 0.15)
					Check.Text = state and "✓" or ""
					if opts.Callback then
						opts.Callback(state)
					end
				end

				Holder.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						Set(not state)
					end
				end)

				local Obj = {
					SetValue = function(_, v) Set(v) end,
					GetValue = function() return state end,
					SetVisible = function(_, v) Holder.Visible = v end
				}

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			function Group:AddSlider(id, opts)
				opts = opts or {}
				local min = opts.Min or 0
				local max = opts.Max or 100
				local value = opts.Default or min
				local rounding = opts.Rounding or 0

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 46),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, -55, 0, 18),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local ValueLabel = Create("TextLabel", {
					Size               = UDim2.fromOffset(50, 18),
					Position           = UDim2.new(1, -50, 0, 0),
					BackgroundTransparency = 1,
					Text               = tostring(value),
					TextColor3         = Theme.AccentSoft,
					Font               = Theme.FontBold,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Right,
					Parent             = Holder
				})

				local Track = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 6),
					Position           = UDim2.fromOffset(0, 28),
					BackgroundColor3   = Theme.SurfaceLight,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })

				local Fill = Create("Frame", {
					Size               = UDim2.new((value - min) / math.max(max - min, 1), 0, 1, 0),
					BackgroundColor3   = Theme.Accent,
					Parent             = Track
				})
				Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fill })

				local sliding = false

				Track.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = true
					end
				end)

				UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						sliding = false
					end
				end)

				RunService.RenderStepped:Connect(function()
					if sliding then
						local relative = math.clamp((Mouse.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
						value = math.floor((min + (max - min) * relative) * (10 ^ rounding) + 0.5) / (10 ^ rounding)
						Fill.Size = UDim2.new(relative, 0, 1, 0)
						ValueLabel.Text = tostring(value)
						Library.Flags[id] = value
						if opts.Callback then
							opts.Callback(value)
						end
					end
				end)

				local Obj = {
					SetValue = function(_, v)
						value = math.clamp(v, min, max)
						local relative = (value - min) / math.max(max - min, 1)
						Fill.Size = UDim2.new(relative, 0, 1, 0)
						ValueLabel.Text = tostring(value)
						Library.Flags[id] = value
					end,
					GetValue = function()
						return value
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Flags[id] = value
				Library.Options[id] = Obj

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			function Group:AddInput(id, opts)
				opts = opts or {}

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 50),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 12,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local Box = Create("TextBox", {
					Size               = UDim2.new(1, 0, 0, 28),
					Position           = UDim2.fromOffset(0, 20),
					BackgroundColor3   = Theme.SurfaceLight,
					Text               = opts.Default or "",
					PlaceholderText    = opts.Placeholder or "Type here...",
					PlaceholderColor3  = Theme.TextDim,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					ClearTextOnFocus   = opts.ClearTextOnFocus ~= false,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Box })
				Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = Box })

				Box.FocusLost:Connect(function()
					Library.Flags[id] = Box.Text
					if opts.Callback then
						opts.Callback(Box.Text)
					end
				end)

				local Obj = {
					SetValue = function(_, v)
						Box.Text = tostring(v)
						Library.Flags[id] = v
					end,
					GetValue = function()
						return Box.Text
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Flags[id] = Box.Text
				Library.Options[id] = Obj

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			function Group:AddDropdown(id, opts)
				opts = opts or {}
				local values = opts.Values or { "Option 1", "Option 2" }
				local multi = opts.Multi or false
				local selected = multi and (opts.Default or {}) or (opts.Default or values[1])

				if opts.SpecialType == "Player" then
					values = {}
					for _, player in pairs(Players:GetPlayers()) do
						if not opts.ExcludeLocalPlayer or player ~= LocalPlayer then
							table.insert(values, player.Name)
						end
					end
					Players.PlayerAdded:Connect(function(player)
						table.insert(values, player.Name)
					end)
					Players.PlayerRemoving:Connect(function(player)
						local idx = table.find(values, player.Name)
						if idx then
							table.remove(values, idx)
						end
					end)
				end

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 50),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 12,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local DropBtn = Create("TextButton", {
					Size               = UDim2.new(1, 0, 0, 28),
					Position           = UDim2.fromOffset(0, 20),
					BackgroundColor3   = Theme.SurfaceLight,
					Text               = multi and (type(selected) == "table" and table.concat(selected, ", ") or "None") or tostring(selected),
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 12,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropBtn })
				Create("UIPadding", { PaddingLeft = UDim.new(0, 8), Parent = DropBtn })

				local Arrow = Create("TextLabel", {
					Size               = UDim2.fromOffset(20, 28),
					Position           = UDim2.new(1, -24, 0, 0),
					BackgroundTransparency = 1,
					Text               = "▼",
					TextColor3         = Theme.TextDim,
					Font               = Theme.Font,
					TextSize           = 10,
					Parent             = DropBtn
				})

				local DropFrame = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 0),
					Position           = UDim2.fromOffset(0, 52),
					BackgroundColor3   = Theme.Surface,
					BorderSizePixel    = 0,
					Visible            = false,
					ZIndex             = 50,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropFrame })
				Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = DropFrame })

				local ListFrame = Create("ScrollingFrame", {
					Size               = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					BorderSizePixel    = 0,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = Theme.Accent,
					CanvasSize         = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ZIndex             = 51,
					Parent             = DropFrame
				})
				Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = ListFrame })
				Create("UIPadding", {
					PaddingTop         = UDim.new(0, 4),
					PaddingBottom      = UDim.new(0, 4),
					Parent             = ListFrame
				})

				local open = false

				local function ToggleDrop()
					open = not open
					DropFrame.Visible = open
					Arrow.Text = open and "▲" or "▼"
					if open then
						DropFrame.Size = UDim2.new(1, 0, 0, math.min(#values * 26 + 8, 160))
					end
				end

				DropBtn.MouseButton1Click:Connect(ToggleDrop)

				local function Refresh()
					for _, child in pairs(ListFrame:GetChildren()) do
						if child:IsA("TextButton") then
							child:Destroy()
						end
					end

					for _, value in ipairs(values) do
						local isSelected = multi and table.find(selected, value) or selected == value

						local Opt = Create("TextButton", {
							Size               = UDim2.new(1, -8, 0, 24),
							BackgroundColor3   = isSelected and Theme.AccentDark or Theme.SurfaceLight,
							BackgroundTransparency = isSelected and 0 or 1,
							Text               = "  " .. value,
							TextColor3         = Theme.Text,
							Font               = Theme.Font,
							TextSize           = 12,
							TextXAlignment     = Enum.TextXAlignment.Left,
							ZIndex             = 52,
							Parent             = ListFrame
						})
						Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Opt })

						Opt.MouseButton1Click:Connect(function()
							if multi then
								local idx = table.find(selected, value)
								if idx then
									table.remove(selected, idx)
								else
									table.insert(selected, value)
								end
								DropBtn.Text = #selected > 0 and table.concat(selected, ", ") or "None"
							else
								selected = value
								DropBtn.Text = tostring(value)
								ToggleDrop()
							end
							Library.Flags[id] = selected
							Refresh()
							if opts.Callback then
								opts.Callback(selected)
							end
						end)
					end
				end

				Refresh()

				local Obj = {
					SetValues = function(_, newValues)
						values = newValues
						Refresh()
					end,
					SetValue = function(_, v)
						selected = v
						DropBtn.Text = multi and (type(v) == "table" and table.concat(v, ", ") or "None") or tostring(v)
						Library.Flags[id] = selected
						Refresh()
					end,
					GetValue = function()
						return selected
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Flags[id] = selected
				Library.Options[id] = Obj

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			function Group:AddKeybind(id, opts)
				opts = opts or {}
				local currentKey = opts.Default or Enum.KeyCode.E
				local listening = false

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, -90, 1, 0),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local KeyBtn = Create("TextButton", {
					Size               = UDim2.fromOffset(80, 24),
					Position           = UDim2.new(1, -80, 0.5, 0),
					AnchorPoint        = Vector2.new(0, 0.5),
					BackgroundColor3   = Theme.SurfaceLight,
					Text               = currentKey.Name,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 12,
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = KeyBtn })

				KeyBtn.MouseButton1Click:Connect(function()
					listening = true
					KeyBtn.Text = "..."
					KeyBtn.TextColor3 = Theme.AccentSoft
				end)

				UserInputService.InputBegan:Connect(function(input)
					if listening and input.UserInputType == Enum.UserInputType.Keyboard then
						currentKey = input.KeyCode
						KeyBtn.Text = currentKey.Name
						KeyBtn.TextColor3 = Theme.Text
						listening = false
						Library.Flags[id] = currentKey.Name
						if opts.Callback then
							opts.Callback(currentKey)
						end
					end
				end)

				local Obj = {
					SetValue = function(_, key)
						currentKey = key
						KeyBtn.Text = key.Name
						Library.Flags[id] = key.Name
					end,
					GetValue = function()
						return currentKey
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Flags[id] = currentKey.Name

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			function Group:AddColorPicker(id, opts)
				opts = opts or {}
				local color = opts.Default or Theme.Accent

				local Holder = Create("Frame", {
					Size               = UDim2.new(1, 0, 0, 28),
					BackgroundTransparency = 1,
					Parent             = Container
				})

				Create("TextLabel", {
					Size               = UDim2.new(1, -40, 1, 0),
					BackgroundTransparency = 1,
					Text               = opts.Text or id,
					TextColor3         = Theme.Text,
					Font               = Theme.Font,
					TextSize           = 13,
					TextXAlignment     = Enum.TextXAlignment.Left,
					Parent             = Holder
				})

				local Preview = Create("TextButton", {
					Size               = UDim2.fromOffset(28, 22),
					Position           = UDim2.new(1, -28, 0.5, 0),
					AnchorPoint        = Vector2.new(0, 0.5),
					BackgroundColor3   = color,
					Text               = "",
					Parent             = Holder
				})
				Create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = Preview })
				Create("UIStroke", { Color = Theme.Border, Thickness = 1, Parent = Preview })

				local palette = {
					Color3.fromRGB(220, 55, 75),
					Color3.fromRGB(255, 100, 50),
					Color3.fromRGB(255, 200, 50),
					Color3.fromRGB(80, 200, 120),
					Color3.fromRGB(50, 150, 255),
					Color3.fromRGB(180, 80, 255),
					Color3.fromRGB(255, 100, 180),
					Color3.fromRGB(255, 255, 255),
					Color3.fromRGB(40, 40, 40)
				}
				local index = 1

				Preview.MouseButton1Click:Connect(function()
					index = index % #palette + 1
					color = palette[index]
					Preview.BackgroundColor3 = color
					Library.Flags[id] = { R = color.R, G = color.G, B = color.B }
					if opts.Callback then
						opts.Callback(color)
					end
				end)

				local Obj = {
					SetValue = function(_, c)
						color = c
						Preview.BackgroundColor3 = c
					end,
					GetValue = function()
						return color
					end,
					SetVisible = function(_, v)
						Holder.Visible = v
					end
				}

				Library.Flags[id] = { R = color.R, G = color.G, B = color.B }

				if opts.Flag then
					MakeDependency(Obj, opts.Flag)
				end

				return Obj
			end

			return Group
		end

		function Tab:AddLeftGroupbox(title)
			return self:AddGroupbox(title)
		end

		function Tab:AddRightGroupbox(title)
			return self:AddGroupbox(title)
		end

		return Tab
	end

	return Window
end

-- ===================== NOTIFY =====================
function Library:Notify(text, duration, side)
	duration = duration or 3
	side = side or "Right"

	local Notif = Create("Frame", {
		Size               = UDim2.fromOffset(280, 54),
		Position           = side == "Left" and UDim2.new(0, -300, 1, -80) or UDim2.new(1, 20, 1, -80),
		BackgroundColor3   = Theme.Surface,
		BorderSizePixel    = 0,
		Parent             = ScreenGui
	})
	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Notif })
	Create("UIStroke", { Color = Theme.Accent, Thickness = 1.3, Parent = Notif })

	Create("TextLabel", {
		Size               = UDim2.new(1, -16, 1, 0),
		Position           = UDim2.fromOffset(12, 0),
		BackgroundTransparency = 1,
		Text               = text,
		TextColor3         = Theme.Text,
		Font               = Theme.Font,
		TextSize           = 13,
		TextXAlignment     = Enum.TextXAlignment.Left,
		TextWrapped        = true,
		Parent             = Notif
	})

	local targetPos = side == "Left" and UDim2.new(0, 20, 1, -80) or UDim2.new(1, -300, 1, -80)
	Tween(Notif, { Position = targetPos }, 0.35)

	task.delay(duration, function()
		local hidePos = side == "Left" and UDim2.new(0, -300, 1, -80) or UDim2.new(1, 20, 1, -80)
		Tween(Notif, { Position = hidePos }, 0.3)
		task.wait(0.35)
		Notif:Destroy()
	end)
end

-- ===================== CONFIG =====================
function Library:SaveConfig(name)
	name = name or "default"
	local data = {}
	for flag, value in pairs(Library.Flags) do
		data[flag] = value
	end

	local success, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)

	if success then
		if writefile then
			writefile("RedObsidian_" .. name .. ".json", encoded)
			Library:Notify("Config \"" .. name .. "\" disimpan!", 2)
		else
			print("[RedObsidian] Config JSON:")
			print(encoded)
			Library:Notify("writefile tidak tersedia (cek F9)", 3)
		end
	end
end

function Library:LoadConfig(name)
	name = name or "default"
	if not (isfile and isfile("RedObsidian_" .. name .. ".json")) then
		Library:Notify("Config tidak ditemukan", 2)
		return
	end

	local success, data = pcall(function()
		return HttpService:JSONDecode(readfile("RedObsidian_" .. name .. ".json"))
	end)

	if success and data then
		for flag, value in pairs(data) do
			if Library.Toggles[flag] then
				Library.Toggles[flag]:SetValue(value, true)
			elseif Library.Options[flag] then
				Library.Options[flag]:SetValue(value)
			end
			Library.Flags[flag] = value
		end
		Library:Notify("Config \"" .. name .. "\" dimuat!", 2)
	end
end

function Library:SetAccent(color)
	Theme.Accent = color
	Theme.AccentSoft = Color3.new(
		math.min(color.R + 0.15, 1),
		math.min(color.G + 0.15, 1),
		math.min(color.B + 0.15, 1)
	)
	Theme.AccentDark = Color3.new(
		math.max(color.R - 0.25, 0),
		math.max(color.G - 0.25, 0),
		math.max(color.B - 0.25, 0)
	)
	Library:Notify("Accent color updated!", 2)
end

return Library
