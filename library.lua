if getgenv().Loaded then getgenv().Library:Unload() end
getgenv().Loaded = true

local InputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local GuiInset = GuiService:GetGuiInset().Y
local IsMobile = InputService.TouchEnabled and not InputService.KeyboardEnabled

local vec2 = Vector2.new
local vec3 = Vector3.new
local dim2 = UDim2.new
local dim = UDim.new
local rect = Rect.new
local dim_offset = UDim2.fromOffset
local color = Color3.new
local rgb = Color3.fromRGB
local hex = Color3.fromHex
local hsv = Color3.fromHSV
local rgbseq = ColorSequence.new
local rgbkey = ColorSequenceKeypoint.new
local numseq = NumberSequence.new
local numkey = NumberSequenceKeypoint.new

local Library = {
    Directory = "repent.cc",
    Folders = {"/fonts", "/configs"},
    Flags = {},
    ConfigFlags = {},
    Connections = {},
    Notifications = {Notifs = {}},
    OpenElement = {},
    Locked = false,
}

getgenv().Library = Library

local Theme = {
    accent = rgb(147, 51, 234),
    window_outline = rgb(15, 15, 15),
    inline = rgb(35, 35, 35),
    background = rgb(25, 25, 25),
    visible_backgrounds = rgb(30, 30, 30),
    text_color = rgb(220, 220, 220),
    glow = rgb(147, 51, 234),
    deselected = rgb(140, 140, 140),
}

local ThemeObjects = {
    accent = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    window_outline = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    inline = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    background = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    visible_backgrounds = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    text_color = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    glow = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
    deselected = {BackgroundColor3 = {}, TextColor3 = {}, ImageColor3 = {}},
}

local KeyNames = {
    [Enum.KeyCode.LeftShift] = "LS",
    [Enum.KeyCode.RightShift] = "RS",
    [Enum.KeyCode.LeftControl] = "LC",
    [Enum.KeyCode.RightControl] = "RC",
    [Enum.KeyCode.Insert] = "INS",
    [Enum.KeyCode.Backspace] = "BS",
    [Enum.KeyCode.Return] = "Ent",
    [Enum.KeyCode.LeftAlt] = "LA",
    [Enum.KeyCode.RightAlt] = "RA",
    [Enum.KeyCode.CapsLock] = "CAPS",
    [Enum.KeyCode.One] = "1",
    [Enum.KeyCode.Two] = "2",
    [Enum.KeyCode.Three] = "3",
    [Enum.KeyCode.Four] = "4",
    [Enum.KeyCode.Five] = "5",
    [Enum.KeyCode.Six] = "6",
    [Enum.KeyCode.Seven] = "7",
    [Enum.KeyCode.Eight] = "8",
    [Enum.KeyCode.Nine] = "9",
    [Enum.KeyCode.Zero] = "0",
    [Enum.KeyCode.Minus] = "-",
    [Enum.KeyCode.Equals] = "=",
    [Enum.KeyCode.Tilde] = "~",
    [Enum.KeyCode.LeftBracket] = "[",
    [Enum.KeyCode.RightBracket] = "]",
    [Enum.KeyCode.Semicolon] = ",",
    [Enum.KeyCode.Quote] = "'",
    [Enum.KeyCode.BackSlash] = "\\",
    [Enum.KeyCode.Comma] = ",",
    [Enum.KeyCode.Period] = ".",
    [Enum.KeyCode.Slash] = "/",
    [Enum.KeyCode.Asterisk] = "*",
    [Enum.KeyCode.Plus] = "+",
    [Enum.KeyCode.Backquote] = "`",
    [Enum.UserInputType.MouseButton1] = "MB1",
    [Enum.UserInputType.MouseButton2] = "MB2",
    [Enum.UserInputType.MouseButton3] = "MB3",
    [Enum.KeyCode.Escape] = "ESC",
    [Enum.KeyCode.Space] = "SPC",
}

Library.__index = Library

for _, path in Library.Folders do
    makefolder(Library.Directory .. path)
end

local Flags = Library.Flags
local ConfigFlags = Library.ConfigFlags
local Notifications = Library.Notifications

function Library:GetTransparency(obj)
    if obj:IsA("Frame") then
        return {"BackgroundTransparency"}
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        return {"TextTransparency", "BackgroundTransparency"}
    elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        return {"BackgroundTransparency", "ImageTransparency"}
    elseif obj:IsA("ScrollingFrame") then
        return {"BackgroundTransparency", "ScrollBarImageTransparency"}
    elseif obj:IsA("TextBox") then
        return {"TextTransparency", "BackgroundTransparency"}
    elseif obj:IsA("UIStroke") then
        return {"Transparency"}
    end
    return nil
end

function Library:Tween(obj, props, info)
    local tween = TweenService:Create(obj, info or TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), props)
    tween:Play()
    return tween
end

function Library:Fade(obj, prop, visible, speed)
    if not (obj and prop) then return end
    local original = obj[prop]
    obj[prop] = visible and 1 or original
    local tween = Library:Tween(obj, {[prop] = visible and original or 1}, TweenInfo.new(speed or 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut))
    Library:Connection(tween.Completed, function()
        if not visible then
            task.wait()
            obj[prop] = original
        end
    end)
    return tween
end

function Library:Hovering(target)
    if type(target) == "table" then
        for _, obj in target do
            if Library:Hovering(obj) then return true end
        end
        return false
    end
    local y_cond = target.AbsolutePosition.Y <= Mouse.Y and Mouse.Y <= target.AbsolutePosition.Y + target.AbsoluteSize.Y
    local x_cond = target.AbsolutePosition.X <= Mouse.X and Mouse.X <= target.AbsolutePosition.X + target.AbsoluteSize.X
    return y_cond and x_cond
end

function Library:Draggify(target)
    local dragging = false
    local startInput = nil
    local startPos = nil
    
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if Library.Locked then return end
            dragging = true
            startInput = input.Position
            startPos = target.Position
        end
    end)
    
    target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    Library:Connection(InputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and not Library.Locked then
            local delta = input.Position - startInput
            target.Position = dim2(0, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - target.AbsoluteSize.X), 0, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - target.AbsoluteSize.Y))
        end
    end)
end

function Library:MobileDrag(target)
    if not IsMobile then return end
    
    local dragging = false
    local startInput = nil
    local startPos = nil
    local hasMoved = false
    local threshold = 10
    
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            startInput = input.Position
            startPos = target.Position
        end
    end)
    
    target.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    Library:Connection(InputService.InputChanged, function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - startInput
            if delta.Magnitude > threshold then hasMoved = true end
            if hasMoved and not Library.Locked then
                target.Position = dim2(0, math.clamp(startPos.X.Offset + delta.X, 0, Camera.ViewportSize.X - target.AbsoluteSize.X), 0, math.clamp(startPos.Y.Offset + delta.Y, 0, Camera.ViewportSize.Y - target.AbsoluteSize.Y))
            end
        end
    end)
end

function Library:Convert(str)
    local values = {}
    for value in string.gmatch(str, "[^,]+") do
        table.insert(values, tonumber(value))
    end
    if #values == 4 then return unpack(values) end
end

function Library:Lerp(a, b, t)
    return a + (b - a) * (t or 1/8)
end

function Library:ConvertEnum(enum)
    local parts = {}
    for part in string.gmatch(enum, "[%w_]+") do
        table.insert(parts, part)
    end
    local result = Enum
    for i = 2, #parts do
        result = result[parts[i]]
    end
    return result
end

function Library:ConvertHex(color, alpha)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    local a = alpha and math.floor(alpha * 255) or 255
    return string.format("#%02X%02X%02X%02X", r, g, b, a)
end

