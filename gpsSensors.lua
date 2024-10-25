
local function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

local function reset_if_needed(widget)
    -- test if the reset switch is toggled, if so then reset all internal flags
    --print("widget.reset_if_needed")
    if widget.resetSwitch == nil or widget.resetSwitch == "" then
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

            widget.gps_current_speed = 0
            widget.gps_max_speed = 0

        elseif -100 == resetSwitchValue then
            --print("reset switch released")
            widget.scheduler.remove('reset_sw')
        end
    end
end


------------------------------------------------------------------------------------------------
-- Function to get North, South, East, West indicators
------------------------------------------------------------------------------------------------
local function getNSEW(widget)
    NS = ""
    EW = ""
    if widget.GPSLat > 0 then
      NS = "N"
    else
      NS = "S"
    end

    if widget.GPSLon > 0 then
      EW = "E"
    else
      EW = "W"
    end
    return NS, EW
end

------------------------------------------------------------------------------------------------
-- Function to Convert Decimal to Degrees, Minutes, Seconds
------------------------------------------------------------------------------------------------
local function dec2deg(decimal)
  local Degrees = math.floor(decimal)
  local Minutes = math.floor((decimal - Degrees) * 60)
  local Seconds = (((decimal - Degrees) * 60) - Minutes) * 60
  return Degrees, Minutes, Seconds
end


------------------------------------------------------------------------------------------------
-- Function to Build Decimal, Minutes, Seconds String
------------------------------------------------------------------------------------------------
local function buildDMSstr(widget)
    -- Converts the gps coordinates to Degrees,Minutes,Seconds
    local LatD,LatM,LatS = dec2deg(widget.GPSLat)
    local LongD,LongM,LongS = dec2deg(widget.GPSLon)
    local NS,EW = getNSEW(widget)
    local DMSLatString  = math.abs(LatD).."°"..LatM.."'"..string.format("%.1f\"",LatS)..NS
    local DMSLongString = math.abs(LongD).."°"..LongM.."'"..string.format("%.1f\"",LongS)..EW
    return DMSLatString , DMSLongString
end

----------------------------------------------------------------------------------------------------------------------


local key = "gpsSensors"

local function create()
    local libscheduler = loadSched()
    local widget = {
        scheduler = libscheduler.new(),
        resetSwitch = "",
        displayState = 0,
        GPSLat = "",
        GPSLon = "",
        gps_current_speed = 0,
        gps_max_speed = 0,
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
            displayTitle = "GPS speed Max"
            displayString = widget.gps_max_speed .. "mph"
        else
            displayTitle = "GPS"
            if system.getSource({ name="GPS", options=OPTION_LATITUDE }):state() == false or
                    widget.GPSLat == nil or widget.GPSLon == nil or
                    widget.GPSLat < -90 or widget.GPSLat > 90 or
                    widget.GPSLon < -180 or widget.GPSLon > 180 then
                displayString = "Sensor Lost"
            else
                local latStr, lonStr = buildDMSstr(widget)
                displayString = string.format("%s\n%s",latStr, lonStr)
            end
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
        lcd.font(FONT_L)
        --y = (h - font_h)/2
    end

    if system.getSource("GPS") == nil or system.getSource("GPS"):state() == false then
        lcd.color(RED)
    else
        lcd.color(WHITE)
    end

    font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    x = (w - font_w) / 2

    --lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y , displayString)
end

local function wakeup(widget)
    reset_if_needed(widget)
    widget.scheduler.tick()
    if system.getSource("GPS speed") ~= nil then
        local gps_speed = system.getSource("GPS speed"):value()
        if gps_speed > widget.gps_max_speed then
            widget.gps_max_speed = gps_speed
        end

        widget.GPSLat = system.getSource({ name="GPS", options=OPTION_LATITUDE }):value()
        widget.GPSLon = system.getSource({ name="GPS", options=OPTION_LONGITUDE }):value()
    end
    lcd.invalidate()
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
    widget.resetSwitch = storage.read("resetSwitch") or system.getSource("SH↓")
end

local function write(widget)
    storage.write("resetSwitch", widget.resetSwitch)
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

        if (debounced == nil or debounced == true)  then
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
    system.registerWidget({ key = "gsens", name = "GPS Sensors", create = create, paint = paint, wakeup = wakeup,
                            event=event, title= false, read = read, write = write, configure=configure})
end

return { init = init }
