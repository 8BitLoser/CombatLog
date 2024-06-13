local config = require("BeefStranger.CombatLog.config")

event.register("initialized", function()
    print("[MWSE:Combat Log] initialized")
end)

local function log(string,...)
    local line = debug.getinfo(2, "l").currentline
    local message = string.format("[CombatLog|%s] - %s", line, string)
    mwse.log(message, ...)
end

---From BeefLibrary
---@param menu tes3uiElement
local function autoSize(menu)
    log("AutoSize")
    menu.autoHeight = true
    menu.autoWidth = true
end

local combatLog = tes3ui.registerID("bsCombatLog")
local cMenu---@type tes3uiElement 
local cheader ---@type tes3uiElement --The cheese
local clog---@type tes3uiElement --The shoes
local scroll---@type tes3uiElement
local manual

local function combatlog()
    log("combatLog started")
    cMenu = tes3ui.createMenu{id = combatLog, dragFrame = true, fixedFrame = false}
        cMenu.text = "Combat Log"
        cMenu.width = 300
        cMenu.height = 200
        cMenu.positionX = -845
        cMenu.positionY = -135
        cMenu.alpha = config.alpha
        -- cMenu:loadMenuPosition()

    ---Have to do this or menu will not load visibly the first time
    if not cMenu.visible  then
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
local function getMenu()
    return tes3ui.findMenu(combatLog)
end
local function update()
    cMenu:updateLayout()
end

local autoTimer---@type mwseTimer

--- @param e attackHitEventData
local function onAttackHitCallback(e)
    log("attackHitCallback")
    ---Could be using cMenu instead of finding menu but dont feel like updating it all
    ---WRONG ^^^ cMenu gets replaced with MenuMulti_bottom_row_right on reload, and breaks the mod/crashes
    local menu = getMenu()
    local attacker = e.reference and e.reference.object and e.reference.object.name or "Unknown"
    local damage = e.mobile and e.mobile.actionData and e.mobile.actionData.physicalDamage or 0
    local isPlayer = e.reference == tes3.player
    local isTarget = e.targetReference ~= nil

    if config.autoShow and not manual and isTarget then
        log("autoShow")
        if cMenu then
            log("Making menu visible")
            cMenu.visible = true
        else
            log("creating log")
            combatlog()
        end

        if autoTimer and autoTimer.state ~= 2 then
            log("resetting timer")
            autoTimer:reset()
        else
            log("timer start %ss", config.autoDuration)
            autoTimer = timer.start {
                duration = config.autoDuration,
                callback = function(e)
                    log("timer end")
                    -- local menu = tes3ui.findMenu(combatLog)
                    if cMenu and cMenu.visible and not manual then
                        log("hiding menu")
                        cMenu.visible = false
                    end
                end
            }
        end
    end

    if menu then
        log("menu found starting update")
        if damage <= 0 and isTarget then
            log("Missed:showing miss text")
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
            log("Missed:Updating")
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
            log("Hit:Updating")
            log("Menu - %s", menu)
            menu:updateLayout()
            scroll.widget.positionY = scroll.widget.positionY + 25
            scroll.widget:contentsChanged()
            log("Hit:Update Finished")
        end
        ---Only save 100 messages
        if #clog.children >= 100 then
            log("Log Full")
            clog.children[1]:destroy()
            menu:updateLayout()
            scroll.widget:contentsChanged()
        end
        log("End of attackCallback")
        menu:saveMenuPosition()
    end
end
event.register(tes3.event.attackHit, onAttackHitCallback)


--[[ event.register("keyUp", function(e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        if tes3ui.menuMode() then return end

        if config.autoShow and cMenu then
            if manual then
                log("manual true | vis %s", cMenu.visible)
                manual = false
                tes3.messageBox("CombatLog Manual Override %s", manual or "Disabled")
                cMenu.visible = false
            else
                log("manual nil or false | vis %s", cMenu.visible)
                manual = true
                tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled")
                cMenu.visible = true
            end
        else
            if cMenu then
                ---Toggle visible
                log("cMenu found toggle visiblity|current %s", cMenu.visible)
                cMenu.visible = not cMenu.visible
                ---Update just incase, probably not needed
                cMenu:updateLayout()
            else
                combatlog()
                if config.autoShow then
                    cMenu.visible = false
                    cMenu:updateLayout()
                end
            end
        end

        if tes3.worldController.inputController:isAltDown() then
            tes3.createReference({ --Spawn a skeleton on the player
            object = "skeleton",
            position = tes3.player.position,
            orientation = tes3vector3.new(0, 0, 0.67),
            cell = tes3.player.cell
        })
        end
    end
end) ]]

---@param e keyUpEventData
local function onKeyUp(e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        if tes3ui.menuMode() then return end
        log("getMenu %s | cMenu %s", getMenu(), cMenu)
        local menu = getMenu()

        if config.autoShow and menu then
            if manual then
                log("manual true | vis %s", menu.visible)
                manual = false
                tes3.messageBox("CombatLog Manual Override %s", manual or "Disabled")
                menu.visible = false
            else
                log("manual nil or false | vis %s", menu.visible)
                manual = true
                tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled")
                menu.visible = true
            end
        else
            if menu then
                ---Toggle visible
                log("menu found toggle visiblity|current %s", menu.visible)
                menu.visible = not menu.visible
                ---Update just incase, probably not needed
                menu:updateLayout()
            else
                combatlog()
            end
        end

        if tes3.worldController.inputController:isAltDown() then
            tes3.createReference({ --Spawn a skeleton on the player
            object = "skeleton",
            position = tes3.player.position,
            orientation = tes3vector3.new(0, 0, 0.67),
            cell = tes3.player.cell
        })
        end
    end
end

event.register(tes3.event.keyUp, onKeyUp)

-- event.register(tes3.event.loaded, function (e)
--     log("event loaded %s", event.isRegistered(tes3.event.keyUp, onKeyUp))
--     if event.isRegistered(tes3.event.keyUp, onKeyUp) then
--         event.unregister(tes3.event.keyUp, onKeyUp)
--         event.register(tes3.event.keyUp, onKeyUp)
--     else
--         event.register(tes3.event.keyUp, onKeyUp)
--     end
-- end)

local showMenu = "combatLog:showMenu"
event.register(showMenu, function ()
    log("showMenu event")
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