--!nolint
--!nocheck

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local GuiInset = GuiService:GetGuiInset().Y

local function LightenColor(C)
    return C:Lerp(Color3.fromRGB(255, 255, 255), 0.6)
end

local function DarkenColor(C)
    return C:Lerp(Color3.fromRGB(0, 0, 0), 0.3)
end

local UI = {
    Flags = {},
    Options = {},
    Connections = {},
    Windows = {},
    Accent = Color3.fromHex("99bcff"),
    AnimationSpeed = 1,
    Version = "2.0",
    _MobileToggle = nil,
    _Watermark = nil,
    _KeybindList = nil,
    Keybinds = {},
}

UI.AccentParts = {}
UI.AccentCallbacks = {}

function UI:SetAccent(Color)
    self.Accent = Color
    for _, Part in self.AccentParts do
        if Part.Inst and Part.Inst.Parent then
            Part.Inst[Part.Prop] = Color
        end
    end
    for _, Callback in self.AccentCallbacks do
        Callback(Color)
    end
end

function UI:RegisterAccent(Inst, Prop)
    Prop = Prop or "BackgroundColor3"
    table.insert(self.AccentParts, { Inst = Inst, Prop = Prop })
    Inst[Prop] = self.Accent
end

function UI:OnAccentChange(Callback)
    if type(Callback) ~= "function" then return end
    table.insert(self.AccentCallbacks, Callback)
    Callback(self.Accent)
end

function UI:Create(ClassName, Properties)
    local Inst = Instance.new(ClassName)
    for K, V in pairs(Properties or {}) do
        Inst[K] = V
    end
    return Inst
end

function UI:Connect(Signal, Callback)
    local Conn = Signal:Connect(Callback)
    table.insert(self.Connections, Conn)
    return Conn
end

function UI:Tween(Inst, Info, Props)
    local Speed = self.AnimationSpeed or 1
    if Speed < 0.05 then Speed = 0.05 end
    local Scale = 1 / Speed
    local Style = self.EasingStyle or Info.EasingStyle
    local Dir = self.EasingDirection or Info.EasingDirection
    if Scale == 1 and Style == Info.EasingStyle and Dir == Info.EasingDirection then
        return TweenService:Create(Inst, Info, Props)
    end
    local Scaled = TweenInfo.new(Info.Time * Scale, Style, Dir, Info.RepeatCount, Info.Reverses, Info.DelayTime)
    return TweenService:Create(Inst, Scaled, Props)
end

function UI:Notify(Text, Time, Color)
    Time = Time or 3
    Color = Color or self.Accent
    
    if not self._NotifyStack then
        local Gui = self:Create("ScreenGui", {
            Name = "Notifications",
            Parent = (gethui and gethui()) or CoreGui,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        })
        local Stack = self:Create("Frame", {
            Name = "Stack",
            Parent = Gui,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 10, 0, 200),
            Size = UDim2.new(0, 200, 1, -210),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        self:Create("UIListLayout", {
            Parent = Stack,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, 6),
        })
        self._NotifyGui = Gui
        self._NotifyStack = Stack
        self._NotifyOrder = 0
    end
    
    self._NotifyOrder = self._NotifyOrder + 1
    
    local Wrapper = self:Create("Frame", {
        Parent = self._NotifyStack,
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = self._NotifyOrder,
        ClipsDescendants = false,
    })
    
    local Outer = self:Create("CanvasGroup", {
        Parent = Wrapper,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.new(0, -60, 0, 0),
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundColor3 = Color3.fromHex("000000"),
        BorderSizePixel = 0,
        GroupTransparency = 1,
    })
    
    self:Create("UIPadding", {
        Parent = Outer,
        PaddingBottom = UDim.new(0, 2),
    })
    
    local Inline = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, 0),
        BackgroundColor3 = Color3.fromHex("393939"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIPadding", {
        Parent = Inline,
        PaddingBottom = UDim.new(0, 2),
    })
    
    local Background = self:Create("Frame", {
        Parent = Inline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, 0),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIGradient", {
        Parent = Background,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("262626")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("191919")),
        }),
    })
    
    local Title = self:Create("TextLabel", {
        Parent = Background,
        Position = UDim2.new(0, 4, 0, 4),
        Size = UDim2.new(0, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.XY,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(Text),
        TextColor3 = Color3.fromHex("A0A0A0"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        RichText = true,
    })
    
    self:Create("UIStroke", {
        Parent = Title,
        Color = Color3.fromHex("000000"),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    
    self:Create("UIPadding", {
        Parent = Title,
        PaddingRight = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 3),
    })
    
    local Liner = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 2, 0, 2),
        Size = UDim2.new(0, 2, 1, -4),
        BackgroundColor3 = Color,
        BorderSizePixel = 0,
        ZIndex = 2,
    })
    
    local DurationLiner = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 2, 1, -1),
        Size = UDim2.new(1, -4, 0, 1),
        BackgroundColor3 = Color,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    
    local InInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local OutInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    TweenService:Create(Outer, InInfo, {
        Position = UDim2.new(0, 0, 0, 0),
        GroupTransparency = 0,
    }):Play()
    
    task.spawn(function()
        task.wait(0.1)
        local TargetWidth = Outer.AbsoluteSize.X - 4
        if TargetWidth > 0 then
            TweenService:Create(DurationLiner, TweenInfo.new(Time, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 0, 1),
            }):Play()
        end
    end)
    
    task.delay(Time, function()
        if not Wrapper.Parent then return end
        TweenService:Create(Outer, OutInfo, {
            Position = UDim2.new(0, -60, 0, 0),
            GroupTransparency = 1,
        }):Play()
        task.delay(OutInfo.Time, function()
            if Wrapper and Wrapper.Parent then Wrapper:Destroy() end
        end)
    end)
    
    return Wrapper
end

function UI:Draggable(Target, Handle)
    Handle = Handle or Target
    local Dragging = false
    local DragStart, StartPos
    local DragInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    
    local function Set(Input)
        if not DragStart or not StartPos then return end
        local Delta = Input.Position - DragStart
        UI:Tween(Target, DragInfo, {
            Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + Delta.Y
            ),
        }):Play()
    end
    
    UI:Connect(Handle.InputBegan, function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        Dragging = true
        DragStart = Input.Position
        StartPos = Target.Position
    end)
    
    UI:Connect(Handle.InputEnded, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)
    
    UI:Connect(UserInputService.InputChanged, function(Input)
        if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
        if Dragging then Set(Input) end
    end)
end

