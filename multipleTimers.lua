
local function secondsToClock(seconds)
  local seconds = tonumber(seconds)

  if seconds == nil or seconds == 0 then
    return "00:00:00";
  else
    hours = string.format("%02.f", math.floor(seconds/3600));
    mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
    secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
    return hours..":"..mins..":"..secs
  end
end

----------------------------------------------------------------------------------------------------------------------
--local name = "Multiple Timers"
local key = "timers"


local function name(widget)
    local name = "Multiple Timers"
    name = "Throttle/Total/Flight"
    if widget ~= nil then

        if widget.timer1.name ~= "" then
            name = widget.timer1.name
        end

        if widget.timer2.name ~= "" then
            name = windowTitle .. "/" .. widget.timer2.name
        end

        if widget.timer3.name ~= "" then
            name = windowTitle .. "/" .. widget.timer3.name
        end

    end

    return name
end

local function create()
    local widget = {
        timer1 = {
            input = nil,
            value = '00:00:00',
            name = ""
        },
        timer2 = {
            input = nil,
            value = '00:00:00',
            name = ""
        },
        timer3 = {
            input = nil,
            value = '00:00:00',
            name = ""
        },
        displayNames = false
    }
    return widget
end

local function paint(widget)

    local function paintTimer(widget, v, w, y)
        local displayString = v.value
        if widget.displayNames then
            displayString = v.name .. " " .. displayString
        end

        local text_w, text_h = lcd.getTextSize(displayString)
        local x = (w - text_w) / 2

        lcd.drawText(x, y, displayString )
        y = y + text_h
        return y
    end

    local w, h = lcd.getWindowSize()
    lcd.font(FONT_XL)
    local y = 10
    --for i, v in pairs(widget) do
    --    if type(v) == 'table' then
    --        local displayString = v.value
    --        if widget.displayNames then
    --            displayString = v.name .. " " .. displayString
    --        end
    --
    --        local text_w, text_h = lcd.getTextSize(displayString)
    --        local x = (w - text_w) / 2
    --
    --        lcd.drawText(x, y, displayString )
    --        y = y + text_h
    --    end
    --end

    y = paintTimer(widget, widget.timer1, w, y)
    y = paintTimer(widget, widget.timer2, w, y)
    y = paintTimer(widget, widget.timer3, w, y)

end

local function wakeup(widget)
    local updateNeeded = false
    if widget.timer1.input ~= nil then
        local t1 = secondsToClock(widget.timer1.input:value())
        if t1 ~= widget.timer1.value then
            widget.timer1.value = t1
            widget.timer1.name = widget.timer1.input:name()
            --print(widget.timer1.name .. " "  .. t1)
        end
        updateNeeded = true
    end

    if widget.timer2.input ~= nil then
        local t2 = secondsToClock(widget.timer2.input:value())
        if t2 ~= widget.timer2.value then
            widget.timer2.value = t2
            widget.timer2.name = widget.timer2.input:name()
            --print(widget.timer2.name .. " "  .. t2)
        end
        updateNeeded = true
    end

    if widget.timer3.input ~= nil then
        local t3 = secondsToClock(widget.timer3.input:value())
        if t3 ~= widget.timer3.value then
            widget.timer3.value = t3
            widget.timer3.name = widget.timer3.input:name()
            --print(widget.timer3.name .. " "  .. t3)
        end
        updateNeeded = true
    end

    if updateNeeded then
        lcd.invalidate()
    end
end

local function configure(widget)
    local line = form.addLine("timer1")
    form.addSourceField(line, nil,
            function() return widget.timer1.input end,
            function(value) widget.timer1.input = value end
    )

    line = form.addLine("timer2")
    form.addSourceField(line, nil,
            function() return widget.timer2.input end,
            function(value) widget.timer2.input = value end
    )

    line = form.addLine("timer3")
    form.addSourceField(line, nil,
            function() return widget.timer3.input end,
            function(value) widget.timer3.input = value end
    )

    line = form.addLine("Display Timer Names")
    form.addBooleanField(line, nil,
            function() return widget.displayNames end,
            function(value) widget.displayNames = value end
    )

end

local function read(widget)
    widget.timer1.input = storage.read("timer1")
    widget.timer2.input = storage.read("timer2")
    widget.timer3.input = storage.read("timer3")
    widget.displayNames = storage.read("displayNames") or false
end

local function write(widget)
    storage.write("timer1" ,widget.timer1.input)
    storage.write("timer2", widget.timer2.input)
    storage.write("timer2", widget.timer3.input)
    storage.write("displayNames", widget.displayNames)
end

local function event(widget, category, value, x, y)

    local function event_end_debounce()
        widget.service.scheduler.remove('touch_event')
        --print("event_end_debounce")
    end

    --print("Event received:", category, value, x, y)
    if category == EVT_KEY and value == KEY_ENTER_BREAK or category == EVT_TOUCH then
        local debounced = widget.service.scheduler.check('touch_event')
        if debounced == nil then
            print("debounced: nil")
        else
            print("debounced: " .. tostring(debounced))
        end

        if (debounced == nil or debounced == true)  then
            widget.service.scheduler.add('touch_event', false, 1, event_end_debounce) -- add the touch event to the scheduler
            widget.service.scheduler.clear('touch_event') -- set touch event to false in the scheduler so we don't run again
            widget.displayState = (widget.displayState + 1) % 3
            print("touch event: " .. widget.displayState)
            lcd.invalidate()
        end
        return true
    else
        return false
    end
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true, event=event })
end

return { init = init }
