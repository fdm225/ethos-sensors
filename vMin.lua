-- define default values

local function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

local function get_voltage_sum(service)
    displayString = "Sensor Lost"
    if service ~= nil and service.vMinValues ~= nil and #service.vMinValues > 0 then
        local min_volts = 0
        local current_volts = 0
        for k,v in ipairs(service.vMinValues) do
            min_volts = min_volts + service.vMinValues[k].low
            current_volts = current_volts + service.vMinValues[k].current
        end
        displayString = string.format("%.2fv", min_volts) .. "/" .. string.format("%.2fv", current_volts)
    end
    return displayString
end

local function paintCell(cellIndex, cellData, x, y)
    lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y, "C" .. cellIndex .. " : ", LEFT)

    local text_w, text_h = lcd.getTextSize("C" .. cellIndex .. " : ")

    if cellData.low < 3.7 then lcd.color(RED) else lcd.color(WHITE) end
    x = x + text_w
    lcd.drawText(x, y, string.format("%.2f",cellData.low), LEFT)

    lcd.color(BLACK)
    text_w, text_h = lcd.getTextSize(string.format("%.2f",cellData.low))
    x = x + text_w
    lcd.drawText(x, y, "/", LEFT)

    if cellData.current < 3.7 then lcd.color(RED) else lcd.color(WHITE) end
    text_w, text_h = lcd.getTextSize("/")
    x = x + text_w
    lcd.drawText(x, y, string.format("%.2f", cellData.current), LEFT)
end

local function paint2Cells(widget, x_start)
    local w, h = lcd.getWindowSize()
    lcd.font(FONT_XL)
    local font_w, font_h = lcd.getTextSize(" ")
    local y = h/2 - font_h
    for i, v in ipairs(widget.vMinValues) do
        local vLabel = "C" .. i .. " : " .. v.low .. "/" .. v.current
        local x = x_start or w / 2 - string.len(vLabel) * font_w * 1.5
        paintCell(i, v, x, y)
        y = y + font_h
    end
end

local function paint4Cells(widget, startIndex, fontSize, x1)
    lcd.font(fontSize)
    local w, h = lcd.getWindowSize()
    local vLabel = "C1 : 4.00/4.00 C2 : 4.00/4.00"
    local font_w_2x, font_h = lcd.getTextSize(vLabel)
    local y = (h - font_h *2)/2
    local endIndex = startIndex + 3
    
    if endIndex > #widget.vMinValues then endIndex = #widget.vMinValues end
    --print("endIndex: " .. endIndex)

    for i=startIndex, endIndex, 2 do
        local x = (w - font_w_2x) / 2
        vLabel = "C" .. i .. " : " .. widget.vMinValues[i].low .. "/" .. widget.vMinValues[i].current .. " "
        local strW, strH = lcd.getTextSize(vLabel)
        --print("strW: " .. strW)
        local cw, ch = lcd.getTextSize(" ")
        --print("cw: " .. cw)
        paintCell(i, widget.vMinValues[i], x, y)
        if i+1 <= #widget.vMinValues then
            x = 195
            paintCell(i+1, widget.vMinValues[i+1], x, y)
        end
        y = y + font_h
    end
end

local function paint6Cells(widget, startIndex, fontSize)
    lcd.font(fontSize)
    local w, h = lcd.getWindowSize()
    local vLabel = "C1 : 4.00/4.00 C2 : 4.00/4.00"
    local font_w_2x, font_h = lcd.getTextSize(vLabel)
    local y = (h - font_h * 3)/2
    local endIndex = startIndex + 4

    if endIndex > #widget.vMinValues then endIndex = #widget.vMinValues end
    --print("endIndex: " .. endIndex)

    for i=startIndex, endIndex, 2 do
        local x = (w - font_w_2x) / 2
        vLabel = "C" .. i .. " : " .. widget.vMinValues[i].low .. "/" .. widget.vMinValues[i].current .. " "
        paintCell(i, widget.vMinValues[i], x, y)
        if i+1 <= #widget.vMinValues then
            x = 205
            paintCell(i+1, widget.vMinValues[i+1], x, y)
        end
        y = y + font_h
    end
end

