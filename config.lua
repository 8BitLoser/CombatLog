local configPath = "CombatLog"

---@class bsCombatLog<K, V>: { [K]: V }
local defaults = {
    showPlayerName = false,
    alpha = 1,
    autoShow = true,
    autoDuration = 5,
    keycode = {              --Keycode to trigger menu
        keyCode = tes3.scanCode.x,
        isShiftDown = false,
        isAltDown = false,
        isControlDown = false,
    },
}
---From BeefLibrary
local function yesNoB(page, label, id, configTable, options)
    local optionTable = { ---@type mwseMCMYesNoButton
        label = label,
        variable = mwse.mcm.createTableVariable{id = id, table = configTable}
    }
    if options then
        for key, value in pairs(options) do
            optionTable[key] = value
        end
    end
    local yesNo = page:createYesNoButton(optionTable)
    return yesNo
end
---From BeefLibrary
local function templateM(configsPath)
    local mcmTemplate = mwse.mcm.createTemplate({ name = configsPath })
    return mcmTemplate
end
local time---@type mwseTimer

local function alpha()
    mwse.log("Callback")
    event.trigger("combatLog:showMenu")
    if time then
        mwse.log("Resetting timer")
        time:reset()
    else
        time = timer.start{
            duration = 5,
            type = timer.real,
            callback = function ()
                local menu = tes3ui.findMenu("bsCombatLog")
                mwse.log(menu)
                if menu and menu.visible then
                    menu.visible = false
                end
                mwse.log("Timer Done")
            end
        }
    end
end


---@class bsCombatLog
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = templateM(configPath)
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings" })

    local toggle = settings:createCategory{paddingBottom = 10,}
        yesNoB(toggle, "Use Players Name in Combat Log?", "showPlayerName", config)
        yesNoB(toggle, "Enable Auto Show Mode", "autoShow", config)

        settings:createSlider({
            variable = mwse.mcm.createTableVariable{id = "autoDuration", table = config},
            label = "Auto Show Time",
            min = 1, max = 60, step = 1, jump = 5,
        })
    ---------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------
    settings:createSlider({
        variable = mwse.mcm.createTableVariable{id = "alpha", table = config},
        label = "Transparency",
        min = 0, max = 1, step = 0.01, jump = 0.1, decimalPlaces = 2,
        callback = alpha
    })

    settings:createKeyBinder({
        label = "Assign Keybind",
        description = "Assign a new keybind.",
        variable = mwse.mcm.createTableVariable{ id = "keycode", table = config },
        allowCombinations = false,
    })






    template:register()

end
event.register(tes3.event.modConfigReady, registerModConfig)

return config