local config = require("BeefStranger.CombatLog.config")
local bs = require("BeefStranger.CombatLog.common")
local rgb, log = bs.rgb, bs.log

local cl = {}


event.register("initialized", function()
    print("[MWSE:Combat log] initialized")
end)

local combatLog = tes3ui.registerID("bsCombatLog")
local cMenu     ---@type tes3uiElement The top level menu
local cheader   ---@type tes3uiElement The cheese
local scroll    ---@type tes3uiElement The ScrollPane
local clog      ---@type tes3uiElement The Block inside of scroll
local manual    ---@type boolean ManualOverride
---Creation of the log
local function combatlog()
    -- log("combatLog started")
    cMenu = tes3ui.createMenu{id = combatLog, dragFrame = true, fixedFrame = false}
        cMenu.text = "Combat log"
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

    clog = scroll:createBlock{id = "clog"}
        bs.autoSize(clog)
        clog.flowDirection = tes3.flowDirection.topToBottom

    cMenu:updateLayout()
end

---finMenu Helper because cMenu breaks on load
local function getMenu()
    return tes3ui.findMenu(combatLog)
end

---Updates menu and ScrollBar
local function updateList()
    local menu = getMenu()
    menu:updateLayout()                                    ---Update Layout
    scroll.widget.positionY = scroll.widget.positionY + 25 ---Scroll down 25
    scroll.widget:contentsChanged()                        ---Update actual scrollPane
end

-------------Get hitChance to add to log--------------
local hitChance = 0
--- @param e calcHitChanceEventData
local function hitChanceCalc(e)
    hitChance = e.hitChance
end
event.register(tes3.event.calcHitChance, hitChanceCalc)

--------------AutoTimer--------------
---The Timer for autoShow
local autoTimer---@type mwseTimer

function cl.autoShow()
    local menu = getMenu() or (combatlog() and getMenu())
    debug.log(menu)

    if menu then
        menu.visible = true

        if autoTimer and autoTimer.state ~= 2 then
            -- log("resetting timer")
            autoTimer:reset()
        else
            autoTimer = timer.start {
                duration = config.autoDuration,
                callback = function(e)
                    log("timer end")
                    -- local menu = getMenu()
                    if menu.visible then
                        log("hiding menu")
                        menu.visible = false
                    end
                end
            }
        end
    else
        log("Combat Log not Found")
    end
end
------------------------------------------------------

------------------------------------------------------
local magicDamage = 0
local damageTimer ---@type mwseTimer|nil
--- @param e damagedEventData
local function damagedCallback(e)
    if e.source == tes3.damageSource.magic then
        magicDamage = magicDamage + math.abs(e.damage)
        local menu = getMenu() or (combatlog() and getMenu())
        local attacker = e.attacker.object.name or "Unknown"        --Name of Attacker
        local playerIsAttacker = e.attacker == tes3.mobilePlayer    --If player is Attacking
        local playerIsTarget = e.mobile == tes3.mobilePlayer        --If player is the Target
        local eName = e.magicEffect.object.name                     --Name of effect
        local you = not config.showPlayerName and "You" or attacker --Set you to various options

        if damageTimer and damageTimer.state ~= 2 then              --Reset timer if effect is still active
            damageTimer:reset()
        else
            damageTimer = timer.start({
                duration = 0.10,
                callback = function()
                    if menu and magicDamage > 0 and (playerIsAttacker or playerIsTarget) then
                        if config.autoShow and not manual then
                            cl.autoShow()
                        end
                        local hitText = string.format(
                            "%s Dealt %.2f %s",
                            (playerIsAttacker and you or attacker),
                            math.ceil(magicDamage),
                            (config.showEffectName and (string.find(eName:lower(), "damage") and eName or eName .. " Damage")) or
                            "Damage"
                        )

                        local magicHit = clog:createLabel { text = hitText }
                        magicHit.color = playerIsAttacker and rgb.bsPrettyBlue or rgb.bsNiceRed

                        if config.autoShow then
                            menu.visible = true
                        end

                        updateList()
                    end
                    magicDamage = 0
                    damageTimer = nil
                end
            })
        end
    end
end
event.register(tes3.event.damaged, damagedCallback)


