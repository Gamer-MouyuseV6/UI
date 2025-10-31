getgenv().GG = {
    Language = {
        CheckboxEnabled = "Enabled",
        CheckboxDisabled = "Disabled",
        SliderValue = "Value",
        DropdownSelect = "Select",
        DropdownNone = "None",
        DropdownSelected = "Selected",
        ButtonClick = "Click",
        TextboxEnter = "Enter",
        ModuleEnabled = "Enabled",
        ModuleDisabled = "Disabled",
        TabGeneral = "General",
        TabSettings = "Settings",
        Loading = "Loading...",
        Error = "Error",
        Success = "Success"
    }
}

local SelectedLanguage = GG.Language

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local UserInputService = cloneref(game:GetService('UserInputService'))
local ContentProvider = cloneref(game:GetService('ContentProvider'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Lighting = cloneref(game:GetService('Lighting'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local LocalPlayer = Players.LocalPlayer
local configFileName = LocalPlayer.Name .. '_' .. tostring(game.GameId)

local mouse = Players.LocalPlayer:GetMouse()
local old_March = CoreGui:FindFirstChild('March')

if old_March then
    Debris:AddItem(old_March, 0)
end

if not isfolder("Mouse Hub") then
    makefolder("Mouse Hub")
end

local Connections = setmetatable({
    disconnect = function(self, connection)
        if not self[connection] then return end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for _, value in self do
            if typeof(value) == 'function' then continue end
            value:Disconnect()
        end
    end
}, Connections)

local Util = setmetatable({
    map = function(self, value, in_min, in_max, out_min, out_max)
        return (value - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
    end,
    viewport_point_to_world = function(self, location, distance)
        local unit_ray = workspace.CurrentCamera:ScreenPointToRay(location.X, location.Y)
        return unit_ray.Origin + unit_ray.Direction * distance
    end,
    get_offset = function(self)
        local viewport_size_Y = workspace.CurrentCamera.ViewportSize.Y
        return self:map(viewport_size_Y, 0, 2560, 8, 56)
    end
}, Util)

local AcrylicBlur = {}
AcrylicBlur.__index = AcrylicBlur

function AcrylicBlur.new(object)
    local self = setmetatable({ _object = object, _folder = nil, _frame = nil, _root = nil }, AcrylicBlur)
    self:setup()
    return self
end

function AcrylicBlur:create_folder()
    local old_folder = workspace.CurrentCamera:FindFirstChild('AcrylicBlur')
    if old_folder then Debris:AddItem(old_folder, 0) end
    local folder = Instance.new('Folder')
    folder.Name = 'AcrylicBlur'
    folder.Parent = workspace.CurrentCamera
    self._folder = folder
end

function AcrylicBlur:create_depth_of_fields()
    local depth = Lighting:FindFirstChild('AcrylicBlur') or Instance.new('DepthOfFieldEffect')
    depth.FarIntensity = 0
    depth.FocusDistance = 0.05
    depth.InFocusRadius = 0.1
    depth.NearIntensity = 1
    depth.Name = 'AcrylicBlur'
    depth.Parent = Lighting
    for _, obj in Lighting:GetChildren() do
        if obj:IsA('DepthOfFieldEffect') and obj ~= depth then
            Connections[obj] = obj:GetPropertyChangedSignal('FarIntensity'):Connect(function() obj.FarIntensity = 0 end)
            obj.FarIntensity = 0
        end
    end
end

function AcrylicBlur:create_frame()
    local frame = Instance.new('Frame')
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    frame.AnchorPoint = Vector2.new(0.5, 0.5)
    frame.BackgroundTransparency = 1
    frame.Parent = self._object
    self._frame = frame
end

function AcrylicBlur:create_root()
    local part = Instance.new('Part')
    part.Name = 'Root'
    part.Color = Color3.new(0, 0, 0)
    part.Material = Enum.Material.Glass
    part.Size = Vector3.new(1, 1, 0)
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.Locked = true
    part.CastShadow = false
    part.Transparency = 0.98
    part.Parent = self._folder
    local mesh = Instance.new('SpecialMesh')
    mesh.MeshType = Enum.MeshType.Brick
    mesh.Offset = Vector3.new(0, 0, -0.000001)
    mesh.Parent = part
    self._root = part
end

function AcrylicBlur:setup()
    self:create_depth_of_fields()
    self:create_folder()
    self:create_root()
    self:create_frame()
    self:render(0.001)
    self:check_quality_level()
end

function AcrylicBlur:render(distance)
    local positions = { top_left = Vector2.new(), top_right = Vector2.new(), bottom_right = Vector2.new() }
    local function update_positions(size, position)
        positions.top_left = position
        positions.top_right = position + Vector2.new(size.X, 0)
        positions.bottom_right = position + size
    end
    local function update()
        local tl = Util:viewport_point_to_world(positions.top_left, distance)
        local tr = Util:viewport_point_to_world(positions.top_right, distance)
        local br = Util:viewport_point_to_world(positions.bottom_right, distance)
        local width = (tr - tl).Magnitude
        local height = (tr - br).Magnitude
        if not self._root then return end
        self._root.CFrame = CFrame.fromMatrix((tl + br) / 2, workspace.CurrentCamera.CFrame.XVector, workspace.CurrentCamera.CFrame.YVector, workspace.CurrentCamera.CFrame.ZVector)
        self._root.Mesh.Scale = Vector3.new(width, height, 0)
    end
    local function on_change()
        local offset = Util:get_offset()
        local size = self._frame.AbsoluteSize - Vector2.new(offset, offset)
        local position = self._frame.AbsolutePosition + Vector2.new(offset / 2, offset / 2)
        update_positions(size, position)
        task.spawn(update)
    end
    Connections['cframe_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(update)
    Connections['viewport_size_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(update)
    Connections['field_of_view_update'] = workspace.CurrentCamera:GetPropertyChangedSignal('FieldOfView'):Connect(update)
    Connections['frame_absolute_position'] = self._frame:GetPropertyChangedSignal('AbsolutePosition'):Connect(on_change)
    Connections['frame_absolute_size'] = self._frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(on_change)
    task.spawn(update)
end

function AcrylicBlur:check_quality_level()
    local game_settings = UserSettings().GameSettings
    local quality = game_settings.SavedQualityLevel.Value
    if quality < 8 then self:change_visiblity(false) end
    Connections['quality_level'] = game_settings:GetPropertyChangedSignal('SavedQualityLevel'):Connect(function()
        self:change_visiblity(game_settings.SavedQualityLevel.Value >= 8)
    end)
end

function AcrylicBlur:change_visiblity(state)
    self._root.Transparency = state and 0.98 or 1
end

local Config = setmetatable({
    save = function(self, file_name, config)
        local success, err = pcall(function()
            writefile('Mouse Hub/'..file_name..'.json', HttpService:JSONEncode(config))
        end)
        if not success then warn('failed to save config', err) end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
            if not isfile('Mouse Hub/'..file_name..'.json') then
                self:save(file_name, config)
                return
            end
            local data = readfile('Mouse Hub/'..file_name..'.json')
            return data and HttpService:JSONDecode(data)
        end)
        if not success then warn('failed to load config', result) end
        if not result then
            result = { _flags = {}, _keybinds = {}, _library = {} }
        end
        return result
    end
}, Config)

local Library = {
    _config = Config:load(configFileName),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui_loaded = false,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _premium = false,
    _premium_id = "1234567890" -- T-shirt ID for premium check
}
Library.__index = Library

function Library.new()
    local self = setmetatable({ _loaded = false, _tab = 0 }, Library)
    self:create_ui()
    return self
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.Position = UDim2.new(0.8, 0, 0, 10)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y
NotificationContainer.Parent = CoreGui.RobloxGui:FindFirstChild("RobloxCoreGuis") or Instance.new("ScreenGui", CoreGui.RobloxGui)

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.FillDirection = Enum.FillDirection.Vertical
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = NotificationContainer

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 60)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.AutomaticSize = Enum.AutomaticSize.Y
    Notification.Parent = NotificationContainer

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 4)
    UICorner.Parent = Notification

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 0, 60)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(32, 38, 51)
    InnerFrame.BackgroundTransparency = 0.1
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.AutomaticSize = Enum.AutomaticSize.Y
    InnerFrame.Parent = Notification

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 4)
    InnerUICorner.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification Title"
    Title.TextColor3 = Color3.fromRGB(210, 210, 210)
    Title.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
    Title.TextSize = 14
    Title.Size = UDim2.new(1, -10, 0, 20)
    Title.Position = UDim2.new(0, 5, 0, 5)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextWrapped = true
    Title.AutomaticSize = Enum.AutomaticSize.Y
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "This is the body of the notification."
    Body.TextColor3 = Color3.fromRGB(180, 180, 180)
    Body.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Regular)
    Body.TextSize = 12
    Body.Size = UDim2.new(1, -10, 0, 30)
    Body.Position = UDim2.new(0, 5, 0, 25)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Top
    Body.TextWrapped = true
    Body.AutomaticSize = Enum.AutomaticSize.Y
    Body.Parent = InnerFrame

    task.spawn(function()
        wait(0.1)
        local totalHeight = Title.TextBounds.Y + Body.TextBounds.Y + 10
        InnerFrame.Size = UDim2.new(1, 0, 0, totalHeight)
    end)

    task.spawn(function()
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenIn:Play()
        local duration = settings.duration or 5
        wait(duration)
        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 310, 0, 10 + NotificationContainer.Size.Y.Offset)
        })
        tweenOut:Play()
        tweenOut.Completed:Connect(function() Notification:Destroy() end)
    end)
