-- define default values
local sfDefaultValues = { 4000, 4500, 5000, 5200, 6000, 8200 }
local defaultPackCapacityMah = 5000

local function loadSched()
    if not libSCHED then
        -- Loadable code chunk is called immediately and returns libGUI
        libSCHED = loadfile("sensorLib/libscheduler.lua")
    end
    return libSCHED()
end

local function paint4th(widget)
    -- 1/4 scree 388x132 (supported)
    local y = 0
    local w, h = lcd.getWindowSize()
    local color = lcd.RGB(0xF8, 0xB0, 0x38)
    lcd.font(FONT_XS)
    local capicityLabel = "Capacity: " .. tostring(widget.capacityFullMah)
    lcd.drawText(w, y, capicityLabel, RIGHT)

    local text_w, text_h = lcd.getTextSize("")
    y = y + text_h + 5
    lcd.font(FONT_XXL)
    local capRemainLabel = math.floor(widget.capacityRemainingMah) .. " mAh"
    lcd.drawText(w / 2, y, capRemainLabel, CENTERED)

    local text_w,
    text_h = lcd.getTextSize("")
    y = y + text_h + 5
    local box_top = y
    local box_height = h - y - 4
    local box_left = 4
    local box_width = w - 8

    -- Gauge background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge Percentage to width calculation
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.batteryRemainingPercent) + 2)
    -- Gauge bar horizontal
    lcd.color(color)
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left + 1, box_top + 1, box_width - 2, box_height - 2)

    -- Gauge percentage
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.batteryRemainingPercent) .. "%", CENTERED)

end

local function paint6th(widget)
    -- 1/4 scree 388x132 (supported)
    local y = 0
    local w, h = lcd.getWindowSize()
    local color = lcd.RGB(0xF8, 0xB0, 0x38)


    --lcd.font(FONT_XXL)
    --local capRemainLabel = math.floor(widget.capacityRemainingMah) .. " mAh"
    --lcd.drawText(w / 2, y, capRemainLabel, CENTERED)
    --
    --local text_w, text_h = lcd.getTextSize("")
    --y = y + text_h + 5

    local box_top = y
    local box_height = h - y - 4
    local box_left = 4
    local box_width = w - 8

    -- Gauge background
    lcd.color(lcd.RGB(200, 200, 200))
    lcd.drawFilledRectangle(box_left, box_top, box_width, box_height)

    -- Gauge Percentage to width calculation
    local gauge_width = math.floor((((box_width - 2) / 100) * widget.batteryRemainingPercent) + 2)
    -- Gauge bar horizontal
    lcd.color(color)
    lcd.drawFilledRectangle(box_left, box_top, gauge_width, box_height)

    -- Gauge frame outline
    lcd.color(lcd.RGB(0, 0, 0))
    lcd.drawRectangle(box_left, box_top, box_width, box_height)
    lcd.drawRectangle(box_left + 1, box_top + 1, box_width - 2, box_height - 2)

    -- Gauge percentage
    lcd.font(FONT_XS)
    local padding = "  "
    y = y + 2
    local capicityLabel = math.floor(widget.capacityRemainingMah) .. "/" .. widget.capacityFullMah .. padding

    if system.getSource("Consumption") == nil or system.getSource("Consumption"):state() == false then
        lcd.color(RED)
    else
        lcd.color(BLACK)
    end

    lcd.drawText(w, y, capicityLabel, RIGHT)
    --
    lcd.font(FONT_XL)
    local text_w, text_h = lcd.getTextSize("")
    --y = y + text_h + 5
    --lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.capacityRemainingMah).."/"..widget.capacityFullMah, CENTERED)
    lcd.drawText(box_left + box_width / 2, box_top + (box_height - text_h) / 2 + 4, math.floor(widget.batteryRemainingPercent) .. "%", CENTERED)

end

local function paint9th(widget)
    paint6th(widget)
end


local function playPercentRemaining(service)
        -- Announces percent remaining using the accompanying sound files.
        -- Announcements ever 10% change when percent remaining is above 10 else
        --	every 5%
        local myModVal
        if service.batteryRemainingPercent < 10 then
            myModVal = service.batteryRemainingPercent % 5
        else
            myModVal = service.batteryRemainingPercent % 10
        end

        if myModVal == 0 and service.batteryRemainingPercent ~= service.batteryRemainingPercentPlayed then
            system.playNumber(service.batteryRemainingPercent, UNIT_PERCENT, 0)
            system.playFile(service.soundDirPath .. "remaining.wav")
            service.batteryRemainingPercentPlayed = service.batteryRemainingPercent    -- do not keep playing the same sound file over and
        end

        local rssi = system.getSource("RSSI")
        if service.batteryRemainingPercent <= 0 and service.atZeroPlayedCount < service.playAtZero
                and rssi ~= nil and rssi:value() > 0 then
            --print(service.batteryRemainingPercent, service.atZeroPlayedCount)
            system.playFile(service.soundDirPath .. "BatNo.wav")
            service.atZeroPlayedCount = service.atZeroPlayedCount + 1
        elseif service.atZeroPlayedCount == service.PlayAtZero and service.batteryRemainingPercent > 0 then
            service.atZeroPlayedCount = 0
        end
    end

