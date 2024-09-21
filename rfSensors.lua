

----------------------------------------------------------------------------------------------------------------------
local name = "RF Sensors"
local key = "rfwidget"

local function create()
    local libservice = libservice or loadService()
    g_mahRe2Service = g_mahRe2Service or libservice.new()
    
    widget = {
        rssi_24_current = 0,
        vfr_current = 0,
        service = g_mahRe2Service,
        displayState = 0,
    }
    return widget
end

local function paint_rssi24(widget)
    lcd.font(FONT_XL)
    local w, h = lcd.getWindowSize()
    local displayString = "---/---"
    if widget ~= nil then
        displayString = math.floor(widget.service.rssi_24) .. "/" .. math.floor(widget.rssi_24_current)
    end
    local font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    local x = (w - font_w) / 2
    local y = (h - font_h)/2

    --lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y, displayString)
    lcd.invalidate()

end

local function paint(widget)
    -- 1/9 screen 256x78 (supported)
    local displayTitle = ""
    local displayString = "---/---"
    if widget ~= nil then
        --print("widget.displayCell: " .. widget.displayCell)
        if widget.displayState == 0 then  --rssi 2.4ghz
            displayTitle = "RSSI 2.4"
            displayString = math.floor(widget.service.rssi_24) .. "dB/" .. math.floor(widget.rssi_24_current).."dB"
        else
            displayTitle = "VFR 2.4"
            displayString = math.floor(widget.service.vfr_24) .. "%/" .. math.floor(widget.vfr_current) .. "%"
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

    local y = (h - font_h)/2
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
    lcd.drawText(x, y , displayString)
end

local function wakeup(widget)
    widget.service.reset_if_needed()
    widget.rssi_24_current = system.getSource("RSSI"):value()
    if widget.service.rssi_24 < widget.rssi_24_current then
        widget.service.rssi_24 = widget.rssi_24_current
    end
    
    widget.vfr_current = system.getSource("VFR"):value()
    if widget.service.vfr_24 < widget.vfr_current then
        widget.service.vfr_24 = widget.vfr_current
    end
    
end

local function configure(widget)
    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.service.resetSwitch
    end, function(value)
        widget.service.resetSwitch = value
    end)
end

local function read(widget)
    widget.service.resetSwitch = storage.read("resetSwitch")
end

local function write(widget)
    storage.write("resetSwitch", widget.service.resetSwitch)
end

local function event(widget, category, value, x, y)

    local function event_end_debounce()
        widget.service.scheduler.remove('touch_event')
        --print("event_end_debounce")
    end

    --print("Event received:", category, value, x, y)
    if category == EVT_KEY and value == KEY_ENTER_BREAK or category == EVT_TOUCH then
        local debounced = widget.service.scheduler.check('touch_event')
        --if debounced == nil then
        --    print("debounced: nil")
        --else
        --    print("debounced: " .. tostring(debounced))
        --end

        if (debounced == nil or debounced == true)  then
            widget.service.scheduler.add('touch_event', false, 1, event_end_debounce) -- add the touch event to the scheduler
            widget.service.scheduler.clear('touch_event') -- set touch event to false in the scheduler so we don't run again
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
    system.registerWidget({ key = "dave", name = "dave", create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true, event=event })
end

return { init = init }