end

function Library:get_screen_scale()
    local viewport_x = workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_x / 1400
end

function Library:get_device()
    local device = 'Unknown'
    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end
    self._device = device
end

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    if not Library._config._flags[flag] then return end
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(tbl, val)
    for i, v in tbl do
        if v == val then table.remove(tbl, i) break end
    end
end

function Library:check_premium()
    local success, owns = pcall(function()
        return game:GetService("MarketplaceService"):UserOwnsAsset(LocalPlayer.UserId, tonumber(self._premium_id))
    end)
    self._premium = success and owns or false
end

function Library:create_ui()
    local old_March = CoreGui:FindFirstChild('March')
    if old_March then Debris:AddItem(old_March, 0) end

    local March = Instance.new('ScreenGui')
    March.ResetOnSpawn = false
    March.Name = 'March'
    March.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    March.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0.05
    Container.BackgroundColor3 = Color3.fromRGB(12, 13, 15)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = March

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(52, 66, 89)
    UIStroke.Transparency = 0.5
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.Size = UDim2.new(0, 698, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0.026, 0, 0.111, 0)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local TabList = Instance.new('UIListLayout')
    TabList.Padding = UDim.new(0, 4)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
    ClientName.TextColor3 = Color3.fromRGB(152, 181, 255)
    ClientName.TextTransparency = 0.2
    ClientName.Text = 'Mouse Hub'
    ClientName.Size = UDim2.new(0, 31, 0, 13)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0.056, 0, 0.055, 0)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.TextSize = 13
    ClientName.Parent = Handler

    local UIGradient = Instance.new('UIGradient')
    UIGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 155, 155)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)) }
    UIGradient.Parent = ClientName

    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0.026, 0, 0.136, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
    Pin.Parent = Handler

    local PinCorner = Instance.new('UICorner')
    PinCorner.CornerRadius = UDim.new(1, 0)
    PinCorner.Parent = Pin

    local Icon = Instance.new('ImageLabel')
    Icon.ImageColor3 = Color3.fromRGB(152, 181, 255)
    Icon.ScaleType = Enum.ScaleType.Fit
    Icon.Image = 'rbxassetid://15822475430'
    Icon.BackgroundTransparency = 1
    Icon.Position = UDim2.new(0.025, 0, 0.055, 0)
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.Parent = Handler

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.5
    Divider.Position = UDim2.new(0.235, 0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 479)
    Divider.BackgroundColor3 = Color3.fromRGB(52, 66, 89)
    Divider.Parent = Handler

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json')
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020, 0, 0.029, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    -- Avatar Profile Button (bottom of tab holder)
    local AvatarButton = Instance.new('ImageButton')
    AvatarButton.Size = UDim2.new(0, 30, 0, 30)
    AvatarButton.Position = UDim2.new(0, 10, 1, -40)
    AvatarButton.BackgroundTransparency = 1
    AvatarButton.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    AvatarButton.Parent = Tabs

    local ProfileMenu = Instance.new('Frame')
    ProfileMenu.Size = UDim2.new(0, 200, 0, 120)
    ProfileMenu.Position = UDim2.new(0, 40, 1, -150)
    ProfileMenu.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
    ProfileMenu.BorderSizePixel = 0
    ProfileMenu.Visible = false
    ProfileMenu.Parent = Tabs

    local MenuCorner = Instance.new('UICorner')
    MenuCorner.CornerRadius = UDim.new(0, 8)
    MenuCorner.Parent = ProfileMenu

    local MenuStroke = Instance.new('UIStroke')
    MenuStroke.Color = Color3.fromRGB(52, 66, 89)
    MenuStroke.Transparency = 0.5
    MenuStroke.Parent = ProfileMenu

    local ProfileIcon = Instance.new('ImageLabel')
    ProfileIcon.Size = UDim2.new(0, 50, 0, 50)
    ProfileIcon.Position = UDim2.new(0, 10, 0, 10)
    ProfileIcon.BackgroundTransparency = 1
    ProfileIcon.Image = AvatarButton.Image
    ProfileIcon.Parent = ProfileMenu

    local NameLabel = Instance.new('TextLabel')
    NameLabel.Size = UDim2.new(0, 130, 0, 20)
    NameLabel.Position = UDim2.new(0, 65, 0, 15)
    NameLabel.BackgroundTransparency = 1
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
    NameLabel.TextSize = 12
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left
    NameLabel.Text = LocalPlayer.DisplayName .. " (@" .. LocalPlayer.Name .. ")"
    NameLabel.Parent = ProfileMenu

    local PremiumLabel = Instance.new('TextLabel')
    PremiumLabel.Size = UDim2.new(0, 130, 0, 16)
    PremiumLabel.Position = UDim2.new(0, 65, 0, 35)
    PremiumLabel.BackgroundTransparency = 1
    PremiumLabel.TextColor3 = Color3.fromRGB(152, 181, 255)
    PremiumLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json')
    PremiumLabel.TextSize = 11
    PremiumLabel.TextXAlignment = Enum.TextXAlignment.Left
    PremiumLabel.Parent = ProfileMenu

    local BuyPremium = Instance.new('TextButton')
    BuyPremium.Size = UDim2.new(0, 180, 0, 25)
    BuyPremium.Position = UDim2.new(0, 10, 0, 85)
    BuyPremium.BackgroundColor3 = Color3.fromRGB(152, 181, 255)
    BuyPremium.TextColor3 = Color3.fromRGB(0, 0, 0)
    BuyPremium.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
    BuyPremium.TextSize = 12
    BuyPremium.Text = "Buy Premium"
    BuyPremium.Parent = ProfileMenu

    local BuyCorner = Instance.new('UICorner')
    BuyCorner.CornerRadius = UDim.new(0, 4)
    BuyCorner.Parent = BuyPremium

    AvatarButton.MouseButton1Click:Connect(function()
        ProfileMenu.Visible = not ProfileMenu.Visible
    end)

    BuyPremium.MouseButton1Click:Connect(function()
        setclipboard("https://www.roblox.com/catalog/" .. Library._premium_id)
        Library.SendNotification({ title = "Premium", text = "Link copied to clipboard!", duration = 3 })
    end)

    task.spawn(function()
        Library:check_premium()
        PremiumLabel.Text = "Premium: " .. (Library._premium and "Yes" or "No")
    end)

    self._ui = March

    local function on_drag(input, process)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position
            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local pos = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), { Position = pos }):Play()
    end

    local function drag(input, process)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:Update1Run(a)
        if a == "nil" then
            Container.BackgroundTransparency = 0.05
        else
            pcall(function() Container.BackgroundTransparency = tonumber(a) end)
        end
    end

    function self:UIVisiblity()
        March.Enabled = not March.Enabled
    end

    function self:change_visiblity(state)
        if state then
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(698, 479) }):Play()
        else
            TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(104.5, 52) }):Play()
        end
    end

    function self:load()
        local content = {}
        for _, obj in March:GetDescendants() do
            if obj:IsA('ImageLabel') then table.insert(content, obj) end
        end
        ContentProvider:PreloadAsync(content)
        self:get_device()
        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
            end)
        end
        TweenService:Create(Container, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(698, 479) }):Play()
        AcrylicBlur.new(Container)
        self._ui_loaded = true
    end

    function self:update_tabs(tab)
        for _, obj in Tabs:GetChildren() do
            if obj.Name ~= 'Tab' then continue end
            if obj == tab then
                if obj.BackgroundTransparency ~= 0.5 then
                    local offset = obj.LayoutOrder * (0.113 / 1.3)
                    TweenService:Create(Pin, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.fromScale(0.026, 0.135 + offset) }):Play()
                    TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(obj.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.2, TextColor3 = Color3.fromRGB(152, 181, 255) }):Play()
                    TweenService:Create(obj.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) }):Play()
                    TweenService:Create(obj.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.2, ImageColor3 = Color3.fromRGB(152, 181, 255) }):Play()
                end
                continue
            end
            if obj.BackgroundTransparency ~= 1 then
                TweenService:Create(obj, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
                TweenService:Create(obj.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.7, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
                TweenService:Create(obj.TextLabel.UIGradient, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Offset = Vector2.new(0, 0) }):Play()
                TweenService:Create(obj.Icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.8, ImageColor3 = Color3.fromRGB(255, 255, 255) }):Play()
            end
        end
    end

    function self:update_sections(left, right)
        for _, obj in Sections:GetChildren() do
            obj.Visible = (obj == left or obj == right)
        end
    end

    function self:create_tab(title, icon)
        local TabManager = { _locked = false }
        local LayoutOrder = 0
        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        font_params.Size = 13
        font_params.Width = 10000
        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/SourceSansPro.json')
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab

        local TabCorner = Instance.new('UICorner')
        TabCorner.CornerRadius = UDim.new(0, 5)
        TabCorner.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
        TextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.TextTransparency = 0.7
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0.24, 0, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.TextSize = 13
        TextLabel.Parent = Tab

        local LabelGradient = Instance.new('UIGradient')
        LabelGradient.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)), ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58)) }
        LabelGradient.Parent = TextLabel

        local TabIcon = Instance.new('ImageLabel')
        TabIcon.ScaleType = Enum.ScaleType.Fit
        TabIcon.ImageTransparency = 0.8
        TabIcon.BackgroundTransparency = 1
        TabIcon.Position = UDim2.new(0.1, 0, 0.5, 0)
        TabIcon.Image = icon
        TabIcon.Size = UDim2.new(0, 12, 0, 12)
        TabIcon.Parent = Tab

        local LockIcon = Instance.new('ImageLabel')
        LockIcon.Image = 'rbxassetid://6034830538'
        LockIcon.Size = UDim2.new(0, 12, 0, 12)
        LockIcon.Position = UDim2.new(1, -16, 0.5, 0)
        LockIcon.AnchorPoint = Vector2.new(1, 0.5)
        LockIcon.BackgroundTransparency = 1
        LockIcon.ImageColor3 = Color3.fromRGB(200, 50, 50)
        LockIcon.Visible = false
        LockIcon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.Size = UDim2.new(0, 243, 0, 445)
        LeftSection.AnchorPoint = Vector2.new(0, 0.5)
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0.259, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections

        local LeftList = Instance.new('UIListLayout')
        LeftList.Padding = UDim.new(0, 11)
        LeftList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        LeftList.SortOrder = Enum.SortOrder.LayoutOrder
        LeftList.Parent = LeftSection

        local LeftPad = Instance.new('UIPadding')
        LeftPad.PaddingTop = UDim.new(0, 1)
        LeftPad.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 445)
        RightSection.AnchorPoint = Vector2.new(0, 0.5)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0.629, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local RightList = Instance.new('UIListLayout')
        RightList.Padding = UDim.new(0, 11)
        RightList.HorizontalAlignment = Enum.HorizontalAlignment.Center
        RightList.SortOrder = Enum.SortOrder.LayoutOrder
        RightList.Parent = RightSection

        local RightPad = Instance.new('UIPadding')
        RightPad.PaddingTop = UDim.new(0, 1)
        RightPad.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            if TabManager._locked and not Library._premium then
                Library.SendNotification({ title = "Premium Required", text = "This tab requires premium.", duration = 3 })
                return
            end
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:lock(state)
            TabManager._locked = state
            LockIcon.Visible = state and not Library._premium
        end

        function TabManager:create_line()
            local line = Instance.new('Frame')
            line.Size = UDim2.new(1, -20, 0, 1)
            line.BackgroundColor3 = Color3.fromRGB(0, 0, 100) -- Dark blue
            line.BorderSizePixel = 0
            line.Parent = Options
            return line
        end

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = { _state = false, _size = 0, _multiplier = 0 }

            if settings.section == 'right' then settings.section = RightSection else settings.section = LeftSection end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BackgroundTransparency = 0.5
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
            Module.Parent = settings.section

            local ModuleList = Instance.new('UIListLayout')
            ModuleList.SortOrder = Enum.SortOrder.LayoutOrder
            ModuleList.Parent = Module

            local ModuleCorner = Instance.new('UICorner')
            ModuleCorner.CornerRadius = UDim.new(0, 5)
            ModuleCorner.Parent = Module

            local ModuleStroke = Instance.new('UIStroke')
            ModuleStroke.Color = Color3.fromRGB(52, 66, 89)
            ModuleStroke.Transparency = 0.5
            ModuleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ModuleStroke.Parent = Module

            -- ... (rest of module creation unchanged)

            function ModuleManager:create_toggle(settings)
                -- ... existing toggle code ...
                local ToggleManager = { _state = false }

                -- ... creation ...

                function ToggleManager:value(state)
                    self:change_state(state)
                end

                return ToggleManager
            end

            -- ... other create_ functions ...

            return ModuleManager
        end

        return TabManager
    end

    Connections['library_visiblity'] = UserInputService.InputBegan:Connect(function(input, proc)
        if input.KeyCode ~= Enum.KeyCode.Insert then return end
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    self._ui.Container.Handler.Minimize.MouseButton1Click:Connect(function()
        self._ui_open = not self._ui_open
        self:change_visiblity(self._ui_open)
    end)

    return self
end

return Library
