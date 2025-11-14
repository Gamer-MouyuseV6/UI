local ReGui = loadstring(game:HttpGet('https://raw.githubusercontent.com/depthso/Dear-ReGui/main/ReGui.lua'))()

ReGui:Init({
	Prefabs = game:GetObjects("rbxassetid://"..ReGui.PrefabsId)[1]
})

ReGui:DefineTheme("Dark", {
	TitleAlign = Enum.TextXAlignment.Center,
	TextDisabled = Color3.fromRGB(100, 100, 100),
	Text = Color3.fromRGB(220, 220, 220),
	
	FrameBg = Color3.fromRGB(20, 20, 20),
	FrameBgTransparency = 0.3,
	FrameBgActive = Color3.fromRGB(40, 40, 40),
	FrameBgTransparencyActive = 0.3,
	
	CheckMark = Color3.fromRGB(80, 80, 80),
	SliderGrab = Color3.fromRGB(30, 30, 30),
	ButtonsBg = Color3.fromRGB(60, 60, 60),
	CollapsingHeaderBg = Color3.fromRGB(60, 60, 60),
	CollapsingHeaderText = Color3.fromRGB(220, 220, 220),
	RadioButtonHoveredBg = Color3.fromRGB(60, 60, 60),
	
	WindowBg = Color3.fromRGB(25, 25, 25),
	TitleBarBg = Color3.fromRGB(25, 25, 25),
	TitleBarBgActive = Color3.fromRGB(40, 40, 40),
	
	Border = Color3.fromRGB(40, 40, 40),
	ResizeGrab = Color3.fromRGB(40, 40, 40),
	RegionBgTransparency = 1,
})

local Window = ReGui:Window({
	Title = "Mouse Hub | The Strongest Battleground",
	Theme = "Dark",
	NoClose = true,
	NoCollapse = true,
	NoScrolling = true,
	NoScrollBar = true,
	NoResize = false,
	Size = UDim2.new(0, 400, 0, 400),
}):Center()

local Group = Window:List({
	UiPadding = 2,
	HorizontalFlex = Enum.UIFlexAlignment.Fill,
})

local TabsBar = Group:List({
	Border = false,
	UiPadding = 5,
	BorderColor = Window:GetThemeKey("Border"),
	BorderThickness = 1,
	HorizontalFlex = Enum.UIFlexAlignment.Fill,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	AutomaticSize = Enum.AutomaticSize.None,
	FlexMode = Enum.UIFlexMode.None,
	Size = UDim2.new(1, 0, 0, 40),
	CornerRadius = UDim.new(0, 5)
})
local TabSelector, SelectorObject = Group:TabSelector({
	NoTabsBar = true,
	Size = UDim2.fromScale(0.5, 1)
})
SelectorObject.Body.ScrollBarThickness = 4

local lol = false
local TabButton = {}
local function CreateTab(Name, Icon, CanvasSize)
	local Tab = TabSelector:CreateTab({
		Name = Name
	})

	local List = Tab:List({
		HorizontalFlex = Enum.UIFlexAlignment.Fill,
        VerticalFlex = Enum.UIFlexAlignment.Fill,
		UiPadding = 1,
		Spacing = 10,
	})

	local Button, Obj = TabsBar:Image({
		Image = Icon,
		Ratio = 1,
		RatioAxis = Enum.DominantAxis.Width,
		Size = UDim2.fromScale(2, 2),
		Callback = function(self)
            for i, v in TabButton do
                local color = i == Name and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
                local tween = game:GetService("TweenService"):Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, 0, false, 0), {ImageColor3 = color})
                tween:Play()
            end
			TabSelector:SetActiveTab(Tab)
		end,
	})
    TabButton[Name] = Obj
    if lol then
        Obj.ImageColor3 = Color3.fromRGB(150, 150, 150)
    end

    if Button.Parent:FindFirstChildOfClass("UIListLayout") then
        Button.Parent:FindFirstChildOfClass("UIListLayout").Padding = UDim.new(0, 25)
    end

	ReGui:SetItemTooltip(Button, function(Canvas)
		Canvas:Label({
			Text = Name
		})
	end)

    lol = true
	return List
