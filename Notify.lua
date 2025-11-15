local Task = loadstring(game:HttpGet('https://raw.githubusercontent.com/panipurienjoyer-cell/Utility/refs/heads/main/Task.lua'))();
local Events = loadstring(game:HttpGet('https://raw.githubusercontent.com/panipurienjoyer-cell/Utility/refs/heads/main/Events.lua'))();
local Services = loadstring(game:HttpGet('https://raw.githubusercontent.com/panipurienjoyer-cell/Utility/refs/heads/main/Services.lua'))();

local TweenService, CoreGui, UserInputService, GuiService = Services:Get('TweenService', 'CoreGui', 'UserInputService', 'GuiService');

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);
local SafeUI = SafeUI or (function() return CoreGui end);

local Notify_PADDING = 10;
local Notify_GAP = 5;
local Notify_DURATION = 3;
local Notify_WIDTH = 300;
local Notify_HEIGHT = 80;
local Notify_CORNER_RADIUS = 4;
local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint);
local PROGRESS_TWEEN_INFO = TweenInfo.new(Notify_DURATION, Enum.EasingStyle.Linear);

local NotifySystem = {};
NotifySystem.__index = NotifySystem;

local function generateRandomString()
    local chars = {};
    for i = 1, math.random(8, 16) do
        chars[i] = string.char(math.random(97, 122));
    end;
    return table.concat(chars);
end;

local THEME = {
    Background = Color3.fromRGB(30, 30, 30),
    Text = Color3.fromRGB(255, 255, 255),
    SubText = Color3.fromRGB(180, 180, 180),
    
    Types = {
        Info = {
            Color = Color3.fromRGB(78, 131, 255)
        },
        Success = {
            Color = Color3.fromRGB(85, 170, 127)
        },
        Warning = {
            Color = Color3.fromRGB(245, 179, 66)
        },
        Error = {
            Color = Color3.fromRGB(235, 87, 87)
        }
    }
};

local ActiveNotifys = {};

local Container = Instance.new('ScreenGui');
Container.Name = generateRandomString();
Container.ResetOnSpawn = false;
Container.ZIndexBehavior = Enum.ZIndexBehavior.Sibling;
Container.Enabled = true;
ProtectGui(Container);
Container.Parent = SafeUI();

local Notify = {};
Notify.__index = Notify;

local function createIconText(notifType)
    if notifType == 'Info' then
        return 'ℹ';
    elseif notifType == 'Success' then
        return '✓';
    elseif notifType == 'Warning' then
        return '⚠';
    elseif notifType == 'Error' then
        return 'X';
    end;
    return '';
end;

function Notify.new(options)
    local self = setmetatable({}, Notify);
    
    self.Type = options.Type or 'Info';
    self.Title = options.Title or 'Notify';
    self.Text = options.Text or '';
    self.Duration = options.Duration or Notify_DURATION;
    self.Callback = options.Callback;
    
    self.Destroying = Events.new();
    self._Task = Task.new();
    
    self:_init();
    
    return self;
end;

function Notify:GetScreenSize()
    local viewport = workspace.CurrentCamera.ViewportSize;
    local insets = GuiService:GetGuiInset();
    return viewport.X, viewport.Y - insets.Y;
end;

function Notify:GetScaledSize()
    local screenWidth, screenHeight = self:GetScreenSize();
    local scale = math.min(screenWidth / 1920, 1);
    
    local width = math.min(Notify_WIDTH * scale, screenWidth * 0.9);
    local height = Notify_HEIGHT * scale;
    
    return width, height;
end;

