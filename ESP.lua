local TaskLib = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/panipurienjoyer-cell/Utility/refs/heads/main/Task.lua"))(); 

local cloneref = cloneref or function(o) return o end;
local RunService: RunService = cloneref(game:GetService('RunService')); 
local Players: Players = cloneref(game:GetService('Players')); 
local Workspace: Workspace = cloneref(game:GetService('Workspace')); 

local LocalPlayer = Players.LocalPlayer; 
local Camera = Workspace.CurrentCamera; 
local ViewportSize = Camera.ViewportSize; 
local GuiContainer = gethui and gethui() or game:GetService('CoreGui'); 

local Floor = math.floor; 
local Round = math.round; 
local ATan2 = math.atan2; 
local Sin = math.sin; 
local Cos = math.cos; 
local TableClear = table.clear; 
local TableUnpack = table.unpack; 
local TableFind = table.find; 

local WorldToViewportPoint = Camera.WorldToViewportPoint; 
local IsA = Workspace.IsA; 
local GetPivot = Workspace.GetPivot; 
local FindFirstChild = Workspace.FindFirstChild; 
local FindFirstChildOfClass = Workspace.FindFirstChildOfClass; 
local GetChildren = Workspace.GetChildren; 
local ToOrientation = CFrame.identity.ToOrientation; 
local PointToObjectSpace = CFrame.identity.PointToObjectSpace; 
local LerpColor = Color3.new().Lerp; 
local Min2 = Vector2.zero.Min; 
local Max2 = Vector2.zero.Max; 
local Lerp2 = Vector2.zero.Lerp; 
local Min3 = Vector3.zero.Min; 
local Max3 = Vector3.zero.Max; 

local HEALTH_BAR_OFFSET = Vector2.new(5, 0); 
local HEALTH_TEXT_OFFSET = Vector2.new(3, 0); 
local HEALTH_BAR_OUTLINE_OFFSET = Vector2.new(0, 1); 
local NAME_OFFSET = Vector2.new(0, 2); 
local DISTANCE_OFFSET = Vector2.new(0, 2); 
local CUBE_VERTS = { 
    Vector3.new(-1, -1, -1), 
    Vector3.new(-1, 1, -1), 
    Vector3.new(-1, 1, 1), 
    Vector3.new(-1, -1, 1), 
    Vector3.new(1, -1, -1), 
    Vector3.new(1, 1, -1), 
    Vector3.new(1, 1, 1), 
    Vector3.new(1, -1, 1) 
}; 

local function IsBodyPart(name) 
    return name == 'Head' or name:find('Torso') or name:find('Leg') or name:find('Arm'); 
end; 

local function GetBoundingBox(parts) 
    if not parts or #parts == 0 then 
        return CFrame.new(), Vector3.new(4, 4, 4); 
    end; 

    local minV, maxV; 
    for i = 1, #parts do 
        local part = parts[i]; 
        if part and part.Parent then 
            local cframe, size = part.CFrame, part.Size; 
            minV = Min3(minV or cframe.Position, (cframe - size*0.5).Position); 
            maxV = Max3(maxV or cframe.Position, (cframe + size*0.5).Position); 
        end; 
    end; 

    if not minV or not maxV then 
        return CFrame.new(), Vector3.new(4, 4, 4); 
    end; 

    local center = (minV + maxV)*0.5; 
    local front = Vector3.new(center.X, center.Y, maxV.Z); 
    return CFrame.new(center, front), maxV - minV; 
end; 

local function WorldToScreen(world) 
    local screen, inBounds = WorldToViewportPoint(Camera, world); 
    return Vector2.new(screen.X, screen.Y), inBounds, screen.Z; 
end; 

local function CalculateCorners(cframe, size) 
    local corners = {}; 
    for i = 1, #CUBE_VERTS do 
        corners[i] = WorldToScreen((cframe + size*0.5*CUBE_VERTS[i]).Position); 
    end; 

    local minV = Min2(ViewportSize, TableUnpack(corners)); 
    local maxV = Max2(Vector2.zero, TableUnpack(corners)); 
    return { 
        corners = corners, 
        topLeft = Vector2.new(Floor(minV.X), Floor(minV.Y)), 
        topRight = Vector2.new(Floor(maxV.X), Floor(minV.Y)), 
        bottomLeft = Vector2.new(Floor(minV.X), Floor(maxV.Y)), 
        bottomRight = Vector2.new(Floor(maxV.X), Floor(maxV.Y)) 
    }; 
end; 

local function RotateVector(vector, radians) 
    local c, s = Cos(radians), Sin(radians); 
    return Vector2.new(c*vector.X - s*vector.Y, s*vector.X + c*vector.Y); 
end; 

local function Boolify(x) 
    return x and true or false; 
end; 

local ESPPlayer = {}; 
ESPPlayer.__index = ESPPlayer; 

function ESPPlayer.new(player, iface) 
    local self = setmetatable({}, ESPPlayer); 
    self.player = assert(player, 'Missing argument #1 (Player expected)'); 
    self.interface = assert(iface, 'Missing argument #2 (table expected)'); 
    self.maid = TaskLib.new(); 
    self:Construct(); 
    return self; 
end; 

function ESPPlayer:Construct() 
    self.charCache = {}; 
    self.childCount = 0; 
    self.bin = {}; 
    self.drawings = { 
        box3d = { 
            { 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }) 
            }, 
            { 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }) 
            }, 
            { 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }) 
            }, 
            { 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }) 
            } 
        }, 
        visible = { 
            tracerOutline = self:create('Line', { Thickness = 3, Visible = false }), 
            tracer = self:create('Line', { Thickness = 1, Visible = false }), 
            boxFill = self:create('Square', { Filled = true, Visible = false }), 
            boxOutline = self:create('Square', { Thickness = 3, Visible = false }), 
            box = self:create('Square', { Thickness = 1, Visible = false }), 
            healthBarOutline = self:create('Line', { Thickness = 3, Visible = false }), 
            healthBar = self:create('Line', { Thickness = 1, Visible = false }), 
            healthText = self:create('Text', { Center = true, Visible = false }), 
            name = self:create('Text', { Text = self.player.Name, Center = true, Visible = false }), 
            distance = self:create('Text', { Center = true, Visible = false }), 
            weapon = self:create('Text', { Center = true, Visible = false }) 
        }, 
        hidden = { 
            arrowOutline = self:create('Triangle', { Thickness = 3, Visible = false }), 
            arrow = self:create('Triangle', { Filled = true, Visible = false }) 
        } 
    }; 

    self.renderConnection = RunService.Heartbeat:Connect(function(deltaTime) 
        self:Update(deltaTime); 
        self:Render(deltaTime); 
    end); 
    self.maid:AddTask(self.renderConnection); 
