
LocksmithInfoWindow = class(Turbine.UI.Lotro.Window())
function LocksmithInfoWindow:Constructor()
    -- Calculate weekly reset --
    local datetime = Turbine.Engine:GetDate()
    local hour = datetime.Hour
    local minute = datetime.Minute
    local dayOfWeek = datetime.DayOfWeek
    local dayOfYear = datetime.DayOfYear

    local minutesToReset = 60 - minute

    if hour >= 10 then
        hoursToReset = 24 - hour + 10 - 1
        daysToReset = LocksmithLocksData["reset"]["weekly"] - dayOfYear - 1
    else
        hoursToReset = 10 - hour - 1
        daysToReset = LocksmithLocksData["reset"]["weekly"] - dayOfYear
    end

    local width = 250
    local height = 450
    local x = LocksmithCharacterSettings["settings"]["window"]["position_x"]
    local y = LocksmithCharacterSettings["settings"]["window"]["position_y"]
    local font = Turbine.UI.Lotro.Font.BookAntiquaBold22
    local colour = Turbine.UI.Color(1, 1, 1)
    Turbine.UI.Window.Constructor(self)
    self:SetSize(width,height)
    self:SetPosition(x,y)
    self:SetVisible(false)
    self:SetMouseVisible(true)
    self:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))
    
    self.background = Turbine.UI.Control()
    self.background:SetParent(self)
    self.background:SetSize(width, height)
    self.background:SetPosition(0, 0)
    self.background:SetMouseVisible(false)
    self.background:SetBackColor(Turbine.UI.Color(0.250, 0.250, 0.250))

    self.title = Turbine.UI.Label()
    self.title:SetParent(self)
    self.title:SetSize(width, 30)
    self.title:SetPosition(0, 0)
    self.title:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))
    self.title:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.title:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold22)
    self.title:SetText("Locksmith v " .. VersionNo)

    self.resetLable = Turbine.UI.Label()
    self.resetLable:SetParent(self)
    self.resetLable:SetSize(width, 30)
    self.resetLable:SetPosition(0, 420)
    self.resetLable:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))
    self.resetLable:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
    self.resetLable:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)
    self.resetLable:SetText("Weekly reset in " .. daysToReset .. "d ".. hoursToReset .. "h " .. minutesToReset .. "m")

    -- Window moving --
    self.Moving = false

    self.title.MouseDown = function(sender,args)
        self.MoveX = args.X
        self.MoveY = args.Y
        self.Moving = true
    end

    self.title.MouseUp = function()
        self.Moving = false
        position_x, position_y = self:GetPosition()
        LocksmithCharacterSettings["settings"]["window"]["position_x"] = position_x
        LocksmithCharacterSettings["settings"]["window"]["position_y"] = position_y
        Turbine.PluginData.Save(Turbine.DataScope.Character, "LocksmithCharacterSettings", LocksmithCharacterSettings)
    end

    self.title.MouseMove = function(sender,args)
        if self.Moving then
            local newLeft = self:GetLeft() - (self.MoveX - args.X)
            local newTop = self:GetTop() - (self.MoveY - args.Y)
            self:SetPosition(newLeft,newTop)
        end
    end

    self.closingButtonBackground = Turbine.UI.Control()
    self.closingButtonBackground:SetParent(self.title)
    self.closingButtonBackground:SetSize(20, 20)
    self.closingButtonBackground:SetPosition(self.background:GetWidth() - 20, 0)
    self.closingButtonBackground:SetMouseVisible(false)
    self.closingButtonBackground:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))

    local ClosingBUtton = Turbine.UI.Label()
    ClosingBUtton:SetParent(self.title)
    ClosingBUtton:SetPosition(self.background:GetWidth() - 15, 0)
    ClosingBUtton:SetSize(15, 15)
    ClosingBUtton:SetBackColor(Turbine.UI.Color(153/255, 0, 0))

    local ClosingBUttonImage = Turbine.UI.Label()
    ClosingBUttonImage:SetParent(ClosingBUtton)
    ClosingBUttonImage:SetPosition(4, -2)
    ClosingBUttonImage:SetSize(20, 20)
    ClosingBUttonImage:SetBackColorBlendMode(Turbine.UI.BlendMode.AlphaBlend)
    ClosingBUttonImage:SetBlendMode(Turbine.UI.BlendMode.Overlay)
    ClosingBUttonImage:SetMouseVisible(false)
    ClosingBUttonImage:SetWantsKeyEvents(true)
    ClosingBUttonImage:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)
    ClosingBUttonImage:SetText("X")

    ClosingBUtton.MouseClick = function()
        self:HideWindow()
    end
    
    ClosingBUttonImage.KeyDown = function(sender, args)
        if args["Action"] == 145 and self:IsVisible() then
            self:HideWindow()
        end
    end

     -- Create the tree view control.
     self.treeView = Turbine.UI.TreeView();
     self.treeView:SetParent(self);
     self.treeView:SetPosition(8, 37);
     self.treeView:SetSize(234, 375);
     self.treeView:SetBackColor(Turbine.UI.Color(0.250, 0.250, 0.250));
     self.treeView:SetIndentationWidth(15);
      
     -- Give the tree view a scroll bar.
     scriptTextScrollBar = Turbine.UI.Lotro.ScrollBar();
     scriptTextScrollBar:SetOrientation(Turbine.UI.Orientation.Vertical);
     scriptTextScrollBar:SetParent(self);
     scriptTextScrollBar:SetPosition(240, 70);
     scriptTextScrollBar:SetSize(10, 340);
     scriptTextScrollBar:SetVisible(false)
      
     self.treeView:SetVerticalScrollBar(scriptTextScrollBar);
    
    self.rootNodes = self.treeView:GetNodes()
