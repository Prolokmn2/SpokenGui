-- SpokenGui | made by Prolokmn | a ForkedHub original
-- Auto-detects mobile vs PC, scales/fits to the screen, touch-friendly.
local SpokenGui = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

SpokenGui.IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

local Theme = {
	Background = Color3.fromRGB(16, 14, 26),
	Topbar = Color3.fromRGB(24, 21, 38),
	Sidebar = Color3.fromRGB(20, 18, 32),
	Element = Color3.fromRGB(32, 28, 50),
	ElementHover = Color3.fromRGB(42, 37, 66),
	Accent = Color3.fromRGB(150, 90, 255),
	Text = Color3.fromRGB(240, 238, 250),
	SubText = Color3.fromRGB(155, 150, 180),
}

local function create(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function round(o, r)
	create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o)
end

local function tween(o, props, t)
	TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

local function getGuiParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h end
	end
	local ok = pcall(function() return CoreGui.Name end)
	if ok then return CoreGui end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(1280, 720)
end

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

------------------------------------------------------------------
-- Notifications
------------------------------------------------------------------
function SpokenGui:Notify(opts)
	opts = opts or {}
	local holder = self._notifHolder
	if not holder then return end
	local card = create("Frame", {
		Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Element,
		ClipsDescendants = true, BorderSizePixel = 0,
	}, holder)
	round(card, 8)
	create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.4 }, card)
	create("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20), Position = UDim2.fromOffset(8, 6),
		BackgroundTransparency = 1, Text = opts.Title or "Notice", Font = Enum.Font.GothamBold,
		TextSize = 14, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
	}, card)
	create("TextLabel", {
		Size = UDim2.new(1, -16, 0, 34), Position = UDim2.fromOffset(8, 26),
		BackgroundTransparency = 1, Text = opts.Content or "", Font = Enum.Font.Gotham,
		TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
	}, card)
	tween(card, { Size = UDim2.new(1, 0, 0, 66) }, 0.2)
	task.delay(opts.Duration or 3, function()
		tween(card, { Size = UDim2.new(1, 0, 0, 0) }, 0.2)
		task.wait(0.25)
		card:Destroy()
	end)
end

