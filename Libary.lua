local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local Library = {}
Library.__index = Library

local Theme = {
	Background   = Color3.fromRGB(14, 14, 17),
	Panel        = Color3.fromRGB(20, 20, 24),
	Element      = Color3.fromRGB(30, 30, 36),
	ElementAlt   = Color3.fromRGB(36, 36, 42),
	Hover        = Color3.fromRGB(46, 46, 54),
	Active       = Color3.fromRGB(58, 58, 68),
	Accent       = Color3.fromRGB(255, 255, 255),
	Text         = Color3.fromRGB(235, 235, 240),
	Muted        = Color3.fromRGB(140, 140, 150),
	Border       = Color3.fromRGB(55, 55, 65),
	Success      = Color3.fromRGB(100, 200, 140),
	Warning      = Color3.fromRGB(220, 180, 80),
	Danger       = Color3.fromRGB(220, 90, 90),
	Info         = Color3.fromRGB(120, 160, 220),
}

local activeTweens = setmetatable({}, { __mode = "k" })

local function tween(obj, duration, props, style, direction)
	if not obj or not obj.Parent then return end

	local running = activeTweens[obj]
	if running then
		for _, t in pairs(running) do
			pcall(function() t:Cancel() end)
		end
	end
	activeTweens[obj] = {}

	local info = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)
	local t = TweenService:Create(obj, info, props)
	table.insert(activeTweens[obj], t)

	t.Completed:Connect(function()
		local list = activeTweens[obj]
		if list then
			for i, v in ipairs(list) do
				if v == t then
					table.remove(list, i)
					break
				end
			end
		end
	end)

	t:Play()
	return t
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
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

local function ripple(parent, x, y)
	local circle = Instance.new("Frame")
	circle.Name = "Ripple"
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.fromOffset(x, y)
	circle.Size = UDim2.fromOffset(0, 0)
	circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	circle.BackgroundTransparency = 0.7
	circle.BorderSizePixel = 0
	circle.ZIndex = 10
	circle.Parent = parent
	addCorner(circle, 999)

	local maxSize = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.2
	tween(circle, 0.45, {
		Size = UDim2.fromOffset(maxSize, maxSize),
		BackgroundTransparency = 1
	}, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	task.delay(0.5, function()
		if circle and circle.Parent then
			circle:Destroy()
		end
	end)
end

local NotificationContainer = nil

local function ensureNotificationContainer()
	if NotificationContainer and NotificationContainer.Parent then
		return NotificationContainer
	end

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = playerGui:FindFirstChild("LegalizeexploitingNotifications")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "LegalizeexploitingNotifications"
		gui.ResetOnSpawn = false
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.DisplayOrder = 100
		gui.IgnoreGuiInset = true
		gui.Parent = playerGui
	end

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, 320, 1, -40)
	container.Position = UDim2.new(1, -340, 0, 20)
	container.BackgroundTransparency = 1
	container.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Parent = container

	NotificationContainer = container
	return container
end

function Library:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "Notification"
	local content = opts.Content or opts.Text or ""
	local duration = opts.Duration or 4
	local notifType = opts.Type or "Info"

	local accentColor = Theme.Info
	if notifType == "Success" then
		accentColor = Theme.Success
	elseif notifType == "Warning" then
		accentColor = Theme.Warning
	elseif notifType == "Error" or notifType == "Danger" then
		accentColor = Theme.Danger
	end

	local container = ensureNotificationContainer()

	local notif = Instance.new("Frame")
	notif.Name = "Notification"
	notif.Size = UDim2.fromOffset(300, 0)
	notif.BackgroundColor3 = Theme.Background
	notif.BackgroundTransparency = 0.08
	notif.BorderSizePixel = 0
	notif.ClipsDescendants = true
	notif.Parent = container
	addCorner(notif, 12)
	addStroke(notif, Theme.Border, 0.4, 1.1)

	local accent = Instance.new("Frame")
	accent.Size = UDim2.fromOffset(4, 0)
	accent.Position = UDim2.fromOffset(0, 0)
	accent.BackgroundColor3 = accentColor
	accent.BackgroundTransparency = 0.15
	accent.BorderSizePixel = 0
	accent.Parent = notif
	addCorner(accent, 2)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -50, 0, 22)
	titleLabel.Position = UDim2.fromOffset(16, 12)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Theme.Text
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
	titleLabel.Parent = notif

	local contentLabel = Instance.new("TextLabel")
	contentLabel.Size = UDim2.new(1, -28, 0, 0)
	contentLabel.Position = UDim2.fromOffset(16, 36)
	contentLabel.BackgroundTransparency = 1
	contentLabel.Text = content
	contentLabel.TextColor3 = Theme.Muted
	contentLabel.TextSize = 12
	contentLabel.Font = Enum.Font.Gotham
	contentLabel.TextXAlignment = Enum.TextXAlignment.Left
	contentLabel.TextYAlignment = Enum.TextYAlignment.Top
	contentLabel.TextWrapped = true
	contentLabel.Parent = notif

	local textSize = TextService:GetTextSize(
		content, 12, Enum.Font.Gotham,
		Vector2.new(272, 1000)
	)
	local contentHeight = math.max(18, textSize.Y)
	local totalHeight = 36 + contentHeight + 16

	contentLabel.Size = UDim2.new(1, -28, 0, contentHeight)
	notif.Size = UDim2.fromOffset(300, 0)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.fromOffset(24, 24)
	closeBtn.Position = UDim2.new(1, -32, 0, 10)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Theme.Muted
	closeBtn.TextSize = 16
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = notif

	local progress = Instance.new("Frame")
	progress.Size = UDim2.new(1, 0, 0, 2)
	progress.Position = UDim2.new(0, 0, 1, -2)
	progress.BackgroundColor3 = accentColor
	progress.BackgroundTransparency = 0.3
	progress.BorderSizePixel = 0
	progress.Parent = notif

	notif.Position = UDim2.new(1, 40, 0, 0)
	tween(notif, 0.4, {
		Size = UDim2.fromOffset(300, totalHeight),
		Position = UDim2.new(0, 0, 0, 0)
	}, Enum.EasingStyle.Back)
	tween(accent, 0.35, { Size = UDim2.fromOffset(4, totalHeight) })

	tween(progress, duration, {
		Size = UDim2.new(0, 0, 0, 2)
	}, Enum.EasingStyle.Linear)

	local function dismiss()
		if not notif or not notif.Parent then return end
		tween(notif, 0.28, {
			Position = UDim2.new(1, 40, 0, 0),
			BackgroundTransparency = 1
		}, Enum.EasingStyle.Quint)
		task.delay(0.3, function()
			if notif and notif.Parent then
				notif:Destroy()
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(dismiss)
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.12, { TextColor3 = Theme.Text })
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.12, { TextColor3 = Theme.Muted })
	end)

	task.delay(duration, dismiss)

	return notif
