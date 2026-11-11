local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Library = {}

local Theme = {
    Background = Color3.fromRGB(15, 15, 18),
    Panel = Color3.fromRGB(22, 22, 26),
    Element = Color3.fromRGB(32, 32, 38),
    Hover = Color3.fromRGB(48, 48, 56),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(240, 240, 245),
    Muted = Color3.fromRGB(150, 150, 160),
    Border = Color3.fromRGB(60, 60, 70),
}

local function tween(object, duration, properties, style, direction)
    local info = TweenInfo.new(
        duration,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

local function addStroke(object, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Transparency = transparency or 0.6
    stroke.Thickness = thickness or 1
    stroke.Parent = object
    return stroke
end

function Library:CreateWindow(options)
    options = options or {}
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "CheeseUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(560, 360)
    main.Position = UDim2.new(0.5, -280, 0.5, -180)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = 1
    main.BorderSizePixel = 0
    main.Parent = gui

    addCorner(main, 16)
    addStroke(main, Theme.Border, 0.5, 1.2)

    local glass = Instance.new("UIGradient")
    glass.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 48)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 18))
    })
    glass.Rotation = 50
    glass.Parent = main

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -40, 0, 50)
    title.Position = UDim2.fromOffset(20, 4)
    title.BackgroundTransparency = 1
    title.Text = options.Title or "Cheese UI"
    title.TextColor3 = Theme.Text
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    local dragBar = Instance.new("Frame")
    dragBar.Name = "DragBar"
    dragBar.Size = UDim2.new(1, 0, 0, 54)
    dragBar.BackgroundTransparency = 1
    dragBar.Parent = main

    local dragging, dragStart, startPosition
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPosition.X.Scale, startPosition.X.Offset + delta.X,
                startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
            )
        end
    end)

    local tabHolder = Instance.new("ScrollingFrame")
    tabHolder.Name = "Tabs"
    tabHolder.Size = UDim2.new(0, 150, 1, -66)
    tabHolder.Position = UDim2.fromOffset(14, 58)
    tabHolder.BackgroundColor3 = Theme.Panel
    tabHolder.BackgroundTransparency = 0.2
    tabHolder.BorderSizePixel = 0
    tabHolder.ScrollBarThickness = 0
    tabHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabHolder.Parent = main

    addCorner(tabHolder, 12)
    addStroke(tabHolder, Theme.Border, 0.8, 1)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabHolder

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingBottom = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    tabPadding.Parent = tabHolder

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabHolder.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
    end)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -180, 1, -66)
    content.Position = UDim2.fromOffset(174, 58)
    content.BackgroundColor3 = Theme.Panel
    content.BackgroundTransparency = 0.25
    content.BorderSizePixel = 0
    content.Parent = main

    addCorner(content, 12)
    addStroke(content, Theme.Border, 0.8, 1)

    local window = {}
    local selectedTab = nil

    function window:AddTab(tabName)
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(1, 0, 0, 38)
        tabButton.BackgroundColor3 = Theme.Element
        tabButton.BackgroundTransparency = 0.2
        tabButton.Text = tabName
        tabButton.TextColor3 = Theme.Muted
        tabButton.TextSize = 13
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabHolder

        addCorner(tabButton, 8)

        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.new(1, -16, 1, -16)
        page.Position = UDim2.fromOffset(8, 8)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Muted
        page.Visible = false
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Parent = content

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
        end)

        local tab = {}

        local function selectThisTab()
            if selectedTab then
                selectedTab.Page.Visible = false
                tween(selectedTab.Button, 0.2, {BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.2}, Enum.EasingStyle.Quart)
                selectedTab.Button.TextColor3 = Theme.Muted
            end

            selectedTab = {Page = page, Button = tabButton}
            page.Visible = true
            
            tween(tabButton, 0.25, {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0}, Enum.EasingStyle.Back)
            tabButton.TextColor3 = Theme.Text
        end

        tabButton.MouseButton1Click:Connect(selectThisTab)

        tabButton.MouseEnter:Connect(function()
            if selectedTab and selectedTab.Button == tabButton then return end
            tween(tabButton, 0.15, {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1})
        end)

        tabButton.MouseLeave:Connect(function()
            if selectedTab and selectedTab.Button == tabButton then return end
            tween(tabButton, 0.15, {BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.2})
        end)

        function tab:AddButton(options)
            options = options or {}
            
            local button = Instance.new("TextButton")
            button.Name = options.Name or "Button"
            button.Size = UDim2.new(1, -4, 0, 44)
            button.BackgroundColor3 = Theme.Element
            button.BackgroundTransparency = 0.15
            button.Text = options.Name or "Button"
            button.TextColor3 = Theme.Text
            button.TextSize = 13
            button.Font = Enum.Font.GothamMedium
            button.AutoButtonColor = false
            button.Parent = page

            addCorner(button, 10)
            addStroke(button, Theme.Border, 0.7, 1)

            button.MouseEnter:Connect(function()
                tween(button, 0.2, {BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.05})
            end)

            button.MouseLeave:Connect(function()
                tween(button, 0.2, {BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.15})
            end)

            button.MouseButton1Down:Connect(function()
                tween(button, 0.1, {Size = UDim2.new(1, -8, 0, 40)}, Enum.EasingStyle.Quad)
            end)

            button.MouseButton1Up:Connect(function()
                tween(button, 0.15, {Size = UDim2.new(1, -4, 0, 44)}, Enum.EasingStyle.Back)
            end)

            button.MouseButton1Click:Connect(function()
                if typeof(options.Callback) == "function" then
                    task.spawn(options.Callback)
                end
            end)

            return button
        end

        function tab:AddTextbox(options)
            options = options or {}

            local holder = Instance.new("Frame")
            holder.Name = options.Name or "Textbox"
            holder.Size = UDim2.new(1, -4, 0, 64)
            holder.BackgroundColor3 = Theme.Element
            holder.BackgroundTransparency = 0.15
            holder.BorderSizePixel = 0
            holder.Parent = page

            addCorner(holder, 10)
            addStroke(holder, Theme.Border, 0.7, 1)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -16, 0, 22)
            label.Position = UDim2.fromOffset(10, 6)
            label.BackgroundTransparency = 1
            label.Text = options.Name or "Textbox"
            label.TextColor3 = Theme.Muted
            label.TextSize = 12
            label.Font = Enum.Font.GothamMedium
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = holder

            local textbox = Instance.new("TextBox")
            textbox.Name = "Input"
            textbox.Size = UDim2.new(1, -20, 0, 28)
            textbox.Position = UDim2.fromOffset(10, 28)
            textbox.BackgroundColor3 = Theme.Panel
            textbox.BackgroundTransparency = 0.1
            textbox.TextColor3 = Theme.Text
            textbox.PlaceholderColor3 = Theme.Muted
            textbox.PlaceholderText = options.Placeholder or "Type here..."
            textbox.Text = options.Default or ""
            textbox.TextSize = 13
            textbox.Font = Enum.Font.Gotham
            textbox.ClearTextOnFocus = false
            textbox.BorderSizePixel = 0
            textbox.Parent = holder

            addCorner(textbox, 8)
            addStroke(textbox, Theme.Border, 0.8, 1)

            textbox.Focused:Connect(function()
                tween(textbox, 0.2, {BackgroundColor3 = Theme.Hover})
            end)

            textbox.FocusLost:Connect(function(enterPressed)
                tween(textbox, 0.2, {BackgroundColor3 = Theme.Panel})
                if typeof(options.Callback) == "function" then
                    task.spawn(options.Callback, textbox.Text, enterPressed)
                end
            end)

            return textbox
        end

        if not selectedTab then
            selectThisTab()
        end

        return tab
    end

    -- Smooth entrance animation using Back style
    main.Size = UDim2.fromOffset(500, 320)
    tween(main, 0.4, {
        Size = UDim2.fromOffset(560, 360),
        BackgroundTransparency = 0.08
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    return window
end

return Library
