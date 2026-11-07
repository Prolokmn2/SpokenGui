-- SpokenGui | made by Prolokmn | a ForkedHub original
-- Auto-detects mobile vs PC, scales/fits to the screen, touch-friendly.
local SpokenGui = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

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
	local Window = { _tabs = {}, _conns = {}, Flags = {} }

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

	local MIN_W, MIN_H = mobile and 300 or 400, mobile and 200 or 260
	local userSize -- set once the player drags the resize grip

	local function computeSize()
		local vp = viewport()
		local base
		if userSize then
			base = userSize
		elseif mobile then
			base = Vector2.new(math.clamp(vp.X * 0.85, 300, 480), math.clamp(vp.Y * 0.78, 200, 320))
		else
			base = Vector2.new(math.clamp(vp.X * 0.6, 420, 560), math.clamp(vp.Y * 0.6, 300, 380))
		end
		local maxW, maxH = vp.X - 16, vp.Y - 16
		return Vector2.new(
			math.clamp(base.X, math.min(MIN_W, maxW), maxW),
			math.clamp(base.Y, math.min(MIN_H, maxH), maxH))
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

	-- resize grip (bottom-right corner, mouse + touch)
	local gs = mobile and 30 or 20
	local grip = create("TextButton", {
		Size = UDim2.fromOffset(gs, gs), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20,
	}, main)
	for _, cfg in ipairs({ { 0.62, 0.8 }, { 0.82, 0.4 } }) do
		create("Frame", {
			Size = UDim2.fromOffset(gs * cfg[2], 2), AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(cfg[1], 0, cfg[1], 0), Rotation = -45,
			BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.2, BorderSizePixel = 0, ZIndex = 21,
		}, grip)
	end
	local resizing, rStart, rSize, rPos
	grip.InputBegan:Connect(function(i)
		if isPress(i) then
			resizing, rStart, rSize, rPos = true, i.Position, main.AbsoluteSize, main.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then resizing = false end
			end)
		end
	end)
	table.insert(Window._conns, UIS.InputChanged:Connect(function(i)
		if resizing and isMove(i) then
			local d = i.Position - rStart
			local vp = viewport()
			local w = math.clamp(rSize.X + d.X, math.min(MIN_W, vp.X - 16), vp.X - 16)
			local h = math.clamp(rSize.Y + d.Y, math.min(MIN_H, vp.Y - 16), vp.Y - 16)
			userSize = Vector2.new(w, h)
			main.Size = UDim2.fromOffset(w, h)
			-- window is centre-anchored: shift by half the change so the top-left corner stays put
			main.Position = UDim2.new(rPos.X.Scale, rPos.X.Offset + (w - rSize.X) / 2, rPos.Y.Scale, rPos.Y.Offset + (h - rSize.Y) / 2)
		end
	end))

	-- show/hide
	local function setVisible(v) main.Visible = v end
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		grip.Visible = not minimized
		sidebar.Visible = not minimized
		pages.Visible = not minimized
		applySize(true)
	end)
	function Window:Destroy()
		for _, c in ipairs(self._conns) do c:Disconnect() end
		gui:Destroy()
	end
	function Window:Toggle() setVisible(not main.Visible) end

	------------------------------------------------------------------
	-- Configs (save / load every control that has a Flag)
	------------------------------------------------------------------
	local function cfgBase() return opts.ConfigFolder or "SpokenGui" end
	local function hasFiles() return (writefile and readfile and isfolder and makefolder) and true or false end
	local function cleanName(n)
		local c = tostring(n or ""):gsub("[^%w_%- ]", "")
		return (c:match("^%s*(.-)%s*$"))
	end
	local function cfgPath(name) return cfgBase() .. "/configs/" .. name .. ".json" end

	function Window:GetConfig()
		local t = {}
		for flag, ctl in pairs(self.Flags) do
			local ok, v = pcall(ctl.Get)
			if ok then t[flag] = v end
		end
		return t
	end

	function Window:SaveConfig(name)
		if not hasFiles() then return false, "Your executor has no file functions" end
		name = cleanName(name)
		if name == "" then return false, "Enter a config name first" end
		local ok, err = pcall(function()
			local base = cfgBase()
			if not isfolder(base) then makefolder(base) end
			if not isfolder(base .. "/configs") then makefolder(base .. "/configs") end
			writefile(cfgPath(name), HttpService:JSONEncode(self:GetConfig()))
		end)
		if not ok then return false, tostring(err) end
		return true, name
	end

	function Window:LoadConfig(name)
		if not hasFiles() then return false, "Your executor has no file functions" end
		name = cleanName(name)
		if name == "" then return false, "Pick or type a config name" end
		if not (isfile and isfile(cfgPath(name))) then return false, "Config '" .. name .. "' not found" end
		local ok, data = pcall(function() return HttpService:JSONDecode(readfile(cfgPath(name))) end)
		if not ok or type(data) ~= "table" then return false, "Config file is corrupted" end
		for flag, value in pairs(data) do
			local ctl = self.Flags[flag]
			if ctl then pcall(ctl.Set, ctl, value) end
		end
		return true, name
	end

	function Window:DeleteConfig(name)
		name = cleanName(name)
		if not (delfile and isfile and isfile(cfgPath(name))) then return false, "Config '" .. name .. "' not found" end
		local ok, err = pcall(delfile, cfgPath(name))
		if not ok then return false, tostring(err) end
		return true, name
	end

	function Window:ListConfigs()
		local names = {}
		if not (listfiles and isfolder) then return names end
		local dir = cfgBase() .. "/configs"
		if not isfolder(dir) then return names end
		local ok, files = pcall(listfiles, dir)
		if ok then
			for _, f in ipairs(files) do
				local n = tostring(f):match("([^/\\]+)%.json$")
				if n then table.insert(names, n) end
			end
		end
		table.sort(names)
		return names
	end
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

		-- attaches all element builders to `obj`, placing elements inside `container`
		-- (used for both the tab itself and collapsible groups)
		local function attach(obj, container)
			local function row(height)
				local f = create("Frame", {
					Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
				}, container)
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

			function obj:CreateSection(text)
				create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.upper(text),
					Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = Theme.Accent,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, container)
			end

			function obj:CreateLabel(text)
				local f = row(mobile and 32 or 28)
				local l = rowLabel(f, text)
				l.Position = UDim2.fromOffset(10, mobile and 6 or 4)
				l.TextColor3 = Theme.SubText
				return { Set = function(_, t) l.Text = t end }
			end

			function obj:CreateButton(o)
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

			function obj:CreateToggle(o)
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
				local ctl = { Set = function(_, v) set(v) end, Get = function() return state end }
				if o.Flag then Window.Flags[o.Flag] = ctl end
				return ctl
			end

			function obj:CreateDropdown(o)
				local options = o.Options or {}
				local selected = o.Default
				local holder = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
				}, container)
				create("UIListLayout", { Padding = UDim.new(0, 4) }, holder)

				local header = create("Frame", {
					Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = Theme.Element, BorderSizePixel = 0, LayoutOrder = 0,
				}, holder)
				round(header, 6)
				local lbl = rowLabel(header, "")
				lbl.Size = UDim2.new(1, -50, 1, 0)
				local arrow = create("TextLabel", {
					Size = UDim2.fromOffset(30, 20), Position = UDim2.new(1, -38, 0.5, -10),
					BackgroundTransparency = 1, Text = "v", Font = Enum.Font.GothamBold,
					TextSize = 14, TextColor3 = Theme.Accent,
				}, header)

				local listFrame = create("ScrollingFrame", {
					Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0,
					ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, Visible = false, LayoutOrder = 1,
					CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, holder)
				round(listFrame, 6)
				create("UIListLayout", { Padding = UDim.new(0, 3) }, listFrame)
				create("UIPadding", {
					PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
					PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 6),
				}, listFrame)

				local open = false
				local function renderLabel()
					lbl.Text = (o.Name or "Select") .. ": " .. tostring(selected or "-")
				end
				local function paint()
					for _, c in ipairs(listFrame:GetChildren()) do
						if c:IsA("TextButton") then
							c.BackgroundColor3 = (c.Text == tostring(selected)) and Theme.Accent or Theme.Element
						end
					end
				end
				local function setOpen(v)
					open = v
					listFrame.Visible = v
					arrow.Text = v and "^" or "v"
				end
				local function select(v, silent)
					selected = v
					renderLabel()
					paint()
					setOpen(false)
					if not silent and o.Callback then task.spawn(o.Callback, v) end
				end
				local function rebuild()
					for _, c in ipairs(listFrame:GetChildren()) do
						if c:IsA("TextButton") then c:Destroy() end
					end
					local itemH = ROW_H - 8
					for _, opt in ipairs(options) do
						local b = create("TextButton", {
							Size = UDim2.new(1, 0, 0, itemH), BackgroundColor3 = Theme.Element, Text = tostring(opt),
							Font = Enum.Font.GothamMedium, TextSize = TEXT, TextColor3 = Theme.Text,
							AutoButtonColor = false, BorderSizePixel = 0,
						}, listFrame)
						round(b, 5)
						b.MouseButton1Click:Connect(function() select(opt) end)
					end
					listFrame.Size = UDim2.new(1, 0, 0, math.min(#options * (itemH + 3) + 8, 160))
					paint()
				end

				create("TextButton", {
					Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
				}, header).MouseButton1Click:Connect(function() setOpen(not open) end)

				renderLabel()
				rebuild()
				local ctl
				ctl = {
					Set = function(_, v) select(v) end,
					Get = function() return selected end,
					Refresh = function(_, newOptions)
						options = newOptions or {}
						local found = false
						for _, opt in ipairs(options) do if opt == selected then found = true end end
						if not found then selected = options[1] end
						renderLabel()
						rebuild()
					end,
				}
				if o.Flag then Window.Flags[o.Flag] = ctl end
				return ctl
			end

			function obj:CreateParagraph(o)
				local f = create("Frame", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
				}, container)
				round(f, 6)
				create("UIPadding", {
					PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
				}, f)
				create("UIListLayout", { Padding = UDim.new(0, 4) }, f)
				if o.Title then
					create("TextLabel", {
						Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
						Text = o.Title, Font = Enum.Font.GothamBold, TextSize = TEXT, TextColor3 = Theme.Accent,
						TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, LayoutOrder = 0,
					}, f)
				end
				create("TextLabel", {
					Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					Text = o.Content or "", Font = Enum.Font.Gotham, TextSize = mobile and 11 or 12,
					TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, LayoutOrder = 1,
				}, f)
			end

			function obj:CreateTextbox(o)
				local f = row(ROW_H)
				local l = rowLabel(f, o.Name or "Text")
				l.Size = UDim2.new(0.4, -10, 1, 0)
				local box = create("TextBox", {
					Size = UDim2.new(0.6, -10, 1, -10), Position = UDim2.new(0.4, 0, 0, 5),
					BackgroundColor3 = Theme.Background, BorderSizePixel = 0, Text = o.Default or "",
					PlaceholderText = o.Placeholder or "", PlaceholderColor3 = Theme.SubText,
					ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = TEXT, TextColor3 = Theme.Text,
				}, f)
				round(box, 5)
				box.FocusLost:Connect(function()
					if o.Callback then task.spawn(o.Callback, box.Text) end
				end)
				return {
					Get = function() return box.Text end,
					Set = function(_, v) box.Text = tostring(v or "") end,
				}
			end

			function obj:CreateSlider(o)
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
				local ctl = { Set = function(_, v) set(v) end, Get = function() return value end }
				if o.Flag then Window.Flags[o.Flag] = ctl end
				return ctl
			end
		end

		attach(Tab, page)

		-- Collapsible group: click the header to list / hide its settings
		function Tab:CreateGroup(title, startOpen)
			local Group = {}
			local open = startOpen and true or false

			local holder = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, page)
			create("UIListLayout", { Padding = UDim.new(0, 6) }, holder)

			local header = create("Frame", {
				Size = UDim2.new(1, 0, 0, ROW_H), BackgroundColor3 = Theme.Element, BorderSizePixel = 0,
				LayoutOrder = 0,
			}, holder)
			round(header, 6)
			create("UIStroke", { Color = Theme.Accent, Thickness = 1, Transparency = 0.6 }, header)
			local titleLbl = create("TextLabel", {
				Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(10, 0),
				BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamBold,
				TextSize = TEXT, TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, header)
			local arrow = create("TextLabel", {
				Size = UDim2.fromOffset(30, 20), Position = UDim2.new(1, -38, 0.5, -10),
				BackgroundTransparency = 1, Text = open and "-" or "+", Font = Enum.Font.GothamBold,
				TextSize = 18, TextColor3 = Theme.Accent,
			}, header)

			local content = create("Frame", {
				Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1, Visible = open, LayoutOrder = 1,
			}, holder)
			create("UIListLayout", { Padding = UDim.new(0, 6) }, content)
			create("UIPadding", { PaddingLeft = UDim.new(0, 8) }, content)

			local function setOpen(v)
				open = v
				content.Visible = v
				arrow.Text = v and "-" or "+"
			end
			create("TextButton", {
				Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "",
			}, header).MouseButton1Click:Connect(function() setOpen(not open) end)

			function Group:SetOpen(v) setOpen(v) end
			attach(Group, content)
			return Group
		end

		return Tab
	end

	return Window
end

return SpokenGui
