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

            widget.vfr_24_min = 100
            widget.rssi_24_min = 100

        elseif -100 == resetSwitchValue then
            --print("reset switch released")
            widget.scheduler.remove('reset_sw')
        end
    end
end

----------------------------------------------------------------------------------------------------------------------
local name = "RF Sensors"
local key = "rfwidget"

local function create()
    libscheduler = libscheduler or loadSched()

    widget = {
        scheduler = libscheduler.new(),
        displayState = 0,

        --rssi stuff below here
        rssi_24_current = 100,
        rssi_24_min = 100,

        --vfr stuff below here
        vfr_current = 0,
        vfr_24_min = 0,

        resetSwitch = "",

    }
    return widget
end

local function paint(widget)
    -- 1/9 screen 256x78 (supported)
    local displayTitle = ""
    local displayString = "---/---"
    if widget ~= nil then
        --print("widget.displayCell: " .. widget.displayCell)
        if widget.displayState == 0 then
            --rssi 2.4ghz
            displayTitle = "RSSI 2.4"
            displayString = math.floor(widget.rssi_24_min) .. "dB/" .. math.floor(widget.rssi_24_current) .. "dB"
        else
            displayTitle = "VFR 2.4"
            displayString = math.floor(widget.vfr_24_min) .. "%/" .. math.floor(widget.vfr_current) .. "%"
        end
    end

    local w, h = lcd.getWindowSize()
    lcd.font(FONT_S)
    local font_w, font_h = lcd.getTextSize(displayTitle)
    local title_font_h = font_h
    local x = (w - font_w) / 2
    local title_font_pad = 5
    lcd.color(lcd.GREY(192))
    lcd.drawText(x, title_font_pad, displayTitle)

    local y = (h - font_h) / 2
    if widget.displayState == 0 then
        lcd.font(FONT_XXL)
        --y = (h - font_h)/2 --+ title_font_h - 5

    else
        lcd.font(FONT_XXL)
        --y = (h - font_h)/2
    end
    lcd.color(WHITE)
    font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    x = (w - font_w) / 2

    --lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y, displayString)
end

local function wakeup(widget)
    reset_if_needed(widget)
    widget.scheduler.tick()

    local lcd_needs_update = false
    local rssi = system.getSource("RSSI")
    local vfr = system.getSource("VFR")

    if rssi ~= nil and vfr ~= nil then
        local curr_rssi = rssi:value()
        local curr_vfr = vfr:value()
        --print(math.floor(widget.rssi_24_min) .. "/" .. math.floor(curr_rssi) .. tostring(math.floor(widget.rssi_24_min)>math.floor(curr_rssi)))
        if widget.rssi_24_min > curr_rssi and curr_rssi > 0 then
            --print("setting rssi_24_min: ".. widget.rssi_24_min)
            widget.rssi_24_min = curr_rssi
            --print("after set: ".. widget.rssi_24_min)
            lcd.invalidate()
        end

        if widget.vfr_24_min > curr_vfr and curr_vfr > 0 then
            widget.vfr_24_min = curr_vfr
            lcd.invalidate()
        end

        if curr_rssi ~= widget.rssi_24_current or curr_vfr ~= widget.vfr_current then
            widget.rssi_24_current = curr_rssi
            widget.vfr_current = curr_vfr
            lcd.invalidate()
        end
    end
end

local function configure(widget)
    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.resetSwitch
    end, function(value)
        widget.resetSwitch = value
    end)
end

local function read(widget)
    widget.resetSwitch = storage.read("rfsResetSwitch")
    --print("read widget.resetSwitch: " .. widget.resetSwitch:name())
end

local function write(widget)
    --print("write widget.resetSwitch: " .. widget.resetSwitch:name())
    storage.write("rfsResetSwitch", widget.resetSwitch)
end

local function event(widget, category, value, x, y)

    local function event_end_debounce()
        widget.scheduler.remove('touch_event')
        --print("event_end_debounce")
    end

    --print("Event received:", category, value, x, y)
    if category == EVT_KEY and value == KEY_ENTER_BREAK or category == EVT_TOUCH then
        local debounced = widget.scheduler.check('touch_event')
        --if debounced == nil then
        --    print("debounced: nil")
        --else
        --    print("debounced: " .. tostring(debounced))
        --end

        if (debounced == nil or debounced == true) then
            widget.scheduler.add('touch_event', false, 1, event_end_debounce) -- add the touch event to the scheduler
            widget.scheduler.clear('touch_event') -- set touch event to false in the scheduler so we don't run again
            widget.displayState = (widget.displayState + 1) % 2
            --print("touch event: " .. widget.displayState)
            lcd.invalidate()
        end
        return true
    else
        return false
    end
end

local function init()
    system.registerWidget({ key = "rfs", name = "rfs", create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write,
                            event = event, title= false })
end

return { init = init }
