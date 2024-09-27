
------------------------------------------------------------------------------------------------
-- Function to get North, South, East, West indicators
------------------------------------------------------------------------------------------------
local function getNSEW(widget)
    NS = ""
    EW = ""
    if widget.service.GPSLat > 0 then
      NS = "N"
    else
      NS = "S"
    end

    if widget.service.GPSLon > 0 then
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
    local LatD,LatM,LatS = dec2deg(widget.service.GPSLat)
    local LongD,LongM,LongS = dec2deg(widget.service.GPSLon)
    local NS,EW = getNSEW(widget)
    local DMSLatString  = math.abs(LatD).."°"..LatM.."'"..string.format("%.1f\"",LatS)..NS
    local DMSLongString = math.abs(LongD).."°"..LongM.."'"..string.format("%.1f\"",LongS)..EW
    return DMSLatString , DMSLongString
end

----------------------------------------------------------------------------------------------------------------------
local key = "gpsSensors"

local function create()
    local libservice = libservice or loadService()
    g_mahRe2Service = g_mahRe2Service or libservice.new()

    local widget = {
        service = g_mahRe2Service,
        displayState = 0,
        gps_max_speed = 0,
        GPSLat = "",
        GPSLon = ""
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
            displayString = widget.service.gps_max_speed .. "mph"
        else
            displayTitle = "GPS"
            if system.getSource({ name="GPS", options=OPTION_LATITUDE }):state() == false or
                    widget.service.GPSLat == nil or widget.service.GPSLon == nil or
                    widget.service.GPSLat < -90 or widget.service.GPSLat > 90 or
                    widget.service.GPSLon < -180 or widget.service.GPSLon > 180 then
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
    widget.service.reset_if_needed()
    widget.service.gps_bg_func()
    lcd.invalidate()
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
    system.registerWidget({ key = "gsens", name = "GPS Sensors", create = create, paint = paint, wakeup = wakeup,
                            persistent = true, event=event })
end

return { init = init }
