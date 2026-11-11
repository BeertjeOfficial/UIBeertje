
-- CheeseUI
-- Modern black-and-white UI library

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}

-- Theme
local Theme = {
    Background = Color3.fromRGB(12, 12, 14),
    Panel = Color3.fromRGB(25, 25, 29),
    Element = Color3.fromRGB(38, 38, 43),
    Hover = Color3.fromRGB(58, 58, 64),
    Text = Color3.fromRGB(245, 245, 248),
    Muted = Color3.fromRGB(165, 165, 175),
    Border = Color3.fromRGB(90, 90, 100),
}

-- Tween
local function tween(object, duration, properties)
    local info = TweenInfo.new(
        duration,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )

    local animation = TweenService:Create(
        object,
        info,
        properties
    )

    animation:Play()
    return animation
end

-- Rounded corners
local function addCorner(object, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = object
    return corner
end

-- Border
local function addStroke(object)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Transparency = 0.65
    stroke.Thickness = 1
    stroke.Parent = object
    return stroke
end

-- Create window
function Library:CreateWindow(options)
    options = options or {}

    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "CheeseUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(540, 350)
    main.Position = UDim2.new(0.5, -270, 0.5, -175)
    main.BackgroundColor3 = Theme.Background
    main.BackgroundTransparency = 0.12
    main.BorderSizePixel = 0
    main.Parent = gui

    addCorner(main, 14)
    addStroke(main)

    -- Glass gradient
    local glass = Instance.new("UIGradient")
    glass.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 12, 14))
    })
    glass.Rotation = 45
    glass.Parent = main

    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -30, 0, 45)
    title.Position = UDim2.fromOffset(18, 8)
    title.BackgroundTransparency = 1
    title.Text = options.Title or "Cheese UI"
    title.TextColor3 = Theme.Text
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main

    -- Draggable title bar
    local dragBar = Instance.new("Frame")
    dragBar.Name = "DragBar"
    dragBar.Size = UDim2.new(1, 0, 0, 52)
    dragBar.BackgroundTransparency = 1
    dragBar.Parent = main

    local dragging = false
    local dragStart
    local startPosition

    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

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
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then

            local delta = input.Position - dragStart

            main.Position = UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,
                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )
        end
    end)

    -- Tab navigation
    local tabHolder = Instance.new("Frame")
    tabHolder.Name = "Tabs"
    tabHolder.Size = UDim2.new(0, 145, 1, -65)
    tabHolder.Position = UDim2.fromOffset(12, 55)
    tabHolder.BackgroundColor3 = Theme.Panel
    tabHolder.BackgroundTransparency = 0.15
    tabHolder.BorderSizePixel = 0
    tabHolder.Parent = main

    addCorner(tabHolder, 10)

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 7)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabHolder

    local tabPadding = Instance.new("UIPadding")
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 8)
    tabPadding.PaddingRight = UDim.new(0, 8)
    tabPadding.Parent = tabHolder

    -- Content
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -175, 1, -65)
    content.Position = UDim2.fromOffset(165, 55)
    content.BackgroundColor3 = Theme.Panel
    content.BackgroundTransparency = 0.2
    content.BorderSizePixel = 0
    content.Parent = main

    addCorner(content, 10)

    local window = {}
    local selectedTab = nil

    -- Add tab
    function window:AddTab(tabName)
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tabName .. "Tab"
        tabButton.Size = UDim2.new(1, 0, 0, 36)
        tabButton.BackgroundColor3 = Theme.Element
        tabButton.BackgroundTransparency = 0.15
        tabButton.Text = tabName
        tabButton.TextColor3 = Theme.Muted
        tabButton.TextSize = 13
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.AutoButtonColor = false
        tabButton.Parent = tabHolder

        addCorner(tabButton, 8)

        -- Page
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
        layout.Padding = UDim.new(0, 9)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(
                0, 0, 0, layout.AbsoluteContentSize.Y + 10
            )
        end)

        local tab = {}

        -- Select tab
        local function selectThisTab()
            if selectedTab then
                selectedTab.Page.Visible = false

                tween(selectedTab.Button, 0.2, {
                    BackgroundColor3 = Theme.Element
                })

                selectedTab.Button.TextColor3 = Theme.Muted
            end

            selectedTab = {
                Page = page,
                Button = tabButton
            }

            page.Visible = true

            tween(tabButton, 0.2, {
                BackgroundColor3 = Theme.Hover
            })

            tabButton.TextColor3 = Theme.Text
        end

        tabButton.MouseButton1Click:Connect(selectThisTab)

        tabButton.MouseEnter:Connect(function()
            if not selectedTab or selectedTab.Button ~= tabButton then
                tween(tabButton, 0.15, {
                    BackgroundColor3 = Theme.Hover
                })
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if not selectedTab or selectedTab.Button ~= tabButton then
                tween(tabButton, 0.15, {
                    BackgroundColor3 = Theme.Element
                })
            end
        end)

        -- Add button
        function tab:AddButton(options)
            options = options or {}

            local button = Instance.new("TextButton")
            button.Name = options.Name or "Button"
            button.Size = UDim2.new(1, -4, 0, 42)
            button.BackgroundColor3 = Theme.Element
            button.BackgroundTransparency = 0.1
            button.Text = options.Name or "Button"
            button.TextColor3 = Theme.Text
            button.TextSize = 14
            button.Font = Enum.Font.GothamMedium
            button.AutoButtonColor = false
            button.Parent = page

            addCorner(button, 9)
            addStroke(button)

            button.MouseEnter:Connect(function()
                tween(button, 0.18, {
                    BackgroundColor3 = Theme.Hover
                })
            end)

            button.MouseLeave:Connect(function()
                tween(button, 0.18, {
                    BackgroundColor3 = Theme.Element
                })
            end)

            button.MouseButton1Down:Connect(function()
                tween(button, 0.08, {
                    BackgroundTransparency = 0.3
                })
            end)

            button.MouseButton1Up:Connect(function()
                tween(button, 0.12, {
                    BackgroundTransparency = 0.1
                })
            end)

            button.MouseButton1Click:Connect(function()
                if typeof(options.Callback) == "function" then
                    task.spawn(options.Callback)
                end
            end)

            return button
        end

        -- Add textbox
        function tab:AddTextbox(options)
            options = options or {}

            local holder = Instance.new("Frame")
            holder.Name = options.Name or "Textbox"
            holder.Size = UDim2.new(1, -4, 0, 62)
            holder.BackgroundColor3 = Theme.Element
            holder.BackgroundTransparency = 0.1
            holder.BorderSizePixel = 0
            holder.Parent = page

            addCorner(holder, 9)
            addStroke(holder)

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -16, 0, 20)
            label.Position = UDim2.fromOffset(8, 4)
            label.BackgroundTransparency = 1
            label.Text = options.Name or "Textbox"
            label.TextColor3 = Theme.Muted
            label.TextSize = 12
            label.Font = Enum.Font.GothamMedium
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = holder

            local textbox = Instance.new("TextBox")
            textbox.Name = "Input"
            textbox.Size = UDim2.new(1, -16, 0, 27)
            textbox.Position = UDim2.fromOffset(8, 27)
            textbox.BackgroundColor3 = Theme.Panel
            textbox.TextColor3 = Theme.Text
            textbox.PlaceholderColor3 = Theme.Muted
            textbox.PlaceholderText = options.Placeholder or "Type here..."
            textbox.Text = options.Default or ""
            textbox.TextSize = 13
            textbox.Font = Enum.Font.Gotham
            textbox.ClearTextOnFocus = false
            textbox.BorderSizePixel = 0
            textbox.Parent = holder

            addCorner(textbox, 6)

            textbox.Focused:Connect(function()
                tween(textbox, 0.2, {
                    BackgroundColor3 = Theme.Hover
                })
            end)

            textbox.FocusLost:Connect(function(enterPressed)
                tween(textbox, 0.2, {
                    BackgroundColor3 = Theme.Panel
                })

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

    gui.Parent = playerGui

    -- Window entrance
    main.BackgroundTransparency = 1
    main.Size = UDim2.fromOffset(510, 325)

    tween(main, 0.35, {
        Size = UDim2.fromOffset(540, 350),
        BackgroundTransparency = 0.12
    })

    return window
end

return Library
