local lib = { }

function lib.new()
    local libscheduler = libscheduler or loadSched()
    g_scheduler = g_scheduler or libscheduler.new()
    local service = {
        -- system stuff here
        startTime = os.clock(),
        scheduler = g_scheduler,
        soundDirPath = "/scripts/sensorLib/sounds/", -- where you put the sound files,

        -- common stuff here
        resetSwitch = nil, -- switch to reset script, usually same switch to reset timers

        -- mahRe2 stuff here
        -- get system info here
        --currentSensor = system.getSource("Current"),
        consumptionSensor = system.getSource("Consumption"),
        --source = system.getSource("Throttle"), -- todo: check to see if this can be removed

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

        -- vMin stuff below here
        vMinValues = {},
        lipoSensor = nil,

        -- watt stuff below here
        currentSensor = nil,
        wattsCurrentValue = 0,
        wattsMaxValue = 0,

        --vfr stuff below here
        vfr_24 = 0,

        --rssi stuff below here
        rssi_24 = 0,
    }

    function service.playPercentRemaining()
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
        if service.batteryRemainingPercent <= 0 and service.atZeroPlayedCount < service.playAtZero and rssi:value() > 0 then
            print(service.batteryRemainingPercent, service.atZeroPlayedCount)
            system.playFile(service.soundDirPath .. "BatNo.wav")
            service.atZeroPlayedCount = service.atZeroPlayedCount + 1
        elseif service.atZeroPlayedCount == service.PlayAtZero and service.batteryRemainingPercent > 0 then
            service.atZeroPlayedCount = 0
        end
    end

    function service.initializeValues()
        if service and service.capacityFullMah ~= nil then
            --mahRe2 stuff here
            service.capacityReservedMah = service.capacityFullMah * (100 - service.capacityReservePercent) / 100
            service.capacityRemainingMah = service.capacityReservedMah
            service.batteryRemainingPercent = 0
            service.atZeroPlayedCount = 0
            service.capacityFullUpdated = false
        end
    end

    function service.reset_if_needed()
        -- test if the reset switch is toggled, if so then reset all internal flags
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
                print("reset event")

                service.startTime = os.clock()  -- this resets the mAh used counter
                service.scheduler.reset()
                service.initializeValues()

                -- vMin stuff here
                service.vMinValues = {}

                -- watt stuff here
                service.wattsCurrentValue = 0
                service.wattsMaxValue = 0
                service.vfr_24 = 0
                service.rssi_24 = 0

            elseif -100 == resetSwitchValue then
                --print("reset switch released")
                service.scheduler.remove('reset_sw')
            end
        end
    end

    function service.bg_func()
        -- test if the reset switch is toggled, if so then reset all internal flags
        service.scheduler.tick()
        service.reset_if_needed()
        service.mahRe2_bg_func()
        service.vMin_bg_func()
        service.watts_bg_func()
    end

    function service.mahRe2_bg_func()
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
            service.initializeValues()
        end

        if service.consumptionSensor ~= nil and service.consumptionSensor:value() ~= service.capacityUsedMah  and service.capacityUsedMah ~= nil then
            --service.capacityUsedMah = math.floor(service.currentSensor:value() * 1000 * (os.clock() - service.startTime) / 3600)
            service.capacityUsedMah = service.consumptionSensor:value()
            --print("capacityUsedMah: " .. service.capacityUsedMah)
            if (service.capacityUsedMah == 0) and service.canCallInitFuncAgain then
                -- service.capacityUsedMah == 0 when Telemetry has been reset or model loaded
                -- service.capacityUsedMah == 0 when no battery used which could be a long time
                --	so don't keep calling the service.initializeValues unnecessarily.

                service.initializeValues()
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

        service.playPercentRemaining()
        lcd.invalidate()
    end

    function service.get_voltage_sum()
        local min_volts = 0
        local current_volts = 0
        for k,v in ipairs(service.vMinValues) do
            min_volts = min_volts + service.vMinValues[k].low
            current_volts = current_volts + service.vMinValues[k].current
        end
        return min_volts, current_volts
    end

    function service.vMin_bg_func()
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

    function service.watts_bg_func()
        if service.lipoSensor ~= nil and service.currentSensor ~= nil then
            local amps = service.currentSensor:value()
            local volts = service.lipoSensor:value()
            --print("amps: " .. amps .. " volts: " .. volts)
            service.wattsCurrentValue = amps * volts
            if service.wattsCurrentValue > service.wattsMaxValue then
                service.wattsMaxValue = service.wattsCurrentValue
            end
        end
    end

    return service
end

return lib
