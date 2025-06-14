
LocksmithIconButton = class(Turbine.UI.Lotro.Window)
function LocksmithIconButton:Constructor()

    local x = LocksmithCharacterSettings["settings"]["button"]["position_x"]
    local y = LocksmithCharacterSettings["settings"]["button"]["position_y"]
    local showButton = LocksmithCharacterSettings["settings"]["showButton"]

    self.inactiveTransparency = 0.6
    self.activeTransparency = 1.0

    Turbine.UI.Window.Constructor(self)
    self:SetPosition(x, y)
    self:SetSize(42,42)
    self:SetOpacity(self.inactiveTransparency)
    self:SetVisible(showButton)
    self:SetWantsKeyEvents(true)
    self:SetZOrder(1)
    
    self.KeyDown = function(sender, args)
        if args.Action == 0x100000B3 and showButton then
            if self:IsVisible() then
                self:SetVisible(false)
            else
                self:SetVisible(true)
            end
        end
    end

    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetSize(42, 42)
    self.background:SetPosition(0, 0)
    self.background:SetMouseVisible(false)
    self.background:SetBackground("Locksmith/Images/Locksmith.tga")
    
    -- Window moving --
    self.Moving = false

    self.MouseDown = function(sender,args)
        self.MoveX = args.X
        self.MoveY = args.Y
        self.Moving = true
    end

    self.MouseUp = function()
        self.Moving = false
        position_x, position_y = self:GetPosition()
        if LocksmithCharacterSettings["settings"]["button"]["position_x"] == position_x and LocksmithCharacterSettings["settings"]["button"]["position_y"] == position_y then
            if LocksmithInfoWindow:IsVisible() then
                LocksmithInfoWindow:HideWindow()
            else
                LocksmithInfoWindow:ShowWindow()
            end
        else
            LocksmithCharacterSettings["settings"]["button"]["position_x"] = position_x
            LocksmithCharacterSettings["settings"]["button"]["position_y"] = position_y
            Turbine.PluginData.Save(Turbine.DataScope.Character, "LocksmithCharacterSettings", LocksmithCharacterSettings)
        end
    end

    self.MouseMove = function(sender,args)
        if self.Moving then
            local newLeft = self:GetLeft() - (self.MoveX - args.X)
            local newTop = self:GetTop() - (self.MoveY - args.Y)
            self:SetPosition(newLeft,newTop)
        end
    end


    -- TODO: Wierd code that can't be removed
    self.random = Turbine.UI.Label()
    self.random:SetParent(self)
    self.random:SetSize(0, 0)
    self.random.MouseMove = function()
        if self.Moving then 
        end
    end
    
end

function LocksmithIconButton:MouseEnter()
    self.mouseInside = true;
    self:SetOpacity(self.activeTransparency);
end

function LocksmithIconButton:MouseLeave()
    self.mouseInside = false;
    self:SetOpacity(self.inactiveTransparency);
end