end

local function CreateRegion(Parent, Title, Scroll)
	local Region = Parent:Region({
		Border = true,
		BorderColor = Window:GetThemeKey("Border"),
		BorderThickness = 1,
		CornerRadius = UDim.new(0, 5),
        Scroll = Scroll or false
	})

	if Title ~= "" then
        Region:Label({
            Text = Title
        })
    end

	return Region
end

local CopiedColor = Color3.new(1, 1, 1)
local Classes = {}
local Labels = {}
local Colors = {}
local function Create(Parent, Name, Props, InstName, Tooltip, Keybind, Colorpicker, KeybindNoToggle, OgColor)
    Parent = (Keybind or Colorpicker) and Parent:Row() or Parent
    if Classes[InstName] then
        warn("!! DUPLICATE !!", Name, InstName)
    end
    if Name == "Checkbox" then
        Labels[InstName] = Props.Label
        
        local OriginalCallback = Props.Callback or function() end
        Props.Callback = function(...)
            return OriginalCallback(...)
        end
    end
    local Class, Object = Parent[Name](Parent, Props)
    if InstName then
        Classes[InstName] = Class
        Object = Object
    end
    if Tooltip then
        ReGui:SetItemTooltip(Class, function(Canvas)
            Canvas:Label({
                Text = Tooltip
            })
        end)
    end
    if Keybind then
        local KeybindClass, _ = Parent:Keybind({
            Size = UDim2.fromOffset(55, 19), 
            Label = "", 
            IgnoreGameProcessed = false, 
            Callback = function() 
                if not KeybindNoToggle then
                    Class:Toggle() 
                end 
            end,
            OnKeybindSet = function() end
        })
        Classes[InstName.."Keybind"] = KeybindClass
    end
    if Colorpicker then
        Colors[InstName] = (OgColor and OgColor or Color3.new(1,1,1))
        local _, Obj; Obj = Parent:Button({
            Size = UDim2.fromOffset(19, 19),
            BackgroundTransparency = 0,
            Ratio = 1,
		    RatioAxis = Enum.DominantAxis.Width,
            UiPadding = 0,
            ColorTag = "",
            ElementStyle = "",
            Text = "",
            BackgroundColor3 = Colors[InstName],
            Border = true,
            BorderThickness = 1,
	        BorderColor = Color3.new(0, 0, 0),
            Callback = function()
                local Color = Colors[InstName] and Colors[InstName] or (OgColor and OgColor or Color3.new(1,1,1))
                Obj.BackgroundColor3 = Color
                local ModalWindow = Window:PopupModal({
                    Title = "Colorpicker",
                    AutoSize = "Y"
                })
                local Slider = ModalWindow:SliderColor3({
                    Value = Color,
                    Label = "Color",
                    Callback = function(_,color)
                        Obj.BackgroundColor3 = color
                        Colors[InstName] = color
                    end
                })
                local Row = ModalWindow:Row({
                    Spacing = 5
                })
                local _, ColorButton;
                Row:Button({
                    Text = "Copy Color",
                    Callback = function()
                        ColorButton.BackgroundColor3 = Colors[InstName]
                        CopiedColor = Colors[InstName]
                    end,
                })
                Row:Button({
                    Text = "Paste Color",
                    Callback = function()
                        Slider:SetValue(CopiedColor)
                    end,
                })
                _, ColorButton = Row:Button({
                    Size = UDim2.fromOffset(19, 19),
                    BackgroundTransparency = 0,
                    Ratio = 1,
                    RatioAxis = Enum.DominantAxis.Width,
                    UiPadding = 0,
                    ColorTag = "",
                    ElementStyle = "",
                    Text = "",
                    BackgroundColor3 = CopiedColor,
                    Border = true,
                    BorderThickness = 1,
                    BorderColor = Color3.new(0, 0, 0),
                })
                ModalWindow:Button({
                    Text = "Done",
                    Size = UDim2.fromScale(1, 0),
                    Callback = function()
                        ModalWindow:ClosePopup()
                    end,
                })
            end
        })
    end
    return Class, Object
end

