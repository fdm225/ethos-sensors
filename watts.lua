-- define default values

function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

----------------------------------------------------------------------------------------------------------------------
local name = "Watts"
local key = "Watts"

local function create()
    local libservice = libservice or loadService()
    g_mahRe2Service = g_mahRe2Service or libservice.new()
    
    local libscheduler = libscheduler or loadSched()
    g_scheduler = g_scheduler or libscheduler.new()
    widget = {
        service = g_mahRe2Service,
    }
    return widget
end

local function paint(widget)
    lcd.font(FONT_XL)
    local w, h = lcd.getWindowSize()
    local displayString = "---/---"
    if widget ~= nil then
        displayString = widget.service.wattsCurrentValue .. "/" .. widget.service.wattsMaxValue
    end
    local font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    local x = (w - font_w) / 2
    local y = (h - font_h)/2

    --lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y, displayString)
    lcd.invalidate()

end

local function wakeup(widget)
    widget.service.bg_func()
end

local function configure(widget)
    line = form.addLine("Lipo Sensor")
    form.addSourceField(line, nil,
            function() return widget.service.lipoSensor end,
            function(value) widget.service.lipoSensor = value end
    )

    line = form.addLine("Current Sensor")
    form.addSourceField(line, nil,
            function() return widget.service.currentSensor end,
            function(value) widget.service.currentSensor = value end
    )

    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.service.resetSwitch
    end, function(value)
        widget.service.resetSwitch = value
    end)
end

local function read(widget)
    widget.service.lipoSensor = storage.read("lipoSensor")
    widget.service.currentSensor = storage.read("currentSensor")
    widget.service.resetSwitch = storage.read("resetSwitch")
end

local function write(widget)
    storage.write("lipoSensor" ,widget.service.lipoSensor)
    storage.write("currentSensor" ,widget.service.currentSensor)
    storage.write("resetSwitch", widget.service.resetSwitch)
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true })
end

return { init = init }