local function paintAllCells(widget, columns)
    local y = 5
    lcd.font(FONT_S)
    local font_w, font_h = lcd.getTextSize(" ")
    for i=1, #widget.vMinValues, columns do
        --print("i: " .. i)
        local vLabel = "C" .. i .. ":" .. widget.vMinValues[i].low .. "/" .. widget.vMinValues[i].current
        local x = 10
        paintCell(i, widget.vMinValues[i], x, y)
        if i+1 <= #widget.vMinValues then
            x = x + string.len(vLabel) * font_w + 50
            paintCell(i+1, widget.vMinValues[i+1], x, y)
        end

        if i+2 <= #widget.vMinValues then
            x = x+1 + string.len(vLabel) * font_w + 50
            paintCell(i+2, widget.vMinValues[i+2], x, y)
        end
        y = y + font_h
    end
end

local function paint4th(widget)
    -- 1/4 scree 388x132 (supported)

    local y = 5
    local w, h = lcd.getWindowSize()
    if #widget.vMinValues == 2 then
        paint2Cells(widget)
    elseif #widget.vMinValues == 3 or #widget.vMinValues == 4 then
        paint4Cells(widget, 1, FONT_L, 20)
    elseif #widget.vMinValues == 5 or #widget.vMinValues == 6 then
        paint6Cells(widget, 1, FONT_L)
    elseif #widget.vMinValues >= 7 then
        if widget.displayState == 0 then
            paintAllCells(widget, 3)
        elseif widget.displayState == 1 then
            paint4Cells(widget, 1, FONT_L, 20)
        else
            paint4Cells(widget, 5, FONT_L, 20)
        end
    end
end

local function paint6th(widget)
    -- 1/4 scree 300x66 (supported)

    local y = 5
    local w, h = lcd.getWindowSize()
    if #widget.vMinValues == 2 then
        paint2Cells(widget)
    elseif #widget.vMinValues == 3 or #widget.vMinValues == 4 then
        paint4Cells(widget, 1, FONT_L, 20)
    elseif #widget.vMinValues >= 5 then
        if widget.displayState == 0 then
            paintAllCells(widget, 3)
        elseif widget.displayState == 1 then
            paint4Cells(widget, 1, FONT_L, 20)
        else
            paint4Cells(widget, 5, FONT_L, 20)
        end
    end
end

local function paint9th(widget)
    -- 1/9 screen 256x78 (supported)
    lcd.font(FONT_XL)
    local w, h = lcd.getWindowSize()
    local displayString = "---/---"
    if widget ~= nil then
        --print("widget.displayCell: " .. widget.displayCell)
        if widget.displayCell == 0 then
            displayString = get_voltage_sum(widget)
        else
            local min_volts = widget.vMinValues[widget.displayCell].low
            local current_volts = widget.vMinValues[widget.displayCell].current
            displayString = string.format("C%d : %.2fv/%.2fv",widget.displayCell, min_volts, current_volts)
        end
    end
    local font_w, font_h = lcd.getTextSize(displayString)
    --local x = (w - font_w)/2
    local x = (w - font_w) / 2
    local y = (h - font_h)/2

    if system.getSource("LiPo") == nil or system.getSource("LiPo"):state() == false then
        lcd.color(RED)
    else
        lcd.color(WHITE)
    end

    lcd.drawText(x, y, displayString)
    lcd.invalidate()
end

local function reset_if_needed(service)
        -- test if the reset switch is toggled, if so then reset all internal flags
        --print("service.reset_if_needed")
        if service.resetSwitch then
            -- Update switch position
            local debounced = service.scheduler.check('reset_sw')
            --print("debounced: " .. tostring(debounced))
            local resetSwitchValue = service.resetSwitch:value()
            if (debounced == nil or debounced == true) and -100 ~= resetSwitchValue then
                -- reset switch
                service.scheduler.add('reset_sw', false, 2) -- add the reset switch to the scheduler
                --print("reset start task: " .. tostring(service.scheduler.tasks['reset_sw'].ready))
                service.scheduler.clear('reset_sw') -- set the reset switch to false in the scheduler so we don't run again
                --print("reset task: " .. tostring(service.scheduler.tasks['reset_sw'].ready))
                --print("reset switch toggled - debounced: " .. tostring(debounced))
                --print("reset event")

                service.scheduler.reset()

                -- vMin stuff here
                service.vMinValues = {}

            elseif -100 == resetSwitchValue then
                --print("reset switch released")
                service.scheduler.remove('reset_sw')
            end
        end
    end