function UI:Watermark(Opts)
    Opts = Opts or {}
    local Text = tostring(Opts.Text or "Hydrogen UI")
    
    local Gui = self:Create("ScreenGui", {
        Name = "Watermark",
        Parent = (gethui and gethui()) or CoreGui,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    local Frame = self:Create("Frame", {
        Parent = Gui,
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(10, 110),
        Size = UDim2.new(0, 0, 0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromHex("000000"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIPadding", {
        Parent = Frame,
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 1),
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 1),
    })
    
    local Gray = self:Create("Frame", {
        Parent = Frame,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromHex("393939"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIPadding", {
        Parent = Gray,
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 1),
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 1),
    })
    
    local GradRing = self:Create("Frame", {
        Parent = Gray,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    local RingGradient = self:Create("UIGradient", {
        Parent = GradRing,
        Rotation = 0,
    })
    self:RegisterAccent(RingGradient)
    
    self:Create("UIPadding", {
        Parent = GradRing,
        PaddingLeft = UDim.new(0, 1),
        PaddingRight = UDim.new(0, 1),
        PaddingTop = UDim.new(0, 1),
        PaddingBottom = UDim.new(0, 1),
    })
    
    local Inside = self:Create("Frame", {
        Parent = GradRing,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIGradient", {
        Parent = Inside,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("1F1F1F")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("181818")),
        }),
    })
    
    self:Create("UIPadding", {
        Parent = Inside,
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 10),
    })
    
    local Lbl = self:Create("TextLabel", {
        Parent = Inside,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = Text,
        TextColor3 = Color3.fromHex("FFFFFF"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    
    self:Draggable(Frame)
    
    local Obj = { Gui = Gui, Frame = Frame, Label = Lbl }
    function Obj:SetText(NewText)
        Lbl.Text = tostring(NewText)
    end
    function Obj:Destroy()
        Gui:Destroy()
    end
    
    self._Watermark = Obj
    return Obj
end

function UI:KeybindList(Opts)
    Opts = Opts or {}
    local Title = tostring(Opts.Title or "Keybinds")
    local Width = tonumber(Opts.Width) or 170
    
    local Gui = self:Create("ScreenGui", {
        Name = "KeybindList",
        Parent = (gethui and gethui()) or CoreGui,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    local Frame = self:Create("Frame", {
        Parent = Gui,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 210),
        Size = UDim2.new(0, Width, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIGradient", {
        Parent = Frame,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("1F1F1F")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("141414")),
        }),
    })
    
    local function Edge(Anchor, Pos, Sz, Color)
        self:Create("Frame", {
            Parent = Frame,
            AnchorPoint = Anchor,
            Position = Pos,
            Size = Sz,
            BackgroundColor3 = Color3.fromHex(Color),
            BorderSizePixel = 0,
            ZIndex = 5,
        })
    end
    
    Edge(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 1), "000000")
    
    local TopLine = self:Create("Frame", {
        Parent = Frame,
        Position = UDim2.new(0, 0, 0, 1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    
    local TopGrad = self:Create("UIGradient", { Parent = TopLine, Rotation = 0 })
    self:RegisterAccent(TopGrad)
    
    Edge(Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, 1), "000000")
    Edge(Vector2.new(0, 1), UDim2.new(0, 1, 1, -1), UDim2.new(1, -2, 0, 1), "393939")
    Edge(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, 1, 1, 0), "000000")
    Edge(Vector2.new(0, 0), UDim2.new(0, 1, 0, 2), UDim2.new(0, 1, 1, -3), "393939")
    Edge(Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, 1, 1, 0), "000000")
    Edge(Vector2.new(1, 0), UDim2.new(1, -1, 0, 2), UDim2.new(0, 1, 1, -3), "393939")
    
    local Inner = self:Create("Frame", {
        Parent = Frame,
        Position = UDim2.new(0, 8, 0, 6),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    
    self:Create("UIListLayout", {
        Parent = Inner,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    
    self:Create("UIPadding", {
        Parent = Inner,
        PaddingBottom = UDim.new(0, 8),
    })
    
    local TitleLbl = self:Create("TextLabel", {
        Parent = Inner,
        Position = UDim2.new(0, -1, 0, 0),
        Size = UDim2.new(1, 0, 0, 13),
        BackgroundTransparency = 1,
        Text = Title,
        TextColor3 = Color3.fromHex("FFFFFF"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 1,
    })
    
    local Entries = self:Create("Frame", {
        Parent = Inner,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    })
    
    self:Create("UIListLayout", {
        Parent = Entries,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    })
    
    self:Create("UIPadding", {
        Parent = Entries,
        PaddingTop = UDim.new(0, 5),
    })
    
    self:Draggable(Frame)
    
    local KeyNames = {
        [Enum.UserInputType.MouseButton1] = "MB1",
        [Enum.UserInputType.MouseButton2] = "MB2",
        [Enum.UserInputType.MouseButton3] = "MB3",
        [Enum.KeyCode.LeftShift] = "LS",
        [Enum.KeyCode.RightShift] = "RS",
        [Enum.KeyCode.LeftControl] = "LC",
        [Enum.KeyCode.RightControl] = "RC",
        [Enum.KeyCode.LeftAlt] = "LA",
        [Enum.KeyCode.RightAlt] = "RA",
        [Enum.KeyCode.CapsLock] = "CAPS",
        [Enum.KeyCode.Insert] = "INS",
        [Enum.KeyCode.Backspace] = "BS",
        [Enum.KeyCode.Return] = "Ent",
        [Enum.KeyCode.Escape] = "ESC",
        [Enum.KeyCode.Space] = "SPC",
    }
    
    local function KeyName(Key)
        if Key == nil then return "None" end
        if typeof(Key) == "EnumItem" then return KeyNames[Key] or Key.Name end
        return tostring(Key)
    end
    
    local Rows = {}
    local function Rebuild()
        for _, R in Rows do R:Destroy() end
        table.clear(Rows)
        for I, Entry in self.Keybinds do
            local Key = Entry.GetKey and Entry.GetKey() or nil
            if Key ~= nil then
                local Row = self:Create("Frame", {
                    Parent = Entries,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2.new(1, 0, 0, 13),
                    LayoutOrder = I,
                })
                local DisplayName = tostring(Entry.Name or "?")
                local NameLbl = self:Create("TextLabel", {
                    Parent = Row,
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.new(1, -50, 1, 0),
                    BackgroundTransparency = 1,
                    Text = DisplayName,
                    TextColor3 = Color3.fromHex("BFC4CC"),
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
                local KeyLbl = self:Create("TextLabel", {
                    Parent = Row,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 46, 1, 0),
                    BackgroundTransparency = 1,
                    Text = KeyName(Key),
                    TextColor3 = self.Accent,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
                self:RegisterAccent(KeyLbl, "TextColor3")
                table.insert(Rows, Row)
            end
        end
    end
    
    local function NotifyKeybind()
        for _, Fn in self._KeybindListeners or {} do Fn() end
    end
    
    function self:RegisterKeybind(Entry)
        if type(Entry) ~= "table" then return end
        table.insert(self.Keybinds, Entry)
        NotifyKeybind()
        return Entry
    end
    
    function self:OnKeybindChange(Fn)
        if type(Fn) ~= "function" then return end
        self._KeybindListeners = self._KeybindListeners or {}
        table.insert(self._KeybindListeners, Fn)
        Fn()
    end
    
    self:OnKeybindChange(Rebuild)
    
    local Obj = { Gui = Gui, Frame = Frame, TitleLabel = TitleLbl }
    function Obj:Refresh() Rebuild() end
    function Obj:SetTitle(NewTitle) TitleLbl.Text = string.upper(tostring(NewTitle)) end
    function Obj:Destroy() Gui:Destroy() end
    
    self._KeybindList = Obj
    return Obj
end

function UI:CreateMobileToggle(Window)
    if self._MobileToggle then return self._MobileToggle end
    
    local ToggleGui = self:Create("ScreenGui", {
        Name = "MobileToggleGui",
        Parent = (gethui and gethui()) or CoreGui,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    local ToggleBtn = self:Create("TextButton", {
        Name = "ToggleButton",
        Parent = ToggleGui,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -70, 0, 60),
        Size = UDim2.fromOffset(55, 55),
        BackgroundColor3 = Color3.fromHex("000000"),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 999,
        Visible = true,
    })
    
    self:Create("UIStroke", {
        Parent = ToggleBtn,
        Color = Color3.fromHex("000000"),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    
    local InnerOutline = self:Create("Frame", {
        Parent = ToggleBtn,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 998,
    })
    
    self:Create("UIStroke", {
        Parent = InnerOutline,
        Color = Color3.fromHex("393939"),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    
    local Bg = self:Create("Frame", {
        Parent = InnerOutline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
        ZIndex = 997,
    })
    
    self:Create("UIGradient", {
        Parent = Bg,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("212121")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("1A1A1A")),
        }),
    })
    
    local Logo = self:Create("ImageLabel", {
        Parent = Bg,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(32, 32),
        BackgroundTransparency = 1,
        ZIndex = 999,
    })
    
    Logo.Image = "rbxassetid://6031092671"
    
    local TopAccent = self:Create("Frame", {
        Parent = InnerOutline,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 0, 1),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
        ZIndex = 1000,
    })
    
    local AccentGrad = self:Create("UIGradient", {
        Parent = TopAccent,
        Rotation = 0,
    })
    self:RegisterAccent(AccentGrad)
    
    local Dragging = false
    local DragStart, StartPos
    
    ToggleBtn.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            DragStart = Input.Position
            StartPos = ToggleBtn.Position
        end
    end)
    
    ToggleBtn.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(Input)
        if not Dragging then return end
        if Input.UserInputType ~= Enum.UserInputType.Touch and Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local Delta = Input.Position - DragStart
        TweenService:Create(ToggleBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(
                StartPos.X.Scale,
                StartPos.X.Offset + Delta.X,
                StartPos.Y.Scale,
                StartPos.Y.Offset + Delta.Y
            )
        }):Play()
    end)
    
    local ToggleRef = { Gui = ToggleGui, Button = ToggleBtn, Visible = true }
    
    function ToggleRef:Toggle()
        if not Window then return end
        Window:Toggle()
    end
    
    function ToggleRef:SetVisible(State)
        self.Visible = State
        ToggleGui.Enabled = State
    end
    
    ToggleBtn.MouseButton1Click:Connect(function()
        if not Dragging then
            ToggleRef:Toggle()
        end
    end)
    
    self:OnAccentChange(function(C)
        if AccentGrad then
            AccentGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C),
                ColorSequenceKeypoint.new(0.5, LightenColor(C)),
                ColorSequenceKeypoint.new(1, C),
            })
        end
    end)
    
    self._MobileToggle = ToggleRef
    return ToggleRef
end

function UI:Window(Opts)
    Opts = Opts or {}
    local Width = tonumber(Opts.Width) or 400
    local Height = tonumber(Opts.Height) or 700
    local MinWidth = tonumber(Opts.MinWidth) or 280
    local MinHeight = tonumber(Opts.MinHeight) or 400
    if Width < MinWidth then Width = MinWidth end
    if Height < MinHeight then Height = MinHeight end
    
    local Gui = self:Create("ScreenGui", {
        Name = "HydrogenUI",
        Parent = (gethui and gethui()) or CoreGui,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    
    local Outer = self:Create("Frame", {
        Parent = Gui,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(Width, Height),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIGradient", {
        Parent = Outer,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("212121")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("1A1A1A")),
        }),
    })
    
    self:Create("UIStroke", {
        Parent = Outer,
        Color = Color3.fromHex("000000"),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    
    local InnerOutline = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    
    self:Create("UIStroke", {
        Parent = InnerOutline,
        Color = Color3.fromHex("393939"),
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
    })
    
    local TopLine = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 1, 0, 1),
        Size = UDim2.new(1, -2, 0, 1),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    
    local TopLineGrad = self:Create("UIGradient", {
        Parent = TopLine,
        Rotation = 0,
    })
    self:RegisterAccent(TopLineGrad)
    
    local TitleText = tostring(Opts.Title or "Hydrogen UI")
    local Title = self:Create("TextLabel", {
        Parent = Outer,
        Position = UDim2.new(0, 6, 0, 9),
        Size = UDim2.new(0, 200, 0, 18),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = TitleText,
        TextColor3 = Color3.fromHex("FFFFFF"),
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    })
    
    local Content = self:Create("Frame", {
        Parent = Outer,
        Position = UDim2.new(0, 5, 0, 34),
        Size = UDim2.new(1, -10, 1, -39),
        BackgroundColor3 = Color3.fromHex("FFFFFF"),
        BorderSizePixel = 0,
    })
    
    self:Create("UIGradient", {
        Parent = Content,
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("161616")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("101010")),
        }),
    })
    
    local function ContentEdge(Anchor, Pos, Sz, Color)
        self:Create("Frame", {
            Parent = Content,
            AnchorPoint = Anchor,
            Position = Pos,
            Size = Sz,
            BackgroundColor3 = Color3.fromHex(Color),
            BorderSizePixel = 0,
            ZIndex = 10,
        })
    end
    
    ContentEdge(Vector2.new(0, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0, 1, 1, 0), "000000")
    ContentEdge(Vector2.new(0, 0), UDim2.new(0, 1, 0, 1), UDim2.new(0, 1, 1, -2), "393939")
    ContentEdge(Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, 1, 1, 0), "000000")
    ContentEdge(Vector2.new(1, 0), UDim2.new(1, -1, 0, 1), UDim2.new(0, 1, 1, -2), "393939")
    ContentEdge(Vector2.new(0, 1), UDim2.new(0, 0, 1, 0), UDim2.new(1, 0, 0, 1), "000000")
    ContentEdge(Vector2.new(0, 1), UDim2.new(0, 1, 1, -1), UDim2.new(1, -2, 0, 1), "393939")
    
    self:Draggable(Outer)
    
    local Window = { Gui = Gui, Outer = Outer, TopLine = TopLine, Content = Content, _Tabs = {} }
    
    function Window:Tab(NameOrOpts)
        local TabOpts = type(NameOrOpts) == "table" and NameOrOpts or { Name = tostring(NameOrOpts) }
        local TabName = tostring(TabOpts.Name or "Tab")
        
        if not self.TabBar then
            self.TabBar = self:Create("Frame", {
                Parent = self.Content,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
            
            self:Create("UIListLayout", {
                Parent = self.TabBar,
                FillDirection = Enum.FillDirection.Horizontal,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })
        end
        
        local Btn = self:Create("TextButton", {
            Parent = self.TabBar,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
            LayoutOrder = #self._Tabs + 1,
        })
        
        local Bg = self:Create("Frame", {
            Parent = Btn,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromHex("FFFFFF"),
            BorderSizePixel = 0,
        })
        
        local Gradient = self:Create("UIGradient", {
            Parent = Bg,
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("1F1F1F")),
                ColorSequenceKeypoint.new(1, Color3.fromHex("181818")),
            }),
        })
        
        local Lbl = self:Create("TextLabel", {
            Parent = Bg,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = TabName,
            TextSize = 12,
            TextColor3 = Color3.fromHex("8C8F99"),
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
        })
        
        local TopGradient = self:Create("Frame", {
            Parent = Bg,
            Size = UDim2.new(1, 0, 0, 1),
            BackgroundColor3 = Color3.fromHex("FFFFFF"),
            BorderSizePixel = 0,
            BackgroundTransparency = 1,
            ZIndex = 5,
        })
        
        local TabTopGrad = self:Create("UIGradient", {
            Parent = TopGradient,
            Rotation = 0,
        })
        self:RegisterAccent(TabTopGrad)
        
        local Page = self:Create("CanvasGroup", {
            Parent = self.Content,
            Position = UDim2.new(0, 0, 0, 24),
            Size = UDim2.new(1, 0, 1, -24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
            GroupTransparency = 1,
        })
        
        self:Create("UIPadding", {
            Parent = Page,
            PaddingLeft = UDim.new(0, 6),
            PaddingRight = UDim.new(0, 6),
            PaddingTop = UDim.new(0, 11),
            PaddingBottom = UDim.new(0, 6),
        })
        
        local LeftColumn = self:Create("ScrollingFrame", {
            Parent = Page,
            AnchorPoint = Vector2.new(0, 0),
            Position = UDim2.new(0, 0, 0, -2),
            Size = UDim2.new(0.5, -3, 1, 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true,
        })
        
        self:Create("UIListLayout", {
            Parent = LeftColumn,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        
        self:Create("UIPadding", {
            Parent = LeftColumn,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 6),
        })
        
        local RightColumn = self:Create("ScrollingFrame", {
            Parent = Page,
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, -2),
            Size = UDim2.new(0.5, -3, 1, 2),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            ClipsDescendants = true,
        })
        
        self:Create("UIListLayout", {
            Parent = RightColumn,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })
        
        self:Create("UIPadding", {
            Parent = RightColumn,
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 6),
        })
        
        local TabRef = {
            Name = TabName,
            Button = Btn,
            Bg = Bg,
            Label = Lbl,
            Page = Page,
            Left = LeftColumn,
            Right = RightColumn,
            Gradient = Gradient,
            TopGradient = TopGradient,
            Active = false,
            IsLeft = false,
            IsRight = false,
        }
        
        local PageInfo = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local BgInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local InactiveA, InactiveB = Color3.fromHex("1F1F1F"), Color3.fromHex("181818")
        local ActiveA, ActiveB = Color3.fromHex("161616"), Color3.fromHex("151515")
        
        function TabRef:SetActive(State)
            self.Active = State
            if State then
                self.Page.Visible = true
                UI:Tween(self.Page, PageInfo, { GroupTransparency = 0 }):Play()
                UI:Tween(Lbl, BgInfo, { TextColor3 = Color3.fromHex("FFFFFF") }):Play()
                UI:Tween(TopGradient, BgInfo, { BackgroundTransparency = 0 }):Play()
                Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, ActiveA),
                    ColorSequenceKeypoint.new(1, ActiveB),
                })
            else
                UI:Tween(self.Page, PageInfo, { GroupTransparency = 1 }):Play()
                task.delay(PageInfo.Time, function()
                    if not self.Active then self.Page.Visible = false end
                end)
                UI:Tween(Lbl, BgInfo, { TextColor3 = Color3.fromHex("8C8F99") }):Play()
                UI:Tween(TopGradient, BgInfo, { BackgroundTransparency = 1 }):Play()
                Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, InactiveA),
                    ColorSequenceKeypoint.new(1, InactiveB),
                })
            end
        end
        
        function TabRef:Section(SecOpts)
            return self:_BuildSection(SecOpts, TabRef)
        end
        
        local WinRef = self
        Btn.MouseButton1Click:Connect(function()
            for _, T in WinRef._Tabs do
                if T ~= TabRef and T.Active then T:SetActive(false) end
            end
            TabRef:SetActive(true)
        end)
        
        table.insert(self._Tabs, TabRef)
        
        local N = #self._Tabs
        for I, T in self._Tabs do
            T.Button.Size = UDim2.new(1 / N, 0, 1, 0)
            T.IsLeft = (I == 1)
            T.IsRight = (I == N)
            T:SetActive(T.Active)
        end
        
        if N == 1 then
            TabRef:SetActive(true)
        end
        
        return TabRef
    end
    
    function Window:_BuildSection(SecOpts, TabRef)
        SecOpts = type(SecOpts) == "table" and SecOpts or { Name = tostring(SecOpts) }
        local SecName = tostring(SecOpts.Name or "section")
        local Side = string.lower(tostring(SecOpts.Side or "Left"))
        local Column = (Side == "right") and TabRef.Right or TabRef.Left
        
        local Sec = self:Create("Frame", {
            Parent = Column,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        
        local SecTitle = self:Create("TextLabel", {
            Parent = Sec,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 4, 0, 2),
            AutomaticSize = Enum.AutomaticSize.X,
            Size = UDim2.new(0, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = SecName,
            TextColor3 = Color3.fromHex("FFFFFF"),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 7,
        })
        
        local Body = self:Create("Frame", {
            Parent = Sec,
            Position = UDim2.new(0, 0, 0, 16),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
        })
        
        self:Create("UIListLayout", {
            Parent = Body,
            FillDirection = Enum.FillDirection.Vertical,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
        })
        
        self:Create("UIPadding", {
            Parent = Body,
            PaddingBottom = UDim.new(0, 4),
        })
        
        local function AddToggle(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Toggle")
            local Default = Opts.Default == true
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            local Flag = tostring(Opts.Flag or ("_" .. Name))
            local State = Default
            UI.Flags[Flag] = State
            
            local Row = self:Create("TextButton", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            local Box = self:Create("Frame", {
                Parent = Row,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
            })
            
            local BoxGray = self:Create("Frame", {
                Parent = Box,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local BoxInside = self:Create("Frame", {
                Parent = BoxGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("131313"),
                BorderSizePixel = 0,
            })
            
            local Fill = self:Create("Frame", {
                Parent = BoxInside,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 0, 0, 0),
                BackgroundColor3 = self.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            self:RegisterAccent(Fill)
            
            local Lbl = self:Create("TextLabel", {
                Parent = Row,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 20, 0.5, 0),
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = Name,
                TextColor3 = State and Color3.fromHex("FFFFFF") or Color3.fromHex("8C8F99"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local TweenIn = TweenInfo.new(0.16, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
            local TweenOut = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            
            local function Render()
                local Info = State and TweenIn or TweenOut
                UI:Tween(Fill, Info, {
                    Size = State and UDim2.new(1, -2, 1, -2) or UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = State and 0 or 1,
                }):Play()
                UI:Tween(Lbl, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = State and Color3.fromHex("FFFFFF") or Color3.fromHex("8C8F99"),
                }):Play()
            end
            
            Fill.Size = State and UDim2.new(1, -2, 1, -2) or UDim2.new(0, 0, 0, 0)
            Fill.BackgroundTransparency = State and 0 or 1
            
            local function SetState(V, Fire)
                V = V == true
                if V == State then return end
                State = V
                UI.Flags[Flag] = State
                Render()
                if Fire ~= false then Callback(State) end
            end
            
            Row.MouseButton1Click:Connect(function() SetState(not State) end)
            
            local Obj = { Container = Row, Box = Box, Fill = Fill }
            function Obj:Get() return State end
            function Obj:Set(V) SetState(V) end
            
            UI.Options[Flag] = {
                Save = function() return State end,
                Load = function(Data) SetState(Data == true) end,
            }
            
            return Obj
        end
        
        local function AddSlider(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Slider")
            local Min = tonumber(Opts.Min) or 0
            local Max = tonumber(Opts.Max) or 100
            local Step = tonumber(Opts.Step) or 1
            local Default = tonumber(Opts.Default) or Min
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            local Flag = tostring(Opts.Flag or ("_" .. Name))
            local Value = math.clamp(Default, Min, Max)
            UI.Flags[Flag] = Value
            
            local Container = self:Create("Frame", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 26),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local Lbl = self:Create("TextLabel", {
                Parent = Container,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, -60, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = Name,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local ValLbl = self:Create("TextLabel", {
                Parent = Container,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -26, 0, 0),
                Size = UDim2.new(0, 24, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                TextColor3 = Color3.fromHex("8C8F99"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextYAlignment = Enum.TextYAlignment.Center,
                Text = tostring(Value),
            })
            
            local Track = self:Create("TextButton", {
                Parent = Container,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 10),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            local TrackGray = self:Create("Frame", {
                Parent = Track,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local TrackInside = self:Create("Frame", {
                Parent = TrackGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("131313"),
                BorderSizePixel = 0,
            })
            
            local Fill = self:Create("Frame", {
                Parent = TrackInside,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new((Value - Min) / (Max - Min), -2, 1, -2),
                BackgroundColor3 = self.Accent,
                BorderSizePixel = 0,
            })
            self:RegisterAccent(Fill)
            
            local function SetVal(V, Fire)
                V = math.clamp(math.floor((V - Min) / Step + 0.5) * Step + Min, Min, Max)
                if V == Value then return end
                Value = V
                UI.Flags[Flag] = Value
                ValLbl.Text = tostring(Value)
                Fill.Size = UDim2.new((Value - Min) / (Max - Min), -2, 1, -2)
                if Fire ~= false then Callback(Value) end
            end
            
            local Dragging = false
            Track.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    local Ax, Aw = TrackInside.AbsolutePosition.X, TrackInside.AbsoluteSize.X
                    if Aw <= 0 then return end
                    local T = math.clamp((Input.Position.X - Ax) / Aw, 0, 1)
                    SetVal(Min + T * (Max - Min))
                end
            end)
            
            Track.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(Input)
                if not Dragging then return end
                if Input.UserInputType ~= Enum.UserInputType.MouseMovement and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                local Ax, Aw = TrackInside.AbsolutePosition.X, TrackInside.AbsoluteSize.X
                if Aw <= 0 then return end
                local T = math.clamp((Input.Position.X - Ax) / Aw, 0, 1)
                SetVal(Min + T * (Max - Min))
            end)
            
            local Obj = { Container = Container, Track = Track, Fill = Fill }
            function Obj:Get() return Value end
            function Obj:Set(V) SetVal(tonumber(V) or Value) end
            
            UI.Options[Flag] = {
                Save = function() return Value end,
                Load = function(Data) SetVal(tonumber(Data) or Value) end,
            }
            
            return Obj
        end
        
        local function AddButton(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Button")
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            
            local Row = self:Create("Frame", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 21),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local Btn = self:Create("TextButton", {
                Parent = Row,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            local BGray = self:Create("Frame", {
                Parent = Btn,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local BInside = self:Create("Frame", {
                Parent = BGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("FFFFFF"),
                BorderSizePixel = 0,
            })
            
            self:Create("UIGradient", {
                Parent = BInside,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("1B1B1B")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("121212")),
                }),
            })
            
            local Lbl = self:Create("TextLabel", {
                Parent = BInside,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = Name,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            Btn.MouseButton1Click:Connect(function()
                UI:Tween(Lbl, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = self.Accent,
                }):Play()
                task.delay(0.1, function()
                    UI:Tween(Lbl, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        TextColor3 = Color3.fromHex("FFFFFF"),
                    }):Play()
                end)
                Callback()
            end)
            
            local Obj = { Container = Row, Button = Btn }
            return Obj
        end
        
        local function AddDropdown(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Dropdown")
            local Options = type(Opts.Options) == "table" and Opts.Options or {}
            local Default = tostring(Opts.Default or Options[1] or "")
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            local Flag = tostring(Opts.Flag or ("_" .. Name))
            local Value = Default
            UI.Flags[Flag] = Value
            
            local Container = self:Create("Frame", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 36),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local Lbl = self:Create("TextLabel", {
                Parent = Container,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 12),
                BackgroundTransparency = 1,
                Text = Name,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local Box = self:Create("TextButton", {
                Parent = Container,
                AnchorPoint = Vector2.new(0, 1),
                Position = UDim2.new(0, 0, 1, 0),
                Size = UDim2.new(1, 0, 0, 21),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            local BoxGray = self:Create("Frame", {
                Parent = Box,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local BoxInside = self:Create("Frame", {
                Parent = BoxGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("FFFFFF"),
                BorderSizePixel = 0,
            })
            
            self:Create("UIGradient", {
                Parent = BoxInside,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("1B1B1B")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("121212")),
                }),
            })
            
            local ValLbl = self:Create("TextLabel", {
                Parent = BoxInside,
                Position = UDim2.new(0, 4, 0, 0),
                Size = UDim2.new(1, -14, 1, 0),
                BackgroundTransparency = 1,
                Text = Value,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                TextTruncate = Enum.TextTruncate.AtEnd,
                ClipsDescendants = true,
            })
            
            local Popup = self:Create("CanvasGroup", {
                Parent = Gui,
                Size = UDim2.new(0, 100, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
                Visible = false,
                GroupTransparency = 1,
                ZIndex = 50,
            })
            
            self:Create("UIPadding", {
                Parent = Popup,
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                PaddingTop = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 1),
            })
            
            local PopupGray = self:Create("Frame", {
                Parent = Popup,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
                ZIndex = 50,
            })
            
            self:Create("UIPadding", {
                Parent = PopupGray,
                PaddingLeft = UDim.new(0, 1),
                PaddingRight = UDim.new(0, 1),
                PaddingTop = UDim.new(0, 1),
                PaddingBottom = UDim.new(0, 1),
            })
            
            local PopupInside = self:Create("Frame", {
                Parent = PopupGray,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundColor3 = Color3.fromHex("131313"),
                BorderSizePixel = 0,
                ZIndex = 50,
            })
            
            self:Create("UIListLayout", {
                Parent = PopupInside,
                FillDirection = Enum.FillDirection.Vertical,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })
            
            local Open = false
            local OptionButtons = {}
            
            local function SetVal(V, Fire)
                V = tostring(V)
                if V == Value then return end
                Value = V
                UI.Flags[Flag] = Value
                ValLbl.Text = Value
                for _, B in OptionButtons do
                    B.TextColor3 = (B.Text == Value) and self.Accent or Color3.fromHex("FFFFFF")
                end
                if Fire ~= false then Callback(Value) end
            end
            
            local function BuildOptions()
                for _, C in PopupInside:GetChildren() do
                    if C:IsA("TextButton") then C:Destroy() end
                end
                OptionButtons = {}
                for I, Opt in Options do
                    local Btn = self:Create("TextButton", {
                        Parent = PopupInside,
                        Size = UDim2.new(1, 0, 0, 14),
                        BackgroundColor3 = Color3.fromHex("131313"),
                        BorderSizePixel = 0,
                        AutoButtonColor = false,
                        Text = tostring(Opt),
                        TextColor3 = (tostring(Opt) == Value) and self.Accent or Color3.fromHex("FFFFFF"),
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextYAlignment = Enum.TextYAlignment.Center,
                        LayoutOrder = I,
                        ZIndex = 51,
                    })
                    
                    self:Create("UIPadding", {
                        Parent = Btn,
                        PaddingLeft = UDim.new(0, 5),
                    })
                    
                    Btn.MouseButton1Click:Connect(function()
                        SetVal(Btn.Text)
                        if ClosePopup then ClosePopup() end
                    end)
                    
                    table.insert(OptionButtons, Btn)
                end
            end
            
            BuildOptions()
            
            local PopupIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local PopupOut = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local SlideOff = 10
            local PopupGap = 60
            
            local function AnchorXY()
                local AbsPos = Box.AbsolutePosition
                local AbsSize = Box.AbsoluteSize
                Popup.Size = UDim2.new(0, AbsSize.X, 0, 0)
                return AbsPos.X, AbsPos.Y + AbsSize.Y + PopupGap
            end
            
            local ClosePopup
            ClosePopup = function()
                if not Open then return end
                Open = false
                local X, Y = AnchorXY()
                UI:Tween(Popup, PopupOut, {
                    Position = UDim2.fromOffset(X, Y - SlideOff),
                    GroupTransparency = 1,
                }):Play()
                task.delay(PopupOut.Time, function()
                    if not Open then Popup.Visible = false end
                end)
            end
            
            Box.MouseButton1Click:Connect(function()
                Open = not Open
                local X, Y = AnchorXY()
                if Open then
                    Popup.Visible = true
                    Popup.Position = UDim2.fromOffset(X, Y - SlideOff)
                    Popup.GroupTransparency = 1
                    UI:Tween(Popup, PopupIn, {
                        Position = UDim2.fromOffset(X, Y),
                        GroupTransparency = 0,
                    }):Play()
                else
                    UI:Tween(Popup, PopupOut, {
                        Position = UDim2.fromOffset(X, Y - SlideOff),
                        GroupTransparency = 1,
                    }):Play()
                    task.delay(PopupOut.Time, function()
                        if not Open then Popup.Visible = false end
                    end)
                end
            end)
            
            UserInputService.InputBegan:Connect(function(Input)
                if not Open then return end
                if Input.UserInputType ~= Enum.UserInputType.MouseButton1 and Input.UserInputType ~= Enum.UserInputType.Touch then return end
                local Mx, My = Input.Position.X, Input.Position.Y
                local function InAbs(Inst)
                    local P, S = Inst.AbsolutePosition, Inst.AbsoluteSize
                    return Mx >= P.X and Mx <= P.X + S.X and My >= P.Y and My <= P.Y + S.Y
                end
                if InAbs(Box) or InAbs(Popup) then return end                Open = false
                local X, Y = AnchorXY()
                UI:Tween(Popup, PopupOut, {
                    Position = UDim2.fromOffset(X, Y - SlideOff),
                    GroupTransparency = 1,
                }):Play()
                task.delay(PopupOut.Time, function()
                    if not Open then Popup.Visible = false end
                end)
            end)
            
            local Obj = { Container = Container, Box = Box, Popup = Popup }
            function Obj:Get() return Value end
            function Obj:Set(V) SetVal(tostring(V)) end
            function Obj:SetOptions(Opts2)
                Options = type(Opts2) == "table" and Opts2 or {}
                BuildOptions()
            end
            
            UI.Options[Flag] = {
                Save = function() return Value end,
                Load = function(Data) SetVal(tostring(Data)) end,
            }
            
            return Obj
        end
        
        local function AddColorpicker(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Color")
            local Color = typeof(Opts.Default) == "Color3" and Opts.Default or Color3.fromRGB(255, 255, 255)
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            local Flag = tostring(Opts.Flag or ("_" .. Name))
            local H, S, V = Color3.toHSV(Color)
            UI.Flags[Flag] = Color
            
            local Row = self:Create("Frame", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local Lbl = self:Create("TextLabel", {
                Parent = Row,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, -32, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = Name,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local Swatch = self:Create("TextButton", {
                Parent = Row,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, 27, 0, 15),
                AutoButtonColor = false,
                Text = "",
                BackgroundColor3 = Color3.fromHex("000105"),
                BorderSizePixel = 0,
            })
            
            local SwatchInline = self:Create("Frame", {
                Parent = Swatch,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("252527"),
                BorderSizePixel = 0,
            })
            
            local SwatchHandle = self:Create("Frame", {
                Parent = SwatchInline,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
            })
            
            self:Create("ImageLabel", {
                Parent = SwatchHandle,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = "rbxassetid://18274452449",
                ScaleType = Enum.ScaleType.Tile,
                TileSize = UDim2.new(0, 6, 0, 6),
                ZIndex = 2,
            })
            
            local SwatchFill = self:Create("Frame", {
                Parent = SwatchHandle,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color,
                BorderSizePixel = 0,
                ZIndex = 3,
            })
            
            self:Create("UIGradient", {
                Parent = SwatchFill,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(167, 167, 167)),
                }),
            })
            
            local PickerHolder = self:Create("CanvasGroup", {
                Parent = Gui,
                Size = UDim2.new(0, 218, 0, 248),
                BackgroundColor3 = Color3.fromHex("131313"),
                BorderSizePixel = 0,
                Visible = false,
                GroupTransparency = 1,
                ZIndex = 50,
            })
            
            self:Create("UIStroke", {
                Parent = PickerHolder,
                Color = Color3.fromHex("000000"),
                Thickness = 1,
                Transparency = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            
            local PickerInner = self:Create("Frame", {
                Parent = PickerHolder,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            self:Create("UIStroke", {
                Parent = PickerInner,
                Color = Color3.fromHex("393939"),
                Thickness = 1,
                Transparency = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            
            local PickerBody = self:Create("Frame", {
                Parent = PickerHolder,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            self:Create("UIPadding", {
                Parent = PickerBody,
                PaddingTop = UDim.new(0, 8),
                PaddingBottom = UDim.new(0, 8),
                PaddingLeft = UDim.new(0, 8),
                PaddingRight = UDim.new(0, 8),
            })
            
            local MainBg = self:Create("Frame", {
                Parent = PickerBody,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local SatValArea = self:Create("Frame", {
                Parent = MainBg,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, -0),
                BackgroundColor3 = Color3.fromRGB(255, 0, 0),
                BorderSizePixel = 0,
            })
            
            self:Create("UIStroke", {
                Parent = SatValArea,
                Color = Color3.fromHex("000105"),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            
            local SatLayer = self:Create("TextButton", {
                Parent = SatValArea,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            self:Create("UIGradient", {
                Parent = SatLayer,
                Rotation = 270,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
                }),
            })
            
            local ValLayer = self:Create("TextButton", {
                Parent = SatValArea,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            self:Create("UIGradient", {
                Parent = ValLayer,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            })
            
            local SatValMarker = self:Create("Frame", {
                Parent = SatValArea,
                Size = UDim2.new(0, 2, 0, 2),
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
            
            local HueArea = self:Create("TextButton", {
                Parent = MainBg,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -14, 0, 0),
                Size = UDim2.new(0, 12, 1, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            self:Create("UIStroke", {
                Parent = HueArea,
                Color = Color3.fromHex("000105"),
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            
            self:Create("UIGradient", {
                Parent = HueArea,
                Rotation = 270,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
            })
            
            local HueMarker = self:Create("Frame", {
                Parent = HueArea,
                Size = UDim2.new(1, 0, 0, 2),
                BorderSizePixel = 1,
                BorderColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
            
            local function ApplyState()
                local C = Color3.fromHSV(H, S, V)
                Color = C
                SwatchFill.BackgroundColor3 = C
                SatValArea.BackgroundColor3 = Color3.fromHSV(H, 1, 1)
                SatValMarker.Position = UDim2.new(S, 0, 1 - V, 0)
                HueMarker.Position = UDim2.new(0, 0, 1 - H, 0)
                UI.Flags[Flag] = C
                Callback(C)
            end
            
            ApplyState()
            
            local DraggingSat, DraggingHue = false, false
            local Open = false
            local PickerIn = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local PickerOut = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local SlideOff = 10
            
            local function AnchorXY()
                local AbsP = Swatch.AbsolutePosition
                return AbsP.X - PickerHolder.AbsoluteSize.X + Swatch.AbsoluteSize.X, AbsP.Y + Swatch.AbsoluteSize.Y + 65
            end
            
            local function SetVisible(B)
                if B == Open then return end
                Open = B
                local X, Y = AnchorXY()
                if Open then
                    PickerHolder.Visible = true
                    PickerHolder.Position = UDim2.fromOffset(X, Y - SlideOff)
                    PickerHolder.GroupTransparency = 1
                    UI:Tween(PickerHolder, PickerIn, {
                        Position = UDim2.fromOffset(X, Y),
                        GroupTransparency = 0,
                    }):Play()
                else
                    UI:Tween(PickerHolder, PickerOut, {
                        Position = UDim2.fromOffset(X, Y - SlideOff),
                        GroupTransparency = 1,
                    }):Play()
                    task.delay(PickerOut.Time, function()
                        if not Open then PickerHolder.Visible = false end
                    end)
                end
            end
            
            Swatch.MouseButton1Click:Connect(function() SetVisible(not Open) end)
            
            SatLayer.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSat = true
                end
            end)
            
            ValLayer.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    DraggingSat = true
                end
            end)
            
            HueArea.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    DraggingHue = true
                end
            end)
            
            UserInputService.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    DraggingSat = false
                    DraggingHue = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(Input)
                if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if not (DraggingSat or DraggingHue) then return end
                local M = UserInputService:GetMouseLocation()
                local Mx, My = M.X, M.Y - GuiInset
                if DraggingSat then
                    local Ap, Sz = SatValArea.AbsolutePosition, SatValArea.AbsoluteSize
                    S = Sz.X > 0 and math.clamp((Mx - Ap.X) / Sz.X, 0, 1) or 0
                    V = Sz.Y > 0 and 1 - math.clamp((My - Ap.Y) / Sz.Y, 0, 1) or 0
                elseif DraggingHue then
                    local Ap, Sz = HueArea.AbsolutePosition, HueArea.AbsoluteSize
                    H = Sz.Y > 0 and 1 - math.clamp((My - Ap.Y) / Sz.Y, 0, 1) or 0
                end
                ApplyState()
            end)
            
            local Obj = { Container = Row, Swatch = Swatch, Picker = PickerHolder }
            function Obj:Get() return Color end
            function Obj:Set(NewColor)
                if typeof(NewColor) == "Color3" then H, S, V = Color3.toHSV(NewColor) end
                ApplyState()
            end
            
            UI.Options[Flag] = {
                Save = function() return { _t = "Color", v = Color:ToHex() } end,
                Load = function(Data)
                    if type(Data) == "table" and type(Data.v) == "string" then
                        local Ok, C = pcall(Color3.fromHex, Data.v)
                        if Ok then Obj:Set(C) end
                    end
                end,
            }
            
            return Obj
        end
        
        local function AddKeybind(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Name = tostring(Opts.Name or "Keybind")
            local Default = Opts.Default
            local Callback = type(Opts.Callback) == "function" and Opts.Callback or function() end
            local Flag = tostring(Opts.Flag or ("_" .. Name))
            local Key = Default
            local State = false
            UI.Flags[Flag] = State
            
            local Row = self:Create("TextButton", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, 16),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
            })
            
            local Lbl = self:Create("TextLabel", {
                Parent = Row,
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, 0, 0.5, 0),
                Size = UDim2.new(1, -62, 1, 0),
                BackgroundTransparency = 1,
                Text = Name,
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local Box = self:Create("Frame", {
                Parent = Row,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.fromOffset(56, 16),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
            })
            
            local BoxGray = self:Create("Frame", {
                Parent = Box,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local BoxInside = self:Create("Frame", {
                Parent = BoxGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("FFFFFF"),
                BorderSizePixel = 0,
            })
            
            self:Create("UIGradient", {
                Parent = BoxInside,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("1B1B1B")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("121212")),
                }),
            })
            
            local KeyNames = {
                [Enum.KeyCode.LeftShift] = "LS",
                [Enum.KeyCode.RightShift] = "RS",
                [Enum.KeyCode.LeftControl] = "LC",
                [Enum.KeyCode.RightControl] = "RC",
                [Enum.KeyCode.LeftAlt] = "LA",
                [Enum.KeyCode.RightAlt] = "RA",
                [Enum.KeyCode.CapsLock] = "CAPS",
                [Enum.KeyCode.Insert] = "INS",
                [Enum.KeyCode.Backspace] = "BS",
                [Enum.KeyCode.Return] = "Ent",
                [Enum.KeyCode.Escape] = "ESC",
                [Enum.KeyCode.Space] = "SPC",
            }
            
            local function KeyDisplay(K)
                if K == nil then return "None" end
                if typeof(K) == "EnumItem" then return KeyNames[K] or K.Name end
                return tostring(K)
            end
            
            local Display = self:Create("TextLabel", {
                Parent = BoxInside,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text = KeyDisplay(Key),
                TextColor3 = Color3.fromHex("FFFFFF"),
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
            })
            
            local Listening = false
            local ListenConn
            
            local function Refresh()
                if Listening then
                    Display.Text = "..."
                    Display.TextColor3 = self.Accent
                else
                    Display.Text = KeyDisplay(Key)
                    Display.TextColor3 = Color3.fromHex("FFFFFF")
                end
            end
            
            local function CancelListen()
                if ListenConn then ListenConn:Disconnect() end
                ListenConn = nil
                Listening = false
                Refresh()
            end
            
            local function StartListen()
                if Listening then CancelListen(); return end
                Listening = true
                Refresh()
                task.defer(function()
                    if not Listening then return end
                    ListenConn = UserInputService.InputBegan:Connect(function(Input)
                        local T = Input.UserInputType
                        if T == Enum.UserInputType.Keyboard then
                            local K = Input.KeyCode
                            if K == Enum.KeyCode.Escape then
                                CancelListen()
                            else
                                Key = K
                                Listening = false
                                if ListenConn then ListenConn:Disconnect() end
                                ListenConn = nil
                                Refresh()
                                UI:NotifyKeybind()
                            end
                        elseif T == Enum.UserInputType.MouseButton1 or T == Enum.UserInputType.MouseButton2 or T == Enum.UserInputType.MouseButton3 then
                            Key = T
                            Listening = false
                            if ListenConn then ListenConn:Disconnect() end
                            ListenConn = nil
                            Refresh()
                            UI:NotifyKeybind()
                        end
                    end)
                end)
            end
            
            Row.MouseButton1Click:Connect(StartListen)
            
            local function KeyMatches(Input)
                if Key == nil or typeof(Key) ~= "EnumItem" then return false end
                if Key.EnumType == Enum.KeyCode then
                    return Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == Key
                elseif Key.EnumType == Enum.UserInputType then
                    return Input.UserInputType == Key
                end
                return false
            end
            
            UI:Connect(UserInputService.InputBegan, function(Input, GameProc)
                if GameProc then return end
                if Listening then return end
                if UserInputService:GetFocusedTextBox() then return end
                if not KeyMatches(Input) then return end
                State = not State
                UI.Flags[Flag] = State
                Callback(State)
            end)
            
            UI:RegisterKeybind({
                Name = Name,
                GetKey = function() return Key end,
                GetState = function() return State end,
            })
            
            local Obj = { Container = Row, Box = Box, Display = Display }
            function Obj:Get() return State end
            function Obj:GetKey() return Key end
            function Obj:SetKey(K)
                if Listening then CancelListen() end
                Key = K
                Refresh()
                UI:NotifyKeybind()
            end
            
            UI.Options[Flag] = {
                Save = function()
                    local Out = { _t = "Key" }
                    if typeof(Key) == "EnumItem" then
                        Out.k = tostring(Key.EnumType) .. "." .. Key.Name
                    end
                    return Out
                end,
                Load = function(Data)
                    if type(Data) ~= "table" or Data._t ~= "Key" then return end
                    local NewKey = nil
                    if type(Data.k) == "string" then
                        local EType, EName = string.match(Data.k, "^(%w+)%.(%w+)$")
                        if EType and EName then
                            pcall(function() NewKey = Enum[EType][EName] end)
                        end
                    end
                    Obj:SetKey(NewKey)
                end,
            }
            
            return Obj
        end
        
        local function AddPreview(Opts)
            Opts = type(Opts) == "table" and Opts or {}
            local Height = tonumber(Opts.Height) or 260
            
            local Container = self:Create("Frame", {
                Parent = Body,
                Size = UDim2.new(1, 0, 0, Height),
                BackgroundColor3 = Color3.fromHex("000000"),
                BorderSizePixel = 0,
            })
            
            local BoxGray = self:Create("Frame", {
                Parent = Container,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("393939"),
                BorderSizePixel = 0,
            })
            
            local BoxInside = self:Create("Frame", {
                Parent = BoxGray,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromHex("FFFFFF"),
                BorderSizePixel = 0,
            })
            
            self:Create("UIGradient", {
                Parent = BoxInside,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex("161616")),
                    ColorSequenceKeypoint.new(1, Color3.fromHex("101010")),
                }),
            })
            
            local Area = self:Create("TextButton", {
                Parent = BoxInside,
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutoButtonColor = false,
                Text = "",
                ClipsDescendants = true,
            })
            
            local Viewport = self:Create("ViewportFrame", {
                Parent = Area,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, Height, 0, Height),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            })
            
            local Esp = self:Create("Frame", {
                Parent = Area,
                AnchorPoint = Vector2.new(0.5, 0),
                Size = UDim2.new(0, 150, 0, 250),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 2,
            })
            
            local FillGradient = self:Create("UIGradient", {
                Parent = Esp,
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            })
            
            local BoxAccent = self:Create("UIStroke", {
                Parent = Esp,
                Thickness = 1,
                Color = Color3.fromRGB(255, 255, 255),
                LineJoinMode = Enum.LineJoinMode.Miter,
                Enabled = false,
            })
            
            local BoxGradient = self:Create("UIGradient", {
                Parent = BoxAccent,
                Rotation = 90,
            })
            
            local Healthbar = self:Create("Frame", {
                Parent = Esp,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(0, -4, 0, -2),
                Size = UDim2.new(0, 4, 1, 4),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Visible = false,
                ZIndex = 2,
            })
            
            local HealthAccent = self:Create("Frame", {
                Parent = Healthbar,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 1, -2),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                BorderSizePixel = 0,
                ZIndex = 2,
            })
            
            local HealthGradient = self:Create("UIGradient", {
                Parent = HealthAccent,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
                }),
            })
            
            local HealthFade = self:Create("Frame", {
                Parent = Healthbar,
                Position = UDim2.new(0, 1, 0, 1),
                Size = UDim2.new(1, -2, 0, 0),
                BackgroundColor3 = Color3.fromRGB(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 3,
            })
            
            local HealthText = self:Create("TextLabel", {
                Parent = Healthbar,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(0, -2, 0, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Text = "100",
                TextColor3 = Color3.fromRGB(0, 255, 0),
                TextSize = 12,
                Visible = false,
                ZIndex = 2,
            })
            
            local NameLbl = self:Create("TextLabel", {
                Parent = Esp,
                AnchorPoint = Vector2.new(0.5, 1),
                Position = UDim2.new(0.5, 0, 0, -4),
                AutomaticSize = Enum.AutomaticSize.XY,
                BackgroundTransparency = 1,
                Text = "Player",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Visible = false,
                ZIndex = 2,
            })
            
            local BottomHolder = self:Create("Frame", {
                Parent = Esp,
                Position = UDim2.new(0, -2, 1, 4),
                Size = UDim2.new(1, 4, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
            })
            
            self:Create("UIListLayout", {
                Parent = BottomHolder,
                Padding = UDim.new(0, 1),
                SortOrder = Enum.SortOrder.LayoutOrder,
            })
            
            local DistLbl = self:Create("TextLabel", {
                Parent = BottomHolder,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = "0st",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Visible = false,
                ZIndex = 2,
            })
            
            local WeaponLbl = self:Create("TextLabel", {
                Parent = BottomHolder,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BackgroundTransparency = 1,
                Text = "none",
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12,
                Visible = false,
                ZIndex = 2,
            })
            
            local Settings = {
                Enabled = true,
                Box = false,
                Fill = false,
                Healthbar = false,
                HealthbarText = false,
                Name = false,
                Distance = false,
                Weapon = false,
                BoxColor = Color3.fromRGB(255, 255, 255),
                BoxThickness = 1,
            }
            
            local ViewportCamera, Model
            local RotationY = 0
            local Distance = 10
            local Dragging = false
            local LastPos = Vector3.zero
            
            local function ViewModel(Item)
                if not Item then return end
                Viewport:ClearAllChildren()
                Model = nil
                if Item:IsA("Model") then
                    Item.Archivable = true
                    Model = Item:Clone()
                    Model.Parent = Viewport
                    if not Model.PrimaryPart then
                        for _, Child in Model:GetDescendants() do
                            if Child:IsA("BasePart") then
                                Model.PrimaryPart = Child
                                break
                            end
                        end
                    end
                elseif Item:IsA("BasePart") then
                    Model = Instance.new("Model")
                    Model.Parent = Viewport
                    local Clone = Item:Clone()
                    Clone.Parent = Model
                    Clone.CFrame = CFrame.new()
                    Model.PrimaryPart = Clone
                end
                ViewportCamera = self:Create("Camera", { Parent = Viewport, FieldOfView = 60 })
                Viewport.CurrentCamera = ViewportCamera
            end
            
            local function BoxSolve(Root)
                local UpVec = Root.CFrame.UpVector
                local RootPos = Root.Position
                local CamCF = ViewportCamera.CFrame
                local WorldTop = RootPos + (UpVec * 1.8) + CamCF.UpVector
                local WorldBottom = RootPos - (UpVec * 2.5) - CamCF.UpVector
                local HolderSize = Viewport.AbsoluteSize
                local Top = ViewportCamera:WorldToScreenPoint(WorldTop)
                Top = Vector2.new(Top.X * HolderSize.X, Top.Y * HolderSize.Y)
                local Bottom = ViewportCamera:WorldToScreenPoint(WorldBottom)
                Bottom = Vector2.new(Bottom.X * HolderSize.X, Bottom.Y * HolderSize.Y)
                local Width = math.max(math.floor(math.abs(Top.X - Bottom.X)), 9)
                local BoxH = math.max(math.floor(math.max(math.abs(Bottom.Y - Top.Y), Width / 2)), 12)
                local BoxSize = Vector2.new(math.floor(math.max(BoxH / 1.5, Width)), BoxH)
                local BoxPos = Vector2.new(
                    math.floor(Top.X * 0.5 + Bottom.X * 0.5 - BoxSize.X * 0.5),
                    math.floor(math.min(Top.Y, Bottom.Y))
                )
                local Dist = (RootPos - CamCF.Position).Magnitude
                return BoxSize, BoxPos, math.floor(Dist * 0.333)
            end
            
            local function ChangeHealth()
                local Value = math.abs(math.sin(tick()))
                local Eased = TweenService:GetValue(Value, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
                HealthFade.Size = UDim2.new(1, -2, 1 - Eased, 0)
                HealthText.Text = tostring(math.floor(Eased * 100 + 0.5))
                HealthText.Position = UDim2.new(0, -2, 1 - Eased, 0)
            end
            
            Area.MouseEnter:Connect(function() Dragging = true end)
            Area.MouseLeave:Connect(function() Dragging = false end)
            
            Area.InputBegan:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    LastPos = Input.Position
                end
            end)
            
            Area.InputEnded:Connect(function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(Input)
                if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
                    local Delta = Input.Position - LastPos
                    LastPos = Input.Position
                    RotationY = RotationY - Delta.X * 0.01
                elseif Input.UserInputType == Enum.UserInputType.MouseWheel then
                    Distance = math.clamp(Distance - Input.Position.Z * 2, 1, 100)
                end
            end)
            
            UI:Connect(RunService.RenderStepped, function()
                if not (ViewportCamera and Model) then return end
                if not UI:IsEffectivelyVisible(Area) then return end
                RotationY = RotationY + 0.01
                local Root = Model.PrimaryPart
                if not Root then return end
                local Center = Root.Position
                local CamCF = CFrame.new(Center) * CFrame.Angles(0, RotationY, 0) * CFrame.new(0, 0, Distance)
                ViewportCamera.CFrame = CFrame.lookAt(CamCF.Position, Center)
                if Settings.Enabled then
                    local BoxSize, BoxPos, Dist = BoxSolve(Root)
                    Esp.Visible = true
                    Esp.Position = UDim2.new(0.5, 0, 0, BoxPos.Y)
                    Esp.Size = UDim2.fromOffset(BoxSize.X, BoxSize.Y)
                    if Settings.Distance then DistLbl.Text = Dist .. "st" end
                    if Settings.Healthbar or Settings.HealthbarText then ChangeHealth() end
                else
                    Esp.Visible = false
                end
            end)
            
            task.defer(function()
                local LP = Players.LocalPlayer
                local Char = LP and LP.Character
                if Char then ViewModel(Char) end
            end)
            
            local function Render()
                BoxAccent.Enabled = Settings.Box
                BoxAccent.Thickness = Settings.BoxThickness
                BoxGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Settings.BoxColor),
                    ColorSequenceKeypoint.new(1, Settings.BoxColor),
                })
                Esp.BackgroundTransparency = Settings.Fill and 0.7 or 1
                if Settings.Fill then
                    FillGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Settings.BoxColor),
                        ColorSequenceKeypoint.new(1, Settings.BoxColor),
                    })
                end
                Healthbar.Visible = Settings.Healthbar
                HealthText.Visible = Settings.HealthbarText
                NameLbl.Visible = Settings.Name
                DistLbl.Visible = Settings.Distance
                WeaponLbl.Visible = Settings.Weapon
            end
            
            Render()
            
            local Obj = { Container = Container, Viewport = Viewport, Settings = Settings }
            
            function Obj:Get(Key) return Settings[Key] end
            function Obj:Set(Key, Value)
                Settings[Key] = Value
                Render()
            end
            function Obj:SetText(Which, Text)
                local Map = { Name = NameLbl, Distance = DistLbl, Weapon = WeaponLbl }
                local L = Map[Which]
                if L then L.Text = tostring(Text) end
            end
            function Obj:ViewModel(M) ViewModel(M) end
            
            return Obj
        end
        
        local SectionRef = {
            Toggle = AddToggle,
            Slider = AddSlider,
            Button = AddButton,
            Dropdown = AddDropdown,
            Colorpicker = AddColorpicker,
            Keybind = AddKeybind,
            Preview = AddPreview,
        }
        
        return SectionRef
    end
    
    function Window:Toggle()
        self:SetVisible(not self.Visible)
    end
    
    function Window:SetVisible(State)
        self.Visible = State
        Gui.Enabled = State
        if State then
            UI:CreateMobileToggle(Window)
        end
    end
    
    function Window:Destroy()
        Gui:Destroy()
        table.remove(UI.Windows, table.find(UI.Windows, Window))
    end
    
    Window.Visible = true
    table.insert(UI.Windows, Window)
    
    UI:CreateMobileToggle(Window)
    
    return Window
end

function UI:Unload()
    for _, Conn in self.Connections do
        if Conn then Conn:Disconnect() end
    end
    self.Connections = {}
    for _, Win in self.Windows do
        if Win and Win.Gui then Win.Gui:Destroy() end
    end
    self.Windows = {}
    self.Flags = {}
    self.Options = {}
    if self._MobileToggle then
        self._MobileToggle.Gui:Destroy()
        self._MobileToggle = nil
    end
    if self._Watermark then
        self._Watermark:Destroy()
        self._Watermark = nil
    end
    if self._KeybindList then
        self._KeybindList:Destroy()
        self._KeybindList = nil
    end
end

function UI:IsEffectivelyVisible(Inst)
    local Cur = Inst
    while Cur do
        if Cur:IsA("ScreenGui") then return Cur.Enabled end
        if Cur:IsA("GuiObject") and not Cur.Visible then return false end
        Cur = Cur.Parent
    end
    return false
end

UI.EasingStyle = Enum.EasingStyle.Quad
UI.EasingDirection = Enum.EasingDirection.Out

function UI:RegisterKeybind(Entry)
    if type(Entry) ~= "table" then return end
    table.insert(self.Keybinds, Entry)
    return Entry
end

function UI:NotifyKeybind()
    if self._KeybindList then self._KeybindList:Refresh() end
end

return UI