function Notify:_init()
    local typeInfo = THEME.Types[self.Type];
    local width, height = self:GetScaledSize();
    local screenWidth, screenHeight = self:GetScreenSize();
    
    self.Frame = Instance.new('Frame');
    self.Frame.Name = generateRandomString();
    self.Frame.Size = UDim2.new(0, width, 0, height);
    self.Frame.Position = UDim2.new(1, -Notify_PADDING, 1, -Notify_PADDING);
    self.Frame.BackgroundColor3 = THEME.Background;
    self.Frame.BorderSizePixel = 0;
    self.Frame.AnchorPoint = Vector2.new(1, 1);
    self.Frame.Parent = Container;
    
    local corner = Instance.new('UICorner');
    corner.CornerRadius = UDim.new(0, Notify_CORNER_RADIUS);
    corner.Parent = self.Frame;
    
    self.Icon = Instance.new('TextLabel');
    self.Icon.Name = generateRandomString();
    self.Icon.Size = UDim2.new(0, 24 * (height/Notify_HEIGHT), 0, 24 * (height/Notify_HEIGHT));
    self.Icon.Position = UDim2.new(0, 16 * (width/Notify_WIDTH), 0.5, 0);
    self.Icon.AnchorPoint = Vector2.new(0, 0.5);
    self.Icon.BackgroundTransparency = 1;
    self.Icon.Text = createIconText(self.Type);
    self.Icon.Font = Enum.Font.GothamBold;
    self.Icon.TextSize = 20 * (height/Notify_HEIGHT);
    self.Icon.TextColor3 = typeInfo.Color;
    self.Icon.Parent = self.Frame;
    
    local iconSize = self.Icon.Size.X.Offset;
    
    self.TitleLabel = Instance.new('TextLabel');
    self.TitleLabel.Name = generateRandomString();
    self.TitleLabel.Size = UDim2.new(1, -iconSize - 50, 0, 20 * (height/Notify_HEIGHT));
    self.TitleLabel.Position = UDim2.new(0, iconSize + 30, 0, 16 * (height/Notify_HEIGHT));
    self.TitleLabel.BackgroundTransparency = 1;
    self.TitleLabel.Text = self.Title;
    self.TitleLabel.Font = Enum.Font.GothamBold;
    self.TitleLabel.TextSize = 14 * (height/Notify_HEIGHT);
    self.TitleLabel.TextColor3 = THEME.Text;
    self.TitleLabel.TextXAlignment = Enum.TextXAlignment.Left;
    self.TitleLabel.Parent = self.Frame;
    
    self.TextLabel = Instance.new('TextLabel');
    self.TextLabel.Name = generateRandomString();
    self.TextLabel.Size = UDim2.new(1, -iconSize - 50, 0, 30 * (height/Notify_HEIGHT));
    self.TextLabel.Position = UDim2.new(0, iconSize + 30, 0, 36 * (height/Notify_HEIGHT));
    self.TextLabel.BackgroundTransparency = 1;
    self.TextLabel.Text = self.Text;
    self.TextLabel.Font = Enum.Font.Gotham;
    self.TextLabel.TextSize = 14 * (height/Notify_HEIGHT);
    self.TextLabel.TextColor3 = THEME.SubText;
    self.TextLabel.TextXAlignment = Enum.TextXAlignment.Left;
    self.TextLabel.TextWrapped = true;
    self.TextLabel.Parent = self.Frame;
    
    self.CloseButton = Instance.new('TextButton');
    self.CloseButton.Name = generateRandomString();
    self.CloseButton.Size = UDim2.new(0, 16 * (height/Notify_HEIGHT), 0, 16 * (height/Notify_HEIGHT));
    self.CloseButton.Position = UDim2.new(1, -24 * (width/Notify_WIDTH), 0, 16 * (height/Notify_HEIGHT));
    self.CloseButton.BackgroundTransparency = 1;
    self.CloseButton.Text = 'X';
    self.CloseButton.Font = Enum.Font.Gotham;
    self.CloseButton.TextSize = 14 * (height/Notify_HEIGHT);
    self.CloseButton.TextColor3 = THEME.SubText;
    self.CloseButton.Parent = self.Frame;
    
    self.ProgressContainer = Instance.new('Frame');
    self.ProgressContainer.Name = generateRandomString();
    self.ProgressContainer.Size = UDim2.new(1, 0, 0, 4);
    self.ProgressContainer.Position = UDim2.new(0, 0, 1, -4);
    self.ProgressContainer.BackgroundTransparency = 0.9;
    self.ProgressContainer.BackgroundColor3 = Color3.fromRGB(100, 100, 100);
    self.ProgressContainer.BorderSizePixel = 0;
    self.ProgressContainer.Parent = self.Frame;
    
    self.ProgressBar = Instance.new('Frame');
    self.ProgressBar.Name = generateRandomString();
    self.ProgressBar.Size = UDim2.new(1, 0, 1, 0);
    self.ProgressBar.BackgroundColor3 = typeInfo.Color;
    self.ProgressBar.BorderSizePixel = 0;
    self.ProgressBar.Parent = self.ProgressContainer;
    
    self._Task:AddTask(self.CloseButton.MouseButton1Click:Connect(function()
        self:Destroy();
    end));
    
    table.insert(ActiveNotifys, self);
    
    self:UpdatePositions();
    
    local targetPos = UDim2.new(1, -Notify_PADDING, 1, -Notify_PADDING);
    TweenService:Create(self.Frame, TWEEN_INFO, {
        Position = targetPos,
        AnchorPoint = Vector2.new(1, 1)
    }):Play();
    
    local progressTween = TweenService:Create(self.ProgressBar, PROGRESS_TWEEN_INFO, {Size = UDim2.new(0, 0, 1, 0)});
    progressTween:Play();
    
    self._Task:AddTask(progressTween.Completed:Connect(function()
        if self._destroyed then return end;
        self:Destroy();
    end));
    
    if self.Callback then
        self.ClickableArea = Instance.new('TextButton');
        self.ClickableArea.Name = generateRandomString();
        self.ClickableArea.Size = UDim2.new(1, 0, 1, -4);
        self.ClickableArea.Position = UDim2.new(0, 0, 0, 0);
        self.ClickableArea.BackgroundTransparency = 1;
        self.ClickableArea.Text = '';
        self.ClickableArea.Parent = self.Frame;
        
        self._Task:AddTask(self.ClickableArea.MouseButton1Click:Connect(function()
            self.Callback();
            self:Destroy();
        end));
    end;
    
    return self;