--- @param e attackHitEventData
local function onAttackHitCallback(e)
    -- log("attackHitCallback")
    ---Could be using cMenu instead of finding menu but dont feel like updating it all
    ---WRONG ^^^ cMenu gets replaced with MenuMulti_bottom_row_right on reload, and breaks the mod/crashes

    local menu = getMenu() or (config.autoShow and combatlog() and getMenu())                    --The CombatLog Menu or create and then get it
    local attacker = e.reference and e.reference.object and e.reference.object.name or "Unknown" --Name of attacker
    local damage = e.mobile and e.mobile.actionData and e.mobile.actionData.physicalDamage or 0  --Damage dealt to target
    local playerAttack = e.reference == tes3.player                                              --Checks if attack was from the player
    local playerIsTarget = e.targetReference == tes3.player                                      --Checks if player is the target
    local validTarget = e.targetReference ~= nil                                                 --Checks for Valid Target
    local target = e.targetReference and e.targetReference.object.name or "Unknown"              --Who got attacked when blocking
    local blocked = e.targetMobile and e.targetMobile.actionData.blockingState ~= 0              --Checks if attack was blocked
    if not menu then log("%s not found", combatLog) return end

    local you = not config.showPlayerName and "You" or attacker --Is "You" if config.showPlayerName = false, or attacker if true

    if config.autoShow and not manual and validTarget then
        cl.autoShow()
        -- -- log("autoShow")
        -- -- log("Making menu visible")
        -- menu.visible = true

        -- if autoTimer and autoTimer.state ~= 2 then
        --     -- log("resetting timer")
        --     autoTimer:reset()
        -- else
        --     -- log("timer start %ss", config.autoDuration)
        --     autoTimer = timer.start {
        --         duration = config.autoDuration,
        --         callback = function(e)
        --             -- log("timer end")
        --             -- local menu = getMenu()
        --             if menu.visible and not manual then
        --                 -- log("hiding menu")
        --                 menu.visible = false
        --             end
        --         end
        --     }
        -- end
    end
    --If Attacker Missed
    if damage <= 0 and validTarget then 
        local missedText = ("%s Missed (%d%%)"):format(playerAttack and you or attacker, hitChance) --"You" or attacker name

        local missedlabel = clog:createLabel { text = missedText }
        missedlabel.color = playerAttack and rgb.bsLightGrey or rgb.focusColor
        -- logmsg("%s Missed", e.reference.object.name)
        updateList()
    --If Attacker Hit
    elseif validTarget and not blocked then
        local hitText = string.format("%s Hit for %.2f (%d%%)", playerAttack and you or attacker , damage, hitChance)

        local hitlabel = clog:createLabel { text = hitText }
        hitlabel.color = playerAttack and rgb.bsPrettyGreen or rgb.bsNiceRed ---Change Color depending on who's attacking
        -- log("Hit:Updating"); log("Menu - %s", menu)
        updateList()
    --If Target Blocked
    elseif validTarget and blocked then
        local blockText = ("%s Blocked!"):format(playerIsTarget and you or target)

        local blockLabel = clog:createLabel { text = blockText }
        blockLabel.color = rgb.normalColor --Default Text color, manually put in to change later if I decide to
        -- log(blockText) 
        updateList()
    end

    ---Only save 100 messages
    if #clog.children > 100 then
        -- log("log Full")
        for i = 1, #clog.children - 100 do
            clog.children[i]:destroy()          ---Destroy First message
        end

        menu:updateLayout()                 ---Update
        scroll.widget:contentsChanged()     ---Update ScrollPane
    end
    -- log("End of attackCallback")
    menu:saveMenuPosition()
end
event.register(tes3.event.attackHit, onAttackHitCallback)

---@param e keyUpEventData
local function onKeyUp(e)
    if not tes3.onMainMenu() and e.keyCode == config.keycode.keyCode and tes3.isCharGenFinished() then
        if tes3ui.menuMode() then return end
        -- log("getMenu %s | cMenu %s", getMenu(), cMenu)
        local menu = getMenu()

        if config.autoShow and menu then
            ---If manual mode is true disable it and hide menu on KeyPress
            if manual then
                -- log("manual true | vis %s", menu.visible)
                manual = false
                tes3.messageBox("CombatLog Manual Override %s", manual or "Disabled")
                menu.visible = false
            else
                -- log("manual nil or false | vis %s", menu.visible)
                manual = true
                tes3.messageBox("CombatLog Manual Override %s", manual and "Enabled")
                menu.visible = true
            end
        else
            if menu then
                ---Toggle visible
                -- log("menu found toggle visiblity|current %s", menu.visible)
                menu.visible = not menu.visible
                ---Update just incase, probably not needed
                menu:updateLayout()
            else
                combatlog() --Create the log if its not done
            end
        end
    end
end
event.register(tes3.event.keyUp, onKeyUp)

event.register("loaded", function (e)
    combatlog()
    local menu = getMenu()
    menu.visible = false
    debug.log(menu)
end)

local showMenu = "combatLog:showMenu"
event.register(showMenu, function ()
    -- log("showMenu event")
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