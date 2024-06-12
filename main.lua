local config = require("BeefStranger.CombatLog.config")

event.register("initialized", function()
    print("[MWSE:Combat Log] initialized")
end)
---From BeefLibrary
---@param menu tes3uiElement
local function autoSize(menu)
    menu.autoHeight = true
    menu.autoWidth = true
end


local combatLog = tes3ui.registerID("bsCombatLog2")
local cMenu---@type tes3uiElement 
local cheader ---@type tes3uiElement 
local clog---@type tes3uiElement 
local scroll---@type tes3uiElement
local manual

local function combatlog()
    -- combatLog = tes3ui.registerID("bsCombatLogTEST2")

    cMenu = tes3ui.createMenu{id = combatLog, dragFrame = true, fixedFrame = false}
        cMenu.text = "Combat Log"
        cMenu.width = 300
        cMenu.height = 200
        cMenu.positionX = -845
        cMenu.positionY = -135
        cMenu.alpha = config.alpha
        cMenu:loadMenuPosition()

    ---Have to do this or menu will not load visibly the first time
    if cMenu.visible == false then
        cMenu.width = 300
        cMenu.height = 200
        cMenu.positionX = -845
        cMenu.positionY = -135
        cMenu.visible = true
    end

    scroll = cMenu:createVerticalScrollPane{id = "scroll"}

    clog = scroll:createBlock{id = "CLOG"}
        autoSize(clog)
        clog.flowDirection = tes3.flowDirection.topToBottom

    cMenu:updateLayout()
end
local autoTimer---@type mwseTimer

--- @param e attackHitEventData
local function onAttackHitCallback(e)
    ---Could be using cMenu instead of finding menu but dont feel like updating it all
    local menu = tes3ui.findMenu(combatLog)
    local attacker = e.reference.object.name
    local damage = e.mobile.actionData.physicalDamage
    local isPlayer = e.reference == tes3.player
    local isTarget = e.targetReference ~= nil

    if config.autoShow and not manual then
        -- mwse.log("autoShow")
        if cMenu then
            -- mwse.log("Making menu visible")
            cMenu.visible = true
        else
            -- mwse.log("creating log")
            combatlog()
        end

        if autoTimer and autoTimer.state ~= 2 then
            -- mwse.log("resetting timer")
            autoTimer:reset()
        else
            -- mwse.log("timer start %ss", config.autoDuration)
            autoTimer = timer.start {
                duration = config.autoDuration,
                callback = function(e)
                    -- mwse.log("timer end")
                    -- local menu = tes3ui.findMenu(combatLog)
                    if cMenu and cMenu.visible then
                        -- mwse.log("hiding menu")
                        cMenu.visible = false
                    end
                end
            }
        end
    end

    if menu then
        if damage <= 0 and isTarget then
            local missedText = ("%s Missed"):format(attacker)

            if isPlayer then
                missedText = string.format("%s Missed", not config.showPlayerName and "You" or attacker)
            end
            -- logmsg("%s Missed", e.reference.object.name) 
            local missedlabel = clog:createLabel { text = missedText }

            if isPlayer then
                missedlabel.color = { 0.839, 0.839, 0.839 }
            else
                missedlabel.color = { 0.38, 0.38, 0.38 }
            end
            ---Update scrollbar and move to the bottom
            menu:updateLayout()
            scroll.widget.positionY = scroll.widget.positionY + 25
            scroll.widget:contentsChanged()

        elseif isTarget then
            local hitText = string.format("%s Hit for %.2f", attacker, damage)
            if isPlayer then
                hitText = string.format("%s Hit for %.2f", not config.showPlayerName and "You" or attacker, damage)
            end

            local hitlabel = clog:createLabel { text = hitText }
            ---Change Color depending on who's attacking
            if isPlayer then
                hitlabel.color = { 0.38, 0.941, 0.525 }
            elseif not isPlayer then
                hitlabel.color = { 0.941, 0.38, 0.38 }
            end

            menu:updateLayout()
            scroll.widget.positionY = scroll.widget.positionY + 25
            scroll.widget:contentsChanged()
        end
        ---Only save 100 messages
        if #clog.children >= 100 then
            clog.children[1]:destroy()
            menu:updateLayout()
            scroll.widget:contentsChanged()
        end
        menu:saveMenuPosition()
    end
end
event.register(tes3.event.attackHit, onAttackHitCallback)

---@param e keyUpEventData
event.register("keyUp", function(e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        if tes3ui.menuMode() then return end

        if config.autoShow then
            if manual then
                manual = false
                tes3.messageBox("CombatLog Manual Override %s", manual or "Disabled")
            else
                manual = true
                tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled")
                cMenu.visible = true
            end
        else
            if cMenu then
                ---Toggle visible
                cMenu.visible = not cMenu.visible
                ---Update just incase, probably not needed
                cMenu:updateLayout()
            else
                combatlog()
            end
        end
    end
end)

local showMenu = "combatLog:showMenu"
event.register(showMenu, function ()
    local menu = tes3ui.findMenu(combatLog)
    if menu then
        menu.width = 300
        menu.height = 200
        menu.positionX = -845
        menu.positionY = -135
        menu.alpha = config.alpha
        menu.visible = true
        menu:updateLayout()
    else
        combatlog()
    end
end)