end

function LocksmithInfoWindow:KeyDown(sender, args)
    Turbine.Shell.WriteLine("asd")
end

function LocksmithInfoWindow:ShowWindow()
    LocksmithInfoWindow.rootNodes:Add(LocksmithInfoWindow.treeView:GetNodes())
    LocksmithInfoWindow:LoadLocksData()
    LocksmithInfoWindow:SetVisible(true)
end

function LocksmithInfoWindow:HideWindow()
    LocksmithInfoWindow.rootNodes:Clear()
    LocksmithInfoWindow:SetVisible(false)
end


function LocksmithInfoWindow:LoadLocksData()
    locksInfo = LocksmithLocksData["locks"]
    -- characters --
    for character, instances in pairs(locksInfo) do
        if tableLenght(instances) > 0 then
            scriptTextScrollBar:SetVisible(false)
            local characterNode = Turbine.UI.TreeNode()
            characterNode:SetSize(240, 30)

            characterNode.border = Turbine.UI.Control()
            characterNode.border:SetParent(characterNode)
            characterNode.border:SetSize(240, 30)
            characterNode.border:SetPosition(0, 3)
            characterNode.border:SetMouseVisible(false)
            characterNode.border:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))

            characterNode.background = Turbine.UI.Control()
            characterNode.background:SetParent(characterNode)
            characterNode.background:SetSize(228, 21)
            characterNode.background:SetPosition(3, 6)
            characterNode.background:SetMouseVisible(false)
            characterNode.background:SetBackColor(Turbine.UI.Color(0.175, 0.175, 0.175))

            characterNode.label = Turbine.UI.Label()
            characterNode.label:SetParent(characterNode)
            characterNode.label:SetSize(228, 24)
            characterNode.label:SetPosition(7, 3)
            characterNode.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
            characterNode.label:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)

            -- Str max len = 30
            if LocksmithLocksData["characterData"] and LocksmithLocksData["characterData"][character] then
                characterNode.label:SetText(character .. " - " .. LocksmithLocksData["characterData"][character])
            else
                characterNode.label:SetText(character)
            end

            -- Mouse functions --
            characterNode.label.MouseEnter = function()
                characterNode.background:SetBackColor(Turbine.UI.Color(0, 0, 0))
            end
            characterNode.label.MouseLeave = function()
                characterNode.background:SetBackColor(Turbine.UI.Color(0.175, 0.175, 0.175))
            end


            self.rootNodes:Add(characterNode);
        
            local subNodes = characterNode:GetChildNodes();
        
            -- Instances --
            for instance, tiers in pairs(instances) do
                local instanceNode = Turbine.UI.TreeNode();
                instanceNode:SetSize(152, 27)

                -- Border --
                instanceNode.border = Turbine.UI.Control()
                instanceNode.border:SetParent(instanceNode)
                instanceNode.border:SetSize(152, 27)
                instanceNode.border:SetPosition(3, 3)
                instanceNode.border:SetMouseVisible(false)
                instanceNode.border:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))

                instanceNode.background = Turbine.UI.Control()
                instanceNode.background:SetParent(instanceNode)
                instanceNode.background:SetSize(143, 18)
                instanceNode.background:SetPosition(6, 6)
                instanceNode.background:SetMouseVisible(false)
                instanceNode.background:SetBackColor(Turbine.UI.Color(0.225, 0.225, 0.225))

                instanceNode.label = Turbine.UI.Label()
                instanceNode.label:SetParent(instanceNode)
                instanceNode.label:SetSize(143, 18)
                instanceNode.label:SetPosition(10, 5)
                instanceNode.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleLeft)
                instanceNode.label:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)
                if instanceLongnameDictionary[instance] then
                    instanceNode.label:SetText(instance .. " - " .. instanceLongnameDictionary[instance])
                else
                    instanceNode.label:SetText(instance)
                end
                
                -- Mouse functions --
                instanceNode.label.MouseEnter = function()
                    instanceNode.background:SetBackColor(Turbine.UI.Color(0, 0, 0))
                end
                instanceNode.label.MouseLeave = function()
                    instanceNode.background:SetBackColor(Turbine.UI.Color(0.225, 0.225, 0.225))
                end

                subNodes:Add(instanceNode);
        
                local subNodes = instanceNode:GetChildNodes();
        
                -- Tiers --
                for tier, bosses in pairs(tiers) do
                    local tierNode = Turbine.UI.TreeNode();
                    tierNode:SetSize(144, 26)

                    -- Border --
                    tierNode.border = Turbine.UI.Control()
                    tierNode.border:SetParent(tierNode)
                    tierNode.border:SetSize(144, 26)
                    tierNode.border:SetPosition(3, 3)
                    tierNode.border:SetMouseVisible(false)
                    tierNode.border:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))

                    tierNode.background = Turbine.UI.Control()
                    tierNode.background:SetParent(tierNode)
                    tierNode.background:SetSize(135, 17)
                    tierNode.background:SetPosition(6, 6)
                    tierNode.background:SetMouseVisible(false)
                    tierNode.background:SetBackColor(Turbine.UI.Color(0.275, 0.275, 0.275))

                    tierNode.label = Turbine.UI.Label()
                    tierNode.label:SetParent(tierNode)
                    tierNode.label:SetSize(135, 17)
                    tierNode.label:SetPosition(5, 5)
                    tierNode.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
                    tierNode.label:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)
                    tierNode.label:SetText(tier)

                    -- Mouse functions --
                    tierNode.label.MouseEnter = function()
                        tierNode.background:SetBackColor(Turbine.UI.Color(0, 0, 0))
                    end
                    tierNode.label.MouseLeave = function()
                        tierNode.background:SetBackColor(Turbine.UI.Color(0.275, 0.275, 0.275))
                    end

                    subNodes:Add(tierNode);
        
                    local subNodes = tierNode:GetChildNodes();

                    -- Bosses --
                    for boss, attempts in pairs(bosses) do
                        local bossAttemptsNode = Turbine.UI.TreeNode();
                        bossAttemptsNode:SetSize(144, 26)

                        bossAttemptsNode.border = Turbine.UI.Control()
                        bossAttemptsNode.border:SetParent(bossAttemptsNode)
                        bossAttemptsNode.border:SetSize(144, 26)
                        bossAttemptsNode.border:SetPosition(3, 3)
                        bossAttemptsNode.border:SetMouseVisible(false)
                        bossAttemptsNode.border:SetBackColor(Turbine.UI.Color(0.125, 0.125, 0.125))

                        bossAttemptsNode.background = Turbine.UI.Control()
                        bossAttemptsNode.background:SetParent(bossAttemptsNode)
                        bossAttemptsNode.background:SetSize(135, 17)
                        bossAttemptsNode.background:SetPosition(6, 6)
                        bossAttemptsNode.background:SetMouseVisible(false)
                        bossAttemptsNode.background:SetBackColor(Turbine.UI.Color(0.325, 0.325, 0.325))

                        bossAttemptsNode.label = Turbine.UI.Label()
                        bossAttemptsNode.label:SetParent(bossAttemptsNode)
                        bossAttemptsNode.label:SetSize(135, 17)
                        bossAttemptsNode.label:SetPosition(5, 5)
                        bossAttemptsNode.label:SetTextAlignment(Turbine.UI.ContentAlignment.MiddleCenter)
                        bossAttemptsNode.label:SetFont(Turbine.UI.Lotro.Font.BookAntiquaBold18)
                        bossAttemptsNode.label:SetText(boss .. " - " .. attempts)

                        subNodes:Add(bossAttemptsNode);
            
                        local subNodes = bossAttemptsNode:GetChildNodes();
                    end
                end
            end
        end
    end
end
