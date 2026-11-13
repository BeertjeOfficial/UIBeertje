--====================================================================--
--  Beertje UI
--  A quiet, sharp interface library for Roblox scripts.
--  Public API is unchanged from v1.
--====================================================================--

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Library = {}
Library.__index = Library

--// Theme -------------------------------------------------------------

local Theme = {
	Background = Color3.fromRGB(6, 6, 7),
	Surface    = Color3.fromRGB(12, 12, 14),
	Surface2   = Color3.fromRGB(18, 18, 20),
	Surface3   = Color3.fromRGB(24, 24, 27),
	Surface4   = Color3.fromRGB(34, 34, 38),
	Border     = Color3.fromRGB(46, 46, 51),
	BorderSoft = Color3.fromRGB(30, 30, 34),
	Text       = Color3.fromRGB(244, 244, 246),
	TextDim    = Color3.fromRGB(158, 158, 164),
	TextFaint  = Color3.fromRGB(104, 104, 110),
	Accent     = Color3.fromRGB(240, 240, 242),
	AccentSoft = Color3.fromRGB(184, 184, 190),
	OnAccent   = Color3.fromRGB(10, 10, 12),
	Success    = Color3.fromRGB(224, 224, 228),
	Warning    = Color3.fromRGB(196, 196, 202),
	Danger     = Color3.fromRGB(236, 236, 240),
	Info       = Color3.fromRGB(170, 170, 178),
}

function Library:SetAccent(color)
	if typeof(color) ~= "Color3" then return end
	Theme.Accent = color
	Theme.AccentSoft = Color3.new(
		math.min(1, color.R * 0.55 + 0.45),
		math.min(1, color.G * 0.55 + 0.45),
		math.min(1, color.B * 0.55 + 0.45)
	)
	Theme.OnAccent = Color3.new(
		math.clamp(color.R * 0.12, 0, 0.16),
		math.clamp(color.G * 0.12, 0, 0.16),
		math.clamp(color.B * 0.12, 0, 0.16)
	)
end

--// Helpers -----------------------------------------------------------

local activeTweens = setmetatable({}, { __mode = "k" })

local function tween(obj, duration, props, style, direction)
	if not obj or not obj.Parent then return end

	local running = activeTweens[obj]
	if running then
		for _, t in ipairs(running) do
			pcall(function() t:Cancel() end)
		end
	end

	local list = {}
	activeTweens[obj] = list

	local info = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(obj, info, props)
	list[#list + 1] = t

	t.Completed:Connect(function()
		local current = activeTweens[obj]
		if current then
			for i, v in ipairs(current) do
				if v == t then
					table.remove(current, i)
					break
				end
			end
		end
	end)

	t:Play()
	return t
end

local function new(className, props, parent)
	local object = Instance.new(className)
	if props then
		for key, value in pairs(props) do
			object[key] = value
		end
	end
	if parent then
		object.Parent = parent
	end
	return object
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, math.min(radius or 1, 1))
	c.Parent = parent
	return c
end