local function vMin_bg_func(service)
    if service.lipoSensor ~= nil then
        local sensor = system.getSource(service.lipoSensor:name())
        local updateRequired = false
        -- print("\n")
        if sensor ~= nil then

            --local lcellscount = system.getSource({
            --      category=lsource:category(),
            --      member=lsource:member(),
            --    options=OPTION_CELL_COUNT
            --        })
            --        print(lcellscount:value())
            --local gpsSrc = system.getSource({name="GPS", category=CATEGORY_TELEMETRY_SENSOR })
            --local gpsLat = system.getSource({member = gpsSrc, category=CATEGORY_TELEMETRY_SENSOR, options=OPTION_LONGITUDE})
            local lipoSensor = system.getSource({name="LiPo", category=CATEGORY_TELEMETRY_SENSOR })
            local numCells = system.getSource({member = lipoSensor:member(), category=CATEGORY_TELEMETRY_SENSOR, options=OPTION_CELL_COUNT})

            -- print("numCells: " .. numCells:value() .. "\n")
            for cell = 1, numCells:value() do
                local cellSensor = system.getSource({member = lipoSensor:member(), category=CATEGORY_TELEMETRY_SENSOR, options=OPTION_CELL_INDEX(cell)})
                -- local cellVoltage = sensor:value(OPTION_CELL_INDEX(cell))
                local cellVoltage = cellSensor:value()
                -- print("cell: " .. cell .. " : " .. cellVoltage .. "\n")
                if service.vMinValues[cell] == nil or service.vMinValues[cell].current ~= cellVoltage then
                    updateRequired = true
                    if service.vMinValues[cell] == nil then
                        service.vMinValues[cell] = {}
                    end
                    service.vMinValues[cell].current = cellVoltage
                    if service.vMinValues[cell].low == nil or service.vMinValues[cell].low > cellVoltage then
                        service.vMinValues[cell].low = cellVoltage
                    end
                end
            end

            if updateRequired then
                lcd.invalidate()
            end
        end
    end

end

----------------------------------------------------------------------------------------------------------------------
local name = "Voltage Sag"
local key = "vMin"

local function create()
    local libscheduler = loadSched()

    local widget = {
        scheduler = libscheduler.new(),
         -- common stuff here
        resetSwitch = nil, -- switch to reset script, usually same switch to reset timers

        -- vMin stuff below here
        vMinValues = {},
        lipoSensor = nil,
        displayState = 0,
        displayCell = 0
    }
    return widget
end

local function paint(widget)

    local w, h = lcd.getWindowSize()
    -- print("w: " .. w .. " h: " .. h)

    if widget == nil or widget == nil or #widget.vMinValues == 0 then
        lcd.font(FONT_L)
        local dString = "Sensor Lost"
        local font_w, font_h = lcd.getTextSize(dString)
        --local x = w/2 - string.len(dString)
        local x = (w - font_w) / 2
        local y = (h - font_h) / 2
        lcd.drawText(x, y, dString, LEFT)
    else
        if w == 388 and h == 132 then
            paint4th(widget)
        elseif w == 300 and h == 66 then
            paint6th(widget)
        elseif w == 256 and h == 78 then
            paint9th(widget)
        else
            paint6th(widget)
        end
    end
end

local function wakeup(widget)
    -- test if the reset switch is toggled, if so then reset all internal flags
    widget.scheduler.tick()
    reset_if_needed(widget)
    vMin_bg_func(widget)
end

local function configure(widget)
    line = form.addLine("lipoSensor")
    form.addSourceField(line, nil,
            function() return widget.lipoSensor end,
            function(value) widget.lipoSensor = value end
    )

    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.resetSwitch
    end, function(value)
        widget.resetSwitch = value
    end)
end

local function read(widget)
    widget.lipoSensor = storage.read("lipoSensor") or system.getSource("LiPo")
    widget.resetSwitch = storage.read("resetSwitch") or system.getSource("SH↓")
end

local function write(widget)
    storage.write("lipoSensor" ,widget.lipoSensor)
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
            widget.displayState = (widget.displayState + 1) % 3
            widget.displayCell = (widget.displayCell + 1) % (#widget.vMinValues + 1)
            --print("touch event: " .. widget.displayCell .. " size: " .. #widget.vMinValues)
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