local function initializeValues(service)
        if service and service.capacityFullMah ~= nil then
            --mahRe2 stuff here
            service.capacityReservedMah = service.capacityFullMah * (100 - service.capacityReservePercent) / 100
            service.capacityRemainingMah = service.capacityReservedMah
            service.batteryRemainingPercent = 0
            service.atZeroPlayedCount = 0
            service.capacityFullUpdated = false
        end
    end

local function reset_if_needed(service)
        -- test if the reset switch is toggled, if so then reset all internal flags
        --print("service.reset_if_needed")
        if service.resetSwitch ~= nil and type(service.resetSwitch) ~= "string" then
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
                initializeValues(service)

            elseif -100 == resetSwitchValue then
                --print("reset switch released")
                service.scheduler.remove('reset_sw')
            end
        end
    end

local function mahRe2_bg_func(service)
        -- check the special function buttons to see if there is a change in pack capacity
        if service.useSpecialFunctionButtons then
            for i = 0, 6, 1 do
                local me = system.getSource({ category = CATEGORY_FUNCTION_SWITCH, member = i })
                local value = me:value()
                if (value == 1024 or value == 100) and service.sfCapacityMah[i + 1] ~= service.capacityFullMah then
                    service.capacityFullMah = service.sfCapacityMah[i + 1]
                    service.capacityFullUpdated = true
                    system.playNumber(service.capacityFullMah, UNIT_MILLIAMPERE_HOUR, 0)
                    break
                end
            end
        end

        -- Check in battery capacity was changed
        if service.capacityFullUpdated then
            initializeValues(service)
        end

        service.consumptionSensor = system.getSource("Consumption")
        if service.consumptionSensor ~= nil and service.consumptionSensor:value() ~= service.capacityUsedMah  and service.capacityUsedMah ~= nil then
            --service.capacityUsedMah = math.floor(service.currentSensor:value() * 1000 * (os.clock() - service.startTime) / 3600)
            service.capacityUsedMah = service.consumptionSensor:value()
            --print("capacityUsedMah: " .. service.capacityUsedMah)
            if (service.capacityUsedMah == 0) and service.canCallInitFuncAgain then
                -- service.capacityUsedMah == 0 when Telemetry has been reset or model loaded
                -- service.capacityUsedMah == 0 when no battery used which could be a long time
                --	so don't keep calling the service.initializeValues unnecessarily.

                initializeValues(service)
                service.canCallInitFuncAgain = false
            elseif service.capacityUsedMah ~= nil and service.capacityUsedMah > 0 then
                -- Call init function again when Telemetry has been reset
                service.canCallInitFuncAgain = true
            end
            service.capacityRemainingMah = service.capacityReservedMah - service.capacityUsedMah
        end -- mAhSensor ~= ""

        -- Update battery remaining percent
        if service.capacityReservedMah > 0 then
            service.batteryRemainingPercent = math.floor((service.capacityRemainingMah / service.capacityFullMah) * 100)
        end

        playPercentRemaining(service)
        lcd.invalidate()
    end

----------------------------------------------------------------------------------------------------------------------
local name = "mahRe2"
local key = "mahRe2"

local function create()
    local libscheduler = loadSched()
    widget = {
        scheduler = libscheduler.new(),
        resetSwitch = "",
        soundDirPath = "/scripts/sensorLib/sounds/", -- where you put the sound files,
        consumptionSensor = system.getSource("Consumption"),

        -- mahRe2 misc
        canCallInitFuncAgain = false,
        useSpecialFunctionButtons = true,

        -- mahRe2 capacity variables in mAh values
        sfCapacityMah = { 4000, 4500, 5000, 5200, 6000, 8200 }, -- list of capacity values assigned to the special function buttons
        capacityFullMah = 5000, -- total pack capacity
        capacityFullUpdated = false,
        capacityUsedMah = 0, -- total mAh used since reset
        capacityReservedMah = 0, -- adjusted capacity based on reserved percent in mAh
        capacityRemainingMah = 0, -- remaining battery based on capacityRemainingMah

        -- mahRe2 capacity variables in percentages
        capacityReservePercent = 20, -- Reserve Capacity: Remaining % Displayed = Calculated Remaining % - Reserve %
        batteryRemainingPercent = 0,

        -- mahRe2 Announcements
        announcePercentRemaining = true,
        batteryRemainingPercentFileName = 0, -- updated in service.PlayPercentRemaining
        batteryRemainingPercentPlayed = 0, -- updated in service.PlayPercentRemaining
        atZeroPlayedCount = 0, -- updated in initializeValues, service.PlayPercentRemaining
        playAtZero = 1,

    }
    return widget
end