function Library:ConvertFromHex(str)
    str = str:gsub("#", "")
    local r = tonumber(str:sub(1, 2), 16) / 255
    local g = tonumber(str:sub(3, 4), 16) / 255
    local b = tonumber(str:sub(5, 6), 16) / 255
    local a = tonumber(str:sub(7, 8), 16) and tonumber(str:sub(7, 8), 16) / 255 or 1
    return Color3.new(r, g, b), a
end

local ConfigHolder

function Library:UpdateConfigList()
    if not ConfigHolder then return end
    local list = {}
    for _, file in listfiles(Library.Directory .. "/configs") do
        local name = file:gsub(Library.Directory .. "/configs\\", ""):gsub(".cfg", ""):gsub(Library.Directory .. "\\configs\\", "")
        list[#list + 1] = name
    end
    ConfigHolder.RefreshOptions(list)
end

function Library:Keypicker(properties)
    local cfg = {
        Name = properties.Name or "Color",
        Flag = properties.Flag or properties.Name or "Colorpicker",
        Callback = properties.Callback or function() end,
        Color = properties.Color or color(1, 1, 1),
        Alpha = properties.Alpha or properties.Transparency or 0,
        Open = false,
        Items = {},
    }
    
    local draggingSat = false
    local draggingHue = false
    local draggingAlpha = false
    local h, s, v = cfg.Color:ToHSV()
    local a = cfg.Alpha
    
    Flags[cfg.Flag] = {Color = cfg.Color, Transparency = cfg.Alpha}
    
    local items = cfg.Items
    
    items.Button = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Name = "\0",
        LayoutOrder = -1,
        Parent = self.Items.Components,
        Size = dim2(0, 28, 0, 14),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.ButtonColor = Library:Create("Frame", {
        Parent = items.Button,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent
    })
    
    Library:Create("UICorner", {Parent = items.ButtonColor, CornerRadius = dim(0, 4)})
    Library:Create("UICorner", {Parent = items.Button, CornerRadius = dim(0, 4)})
    
    items.Window = Library:Create("TextButton", {
        Parent = Library.Other,
        Text = "",
        AutoButtonColor = false,
        Active = false,
        Name = "\0",
        Position = dim2(0, 100, 0, 10),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 230, 0, 200),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Window, "inline", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Window})
    
    items.Inline = Library:Create("Frame", {
        Parent = items.Window,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.visible_backgrounds
    })
    Library:Themify(items.Inline, "visible_backgrounds", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Inline})
    
    items.Pallete = Library:Create("Frame", {
        Parent = items.Inline,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 1, 0, 2),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -4, 1, -3),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.SatVal = Library:Create("Frame", {
        Name = "\0",
        Parent = items.Pallete,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -38, 1, -43),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    
    items.SatValInner = Library:Create("Frame", {
        Parent = items.SatVal,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.SatValColor = Library:Create("Frame", {
        Parent = items.SatValInner,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent
    })
    
    items.SatValBtn = Library:Create("TextButton", {
        Name = "\0",
        Text = "",
        AutoButtonColor = false,
        Parent = items.SatValColor,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIGradient", {
        Parent = items.SatValBtn,
        Transparency = numseq(numkey(0, 0), numkey(1, 1))
    })
    
    items.SatValWhite = Library:Create("Frame", {
        Parent = items.SatValColor,
        Name = "\0",
        Size = dim2(1, 0, 1, 0),
        BorderColor3 = rgb(0, 0, 0),
        ZIndex = 2,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIGradient", {
        Rotation = 270,
        Transparency = numseq(numkey(0, 0), numkey(1, 1)),
        Parent = items.SatValWhite,
        Color = rgbseq(rgbkey(0, rgb(0, 0, 0)), rgbkey(1, rgb(0, 0, 0)))
    })
    
    items.SatValPicker = Library:Create("Frame", {
        Name = "\0",
        Parent = items.SatValColor,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 4, 0, 4),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    
    items.SatValPickerInner = Library:Create("Frame", {
        Parent = items.SatValPicker,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.HueBar = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 1),
        Parent = items.Pallete,
        Name = "\0",
        Position = dim2(1, -18, 1, 0),
        Size = dim2(0, 16, 1, 0),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    
    items.HueBarInner = Library:Create("Frame", {
        Parent = items.HueBar,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.HueGradient = Library:Create("Frame", {
        Parent = items.HueBarInner,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIGradient", {
        Rotation = 90,
        Parent = items.HueGradient,
        Color = rgbseq(rgbkey(0, rgb(255, 0, 0)), rgbkey(0.17, rgb(255, 255, 0)), rgbkey(0.33, rgb(0, 255, 0)), rgbkey(0.5, rgb(0, 255, 255)), rgbkey(0.67, rgb(0, 0, 255)), rgbkey(0.83, rgb(255, 0, 255)), rgbkey(1, rgb(255, 0, 0)))
    })
    
    items.HuePicker = Library:Create("Frame", {
        Parent = items.HueGradient,
        Name = "\0",
        BorderMode = Enum.BorderMode.Inset,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 2, 0, 4),
        Position = dim2(0, -1, 0, -1),
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.AlphaBar = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        AnchorPoint = vec2(1, 1),
        Parent = items.Pallete,
        Name = "\0",
        Position = dim2(1, 2, 1, 0),
        Size = dim2(0, 16, 1, 0),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    
    items.AlphaBarInner = Library:Create("Frame", {
        Parent = items.AlphaBar,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.AlphaGradient = Library:Create("Frame", {
        Parent = items.AlphaBarInner,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIGradient", {
        Rotation = 90,
        Parent = items.AlphaGradient,
        Color = rgbseq(rgbkey(0, rgb(255, 255, 255)), rgbkey(1, rgb(9, 9, 9)))
    })
    
    items.AlphaPicker = Library:Create("Frame", {
        Parent = items.AlphaGradient,
        Name = "\0",
        BorderMode = Enum.BorderMode.Inset,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 2, 0, 4),
        Position = dim2(0, -1, 0, -1),
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.HexInput = Library:Create("Frame", {
        AnchorPoint = vec2(0, 1),
        Parent = items.Pallete,
        Name = "\0",
        Position = dim2(0, 1, 1, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -39, 0, 18),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(0, 0, 0)
    })
    
    items.HexInputInner = Library:Create("Frame", {
        Parent = items.HexInput,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.HexBox = Library:Create("TextBox", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Parent = items.HexInputInner,
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = "255, 255, 255, 0.5",
        Name = "\0",
        Size = dim2(1, 0, 1, 0),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        Active = false,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIPadding", {
        PaddingTop = dim(0, 2),
        PaddingBottom = dim(0, 3),
        Parent = items.Pallete,
        PaddingRight = dim(0, 3),
        PaddingLeft = dim(0, 2)
    })
    
    function cfg:SetVisible(visible)
        items.Window.Visible = visible
        items.Window.Parent = visible and Library.Items or Library.Other
        items.Window.Position = dim2(0, items.Button.AbsolutePosition.X + 2, 0, items.Button.AbsolutePosition.Y + 74)
    end
    
    function cfg:Set(newColor, newAlpha)
        if type(newColor) == "boolean" then return end
        
        if newColor then
            h, s, v = newColor:ToHSV()
        end
        
        if newAlpha then
            a = newAlpha
        end
        
        local currentColor = hsv(h, s, v)
        
        items.SatValPicker.Position = dim2(s, -2, 1 - v, -2)
        items.AlphaPicker.Position = dim2(0, -1, a, -1)
        items.HuePicker.Position = dim2(0, -1, h, -1)
        
        items.ButtonColor.BackgroundColor3 = currentColor
        items.SatValColor.BackgroundColor3 = hsv(h, 1, 1)
        
        Flags[cfg.Flag] = {Color = currentColor, Transparency = a}
        
        items.HexBox.Text = string.format("%s, %s, %s, %s", Library:Round(currentColor.R * 255), Library:Round(currentColor.G * 255), Library:Round(currentColor.B * 255), Library:Round(1 - a, 0.01))
        
        cfg.Callback(currentColor, a)
    end
    
    function cfg:UpdateFromInput(input)
        if not IsMobile then
            local mousePos = InputService:GetMouseLocation()
            local offset = vec2(mousePos.X, mousePos.Y - GuiInset)
            
            if draggingSat then
                s = math.clamp((offset - items.SatValBtn.AbsolutePosition).X / items.SatValBtn.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((offset - items.SatValBtn.AbsolutePosition).Y / items.SatValBtn.AbsoluteSize.Y, 0, 1)
            elseif draggingHue then
                h = math.clamp((offset - items.HueBar.AbsolutePosition).Y / items.HueBar.AbsoluteSize.Y, 0, 1)
            elseif draggingAlpha then
                a = math.clamp((offset - items.AlphaBar.AbsolutePosition).Y / items.AlphaBar.AbsoluteSize.Y, 0, 1)
            end
        else
            local touchPos = input.Position
            local offset = vec2(touchPos.X, touchPos.Y)
            
            if draggingSat then
                s = math.clamp((offset - items.SatValBtn.AbsolutePosition).X / items.SatValBtn.AbsoluteSize.X, 0, 1)
                v = 1 - math.clamp((offset - items.SatValBtn.AbsolutePosition).Y / items.SatValBtn.AbsoluteSize.Y, 0, 1)
            elseif draggingHue then
                h = math.clamp((offset - items.HueBar.AbsolutePosition).Y / items.HueBar.AbsoluteSize.Y, 0, 1)
            elseif draggingAlpha then
                a = math.clamp((offset - items.AlphaBar.AbsolutePosition).Y / items.AlphaBar.AbsoluteSize.Y, 0, 1)
            end
        end
        
        cfg:Set()
    end
    
    items.Button.MouseButton1Click:Connect(function()
        cfg.Open = not cfg.Open
        cfg:SetVisible(cfg.Open)
        Library.OpenElement = cfg
    end)
    
    InputService.InputChanged:Connect(function(input)
        if (draggingSat or draggingHue or draggingAlpha) and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg:UpdateFromInput(input)
        end
    end)
    
    Library:Connection(InputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSat = false
            draggingHue = false
            draggingAlpha = false
        end
    end)
    
    items.SatValBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSat = true
        end
    end)
    
    items.HueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
        end
    end)
    
    items.AlphaBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingAlpha = true
        end
    end)
    
    items.HexBox.FocusLost:Connect(function()
        local r, g, b, newA = Library:Convert(items.HexBox.Text)
        if r and g and b and newA then
            cfg:Set(rgb(r, g, b), 1 - newA)
        end
    end)
    
    cfg:Set(cfg.Color, cfg.Alpha)
    ConfigFlags[cfg.Flag] = cfg.Set
    
    return setmetatable(cfg, Library)
end

function Library:GetConfig()
    local config = {}
    for idx, value in Flags do
        if type(value) == "table" and value.key then
            config[idx] = {active = value.Active, mode = value.Mode, key = tostring(value.Key)}
        elseif type(value) == "table" and value.Transparency and value.Color then
            config[idx] = {Transparency = value.Transparency, Color = value.Color:ToHex()}
        else
            config[idx] = value
        end
    end
    return HttpService:JSONEncode(config)
end

function Library:LoadConfig(json)
    local config = HttpService:JSONDecode(json)
    for idx, value in config do
        if idx == "config_name_list" then continue end
        local func = ConfigFlags[idx]
        if func then
            if type(value) == "table" and value.Transparency and value.Color then
                func(hex(value.Color), value.Transparency)
            elseif type(value) == "table" and value.Active then
                func(value)
            else
                func(value)
            end
        end
    end
end

function Library:Round(num, float)
    local mult = 1 / (float or 1)
    return math.floor(num * mult + 0.5) / mult
end

function Library:Themify(instance, theme, property)
    table.insert(ThemeObjects[theme][property], instance)
end

function Library:RefreshTheme(theme, newColor)
    for property, instances in ThemeObjects[theme] do
        for _, obj in instances do
            if obj[property] == Theme[theme] then
                obj[property] = newColor
            end
        end
    end
    Theme[theme] = newColor
end

function Library:Connection(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Library.Connections, connection)
    return connection
end

function Library:CloseAllElements()
    if Library.OpenElement and Library.OpenElement.SetVisible then
        Library.OpenElement:SetVisible(false)
        Library.OpenElement.Open = false
        Library.OpenElement = {}
    end
end

function Library:Create(class, props)
    local instance = Instance.new(class)
    for prop, value in props do
        instance[prop] = value
    end
    return instance
end

function Library:Unload()
    if Library.Items then Library.Items:Destroy() end
    if Library.Other then Library.Other:Destroy() end
    if Library.MobileToggle then Library.MobileToggle:Destroy() end
    if Library.MobileLock then Library.MobileLock:Destroy() end
    for _, connection in Library.Connections do
        connection:Disconnect()
    end
    getgenv().Library = nil
end

function Library:Window(properties)
    local cfg = {
        Prefix = properties.Prefix or "REPENT",
        Suffix = properties.Suffix or "CC",
        Size = properties.Size or dim2(0, 620, 0, 471),
        TabInfo = nil,
        Items = {},
        Locked = false,
        Visible = true,
    }
    
    Library.Items = Library:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "\0",
        Enabled = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    Library.Other = Library:Create("ScreenGui", {
        Parent = CoreGui,
        Name = "\0",
        Enabled = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
    })
    
    local items = cfg.Items
    
    items.Window = Library:Create("Frame", {
        Parent = Library.Items,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.window_outline
    })
    Library:Themify(items.Window, "window_outline", "BackgroundColor3")
    
    if IsMobile then
        items.Window.Size = dim2(0, cfg.Size.X.Offset * 0.9, 0, cfg.Size.Y.Offset * 0.75)
        items.Window.Position = dim2(0.5, -items.Window.Size.X.Offset / 2, 0.5, -items.Window.Size.Y.Offset / 2)
    else
        items.Window.Size = cfg.Size
        items.Window.Position = dim2(0.5, -cfg.Size.X.Offset / 2, 0.5, -cfg.Size.Y.Offset / 2)
    end
    
    items.Outline = Library:Create("Frame", {
        Parent = items.Window,
        Name = "\0",
        Size = dim2(1, 0, 1, 0),
        BorderColor3 = rgb(0, 0, 0),
        ZIndex = 2,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.window_outline
    })
    Library:Themify(items.Outline, "window_outline", "BackgroundColor3")
    
    items.Inline = Library:Create("Frame", {
        Parent = items.Outline,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Inline, "inline", "BackgroundColor3")
    
    items.TabBar = Library:Create("Frame", {
        Parent = items.Inline,
        Name = "\0",
        Position = dim2(0, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 139, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.background
    })
    
    items.TabHolder = Library:Create("Frame", {
        Parent = items.TabBar,
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        Parent = items.TabHolder,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Library:Create("UIPadding", {
        Parent = items.TabHolder,
        PaddingTop = dim(0, 10)
    })
    
    items.PageArea = Library:Create("Frame", {
        Parent = items.Inline,
        Name = "\0",
        Position = dim2(0, 140, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -140, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.background
    })
    Library:Themify(items.PageArea, "background", "BackgroundColor3")
    
    items.TitleBar = Library:Create("Frame", {
        Parent = items.PageArea,
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 43),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.TitleBarLine = Library:Create("Frame", {
        Parent = items.TitleBar,
        Name = "\0",
        Position = dim2(0, 0, 1, -1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.TitleBarLine, "inline", "BackgroundColor3")
    
    items.Title = Library:Create("TextLabel", {
        RichText = true,
        Parent = items.TitleBar,
        TextColor3 = Theme.accent,
        BorderColor3 = rgb(0, 0, 0),
        Text = '<font color = "rgb(255,255,255)">' .. cfg.Prefix .. '</font> ' .. cfg.Suffix .. '',
        Name = "\0",
        AutomaticSize = Enum.AutomaticSize.XY,
        AnchorPoint = vec2(0, 0.5),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Position = dim2(0, 13, 0.5, 0),
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        ZIndex = 2,
        TextSize = 20,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Title, "accent", "TextColor3")
    
    items.Pages = Library:Create("Frame", {
        Parent = items.PageArea,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 0, 0, 43),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 1, -43),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Fade = Library:Create("Frame", {
        Name = "\0",
        BackgroundTransparency = 1,
        Parent = items.Pages,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.background,
        ZIndex = 2,
    })
    Library:Themify(items.Fade, "background", "BackgroundColor3")
    
    items.Glow = Library:Create("ImageLabel", {
        ImageColor3 = Theme.glow,
        ScaleType = Enum.ScaleType.Slice,
        ImageTransparency = 0.65,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.Window,
        Name = "\0",
        Size = dim2(1, 40, 1, 40),
        Image = "rbxassetid://18245826428",
        BackgroundTransparency = 1,
        Position = dim2(0, -20, 0, -20),
        BackgroundColor3 = rgb(255, 255, 255),
        BorderSizePixel = 0,
        SliceCenter = rect(vec2(21, 21), vec2(79, 79))
    })
    Library:Themify(items.Glow, "glow", "ImageColor3")
    
    Library:Draggify(items.Window)
    Library:MobileDrag(items.Window)
    
    if IsMobile then
        Library.MobileToggle = Library:Create("TextButton", {
            Parent = Library.Items,
            Text = "MENU",
            Name = "ToggleUI",
            Size = dim2(0, 50, 0, 40),
            Position = dim2(0, 10, 0, 10),
            BackgroundColor3 = Theme.inline,
            BorderColor3 = Theme.accent,
            BorderSizePixel = 1,
            AutoButtonColor = false,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextColor3 = Theme.text_color,
            TextSize = 14,
        })
        
        Library:Create("UICorner", {Parent = Library.MobileToggle, CornerRadius = dim(0, 6)})
        Library:Create("UIStroke", {
            Parent = Library.MobileToggle,
            Color = Theme.accent,
            Thickness = 1,
            Transparency = 0.3
        })
        
        Library.MobileToggle.MouseButton1Click:Connect(function()
            cfg:ToggleMenu(not cfg.Visible)
        end)
        
        Library.MobileLock = Library:Create("TextButton", {
            Parent = Library.Items,
            Text = "LOCK",
            Name = "LockUI",
            Size = dim2(0, 50, 0, 40),
            Position = dim2(0, 65, 0, 10),
            BackgroundColor3 = Theme.inline,
            BorderColor3 = Theme.accent,
            BorderSizePixel = 1,
            AutoButtonColor = false,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
            TextColor3 = Theme.text_color,
            TextSize = 14,
        })
        
        Library:Create("UICorner", {Parent = Library.MobileLock, CornerRadius = dim(0, 6)})
        Library:Create("UIStroke", {
            Parent = Library.MobileLock,
            Color = Theme.accent,
            Thickness = 1,
            Transparency = 0.3
        })
        
        Library.MobileLock.MouseButton1Click:Connect(function()
            Library.Locked = not Library.Locked
            cfg.Locked = Library.Locked
            Library.MobileLock.Text = Library.Locked and "LOCKED" or "LOCK"
            Library.MobileLock.BorderColor3 = Library.Locked and rgb(255, 100, 100) or Theme.accent
            local stroke = Library.MobileLock:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = Library.Locked and rgb(255, 100, 100) or Theme.accent end
        end)
    end
    
    function cfg:ToggleMenu(visible)
        if cfg.Tweening then return end
        cfg.Tweening = true
        
        if visible then
            items.Window.Visible = true
            local children = items.Window:GetDescendants()
            table.insert(children, items.Window)
            
            local tween
            for _, obj in children do
                local index = Library:GetTransparency(obj)
                if not index then continue end
                if type(index) == "table" then
                    for _, prop in index do
                        tween = Library:Fade(obj, prop, true)
                    end
                else
                    tween = Library:Fade(obj, index, true)
                end
            end
            
            Library:Connection(tween.Completed, function()
                task.wait()
                cfg.Tweening = false
                cfg.Visible = true
            end)
        else
            Library:CloseAllElements()
            
            local children = items.Window:GetDescendants()
            table.insert(children, items.Window)
            
            local tween
            for _, obj in children do
                local index = Library:GetTransparency(obj)
                if not index then continue end
                if type(index) == "table" then
                    for _, prop in index do
                        tween = Library:Fade(obj, prop, false)
                    end
                else
                    tween = Library:Fade(obj, index, false)
                end
            end
            
            Library:Connection(tween.Completed, function()
                task.wait()
                items.Window.Visible = false
                cfg.Tweening = false
                cfg.Visible = false
            end)
        end
    end
    
    return setmetatable(cfg, Library)
end

function Library:Tab(properties)
    local cfg = {
        Name = properties.Name or properties.name or "Tab",
        Icon = properties.Icon or properties.icon or "rbxassetid://112730572155522",
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Button = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Items.TabHolder,
        BackgroundTransparency = 1,
        Name = "\0",
        Size = dim2(1, 0, 0, 30),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Holder = Library:Create("Frame", {
        Parent = items.Button,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 6, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -13, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.visible_backgrounds
    })
    Library:Themify(items.Holder, "visible_backgrounds", "BackgroundColor3")
    
    items.Icon = Library:Create("ImageLabel", {
        ImageColor3 = Theme.deselected,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.Holder,
        Name = "\0",
        AnchorPoint = vec2(0, 0.5),
        Image = cfg.Icon,
        BackgroundTransparency = 1,
        Position = dim2(0, 8, 0.5, 0),
        Size = dim2(0, 14, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Icon, "deselected", "ImageColor3")
    Library:Themify(items.Icon, "accent", "ImageColor3")
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
        TextColor3 = Theme.deselected,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Holder,
        Name = "\0",
        AnchorPoint = vec2(0, 0.5),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Position = dim2(0, 22, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(30, 30, 30)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    Library:Themify(items.Label, "deselected", "TextColor3")
    
    items.Indicator = Library:Create("Frame", {
        BackgroundTransparency = 1,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.Button,
        AnchorPoint = vec2(0, 0.5),
        Name = "\0",
        Position = dim2(0, 0, 0.5, 0),
        Size = dim2(0, 3, 0, 19),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent
    })
    Library:Themify(items.Indicator, "accent", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Indicator, CornerRadius = dim(0, 2)})
    
    items.Pages = Library:Create("Frame", {
        Parent = Library.Other,
        Visible = false,
        BackgroundTransparency = 1,
        Name = "\0",
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalFlex = Enum.UIFlexAlignment.Fill,
        Parent = items.Pages,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalFlex = Enum.UIFlexAlignment.Fill
    })
    
    Library:Create("UIPadding", {
        PaddingTop = dim(0, 6),
        PaddingBottom = dim(0, 6),
        Parent = items.Pages,
        PaddingRight = dim(0, 6),
        PaddingLeft = dim(0, 6)
    })
    
    items.Left = Library:Create("ScrollingFrame", {
        ScrollBarImageColor3 = rgb(0, 0, 0),
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = items.Pages,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(0, 100, 0, 100),
        BackgroundColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        CanvasSize = dim2(0, 0, 0, 0)
    })
    
    Library:Create("UIListLayout", {
        Parent = items.Left,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalFlex = Enum.UIFlexAlignment.Fill
    })
    
    items.Right = Library:Create("ScrollingFrame", {
        ScrollBarImageColor3 = rgb(0, 0, 0),
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 0,
        Parent = items.Pages,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(0, 100, 0, 100),
        BackgroundColor3 = rgb(255, 255, 255),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        CanvasSize = dim2(0, 0, 0, 0)
    })
    
    Library:Create("UIListLayout", {
        Parent = items.Right,
        Padding = dim(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalFlex = Enum.UIFlexAlignment.Fill
    })
    
    function cfg:Open()
        local tab = self.TabInfo
        
        if tab then
            Library:Tween(tab.Indicator, {BackgroundTransparency = 1})
            Library:Tween(tab.Holder, {BackgroundTransparency = 1})
            Library:Tween(tab.Icon, {ImageColor3 = Theme.deselected})
            Library:Tween(tab.Label, {TextColor3 = Theme.deselected})
            tab.Pages.Visible = false
            tab.Pages.Parent = Library.Other
        end
        
        Library:CloseAllElements()
        
        self.Items.Fade.BackgroundTransparency = 0
        Library:Tween(self.Items.Fade, {BackgroundTransparency = 1})
        
        Library:Tween(items.Indicator, {BackgroundTransparency = 0})
        Library:Tween(items.Holder, {BackgroundTransparency = 0})
        Library:Tween(items.Icon, {ImageColor3 = Theme.accent})
        Library:Tween(items.Label, {TextColor3 = Theme.text_color})
        
        items.Pages.Parent = self.Items.Pages
        items.Pages.Visible = true
        
        self.TabInfo = items
    end
    
    items.Button.MouseButton1Down:Connect(function()
        cfg:Open()
    end)
    
    if not self.TabInfo then
        cfg:Open()
    end
    
    return setmetatable(cfg, Library)
end

function Library:Section(properties)
    local cfg = {
        Name = properties.Name or properties.name or "Section",
        Side = properties.Side or properties.side or "Left",
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Section = Library:Create("Frame", {
        Parent = self.Items[cfg.Side],
        Name = "\0",
        Size = dim2(0, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Section, "inline", "BackgroundColor3")
    
    items.Inline = Library:Create("Frame", {
        Parent = items.Section,
        Size = dim2(1, -2, 1, -2),
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.visible_backgrounds
    })
    Library:Themify(items.Inline, "visible_backgrounds", "BackgroundColor3")
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = rgb(180, 180, 180),
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Inline,
        Name = "\0",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Position = dim2(0, 6, 0, 6),
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Line = Library:Create("Frame", {
        Parent = items.Inline,
        Name = "\0",
        Position = dim2(0, 1, 0, 26),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 0, 1),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Line, "inline", "BackgroundColor3")
    
    items.Elements = Library:Create("Frame", {
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.Inline,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 7, 0, 36),
        Size = dim2(1, -14, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        Parent = items.Elements,
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Library:Create("UIPadding", {
        PaddingBottom = dim(0, 15),
        Parent = items.Elements
    })
    
    Library:Create("UIPadding", {
        PaddingBottom = dim(0, 2),
        Parent = items.Section
    })
    
    return setmetatable(cfg, Library)
end

function Library:Toggle(properties)
    local cfg = {
        Name = properties.Name or "Toggle",
        Flag = properties.Flag or properties.Name or "Toggle",
        Enabled = properties.Default or false,
        Callback = properties.Callback or function() end,
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Toggle = Library:Create("TextButton", {
        Active = false,
        TextTransparency = 1,
        Text = "",
        Parent = self.Items.Elements,
        AutoButtonColor = false,
        Name = "\0",
        Size = dim2(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Selectable = false,
        BorderSizePixel = 0,
        BorderColor3 = rgb(0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Toggle,
        Name = "\0",
        RichText = true,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    items.Components = Library:Create("Frame", {
        Parent = items.Toggle,
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items.Components,
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    items.Switch = Library:Create("Frame", {
        Name = "\0",
        Parent = items.Components,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 29, 0, 14),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    Library:Create("UICorner", {Parent = items.Switch, CornerRadius = dim(0, 7)})
    
    items.SwitchInner = Library:Create("Frame", {
        Parent = items.Switch,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.background
    })
    
    Library:Create("UICorner", {Parent = items.SwitchInner, CornerRadius = dim(0, 6)})
    
    items.Knob = Library:Create("Frame", {
        AnchorPoint = vec2(0, 0.5),
        Parent = items.SwitchInner,
        Name = "\0",
        Position = dim2(0, 2, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 8, 0, 8),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.deselected
    })
    
    Library:Create("UICorner", {Parent = items.Knob, CornerRadius = dim(0, 999)})
    
    function cfg:Set(active)
        Flags[cfg.Flag] = active
        cfg.Callback(active)
        
        Library:Tween(items.Switch, {BackgroundColor3 = active and Theme.accent or Theme.inline})
        Library:Tween(items.SwitchInner, {BackgroundColor3 = active and Theme.accent or Theme.background})
        Library:Tween(items.Knob, {
            BackgroundColor3 = active and rgb(255, 255, 255) or Theme.deselected,
            Position = active and dim2(1, -10, 0.5, 0) or dim2(0, 2, 0.5, 0)
        })
    end
    
    items.Toggle.MouseButton1Click:Connect(function()
        cfg.Enabled = not cfg.Enabled
        cfg:Set(cfg.Enabled)
    end)
    
    cfg:Set(cfg.Enabled)
    ConfigFlags[cfg.Flag] = cfg.Set
    
    return setmetatable(cfg, Library)
end

function Library:Slider(properties)
    local cfg = {
        Name = properties.Name or "Slider",
        Suffix = properties.Suffix or "",
        Flag = properties.Flag or properties.Name or "Slider",
        Callback = properties.Callback or function() end,
        Min = properties.Min or 0,
        Max = properties.Max or 100,
        Decimal = properties.Decimal or 1,
        Value = properties.Default or 10,
        Dragging = false,
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Slider = Library:Create("Frame", {
        Parent = self.Items.Elements,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Slider,
        Name = "\0",
        RichText = true,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    items.Value = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.deselected,
        BorderColor3 = rgb(0, 0, 0),
        Text = "10",
        Parent = items.Slider,
        Name = "\0",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        AnchorPoint = vec2(1, 0),
        Position = dim2(1, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Value, "deselected", "TextColor3")
    
    items.Track = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = items.Slider,
        Name = "\0",
        Position = dim2(0, 0, 0, 21),
        Size = dim2(1, 0, 0, 7),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.background
    })
    
    Library:Create("UICorner", {Parent = items.Track, CornerRadius = dim(0, 3)})
    
    items.Fill = Library:Create("Frame", {
        Name = "\0",
        Parent = items.Track,
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0.5, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent
    })
    Library:Themify(items.Fill, "accent", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Fill, CornerRadius = dim(0, 3)})
    
    items.Knob = Library:Create("Frame", {
        AnchorPoint = vec2(0.5, 0.5),
        Parent = items.Fill,
        Name = "\0",
        Position = dim2(1, 0, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 11, 0, 11),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.accent
    })
    Library:Themify(items.Knob, "accent", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Knob, CornerRadius = dim(0, 999)})
    
    function cfg:Set(value)
        cfg.Value = math.clamp(Library:Round(value, cfg.Decimal), cfg.Min, cfg.Max)
        
        local percent = (cfg.Value - cfg.Min) / (cfg.Max - cfg.Min)
        items.Fill.Size = dim2(percent, 0, 1, 0)
        items.Value.Text = tostring(cfg.Value) .. cfg.Suffix
        
        Flags[cfg.Flag] = cfg.Value
        cfg.Callback(cfg.Value)
    end
    
    function cfg:UpdateFromInput(input)
        if IsMobile then
            local pos = input.Position
            local size = (pos.X - items.Track.AbsolutePosition.X) / items.Track.AbsoluteSize.X
            local value = ((cfg.Max - cfg.Min) * size) + cfg.Min
            cfg:Set(value)
        else
            local mousePos = InputService:GetMouseLocation()
            local size = (mousePos.X - items.Track.AbsolutePosition.X) / items.Track.AbsoluteSize.X
            local value = ((cfg.Max - cfg.Min) * size) + cfg.Min
            cfg:Set(value)
        end
    end
    
    items.Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.Dragging = true
            cfg:UpdateFromInput(input)
        end
    end)
    
    Library:Connection(InputService.InputChanged, function(input)
        if cfg.Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            cfg:UpdateFromInput(input)
        end
    end)
    
    Library:Connection(InputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cfg.Dragging = false
        end
    end)
    
    cfg:Set(cfg.Value)
    ConfigFlags[cfg.Flag] = cfg.Set
    
    return setmetatable(cfg, Library)
end

function Library:Dropdown(properties)
    local cfg = {
        Name = properties.Name or "Dropdown",
        Flag = properties.Flag or properties.Name or "Dropdown",
        Options = properties.Options or {""},
        Callback = properties.Callback or function() end,
        Multi = properties.Multi or false,
        Open = false,
        OptionInstances = {},
        MultiItems = {},
        Items = {},
    }
    
    cfg.Default = properties.Default or (cfg.Multi and {cfg.Options[1]}) or cfg.Options[1] or "None"
    Flags[cfg.Flag] = cfg.Default
    
    local items = cfg.Items
    
    items.Dropdown = Library:Create("Frame", {
        Parent = self.Items.Elements,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Dropdown,
        Name = "\0",
        BackgroundTransparency = 1,
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    items.Button = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = items.Dropdown,
        Name = "\0",
        Position = dim2(0, 0, 0, 21),
        Size = dim2(1, 0, 0, 20),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Button, "inline", "BackgroundColor3")
    
    items.ButtonInner = Library:Create("Frame", {
        Parent = items.Button,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.Arrow = Library:Create("ImageLabel", {
        ImageColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.ButtonInner,
        Name = "\0",
        AnchorPoint = vec2(0, 0.5),
        Image = "rbxassetid://70449495580650",
        BackgroundTransparency = 1,
        Position = dim2(1, -15, 0.5, 0),
        Size = dim2(0, 11, 0, 9),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.SelectedText = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = "Select",
        Parent = items.ButtonInner,
        Name = "\0",
        AnchorPoint = vec2(0, 0.5),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Position = dim2(0, 4, 0.5, 0),
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.SelectedText, "text_color", "TextColor3")
    
    items.List = Library:Create("Frame", {
        Parent = Library.Other,
        Size = dim2(0, 211, 0, 20),
        Name = "\0",
        Position = dim2(0, 0, 0, 21),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.List, "inline", "BackgroundColor3")
    
    items.ListInner = Library:Create("Frame", {
        Parent = items.List,
        Size = dim2(1, -2, 1, -2),
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.inline
    })
    
    Library:Create("UIListLayout", {
        Parent = items.ListInner,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Library:Create("UIPadding", {
        PaddingBottom = dim(0, 2),
        Parent = items.List
    })
    
    function cfg:RenderOption(text)
        local option = Library:Create("TextButton", {
            Parent = items.ListInner,
            AutoButtonColor = false,
            FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
            Name = "\0",
            TextColor3 = Theme.deselected,
            BorderColor3 = rgb(0, 0, 0),
            Text = text,
            AutomaticSize = Enum.AutomaticSize.XY,
            Size = dim2(1, 0, 0, 0),
            AnchorPoint = vec2(0, 0.5),
            Position = dim2(0, 4, 0.5, 0),
            BackgroundTransparency = 1,
            TextXAlignment = Enum.TextXAlignment.Left,
            BorderSizePixel = 0,
            ZIndex = 2,
            TextSize = 14,
            BackgroundColor3 = rgb(255, 255, 255)
        })
        Library:Themify(option, "deselected", "TextColor3")
        
        Library:Create("UIPadding", {
            PaddingTop = dim(0, 4),
            PaddingBottom = dim(0, 4),
            Parent = option,
            PaddingRight = dim(0, 4),
            PaddingLeft = dim(0, 4)
        })
        
        table.insert(cfg.OptionInstances, option)
        return option
    end
    
    function cfg:SetVisible(visible)
        items.List.Position = dim2(0, items.Button.AbsolutePosition.X, 0, items.Button.AbsolutePosition.Y + 80)
        items.List.Size = dim_offset(items.Button.AbsoluteSize.X + 1, 0)
        items.List.Visible = visible
        items.List.Parent = visible and Library.Items or Library.Other
        Library:Tween(items.Arrow, {Rotation = visible and 180 or 0})
    end
    
    function cfg:Set(value)
        local selected = {}
        local isTable = type(value) == "table"
        
        for _, option in cfg.OptionInstances do
            if option.Text == value or (isTable and table.find(value, option.Text)) then
                table.insert(selected, option.Text)
                cfg.MultiItems = selected
                option.TextColor3 = Theme.text_color
                option.BackgroundTransparency = 0.95
            else
                option.TextColor3 = Theme.deselected
                option.BackgroundTransparency = 1
            end
        end
        
        items.SelectedText.Text = isTable and table.concat(selected, ", ") or selected[1] or ""
        Flags[cfg.Flag] = isTable and selected or selected[1]
        cfg.Callback(Flags[cfg.Flag])
    end
    
    function cfg:RefreshOptions(options)
        for _, option in cfg.OptionInstances do
            option:Destroy()
        end
        cfg.OptionInstances = {}
        
        for _, option in options do
            local button = cfg:RenderOption(option)
            button.MouseButton1Down:Connect(function()
                if cfg.Multi then
                    local selected = table.find(cfg.MultiItems, button.Text)
                    if selected then
                        table.remove(cfg.MultiItems, selected)
                    else
                        table.insert(cfg.MultiItems, button.Text)
                    end
                    cfg:Set(cfg.MultiItems)
                else
                    cfg:SetVisible(false)
                    cfg.Open = false
                    cfg:Set(button.Text)
                end
            end)
        end
    end
    
    items.Button.MouseButton1Click:Connect(function()
        cfg.Open = not cfg.Open
        cfg:SetVisible(cfg.Open)
        Library.OpenElement = cfg
    end)
    
    Library:Connection(InputService.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if not Library:Hovering({items.List, items.Dropdown}) then
                cfg:SetVisible(false)
                cfg.Open = false
            end
        end
    end)
    
    ConfigFlags[cfg.Flag] = cfg.Set
    cfg:RefreshOptions(cfg.Options)
    cfg:Set(cfg.Default)
    
    return setmetatable(cfg, Library)
end

function Library:Label(properties)
    local cfg = {
        Name = properties.Name or "Label",
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Label = Library:Create("Frame", {
        Parent = self.Items.Elements,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Text = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Label,
        Name = "\0",
        BackgroundTransparency = 1,
        RichText = true,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Text, "text_color", "TextColor3")
    
    items.Components = Library:Create("Frame", {
        Parent = items.Label,
        Name = "\0",
        Position = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = items.Components,
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    function cfg:Set(text)
        items.Text.Text = text
    end
    
    return setmetatable(cfg, Library)
end

function Library:Colorpicker(properties)
    local cfg = {
        Name = properties.Name or "Color",
        Flag = properties.Flag or properties.Name or "Colorpicker",
        Callback = properties.Callback or function() end,
        Color = properties.Color or color(1, 1, 1),
        Alpha = properties.Alpha or properties.Transparency or 0,
        Open = false,
        Items = {},
    }
    
    local picker = self:Keypicker(cfg)
    cfg.Items = picker.Items
    cfg.Set = picker.Set
    cfg.SetVisible = picker.SetVisible
    
    cfg:Set(cfg.Color, cfg.Alpha)
    ConfigFlags[cfg.Flag] = cfg.Set
    
    return setmetatable(cfg, Library)
end

function Library:Textbox(properties)
    local cfg = {
        Name = properties.Name or "TextBox",
        PlaceHolder = properties.PlaceHolder or properties.Placeholder or "Type here...",
        Default = properties.Default or "",
        Flag = properties.Flag or properties.Name or "TextBox",
        Callback = properties.Callback or function() end,
        Items = {},
    }
    
    Flags[cfg.Flag] = cfg.Default
    
    local items = cfg.Items
    
    items.Textbox = Library:Create("Frame", {
        Parent = self.Items.Elements,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 0, 0),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        RichText = true,
        Text = cfg.Name,
        Parent = items.Textbox,
        Name = "\0",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    items.Outline = Library:Create("Frame", {
        Parent = items.Textbox,
        Name = "\0",
        Position = dim2(0, 0, 0, 21),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, 0, 0, 20),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.Input = Library:Create("TextBox", {
        Parent = items.Outline,
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        Name = "\0",
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.PlaceHolder,
        Size = dim2(1, -8, 1, 0),
        Selectable = false,
        Position = dim2(0, 4, 0, 0),
        BorderSizePixel = 0,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.XY,
        TextColor3 = Theme.text_color,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    function cfg:Set(text)
        Flags[cfg.Flag] = text
        items.Input.Text = text
        cfg.Callback(text)
    end
    
    items.Input:GetPropertyChangedSignal("Text"):Connect(function()
        cfg:Set(items.Input.Text)
    end)
    
    if cfg.Default then
        cfg:Set(cfg.Default)
    end
    
    ConfigFlags[cfg.Flag] = cfg.Set
    
    return setmetatable(cfg, Library)
end

function Library:Keybind(properties)
    local cfg = {
        Flag = properties.Flag or properties.Name or "Keybind",
        Callback = properties.Callback or function() end,
        Name = properties.Name or "Keybind",
        Key = properties.Key or nil,
        Mode = properties.Mode or "Toggle",
        Active = properties.Default or false,
        Open = false,
        Binding = nil,
        Items = {},
    }
    
    Flags[cfg.Flag] = {
        Mode = cfg.Mode,
        Key = cfg.Key,
        Active = cfg.Active
    }
    
    local items = cfg.Items
    
    items.Button = Library:Create("TextButton", {
        Active = false,
        LayoutOrder = -1,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Items.Components,
        Name = "\0",
        Size = dim2(0, 28, 0, 14),
        Selectable = false,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.inline
    })
    
    items.ButtonInner = Library:Create("Frame", {
        Parent = items.Button,
        Size = dim2(1, -2, 1, -2),
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Theme.inline
    })
    
    Library:Create("UICorner", {Parent = items.ButtonInner, CornerRadius = dim(0, 4)})
    
    items.KeyLabel = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = "NONE",
        Parent = items.ButtonInner,
        Name = "\0",
        TextXAlignment = Enum.TextXAlignment.Center,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.KeyLabel, "text_color", "TextColor3")
    
    Library:Create("UIPadding", {
        Parent = items.KeyLabel,
        PaddingRight = dim(0, 4),
        PaddingLeft = dim(0, 5),
        PaddingBottom = dim(0, 2),
    })
    
    Library:Create("UICorner", {Parent = items.Button, CornerRadius = dim(0, 4)})
    
    items.ModeHolder = Library:Create("TextButton", {
        Name = "\0",
        Text = "",
        AutoButtonColor = false,
        Position = dim2(0.5, 0, 0.5, 0),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(0, 160, 0, 58),
        Visible = false,
        Parent = Library.Items,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.visible_backgrounds
    })
    Library:Themify(items.ModeHolder, "visible_backgrounds", "BackgroundColor3")
    
    items.ModeElements = Library:Create("Frame", {
        BorderColor3 = rgb(0, 0, 0),
        Parent = items.ModeHolder,
        Name = "\0",
        BackgroundTransparency = 1,
        Position = dim2(0, 7, 0, 7),
        Size = dim2(1, -14, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    
    Library:Create("UIListLayout", {
        Parent = items.ModeElements,
        Padding = dim(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Library:Create("UIPadding", {
        PaddingBottom = dim(0, 15),
        Parent = items.ModeElements
    })
    
    items.ModeDropdown = setmetatable(cfg, Library):Dropdown({
        Name = "Mode",
        Options = {"Hold", "Toggle", "Always"},
        Flag = cfg.Flag .. "_OPTION_SETTINGS",
        Callback = function(mode)
            if cfg.Set then cfg:Set(mode) end
        end
    })
    
    function cfg:SetMode(mode)
        cfg.Mode = mode
        if mode == "Always" then
            cfg:Set(true)
        elseif mode == "Hold" then
            cfg:Set(false)
        end
        Flags[cfg.Flag].Mode = mode
    end
    
    function cfg:Set(input)
        if type(input) == "boolean" then
            cfg.Active = input
            if cfg.Mode == "Always" then cfg.Active = true end
        elseif tostring(input):find("Enum") then
            input = input.Name == "Escape" and "NONE" or input
            cfg.Key = input or "NONE"
        elseif table.find({"Toggle", "Hold", "Always"}, input) then
            if input == "Always" then cfg.Active = true end
            cfg.Mode = input
            cfg:SetMode(cfg.Mode)
        elseif type(input) == "table" then
            input.Key = type(input.Key) == "string" and input.Key ~= "NONE" and Library:ConvertEnum(input.key) or input.Key
            input.Key = input.Key == Enum.KeyCode.Escape and "NONE" or input.Key
            cfg.Key = input.Key or "NONE"
            cfg.Mode = input.Mode or "Toggle"
            if input.Active then cfg.Active = input.Active end
            cfg:SetMode(cfg.Mode)
        end
        
        cfg.Callback(cfg.Active)
        
        local text = (tostring(cfg.Key) ~= "Enums" and (KeyNames[cfg.Key] or tostring(cfg.Key):gsub("Enum.", "")) or nil)
        local displayText = text and tostring(text):gsub("KeyCode.", ""):gsub("UserInputType.", "") or "NONE"
        
        items.KeyLabel.Text = " " .. displayText .. " "
        
        Flags[cfg.Flag] = {
            mode = cfg.Mode,
            key = cfg.Key,
            active = cfg.Active
        }
    end
    
    function cfg:SetVisible(visible)
        items.ModeHolder.Visible = visible
        items.ModeHolder.Position = dim2(0, items.Button.AbsolutePosition.X + 2, 0, items.Button.AbsolutePosition.Y + 74)
    end
    
    items.Button.MouseButton1Down:Connect(function()
        task.wait()
        items.KeyLabel.Text = " ... "
        cfg.Binding = Library:Connection(InputService.InputBegan, function(keycode, game_event)
            cfg:Set(keycode.KeyCode ~= Enum.KeyCode.Unknown and keycode.KeyCode or keycode.UserInputType)
            cfg.Binding:Disconnect()
            cfg.Binding = nil
        end)
    end)
    
    items.Button.MouseButton2Down:Connect(function()
        cfg.Open = not cfg.Open
        cfg:SetVisible(cfg.Open)
    end)
    
    Library:Connection(InputService.InputBegan, function(input, game_event)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not Library:Hovering({items.ModeHolder, items.ModeDropdown.Items.List}) then
                items.ModeDropdown:SetVisible(false)
                cfg:SetVisible(false)
                cfg.Open = false
            end
        end
        
        if not game_event then
            local selectedKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
            if selectedKey == cfg.Key then
                if cfg.Mode == "Toggle" then
                    cfg.Active = not cfg.Active
                    cfg:Set(cfg.Active)
                elseif cfg.Mode == "Hold" then
                    cfg:Set(true)
                end
            end
        end
    end)
    
    Library:Connection(InputService.InputEnded, function(input, game_event)
        if game_event then return end
        local selectedKey = input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode or input.UserInputType
        if selectedKey == cfg.Key then
            if cfg.Mode == "Hold" then cfg:Set(false) end
        end
    end)
    
    cfg:Set({Mode = cfg.Mode, Active = cfg.Active, Key = cfg.Key})
    ConfigFlags[cfg.Flag] = cfg.Set
    items.ModeDropdown:Set(cfg.Mode)
    
    return setmetatable(cfg, Library)
end

function Library:Button(properties)
    local cfg = {
        Name = properties.Name or "Button",
        Callback = properties.Callback or function() end,
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Button = Library:Create("TextButton", {
        Active = false,
        BorderColor3 = rgb(0, 0, 0),
        Text = "",
        AutoButtonColor = false,
        Name = "\0",
        Parent = self.Items.Elements,
        Size = dim2(1, 0, 0, 20),
        Selectable = false,
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.inline
    })
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        RichText = true,
        Text = cfg.Name,
        Parent = items.Button,
        Name = "\0",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        Size = dim2(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    items.Button.MouseButton1Click:Connect(function()
        items.Label.TextColor3 = rgb(255, 255, 255)
        Library:Tween(items.Label, {TextColor3 = Theme.text_color})
        cfg.Callback()
    end)
    
    return setmetatable(cfg, Library)
end

function Library:Configs(window)
    local tab = window:Tab({Name = "Settings"})
    
    local section = tab:Section({Name = "Configs", Side = "Left"})
    ConfigHolder = section:Dropdown({
        Name = "Config List",
        Options = {},
        Flag = "config_name_list",
        Callback = function(option)
            if Flags["config_name_text"] then
                ConfigFlags["config_name_text"](option)
            end
        end
    })
    Library:UpdateConfigList()
    
    section:Textbox({Name = "Config Name", Flag = "config_name_text", Default = ""})
    
    section:Button({
        Name = "Save Config",
        Callback = function()
            if Flags["config_name_text"] == "" then return end
            writefile(Library.Directory .. "/configs/" .. Flags["config_name_text"] .. ".cfg", Library:GetConfig())
            Library:UpdateConfigList()
            Notifications:Create({Name = "Saved Config"})
        end
    })
    
    section:Button({
        Name = "Load Config",
        Callback = function()
            if Flags["config_name_text"] == "" then return end
            Library:LoadConfig(readfile(Library.Directory .. "/configs/" .. Flags["config_name_text"] .. ".cfg"))
            Notifications:Create({Name = "Loaded Config"})
        end
    })
    
    section:Button({
        Name = "Delete Config",
        Callback = function()
            if Flags["config_name_text"] == "" then return end
            delfile(Library.Directory .. "/configs/" .. Flags["config_name_text"] .. ".cfg")
            Library:UpdateConfigList()
            Notifications:Create({Name = "Deleted Config"})
        end
    })
    
    local themeSection = tab:Section({Name = "Theme", Side = "Right"})
    
    themeSection:Label({Name = "Accent"}):Colorpicker({
        Flag = "theme_accent",
        Color = Theme.accent,
        Callback = function(newColor) Library:RefreshTheme("accent", newColor) end
    })
    
    themeSection:Label({Name = "Window Outline"}):Colorpicker({
        Flag = "theme_window_outline",
        Color = Theme.window_outline,
        Callback = function(newColor) Library:RefreshTheme("window_outline", newColor) end
    })
    
    themeSection:Label({Name = "Inline"}):Colorpicker({
        Flag = "theme_inline",
        Color = Theme.inline,
        Callback = function(newColor) Library:RefreshTheme("inline", newColor) end
    })
    
    themeSection:Label({Name = "Background"}):Colorpicker({
        Flag = "theme_background",
        Color = Theme.background,
        Callback = function(newColor) Library:RefreshTheme("background", newColor) end
    })
    
    themeSection:Label({Name = "Visible Backgrounds"}):Colorpicker({
        Flag = "theme_visible_backgrounds",
        Color = Theme.visible_backgrounds,
        Callback = function(newColor) Library:RefreshTheme("visible_backgrounds", newColor) end
    })
    
    themeSection:Label({Name = "Text Color"}):Colorpicker({
        Flag = "theme_text_color",
        Color = Theme.text_color,
        Callback = function(newColor) Library:RefreshTheme("text_color", newColor) end
    })
    
    themeSection:Label({Name = "Glow"}):Colorpicker({
        Flag = "theme_glow",
        Color = Theme.glow,
        Callback = function(newColor) Library:RefreshTheme("glow", newColor) end
    })
    
    themeSection:Label({Name = "Deselected"}):Colorpicker({
        Flag = "theme_deselected",
        Color = Theme.deselected,
        Callback = function(newColor) Library:RefreshTheme("deselected", newColor) end
    })
    
    window.Tweening = true
    section:Label({Name = "Menu Bind"}):Keybind({
        Name = "Menu Bind",
        Flag = "menu_bind",
        Default = true,
        Callback = function(bool)
            if window.Tweening then return end
            window:ToggleMenu(bool)
        end
    })
    
    delay(2, function() window.Tweening = false end)
end

function Notifications:Refresh()
    local offset = 50
    for i, notif in Notifications.Notifs do
        Library:Tween(notif, {Position = dim_offset(20, offset)}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
        offset += (notif.AbsoluteSize.Y + 10)
    end
    return offset
end

function Notifications:FadeOut(path)
    Library:Tween(path, {BackgroundTransparency = 1}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
    for _, instance in path:GetDescendants() do
        if instance:IsA("TextLabel") then
            Library:Tween(instance, {TextTransparency = 1}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
        elseif instance:IsA("Frame") then
            Library:Tween(instance, {BackgroundTransparency = 1}, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out))
        end
    end
end

function Notifications:Create(properties)
    local cfg = {
        Name = properties.Name or "Notification",
        Lifetime = properties.LifeTime or 3,
        Items = {},
    }
    
    local items = cfg.Items
    
    items.Outline = Library:Create("Frame", {
        Parent = Library.Items,
        Name = "\0",
        Position = dim2(0, 100, 0, 10),
        BorderColor3 = rgb(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Theme.inline
    })
    Library:Themify(items.Outline, "inline", "BackgroundColor3")
    
    items.Inline = Library:Create("Frame", {
        Parent = items.Outline,
        Name = "\0",
        Position = dim2(0, 1, 0, 1),
        BorderColor3 = rgb(0, 0, 0),
        Size = dim2(1, -2, 1, -2),
        BorderSizePixel = 0,
        BackgroundColor3 = Theme.visible_backgrounds
    })
    Library:Themify(items.Inline, "visible_backgrounds", "BackgroundColor3")
    
    Library:Create("UICorner", {Parent = items.Inline})
    
    items.Label = Library:Create("TextLabel", {
        FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
        TextColor3 = Theme.text_color,
        BorderColor3 = rgb(0, 0, 0),
        Text = cfg.Name,
        Parent = items.Inline,
        Name = "\0",
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        BorderSizePixel = 0,
        ZIndex = 2,
        TextSize = 14,
        BackgroundColor3 = rgb(255, 255, 255)
    })
    Library:Themify(items.Label, "text_color", "TextColor3")
    
    Library:Create("UIPadding", {
        PaddingTop = dim(0, 5),
        PaddingBottom = dim(0, 5),
        Parent = items.Label,
        PaddingRight = dim(0, 5),
        PaddingLeft = dim(0, 5)
    })
    
    Library:Create("UICorner", {Parent = items.Outline})
    
    local index = #Notifications.Notifs + 1
    Notifications.Notifs[index] = items.Outline
    
    local offset = Notifications:Refresh()
    items.Outline.Position = dim_offset(20, offset)
    
    task.spawn(function()
        task.wait(cfg.Lifetime)
        Notifications.Notifs[index] = nil
        Notifications:FadeOut(items.Outline)
        task.wait(1)
        items.Outline:Destroy()
        Notifications:Refresh()
    end)
end

return Library