end; 

function ESPPlayer:create(class, properties) 
    local drawing = Drawing.new(class); 
    for property, value in next, properties do 
        drawing[property] = value; 
    end; 
    self.bin[#self.bin + 1] = drawing; 
    self.maid:AddTask(drawing); 
    return drawing; 
end; 

function ESPPlayer:Destruct() 
    if self.drawings then 
        for _, drawings in pairs(self.drawings) do 
            if type(drawings) == 'table' then 
                for _, drawing in pairs(drawings) do 
                    if type(drawing) == 'table' then 
                        for _, line in pairs(drawing) do 
                            if line.Visible ~= nil then 
                                line.Visible = false; 
                            end; 
                        end; 
                    elseif drawing.Visible ~= nil then 
                        drawing.Visible = false; 
                    end; 
                end; 
            end; 
        end; 
    end; 

    self.maid:Cleanup(); 
    TableClear(self); 
end; 

function ESPPlayer:Update() 
    local iface = self.interface; 
    self.options = iface.teamSettings[iface.isFriendly(self.player) and 'friendly' or 'enemy']; 
    self.character = iface.getCharacter(self.player); 
    self.health, self.maxHealth = iface.getHealth(self.character); 
    self.weapon = iface.getWeapon(self.player); 
    self.enabled = self.options.enabled and self.character and not (#iface.whitelist > 0 and not TableFind(iface.whitelist, self.player.UserId)); 

    local head = self.enabled and FindFirstChild(self.character, 'Head'); 
    if not head then 
        return; 
    end; 

    local _, onScreen, depth = WorldToScreen(head.Position); 
    self.onScreen = onScreen; 
    self.distance = depth; 

    if iface.sharedSettings.limitDistance and depth > iface.sharedSettings.maxDistance then 
        self.onScreen = false; 
    end; 

    if self.onScreen then 
        local cache = self.charCache; 
        local children = GetChildren(self.character); 
        if not cache[1] or self.childCount ~= #children then 
            TableClear(cache); 
            for i = 1, #children do 
                local part = children[i]; 
                if IsA(part, 'BasePart') and IsBodyPart(part.Name) then 
                    cache[#cache + 1] = part; 
                end; 
            end; 
            self.childCount = #children; 
        end; 
        self.corners = CalculateCorners(GetBoundingBox(cache)); 
    elseif self.options.offScreenArrow then 
        local _, yaw, roll = ToOrientation(Camera.CFrame); 
        local flatCFrame = CFrame.Angles(0, yaw, roll) + Camera.CFrame.Position; 
        local objectSpace = PointToObjectSpace(flatCFrame, head.Position); 
        local angle = ATan2(objectSpace.Z, objectSpace.X); 
        self.direction = Vector2.new(Cos(angle), Sin(angle)); 
    end; 
end; 

function ESPPlayer:Render() 
    local onScreen = self.onScreen or false; 
    local enabled = self.enabled or false; 
    local visible = self.drawings.visible; 
    local hidden = self.drawings.hidden; 
    local box3d = self.drawings.box3d; 
    local iface = self.interface; 
    local options = self.options; 
    local corners = self.corners; 

    visible.box.Visible = enabled and onScreen and options.box; 
    visible.boxOutline.Visible = visible.box.Visible and options.boxOutline; 
    if visible.box.Visible then 
        local box = visible.box; 
        box.Position = corners.topLeft; 
        box.Size = corners.bottomRight - corners.topLeft; 
        box.Color = options.boxColor[1]; 
        box.Transparency = options.boxColor[2]; 

        local boxOutline = visible.boxOutline; 
        boxOutline.Position = box.Position; 
        boxOutline.Size = box.Size; 
        boxOutline.Color = options.boxOutlineColor[1]; 
        boxOutline.Transparency = options.boxOutlineColor[2]; 
    end; 

    visible.boxFill.Visible = enabled and onScreen and options.boxFill; 
    if visible.boxFill.Visible then 
        local boxFill = visible.boxFill; 
        boxFill.Position = corners.topLeft; 
        boxFill.Size = corners.bottomRight - corners.topLeft; 
        boxFill.Color = options.boxFillColor[1]; 
        boxFill.Transparency = options.boxFillColor[2]; 
    end; 

    visible.healthBar.Visible = enabled and onScreen and options.healthBar; 
    visible.healthBarOutline.Visible = visible.healthBar.Visible and options.healthBarOutline; 
    if visible.healthBar.Visible then 
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET; 
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET; 

        local healthBar = visible.healthBar; 
        healthBar.To = barTo; 
        healthBar.From = Lerp2(barTo, barFrom, self.health/self.maxHealth); 
        healthBar.Color = LerpColor(options.dyingColor, options.healthyColor, self.health/self.maxHealth); 

        local healthBarOutline = visible.healthBarOutline; 
        healthBarOutline.To = barTo + HEALTH_BAR_OUTLINE_OFFSET; 
        healthBarOutline.From = barFrom - HEALTH_BAR_OUTLINE_OFFSET; 
        healthBarOutline.Color = options.healthBarOutlineColor[1]; 
        healthBarOutline.Transparency = options.healthBarOutlineColor[2]; 
    end; 

    visible.healthText.Visible = not not (enabled and onScreen and options.healthText and self.health); 
    if visible.healthText.Visible then 
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET; 
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET; 

        local healthText = visible.healthText; 
        healthText.Text = Round(self.health) .. 'hp'; 
        healthText.Size = iface.sharedSettings.textSize; 
        healthText.Font = iface.sharedSettings.textFont; 
        healthText.Color = options.healthTextColor[1]; 
        healthText.Transparency = options.healthTextColor[2]; 
        healthText.Outline = options.healthTextOutline; 
        healthText.OutlineColor = options.healthTextOutlineColor; 

        local healthRatio = 0; 
        if self.health and self.maxHealth and self.maxHealth > 0 then 
            healthRatio = math.max(0, math.min(1, self.health / self.maxHealth)); 
        end; 

        healthText.Position = Lerp2(barTo, barFrom, healthRatio) - healthText.TextBounds*0.5 - HEALTH_TEXT_OFFSET; 
    end; 

    visible.name.Visible = enabled and onScreen and options.name; 
    if visible.name.Visible then 
        local name = visible.name; 
        name.Size = iface.sharedSettings.textSize; 
        name.Font = iface.sharedSettings.textFont; 
        name.Color = options.nameColor[1]; 
        name.Transparency = options.nameColor[2]; 
        name.Outline = options.nameOutline; 
        name.OutlineColor = options.nameOutlineColor; 
        name.Position = (corners.topLeft + corners.topRight)*0.5 - Vector2.yAxis*name.TextBounds.Y - NAME_OFFSET; 
    end; 

    visible.distance.Visible = enabled and onScreen and self.distance and options.distance; 
    if visible.distance.Visible then 
        local distance = visible.distance; 
        distance.Text = Round(self.distance) .. ' studs'; 
        distance.Size = iface.sharedSettings.textSize; 
        distance.Font = iface.sharedSettings.textFont; 
        distance.Color = options.distanceColor[1]; 
        distance.Transparency = options.distanceColor[2]; 
        distance.Outline = options.distanceOutline; 
        distance.OutlineColor = options.distanceOutlineColor; 
        distance.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + DISTANCE_OFFSET; 
    end; 

    visible.weapon.Visible = enabled and onScreen and options.weapon; 
    if visible.weapon.Visible then 
        local weapon = visible.weapon; 
        weapon.Text = self.weapon; 
        weapon.Size = iface.sharedSettings.textSize; 
        weapon.Font = iface.sharedSettings.textFont; 
        weapon.Color = options.weaponColor[1]; 
        weapon.Transparency = options.weaponColor[2]; 
        weapon.Outline = options.weaponOutline; 
        weapon.OutlineColor = options.weaponOutlineColor; 
        weapon.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + (visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis*visible.distance.TextBounds.Y or Vector2.zero); 
    end; 

    visible.tracer.Visible = enabled and onScreen and options.tracer; 
    visible.tracerOutline.Visible = visible.tracer.Visible and options.tracerOutline; 
    if visible.tracer.Visible then 
        local tracer = visible.tracer; 
        tracer.Color = options.tracerColor[1]; 
        tracer.Transparency = options.tracerColor[2]; 
        tracer.To = (corners.bottomLeft + corners.bottomRight)*0.5; 
        tracer.From = options.tracerOrigin == 'Middle' and ViewportSize*0.5 or options.tracerOrigin == 'Top' and ViewportSize*Vector2.new(0.5, 0) or options.tracerOrigin == 'Bottom' and ViewportSize*Vector2.new(0.5, 1); 

        local tracerOutline = visible.tracerOutline; 
        tracerOutline.Color = options.tracerOutlineColor[1]; 
        tracerOutline.Transparency = options.tracerOutlineColor[2]; 
        tracerOutline.To = tracer.To; 
        tracerOutline.From = tracer.From; 
    end; 

    hidden.arrow.Visible = enabled and (not onScreen) and options.offScreenArrow; 
    hidden.arrowOutline.Visible = hidden.arrow.Visible and options.offScreenArrowOutline; 
    if hidden.arrow.Visible then 
        local arrow = hidden.arrow; 
        arrow.PointA = Min2(Max2(ViewportSize*0.5 + self.direction*options.offScreenArrowRadius, Vector2.one*25), ViewportSize - Vector2.one*25); 
        arrow.PointB = arrow.PointA - RotateVector(self.direction, 0.45)*options.offScreenArrowSize; 
        arrow.PointC = arrow.PointA - RotateVector(self.direction, -0.45)*options.offScreenArrowSize; 
        arrow.Color = options.offScreenArrowColor[1]; 
        arrow.Transparency = options.offScreenArrowColor[2]; 

        local arrowOutline = hidden.arrowOutline; 
        arrowOutline.PointA = arrow.PointA; 
        arrowOutline.PointB = arrow.PointB; 
        arrowOutline.PointC = arrow.PointC; 
        arrowOutline.Color = options.offScreenArrowOutlineColor[1]; 
        arrowOutline.Transparency = options.offScreenArrowOutlineColor[2]; 
    end; 

    local box3dEnabled = enabled and onScreen and options.box3d; 
    for i = 1, #box3d do 
        local face = box3d[i]; 
        for i2 = 1, #face do 
            local line = face[i2]; 
            line.Visible = box3dEnabled; 
            line.Color = options.box3dColor[1]; 
            line.Transparency = options.box3dColor[2]; 
        end; 

        if box3dEnabled then 
            local line1 = face[1]; 
            line1.From = corners.corners[i]; 
            line1.To = corners.corners[i == 4 and 1 or i+1]; 

            local line2 = face[2]; 
            line2.From = corners.corners[i == 4 and 1 or i+1]; 
            line2.To = corners.corners[i == 4 and 5 or i+5]; 

            local line3 = face[3]; 
            line3.From = corners.corners[i == 4 and 5 or i+5]; 
            line3.To = corners.corners[i == 4 and 8 or i+4]; 
        end; 
    end; 
end; 

local ChamPlayer = {}; 
ChamPlayer.__index = ChamPlayer; 

function ChamPlayer.new(player, iface) 
    local self = setmetatable({}, ChamPlayer); 
    self.player = assert(player, 'Missing argument #1 (Player expected)'); 
    self.interface = assert(iface, 'Missing argument #2 (table expected)'); 
    self.maid = TaskLib.new(); 
    self:Construct(); 
    return self; 
end; 

function ChamPlayer:Construct() 
    self.highlight = Instance.new('Highlight', GuiContainer); 
    self.maid:AddTask(self.highlight); 

    self.updateConnection = RunService.Heartbeat:Connect(function() 
        self:Update(); 
    end); 
    self.maid:AddTask(self.updateConnection); 
end; 

function ChamPlayer:Destruct() 
    self.maid:Cleanup(); 
    TableClear(self); 
end; 

function ChamPlayer:Update() 
    local iface = self.interface; 
    local character = iface.getCharacter(self.player); 
    local options = iface.teamSettings[iface.isFriendly(self.player) and 'friendly' or 'enemy']; 
    local enabled = options.enabled and character and not (#iface.whitelist > 0 and not TableFind(iface.whitelist, self.player.UserId)); 

    if enabled and options.chams then 
        if not self.highlight or not self.highlight.Parent or not pcall(function() return self.highlight.Enabled end) then 
            if self.highlight then 
                pcall(function() self.highlight:Destroy() end); 
                self.highlight = nil; 
            end; 

            local success, newHighlight = pcall(function() 
                local highlight = Instance.new('Highlight'); 
                highlight.Parent = GuiContainer; 
                return highlight; 
            end); 

            if success and newHighlight then 
                self.highlight = newHighlight; 
                self.maid:AddTask(self.highlight); 
            else 
                return; 
            end; 
        end; 

        if self.highlight and pcall(function() return self.highlight.Parent end) then 
            pcall(function() 
                self.highlight.Enabled = true; 
                self.highlight.DepthMode = options.chamsVisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop; 
                self.highlight.Adornee = character; 
                self.highlight.FillColor = options.chamsFillColor[1]; 
                self.highlight.FillTransparency = options.chamsFillColor[2]; 
                self.highlight.OutlineColor = options.chamsOutlineColor[1]; 
                self.highlight.OutlineTransparency = options.chamsOutlineColor[2]; 
            end); 
        end; 
    else 
        if self.highlight and pcall(function() return self.highlight.Parent end) then 
            pcall(function() 
                self.highlight.Enabled = false; 
            end); 
        end; 
    end; 
end; 

local InstanceESP = {}; 
InstanceESP.__index = InstanceESP; 

function InstanceESP.new(instance, iface, customOptions) 
    local self = setmetatable({}, InstanceESP); 
    self.instance = assert(instance, 'Missing argument #1 (Instance expected)'); 
    self.interface = assert(iface, 'Missing argument #2 (table expected)'); 
    self.customOptions = customOptions or {}; 
    self.maid = TaskLib.new(); 
    self:Construct(); 
    return self; 
end; 

function InstanceESP:Construct() 
    self.charCache = {}; 
    self.childCount = 0; 
    self.bin = {}; 
    if not self.customOptions then self.customOptions = {}; end; 

    self.drawings = { 
        box3d = {}, 
        visible = { 
            tracerOutline = self:create('Line', { Thickness = 3, Visible = false }), 
            tracer = self:create('Line', { Thickness = 1, Visible = false }), 
            boxFill = self:create('Square', { Filled = true, Visible = false }), 
            boxOutline = self:create('Square', { Thickness = 3, Visible = false }), 
            box = self:create('Square', { Thickness = 1, Visible = false }), 
            healthBarOutline = self:create('Line', { Thickness = 3, Visible = false }), 
            healthBar = self:create('Line', { Thickness = 1, Visible = false }), 
            healthText = self:create('Text', { Center = true, Visible = false }), 
            name = self:create('Text', { Text = self.instance.Name, Center = true, Visible = false }), 
            distance = self:create('Text', { Center = true, Visible = false }), 
            weapon = self:create('Text', { Center = true, Visible = false }), 
            customText = self:create('Text', { Center = true, Visible = false }) 
        }, 
        hidden = { 
            arrowOutline = self:create('Triangle', { Thickness = 3, Visible = false }), 
            arrow = self:create('Triangle', { Filled = true, Visible = false }) 
        } 
    }; 

    local options = self.customOptions; 
    if type(options) == 'function' then options = options(); end; 
    if options and options.box3d then 
        for i = 1, 4 do 
            self.drawings.box3d[i] = { 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }), 
                self:create('Line', { Thickness = 1, Visible = false }) 
            }; 
        end; 
    end; 

    self.renderConnection = RunService.Heartbeat:Connect(function(deltaTime) 
        self:Update(deltaTime); 
        self:Render(deltaTime); 
    end); 
    self.maid:AddTask(self.renderConnection); 
end; 

function InstanceESP:create(class, properties) 
    local drawing = Drawing.new(class); 
    for property, value in next, properties do drawing[property] = value; end; 
    self.bin[#self.bin + 1] = drawing; 
    self.maid:AddTask(drawing); 
    return drawing; 
end; 

function InstanceESP:Destruct() 
    if self.drawings then 
        for _, drawings in pairs(self.drawings) do 
            if type(drawings) == 'table' then 
                for _, drawing in pairs(drawings) do 
                    if type(drawing) == 'table' then 
                        for _, line in pairs(drawing) do 
                            if line and line.Visible ~= nil then line.Visible = false; end; 
                        end; 
                    elseif drawing and drawing.Visible ~= nil then 
                        drawing.Visible = false; 
                    end; 
                end; 
            end; 
        end; 
    end; 

    if self.interface and self.interface._instanceCache then 
        local cache = self.interface._instanceCache; 
        if cache[self.instance] then cache[self.instance] = nil; end; 
    end; 

    if self.maid then self.maid:Cleanup(); end; 
    TableClear(self); 
end; 

function InstanceESP:Update() 
    if not self.instance or not self.instance.Parent then return self:Destruct(); end; 
    local iface = self.interface; 
    self.options = iface.instanceSettings or iface.teamSettings.enemy; 

    if self.customOptions then 
        if type(self.customOptions) == 'function' then 
            local freshOptions = self.customOptions(); 
            for key, value in pairs(freshOptions) do self.options[key] = value; end; 
        else 
            for key, value in pairs(self.customOptions) do self.options[key] = value; end; 
        end; 
    end; 

    self.enabled = self.options.enabled; 

    local primaryPart = self.instance:FindFirstChild('HumanoidRootPart') or self.instance:FindFirstChild('Primary') or self.instance:FindFirstChildOfClass('BasePart'); 
    if not primaryPart then return; end; 

    local _, onScreen, depth = WorldToScreen(primaryPart.Position); 
    self.onScreen = onScreen; 
    self.distance = depth; 

    if iface.sharedSettings.limitDistance and depth > iface.sharedSettings.maxDistance then 
        self.onScreen = false; 
    end; 

    if self.onScreen then 
        local cache = self.charCache; 
        local children = GetChildren(self.instance); 
        if not cache[1] or self.childCount ~= #children then 
            TableClear(cache); 
            for i = 1, #children do 
                local part = children[i]; 
                if IsA(part, 'BasePart') then cache[#cache + 1] = part; end; 
            end; 
            self.childCount = #children; 
        end; 
        self.corners = CalculateCorners(GetBoundingBox(cache)); 
    elseif self.options.offScreenArrow then 
        local _, yaw, roll = ToOrientation(Camera.CFrame); 
        local flatCFrame = CFrame.Angles(0, yaw, roll) + Camera.CFrame.Position; 
        local objectSpace = PointToObjectSpace(flatCFrame, primaryPart.Position); 
        local angle = ATan2(objectSpace.Z, objectSpace.X); 
        self.direction = Vector2.new(Cos(angle), Sin(angle)); 
    end; 

    if self.interface.getHealth then 
        self.health, self.maxHealth = self.interface.getHealth(self.instance); 
    else 
        local humanoid = self.instance:FindFirstChildOfClass('Humanoid'); 
        if humanoid then 
            self.health = humanoid.Health; 
            self.maxHealth = humanoid.MaxHealth; 
        else 
            self.health = 100; 
            self.maxHealth = 100; 
        end; 
    end; 
end; 

function InstanceESP:Render() 
    local onScreen = self.onScreen or false; 
    local enabled = self.enabled or false; 
    local visible = self.drawings and self.drawings.visible or {}; 
    local hidden = self.drawings and self.drawings.hidden or {}; 
    local box3d = self.drawings and self.drawings.box3d or {}; 
    local iface = self.interface; 
    local options = self.options; 
    local corners = self.corners; 

    if not self.drawings or not self.drawings.visible then return; end; 
    if not corners then 
        for _, drawing in pairs(visible) do drawing.Visible = false; end; 
        for _, drawing in pairs(hidden) do drawing.Visible = false; end; 
        for _, face in pairs(box3d) do for _, line in pairs(face) do line.Visible = false; end; end; 
        return; 
    end; 

    visible.box.Visible = enabled and onScreen and options.box; 
    visible.boxOutline.Visible = visible.box.Visible and options.boxOutline; 
    if visible.box.Visible then 
        local box = visible.box; 
        box.Position = corners.topLeft; 
        box.Size = corners.bottomRight - corners.topLeft; 
        box.Color = options.boxColor[1]; 
        box.Transparency = options.boxColor[2]; 

        local boxOutline = visible.boxOutline; 
        boxOutline.Position = box.Position; 
        boxOutline.Size = box.Size; 
        boxOutline.Color = options.boxOutlineColor[1]; 
        boxOutline.Transparency = options.boxOutlineColor[2]; 
    end; 

    visible.boxFill.Visible = enabled and onScreen and options.boxFill; 
    if visible.boxFill.Visible then 
        local boxFill = visible.boxFill; 
        boxFill.Position = corners.topLeft; 
        boxFill.Size = corners.bottomRight - corners.topLeft; 
        boxFill.Color = options.boxFillColor[1]; 
        boxFill.Transparency = options.boxFillColor[2]; 
    end; 

    visible.healthBar.Visible = enabled and onScreen and options.healthBar and self.health ~= nil; 
    visible.healthBarOutline.Visible = visible.healthBar.Visible and options.healthBarOutline; 
    if visible.healthBar.Visible then 
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET; 
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET; 

        local healthRatio = 0; 
        if self.health and self.maxHealth and self.maxHealth > 0 then 
            healthRatio = math.max(0, math.min(1, self.health / self.maxHealth)); 
        end; 

        local healthBar = visible.healthBar; 
        healthBar.To = Vector2.new(barTo.X, barTo.Y); 
        healthBar.From = Lerp2(barTo, barFrom, healthRatio); 
        healthBar.Color = LerpColor(options.dyingColor, options.healthyColor, healthRatio); 

        if visible.healthBarOutline.Visible then 
            local healthBarOutline = visible.healthBarOutline; 
            local outlineFrom = barFrom - HEALTH_BAR_OUTLINE_OFFSET; 
            local outlineTo = barTo + HEALTH_BAR_OUTLINE_OFFSET; 
            healthBarOutline.To = outlineTo; 
            healthBarOutline.From = outlineFrom; 
            healthBarOutline.Color = options.healthBarOutlineColor[1]; 
            healthBarOutline.Transparency = options.healthBarOutlineColor[2]; 
        end; 
    end; 

    visible.healthText.Visible = not not (enabled and onScreen and options.healthText and self.health); 
    if visible.healthText.Visible then 
        local barFrom = corners.topLeft - HEALTH_BAR_OFFSET; 
        local barTo = corners.bottomLeft - HEALTH_BAR_OFFSET; 

        local healthText = visible.healthText; 
        healthText.Text = Round(self.health) .. 'hp'; 
        healthText.Size = iface.sharedSettings.textSize; 
        healthText.Font = iface.sharedSettings.textFont; 
        healthText.Color = options.healthTextColor[1]; 
        healthText.Transparency = options.healthTextColor[2]; 
        healthText.Outline = options.healthTextOutline; 
        healthText.OutlineColor = options.healthTextOutlineColor; 
        healthText.Position = Lerp2(barTo, barFrom, self.health/self.maxHealth) - healthText.TextBounds*0.5 - HEALTH_TEXT_OFFSET; 
    end; 

    visible.name.Visible = enabled and onScreen and options.name; 
    if visible.name.Visible then 
        local name = visible.name; 
        name.Size = iface.sharedSettings.textSize; 
        name.Font = iface.sharedSettings.textFont; 
        name.Color = options.nameColor[1]; 
        name.Transparency = options.nameColor[2]; 
        name.Outline = options.nameOutline; 
        name.OutlineColor = options.nameOutlineColor; 
        name.Position = (corners.topLeft + corners.topRight)*0.5 - Vector2.yAxis*name.TextBounds.Y - NAME_OFFSET; 
    end; 

    visible.distance.Visible = enabled and onScreen and self.distance and options.distance; 
    if visible.distance.Visible then 
        local distance = visible.distance; 
        distance.Text = Round(self.distance) .. ' studs'; 
        distance.Size = iface.sharedSettings.textSize; 
        distance.Font = iface.sharedSettings.textFont; 
        distance.Color = options.distanceColor[1]; 
        distance.Transparency = options.distanceColor[2]; 
        distance.Outline = options.distanceOutline; 
        distance.OutlineColor = options.distanceOutlineColor; 
        distance.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + DISTANCE_OFFSET; 
    end; 

    visible.customText.Visible = enabled and onScreen and options.customText; 
    if visible.customText.Visible then 
        local customText = visible.customText; 
        customText.Text = options.customTextValue or ''; 
        customText.Size = iface.sharedSettings.textSize; 
        customText.Font = iface.sharedSettings.textFont; 
        customText.Color = options.customTextColor[1]; 
        customText.Transparency = options.customTextColor[2]; 
        customText.Outline = options.customTextOutline; 
        customText.OutlineColor = options.customTextOutlineColor; 
        customText.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + (visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis*visible.distance.TextBounds.Y or Vector2.zero); 
    end; 

    visible.tracer.Visible = enabled and onScreen and options.tracer; 
    visible.tracerOutline.Visible = visible.tracer.Visible and options.tracerOutline; 
    if visible.tracer.Visible then 
        local tracer = visible.tracer; 
        tracer.Color = options.tracerColor[1]; 
        tracer.Transparency = options.tracerColor[2]; 
        tracer.To = (corners.bottomLeft + corners.bottomRight)*0.5; 
        tracer.From = options.tracerOrigin == 'Middle' and ViewportSize*0.5 or options.tracerOrigin == 'Top' and ViewportSize*Vector2.new(0.5, 0) or options.tracerOrigin == 'Bottom' and ViewportSize*Vector2.new(0.5, 1); 

        local tracerOutline = visible.tracerOutline; 
        tracerOutline.Color = options.tracerOutlineColor[1]; 
        tracerOutline.Transparency = options.tracerOutlineColor[2]; 
        tracerOutline.To = tracer.To; 
        tracerOutline.From = tracer.From; 
    end; 

    if visible.weapon.Visible then 
        pcall(function() 
            visible.weapon.Text = self.interface.getWeapon(self.instance) or 'Unknown'; 
            local weapon = visible.weapon; 
            weapon.Text = options.weaponText or 'Unknown'; 
            weapon.Size = iface.sharedSettings.textSize; 
            weapon.Font = iface.sharedSettings.textFont; 
            weapon.Color = options.weaponColor[1]; 
            weapon.Transparency = options.weaponColor[2]; 
            weapon.Outline = options.weaponOutline; 
            weapon.OutlineColor = options.weaponOutlineColor; 
            weapon.Position = (corners.bottomLeft + corners.bottomRight)*0.5 + (visible.distance.Visible and DISTANCE_OFFSET + Vector2.yAxis*visible.distance.TextBounds.Y or Vector2.zero); 
        end); 
    end; 

    hidden.arrow.Visible = enabled and (not onScreen) and options.offScreenArrow; 
    hidden.arrowOutline.Visible = hidden.arrow.Visible and options.offScreenArrowOutline; 
    if hidden.arrow.Visible then 
        local arrow = hidden.arrow; 
        arrow.PointA = Min2(Max2(ViewportSize*0.5 + self.direction*options.offScreenArrowRadius, Vector2.one*25), ViewportSize - Vector2.one*25); 
        arrow.PointB = arrow.PointA - RotateVector(self.direction, 0.45)*options.offScreenArrowSize; 
        arrow.PointC = arrow.PointA - RotateVector(self.direction, -0.45)*options.offScreenArrowSize; 
        arrow.Color = options.offScreenArrowColor[1]; 
        arrow.Transparency = options.offScreenArrowColor[2]; 

        local arrowOutline = hidden.arrowOutline; 
        arrowOutline.PointA = arrow.PointA; 
        arrowOutline.PointB = arrow.PointB; 
        arrowOutline.PointC = arrow.PointC; 
        arrowOutline.Color = options.offScreenArrowOutlineColor[1]; 
        arrowOutline.Transparency = options.offScreenArrowOutlineColor[2]; 
    end; 

    local box3dEnabled = enabled and onScreen and options.box3d; 
    for i = 1, #box3d do 
        local face = box3d[i]; 
        for i2 = 1, #face do 
            local line = face[i2]; 
            line.Visible = box3dEnabled; 
            if box3dEnabled then 
                line.Color = options.box3dColor[1]; 
                line.Transparency = options.box3dColor[2]; 
            end; 
        end; 

        if box3dEnabled then 
            local line1 = face[1]; 
            line1.From = corners.corners[i]; 
            line1.To = corners.corners[i == 4 and 1 or i+1]; 

            local line2 = face[2]; 
            line2.From = corners.corners[i == 4 and 1 or i+1]; 
            line2.To = corners.corners[i == 4 and 5 or i+5]; 

            local line3 = face[3]; 
            line3.From = corners.corners[i == 4 and 5 or i+5]; 
            line3.To = corners.corners[i == 4 and 8 or i+4]; 
        end; 
    end; 
end; 

function InstanceESP:UpdateSettings(newSettings) 
    if not self.customOptions then self.customOptions = {}; end; 
    for key, value in pairs(newSettings) do self.customOptions[key] = value; end; 
end; 

local InstanceCham = {}; 
InstanceCham.__index = InstanceCham; 

function InstanceCham.new(instance, iface, customOptions) 
    local self = setmetatable({}, InstanceCham); 
    self.instance = instance; 
    self.interface = iface; 
    self.customOptions = customOptions or {}; 
    self.maid = TaskLib.new(); 
    self:Construct(); 
    return self; 
end; 

function InstanceCham:Construct() 
    self.highlight = Instance.new('Highlight'); 
    self.highlight.Parent = Workspace; 
    self.maid:AddTask(self.highlight); 

    self.updateConnection = RunService.Heartbeat:Connect(function() self:Update(); end); 
    self.maid:AddTask(self.updateConnection); 
end; 

function InstanceCham:Destruct() 
    if self.highlight then self.highlight:Destroy(); self.highlight = nil; end; 
    if self.maid then self.maid:Cleanup(); end; 
end; 

function InstanceCham:Update() 
    if not self.instance or not self.instance.Parent then return self:Destruct(); end; 

    local options = self.customOptions; 
    if type(options) == 'function' then options = options(); end; 
    local enabled = options.enabled and options.chams; 

    if self.highlight then 
        self.highlight.Enabled = enabled; 
        if enabled then 
            self.highlight.Adornee = self.instance; 
            self.highlight.DepthMode = options.chamsVisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop; 
            self.highlight.FillColor = options.chamsFillColor[1]; 
            self.highlight.FillTransparency = options.chamsFillColor[2]; 
            self.highlight.OutlineColor = options.chamsOutlineColor[1]; 
            self.highlight.OutlineTransparency = options.chamsOutlineColor[2]; 
        end; 
    end; 
end; 

local InstanceLabel = {}; 
InstanceLabel.__index = InstanceLabel; 

function InstanceLabel.new(instance, options) 
    local self = setmetatable({}, InstanceLabel); 
    self.instance = instance; 
    self.options = options; 
    self.maid = TaskLib.new(); 

    self.text = Drawing.new('Text'); 
    self.text.Center = true; 
    self.maid:AddTask(self.text); 

    self.renderConnection = RunService.Heartbeat:Connect(function() self:Render(); end); 
    self.maid:AddTask(self.renderConnection); 

    self.removedConnection = instance.AncestryChanged:Connect(function() if not instance.Parent then self:Destruct(); end; end); 
    self.maid:AddTask(self.removedConnection); 

    self:ApplyDefaults(); 
    return self; 
end; 

function InstanceLabel:ApplyDefaults() 
    local o = self.options; 
    o.enabled = o.enabled ~= false; 
    o.text = o.text or '{name}'; 
    o.textColor = o.textColor or { Color3.new(1,1,1), 1 }; 
    o.textOutline = o.textOutline ~= false; 
    o.textOutlineColor = o.textOutlineColor or Color3.new(); 
    o.textSize = o.textSize or 13; 
    o.textFont = o.textFont or 2; 
    o.limitDistance = o.limitDistance == true; 
    o.maxDistance = o.maxDistance or 150; 
end; 

function InstanceLabel:UpdateSettings(new) 
    for k,v in pairs(new) do self.options[k] = v; end; 
    self:ApplyDefaults(); 
end; 

function InstanceLabel:Destruct() 
    if self.text then self.text.Visible = false; end; 
    if self.maid then self.maid:Cleanup(); end; 
    TableClear(self); 
end; 

function InstanceLabel:Render() 
    if not self.instance or not self.instance.Parent then return self:Destruct(); end; 
    local o = self.options; 
    if not o.enabled then self.text.Visible = false; return; end; 

    local pos = GetPivot(self.instance).Position; 
    local screen, visible, depth = WorldToScreen(pos); 
    if o.limitDistance and depth > o.maxDistance then visible = false; end; 

    local text = self.text; 
    text.Visible = visible; 
    if visible then 
        text.Position = screen; 
        text.Color = o.textColor[1]; 
        text.Transparency = o.textColor[2]; 
        text.Outline = o.textOutline; 
        text.OutlineColor = o.textOutlineColor; 
        text.Size = o.textSize; 
        text.Font = o.textFont; 
        text.Text = o.text:gsub('{name}', self.instance.Name):gsub('{distance}', Round(depth)):gsub('{position}', tostring(pos)); 
    end; 
end; 

local ESPInterface = { 
    _hasLoaded = false, 
    _objectCache = {}, 
    _instanceCache = {}, 
    whitelist = {}, 
    maid = TaskLib.new(), 
    sharedSettings = { textSize = 13, textFont = 2, limitDistance = false, maxDistance = 150 }, 
    teamSettings = { 
        enemy = { 
            enabled = false, box = false, boxColor = { Color3.new(1,0,0), 1 }, boxOutline = true, boxOutlineColor = { Color3.new(), 1 }, boxFill = false, boxFillColor = { Color3.new(1,0,0), 0.5 }, healthBar = false, healthyColor = Color3.new(0,1,0), dyingColor = Color3.new(1,0,0), healthBarOutline = true, healthBarOutlineColor = { Color3.new(), 0.5 }, healthText = false, healthTextColor = { Color3.new(1,1,1), 1 }, healthTextOutline = true, healthTextOutlineColor = Color3.new(), box3d = false, box3dColor = { Color3.new(1,0,0), 1 }, name = false, nameColor = { Color3.new(1,1,1), 1 }, nameOutline = true, nameOutlineColor = Color3.new(), weapon = false, weaponColor = { Color3.new(1,1,1), 1 }, weaponOutline = true, weaponOutlineColor = Color3.new(), distance = false, distanceColor = { Color3.new(1,1,1), 1 }, distanceOutline = true, distanceOutlineColor = Color3.new(), tracer = false, tracerOrigin = 'Bottom', tracerColor = { Color3.new(1,0,0), 1 }, tracerOutline = true, tracerOutlineColor = { Color3.new(), 1 }, offScreenArrow = false, offScreenArrowColor = { Color3.new(1,1,1), 1 }, offScreenArrowSize = 15, offScreenArrowRadius = 150, offScreenArrowOutline = true, offScreenArrowOutlineColor = { Color3.new(), 1 }, chams = false, chamsVisibleOnly = false, chamsFillColor = { Color3.new(0.2,0.2,0.2), 0.5 }, chamsOutlineColor = { Color3.new(1,0,0), 0 } 
        }, 
        friendly = { 
            enabled = false, box = false, boxColor = { Color3.new(0,1,0), 1 }, boxOutline = true, boxOutlineColor = { Color3.new(), 1 }, boxFill = false, boxFillColor = { Color3.new(0,1,0), 0.5 }, healthBar = false, healthyColor = Color3.new(0,1,0), dyingColor = Color3.new(1,0,0), healthBarOutline = true, healthBarOutlineColor = { Color3.new(), 0.5 }, healthText = false, healthTextColor = { Color3.new(1,1,1), 1 }, healthTextOutline = true, healthTextOutlineColor = Color3.new(), box3d = false, box3dColor = { Color3.new(0,1,0), 1 }, name = false, nameColor = { Color3.new(1,1,1), 1 }, nameOutline = true, nameOutlineColor = Color3.new(), weapon = false, weaponColor = { Color3.new(1,1,1), 1 }, weaponOutline = true, weaponOutlineColor = Color3.new(), distance = false, distanceColor = { Color3.new(1,1,1), 1 }, distanceOutline = true, distanceOutlineColor = Color3.new(), tracer = false, tracerOrigin = 'Bottom', tracerColor = { Color3.new(0,1,0), 1 }, tracerOutline = true, tracerOutlineColor = { Color3.new(), 1 }, offScreenArrow = false, offScreenArrowColor = { Color3.new(1,1,1), 1 }, offScreenArrowSize = 15, offScreenArrowRadius = 150, offScreenArrowOutline = true, offScreenArrowOutlineColor = { Color3.new(), 1 }, chams = false, chamsVisibleOnly = false, chamsFillColor = { Color3.new(0.2,0.2,0.2), 0.5 }, chamsOutlineColor = { Color3.new(0,1,0), 0 } 
        } 
    }, 
    instanceSettings = { 
        enabled = false, box = false, boxColor = { Color3.new(1,1,0), 1 }, boxOutline = true, boxOutlineColor = { Color3.new(), 1 }, boxFill = false, boxFillColor = { Color3.new(1,1,0), 0.5 }, healthBar = false, healthyColor = Color3.new(0,1,0), dyingColor = Color3.new(1,0,0), healthBarOutline = true, healthBarOutlineColor = { Color3.new(), 0.5 }, healthText = false, healthTextColor = { Color3.new(1,1,1), 1 }, healthTextOutline = true, healthTextOutlineColor = Color3.new(), box3d = false, box3dColor = { Color3.new(1,1,0), 1 }, name = false, nameColor = { Color3.new(1,1,1), 1 }, nameOutline = true, nameOutlineColor = Color3.new(), customText = false, customTextValue = '', customTextColor = { Color3.new(1,1,1), 1 }, customTextOutline = true, customTextOutlineColor = Color3.new(), distance = false, distanceColor = { Color3.new(1,1,1), 1 }, distanceOutline = true, distanceOutlineColor = Color3.new(), tracer = false, tracerOrigin = 'Bottom', tracerColor = { Color3.new(1,1,0), 1 }, tracerOutline = true, tracerOutlineColor = { Color3.new(), 1 }, offScreenArrow = false, offScreenArrowColor = { Color3.new(1,1,1), 1 }, offScreenArrowSize = 15, offScreenArrowRadius = 150, offScreenArrowOutline = true, offScreenArrowOutlineColor = { Color3.new(), 1 }, chams = false, chamsVisibleOnly = false, chamsFillColor = { Color3.new(0.2,0.2,0.2), 0.5 }, chamsOutlineColor = { Color3.new(1,1,0), 0 } 
    } 
}; 

function ESPInterface.AddInstanceEsp(instance, customOptions) 
    if not instance or not instance.Parent then warn('Cannot add ESP to invalid instance'); return nil; end; 
    local cache = ESPInterface._instanceCache; 
    if cache[instance] then return cache[instance]; end; 
    cache[instance] = InstanceESP.new(instance, ESPInterface, customOptions); 
    return cache[instance]; 
end; 

function ESPInterface.AddInstance(instance, options) 
    if not instance or not instance.Parent then warn('Cannot add ESP to invalid instance'); return nil; end; 
    local cache = ESPInterface._instanceCache; 
    if cache[instance] then return cache[instance]; end; 
    cache[instance] = InstanceLabel.new(instance, options); 
    return cache[instance]; 
end; 

function ESPInterface.RemoveInstance(instance) 
    local cache = ESPInterface._instanceCache; 
    local object = cache[instance]; 
    if object then object:Destruct(); cache[instance] = nil; return true; end; 
    return false; 
end; 

function ESPInterface.Load() 
    assert(not ESPInterface._hasLoaded, 'Esp has already been loaded.'); 

    local function createObject(player) 
        ESPInterface._objectCache[player] = { ESPPlayer.new(player, ESPInterface), ChamPlayer.new(player, ESPInterface) }; 
    end; 

    local function removeObject(player) 
        local object = ESPInterface._objectCache[player]; 
        if object then for i = 1, #object do object[i]:Destruct(); end; ESPInterface._objectCache[player] = nil; end; 
    end; 

    for _, player in next, Players:GetPlayers() do 
        if player ~= LocalPlayer then createObject(player); end; 
    end; 

    ESPInterface.playerAdded = Players.PlayerAdded:Connect(createObject); 
    ESPInterface.playerRemoving = Players.PlayerRemoving:Connect(removeObject); 
    ESPInterface.maid:AddTask(ESPInterface.playerAdded); 
    ESPInterface.maid:AddTask(ESPInterface.playerRemoving); 
    ESPInterface._hasLoaded = true; 
end; 

function ESPInterface.Unload() 
    assert(ESPInterface._hasLoaded, 'Esp has not been loaded yet.'); 

    for player, object in next, ESPInterface._objectCache do 
        if object then for i = 1, #object do object[i]:Destruct(); end; end; 
    end; 
    TableClear(ESPInterface._objectCache); 

    for instance, object in next, ESPInterface._instanceCache do 
        if object then object:Destruct(); end; 
    end; 
    TableClear(ESPInterface._instanceCache); 

    ESPInterface.maid:Cleanup(); 
    ESPInterface._hasLoaded = false; 
end; 

function ESPInterface.getWeapon(player) 
    local character = player.Character; 
    if not character then return 'None'; end; 
    local tool = character:FindFirstChildOfClass('Tool'); 
    if tool then return tool.Name; end; 
    return 'Unarmed'; 
end; 

function ESPInterface.isFriendly(player) 
    return player.Team and player.Team == LocalPlayer.Team; 
end; 

function ESPInterface.getCharacter(player) 
    return player.Character; 
end; 

function ESPInterface.getHealth(character) 
    local humanoid = character and FindFirstChildOfClass(character, 'Humanoid'); 
    if humanoid then return humanoid.Health, humanoid.MaxHealth; end; 
    return 100, 100; 
end; 

ESPInterface.InstanceChamObject = InstanceCham; 

return ESPInterface; 