end;

function Notify:UpdatePositions()
    local totalHeight = 0;
    
    for i = #ActiveNotifys, 1, -1 do
        local notif = ActiveNotifys[i];
        if notif._destroyed then continue end;
        
        local width, height = notif:GetScaledSize();
        
        local newY = -Notify_PADDING - totalHeight;
        local targetPosition = UDim2.new(
            1, -Notify_PADDING,  
            1, newY              
        );
        
        if notif == self then
            notif.originalPosition = targetPosition;
        else
            TweenService:Create(notif.Frame, TWEEN_INFO, {
                Position = targetPosition,
                AnchorPoint = Vector2.new(1, 1)
            }):Play();
        end;
        
        totalHeight = totalHeight + height + Notify_GAP;
    end;
end;

function Notify:Destroy()
    if self._destroyed then return end;
    self._destroyed = true;
    
    self.Destroying:Fire();
    
    local targetPosition = UDim2.new(0, -self.Frame.AbsoluteSize.X - Notify_PADDING, 1, -Notify_PADDING);
    local tween = TweenService:Create(self.Frame, TWEEN_INFO, {
        Position = targetPosition,
        Transparency = 1
    });
    
    tween:Play();
    
    self._Task:AddTask(tween.Completed:Connect(function()
        local index = table.find(ActiveNotifys, self);
        if index then
            table.remove(ActiveNotifys, index);
        end;
        
        if #ActiveNotifys > 0 then
            ActiveNotifys[1]:UpdatePositions();
        end;
        
        self.Frame:Destroy();
        self._Task:Clean();
    end));
end;

function NotifySystem.new()
    local self = setmetatable({}, NotifySystem);
    self._Task = Task.new();
    return self;
end;

function NotifySystem:Create(options)
    return Notify.new(options);
end;

function NotifySystem:Notify(title, message, NotifyType, duration, callback)
    return self:Create({
        Title = title,
        Text = message,
        Type = NotifyType or 'Unknown',
        Duration = duration,
        Callback = callback
    });
end;

function NotifySystem:Info(title, message, duration, callback)
    return self:Notify(title, message, 'Info', duration, callback);
end;

function NotifySystem:Success(title, message, duration, callback)
    return self:Notify(title, message, 'Success', duration, callback);
end;

function NotifySystem:Warning(title, message, duration, callback)
    return self:Notify(title, message, 'Warning', duration, callback);
end;

function NotifySystem:Error(title, message, duration, callback)
    return self:Notify(title, message, 'Error', duration, callback);
end;

function NotifySystem:ClearAll()
    for _, Notify in ipairs(ActiveNotifys) do
        Notify:Destroy();
    end;
end;

function NotifySystem:Destroy()
    self:ClearAll();
    self._Task:Clean();
end;

return NotifySystem.new();

--[[
local Notifys = NotifySystem.new()
NotifySystem:Info('Information', 'This is an informational message')
NotifySystem:Warning('Warning', 'This action may cause issues')
NotifySystem:Error('Error', 'Something went wrong')
]]