local function paint(widget)

    local w, h = lcd.getWindowSize()
    if w == 388 and h == 132 then
        paint4th(widget)
    elseif w == 300 and h == 66 then
        paint6th(widget)
    elseif w == 256 and h == 78 then
        paint9th(widget)
    else
        --print("w: " .. w .. " h: " .. h)
        paint4th(widget)
    end

end

local function wakeup(widget)
    widget.scheduler.tick()
    reset_if_needed(widget)
    mahRe2_bg_func(widget)
end

local function configure(widget)

    --line = form.addLine("mAh")
    --form.addSourceField(line, nil, function() return widget.mAh end, function(value) widget.mah = value end)


    -- reset switch position
    line = form.addLine("Reset Switch")
    form.addSwitchField(line, form.getFieldSlots(line)[0], function()
        return widget.resetSwitch
    end, function(value)
        widget.resetSwitch = value
    end)
    --resetSwitch:default("SF╚")


    -- Battery pack capacity
    line = form.addLine("Capacity")
    local capacity = form.addNumberField(line, nil, 100, 10000,
            function()
                return widget.capacityFullMah
            end,
            function(value)
                widget.capacityFullMah = value
                widget.capacityFullUpdated = true
            end)
    capacity:suffix("mAh")
    capacity:default(5000)
    capacity:step(100)

    if type(form.beginExpansionPanel) == 'function' then
        form.beginExpansionPanel("Special Function Buttons")
        line = form.addLine("Use Special Function Buttons")
        form.addBooleanField(line, form.getFieldSlots(line)[0],
                function() return widget.useSpecialFunctionButtons end,
                function(value) widget.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity")
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.sfCapacityMah[i] end,
                    function(value) widget.sfCapacityMah[i] = value end
            )
            capacity:suffix("mAh")
            capacity:default(sfDefaultValues[i])
            capacity:step(100)
        end
        form.endExpansionPanel()
    else
        panel = form.addExpansionPanel("Special Function Buttons")
        line = form.addLine("Use Special Function Buttons", panel)
        form.addBooleanField(line, form.getFieldSlots(line)[0],
                function() return widget.useSpecialFunctionButtons end,
                function(value) widget.useSpecialFunctionButtons = value end
        )

        for i = 1, 6, 1 do
            line = form.addLine("SF" .. i .. " Capacity", panel)
            local capacity = form.addNumberField(line, nil, 100, 10000,
                    function() return widget.sfCapacityMah[i] end,
                    function(value) widget.sfCapacityMah[i] = value end,
                    panel
            )
            capacity:suffix("mAh")
            capacity:default(sfDefaultValues[i])
            capacity:step(100)
        end
        panel:open(false)
    end

    line = form.addLine("Source")
    form.addSourceField(line, nil,
            function() return widget.consumptionSensor end,
            function(value) widget.consumptionSensor = value end
    )

end

local function read(widget)
    --print("in read funciton")
    widget.resetSwitch = storage.read("resetSwitch") or system.getSource("SH↓")
    widget.capacityFullMah = storage.read("capacity") or defaultPackCapacityMah
    --if not widget.capacityFullMah then
    --    widget.capacityFullMah = defaultPackCapacityMah
    --end
    widget.capacityFullUpdated = true
    widget.useSpecialFunctionButtons = storage.read("useSpecialFunctionButtons") or true
    for i = 1, 6, 1 do
        local specialFunctionButton = "sfCapacityMah" .. i
        value = storage.read(specialFunctionButton)
        --print("read sf: " .. i .. " value: " .. value)
        if value and value > 0 then
            widget.sfCapacityMah[i] = value
            --print("read:" .. specialFunctionButton .. " " .. value)
        else
            widget.sfCapacityMah[i] = sfDefaultValues[i]
            --print("setting default value:" .. specialFunctionButton .. " " .. sfDefaultValues[i])
        end
    end
    widget.consumptionSensor = storage.read("source") or system.getSource("Consumption")
end

local function write(widget)
    storage.write("resetSwitch", widget.resetSwitch)
    storage.write("capacity", widget.capacityFullMah)
    storage.write("useSpecialFunctionButtons", widget.useSpecialFunctionButtons)
    --print("length: " .. #widget.sfCapacityMah)
    for i = 1, 6, 1 do
        if widget.sfCapacityMah[i] == nil or widget.sfCapacityMah[i] == 0 then
            widget.sfCapacityMah[i] = sfDefaultValues[i]
        end
        local specialFunctionButton = "sfCapacityMah" .. i
        storage.write("sfCapacityMah" .. i, widget.sfCapacityMah[i])
        --print("writing " .. specialFunctionButton .. " " .. widget.sfCapacityMah[i])
    end
    storage.write("source", widget.consumptionSensor)
end

local function init()
    system.registerWidget({ key = key, name = name, create = create, paint = paint, wakeup = wakeup,
                            configure = configure, read = read, write = write, persistent = true })
end

return { init = init }