local function addStroke(parent, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Transparency = transparency or 0.55
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addPadding(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

local function label(parent, props)
	props = props or {}
	local base = {
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
		TextSize = 12,
		Font = Enum.Font.Gotham,
	}
	for key, value in pairs(props) do
		base[key] = value
	end
	return new("TextLabel", base, parent)
end

local function ripple(parent, x, y)
	if not parent then return end
	local circle = new("Frame", {
		Name = "Ripple",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.9,
		BorderSizePixel = 0,
		ZIndex = 6,
	}, parent)
	addCorner(circle, 999)

	local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
	tween(circle, 0.5, {
		Size = UDim2.fromOffset(maxSize, maxSize),
		BackgroundTransparency = 1,
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	task.delay(0.55, function()
		if circle.Parent then
			circle:Destroy()
		end
	end)
end

local function card(parent, height, order)
	local frame = new("Frame", {
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		LayoutOrder = order,
	}, parent)
	addCorner(frame, 8)
	local stroke = addStroke(frame, Theme.Border, 0.6, 1)
	return frame, stroke
end

local function cardHover(frame, stroke, hover)
	if not frame or not frame.Parent then return end
	tween(frame, 0.14, {
		BackgroundColor3 = hover and Theme.Surface3 or Theme.Surface2,
	})
	if stroke then
		tween(stroke, 0.14, { Transparency = hover and 0.3 or 0.6 })
	end
end

--// Notifications -----------------------------------------------------

local NotificationContainer = nil
local notifList = {}

local function ensureNotificationContainer()
	if NotificationContainer and NotificationContainer.Parent then
		return NotificationContainer
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = playerGui:FindFirstChild("LegalizeexploitingNotifications")
	if not gui then
		gui = new("ScreenGui", {
			Name = "LegalizeexploitingNotifications",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 200,
			IgnoreGuiInset = true,
		}, playerGui)
	end

	local container = gui:FindFirstChild("Container")
	if not container then
		container = new("Frame", {
			Name = "Container",
			Size = UDim2.new(0, 322, 1, -32),
			Position = UDim2.new(1, -338, 0, 16),
			BackgroundTransparency = 1,
		}, gui)
	end

	NotificationContainer = container
	return container
end

local function reflowNotifications()
	local y = 0
	for _, item in ipairs(notifList) do
		local frame = item.frame
		if frame and frame.Parent then
			tween(frame, 0.26, {
				Position = UDim2.fromOffset(0, y),
			}, Enum.EasingStyle.Quint)
			y = y + (item.height or 0) + 8
		end
	end
end

function Library:Notify(opts)
	opts = opts or {}
	local titleText = opts.Title or "Notice"
	local contentText = opts.Content or opts.Text or ""
	local duration = opts.Duration or 4
	local notifType = opts.Type or "Info"

	local accent = Theme.Info
	if notifType == "Success" then
		accent = Theme.Success
	elseif notifType == "Warning" then
		accent = Theme.Warning
	elseif notifType == "Error" or notifType == "Danger" then
		accent = Theme.Danger
	end

	local container = ensureNotificationContainer()
	local width = 306
	local innerWidth = 232
	local contentHeight = 0
	if contentText ~= "" then
		contentHeight = math.max(15, TextService:GetTextSize(
			contentText, 12, Enum.Font.Gotham, Vector2.new(innerWidth, 1000)
		).Y)
	end
	local totalHeight = 13 + 16 + (contentHeight > 0 and (5 + contentHeight) or 0) + 13

	while #notifList >= 4 do
		local oldest = notifList[1]
		if oldest and oldest.dismiss then
			oldest.dismiss()
		else
			table.remove(notifList, 1)
		end
	end

	local notif = new("Frame", {
		Name = "Notification",
		Size = UDim2.fromOffset(width, 0),
		Position = UDim2.fromOffset(340, 0),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, container)
	addCorner(notif, 10)
	addStroke(notif, Theme.Border, 0.35, 1)

	new("Frame", {
		Name = "Accent",
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
	}, notif)

	label(notif, {
		Name = "Title",
		Size = UDim2.new(1, -60, 0, 16),
		Position = UDim2.fromOffset(18, 13),
		Text = titleText,
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	if contentText ~= "" then
		label(notif, {
			Name = "Body",
			Size = UDim2.new(1, -40, 0, contentHeight),
			Position = UDim2.fromOffset(18, 34),
			Text = contentText,
			TextSize = 12,
			TextColor3 = Theme.TextDim,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		})
	end

	local closeBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(20, 20),
		Position = UDim2.new(1, -28, 0, 11),
		BackgroundTransparency = 1,
		Text = "x",
		TextSize = 12,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.TextFaint,
		AutoButtonColor = false,
	}, notif)
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.12, { TextColor3 = Theme.Text })
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.12, { TextColor3 = Theme.TextFaint })
	end)

	local progress = new("Frame", {
		Name = "Progress",
		Size = UDim2.new(1, 0, 0, 2),
		Position = UDim2.new(0, 0, 1, -2),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
	}, notif)

	local item = { frame = notif, height = totalHeight }
	local dismissed = false

	local function dismiss()
		if dismissed or not notif.Parent then return end
		dismissed = true
		for i, v in ipairs(notifList) do
			if v == item then
				table.remove(notifList, i)
				break
			end
		end
		tween(notif, 0.24, {
			Position = UDim2.fromOffset(340, notif.Position.Y.Offset),
		}, Enum.EasingStyle.Quint)
		task.delay(0.26, function()
			if notif.Parent then
				notif:Destroy()
			end
			reflowNotifications()
		end)
		reflowNotifications()
	end

	item.dismiss = dismiss

	local slot = 0
	for _, other in ipairs(notifList) do
		slot = slot + (other.height or 0) + 8
	end
	notif.Position = UDim2.fromOffset(340, slot)
	notifList[#notifList + 1] = item

	tween(notif, 0.36, {
		Size = UDim2.fromOffset(width, totalHeight),
		Position = UDim2.fromOffset(0, slot),
	}, Enum.EasingStyle.Quint)
	tween(progress, duration, {
		Size = UDim2.new(0, 0, 0, 2),
	}, Enum.EasingStyle.Linear)

	if #notifList > 1 then
		reflowNotifications()
	end

	closeBtn.MouseButton1Click:Connect(dismiss)
	task.delay(duration, dismiss)

	return notif
end

--// Window ------------------------------------------------------------

local TAB_DESCRIPTIONS = {
	Aimbot = "Targeting, FOV and NPC locks",
	Visuals = "Wallhack, boxes and fill",
	["ESP & Chams"] = "Overlay text and body chams",
	["Tracers & Dots"] = "Tracers, head dots and health",
	Crosshair = "Crosshair and cursor styling",
	Config = "Save, load and manage presets",
	Functions = "Modules, links and utilities",
}

function Library:CreateWindow(options)
	options = options or {}
	local rawTitle = options.Title or "Beertje UI"
	local width = options.Width or 620
	local height = options.Height or 420
	local versionTag = options.Version or "v2.0"
	local footerHint = options.Footer or "Right Shift"

	local displayName, displayTag = rawTitle, nil
	local dotIndex = string.find(rawTitle, "\194\183", 1, true)
	if dotIndex then
		displayName = string.gsub(string.sub(rawTitle, 1, dotIndex - 1), "%s+$", "")
		displayTag = string.gsub(string.sub(rawTitle, dotIndex + 2), "^%s+", "")
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("LegalizeexploitingUI")
	if existing then
		existing:Destroy()
	end

	local gui = new("ScreenGui", {
		Name = "LegalizeexploitingUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
		DisplayOrder = 50,
	}, playerGui)

	local viewport = gui.AbsoluteSize
	if viewport.X > 0 and viewport.Y > 0 then
		width = math.min(width, math.max(500, viewport.X - 24))
		height = math.min(height, math.max(300, viewport.Y - 24))
	end

	local main = new("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(width - 26, height - 20),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui)
	addCorner(main, 12)
	addStroke(main, Theme.Border, 0.35, 1)

	local topLine = new("Frame", {
		Name = "TopLine",
		Size = UDim2.new(1, -36, 0, 1),
		Position = UDim2.fromOffset(18, 0),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		ZIndex = 4,
	}, main)
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.35, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, topLine)

	local titleBar = new("Frame", {
		Name = "TitleBar",
		Size = UDim2.new(1, 0, 0, 56),
		BackgroundTransparency = 1,
	}, main)

	local title = label(titleBar, {
		Name = "Title",
		Size = UDim2.new(1, -240, 0, 18),
		Position = UDim2.fromOffset(18, displayTag and 11 or 19),
		Text = displayName,
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local tagChip, tagLabel
	if displayTag then
		local tagText = string.upper(displayTag)
		local tagWidth = TextService:GetTextSize(
			tagText, 9, Enum.Font.GothamMedium, Vector2.new(1000, 100)
		).X
		tagChip = new("Frame", {
			Name = "Tag",
			Size = UDim2.fromOffset(math.floor(tagWidth) + 14, 15),
			Position = UDim2.fromOffset(18, 29),
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
		}, titleBar)
		addCorner(tagChip, 2)
		tagLabel = label(tagChip, {
			Size = UDim2.new(1, 0, 1, 0),
			Text = tagText,
			TextSize = 9,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Theme.TextFaint,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
	end

	local minBtn = new("TextButton", {
		Name = "Minimize",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -70, 0, 15),
		BackgroundColor3 = Theme.Surface2,
		BackgroundTransparency = 0.4,
		Text = "-",
		TextSize = 15,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.TextDim,
		AutoButtonColor = false,
	}, titleBar)
	addCorner(minBtn, 7)

	local closeBtn = new("TextButton", {
		Name = "Close",
		Size = UDim2.fromOffset(26, 26),
		Position = UDim2.new(1, -40, 0, 15),
		BackgroundColor3 = Theme.Surface2,
		BackgroundTransparency = 0.4,
		Text = "x",
		TextSize = 13,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.TextDim,
		AutoButtonColor = false,
	}, titleBar)
	addCorner(closeBtn, 7)

	minBtn.MouseEnter:Connect(function()
		tween(minBtn, 0.14, {
			BackgroundColor3 = Theme.Surface4,
			BackgroundTransparency = 0.1,
			TextColor3 = Theme.Text,
		})
	end)
	minBtn.MouseLeave:Connect(function()
		tween(minBtn, 0.14, {
			BackgroundColor3 = Theme.Surface2,
			BackgroundTransparency = 0.4,
			TextColor3 = Theme.TextDim,
		})
	end)

	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.14, {
			BackgroundColor3 = Theme.Danger,
			BackgroundTransparency = 0.05,
			TextColor3 = Theme.OnAccent,
		})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.14, {
			BackgroundColor3 = Theme.Surface2,
			BackgroundTransparency = 0.4,
			TextColor3 = Theme.TextDim,
		})
	end)

	local window = {}
	local tabs = {}
	local selectedTab = nil
	local visible = true
	local dragging = false
	local dragStart, startPos
	local dropdowns = {}

	closeBtn.MouseButton1Click:Connect(function()
		tween(main, 0.22, {
			Size = UDim2.fromOffset(width - 60, height - 40),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.24, function()
			gui:Destroy()
		end)
	end)

	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local pos = input.Position
			local function overButton(button)
				local origin = button.AbsolutePosition
				local size = button.AbsoluteSize
				return pos.X >= origin.X and pos.X <= origin.X + size.X
					and pos.Y >= origin.Y and pos.Y <= origin.Y + size.Y
			end
			if overButton(minBtn) or overButton(closeBtn) then
				return
			end
			dragging = true
			dragStart = input.Position
			local absolute = main.AbsolutePosition
			main.AnchorPoint = Vector2.new(0, 0)
			main.Position = UDim2.fromOffset(absolute.X, absolute.Y)
			startPos = main.Position
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local delta = input.Position - dragStart
		local viewport = gui.AbsoluteSize
		local maxX = math.max(0, viewport.X - main.AbsoluteSize.X)
		local maxY = math.max(0, viewport.Y - main.AbsoluteSize.Y)
		main.Position = UDim2.fromOffset(
			math.clamp(startPos.X.Offset + delta.X, 0, maxX),
			math.clamp(startPos.Y.Offset + delta.Y, 0, maxY)
		)
	end)

	function window:Toggle(state)
		if state ~= nil then
			visible = state
		else
			visible = not visible
		end

		if visible then
			main.Visible = true
			tween(main, 0.34, {
				Size = UDim2.fromOffset(width, height),
				BackgroundTransparency = 0,
			}, Enum.EasingStyle.Quint)
		else
			tween(main, 0.24, {
				Size = UDim2.fromOffset(width - 34, height - 26),
			}, Enum.EasingStyle.Quint)
			task.delay(0.26, function()
				if not visible then
					main.Visible = false
				end
			end)
		end
	end

	minBtn.MouseButton1Click:Connect(function()
		window:Toggle()
	end)

	function window:SetTitle(text)
		if typeof(text) ~= "string" or text == "" then return end
		local name = text
		local tag = nil
		local index = string.find(text, "\194\183", 1, true)
		if index then
			name = string.gsub(string.sub(text, 1, index - 1), "%s+$", "")
			tag = string.gsub(string.sub(text, index + 2), "^%s+", "")
		end
		title.Text = name
		if tagLabel then
			tagLabel.Text = tag and string.upper(tag) or ""
		end
	end

	function window:Destroy()
		dragging = false
		gui:Destroy()
	end

	function window:SelectTab(name)
		for _, data in ipairs(tabs) do
			if data.Name == name then
				data.Select()
				return true
			end
		end
		return false
	end

	--// Sidebar ---------------------------------------------------------

	local sidebar = new("ScrollingFrame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 152, 1, -96),
		Position = UDim2.fromOffset(16, 62),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
	}, main)
	addCorner(sidebar, 10)
	addStroke(sidebar, Theme.BorderSoft, 0.25, 1)
	addPadding(sidebar, 10, 10, 8, 8)

	new("UIListLayout", {
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, sidebar)

	label(sidebar, {
		Name = "NavLabel",
		Size = UDim2.new(1, 0, 0, 18),
		Text = "NAVIGATION",
		TextSize = 9,
		Font = Enum.Font.GothamBold,
		TextColor3 = Theme.TextFaint,
		LayoutOrder = 0,
	})

	local footer = new("Frame", {
		Name = "Footer",
		Size = UDim2.new(0, 152, 0, 18),
		Position = UDim2.new(0, 16, 1, -27),
		BackgroundTransparency = 1,
	}, main)

	label(footer, {
		Size = UDim2.new(0.5, -10, 1, 0),
		Position = UDim2.fromOffset(2, 0),
		Text = versionTag,
		TextSize = 9,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Theme.TextFaint,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	label(footer, {
		Size = UDim2.new(0.5, -6, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Text = footerHint,
		TextSize = 9,
		Font = Enum.Font.GothamMedium,
		TextColor3 = Theme.TextFaint,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	--// Content ---------------------------------------------------------

	local content = new("Frame", {
		Name = "Content",
		Size = UDim2.new(1, -196, 1, -76),
		Position = UDim2.fromOffset(180, 62),
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, main)
	addCorner(content, 10)
	addStroke(content, Theme.BorderSoft, 0.25, 1)

	local pageTitle = label(content, {
		Name = "PageTitle",
		Size = UDim2.new(1, -210, 0, 18),
		Position = UDim2.fromOffset(18, 14),
		Text = "",
		TextSize = 14,
		Font = Enum.Font.GothamBold,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local pageDesc = label(content, {
		Name = "PageDesc",
		Size = UDim2.new(1, -210, 0, 13),
		Position = UDim2.fromOffset(18, 32),
		Text = "",
		TextSize = 10,
		TextColor3 = Theme.TextFaint,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local searchBox = new("TextBox", {
		Name = "Search",
		Size = UDim2.fromOffset(146, 26),
		Position = UDim2.new(1, -164, 0, 15),
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Text = "",
		PlaceholderText = "Search",
		PlaceholderColor3 = Theme.TextFaint,
		TextColor3 = Theme.Text,
		TextSize = 11,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, content)
	addCorner(searchBox, 6)
	local searchStroke = addStroke(searchBox, Theme.BorderSoft, 0.2, 1)
	addPadding(searchBox, 0, 0, 9, 8)

	if width - 196 < 330 then
		searchBox.Visible = false
		pageTitle.Size = UDim2.new(1, -36, 0, 18)
		pageDesc.Size = UDim2.new(1, -36, 0, 13)
	end

	searchBox.Focused:Connect(function()
		tween(searchStroke, 0.16, { Color = Theme.Accent, Transparency = 0.45 })
		tween(searchBox, 0.16, { BackgroundColor3 = Theme.Surface3 })
	end)
	searchBox.FocusLost:Connect(function()
		tween(searchStroke, 0.16, { Color = Theme.Border, Transparency = 0.55 })
		tween(searchBox, 0.16, { BackgroundColor3 = Theme.Surface2 })
	end)

	local headerLine = new("Frame", {
		Name = "HeaderLine",
		Size = UDim2.new(1, -36, 0, 1),
		Position = UDim2.fromOffset(18, 52),
		BackgroundColor3 = Theme.BorderSoft,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
	}, content)
	new("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.35),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, headerLine)

	local function applySearch()
		if selectedTab and selectedTab.Filter then
			selectedTab.Filter(searchBox.Text)
		end
	end

	searchBox:GetPropertyChangedSignal("Text"):Connect(applySearch)

	--// Tabs ------------------------------------------------------------

	local tabOrder = 0

	function window:AddTab(name, description)
		tabOrder = tabOrder + 1
		local order = tabOrder

		local tabBtn = new("TextButton", {
			Name = name,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Theme.Surface2,
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
		}, sidebar)
		addCorner(tabBtn, 7)
		local tabStroke = addStroke(tabBtn, Theme.Border, 1, 1)

		local tabLabel = label(tabBtn, {
			Size = UDim2.new(1, -30, 1, 0),
			Position = UDim2.fromOffset(14, 0),
			Text = name,
			TextSize = 12,
			Font = Enum.Font.GothamMedium,
			TextColor3 = Theme.TextDim,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local indicator = new("Frame", {
			Name = "Indicator",
			Size = UDim2.new(0, 2, 0, 0),
			Position = UDim2.new(0, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
		}, tabBtn)
		addCorner(indicator, 2)

		local page = new("ScrollingFrame", {
			Name = name .. "Page",
			Size = UDim2.new(1, 0, 1, -64),
			Position = UDim2.fromOffset(0, 64),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.TextFaint,
			ScrollBarImageTransparency = 0.35,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Visible = false,
			ClipsDescendants = true,
		}, content)
		addPadding(page, 6, 16, 14, 10)

		new("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, page)

		local entries = {}

		local function register(root, text, kind)
			entries[#entries + 1] = {
				root = root,
				text = string.lower(text or ""),
				kind = kind or "item",
			}
		end

		local emptyLabel = label(page, {
			Name = "Empty",
			Size = UDim2.new(1, 0, 0, 36),
			Text = "Nothing matches your search",
			TextSize = 11,
			TextColor3 = Theme.TextFaint,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Visible = false,
			LayoutOrder = 99999,
		})

		local function applyFilter(query)
			query = string.lower(query or "")
			local searching = query ~= ""
			local found = false
			for _, entry in ipairs(entries) do
				local root = entry.root
				if root and root.Parent then
					if entry.kind == "structure" then
						root.Visible = not searching
					else
						local match = not searching
							or string.find(entry.text, query, 1, true) ~= nil
						root.Visible = match
						if searching and match then
							found = true
						end
					end
				end
			end
			emptyLabel.Visible = searching and not found
		end

		local tabData = {
			Name = name,
			Button = tabBtn,
			Label = tabLabel,
			Stroke = tabStroke,
			Indicator = indicator,
			Page = page,
			Filter = applyFilter,
		}

		local function selectTab()
			if selectedTab == tabData then return end
			local previous = selectedTab

			if previous then
				tween(previous.Button, 0.2, {
					BackgroundColor3 = Theme.Surface2,
					BackgroundTransparency = 1,
				})
				tween(previous.Stroke, 0.2, { Transparency = 1 })
				tween(previous.Indicator, 0.2, { Size = UDim2.new(0, 2, 0, 0) })
				previous.Label.TextColor3 = Theme.TextDim
				previous.Page.Visible = false
			end

			selectedTab = tabData

			tween(tabBtn, 0.22, {
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 0.86,
			})
			tween(tabStroke, 0.22, {
				Color = Theme.Accent,
				Transparency = 0.72,
			})
			tween(indicator, 0.28, { Size = UDim2.new(0, 2, 0, 14) })
			tabLabel.TextColor3 = Theme.Text

			page.CanvasPosition = Vector2.new(0, 0)
			page.Position = UDim2.fromOffset(0, 74)
			page.Visible = true
			tween(page, 0.28, { Position = UDim2.fromOffset(0, 64) })

			pageTitle.Text = name
			pageTitle.TextTransparency = 1
			pageTitle.Position = UDim2.fromOffset(18, 17)
			tween(pageTitle, 0.24, {
				TextTransparency = 0,
				Position = UDim2.fromOffset(18, 14),
			})

			pageDesc.Text = description or TAB_DESCRIPTIONS[name] or ("Configure " .. name)
			pageDesc.TextTransparency = 1
			tween(pageDesc, 0.24, { TextTransparency = 0 })

			if searchBox.Text ~= "" then
				searchBox.Text = ""
			else
				applyFilter("")
			end
		end

		tabData.Select = selectTab
		tabs[#tabs + 1] = tabData

		tabBtn.MouseButton1Click:Connect(selectTab)

		tabBtn.MouseEnter:Connect(function()
			if selectedTab == tabData then return end
			tween(tabBtn, 0.14, {
				BackgroundColor3 = Theme.Surface3,
				BackgroundTransparency = 0.35,
			})
			tabLabel.TextColor3 = Theme.Text
		end)

		tabBtn.MouseLeave:Connect(function()
			if selectedTab == tabData then return end
			tween(tabBtn, 0.14, {
				BackgroundColor3 = Theme.Surface2,
				BackgroundTransparency = 1,
			})
			tabLabel.TextColor3 = Theme.TextDim
		end)

		if not selectedTab then
			selectTab()
		end

		local tab = {}
		local elementOrder = 0

		local function nextOrder()
			elementOrder = elementOrder + 1
			return elementOrder
		end

		--// Button ------------------------------------------------------

		function tab:AddButton(opts)
			opts = opts or {}
			local name = opts.Name or "Button"

			local btn = new("TextButton", {
				Name = name,
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Theme.Surface2,
				Text = "",
				AutoButtonColor = false,
				ClipsDescendants = true,
				LayoutOrder = nextOrder(),
			}, page)
			addCorner(btn, 8)
			local stroke = addStroke(btn, Theme.Border, 0.6, 1)

			local nameLabel = label(btn, {
				Size = UDim2.new(1, -26, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				Text = name,
				TextSize = 13,
				Font = Enum.Font.GothamMedium,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local bar = new("Frame", {
				Size = UDim2.new(0, 2, 0, 0),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
			}, btn)
			addCorner(bar, 2)

			register(btn, name, "item")

			btn.MouseEnter:Connect(function()
				cardHover(btn, stroke, true)
				tween(bar, 0.2, { Size = UDim2.new(0, 2, 0, 16) })
			end)

			btn.MouseLeave:Connect(function()
				cardHover(btn, stroke, false)
				tween(bar, 0.2, { Size = UDim2.new(0, 2, 0, 0) })
			end)

			btn.MouseButton1Down:Connect(function()
				tween(btn, 0.1, { BackgroundColor3 = Theme.Surface4 })
			end)

			btn.MouseButton1Up:Connect(function()
				tween(btn, 0.16, { BackgroundColor3 = Theme.Surface3 })
			end)

			btn.MouseButton1Click:Connect(function()
				local mouse = UserInputService:GetMouseLocation()
				ripple(btn, mouse.X - btn.AbsolutePosition.X, mouse.Y - btn.AbsolutePosition.Y)
				if typeof(opts.Callback) == "function" then
					task.spawn(opts.Callback)
				end
			end)

			return btn
		end

		--// Toggle ------------------------------------------------------

		function tab:AddToggle(opts)
			opts = opts or {}
			local name = opts.Name or "Toggle"
			local description = opts.Description
			local callback = opts.Callback
			local state = opts.Default == true

			local holder, stroke = card(page, description and 52 or 38, nextOrder())

			local nameLabel = label(holder, {
				Size = UDim2.new(1, -74, 0, 16),
				Position = UDim2.fromOffset(14, description and 9 or 11),
				Text = name,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			if description then
				label(holder, {
					Size = UDim2.new(1, -74, 0, 14),
					Position = UDim2.fromOffset(14, 27),
					Text = description,
					TextSize = 10,
					TextColor3 = Theme.TextFaint,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
			end

			local box = new("Frame", {
				Name = "Checkbox",
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.new(1, -30, 0.5, -8),
				BackgroundColor3 = state and Theme.Accent or Theme.Surface3,
				BackgroundTransparency = state and 0 or 0.15,
				BorderSizePixel = 0,
			}, holder)
			addCorner(box, 1)
			local boxStroke = addStroke(
				box,
				state and Theme.Accent or Theme.Border,
				state and 0.2 or 0.3,
				1
			)

			local markShort = new("Frame", {
				Name = "MarkShort",
				Size = UDim2.fromOffset(6, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(5, 10),
				Rotation = 45,
				BackgroundColor3 = Theme.OnAccent,
				BackgroundTransparency = state and 0 or 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, box)
			addCorner(markShort, 1)

			local markLong = new("Frame", {
				Name = "MarkLong",
				Size = UDim2.fromOffset(10, 2),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(10, 8),
				Rotation = -45,
				BackgroundColor3 = Theme.OnAccent,
				BackgroundTransparency = state and 0 or 1,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, box)
			addCorner(markLong, 1)

			local function render(animate, silent)
				local fill = state and Theme.Accent or Theme.Surface3
				local fillAlpha = state and 0 or 0.15
				local edge = state and Theme.Accent or Theme.Border
				local edgeAlpha = state and 1 or 0.3
				local markAlpha = state and 0 or 1

				if animate then
					tween(box, 0.16, {
						BackgroundColor3 = fill,
						BackgroundTransparency = fillAlpha,
					})
					tween(boxStroke, 0.16, {
						Color = edge,
						Transparency = edgeAlpha,
					})
					tween(markShort, 0.14, { BackgroundTransparency = markAlpha })
					tween(markLong, 0.14, { BackgroundTransparency = markAlpha })
				else
					box.BackgroundColor3 = fill
					box.BackgroundTransparency = fillAlpha
					boxStroke.Color = edge
					boxStroke.Transparency = edgeAlpha
					markShort.BackgroundTransparency = markAlpha
					markLong.BackgroundTransparency = markAlpha
				end

				if not silent and typeof(callback) == "function" then
					task.spawn(callback, state)
				end
			end

			local click = new("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, holder)

			click.MouseButton1Click:Connect(function()
				state = not state
				render(true, false)
			end)

			click.MouseEnter:Connect(function()
				cardHover(holder, stroke, true)
			end)
			click.MouseLeave:Connect(function()
				cardHover(holder, stroke, false)
			end)

			register(holder, name, "item")

			return {
				Set = function(_, value, silent)
					state = value == true
					render(true, silent)
				end,
				Get = function()
					return state
				end,
			}
		end

		--// Textbox -----------------------------------------------------

		function tab:AddTextbox(opts)
			opts = opts or {}
			local name = opts.Name or "Textbox"
			local placeholder = opts.Placeholder or "Type here..."
			local callback = opts.Callback

			local holder, stroke = card(page, 62, nextOrder())

			label(holder, {
				Size = UDim2.new(1, -28, 0, 14),
				Position = UDim2.fromOffset(14, 7),
				Text = name,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local box = new("TextBox", {
				Name = "Input",
				Size = UDim2.new(1, -28, 0, 28),
				Position = UDim2.fromOffset(14, 24),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
				Text = opts.Default or "",
				PlaceholderText = placeholder,
				PlaceholderColor3 = Theme.TextFaint,
				TextColor3 = Theme.Text,
				TextSize = 12,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
			}, holder)
			addCorner(box, 6)
			local boxStroke = addStroke(box, Theme.BorderSoft, 0.2, 1)
			addPadding(box, 0, 0, 10, 30)

			local clearBtn = new("TextButton", {
				Name = "Clear",
				Size = UDim2.fromOffset(18, 18),
				Position = UDim2.new(1, -33, 0, 29),
				BackgroundTransparency = 1,
				Text = "x",
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.TextFaint,
				Visible = box.Text ~= "",
				AutoButtonColor = false,
			}, holder)

			clearBtn.MouseEnter:Connect(function()
				tween(clearBtn, 0.12, { TextColor3 = Theme.Text })
			end)
			clearBtn.MouseLeave:Connect(function()
				tween(clearBtn, 0.12, { TextColor3 = Theme.TextFaint })
			end)

			box:GetPropertyChangedSignal("Text"):Connect(function()
				clearBtn.Visible = box.Text ~= ""
			end)

			clearBtn.MouseButton1Click:Connect(function()
				box.Text = ""
				if typeof(callback) == "function" then
					task.spawn(callback, "", false)
				end
			end)

			box.Focused:Connect(function()
				tween(box, 0.16, { BackgroundColor3 = Theme.Surface2 })
				tween(boxStroke, 0.16, { Color = Theme.Accent, Transparency = 0.45 })
				tween(holder, 0.16, { BackgroundColor3 = Theme.Surface3 })
			end)

			box.FocusLost:Connect(function(enter)
				tween(box, 0.16, { BackgroundColor3 = Theme.Surface3 })
				tween(boxStroke, 0.16, { Color = Theme.Border, Transparency = 0.55 })
				tween(holder, 0.16, { BackgroundColor3 = Theme.Surface2 })
				if typeof(callback) == "function" then
					task.spawn(callback, box.Text, enter)
				end
			end)

			register(holder, name, "item")
			return box
		end

		--// Slider ------------------------------------------------------

		function tab:AddSlider(opts)
			opts = opts or {}
			local name = opts.Name or "Slider"
			local minValue = opts.Min or 0
			local maxValue = opts.Max or 100
			if maxValue <= minValue then
				maxValue = minValue + 1
			end
			local decimals = opts.Decimals or 0
			local callback = opts.Callback
			local value = math.clamp(opts.Default or minValue, minValue, maxValue)

			local function format(v)
				return string.format("%." .. decimals .. "f", v)
			end

			local holder = card(page, 62, nextOrder())

			label(holder, {
				Size = UDim2.new(1, -108, 0, 16),
				Position = UDim2.fromOffset(14, 9),
				Text = name,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.TextDim,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local chip = new("Frame", {
				Name = "Value",
				Size = UDim2.fromOffset(64, 20),
				Position = UDim2.new(1, -78, 0, 6),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
			}, holder)
			addCorner(chip, 1)
			local chipStroke = addStroke(chip, Theme.BorderSoft, 0.3, 1)

			local valueLabel = label(chip, {
				Size = UDim2.new(1, 0, 1, 0),
				Text = format(value),
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local track = new("Frame", {
				Name = "Track",
				Size = UDim2.new(1, -28, 0, 6),
				Position = UDim2.fromOffset(14, 36),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
			}, holder)
			addCorner(track, 1)
			local trackStroke = addStroke(track, Theme.BorderSoft, 0.4, 1)

			local fill = new("Frame", {
				Name = "Fill",
				Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
			}, track)
			addCorner(fill, 1)
			new("UIGradient", {
				Color = ColorSequence.new(Theme.TextDim, Theme.Text),
			}, fill)

			local knob = new("Frame", {
				Name = "Knob",
				Size = UDim2.fromOffset(10, 18),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new((value - minValue) / (maxValue - minValue), 0, 0.5, 0),
				BackgroundColor3 = Theme.Text,
				BorderSizePixel = 0,
				ZIndex = 3,
			}, track)
			addCorner(knob, 1)
			addStroke(knob, Theme.Background, 0.15, 1)

			new("Frame", {
				Name = "Grip",
				Size = UDim2.fromOffset(2, 6),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = Theme.Background,
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
				ZIndex = 4,
			}, knob)

			label(holder, {
				Size = UDim2.new(0, 60, 0, 11),
				Position = UDim2.fromOffset(14, 47),
				Text = format(minValue),
				TextSize = 9,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.TextFaint,
				TextYAlignment = Enum.TextYAlignment.Center,
			})

			label(holder, {
				Size = UDim2.new(0, 60, 0, 11),
				Position = UDim2.new(1, -74, 0, 47),
				Text = format(maxValue),
				TextSize = 9,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.TextFaint,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
			})

			local sliding = false
			local hovered = false

			local hit = new("TextButton", {
				Name = "Hit",
				Size = UDim2.new(1, -20, 0, 22),
				Position = UDim2.fromOffset(10, 27),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
			}, holder)

			local function update(nextValue, fire)
				value = math.clamp(nextValue, minValue, maxValue)
				local percent = (value - minValue) / (maxValue - minValue)
				fill.Size = UDim2.new(percent, 0, 1, 0)
				knob.Position = UDim2.new(percent, 0, 0.5, 0)
				valueLabel.Text = format(value)
				if fire and typeof(callback) == "function" then
					task.spawn(callback, value)
				end
			end

			local function fromInput(input)
				local relative = (input.Position.X - track.AbsolutePosition.X)
					/ math.max(track.AbsoluteSize.X, 1)
				relative = math.clamp(relative, 0, 1)
				update(minValue + relative * (maxValue - minValue), true)
			end

			local function setHover(on)
				hovered = on
				tween(track, 0.16, {
					BackgroundColor3 = on and Theme.Surface4 or Theme.Surface3,
				})
				tween(trackStroke, 0.16, {
					Color = on and Theme.Border or Theme.BorderSoft,
					Transparency = on and 0.1 or 0.4,
				})
				tween(chipStroke, 0.16, {
					Color = on and Theme.Border or Theme.BorderSoft,
					Transparency = on and 0.1 or 0.3,
				})
				if not sliding then
					tween(knob, 0.16, {
						Size = on and UDim2.fromOffset(12, 20) or UDim2.fromOffset(10, 18),
					})
				end
			end

			hit.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					fromInput(input)
					tween(knob, 0.12, { Size = UDim2.fromOffset(12, 22) })
					tween(chip, 0.12, { BackgroundColor3 = Theme.Surface4 })
				end
			end)

			hit.MouseEnter:Connect(function()
				setHover(true)
			end)

			hit.MouseLeave:Connect(function()
				setHover(false)
			end)

			UserInputService.InputChanged:Connect(function(input)
				if not sliding then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch then
					fromInput(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					if not sliding then return end
					sliding = false
					tween(knob, 0.16, {
						Size = hovered and UDim2.fromOffset(12, 20) or UDim2.fromOffset(10, 18),
					})
					tween(chip, 0.16, { BackgroundColor3 = Theme.Surface3 })
				end
			end)

			register(holder, name, "item")

			return {
				Set = function(_, nextValue)
					update(nextValue, true)
				end,
				Get = function()
					return value
				end,
			}
		end

		--// Color picker ------------------------------------------------

		function tab:AddColorPicker(opts)
			opts = opts or {}
			local name = opts.Name or "Color"
			local callback = opts.Callback
			local current = opts.Default or Color3.fromRGB(255, 255, 255)
			local h, s, v = Color3.toHSV(current)
			local svWidth = math.clamp(math.floor((width - 254) * 0.55), 110, 196)
			local sideX = svWidth + 34

			local holder, stroke = card(page, 42, nextOrder())
			holder.ClipsDescendants = true

			label(holder, {
				Size = UDim2.new(1, -70, 0, 42),
				Position = UDim2.fromOffset(14, 0),
				Text = name,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local preview = new("Frame", {
				Name = "Preview",
				Size = UDim2.fromOffset(24, 24),
				Position = UDim2.new(1, -38, 0, 9),
				BackgroundColor3 = current,
				BorderSizePixel = 0,
			}, holder)
			addCorner(preview, 6)
			addStroke(preview, Theme.Border, 0.35, 1)

			local panel = new("Frame", {
				Name = "Panel",
				Size = UDim2.new(1, -28, 0, 0),
				Position = UDim2.fromOffset(14, 46),
				BackgroundTransparency = 1,
				ClipsDescendants = true,
			}, holder)

			local svFrame = new("Frame", {
				Name = "SaturationValue",
				Size = UDim2.fromOffset(svWidth, 140),
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				BorderSizePixel = 0,
			}, panel)
			addCorner(svFrame, 8)

			local satGrad = new("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
				}),
			}, svFrame)

			local valueOverlay = new("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BorderSizePixel = 0,
			}, svFrame)
			addCorner(valueOverlay, 8)
			new("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				}),
			}, valueOverlay)

			local svCursor = new("Frame", {
				Size = UDim2.fromOffset(10, 10),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 3,
			}, svFrame)
			addCorner(svCursor, 5)
			addStroke(svCursor, Color3.new(0, 0, 0), 0.35, 1)

			local hueTrack = new("Frame", {
				Name = "Hue",
				Size = UDim2.fromOffset(20, 140),
				Position = UDim2.fromOffset(svWidth + 8, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
			}, panel)
			addCorner(hueTrack, 6)
			new("UIGradient", {
				Rotation = 90,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				}),
			}, hueTrack)

			local hueCursor = new("Frame", {
				Size = UDim2.new(1, 6, 0, 5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				ZIndex = 3,
			}, hueTrack)
			addCorner(hueCursor, 2)
			addStroke(hueCursor, Color3.new(0, 0, 0), 0.45, 1)

			label(panel, {
				Size = UDim2.new(1, -(sideX + 8), 0, 12),
				Position = UDim2.fromOffset(sideX, 4),
				Text = "HEX",
				TextSize = 9,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.TextFaint,
			})

			local hexBox = new("TextBox", {
				Name = "Hex",
				Size = UDim2.new(1, -(sideX + 8), 0, 26),
				Position = UDim2.fromOffset(sideX, 18),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
				Text = "",
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.Text,
				TextXAlignment = Enum.TextXAlignment.Center,
				ClearTextOnFocus = false,
			}, panel)
			addCorner(hexBox, 6)
			addStroke(hexBox, Theme.BorderSoft, 0.3, 1)

			label(panel, {
				Size = UDim2.new(1, -(sideX + 8), 0, 12),
				Position = UDim2.fromOffset(sideX, 52),
				Text = "RGB",
				TextSize = 9,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.TextFaint,
			})

			local rgbLabel = label(panel, {
				Size = UDim2.new(1, -(sideX + 8), 0, 14),
				Position = UDim2.fromOffset(sideX, 66),
				Text = "",
				TextSize = 10,
				TextColor3 = Theme.TextDim,
			})

			local function hexText(color)
				return string.format("#%02X%02X%02X",
					math.floor(color.R * 255 + 0.5),
					math.floor(color.G * 255 + 0.5),
					math.floor(color.B * 255 + 0.5))
			end

			local function updateColor(fire)
				current = Color3.fromHSV(h, s, v)
				preview.BackgroundColor3 = current
				svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				satGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
				})
				if not hexBox:IsFocused() then
					hexBox.Text = hexText(current)
				end
				rgbLabel.Text = string.format("%d, %d, %d",
					math.floor(current.R * 255 + 0.5),
					math.floor(current.G * 255 + 0.5),
					math.floor(current.B * 255 + 0.5))
				if fire and typeof(callback) == "function" then
					task.spawn(callback, current)
				end
			end

			local draggingSV = false
			local draggingHue = false

			local function applySV(input)
				local relative = Vector2.new(input.Position.X, input.Position.Y) - svFrame.AbsolutePosition
				s = math.clamp(relative.X / math.max(svFrame.AbsoluteSize.X, 1), 0, 1)
				v = 1 - math.clamp(relative.Y / math.max(svFrame.AbsoluteSize.Y, 1), 0, 1)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				updateColor(true)
			end

			local function applyHue(input)
				local relative = (input.Position.Y - hueTrack.AbsolutePosition.Y)
					/ math.max(hueTrack.AbsoluteSize.Y, 1)
				h = math.clamp(relative, 0, 1)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				updateColor(true)
			end

			svFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = true
					applySV(input)
				end
			end)

			hueTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingHue = true
					applyHue(input)
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement
					and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				if draggingSV then
					applySV(input)
				elseif draggingHue then
					applyHue(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = false
					draggingHue = false
				end
			end)

			hexBox.FocusLost:Connect(function()
				local text = string.gsub(hexBox.Text, "#", "")
				if string.match(text, "^%x%x%x%x%x%x$") then
					local r = tonumber(string.sub(text, 1, 2), 16) / 255
					local g = tonumber(string.sub(text, 3, 4), 16) / 255
					local b = tonumber(string.sub(text, 5, 6), 16) / 255
					current = Color3.new(r, g, b)
					h, s, v = Color3.toHSV(current)
					svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					hueCursor.Position = UDim2.new(0.5, 0, h, 0)
					updateColor(true)
				end
				updateColor(false)
			end)

			local open = false

			local headerBtn = new("TextButton", {
				Name = "Header",
				Size = UDim2.new(1, 0, 0, 42),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, holder)

			headerBtn.MouseButton1Click:Connect(function()
				open = not open
				tween(holder, 0.34, {
					Size = UDim2.new(1, 0, 0, open and 196 or 42),
				}, Enum.EasingStyle.Quint)
				tween(panel, 0.34, {
					Size = UDim2.new(1, -28, 0, open and 140 or 0),
				}, Enum.EasingStyle.Quint)
			end)

			headerBtn.MouseEnter:Connect(function()
				cardHover(holder, stroke, true)
			end)
			headerBtn.MouseLeave:Connect(function()
				cardHover(holder, stroke, false)
			end)

			updateColor(false)
			register(holder, name, "item")

			return {
				Set = function(_, color)
					current = color
					h, s, v = Color3.toHSV(color)
					svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					hueCursor.Position = UDim2.new(0.5, 0, h, 0)
					updateColor(false)
				end,
				Get = function()
					return current
				end,
			}
		end

		--// Label -------------------------------------------------------

		function tab:AddLabel(opts)
			opts = opts or {}
			local text = opts.Text or opts.Name or ""

			local textLabel = label(page, {
				Name = "Label",
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = text,
				TextSize = opts.Size or 12,
				TextColor3 = opts.Color or Theme.TextDim,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LayoutOrder = nextOrder(),
			})

			register(textLabel, text, "item")
			return textLabel
		end

		--// Paragraph ---------------------------------------------------

		function tab:AddParagraph(opts)
			opts = opts or {}
			local titleText = opts.Title or opts.Name or "Info"
			local contentText = opts.Content or opts.Text or ""

			local holder = new("Frame", {
				Name = titleText,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Theme.Surface2,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, page)
			addCorner(holder, 8)
			addStroke(holder, Theme.Border, 0.6, 1)
			addPadding(holder, 12, 12, 14, 14)

			new("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, holder)

			local titleLabel = label(holder, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = titleText,
				TextSize = 12,
				Font = Enum.Font.GothamBold,
				TextWrapped = true,
				LayoutOrder = 1,
			})

			local bodyLabel = label(holder, {
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = contentText,
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				LayoutOrder = 2,
			})

			register(holder, titleText .. " " .. contentText, "item")

			return {
				SetTitle = function(_, value)
					titleLabel.Text = value
				end,
				SetContent = function(_, value)
					bodyLabel.Text = value
				end,
			}
		end

		--// Section -----------------------------------------------------

		function tab:AddSection(opts)
			opts = opts or {}
			local name = opts.Name or "Section"

			local holder = new("Frame", {
				Name = name,
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
			}, page)

			label(holder, {
				Size = UDim2.new(1, 0, 0, 16),
				Text = string.upper(name),
				TextSize = 9,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.TextFaint,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			})

			local line = new("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 1, -1),
				BackgroundColor3 = Theme.BorderSoft,
				BackgroundTransparency = 0.1,
				BorderSizePixel = 0,
			}, holder)
			new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.65, 0.4),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, line)

			register(holder, name, "structure")
			return holder
		end

		function tab:AddSeparator()
			local separator = new("Frame", {
				Name = "Separator",
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = Theme.BorderSoft,
				BackgroundTransparency = 0.2,
				BorderSizePixel = 0,
				LayoutOrder = nextOrder(),
			}, page)
			new("UIGradient", {
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.5, 0),
					NumberSequenceKeypoint.new(1, 1),
				}),
			}, separator)
			register(separator, "", "structure")
			return separator
		end

		--// Keybind -----------------------------------------------------

		function tab:AddKeybind(opts)
			opts = opts or {}
			local name = opts.Name or "Keybind"
			local callback = opts.Callback
			local current = opts.Default or Enum.KeyCode.Unknown

			local function displayName(bind)
				if typeof(bind) == "EnumItem" then
					if bind.EnumType == Enum.KeyCode then
						if bind == Enum.KeyCode.Unknown then
							return "None"
						end
						return bind.Name
					end
					if bind.EnumType == Enum.UserInputType then
						if bind == Enum.UserInputType.MouseButton1 then return "M1" end
						if bind == Enum.UserInputType.MouseButton2 then return "M2" end
						if bind == Enum.UserInputType.MouseButton3 then return "M3" end
						return bind.Name
					end
				end
				if type(bind) == "string" then
					return bind
				end
				return "None"
			end

			local holder, stroke = card(page, 38, nextOrder())

			local nameLabel = label(holder, {
				Size = UDim2.new(1, -122, 1, 0),
				Position = UDim2.fromOffset(14, 0),
				Text = name,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local keyBtn = new("TextButton", {
				Name = "Key",
				Size = UDim2.fromOffset(88, 22),
				Position = UDim2.new(1, -102, 0.5, -11),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
				Text = displayName(current),
				TextSize = 10,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.TextDim,
				AutoButtonColor = false,
			}, holder)
			addCorner(keyBtn, 5)
			local keyStroke = addStroke(keyBtn, Theme.BorderSoft, 0.3, 1)

			local listening = false

			local function setListening(on)
				listening = on
				if on then
					nameLabel.Text = "Press a key..."
					nameLabel.TextColor3 = Theme.Accent
					keyBtn.Text = "..."
					tween(keyBtn, 0.14, {
						BackgroundColor3 = Theme.Accent,
						BackgroundTransparency = 0.85,
						TextColor3 = Theme.Accent,
					})
					tween(keyStroke, 0.14, {
						Color = Theme.Accent,
						Transparency = 0.5,
					})
				else
					nameLabel.Text = name
					nameLabel.TextColor3 = Theme.Text
					keyBtn.Text = displayName(current)
					tween(keyBtn, 0.14, {
						BackgroundColor3 = Theme.Surface3,
						BackgroundTransparency = 0,
						TextColor3 = Theme.TextDim,
					})
					tween(keyStroke, 0.14, {
						Color = Theme.BorderSoft,
						Transparency = 0.3,
					})
				end
			end

			local function finishBind(bind)
				current = bind
				setListening(false)
				if typeof(callback) == "function" then
					task.spawn(callback, bind, displayName(bind))
				end
			end

			keyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				setListening(true)
			end)

			keyBtn.MouseEnter:Connect(function()
				if listening then return end
				tween(keyBtn, 0.14, { BackgroundColor3 = Theme.Surface4 })
				tween(keyStroke, 0.14, { Transparency = 0.15 })
			end)

			keyBtn.MouseLeave:Connect(function()
				if listening then return end
				tween(keyBtn, 0.14, { BackgroundColor3 = Theme.Surface3 })
			end)

			UserInputService.InputBegan:Connect(function(input)
				if not listening then return end

				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape then
						setListening(false)
						return
					end
					finishBind(input.KeyCode)
					return
				end

				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3 then
					finishBind(input.UserInputType)
				end
			end)

			register(holder, name, "item")

			return {
				Get = function()
					return current
				end,
				Set = function(_, bind)
					current = bind
					if not listening then
						keyBtn.Text = displayName(bind)
					end
				end,
			}
		end

		--// Dropdown ----------------------------------------------------

		function tab:AddDropdown(opts)
			opts = opts or {}
			local name = opts.Name or "Dropdown"
			local list = opts.Options or { "Option 1", "Option 2" }
			local callback = opts.Callback
			local selected = opts.Default or list[1]
			local open = false

			local rowHeight, rowGap = 28, 2
			local contentHeight = #list * rowHeight + math.max(0, #list - 1) * rowGap + 10
			local listHeight = math.min(contentHeight, 190)

			local holder, stroke = card(page, 38, nextOrder())
			holder.ClipsDescendants = true

			local nameLabel = label(holder, {
				Size = UDim2.new(1, -180, 0, 38),
				Position = UDim2.fromOffset(14, 0),
				Text = name,
				TextSize = 12,
				Font = Enum.Font.GothamMedium,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local valueLabel = label(holder, {
				Size = UDim2.new(0, 108, 0, 38),
				Position = UDim2.new(1, -134, 0, 0),
				Text = tostring(selected),
				TextSize = 11,
				TextColor3 = Theme.TextDim,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local caret = label(holder, {
				Size = UDim2.fromOffset(18, 38),
				Position = UDim2.new(1, -25, 0, 0),
				Text = "v",
				TextSize = 10,
				Font = Enum.Font.GothamBold,
				TextColor3 = Theme.TextFaint,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			})

			local listFrame = new("ScrollingFrame", {
				Name = "Options",
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.fromOffset(0, 38),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.TextFaint,
				ScrollBarImageTransparency = 0.35,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ClipsDescendants = true,
			}, holder)
			addPadding(listFrame, 4, 6, 6, 6)
			new("UIListLayout", {
				Padding = UDim.new(0, rowGap),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, listFrame)

			local views = {}
			local closeSelf

			local function refresh()
				valueLabel.Text = tostring(selected)
				for index, option in ipairs(list) do
					local view = views[index]
					if view then
						local active = option == selected
						view.label.TextColor3 = active and Theme.Text or Theme.TextDim
						view.label.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
					end
				end
			end

			for index, option in ipairs(list) do
				local row = new("TextButton", {
					Name = tostring(option),
					Size = UDim2.new(1, 0, 0, rowHeight),
					BackgroundColor3 = Theme.Surface3,
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = index,
				}, listFrame)
				addCorner(row, 6)

				local optionLabel = label(row, {
					Size = UDim2.new(1, -26, 1, 0),
					Position = UDim2.fromOffset(10, 0),
					Text = tostring(option),
					TextSize = 11,
					TextColor3 = Theme.TextDim,
					TextYAlignment = Enum.TextYAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
				})

				views[index] = { label = optionLabel }

				row.MouseEnter:Connect(function()
					optionLabel.TextColor3 = Theme.Text
					tween(row, 0.12, {
						BackgroundColor3 = Theme.Surface4,
						BackgroundTransparency = 0.25,
					})
				end)

				row.MouseLeave:Connect(function()
					tween(row, 0.12, { BackgroundTransparency = 1 })
					refresh()
				end)

				row.MouseButton1Click:Connect(function()
					selected = option
					refresh()
					closeSelf()
					if typeof(callback) == "function" then
						task.spawn(callback, selected)
					end
				end)
			end

			local function setOpen(value)
				if open == value then return end
				open = value

				if open then
					for _, close in ipairs(dropdowns) do
						if close ~= closeSelf then
							close()
						end
					end
				end

				tween(holder, 0.26, {
					Size = UDim2.new(1, 0, 0, open and (38 + listHeight + 4) or 38),
				}, Enum.EasingStyle.Quint)
				tween(listFrame, 0.26, {
					Size = UDim2.new(1, 0, 0, open and listHeight or 0),
				}, Enum.EasingStyle.Quint)
				tween(caret, 0.22, {
					Rotation = open and 180 or 0,
				}, Enum.EasingStyle.Quint)
				if stroke then
					tween(stroke, 0.2, {
						Color = open and Theme.Accent or Theme.Border,
						Transparency = open and 0.7 or 0.6,
					})
				end
			end

			closeSelf = function()
				setOpen(false)
			end

			dropdowns[#dropdowns + 1] = closeSelf

			local header = new("TextButton", {
				Name = "Header",
				Size = UDim2.new(1, 0, 0, 38),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
			}, holder)

			header.MouseButton1Click:Connect(function()
				setOpen(not open)
			end)

			header.MouseEnter:Connect(function()
				cardHover(holder, stroke, true)
			end)
			header.MouseLeave:Connect(function()
				cardHover(holder, stroke, false)
			end)

			refresh()
			register(holder, name, "item")

			return {
				Get = function()
					return selected
				end,
				Set = function(_, value)
					selected = value
					refresh()
				end,
				Open = function()
					setOpen(true)
				end,
				Close = closeSelf,
			}
		end

		--// Progress bar ------------------------------------------------

		function tab:AddProgressBar(opts)
			opts = opts or {}
			local name = opts.Name or "Progress"
			local value = math.clamp(opts.Default or 0, 0, 1)

			local holder, stroke = card(page, 46, nextOrder())

			label(holder, {
				Size = UDim2.new(1, -80, 0, 16),
				Position = UDim2.fromOffset(14, 8),
				Text = name,
				TextSize = 12,
				TextColor3 = Theme.TextDim,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})

			local percentLabel = label(holder, {
				Size = UDim2.new(0, 60, 0, 16),
				Position = UDim2.new(1, -74, 0, 8),
				Text = string.format("%d%%", math.floor(value * 100)),
				TextSize = 11,
				Font = Enum.Font.GothamMedium,
				TextColor3 = Theme.Accent,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextYAlignment = Enum.TextYAlignment.Center,
			})

			local track = new("Frame", {
				Name = "Track",
				Size = UDim2.new(1, -28, 0, 6),
				Position = UDim2.fromOffset(14, 30),
				BackgroundColor3 = Theme.Surface3,
				BorderSizePixel = 0,
			}, holder)
			addCorner(track, 3)

			local fill = new("Frame", {
				Name = "Fill",
				Size = UDim2.new(value, 0, 1, 0),
				BackgroundColor3 = Theme.Accent,
				BorderSizePixel = 0,
			}, track)
			addCorner(fill, 3)

			register(holder, name, "item")

			return {
				Set = function(_, nextValue)
					value = math.clamp(nextValue, 0, 1)
					tween(fill, 0.28, { Size = UDim2.new(value, 0, 1, 0) })
					percentLabel.Text = string.format("%d%%", math.floor(value * 100))
				end,
				Get = function()
					return value
				end,
			}
		end

		--// Button group ------------------------------------------------

		function tab:AddButtonGroup(opts)
			opts = opts or {}
			local buttons = opts.Buttons or {}

			local holder = new("Frame", {
				Name = "ButtonGroup",
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				LayoutOrder = nextOrder(),
			}, page)
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, holder)

			local count = math.max(#buttons, 1)
			local names = {}

			for index, buttonOpts in ipairs(buttons) do
				local text = buttonOpts.Name or "Button"
				names[#names + 1] = text

				local btn = new("TextButton", {
					Name = text,
					Size = UDim2.new(1 / count, -6, 1, 0),
					BackgroundColor3 = Theme.Surface2,
					Text = text,
					TextSize = 11,
					Font = Enum.Font.GothamMedium,
					TextColor3 = Theme.Text,
					AutoButtonColor = false,
					ClipsDescendants = true,
					LayoutOrder = index,
				}, holder)
				addCorner(btn, 7)
				local btnStroke = addStroke(btn, Theme.Border, 0.6, 1)

				btn.MouseEnter:Connect(function()
					cardHover(btn, btnStroke, true)
				end)
				btn.MouseLeave:Connect(function()
					cardHover(btn, btnStroke, false)
				end)
				btn.MouseButton1Click:Connect(function()
					local mouse = UserInputService:GetMouseLocation()
					ripple(btn, mouse.X - btn.AbsolutePosition.X, mouse.Y - btn.AbsolutePosition.Y)
					if typeof(buttonOpts.Callback) == "function" then
						task.spawn(buttonOpts.Callback)
					end
				end)
			end

			register(holder, table.concat(names, " "), "item")
			return holder
		end

		return tab
	end

	tween(main, 0.42, {
		Size = UDim2.fromOffset(width, height),
	}, Enum.EasingStyle.Quint)

	return window
end

return Library







