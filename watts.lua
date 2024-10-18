-- define default values

function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

local function reset_if_needed(widget)
    -- test if the reset switch is toggled, if so then reset all internal flags
    --print("widget.reset_if_needed")
    if widget.resetSwitch == nil then
        --print("setting reset switch")
        widget.resetSwitch = system.getSource("SH↓")
    end
    if widget.resetSwitch ~= nil then
        -- Update switch position
        local debounced = widget.scheduler.check('reset_sw')
        --print("debounced: " .. tostring(debounced))
        local resetSwitchValue = widget.resetSwitch:value()
        if (debounced == nil or debounced == true) and -100 ~= resetSwitchValue then
            -- reset switch
            widget.scheduler.add('reset_sw', false, 2) -- add the reset switch to the scheduler
            --print("reset start task: " .. tostring(widget.scheduler.tasks['reset_sw'].ready))
            widget.scheduler.clear('reset_sw') -- set the reset switch to false in the scheduler so we don't run again
            --print("reset task: " .. tostring(widget.scheduler.tasks['reset_sw'].ready))
            --print("reset switch toggled - debounced: " .. tostring(debounced))
            --print("reset event")

            widget.wattsCurrentValue = 0
            widget.wattsMaxValue = 0

        elseif -100 == resetSwitchValue then
            --print("reset switch released")
            widget.scheduler.remove('reset_sw')
        end
    end
end


----------------------------------------------------------------------------------------------------------------------
local name = "Watts"
local key = "Watts"

local function create()
    widget = {
        scheduler = libscheduler.new(),
        resetSwitch = "",
        lipoSensor = nil,
        currentSensor = nil,
        wattsCurrentValue = 0,
        wattsMaxValue = 0,
    }
    return widget
end

local function paint(widget)
    lcd.font(FONT_XL)
    local w, h = lcd.getWindowSize()
    local displayString = "---/---"
    if widget ~= nil then
        displayString = widget.wattsCurrentValue .. "W/" .. widget.wattsMaxValue  .. "W"
    end
    local font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    local x = (w - font_w) / 2
    local y = (h - font_h)/2

    --lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))

    if widget.lipoSensor == nil or widget.lipoSensor:state() == false or
    widget.currentSensor == nil or widget.currentSensor:state() == false then
        lcd.color(RED)
    else
        lcd.color(WHITE)
    end

    lcd.drawText(x, y, displayString)
end

local function wakeup(widget)
    reset_if_needed(widget)
    widget.scheduler.tick()

    --widget.lipoSensor = system.getSource("LiPo")
    --widget.currentSensor = system.getSource("Current")
    if widget.lipoSensor ~= nil and widget.currentSensor ~= nil then
        local amps = widget.currentSensor:value()
        local volts = widget.lipoSensor:value()
        --print("amps: " .. amps .. " volts: " .. volts)
        local watts = amps * volts
        if watts ~= widget.wattsCurrentValue then
            widget.wattsCurrentValue = watts
            if widget.wattsCurrentValue > widget.wattsMaxValue then
                widget.wattsMaxValue = widget.wattsCurrentValue
            end
            lcd.invalidate()
        end
    end
end

local function configure(widget)
    line = form.addLine("Lipo Sensor")
    form.addSourceField(line, nil,
            function() return widget.lipoSensor end,
            function(value) widget.lipoSensor = value end
    )

    line = form.addLine("Current Sensor")
    form.addSourceField(line, nil,
            function() return widget.currentSensor end,
            function(value) widget.currentSensor = value end
    )

    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.resetSwitch
    end, function(value)
        widget.resetSwitch = value
    end)
end

local function read(widget)
    widget.lipoSensor = storage.read("lipoSensor")
    widget.currentSensor = storage.read("currentSensor")
    widget.resetSwitch = storage.read("resetSwitch")
end

local function write(widget)
    storage.write("lipoSensor" ,widget.lipoSensor)
    storage.write("currentSensor" ,widget.currentSensor)
    storage.write("resetSwitch", widget.resetSwitch)
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true })
end

return { init = init }
