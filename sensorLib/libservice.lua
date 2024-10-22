local lib = { }

function lib.new()
    local libscheduler = libscheduler or loadSched()
    g_scheduler = g_scheduler or libscheduler.new()
    local service = {
        -- system stuff here
        scheduler = g_scheduler,

        -- common stuff here
        resetSwitch = nil, -- switch to reset script, usually same switch to reset timers

        -- vMin stuff below here
        vMinValues = {},
        lipoSensor = nil,
    }

    function service.reset_if_needed()
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

    function service.bg_func()
        -- test if the reset switch is toggled, if so then reset all internal flags
        service.scheduler.tick()
        service.reset_if_needed()
        service.vMin_bg_func()
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

    return service
end

return lib
