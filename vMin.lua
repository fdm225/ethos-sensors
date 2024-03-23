-- define default values

function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

local function paintCell(cellIndex, cellData, x, y)
    lcd.color(lcd.RGB(0xF8, 0xB0, 0x38))
    lcd.drawText(x, y, "C" .. cellIndex .. " : ", LEFT)

    local text_w, text_h = lcd.getTextSize("C" .. cellIndex .. " : ")

    if cellData.low < 3.7 then lcd.color(RED) else lcd.color(WHITE) end
    x = x + text_w
    lcd.drawText(x, y, cellData.low, LEFT)

    lcd.color(BLACK)
    text_w, text_h = lcd.getTextSize(cellData.low)
    x = x + text_w
    lcd.drawText(x, y, "/", LEFT)

    if cellData.current < 3.7 then lcd.color(RED) else lcd.color(WHITE) end
    text_w, text_h = lcd.getTextSize("/")
    x = x + text_w
    lcd.drawText(x, y, cellData.current, LEFT)
end

local function paint4th(widget)
    -- 1/4 scree 388x132 (supported)
    function paint2Cells(widget)
        local y = 5
        local w, h = lcd.getWindowSize()
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        for i, v in ipairs(widget.service.vMinValues) do
            local vLabel = "C" .. i .. " : " .. v.low .. "/" .. v.current
            local x = w / 2 - string.len(vLabel) * font_w
            paintCell(i, v, x, y)
            y = y + font_h
        end
    end

    function paint4Cells(widget, startIndex)
        local y = 5
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        local endIndex = startIndex + 3
        if endIndex > #widget.service.vMinValues then endIndex = #widget.service.vMinValues end
        --print("endIndex: " .. endIndex)
        for i=startIndex, endIndex, 2 do
            local vLabel = "C" .. i .. " : " .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 20
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w *2 + 15
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end
            y = y + font_h
        end
    end

    function paintAllCells(widget)
        local y = 5
        lcd.font(FONT_S)
        local font_w, font_h = lcd.getTextSize(" ")
        for i=1, #widget.service.vMinValues, 3 do
            --print("i: " .. i)
            local vLabel = "C" .. i .. ":" .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 10
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x + string.len(vLabel) * font_w + 50
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end

            if i+2 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w + 50
                paintCell(i+2, widget.service.vMinValues[i+2], x, y)
            end
            y = y + font_h
        end
    end

    local y = 5
    local w, h = lcd.getWindowSize()
    if #widget.service.vMinValues == 2 then
        paint2Cells(widget)
    elseif #widget.service.vMinValues == 3 or #widget.service.vMinValues == 4 then
        paint4Cells(widget, 1)
    elseif #widget.service.vMinValues >= 5 then
        if widget.displayState == 0 then
            paintAllCells(widget)
        elseif widget.displayState == 1 then
            paint4Cells(widget, 1)
        else
            paint4Cells(widget, 5)
        end
    end
end

local function paint6th(widget)
    -- 1/4 scree 388x132 (supported)

    function paint2Cells(widget)
        local y = 5
        local w, h = lcd.getWindowSize()
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        for i, v in ipairs(widget.service.vMinValues) do
            local vLabel = "C" .. i .. " : " .. v.low .. "/" .. v.current
            local x = w / 2 - string.len(vLabel) * font_w
            paintCell(i, v, x, y)
            y = y + font_h
        end
    end

    function paint4Cells(widget, startIndex)
        local y = 5
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        local endIndex = startIndex + 3
        if endIndex > #widget.service.vMinValues then endIndex = #widget.service.vMinValues end
        print("endIndex: " .. endIndex)
        for i=startIndex, endIndex, 2 do
            local vLabel = "C" .. i .. " : " .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 20
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w *2 + 15
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end
            y = y + font_h
        end
    end

    function paintAllCells(widget)
        local y = 5
        lcd.font(FONT_S)
        local font_w, font_h = lcd.getTextSize(" ")
        for i=1, #widget.service.vMinValues, 3 do
            --print("i: " .. i)
            local vLabel = "C" .. i .. ":" .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 10
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x + string.len(vLabel) * font_w + 50
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end

            if i+2 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w + 50
                paintCell(i+2, widget.service.vMinValues[i+2], x, y)
            end
            y = y + font_h
        end
    end

    local y = 5
    local w, h = lcd.getWindowSize()
    if #widget.service.vMinValues == 2 then
        paint2Cells(widget)
    elseif #widget.service.vMinValues == 3 or #widget.service.vMinValues == 4 then
        paint4Cells(widget, 1)
    elseif #widget.service.vMinValues >= 5 then
        if widget.displayState == 0 then
            paintAllCells(widget)
        elseif widget.displayState == 1 then
            paint4Cells(widget, 1)
        else
            paint4Cells(widget, 5)
        end
    end