------------------------------------------------------------------
-- Window
------------------------------------------------------------------
function SpokenGui:CreateWindow(opts)
	opts = opts or {}
	local Window = { _tabs = {}, _conns = {} }

	local mobile = opts.Mobile
	if mobile == nil then mobile = SpokenGui.IsMobile end
	Window.IsMobile = mobile

	if opts.Accent then Theme.Accent = opts.Accent end

	-- device-dependent metrics
	local TOP = mobile and 42 or 38
	local SIDEBAR_W = mobile and 96 or 130
	local ROW_H = mobile and 42 or 34
	local SLIDER_H = mobile and 58 or 50
	local TEXT = mobile and 12 or 13
	local TAB_H = mobile and 34 or 30

	local gui = create("ScreenGui", {
		Name = "SpokenGui_" .. tostring(math.random(1000, 9999)),
		ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
	})
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	gui.Parent = getGuiParent()
	Window.Gui = gui

	-- notifications (top-right on mobile, bottom-right on PC)
	local nw = mobile and 220 or 260
	local nh = create("Frame", {
		Size = UDim2.fromOffset(nw, 400), BackgroundTransparency = 1,
		Position = mobile and UDim2.new(1, -(nw + 8), 0, 8) or UDim2.new(1, -(nw + 16), 1, -416),
	}, gui)
	create("UIListLayout", {
		Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = mobile and Enum.VerticalAlignment.Top or Enum.VerticalAlignment.Bottom,
	}, nh)
	self._notifHolder = nh

	-- main frame
	local main = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0, ClipsDescendants = true,
	}, gui)
	round(main, 10)
	create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.5 }, main)

	local minimized = false

	local function computeSize()
		local vp = viewport()
		if mobile then
			return Vector2.new(
				math.min(vp.X - 16, math.clamp(vp.X * 0.85, 300, 480)),
				math.min(vp.Y - 16, math.clamp(vp.Y * 0.78, 200, 320)))
		end
		return Vector2.new(
			math.min(vp.X - 16, math.clamp(vp.X * 0.6, 420, 560)),
			math.min(vp.Y - 16, math.clamp(vp.Y * 0.6, 300, 380)))
	end

	local function applySize(animated)
		local s = computeSize()
		local target = UDim2.fromOffset(s.X, minimized and TOP or s.Y)
		if animated then tween(main, { Size = target }, 0.2) else main.Size = target end
	end

	local function keepOnScreen()
		local vp = viewport()
		local p, s = main.AbsolutePosition, main.AbsoluteSize
		if p.X < -s.X + 60 or p.Y < -10 or p.X > vp.X - 60 or p.Y > vp.Y - 30 then
			main.Position = UDim2.new(0.5, 0, 0.5, 0)
		end
	end

	applySize(false)

	-- refit when the screen size / orientation changes
	local function hookCamera()
		local cam = workspace.CurrentCamera
		if cam then
			table.insert(Window._conns, cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applySize(false)
				task.defer(keepOnScreen)
			end))
		end
	end
	hookCamera()
	table.insert(Window._conns, workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hookCamera))

	-- topbar
	local top = create("Frame", {
		Size = UDim2.new(1, 0, 0, TOP), BackgroundColor3 = Theme.Topbar, BorderSizePixel = 0,
	}, main)
	create("TextLabel", {
		Size = UDim2.new(1, -100, 0, 20), Position = UDim2.fromOffset(12, mobile and 5 or 4),
		BackgroundTransparency = 1, Text = opts.Name or "SpokenGui", Font = Enum.Font.GothamBold,
		TextSize = mobile and 14 or 15, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)
	create("TextLabel", {
		Size = UDim2.new(1, -100, 0, 14), Position = UDim2.fromOffset(12, mobile and 24 or 22),
		BackgroundTransparency = 1, Text = opts.Subtitle or "", Font = Enum.Font.Gotham,
		TextSize = mobile and 10 or 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, top)

	local bw, bh = mobile and 34 or 28, mobile and 30 or 24
	local function topButton(text, xOff)
		local b = create("TextButton", {
			Size = UDim2.fromOffset(bw, bh), Position = UDim2.new(1, xOff, 0.5, -bh / 2),
			BackgroundColor3 = Theme.Element, Text = text, Font = Enum.Font.GothamBold,
			TextSize = 14, TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0,
		}, top)
		round(b, 6)
		return b
	end
	local minBtn = topButton("-", -(bw * 2 + 10))
	local closeBtn = topButton("X", -(bw + 6))

	-- drag
	local dragging, dragStart, startPos
	top.InputBegan:Connect(function(i)
		if isPress(i) then
			dragging, dragStart, startPos = true, i.Position, main.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	table.insert(Window._conns, UIS.InputChanged:Connect(function(i)
		if dragging and isMove(i) then
			local d = i.Position - dragStart
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end))

	-- sidebar + pages
	local sidebar = create("ScrollingFrame", {
		Size = UDim2.new(0, SIDEBAR_W, 1, -TOP), Position = UDim2.fromOffset(0, TOP),
		BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, ScrollBarThickness = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
	}, main)
	create("UIListLayout", { Padding = UDim.new(0, 4) }, sidebar)
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, sidebar)

	local pages = create("Frame", {
		Size = UDim2.new(1, -SIDEBAR_W, 1, -TOP), Position = UDim2.fromOffset(SIDEBAR_W, TOP),
		BackgroundTransparency = 1,
	}, main)

	-- show/hide
	local function setVisible(v) main.Visible = v end
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		sidebar.Visible = not minimized
		pages.Visible = not minimized
		applySize(true)
	end)
	function Window:Destroy()
		for _, c in ipairs(self._conns) do c:Disconnect() end
		gui:Destroy()
	end
	function Window:Toggle() setVisible(not main.Visible) end
	closeBtn.MouseButton1Click:Connect(function() Window:Destroy() end)

	if mobile then
		-- floating button to hide/show (no keyboard on mobile)
		local fb = create("TextButton", {
			Size = UDim2.fromOffset(44, 44), Position = UDim2.new(0, 10, 0.4, 0),
			BackgroundColor3 = Theme.Accent, Text = "S", Font = Enum.Font.GothamBold,
			TextSize = 20, TextColor3 = Theme.Text, AutoButtonColor = false, BorderSizePixel = 0,
			ZIndex = 50,
		}, gui)
		round(fb, 22)
		local fbDrag, fbStart, fbPos, fbMoved
		fb.InputBegan:Connect(function(i)
			if isPress(i) then
				fbDrag, fbStart, fbPos, fbMoved = true, i.Position, fb.Position, false
				i.Changed:Connect(function()
					if i.UserInputState == Enum.UserInputState.End then
						fbDrag = false
						if not fbMoved then Window:Toggle() end
					end
				end)
			end
		end)
		table.insert(Window._conns, UIS.InputChanged:Connect(function(i)
			if fbDrag and isMove(i) then
				local d = i.Position - fbStart
				if d.Magnitude > 6 then fbMoved = true end
				fb.Position = UDim2.new(fbPos.X.Scale, fbPos.X.Offset + d.X, fbPos.Y.Scale, fbPos.Y.Offset + d.Y)
			end
		end))
	else
		local toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift
		table.insert(Window._conns, UIS.InputBegan:Connect(function(i, gp)
			if not gp and i.KeyCode == toggleKey then Window:Toggle() end
		end))
	end

	local function selectTab(tab)
		for _, t in ipairs(Window._tabs) do
			t.Page.Visible = (t == tab)
			tween(t.Button, {
				BackgroundColor3 = (t == tab) and Theme.Accent or Theme.Element,
				TextColor3 = (t == tab) and Theme.Text or Theme.SubText,
			})
		end
	end

	------------------------------------------------------------------
	-- Tabs
	------------------------------------------------------------------
	function Window:CreateTab(name)
		local Tab = {}
		local btn = create("TextButton", {
			Size = UDim2.new(1, 0, 0, TAB_H), BackgroundColor3 = Theme.Element, Text = name,
			Font = Enum.Font.GothamMedium, TextSize = mobile and 11 or 12, TextColor3 = Theme.SubText,
			AutoButtonColor = false, BorderSizePixel = 0, TextWrapped = true,
		}, sidebar)
		round(btn, 6)

		local page = create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
			ScrollBarThickness = mobile and 4 or 3, ScrollBarImageColor3 = Theme.Accent, Visible = false,
			CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		}, pages)
		create("UIListLayout", { Padding = UDim.new(0, 6) }, page)
		create("UIPadding", {
			PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, mobile and 8 or 10),
			PaddingRight = UDim.new(0, mobile and 8 or 10), PaddingBottom = UDim.new(0, 8),
		}, page)

		Tab.Button, Tab.Page = btn, page
		table.insert(Window._tabs, Tab)
		btn.MouseButton1Click:Connect(function() selectTab(Tab) end)
		if #Window._tabs == 1 then selectTab(Tab) end

		local function row(height)
			local f = create("Frame", {
				Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
			}, page)
			round(f, 6)
			return f
		end
		local function rowLabel(parent, text)
			return create("TextLabel", {
				Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 0),
				BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamMedium,
				TextSize = TEXT, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, parent)
		end

		function Tab:CreateSection(text)
			create("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.upper(text),
				Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, page)
		end

		function Tab:CreateLabel(text)
			local f = row(mobile and 32 or 28)
			local l = rowLabel(f, text)
			l.Position = UDim2.fromOffset(10, mobile and 6 or 4)
			l.TextColor3 = Theme.SubText
			return { Set = function(_, t) l.Text = t end }
		end

		function Tab:CreateButton(o)
			local f = row(ROW_H)
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = o.Name or "Button",
				Font = Enum.Font.GothamMedium, TextSize = TEXT, TextColor3 = Theme.Text, AutoButtonColor = false,
			}, f)
			b.MouseEnter:Connect(function() tween(f, { BackgroundColor3 = Theme.ElementHover }) end)
			b.MouseLeave:Connect(function() tween(f, { BackgroundColor3 = Theme.Element }) end)
			b.MouseButton1Click:Connect(function()
				tween(f, { BackgroundColor3 = Theme.Accent }, 0.08)
				task.delay(0.12, function() tween(f, { BackgroundColor3 = Theme.Element }) end)
				if o.Callback then task.spawn(o.Callback) end
			end)
		end

		function Tab:CreateToggle(o)
			local state = o.Default or false
			local f = row(ROW_H)
			local l = rowLabel(f, o.Name or "Toggle")
			l.Size = UDim2.new(1, -70, 1, 0)
			local pill = create("Frame", {
				Size = UDim2.fromOffset(38, 20), Position = UDim2.new(1, -48, 0.5, -10),
				BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
			}, f)
			round(pill, 10)
			local knob = create("Frame", {
				Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3),
				BackgroundColor3 = Theme.SubText, BorderSizePixel = 0,
			}, pill)
			round(knob, 7)
			local function render()
				tween(pill, { BackgroundColor3 = state and Theme.Accent or Theme.Background })
				tween(knob, {
					Position = state and UDim2.fromOffset(21, 3) or UDim2.fromOffset(3, 3),
					BackgroundColor3 = state and Theme.Text or Theme.SubText,
				})
			end
			local function set(v, silent)
				state = v and true or false
				render()
				if not silent and o.Callback then task.spawn(o.Callback, state) end
			end
			create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
			}, f).MouseButton1Click:Connect(function() set(not state) end)
			render()
			if state and o.Callback then task.spawn(o.Callback, state) end
			return { Set = function(_, v) set(v) end, Get = function() return state end }
		end

		function Tab:CreateSlider(o)
			local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
			local value = math.clamp(o.Default or min, min, max)
			local f = row(SLIDER_H)
			local l = rowLabel(f, "")
			l.Position = UDim2.fromOffset(10, 6)
			local barH = mobile and 8 or 6
			local bar = create("Frame", {
				Size = UDim2.new(1, -20, 0, barH), Position = UDim2.new(0, 10, 1, -(barH + 12)),
				BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
			}, f)
			round(bar, 4)
			local fill = create("Frame", {
				Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
			}, bar)
			round(fill, 4)

			local function render()
				local shown = math.floor(value * 100 + 0.5) / 100
				l.Text = string.format("%s: %s%s", o.Name or "Slider", tostring(shown), o.Suffix and (" " .. o.Suffix) or "")
				fill.Size = UDim2.new((value - min) / math.max(max - min, 1e-9), 0, 1, 0)
			end
			local function set(v, silent)
				v = math.clamp(math.floor(v / inc + 0.5) * inc, min, max)
				if v == value and not silent then return end
				value = v
				render()
				if not silent and o.Callback then task.spawn(o.Callback, value) end
			end
			local function fromX(x)
				local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				set(min + (max - min) * rel)
			end

			local sliding = false
			f.InputBegan:Connect(function(i)
				if isPress(i) then
					sliding = true
					page.ScrollingEnabled = false -- stop the page scrolling while dragging on touch
					fromX(i.Position.X)
					i.Changed:Connect(function()
						if i.UserInputState == Enum.UserInputState.End then
							sliding = false
							page.ScrollingEnabled = true
						end
					end)
				end
			end)
			table.insert(Window._conns, UIS.InputChanged:Connect(function(i)
				if sliding and isMove(i) then fromX(i.Position.X) end
			end))
			render()
			return { Set = function(_, v) set(v) end, Get = function() return value end }
		end

		return Tab
	end

	return Window
end

return SpokenGui