end

function Library:CreateWindow(options)
	options = options or {}
	local titleText = options.Title or "Legalizeexploiting UI"
	local width = options.Width or 600
	local height = options.Height or 400

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local existing = playerGui:FindFirstChild("LegalizeexploitingUI")
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "LegalizeexploitingUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.fromOffset(width - 50, height - 40)
	main.Position = UDim2.new(0.5, -width / 2, 0.5, -height / 2)
	main.BackgroundColor3 = Theme.Background
	main.BackgroundTransparency = 1
	main.BorderSizePixel = 0
	main.ClipsDescendants = true
	main.Parent = gui
	addCorner(main, 14)
	addStroke(main, Theme.Border, 0.4, 1.2)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 34, 40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 18, 22)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 15))
	})
	gradient.Rotation = 110
	gradient.Parent = main

	local titleBar = Instance.new("Frame")
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 48)
	titleBar.BackgroundTransparency = 1
	titleBar.Parent = main

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.fromOffset(18, 0)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = Theme.Text
	title.TextSize = 16
	title.Font = Enum.Font.GothamMedium
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = titleBar

	local minBtn = Instance.new("TextButton")
	minBtn.Name = "Minimize"
	minBtn.Size = UDim2.fromOffset(28, 28)
	minBtn.Position = UDim2.new(1, -72, 0.5, -14)
	minBtn.BackgroundColor3 = Theme.Element
	minBtn.BackgroundTransparency = 0.4
	minBtn.Text = "–"
	minBtn.TextColor3 = Theme.Muted
	minBtn.TextSize = 16
	minBtn.Font = Enum.Font.GothamBold
	minBtn.AutoButtonColor = false
	minBtn.Parent = titleBar
	addCorner(minBtn, 7)

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
	closeBtn.BackgroundColor3 = Theme.Element
	closeBtn.BackgroundTransparency = 0.4
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Theme.Muted
	closeBtn.TextSize = 18
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.AutoButtonColor = false
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 7)

	local fullSize = UDim2.fromOffset(width, height)

	minBtn.MouseEnter:Connect(function()
		tween(minBtn, 0.15, {
			BackgroundColor3 = Theme.Hover,
			BackgroundTransparency = 0.15,
			TextColor3 = Theme.Text
		})
	end)
	minBtn.MouseLeave:Connect(function()
		tween(minBtn, 0.15, {
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 0.4,
			TextColor3 = Theme.Muted
		})
	end)

	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.15, {
			BackgroundColor3 = Theme.Danger,
			BackgroundTransparency = 0.15,
			TextColor3 = Color3.new(1, 1, 1)
		})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.15, {
			BackgroundColor3 = Theme.Element,
			BackgroundTransparency = 0.4,
			TextColor3 = Theme.Muted
		})
	end)

	closeBtn.MouseButton1Click:Connect(function()
		tween(main, 0.28, {
			Size = UDim2.fromOffset(width - 60, height - 50),
			BackgroundTransparency = 1
		}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.delay(0.3, function()
			gui:Destroy()
		end)
	end)

	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			main.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)

	local sidebar = Instance.new("ScrollingFrame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 148, 1, -62)
	sidebar.Position = UDim2.fromOffset(12, 52)
	sidebar.BackgroundColor3 = Theme.Panel
	sidebar.BackgroundTransparency = 0.35
	sidebar.BorderSizePixel = 0
	sidebar.ScrollBarThickness = 0
	sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
	sidebar.Parent = main
	addCorner(sidebar, 11)
	addStroke(sidebar, Theme.Border, 0.7, 1)
	addPadding(sidebar, 10, 10, 8, 8)

	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 5)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sidebar

	sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		sidebar.CanvasSize = UDim2.new(0, 0, 0, sideLayout.AbsoluteContentSize.Y + 20)
	end)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -176, 1, -62)
	content.Position = UDim2.fromOffset(168, 52)
	content.BackgroundColor3 = Theme.Panel
	content.BackgroundTransparency = 0.4
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Parent = main
	addCorner(content, 11)
	addStroke(content, Theme.Border, 0.7, 1)

	local window = {}
	local tabs = {}
	local selectedTab = nil
	local tabOrder = 0
	local visible = true

	function window:Toggle(state)
		if state ~= nil then
			visible = state
		else
			visible = not visible
		end

		if visible then
			main.Visible = true
			tween(main, 0.4, {
				Size = fullSize,
				BackgroundTransparency = 0.06
			}, Enum.EasingStyle.Quint)
		else
			tween(main, 0.32, {
				Size = UDim2.fromOffset(width - 40, height - 30),
				BackgroundTransparency = 1
			}, Enum.EasingStyle.Quint)
			task.delay(0.34, function()
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
		title.Text = text
	end

	function window:Destroy()
		gui:Destroy()
	end

	function window:AddTab(name)
		tabOrder += 1
		local order = tabOrder

		local tabBtn = Instance.new("TextButton")
		tabBtn.Name = name
		tabBtn.Size = UDim2.new(1, 0, 0, 36)
		tabBtn.BackgroundColor3 = Theme.Element
		tabBtn.BackgroundTransparency = 0.55
		tabBtn.Text = ""
		tabBtn.AutoButtonColor = false
		tabBtn.LayoutOrder = order
		tabBtn.Parent = sidebar
		addCorner(tabBtn, 8)

		local tabLabel = Instance.new("TextLabel")
		tabLabel.Size = UDim2.new(1, -12, 1, 0)
		tabLabel.Position = UDim2.fromOffset(10, 0)
		tabLabel.BackgroundTransparency = 1
		tabLabel.Text = name
		tabLabel.TextColor3 = Theme.Muted
		tabLabel.TextSize = 13
		tabLabel.Font = Enum.Font.GothamMedium
		tabLabel.TextXAlignment = Enum.TextXAlignment.Left
		tabLabel.Parent = tabBtn

		local indicator = Instance.new("Frame")
		indicator.Name = "Indicator"
		indicator.Size = UDim2.fromOffset(3, 0)
		indicator.Position = UDim2.new(0, 0, 0.5, 0)
		indicator.AnchorPoint = Vector2.new(0, 0.5)
		indicator.BackgroundColor3 = Theme.Accent
		indicator.BackgroundTransparency = 0.25
		indicator.BorderSizePixel = 0
		indicator.Parent = tabBtn
		addCorner(indicator, 2)

		local page = Instance.new("ScrollingFrame")
		page.Name = name .. "Page"
		page.Size = UDim2.new(1, -16, 1, -16)
		page.Position = UDim2.fromOffset(8, 8)
		page.BackgroundTransparency = 1
		page.BorderSizePixel = 0
		page.ScrollBarThickness = 3
		page.ScrollBarImageColor3 = Theme.Muted
		page.ScrollBarImageTransparency = 0.4
		page.Visible = false
		page.CanvasSize = UDim2.new(0, 0, 0, 0)
		page.Parent = content

		local pageLayout = Instance.new("UIListLayout")
		pageLayout.Padding = UDim.new(0, 9)
		pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pageLayout.Parent = page

		pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			page.CanvasSize = UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 16)
		end)

		local tabData = {
			Button = tabBtn,
			Label = tabLabel,
			Indicator = indicator,
			Page = page,
			Name = name
		}
		table.insert(tabs, tabData)

		local function selectTab()
			if selectedTab == tabData then return end

			if selectedTab then
				local prev = selectedTab
				tween(prev.Button, 0.25, {
					BackgroundColor3 = Theme.Element,
					BackgroundTransparency = 0.55
				}, Enum.EasingStyle.Quart)
				tween(prev.Indicator, 0.25, { Size = UDim2.fromOffset(3, 0) }, Enum.EasingStyle.Quint)
				prev.Label.TextColor3 = Theme.Muted

				local oldPage = prev.Page
				tween(oldPage, 0.2, {
					Position = UDim2.fromOffset(8, 16)
				}, Enum.EasingStyle.Quad)
				task.delay(0.18, function()
					if selectedTab ~= prev then
						oldPage.Visible = false
						oldPage.Position = UDim2.fromOffset(8, 8)
					end
				end)
			end

			selectedTab = tabData

			tween(tabBtn, 0.3, {
				BackgroundColor3 = Theme.Hover,
				BackgroundTransparency = 0.1
			}, Enum.EasingStyle.Quint)
			tween(indicator, 0.32, {
				Size = UDim2.fromOffset(3, 20)
			}, Enum.EasingStyle.Quint)
			tabLabel.TextColor3 = Theme.Text

			page.Position = UDim2.fromOffset(8, 20)
			page.Visible = true
			tween(page, 0.32, {
				Position = UDim2.fromOffset(8, 8)
			}, Enum.EasingStyle.Quint)
		end

		tabBtn.MouseButton1Click:Connect(selectTab)

		tabBtn.MouseEnter:Connect(function()
			if selectedTab == tabData then return end
			tween(tabBtn, 0.14, {
				BackgroundColor3 = Theme.Hover,
				BackgroundTransparency = 0.3
			})
		end)

		tabBtn.MouseLeave:Connect(function()
			if selectedTab == tabData then return end
			tween(tabBtn, 0.14, {
				BackgroundColor3 = Theme.Element,
				BackgroundTransparency = 0.55
			})
		end)

		if not selectedTab then
			selectTab()
		end

		local tab = {}
		local elementOrder = 0

		local function nextOrder()
			elementOrder += 1
			return elementOrder
		end

		function tab:AddButton(opts)
			opts = opts or {}
			local name = opts.Name or "Button"
			local callback = opts.Callback

			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.new(1, 0, 0, 40)
			btn.BackgroundColor3 = Theme.Element
			btn.BackgroundTransparency = 0.2
			btn.Text = ""
			btn.AutoButtonColor = false
			btn.ClipsDescendants = true
			btn.LayoutOrder = nextOrder()
			btn.Parent = page
			addCorner(btn, 9)
			addStroke(btn, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -20, 1, 0)
			label.Position = UDim2.fromOffset(12, 0)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Text
			label.TextSize = 13
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = btn

			local pressed = false

			btn.MouseEnter:Connect(function()
				if pressed then return end
				tween(btn, 0.2, {
					BackgroundColor3 = Theme.Hover,
					BackgroundTransparency = 0.05
				})
			end)

			btn.MouseLeave:Connect(function()
				pressed = false
				tween(btn, 0.22, {
					BackgroundColor3 = Theme.Element,
					BackgroundTransparency = 0.2,
					Size = UDim2.new(1, 0, 0, 40)
				})
			end)

			btn.MouseButton1Down:Connect(function()
				pressed = true
				tween(btn, 0.1, {
					Size = UDim2.new(1, -4, 0, 37),
					BackgroundTransparency = 0
				}, Enum.EasingStyle.Quad)
			end)

			btn.MouseButton1Up:Connect(function()
				pressed = false
				tween(btn, 0.22, {
					Size = UDim2.new(1, 0, 0, 40),
					BackgroundColor3 = Theme.Hover,
					BackgroundTransparency = 0.05
				}, Enum.EasingStyle.Quint)
			end)

			btn.MouseButton1Click:Connect(function()
				local rel = UserInputService:GetMouseLocation() - btn.AbsolutePosition
				ripple(btn, rel.X, rel.Y)
				if typeof(callback) == "function" then
					task.spawn(callback)
				end
			end)

			return btn
		end

		function tab:AddToggle(opts)
			opts = opts or {}
			local name = opts.Name or "Toggle"
			local default = opts.Default or false
			local callback = opts.Callback
			local state = default

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 40)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -70, 1, 0)
			label.Position = UDim2.fromOffset(12, 0)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Text
			label.TextSize = 13
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local track = Instance.new("Frame")
			track.Name = "Track"
			track.Size = UDim2.fromOffset(42, 22)
			track.Position = UDim2.new(1, -54, 0.5, -11)
			track.BackgroundColor3 = state and Theme.Accent or Theme.ElementAlt
			track.BackgroundTransparency = state and 0.15 or 0.3
			track.BorderSizePixel = 0
			track.Parent = holder
			addCorner(track, 11)

			local knob = Instance.new("Frame")
			knob.Name = "Knob"
			knob.Size = UDim2.fromOffset(16, 16)
			knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3)
			knob.BackgroundColor3 = state and Theme.Background or Theme.Muted
			knob.BorderSizePixel = 0
			knob.Parent = track
			addCorner(knob, 8)

			local function setState(val, animate, silent)
				state = val and true or false
				if animate ~= false then
					tween(track, 0.22, {
						BackgroundColor3 = state and Theme.Accent or Theme.ElementAlt,
						BackgroundTransparency = state and 0.15 or 0.3
					})
					tween(knob, 0.25, {
						Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3),
						BackgroundColor3 = state and Theme.Background or Theme.Muted
					}, Enum.EasingStyle.Back)
				else
					track.BackgroundColor3 = state and Theme.Accent or Theme.ElementAlt
					track.BackgroundTransparency = state and 0.15 or 0.3
					knob.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.fromOffset(3, 3)
					knob.BackgroundColor3 = state and Theme.Background or Theme.Muted
				end
				if not silent and typeof(callback) == "function" then
					task.spawn(callback, state)
				end
			end

			local click = Instance.new("TextButton")
			click.Size = UDim2.new(1, 0, 1, 0)
			click.BackgroundTransparency = 1
			click.Text = ""
			click.Parent = holder

			click.MouseButton1Click:Connect(function()
				setState(not state)
			end)

			click.MouseEnter:Connect(function()
				tween(holder, 0.15, { BackgroundTransparency = 0.08 })
			end)
			click.MouseLeave:Connect(function()
				tween(holder, 0.15, { BackgroundTransparency = 0.2 })
			end)

			return {

				Set = function(_, val, silent) setState(val, true, silent) end,
				Get = function() return state end
			}
		end

		function tab:AddTextbox(opts)
			opts = opts or {}
			local name = opts.Name or "Textbox"
			local placeholder = opts.Placeholder or "Type here..."
			local default = opts.Default or ""
			local callback = opts.Callback

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 62)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -16, 0, 20)
			label.Position = UDim2.fromOffset(12, 6)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Muted
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local box = Instance.new("TextBox")
			box.Name = "Input"
			box.Size = UDim2.new(1, -20, 0, 26)
			box.Position = UDim2.fromOffset(10, 28)
			box.BackgroundColor3 = Theme.Panel
			box.BackgroundTransparency = 0.15
			box.TextColor3 = Theme.Text
			box.PlaceholderColor3 = Theme.Muted
			box.PlaceholderText = placeholder
			box.Text = default
			box.TextSize = 13
			box.Font = Enum.Font.Gotham
			box.ClearTextOnFocus = false
			box.BorderSizePixel = 0
			box.Parent = holder
			addCorner(box, 7)
			addStroke(box, Theme.Border, 0.75, 1)

			box.Focused:Connect(function()
				tween(box, 0.18, {
					BackgroundColor3 = Theme.Hover,
					BackgroundTransparency = 0.05
				})
				tween(holder, 0.18, { BackgroundTransparency = 0.1 })
			end)

			box.FocusLost:Connect(function(enter)
				tween(box, 0.18, {
					BackgroundColor3 = Theme.Panel,
					BackgroundTransparency = 0.15
				})
				tween(holder, 0.18, { BackgroundTransparency = 0.2 })
				if typeof(callback) == "function" then
					task.spawn(callback, box.Text, enter)
				end
			end)

			return box
		end

		function tab:AddSlider(opts)
			opts = opts or {}
			local name = opts.Name or "Slider"
			local min = opts.Min or 0
			local max = opts.Max or 100
			local default = opts.Default or min
			local callback = opts.Callback
			local decimals = opts.Decimals or 0

			local value = math.clamp(default, min, max)

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 58)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.65, 0, 0, 20)
			label.Position = UDim2.fromOffset(12, 6)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Muted
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local valueLabel = Instance.new("TextLabel")
			valueLabel.Size = UDim2.new(0.35, -12, 0, 20)
			valueLabel.Position = UDim2.new(0.65, 0, 0, 6)
			valueLabel.BackgroundTransparency = 1
			valueLabel.Text = string.format("%." .. decimals .. "f", value)
			valueLabel.TextColor3 = Theme.Text
			valueLabel.TextSize = 12
			valueLabel.Font = Enum.Font.GothamMedium
			valueLabel.TextXAlignment = Enum.TextXAlignment.Right
			valueLabel.Parent = holder

			local track = Instance.new("Frame")
			track.Name = "Track"
			track.Size = UDim2.new(1, -24, 0, 6)
			track.Position = UDim2.fromOffset(12, 36)
			track.BackgroundColor3 = Theme.ElementAlt
			track.BackgroundTransparency = 0.2
			track.BorderSizePixel = 0
			track.Parent = holder
			addCorner(track, 3)

			local fill = Instance.new("Frame")
			fill.Name = "Fill"
			fill.Size = UDim2.new((value - min) / math.max(max - min, 0.001), 0, 1, 0)
			fill.BackgroundColor3 = Theme.Accent
			fill.BackgroundTransparency = 0.25
			fill.BorderSizePixel = 0
			fill.Parent = track
			addCorner(fill, 3)

			local knob = Instance.new("Frame")
			knob.Name = "Knob"
			knob.Size = UDim2.fromOffset(14, 14)
			knob.Position = UDim2.new((value - min) / math.max(max - min, 0.001), -7, 0.5, -7)
			knob.BackgroundColor3 = Theme.Accent
			knob.BorderSizePixel = 0
			knob.ZIndex = 2
			knob.Parent = track
			addCorner(knob, 7)
			addStroke(knob, Theme.Background, 0.3, 2)

			local sliding = false

			local function update(val, fire)
				value = math.clamp(val, min, max)
				local pct = (value - min) / math.max(max - min, 0.001)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knob.Position = UDim2.new(pct, -7, 0.5, -7)
				valueLabel.Text = string.format("%." .. decimals .. "f", value)
				if fire and typeof(callback) == "function" then
					task.spawn(callback, value)
				end
			end

			local function fromInput(input)
				local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
				rel = math.clamp(rel, 0, 1)
				update(min + rel * (max - min), true)
			end

			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					fromInput(input)
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch) then
					fromInput(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			return {
				Set = function(_, val) update(val, true) end,
				Get = function() return value end
			}
		end

		function tab:AddColorPicker(opts)
			opts = opts or {}
			local name = opts.Name or "Color"
			local default = opts.Default or Color3.fromRGB(255, 255, 255)
			local callback = opts.Callback

			local current = default
			local h, s, v = Color3.toHSV(current)

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 40)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.ClipsDescendants = true
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -60, 0, 40)
			label.Position = UDim2.fromOffset(12, 0)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Text
			label.TextSize = 13
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local preview = Instance.new("Frame")
			preview.Name = "Preview"
			preview.Size = UDim2.fromOffset(28, 28)
			preview.Position = UDim2.new(1, -40, 0.5, -14)
			preview.BackgroundColor3 = current
			preview.BorderSizePixel = 0
			preview.Parent = holder
			addCorner(preview, 7)
			addStroke(preview, Theme.Border, 0.5, 1)

			local picker = Instance.new("Frame")
			picker.Name = "Picker"
			picker.Size = UDim2.new(1, -16, 0, 0)
			picker.Position = UDim2.fromOffset(8, 44)
			picker.BackgroundTransparency = 1
			picker.ClipsDescendants = true
			picker.Parent = holder

			local svFrame = Instance.new("Frame")
			svFrame.Size = UDim2.fromOffset(160, 120)
			svFrame.Position = UDim2.fromOffset(0, 0)
			svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svFrame.BorderSizePixel = 0
			svFrame.Parent = picker
			addCorner(svFrame, 8)

			local satGrad = Instance.new("UIGradient")
			satGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
			})
			satGrad.Parent = svFrame

			local valOverlay = Instance.new("Frame")
			valOverlay.Size = UDim2.new(1, 0, 1, 0)
			valOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
			valOverlay.BackgroundTransparency = 0
			valOverlay.BorderSizePixel = 0
			valOverlay.Parent = svFrame
			addCorner(valOverlay, 8)

			local valGrad = Instance.new("UIGradient")
			valGrad.Rotation = 90
			valGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0)
			})
			valGrad.Parent = valOverlay

			local svCursor = Instance.new("Frame")
			svCursor.Size = UDim2.fromOffset(12, 12)
			svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
			svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
			svCursor.BorderSizePixel = 0
			svCursor.ZIndex = 3
			svCursor.Parent = svFrame
			addCorner(svCursor, 6)
			addStroke(svCursor, Color3.new(0, 0, 0), 0.3, 1.5)

			local hueTrack = Instance.new("Frame")
			hueTrack.Size = UDim2.fromOffset(18, 120)
			hueTrack.Position = UDim2.fromOffset(172, 0)
			hueTrack.BackgroundColor3 = Color3.new(1, 1, 1)
			hueTrack.BorderSizePixel = 0
			hueTrack.Parent = picker
			addCorner(hueTrack, 6)

			local hueGrad = Instance.new("UIGradient")
			hueGrad.Rotation = 90
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
			})
			hueGrad.Parent = hueTrack

			local hueCursor = Instance.new("Frame")
			hueCursor.Size = UDim2.new(1, 4, 0, 6)
			hueCursor.Position = UDim2.new(0.5, 0, h, 0)
			hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
			hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
			hueCursor.BorderSizePixel = 0
			hueCursor.ZIndex = 3
			hueCursor.Parent = hueTrack
			addCorner(hueCursor, 3)
			addStroke(hueCursor, Color3.new(0, 0, 0), 0.4, 1)

			local hexLabel = Instance.new("TextLabel")
			hexLabel.Size = UDim2.fromOffset(100, 22)
			hexLabel.Position = UDim2.fromOffset(200, 50)
			hexLabel.BackgroundColor3 = Theme.Panel
			hexLabel.BackgroundTransparency = 0.2
			hexLabel.Text = string.format("#%02X%02X%02X",
				math.floor(current.R * 255),
				math.floor(current.G * 255),
				math.floor(current.B * 255))
			hexLabel.TextColor3 = Theme.Text
			hexLabel.TextSize = 11
			hexLabel.Font = Enum.Font.GothamMedium
			hexLabel.Parent = picker
			addCorner(hexLabel, 6)

			local open = false

			local function updateColor(fire)
				current = Color3.fromHSV(h, s, v)
				preview.BackgroundColor3 = current
				svFrame.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				satGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
				})
				hexLabel.Text = string.format("#%02X%02X%02X",
					math.floor(current.R * 255),
					math.floor(current.G * 255),
					math.floor(current.B * 255))
				if fire and typeof(callback) == "function" then
					task.spawn(callback, current)
				end
			end

			local draggingSV, draggingHue = false, false

			svFrame.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = true
				end
			end)

			hueTrack.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingHue = true
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement
					and input.UserInputType ~= Enum.UserInputType.Touch then
					return
				end
				if draggingSV then
					local rel = input.Position - svFrame.AbsolutePosition
					s = math.clamp(rel.X / svFrame.AbsoluteSize.X, 0, 1)
					v = 1 - math.clamp(rel.Y / svFrame.AbsoluteSize.Y, 0, 1)
					svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					updateColor(true)
				elseif draggingHue then
					local rel = (input.Position.Y - hueTrack.AbsolutePosition.Y) / hueTrack.AbsoluteSize.Y
					h = math.clamp(rel, 0, 1)
					hueCursor.Position = UDim2.new(0.5, 0, h, 0)
					updateColor(true)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = false
					draggingHue = false
				end
			end)

			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(1, 0, 0, 40)
			toggleBtn.BackgroundTransparency = 1
			toggleBtn.Text = ""
			toggleBtn.Parent = holder

			toggleBtn.MouseButton1Click:Connect(function()
				open = not open
				local targetH = open and 180 or 40
				tween(holder, 0.38, {
					Size = UDim2.new(1, 0, 0, targetH)
				}, Enum.EasingStyle.Quint)
				tween(picker, 0.38, {
					Size = UDim2.new(1, -16, 0, open and 130 or 0)
				}, Enum.EasingStyle.Quint)
			end)

			return {
				Set = function(_, col)
					current = col
					h, s, v = Color3.toHSV(col)
					svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
					hueCursor.Position = UDim2.new(0.5, 0, h, 0)
					updateColor(false)
				end,
				Get = function() return current end
			}
		end

		function tab:AddLabel(opts)
			opts = opts or {}
			local text = opts.Text or opts.Name or "Label"

			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(1, 0, 0, 22)
			label.BackgroundTransparency = 1
			label.Text = text
			label.TextColor3 = Theme.Muted
			label.TextSize = 12
			label.Font = Enum.Font.Gotham
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextWrapped = true
			label.LayoutOrder = nextOrder()
			label.Parent = page

			local function updateHeight()
				local size = TextService:GetTextSize(
					label.Text, label.TextSize, label.Font,
					Vector2.new(page.AbsoluteSize.X - 8, 1000)
				)
				label.Size = UDim2.new(1, 0, 0, math.max(22, size.Y + 4))
			end
			updateHeight()
			label:GetPropertyChangedSignal("Text"):Connect(updateHeight)

			return label
		end

		function tab:AddParagraph(opts)
			opts = opts or {}
			local titleText = opts.Title or opts.Name or "Info"
			local contentText = opts.Content or opts.Text or ""

			local holder = Instance.new("Frame")
			holder.Name = titleText
			holder.Size = UDim2.new(1, 0, 0, 0)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.25
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.7, 1)
			addPadding(holder, 10, 10, 12, 12)

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 0, 18)
			title.BackgroundTransparency = 1
			title.Text = titleText
			title.TextColor3 = Theme.Text
			title.TextSize = 13
			title.Font = Enum.Font.GothamMedium
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = holder

			local body = Instance.new("TextLabel")
			body.Size = UDim2.new(1, 0, 0, 0)
			body.Position = UDim2.fromOffset(0, 22)
			body.BackgroundTransparency = 1
			body.Text = contentText
			body.TextColor3 = Theme.Muted
			body.TextSize = 12
			body.Font = Enum.Font.Gotham
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextYAlignment = Enum.TextYAlignment.Top
			body.TextWrapped = true
			body.Parent = holder

			local function update()
				local size = TextService:GetTextSize(
					body.Text, 12, Enum.Font.Gotham,
					Vector2.new(page.AbsoluteSize.X - 40, 2000)
				)
				body.Size = UDim2.new(1, 0, 0, size.Y)
				holder.Size = UDim2.new(1, 0, 0, 32 + size.Y + 8)
			end
			update()
			body:GetPropertyChangedSignal("Text"):Connect(update)

			return {
				SetTitle = function(_, t) title.Text = t end,
				SetContent = function(_, c)
					body.Text = c
					update()
				end
			}
		end

		function tab:AddSection(opts)
			opts = opts or {}
			local name = opts.Name or "Section"

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 28)
			holder.BackgroundTransparency = 1
			holder.LayoutOrder = nextOrder()
			holder.Parent = page

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = string.upper(name)
			label.TextColor3 = Theme.Muted
			label.TextSize = 11
			label.Font = Enum.Font.GothamBold
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local line = Instance.new("Frame")
			line.Size = UDim2.new(1, 0, 0, 1)
			line.Position = UDim2.new(0, 0, 1, -1)
			line.BackgroundColor3 = Theme.Border
			line.BackgroundTransparency = 0.5
			line.BorderSizePixel = 0
			line.Parent = holder

			return holder
		end

		function tab:AddSeparator()
			local sep = Instance.new("Frame")
			sep.Name = "Separator"
			sep.Size = UDim2.new(1, 0, 0, 1)
			sep.BackgroundColor3 = Theme.Border
			sep.BackgroundTransparency = 0.55
			sep.BorderSizePixel = 0
			sep.LayoutOrder = nextOrder()
			sep.Parent = page
			return sep
		end

		function tab:AddKeybind(opts)
			opts = opts or {}
			local name = opts.Name or "Keybind"
			local default = opts.Default or Enum.KeyCode.Unknown
			local callback = opts.Callback
			local current = default

			local function displayName(bind)
				if typeof(bind) == "EnumItem" then
					if bind.EnumType == Enum.KeyCode then
						if bind == Enum.KeyCode.Unknown then return "None" end
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

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 40)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -90, 1, 0)
			label.Position = UDim2.fromOffset(12, 0)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Text
			label.TextSize = 13
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local keyBtn = Instance.new("TextButton")
			keyBtn.Size = UDim2.fromOffset(78, 26)
			keyBtn.Position = UDim2.new(1, -90, 0.5, -13)
			keyBtn.BackgroundColor3 = Theme.Panel
			keyBtn.BackgroundTransparency = 0.2
			keyBtn.Text = displayName(current)
			keyBtn.TextColor3 = Theme.Muted
			keyBtn.TextSize = 11
			keyBtn.Font = Enum.Font.GothamMedium
			keyBtn.AutoButtonColor = false
			keyBtn.Parent = holder
			addCorner(keyBtn, 6)
			addStroke(keyBtn, Theme.Border, 0.7, 1)

			local listening = false
			local ignoreNextClick = false

			local function finishBind(bind)
				current = bind
				keyBtn.Text = displayName(bind)
				listening = false
				tween(keyBtn, 0.15, {
					BackgroundColor3 = Theme.Panel,
					TextColor3 = Theme.Muted
				})
				if typeof(callback) == "function" then

					task.spawn(callback, bind, displayName(bind))
				end
			end

			keyBtn.MouseButton1Click:Connect(function()
				if listening then return end
				listening = true
				ignoreNextClick = true
				keyBtn.Text = "..."
				tween(keyBtn, 0.15, {
					BackgroundColor3 = Theme.Hover,
					TextColor3 = Theme.Text
				})
			end)

			UserInputService.InputBegan:Connect(function(input, gpe)
				if not listening then return end

				if input.UserInputType == Enum.UserInputType.Keyboard then

					if input.KeyCode == Enum.KeyCode.Escape then
						listening = false
						keyBtn.Text = displayName(current)
						tween(keyBtn, 0.15, {
							BackgroundColor3 = Theme.Panel,
							TextColor3 = Theme.Muted
						})
						return
					end
					finishBind(input.KeyCode)
					return
				end

				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3 then
					if ignoreNextClick and input.UserInputType == Enum.UserInputType.MouseButton1 then
						ignoreNextClick = false
						return
					end
					ignoreNextClick = false
					finishBind(input.UserInputType)
				end
			end)

			return {
				Get = function() return current end,
				Set = function(_, bind)
					current = bind
					keyBtn.Text = displayName(bind)
				end
			}
		end

		function tab:AddDropdown(opts)
			opts = opts or {}
			local name = opts.Name or "Dropdown"
			local list = opts.Options or { "Option 1", "Option 2" }
			local default = opts.Default or list[1]
			local callback = opts.Callback
			local selected = default
			local open = false

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 40)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.ClipsDescendants = true
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, -30, 0, 40)
			label.Position = UDim2.fromOffset(12, 0)
			label.BackgroundTransparency = 1
			label.Text = name .. "  ·  " .. tostring(selected)
			label.TextColor3 = Theme.Text
			label.TextSize = 13
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local arrow = Instance.new("TextLabel")
			arrow.Size = UDim2.fromOffset(20, 40)
			arrow.Position = UDim2.new(1, -28, 0, 0)
			arrow.BackgroundTransparency = 1
			arrow.Text = "▾"
			arrow.TextColor3 = Theme.Muted
			arrow.TextSize = 14
			arrow.Font = Enum.Font.GothamBold
			arrow.Parent = holder

			local optionList = Instance.new("Frame")
			optionList.Name = "Options"
			optionList.Size = UDim2.new(1, 0, 0, 0)
			optionList.Position = UDim2.fromOffset(0, 40)
			optionList.BackgroundTransparency = 1
			optionList.Parent = holder

			local optLayout = Instance.new("UIListLayout")
			optLayout.SortOrder = Enum.SortOrder.LayoutOrder
			optLayout.Parent = optionList

			for i, opt in ipairs(list) do
				local optBtn = Instance.new("TextButton")
				optBtn.Size = UDim2.new(1, 0, 0, 32)
				optBtn.BackgroundColor3 = Theme.ElementAlt
				optBtn.BackgroundTransparency = 0.4
				optBtn.Text = "  " .. tostring(opt)
				optBtn.TextColor3 = Theme.Muted
				optBtn.TextSize = 12
				optBtn.Font = Enum.Font.Gotham
				optBtn.TextXAlignment = Enum.TextXAlignment.Left
				optBtn.AutoButtonColor = false
				optBtn.LayoutOrder = i
				optBtn.Parent = optionList

				optBtn.MouseEnter:Connect(function()
					tween(optBtn, 0.12, {
						BackgroundTransparency = 0.15,
						TextColor3 = Theme.Text
					})
				end)
				optBtn.MouseLeave:Connect(function()
					tween(optBtn, 0.12, {
						BackgroundTransparency = 0.4,
						TextColor3 = Theme.Muted
					})
				end)

				optBtn.MouseButton1Click:Connect(function()
					selected = opt
					label.Text = name .. "  ·  " .. tostring(selected)
					open = false
					tween(holder, 0.22, { Size = UDim2.new(1, 0, 0, 40) }, Enum.EasingStyle.Quint)
					tween(arrow, 0.2, { Rotation = 0 })
					if typeof(callback) == "function" then
						task.spawn(callback, selected)
					end
				end)
			end

			local toggleBtn = Instance.new("TextButton")
			toggleBtn.Size = UDim2.new(1, 0, 0, 40)
			toggleBtn.BackgroundTransparency = 1
			toggleBtn.Text = ""
			toggleBtn.Parent = holder

			toggleBtn.MouseButton1Click:Connect(function()
				open = not open
				local targetH = open and (40 + #list * 32) or 40
				tween(holder, 0.36, {
					Size = UDim2.new(1, 0, 0, targetH)
				}, Enum.EasingStyle.Quint)
				tween(arrow, 0.3, { Rotation = open and 180 or 0 }, Enum.EasingStyle.Quint)
			end)

			return {
				Get = function() return selected end,
				Set = function(_, val)
					selected = val
					label.Text = name .. "  ·  " .. tostring(selected)
				end
			}
		end

		function tab:AddProgressBar(opts)
			opts = opts or {}
			local name = opts.Name or "Progress"
			local default = opts.Default or 0

			local value = math.clamp(default, 0, 1)

			local holder = Instance.new("Frame")
			holder.Name = name
			holder.Size = UDim2.new(1, 0, 0, 48)
			holder.BackgroundColor3 = Theme.Element
			holder.BackgroundTransparency = 0.2
			holder.BorderSizePixel = 0
			holder.LayoutOrder = nextOrder()
			holder.Parent = page
			addCorner(holder, 9)
			addStroke(holder, Theme.Border, 0.65, 1)

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(0.7, 0, 0, 20)
			label.Position = UDim2.fromOffset(12, 6)
			label.BackgroundTransparency = 1
			label.Text = name
			label.TextColor3 = Theme.Muted
			label.TextSize = 12
			label.Font = Enum.Font.GothamMedium
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.Parent = holder

			local pctLabel = Instance.new("TextLabel")
			pctLabel.Size = UDim2.new(0.3, -12, 0, 20)
			pctLabel.Position = UDim2.new(0.7, 0, 0, 6)
			pctLabel.BackgroundTransparency = 1
			pctLabel.Text = math.floor(value * 100) .. "%"
			pctLabel.TextColor3 = Theme.Text
			pctLabel.TextSize = 12
			pctLabel.Font = Enum.Font.GothamMedium
			pctLabel.TextXAlignment = Enum.TextXAlignment.Right
			pctLabel.Parent = holder

			local track = Instance.new("Frame")
			track.Size = UDim2.new(1, -24, 0, 8)
			track.Position = UDim2.fromOffset(12, 30)
			track.BackgroundColor3 = Theme.ElementAlt
			track.BackgroundTransparency = 0.2
			track.BorderSizePixel = 0
			track.Parent = holder
			addCorner(track, 4)

			local fill = Instance.new("Frame")
			fill.Size = UDim2.new(value, 0, 1, 0)
			fill.BackgroundColor3 = Theme.Accent
			fill.BackgroundTransparency = 0.2
			fill.BorderSizePixel = 0
			fill.Parent = track
			addCorner(fill, 4)

			return {
				Set = function(_, val)
					value = math.clamp(val, 0, 1)
					tween(fill, 0.3, { Size = UDim2.new(value, 0, 1, 0) })
					pctLabel.Text = math.floor(value * 100) .. "%"
				end,
				Get = function() return value end
			}
		end

		function tab:AddButtonGroup(opts)
			opts = opts or {}
			local buttons = opts.Buttons or {}

			local holder = Instance.new("Frame")
			holder.Name = "ButtonGroup"
			holder.Size = UDim2.new(1, 0, 0, 36)
			holder.BackgroundTransparency = 1
			holder.LayoutOrder = nextOrder()
			holder.Parent = page

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.Padding = UDim.new(0, 6)
			layout.Parent = holder

			local count = math.max(#buttons, 1)

			for _, btnOpts in ipairs(buttons) do
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1 / count, -4, 1, 0)
				btn.BackgroundColor3 = Theme.Element
				btn.BackgroundTransparency = 0.2
				btn.Text = btnOpts.Name or "Btn"
				btn.TextColor3 = Theme.Text
				btn.TextSize = 12
				btn.Font = Enum.Font.GothamMedium
				btn.AutoButtonColor = false
				btn.ClipsDescendants = true
				btn.Parent = holder
				addCorner(btn, 8)
				addStroke(btn, Theme.Border, 0.65, 1)

				btn.MouseEnter:Connect(function()
					tween(btn, 0.15, {
						BackgroundColor3 = Theme.Hover,
						BackgroundTransparency = 0.05
					})
				end)
				btn.MouseLeave:Connect(function()
					tween(btn, 0.15, {
						BackgroundColor3 = Theme.Element,
						BackgroundTransparency = 0.2
					})
				end)
				btn.MouseButton1Click:Connect(function()
					local rel = UserInputService:GetMouseLocation() - btn.AbsolutePosition
					ripple(btn, rel.X, rel.Y)
					if typeof(btnOpts.Callback) == "function" then
						task.spawn(btnOpts.Callback)
					end
				end)
			end

			return holder
		end

		return tab
	end

	main.Size = UDim2.fromOffset(width - 50, height - 40)
	main.BackgroundTransparency = 1
	tween(main, 0.5, {
		Size = fullSize,
		BackgroundTransparency = 0.06
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	return window
end

return Library