end

local function paint9th(widget)
    -- 1/9 screen 388x132 (supported)

    function paint2Cells(widget)
        local y = 5
        local w, h = lcd.getWindowSize()
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        for i, v in ipairs(widget.service.vMinValues) do
            local vLabel = "C" .. i .. " : " .. v.low .. "/" .. v.current
            local x = w / 2 - string.len(vLabel) * font_w
            x=0
            paintCell(i, v, x, y)
            y = y + font_h
        end
    end

    function paint4Cells(widget, startIndex)
        local y = 5
        lcd.font(FONT_L)
        local font_w, font_h = lcd.getTextSize(" ")
        local endIndex = startIndex + 3
        if endIndex > #widget.service.vMinValues then endIndex = #widget.service.vMinValues end
        print("endIndex: " .. endIndex)
        for i=startIndex, endIndex, 2 do
            local vLabel = "C" .. i .. " : " .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 20
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w *2 + 15
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end
            y = y + font_h
        end
    end

    function paintAllCells(widget)
        local y = 5
        lcd.font(FONT_S)
        local font_w, font_h = lcd.getTextSize(" ")
        for i=1, #widget.service.vMinValues, 3 do
            --print("i: " .. i)
            local vLabel = "C" .. i .. ":" .. widget.service.vMinValues[i].low .. "/" .. widget.service.vMinValues[i].current
            local x = 10
            paintCell(i, widget.service.vMinValues[i], x, y)
            if i+1 <= #widget.service.vMinValues then
                x = x + string.len(vLabel) * font_w + 50
                paintCell(i+1, widget.service.vMinValues[i+1], x, y)
            end

            if i+2 <= #widget.service.vMinValues then
                x = x+1 + string.len(vLabel) * font_w + 50
                paintCell(i+2, widget.service.vMinValues[i+2], x, y)
            end
            y = y + font_h
        end
    end

    local y = 5
    local w, h = lcd.getWindowSize()
    if #widget.service.vMinValues == 2 then
        paint2Cells(widget)
    elseif #widget.service.vMinValues == 3 or #widget.service.vMinValues == 4 then
        paint4Cells(widget, 1)
    elseif #widget.service.vMinValues >= 5 then
        if widget.displayState == 0 then
            paintAllCells(widget)
        elseif widget.displayState == 1 then
            paint4Cells(widget, 1)
        else
            paint4Cells(widget, 5)
        end
    end
end

----------------------------------------------------------------------------------------------------------------------
local name = "Voltage Sag"
local key = "vMin"

local function create()
    local libservice = libservice or loadService()
    g_mahRe2Service = g_mahRe2Service or libservice.new()
    
    local libscheduler = libscheduler or loadSched()
    g_scheduler = g_scheduler or libscheduler.new()
    widget = {
        service = g_mahRe2Service,
        --scheduler = g_scheduler,
        displayState = 0,
    }
    return widget
end

local function paint(widget)

    local w, h = lcd.getWindowSize()
    local y = 0
    -- print("w: " .. w .. " h: " .. h)
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

local function wakeup(widget)
    widget.service.bg_func()
end

local function configure(widget)
    line = form.addLine("lipoSensor")
    form.addSourceField(line, nil,
            function() return widget.service.lipoSensor end,
            function(value) widget.service.lipoSensor = value end
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
    widget.service.resetSwitch = storage.read("resetSwitch")
end

local function write(widget)
    storage.write("lipoSensor" ,widget.service.lipoSensor)
    storage.write("resetSwitch", widget.service.resetSwitch)
end

local function event(widget, category, value, x, y)

    local function event_end_debounce()
        widget.service.scheduler.remove('touch_event')
        print("event_end_debounce")
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
