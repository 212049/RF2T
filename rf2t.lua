-- Rotorflight Dashboard V2.1
-- Intuitive and concise telemetry data panel, supports common telemetry items, one-click configuration
-- Automatically statistics flight data after flight ends and records daily flight count
-- Built-in simple timer with voice prompts at 1/2/3/4/5 minutes
-- Only supports RF2.1 and above versions, requires ELRS custom telemetry enabled
-- 
-- Important: For first-time use, manually create a folder with the corresponding model name in /LOGS/ directory
-- Example: If model name is "M4", create /LOGS/M4/ folder
-- Flight logs will be automatically stored in this folder afterwards

-- Constants
local MAX_LOG_ENTRIES = 99  -- Maximum log entries
local MIN_FLIGHT_TIME_SEC = 30  -- Minimum valid flight time (seconds)
local SCAN_STATS_BATCH_SIZE = 3  -- Stats scan batch size (files per batch)
local SCAN_LOGS_BATCH_SIZE = 5  -- Log scan batch size (days per batch)
local SCAN_TOTAL_DAYS = 365  -- Total scan days
local STATS_SCAN_PHASE2_BATCH_SIZE = 2  -- Stats scan phase 2 batch size (files per batch)
local MAX_DATE_STR_LEN = 8  -- Date string length (YYYYMMDD)

-- Helper function to join array elements (replaces table.concat)
local function joinArray(arr, separator)
    if #arr == 0 then return "" end
    local result = arr[1]
    for i = 2, #arr do
        result = result .. separator .. arr[i]
    end
    return result
end

-- Helper function to sort array (replaces table.sort) - uses insertion sort
local function sortArray(arr, compareFunc)
    if not compareFunc then
        compareFunc = function(a, b) return a < b end
    end
    -- Use insertion sort (efficient for small arrays common in this code)
    for i = 2, #arr do
        local key = arr[i]
        local j = i - 1
        -- Compare function returns true when key should come before arr[j]
        while j > 0 and compareFunc(key, arr[j]) do
            arr[j + 1] = arr[j]
            j = j - 1
        end
        arr[j + 1] = key
    end
end

local modelName = "RFDB2.1"
local deviceDate = {}
local txBat = 0
local teleItem = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 1 }
local teleItemId = {}
local teleItemName = { "Vbat", "Curr", "Hspd", "Capa", "Bat%", "Tesc", "Thr", "1RSS", "Vbec", "GOV" }
local gov_state_names = { "OFF", "IDLE", "SPOOLUP", "RECOVERY", "ACTIVE", "THR-OFF", "LOST-HS", "AUTOROT", "BAILOUT" }
local connected = false
local armed = false
-- log format 1.Date 2.ModelName 3.Timer 4.Times 5.Capa 6.LowVoltage 7.MaxCurrent 8.MaxPower 9.MaxRPM 10.LowBEC 11.TotalFlights
local flightData = { "20250101", "Model", 0, 0, 0, 0, 0, 0, 0, 0, 0 }
local flightTimes = 0
local showPage = 0 -- 0 Main  1 LogList  2 DateSelect  3 LogDetail

local log_v = ""
local log_c = ""
local log_a = ""
local log_r = ""
local logIndex = 1
local logCount = 0
local logListOffsetY = 0
local loglistOrgY = -2
local logIsNil = false
local logReadData = {}  -- Initialize empty, allocate on demand

-- Date selection related variables
local monthList = {}  -- Month list {year, mon, dates={}}
local monthCount = 0
local monthIndex = 1
local monthListOffsetY = 0
local selectedMonth = { year = 0, mon = 0 }  -- Selected month
local datesInMonth = {}  -- Date list under selected month
local dateInMonthCount = 0
local dateInMonthIndex = 1
local dateInMonthOffsetY = 0
local dateSelectState = 0  -- 0: Select month  1: Select date
local selectedDate = { year = 0, mon = 0, day = 0 }
local modelTotalFlights = 0  -- Model total flight count
local fromDateSelect = false  -- Flag indicating if entered log list from date selection
local scanningLogs = false  -- Flag indicating if scanning logs
local scanProgress = 0  -- Scan progress 0-100
local scanDaysAgo = 0  -- Current scan progress (days scanned)
local scanTotalDays = SCAN_TOTAL_DAYS  -- Scan days
local scanningStats = false  -- Flag indicating if scanning stats
local scanStatsPhase = 0  -- Scan phase: 0=not started, 1=collecting model names, 2=counting flights
local scanStatsDaysAgo = 0  -- Stats scan current progress
local scanStatsTotalDays = SCAN_TOTAL_DAYS  -- Scan days
local scanStatsProgress = 0  -- Scan progress 0-100
local scanStatsModelStats = {}  -- Stats result {model name: flight count}
local scanStatsKnownModels = {}  -- List of discovered model names

local ShowBoard = false
local closeBoardKey = false
local T_0 = 0 -- Base time
local T_P = 0 -- Pause time
local T_Ssecond = 0
local T_MM = "00"
local T_SS = "00"
local timerTipsNum = 0

-- Get model log folder path
function getModelLogPath(modelName)
    if not modelName or modelName == "" then
        modelName = getCurrentModelName()
    end
    return "/LOGS/" .. modelName .. "/"
end

-- Get model log file path
function getModelLogFile(modelName, dateStr)
    return getModelLogPath(modelName) .. "RFLog_" .. dateStr .. ".csv"
end

-- Get number of days in specified month (optimized version)
function getDaysInMonth(year, mon)
    -- Days table for months: 1-12
    local daysTable = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    local days = daysTable[mon] or 31
    -- Note: Leap year is not considered here, as original code doesn't consider it
    return days
end

-- Format date as string (YYYYMMDD)
-- Cache for date string formatting with size limit
local dateStrCache = {}
local dateStrCacheSize = 0
local MAX_DATE_CACHE = 50  -- Limit cache size
function formatDateStr(year, mon, day)
    local cacheKey = year * 10000 + mon * 100 + day
    local cached = dateStrCache[cacheKey]
    if cached then
        return cached
    end
    -- Clear cache if too large before adding new entry
    if dateStrCacheSize >= MAX_DATE_CACHE then
        dateStrCache = {}
        dateStrCacheSize = 0
    end
    cached = string.format("%04d%02d%02d", year, mon, day)
    dateStrCache[cacheKey] = cached
    dateStrCacheSize = dateStrCacheSize + 1
    return cached
end

-- Format date as display string (YYYY-MM-DD)
function formatDateDisplay(year, mon, day)
    return string.format("%04d-%02d-%02d", year, mon, day)
end

-- Get current model name (with cache)
local cachedModelName = nil
local cachedModelNameTime = 0
function getCurrentModelName()
    local currentTime = getRtcTime()
    -- Cache model name for 1 second to avoid frequent calls
    if cachedModelName == nil or currentTime - cachedModelNameTime > 1 then
        cachedModelName = model.getInfo()["name"]
        cachedModelNameTime = currentTime
    end
    return cachedModelName
end

-- Calculate date for specified days ago
function getDateDaysAgo(daysAgo)
    local today = getDateTime()
    local checkDate = { year = today.year, mon = today.mon, day = today.day }
    local targetDays = daysAgo
    
    while targetDays > 0 do
        if checkDate.day > targetDays then
            checkDate.day = checkDate.day - targetDays
            targetDays = 0
        else
            targetDays = targetDays - checkDate.day
            checkDate.mon = checkDate.mon - 1
            if checkDate.mon <= 0 then
                checkDate.mon = 12
                checkDate.year = checkDate.year - 1
            end
            checkDate.day = getDaysInMonth(checkDate.year, checkDate.mon)
        end
    end
    return checkDate
end

-- Try to open log file (try new path first, then old path)
function tryOpenLogFile(modelName, dateStr)
    local filename = getModelLogFile(modelName, dateStr)
    local logFile = io.open(filename, "r")
    
    if logFile == nil then
        -- Try old path format
        local oldFilename = "/LOGS/RFLog_" .. dateStr .. ".csv"
        logFile = io.open(oldFilename, "r")
        if logFile ~= nil then
            filename = oldFilename
        end
    end
    
    return logFile, filename
end

-- Try to open log file for append (try new path first, then old path)
function tryOpenLogFileAppend(modelName, dateStr)
    local filename = getModelLogFile(modelName, dateStr)
    local logFile = io.open(filename, "a")
    
    if logFile == nil then
        -- Try old path format
        local oldFilename = "/LOGS/RFLog_" .. dateStr .. ".csv"
        logFile = io.open(oldFilename, "a")
        if logFile ~= nil then
            filename = oldFilename
        end
    end
    
    return logFile, filename
end

-- Check if model name exists in list (avoid duplicates)
-- Optimized model name check using set lookup
local modelNameSet = {}
function addModelNameIfNotExists(modelName, modelList)
    if not modelName or modelName == "" then
        return false
    end
    if not modelNameSet[modelName] then
        modelNameSet[modelName] = true
        modelList[#modelList + 1] = modelName
        return true  -- Added
    end
    return false  -- Already exists
end

-- Check if total flight count needs update (compatible with old format)
function checkAndUpdateTotalFlights(tempLine, currentModelName)
    local totalFlightsVal = tempLine[11]
    local needUpdate = not totalFlightsVal or totalFlightsVal == "" or (tonumber(totalFlightsVal) or 0) == 0
    
    if needUpdate then
        local totalFlights = getModelTotalFlightsFromStats(currentModelName)
        if totalFlights > 0 then
            tempLine[11] = tostring(totalFlights)
        elseif modelTotalFlights > 0 then
            tempLine[11] = tostring(modelTotalFlights)
        else
            tempLine[11] = "0"
        end
    end
end

-- Parse a line from CSV file (generic parsing function)
function parseCSVLine(logFile, onLineParsed)
    local logdata = ""
    local buffer = ""
    local key = 1
    local tempLine = {}
    
    while true do
        logdata = io.read(logFile, 1)
        
        if not logdata or #logdata == 0 then
            -- Handle end of file (may not have newline)
            if buffer ~= "" and key > 1 then
                tempLine[key] = buffer
            end
            if tempLine[1] then
                onLineParsed(tempLine)
            end
            break
        else
            if logdata ~= "|" and logdata ~= "\n" then
                buffer = buffer .. logdata
            end
            if logdata == "|" then
                tempLine[key] = buffer
                buffer = ""
                key = key + 1
            end
            if logdata == "\n" then
                if buffer ~= "" then
                    tempLine[key] = buffer
                    buffer = ""
                end
                if tempLine[1] then
                    onLineParsed(tempLine)
                end
                key = 1
                buffer = ""
                tempLine = {}
            end
        end
    end
end

-- Load date list under selected month
function loadDatesInMonth(year, mon)
    datesInMonth = {}
    dateInMonthCount = 0
    
    for i = 1, monthCount do
        if monthList[i] and monthList[i].year == year and monthList[i].mon == mon and monthList[i].dates then
            for _, date in ipairs(monthList[i].dates) do
                dateInMonthCount = dateInMonthCount + 1
                datesInMonth[dateInMonthCount] = date
            end
            break
        end
    end
    
    dateInMonthIndex = 1
    dateInMonthOffsetY = 0
end

-- Start stats scan (background batch processing)
function startScanStats()
    scanningStats = true
    scanStatsPhase = 1  -- Start collecting model names phase
    scanStatsDaysAgo = 0
    scanStatsProgress = 0
    scanStatsModelStats = {}
    scanStatsKnownModels = {}
    modelNameSet = {}  -- Reset model name set
    print("Starting stats scan...")
end

-- Process stats scan in batches (called in background)
function processScanStats()
    if not scanningStats then
        return
    end
    
    local scanned = 0
    
    if scanStatsPhase == 1 then
        -- Phase 1: Collect model names (scan old format files)
        while scanned < SCAN_STATS_BATCH_SIZE and scanStatsDaysAgo < scanStatsTotalDays do
            local checkDate = getDateDaysAgo(scanStatsDaysAgo)
            local dateStr = formatDateStr(checkDate.year, checkDate.mon, checkDate.day)
            
            local oldFilename = "/LOGS/RFLog_" .. dateStr .. ".csv"
            local logFile = io.open(oldFilename, "r")
            
            if logFile ~= nil then
                -- Read file, collect model names (using generic parsing function)
                parseCSVLine(logFile, function(tempLine)
                    if tempLine[1] and tempLine[2] then
                        local currentModelName = tempLine[2]
                        addModelNameIfNotExists(currentModelName, scanStatsKnownModels)
                    end
                end)
                io.close(logFile)
            end
            
            scanStatsDaysAgo = scanStatsDaysAgo + 1
            scanned = scanned + 1
            -- Update progress (Phase 1 accounts for 50%)
            scanStatsProgress = math.floor((scanStatsDaysAgo / scanStatsTotalDays) * 50)
        end
        
        -- Phase 1 complete, check if need to add current model
        if scanStatsDaysAgo >= scanStatsTotalDays then
            if #scanStatsKnownModels == 0 then
                local currentModelName = getCurrentModelName()
                if currentModelName and currentModelName ~= "" then
                    for daysAgo = 0, 30 do
                        local checkDate = getDateDaysAgo(daysAgo)
                        local dateStr = formatDateStr(checkDate.year, checkDate.mon, checkDate.day)
                        local newFilename = getModelLogFile(currentModelName, dateStr)
                        local testFile = io.open(newFilename, "r")
                        if testFile ~= nil then
                            io.close(testFile)
                            scanStatsKnownModels[#scanStatsKnownModels + 1] = currentModelName
                            break
                        end
                    end
                end
            end
            -- Enter Phase 2: Count flights
            scanStatsPhase = 2
            scanStatsDaysAgo = 0
            scanStatsProgress = 50  -- Phase 1 complete, progress 50%
        end
        
    elseif scanStatsPhase == 2 then
        -- Phase 2: Count flights
        while scanned < STATS_SCAN_PHASE2_BATCH_SIZE and scanStatsDaysAgo < scanStatsTotalDays do
            local checkDate = getDateDaysAgo(scanStatsDaysAgo)
            local dateStr = formatDateStr(checkDate.year, checkDate.mon, checkDate.day)
            
            -- Count new format files first - optimized file reading
            local modelsWithNewFormat = {}
            for _, modelName in ipairs(scanStatsKnownModels) do
                local newFilename = getModelLogFile(modelName, dateStr)
                local newLogFile = io.open(newFilename, "r")
                if newLogFile ~= nil then
                    modelsWithNewFormat[modelName] = true
                    local linecount = 0
                    local buffer = ""
                    while true do
                        local data = io.read(newLogFile, 512)  -- Read in chunks
                        if not data or #data == 0 then
                            break
                        end
                        buffer = buffer .. data
                        -- Count newlines efficiently
                        local pos = 1
                        while true do
                            local newPos = string.find(buffer, "\n", pos, true)
                            if not newPos then break end
                            linecount = linecount + 1
                            pos = newPos + 1
                        end
                        -- Keep remaining data without newline
                        buffer = string.sub(buffer, pos)
                    end
                    io.close(newLogFile)
                    if linecount > 0 then
                        scanStatsModelStats[modelName] = (scanStatsModelStats[modelName] or 0) + linecount
                    end
                end
            end
            
            -- Check old format files
            local oldFilename = "/LOGS/RFLog_" .. dateStr .. ".csv"
            local logFile = io.open(oldFilename, "r")
            
            if logFile ~= nil then
                -- Use generic parsing function to count old format files
                parseCSVLine(logFile, function(tempLine)
                    if tempLine[1] and tempLine[2] then
                        local currentModelName = tempLine[2]
                        if currentModelName and currentModelName ~= "" and not modelsWithNewFormat[currentModelName] then
                            scanStatsModelStats[currentModelName] = (scanStatsModelStats[currentModelName] or 0) + 1
                        end
                    end
                end)
                io.close(logFile)
            end
            
            scanStatsDaysAgo = scanStatsDaysAgo + 1
            scanned = scanned + 1
            -- Update progress (Phase 2 accounts for 50%, from 50% to 100%)
            scanStatsProgress = 50 + math.floor((scanStatsDaysAgo / scanStatsTotalDays) * 50)
        end
        
        -- Phase 2 complete, create stats file
        if scanStatsDaysAgo >= scanStatsTotalDays then
            local statsFile = io.open("/LOGS/RFStats.csv", "w")
            if statsFile ~= nil then
                local outputLines = {}
                local modelCount = 0
                for modelName, count in pairs(scanStatsModelStats) do
                    outputLines[#outputLines + 1] = modelName .. "|" .. count .. "\n"
                    modelCount = modelCount + 1
                end
                io.write(statsFile, joinArray(outputLines, ""))
                io.close(statsFile)
                print("RFStats.csv created with " .. modelCount .. " models")
            end
            scanningStats = false
            scanStatsPhase = 0
            -- Load model total flight count after scan completes
            loadModelTotalFlights()
        end
    end
end

-- Read model total flight count (from RFStats.csv)
function loadModelTotalFlights()
    modelTotalFlights = 0
    local currentModelName = getCurrentModelName()
    local statsFile = io.open("/LOGS/RFStats.csv", "r")
    if statsFile ~= nil then
        local buffer = ""
        local modelName = ""
        while true do
            local data = io.read(statsFile, 1)
            if not data or #data == 0 then
                -- Handle end of file (may not have newline)
                if modelName == currentModelName and buffer ~= "" then
                    modelTotalFlights = tonumber(buffer) or 0
                end
                break
            end
            
            if data == "|" then
                modelName = buffer
                buffer = ""
            elseif data == "\n" then
                if modelName == currentModelName and buffer ~= "" then
                    modelTotalFlights = tonumber(buffer) or 0
                    break
                end
                buffer = ""
                modelName = ""
            else
                buffer = buffer .. data
            end
        end
        io.close(statsFile)
    end
end

-- Get total flight count for specified model (for old logs)
function getModelTotalFlightsFromStats(modelName)
    local totalFlights = 0
    local statsFile = io.open("/LOGS/RFStats.csv", "r")
    if statsFile ~= nil then
        local buffer = ""
        local foundModelName = ""
        while true do
            local data = io.read(statsFile, 1)
            if not data or #data == 0 then
                -- Handle end of file (may not have newline)
                if foundModelName == modelName and buffer ~= "" then
                    totalFlights = tonumber(buffer) or 0
                end
                break
            end
            
            if data == "|" then
                foundModelName = buffer
                buffer = ""
            elseif data == "\n" then
                if foundModelName == modelName then
                    totalFlights = tonumber(buffer) or 0
                    break
                end
                buffer = ""
                foundModelName = ""
            else
                buffer = buffer .. data
            end
        end
        io.close(statsFile)
    end
    return totalFlights
end

-- Update model total flight count
function updateModelTotalFlights()
    local currentModelName = getCurrentModelName()
    local statsFile = io.open("/LOGS/RFStats.csv", "r")
    local statsData = {}
    local found = false
    local newCount = 1
    
    -- Read existing stats data
    if statsFile ~= nil then
        local buffer = ""
        local modelName = ""
        local line = 1
        while true do
            local data = io.read(statsFile, 1)
            if not data or #data == 0 then
                -- Handle end of file (may not have newline)
                if modelName ~= "" and buffer ~= "" then
                    if modelName == currentModelName then
                        local currentCount = tonumber(buffer) or 0
                        newCount = currentCount + 1
                        statsData[line] = { name = modelName, count = newCount }
                        found = true
                    else
                        statsData[line] = { name = modelName, count = tonumber(buffer) or 0 }
                    end
                end
                break
            end
            
            if data == "|" then
                modelName = buffer
                buffer = ""
            elseif data == "\n" then
                if modelName ~= "" and buffer ~= "" then
                    if modelName == currentModelName then
                        local currentCount = tonumber(buffer) or 0
                        newCount = currentCount + 1
                        statsData[line] = { name = modelName, count = newCount }
                        found = true
                    else
                        statsData[line] = { name = modelName, count = tonumber(buffer) or 0 }
                    end
                    line = line + 1
                end
                buffer = ""
                modelName = ""
            else
                buffer = buffer .. data
            end
        end
        io.close(statsFile)
    end
    
    -- If not found, add new record
    if not found then
        newCount = 1
        statsData[#statsData + 1] = { name = currentModelName, count = newCount }
    end
    
    -- Write updated data - optimized
    statsFile = io.open("/LOGS/RFStats.csv", "w")
    if statsFile ~= nil then
        -- Build output string efficiently
        local outputLines = {}
        for k, v in pairs(statsData) do
            if v and v.name and v.count then
                outputLines[#outputLines + 1] = v.name .. "|" .. v.count .. "\n"
            end
        end
        -- Write all at once
        io.write(statsFile, joinArray(outputLines, ""))
        io.close(statsFile)
        modelTotalFlights = newCount
    end
end



-- Cleanup function to free memory
local function cleanupMemory()
    -- Clear large arrays
    logReadData = {}
    monthList = {}
    datesInMonth = {}
    scanStatsKnownModels = {}
    scanStatsModelStats = {}
    modelNameSet = {}
    -- Reset counters
    monthCount = 0
    dateInMonthCount = 0
    logCount = 0
    -- Clear caches periodically
    if dateStrCacheSize > MAX_DATE_CACHE * 2 then
        dateStrCache = {}
        dateStrCacheSize = 0
    end
end

local function init()
    -- Cleanup memory on init to prevent accumulation
    cleanupMemory()
    
    T_0 = getRtcTime()
    -- Get current date
    deviceDate = getDateTime()

    -- Read today's log file and calculate flight count (synchronously)
    local currentModelName = getCurrentModelName()
    local dateStr = formatDateStr(deviceDate.year, deviceDate.mon, deviceDate.day)
    local logFile, filename = tryOpenLogFile(currentModelName, dateStr)
    
    -- Read current model's today flight count (files are already categorized by model, so just count lines)
    if logFile ~= nil then
        local linecount = 0
        local buffer = ""
        while true do
            local logdata = io.read(logFile, 512)  -- Read in chunks for better performance
            if not logdata or #logdata == 0 then
                break
            end
            buffer = buffer .. logdata
            -- Count newlines in buffer efficiently
            local pos = 1
            while true do
                local newPos = string.find(buffer, "\n", pos, true)
                if not newPos then break end
                linecount = linecount + 1
                pos = newPos + 1
            end
            -- Keep remaining data without newline
            buffer = string.sub(buffer, pos)
        end
        io.close(logFile)
        flightTimes = linecount
    else
        flightTimes = 0
    end
    
    -- Check if RFStats.csv exists, if not start background scan
    local statsFile = io.open("/LOGS/RFStats.csv", "r")
    if statsFile == nil then
        -- RFStats.csv doesn't exist, start background stats scan
        startScanStats()
    else
        io.close(statsFile)
        -- Load model total flight count
        loadModelTotalFlights()
    end
end

local function background()
    if (checkConnect() and showPage == 0) then
        getTeleId() -- Get telemetry id first
        upValues()  -- Get data based on obtained id
        if (checkArm()) then
            startTimer()
            timerTips()
        else
            pauseTimer()
        end
    end
    
    -- If scanning stats, process stats scan (priority higher than log scan)
    if scanningStats then
        processScanStats()
    -- If scanning logs, continue scan process
    elseif scanningLogs and showPage == 2 then
        local scanned = 0
        
        -- Scan specified days each time (batch processing, avoid blocking)
        while scanned < SCAN_LOGS_BATCH_SIZE and scanDaysAgo < scanTotalDays do
            local checkDate = getDateDaysAgo(scanDaysAgo)
            
            -- Check if file exists (check new path first, then try old path)
            local currentModelName = getCurrentModelName()
            local dateStr = formatDateStr(checkDate.year, checkDate.mon, checkDate.day)
            local logFile, filename = tryOpenLogFile(currentModelName, dateStr)
            
            if logFile ~= nil then
                io.close(logFile)
                
                -- Find or create month
                local monthIdx = 0
                for i = 1, monthCount do
                    if monthList[i].year == checkDate.year and monthList[i].mon == checkDate.mon then
                        monthIdx = i
                        break
                    end
                end
                
                if monthIdx == 0 then
                    -- Create new month, add to end of list (will sort later)
                    monthCount = monthCount + 1
                    monthList[monthCount] = { year = checkDate.year, mon = checkDate.mon, dates = {} }
                    monthIdx = monthCount
                end
                
                -- Add date to this month (add to end, will sort later)
                local dates = monthList[monthIdx].dates
                -- Limit dates per month to prevent memory issues (keep latest 31 days)
                if #dates < 31 then
                    dates[#dates + 1] = { year = checkDate.year, mon = checkDate.mon, day = checkDate.day }
                    
                    -- Sort dates in current month in reverse order (newest first) - optimized
                    sortArray(dates, function(a, b)
                        local dateA = a.year * 10000 + a.mon * 100 + a.day
                        local dateB = b.year * 10000 + b.mon * 100 + b.day
                        return dateA > dateB
                    end)
                end
            end
            
            scanDaysAgo = scanDaysAgo + 1
            scanned = scanned + 1
            scanProgress = math.floor((scanDaysAgo / scanTotalDays) * 100)
        end
        
        -- Scan complete
        if scanDaysAgo >= scanTotalDays then
            -- Sort month list in reverse order (newest first) - optimized
            sortArray(monthList, function(a, b)
                local monthA = a.year * 100 + a.mon
                local monthB = b.year * 100 + b.mon
                return monthA > monthB
            end)
            scanningLogs = false
            scanProgress = 100
            -- Limit month list size to prevent memory issues (keep latest 24 months)
            if monthCount > 24 then
                local tempList = {}
                for i = 1, 24 do
                    tempList[i] = monthList[i]
                end
                monthList = tempList
                monthCount = 24
            end
        end
    end
    
end

-- Cache for timer formatting with size limits
local timerMMCache = {}
local timerSSCache = {}
local MAX_TIMER_CACHE = 60  -- Limit to 60 minutes/seconds max
function startTimer()
    T_Ssecond = getRtcTime() - T_0 + T_P
    local mm = math.floor(T_Ssecond / 60)
    local ss = math.floor(T_Ssecond % 60)
    -- Limit cache size to reasonable values
    if mm > MAX_TIMER_CACHE then mm = MAX_TIMER_CACHE end
    if ss > MAX_TIMER_CACHE then ss = MAX_TIMER_CACHE end
    if not timerMMCache[mm] then
        timerMMCache[mm] = string.format("%02d", mm)
    end
    if not timerSSCache[ss] then
        timerSSCache[ss] = string.format("%02d", ss)
    end
    T_MM = timerMMCache[mm]
    T_SS = timerSSCache[ss]
end

function pauseTimer()
    T_P = T_Ssecond
    T_0 = getRtcTime()
end

function timerTips()
    if (armed) then
        if tonumber(T_MM) > timerTipsNum then
            timerTipsNum = tonumber(T_MM)
            playNumber(timerTipsNum, 36)
        end
    end
end

local function run(event)
    getRadioStatus()

    lcd.clear()
    drawMainPage()
    drawLogUI()
    drawDateSelectUI()
    drawLogDetailUI()
    
    -- Detect wheel press
    if (event == EVT_ROT_BREAK) then
        if (ShowBoard) then -- Don't respond to key when panel is not shown
            closeBoardKey = true
            closeBoard()
        elseif (showPage == 1) then -- In log list page, view details
            if logCount > 0 and logReadData[logIndex] then
                showPage = 3  -- Enter log detail page
            end
        elseif (showPage == 3) then -- In log detail page, return to list
            showPage = 1  -- Return to log list
        elseif (showPage == 2) then -- In date selection page
            if dateSelectState == 0 then -- Select month state
                if monthCount > 0 then
                    selectedMonth = monthList[monthIndex]
                    loadDatesInMonth(selectedMonth.year, selectedMonth.mon)
                    dateSelectState = 1  -- Switch to select date state
                    dateInMonthIndex = 1
                    dateInMonthOffsetY = 0
                end
            else -- Select date state
                if dateInMonthCount > 0 then
                    selectedDate = datesInMonth[dateInMonthIndex]
                    showPage = 1
                    logIndex = 1
                    logListOffsetY = 0
                    fromDateSelect = true  -- Mark entered from date selection
                    loadLogData(selectedDate)
                end
            end
        end
    end

    -- Detect menu key press
    if (event == EVT_VIRTUAL_MENU) then
        if (showPage == 0) then -- Currently on main page
            showPage = 1
            selectedDate = nil  -- Use current date
            fromDateSelect = false  -- Entered from main page, not from date selection
            loadLogData()       -- Read data
        elseif (showPage == 1) then -- In log list page, switch to date selection
            -- Clear log data to free memory before switching
            logReadData = {}
            logCount = 0
            
            showPage = 2
            -- Initialize scan state
            scanningLogs = true
            scanProgress = 0
            scanDaysAgo = 0
            monthList = {}
            monthCount = 0
            monthIndex = 1
            monthListOffsetY = 0
            dateSelectState = 0  -- Initial state: select month
        end
    end

    -- Detect exit key press
    if (event == EVT_EXIT_BREAK) then
        if (showPage == 2) then -- In date selection page
            if dateSelectState == 1 then -- In date selection state, return to month selection
                dateSelectState = 0
            else -- In month selection state, return to log list
                showPage = 1
                selectedDate = nil  -- Return to today's logs
                loadLogData()
            end
        elseif (showPage == 3) then -- In log detail page
            showPage = 1  -- Return to log list
        elseif (showPage == 1) then -- In log list page
            -- Clear log data when leaving to free memory
            logReadData = {}
            logCount = 0
            
            if fromDateSelect then
                -- Entered from date selection, return to date selection page
                showPage = 2
                fromDateSelect = false
                -- Keep previous selection state
            else
                -- Entered from main page, return to main page
                showPage = 0
                selectedDate = nil
            end
            logIndex = 1
            logListOffsetY = 0
        else
            if (ShowBoard) then -- Don't respond to key when panel is not shown
                closeBoardKey = true
                closeBoard()
            end
        end
    end

    -- Detect wheel scroll - log list page
    if (showPage == 1 and logCount > 0) then
        if (event == EVT_ROT_LEFT) then
            if logIndex > 1 then
                logIndex = logIndex - 1
                -- Check if need to scroll view
                local LogPosY = logIndex * 11 + logListOffsetY + loglistOrgY
                if LogPosY < 11 then
                    logListOffsetY = logListOffsetY + 11
                end
            end
        elseif (event == EVT_ROT_RIGHT) then
            if logIndex < logCount then
                logIndex = logIndex + 1
                -- Check if need to scroll view
                local LogPosY = logIndex * 11 + logListOffsetY + loglistOrgY
                if LogPosY > 54 then
                    logListOffsetY = logListOffsetY - 11
                end
            end
        end
    end
    
    -- Detect wheel scroll - date selection page
    if (showPage == 2) then
        if (dateSelectState == 0) then
            -- Select month
            if (event == EVT_ROT_LEFT and monthCount > 0) then
                if monthIndex > 1 then
                    monthIndex = monthIndex - 1
                    local MonthPosY = (monthIndex - 1) * 11 + 10 + monthListOffsetY
                    if MonthPosY < 10 then
                        monthListOffsetY = monthListOffsetY + 11
                    end
                end
            elseif (event == EVT_ROT_RIGHT and monthCount > 0) then
                if monthIndex < monthCount then
                    monthIndex = monthIndex + 1
                    local MonthPosY = (monthIndex - 1) * 11 + 10 + monthListOffsetY
                    if MonthPosY > 54 then
                        monthListOffsetY = monthListOffsetY - 11
                    end
                end
            end
        else
            -- Select date
            if (event == EVT_ROT_LEFT and dateInMonthCount > 0) then
                if dateInMonthIndex > 1 then
                    dateInMonthIndex = dateInMonthIndex - 1
                    local DatePosY = (dateInMonthIndex - 1) * 11 + 10 + dateInMonthOffsetY
                    if DatePosY < 10 then
                        dateInMonthOffsetY = dateInMonthOffsetY + 11
                    end
                end
            elseif (event == EVT_ROT_RIGHT and dateInMonthCount > 0) then
                if dateInMonthIndex < dateInMonthCount then
                    dateInMonthIndex = dateInMonthIndex + 1
                    local DatePosY = (dateInMonthIndex - 1) * 11 + 10 + dateInMonthOffsetY
                    if DatePosY > 54 then
                        dateInMonthOffsetY = dateInMonthOffsetY - 11
                    end
                end
            end
        end
    end
end

function getRadioStatus()
    local txVoltage = getValue('tx-voltage')
    if txVoltage then
        txBat = string.format("%.1f", txVoltage)
    else
        txBat = "0.0"
    end
end

function getTeleId()
    -- get telemetry id - cache check to avoid redundant calls
    if teleItemId[1] == nil then  -- Only update if not already cached
        for k, v in ipairs(teleItemName) do
            local info = getFieldInfo(v)
            if info ~= nil then
                teleItemId[k] = info.id
            end
        end
    end
end

function upValues()
    -- get modelName
    local newModelName = getCurrentModelName()
    -- If model name changed, reload total flight count
    if newModelName ~= modelName then
        modelName = newModelName
        loadModelTotalFlights()
    end
    -- get telemetry data - optimized iteration
    for k, v in ipairs(teleItemId) do
        if v ~= nil then
            teleItem[k] = getValue(v)
        end
    end
    -- update Capa
    flightData[5] = teleItem[4]

    -- Detecting maximum current (optimized with math.max)
    flightData[7] = math.max(flightData[7], teleItem[2])

    -- Detecting maximum Hspd (optimized with math.max)
    flightData[9] = math.max(flightData[9], teleItem[3])

    -- Detecting lower battery
    -- Need to check: less than armed voltage, not 0v (lost frame), and RPM > 500 (ensure started)
    if teleItem[1] ~= 0 and teleItem[3] > 500 and teleItem[1] < flightData[6] then
        flightData[6] = teleItem[1]
    end

    -- Detecting maximum MaxPower
    local maxPow = teleItem[1] * teleItem[2]
    flightData[8] = math.max(flightData[8], math.floor(maxPow))

    -- Detecting lower BEC
    if teleItem[9] ~= 0 and teleItem[3] > 500 and teleItem[9] < flightData[10] then
        flightData[10] = teleItem[9]
    end

    -- -- Detecting maximum G-Force
    -- -- Need to calculate total acceleration
    -- local totalAcc = math.sqrt(math.pow(teleItem[11], 2) + math.pow(teleItem[12], 2) + math.pow(teleItem[13], 2))

    -- if (totalAcc > flightData[10]) then
    --     flightData[10] = tonumber(string.format("%.2f", totalAcc))
    -- end
end

function checkConnect() -- Check if connected
    local rssi = getValue(teleItemName[8])
    if (rssi ~= 0) then
        if not connected then
            -- Connected

            print("connected!")
            connected = true
            T_MM = "00"
            T_SS = "00"

            closeBoard()
            closeBoardKey = false

            ---If on log page, return to telemetry page

            if (showPage == 1) then
                showPage = 0
                logIndex = 1
                logListOffsetY = 0
            end
        end
        return true
    else
        if connected then
            -- Disconnected
            connected = false

            print("plautone")

            ----------- Record flight data to local -----------------
            function writeLog()
                -- Update model total flight count first (this updates modelTotalFlights)
                updateModelTotalFlights()
                
                -- Get latest total flight count again to ensure accuracy
                loadModelTotalFlights()
                
                flightData[1] = formatDateStr(deviceDate.year, deviceDate.mon, deviceDate.day)
                flightData[2] = getCurrentModelName()
                flightData[3] = T_MM .. ":" .. T_SS
                flightData[4] = flightTimes
                -- Note: flightData[5] already updated to Capa in upValues
                local lowVoltage = flightData[6]
                flightData[6] = string.format("%.1f", lowVoltage)
                flightData[7] = string.format("%.1f", flightData[7])
                flightData[8] = string.format("%u", flightData[8])
                flightData[10] = string.format("%.1f", flightData[10])
                flightData[11] = modelTotalFlights  -- Total flight count (updated)

                -- Write to current model's log folder
                local currentModelName = getCurrentModelName()
                local logFile, filename = tryOpenLogFileAppend(currentModelName, flightData[1])
                
                if logFile ~= nil then
                    -- Start writing data (write 11 fields in order) - optimized
                    local logLine = {}
                    for index = 1, 11 do
                        logLine[index] = tostring(flightData[index] or "")
                    end
                    io.write(logFile, joinArray(logLine, "|") .. "\n")
                    io.close(logFile)
                end
            end

            -- Check if flight time exceeds minimum time, if so count as valid flight
            if (T_Ssecond > MIN_FLIGHT_TIME_SEC) then
                flightTimes = flightTimes + 1
                writeLog()
            end

            -- show flightData board
            if not closeBoardKey then
                ShowBoard = true
            end

            -- reset timertips
            timerTipsNum = 0
        end
        -- pausetimer
        pauseTimer()
        T_P = 0
        T_Ssecond = 0
        return false
    end
end

function checkArm()
    local ch5 = getValue("ch5")
    if (ch5 > 0) then
        if not armed then                -- first arm, record maximum voltage once
            flightData[6] = teleItem[1]  -- BAT
            flightData[10] = teleItem[9] -- BEC
        end
        armed = true
        return armed
    else
        armed = false
        return armed
    end
end

function loadLogData(targetDate)
    -- If date specified, use specified date; otherwise use current date
    local loadDate = targetDate or deviceDate
    
    -- Ensure loadDate is valid
    if not loadDate or not loadDate.year or not loadDate.mon or not loadDate.day then
        loadDate = deviceDate
    end
    
    -- Ensure model total flight count is loaded (if not loaded yet) - check properly
    local currentModelName = getCurrentModelName()
    if modelTotalFlights == 0 and currentModelName ~= modelName then
        loadModelTotalFlights()
    end
    
    -- Only read current model's log file (already categorized by model, all records are current model's)
    local dateStr = formatDateStr(loadDate.year, loadDate.mon, loadDate.day)
    logFile, filename = tryOpenLogFile(currentModelName, dateStr)
    
    -- Clear previous data (only clear used parts) - optimized
    logCount = 0
    
    if logFile ~= nil then
        logIsNil = false
        -- Use generic parsing function to read data
        parseCSVLine(logFile, function(tempLine)
            -- Since file is already categorized by model, all records are current model's, add directly
            if tempLine[1] and logCount < MAX_LOG_ENTRIES then
                -- Compatible with old format: check and update total flight count
                checkAndUpdateTotalFlights(tempLine, currentModelName)
                logCount = logCount + 1
                -- Allocate on demand instead of pre-initializing
                if not logReadData[logCount] then
                    logReadData[logCount] = {}
                end
                -- Copy data to avoid reference issues
                for i = 1, 11 do
                    logReadData[logCount][i] = tempLine[i]
                end
            end
        end)
        io.close(logFile)
        
        -- Sort log records in reverse order (newest first) - optimized
        if logCount > 1 then
            -- Create temporary array with only valid entries
            local tempArray = {}
            for i = 1, logCount do
                tempArray[i] = logReadData[i]
            end
            -- Sort the temporary array
            sortArray(tempArray, function(a, b)
                if not a or not b then return false end
                local dateA = tonumber(a[1] or "0") or 0
                local dateB = tonumber(b[1] or "0") or 0
                return dateA > dateB
            end)
            -- Copy back to logReadData
            for i = 1, logCount do
                logReadData[i] = tempArray[i]
            end
        end
    else
        logIsNil = true
        logCount = 0
    end
    
    -- Ensure logIndex is within valid range
    if logCount > 0 and logIndex > logCount then
        logIndex = logCount
    end
    if logIndex < 1 then
        logIndex = 1
    end
end

function drawDataBoard()
    if (ShowBoard) then
        lcd.drawFilledRectangle(0, 0, 128, 64)
        lcd.drawFilledRectangle(2, 3, 124, 58, ERASE)
        lcd.drawRectangle(3, 4, 122, 56, FORCE)

        -- Top title area (Y: 5-20, remove bottom line, use background color to separate)
        lcd.drawFilledRectangle(4, 19, 120, 1, FORCE)  -- Use filled rectangle instead of line to avoid overlap
        lcd.drawFilledRectangle(104, 5, 20, 16, FORCE)
        
        -- timer
        lcd.drawText(7, 7, T_MM .. ":" .. T_SS, MIDSIZE)
        -- date
        lcd.drawText(52, 10, formatDateDisplay(deviceDate.year, deviceDate.mon, deviceDate.day), SMLSIZE)
        -- times (today's flight count) - Use RIGHT alignment to avoid overlap with separator
        lcd.drawText(123, 7, tostring(flightTimes), MIDSIZE + INVERS + RIGHT)

        -- Middle separator line (left and right columns)
        lcd.drawLine(63, 21, 63, 57, SOLID, FORCE)

        -- Left info area (Y: 22-57)
        -- capa
        drawBatIcon(8, 23)
        lcd.drawText(20, 22, tostring(flightData[5]) .. "mAh", SMLSIZE + LEFT)
        -- maxcurrent
        drawFlashIcon(8, 32)
        lcd.drawText(20, 31, tostring(flightData[7]) .. "A", SMLSIZE + LEFT)
        -- maxrpm
        drawRotorIcon(8, 41)
        lcd.drawText(20, 40, tostring(flightData[9]) .. "RPM", SMLSIZE + LEFT)
        -- Total Flights
        lcd.drawText(8, 50, "Total:", SMLSIZE + LEFT)
        lcd.drawText(50, 50, tostring(modelTotalFlights), SMLSIZE + LEFT)

        -- Right info area (Y: 22-57)
        -- voltage
        drawBatIcon(68, 23)
        lcd.drawText(80, 22, string.format("%.1f", flightData[6]) .. "V", SMLSIZE + LEFT)
        -- maxpower
        drawFlashIcon(68, 32)
        lcd.drawText(80, 31, tostring(flightData[8]) .. "W", SMLSIZE + LEFT)
        -- low bec
        drawBEC(67, 41)
        lcd.drawText(80, 40, string.format("%.1f", flightData[10]) .. "V", SMLSIZE + LEFT)
    end
end

function closeBoard()
    -- hide flightdata board
    ShowBoard = false

    -- reset all flight data
    flightData = { "20250101", "Model", 0, 0, 0, 0, 0, 0, 0, 0, 0 }
end

function drawMainPage()
    if showPage == 0 then
        lcd.clear()

        -- status bar
        lcd.drawFilledRectangle(0, 0, 128, 8)

        -- modelName
        lcd.drawText(1, 1, modelName, SMLSIZE + INVERS)

        -- Flight mode
        if (connected == false) then
            lcd.drawText(63, 1, "RX LOSS", SMLSIZE + INVERS + BLINK + CENTER)
        else
            lcd.drawText(63, 1, gov_state_names[teleItem[10]], SMLSIZE + INVERS + CENTER)
        end

        -- TX Battery Voltage
        lcd.drawText(127, 1, txBat .. "V", SMLSIZE + RIGHT + INVERS)

        -- battery block
        -- battery graphic
        lcd.drawFilledRectangle(2, 10, 33, 8, SOLID)
        lcd.drawLine(35, 11, 35, 16, SOLID, FORCE)
        for i = 0, math.ceil(teleItem[5] / 10) - 1, 1 do
            lcd.drawFilledRectangle(3 * i + 4, 12, 2, 4, ERASE)
        end

        -- battery voltage
        lcd.drawText(2, 21, string.format("%.1f", teleItem[1]) .. "V", MIDSIZE)

        --------------------------------------------------------------
        lcd.drawLine(0, 36, 40, 36, SOLID, FORCE)

        -- battery capa
        lcd.drawText(2, 41, string.format("%u", teleItem[4]) .. "mah", SMLSIZE)

        --------------------------------------------------------------
        lcd.drawLine(0, 51, 40, 51, SOLID, FORCE)

        -- battery current

        lcd.drawText(2, 55, string.format("%u", teleItem[2]) .. "/" .. string.format("%u", flightData[7]) .. "A",
            SMLSIZE)

        -- other block

        function drawSignal(x, y)
            lcd.drawLine(x, y + 4, x, y + 5, SOLID, FORCE)
            lcd.drawLine(x + 2, y + 2, x + 2, y + 5, SOLID, FORCE)
            lcd.drawLine(x + 4, y, x + 4, y + 5, SOLID, FORCE)
        end

        -- timer
        lcd.drawText(86, 11, "Time", SMLSIZE)
        lcd.drawText(126, 21, T_MM .. ":" .. T_SS, MIDSIZE + RIGHT)

        --------------------------------------------------------------
        lcd.drawLine(85, 36, 127, 36, SOLID, FORCE)

        -- BEC
        lcd.drawText(86, 41, "BEC", SMLSIZE)
        lcd.drawText(126, 41, string.format("%.1f", teleItem[9]) .. "V", SMLSIZE + RIGHT)

        --------------------------------------------------------------
        lcd.drawLine(85, 51, 127, 51, SOLID, FORCE)

        -- RSSI
        drawSignal(88, 55)
        lcd.drawText(126, 55, teleItem[8] .. "dB", SMLSIZE + RIGHT)

        -- mid block
        lcd.drawFilledRectangle(42, 9, 42, 55, SOLID)

        -- headSp
        lcd.drawText(64, 11, teleItem[3], DBLSIZE + INVERS + CENTER)
        lcd.drawText(64, 28, "RPM", SMLSIZE + INVERS + CENTER)
        --------------------------------------------------------------
        lcd.drawLine(44, 36, 81, 36, SOLID, ERASE)
        -- throttle
        lcd.drawText(44, 41, "Thr", SMLSIZE + INVERS)
        lcd.drawText(83, 41, teleItem[7] .. "%", SMLSIZE + INVERS + RIGHT)
        -- esc Temp
        lcd.drawText(44, 54, "ESC", SMLSIZE + INVERS)
        lcd.drawText(83, 54, teleItem[6] .. "°C", SMLSIZE + INVERS + RIGHT)

        -- draw flightdata board
        drawDataBoard()
    end
end

function drawLogUI()
    if showPage == 1 then
        -- Clear screen (ensure no residual content)
        lcd.clear()
        
        -- Determine display date
        local displayDate = selectedDate or deviceDate
        
        -- Draw status bar and separator first (bottom layer)
        --------------------------------------------------------------
        -- status bar
        lcd.drawFilledRectangle(0, 0, 128, 8, FORCE)

        -- title (display selected or current date)
        lcd.drawText(1, 1, formatDateDisplay(displayDate.year, displayDate.mon, displayDate.day),
            SMLSIZE + INVERS)

        -- Log Date
        lcd.drawText(127, 1, logCount .. " Flights", SMLSIZE + RIGHT + INVERS)
        --------------------------------------------------------------

        -- Right separator line
        lcd.drawFilledRectangle(75, 8, 1, 56, FORCE)
        
        -- Prepare right side display data
        if logIsNil or logCount == 0 then
            log_v = "--"
            log_c = "--"
            log_a = "--"
            log_r = "--"
        else
            -- Safely get log data, avoid nil values
            if logReadData[logIndex] then
                log_v = logReadData[logIndex][6] or "--"
                log_c = logReadData[logIndex][5] or "--"
                log_a = logReadData[logIndex][7] or "--"
                log_r = logReadData[logIndex][9] or "--"
            else
                log_v = "--"
                log_c = "--"
                log_a = "--"
                log_r = "--"
            end
        end

        --------------------------------------------------------------
        -- Right side info (drawn above list)
        -- voltage
        drawBatIcon(79, 14)
        lcd.drawText(90, 13, log_v .. "V", SMLSIZE + LEFT)
        -- battery used
        drawBatIcon(79, 27)
        lcd.drawText(90, 26, log_c .. "mAh", SMLSIZE + LEFT)
        -- MaxCurrent
        drawFlashIcon(79, 39)
        lcd.drawText(90, 39, log_a .. "A", SMLSIZE + LEFT)
        -- Max RPM
        drawRotorIcon(79, 53)
        lcd.drawText(90, 52, log_r .. "RPM", SMLSIZE + LEFT)
        
        -- Draw log list last (below status bar)
        if logIsNil or logCount == 0 then
            --- Display "No logs!" when no log data
            lcd.drawText(16, 32, "No logs!", SMLSIZE + LEFT)
        else
            for i = 1, logCount do
                if logReadData[i] then  -- Ensure data exists
                    LogPosY = i * 11 + logListOffsetY + loglistOrgY

                    if LogPosY > 8 and LogPosY < 64 then ---Parts beyond screen not rendered (status bar Y=8)
                        local Sta = (i == logIndex)  ---Current pointer position selected
                        local modelName = logReadData[i][2] or "Unknown"
                        local timer = logReadData[i][3] or "00:00"
                        drawLogItem(i, modelName, timer, LogPosY, Sta)
                    end
                end
            end
        end
    end
end

function drawDateSelectUI()
    if showPage == 2 then
        -- Clear screen
        lcd.clear()
        
        -- status bar
        lcd.drawFilledRectangle(0, 0, 128, 8, FORCE)
        -- Prioritize displaying background stats scan progress
        if scanningStats then
            local phaseText = ""
            if scanStatsPhase == 1 then
                phaseText = "Scan1"
            elseif scanStatsPhase == 2 then
                phaseText = "Scan2"
            end
            lcd.drawText(1, 1, phaseText, SMLSIZE + INVERS + BLINK)
            lcd.drawText(127, 1, scanStatsProgress .. "%", SMLSIZE + RIGHT + INVERS)
        elseif scanningLogs then
            lcd.drawText(1, 1, "Scanning...", SMLSIZE + INVERS)
            lcd.drawText(127, 1, scanProgress .. "%", SMLSIZE + RIGHT + INVERS)
        elseif dateSelectState == 0 then
            lcd.drawText(1, 1, "Select Month", SMLSIZE + INVERS)
            lcd.drawText(127, 1, monthCount .. " Months", SMLSIZE + RIGHT + INVERS)
        else
            local monthStr = string.format("%04d-%02d", selectedMonth.year, selectedMonth.mon)
            lcd.drawText(1, 1, monthStr, SMLSIZE + INVERS)
            lcd.drawText(127, 1, dateInMonthCount .. " Days", SMLSIZE + RIGHT + INVERS)
        end
        
        -- If scanning, show progress bar (don't show separator)
        if scanningStats then
            -- Background stats scan progress bar
            lcd.drawFilledRectangle(20, 30, 88, 12, FORCE)
            lcd.drawFilledRectangle(22, 32, 84, 8, ERASE)
            -- Progress bar fill
            local progressWidth = math.floor((scanStatsProgress / 100) * 84)
            if progressWidth > 0 then
                lcd.drawFilledRectangle(22, 32, progressWidth, 8, FORCE)
            end
            -- Progress text
            local phaseText = "Scanning Stats..."
            if scanStatsPhase == 1 then
                phaseText = "Phase 1: Finding Models"
            elseif scanStatsPhase == 2 then
                phaseText = "Phase 2: Counting Flights"
            end
            lcd.drawText(64, 48, phaseText, SMLSIZE + CENTER)
        elseif scanningLogs then
            -- Log scan progress bar
            lcd.drawFilledRectangle(20, 30, 88, 12, FORCE)
            lcd.drawFilledRectangle(22, 32, 84, 8, ERASE)
            -- Progress bar fill
            local progressWidth = math.floor((scanProgress / 100) * 84)
            if progressWidth > 0 then
                lcd.drawFilledRectangle(22, 32, progressWidth, 8, FORCE)
            end
            -- Progress text
            lcd.drawText(64, 48, "Scanning...", SMLSIZE + CENTER)
        else
            -- Separator line (left and right split) - only show in non-scanning state
            lcd.drawLine(64, 8, 64, 64, SOLID, FORCE)
            
            if monthCount == 0 then
                lcd.drawText(16, 32, "No logs found!", SMLSIZE + LEFT)
            else
                -- Left side: always show month list
                for i = 1, monthCount do
                    local MonthPosY = (i - 1) * 11 + 10 + monthListOffsetY
                    
                    if MonthPosY > 8 and MonthPosY < 64 then
                        local isSelected = (i == monthIndex and dateSelectState == 0)
                        local monthStr = string.format("%04d-%02d", monthList[i].year, monthList[i].mon)
                        
                        if isSelected then
                            lcd.drawFilledRectangle(0, MonthPosY, 63, 10, FORCE)
                            lcd.drawText(32, MonthPosY + 2, monthStr, SMLSIZE + INVERS + CENTER)
                        else
                            lcd.drawFilledRectangle(0, MonthPosY, 63, 10, ERASE)
                            lcd.drawText(32, MonthPosY + 2, monthStr, SMLSIZE + CENTER)
                        end
                    end
                end
                
                -- Right side: show date list of selected month (only show when dateSelectState == 1)
                if dateSelectState == 1 then
                    for i = 1, dateInMonthCount do
                        local DatePosY = (i - 1) * 11 + 10 + dateInMonthOffsetY
                        
                        if DatePosY > 8 and DatePosY < 64 then
                            local isSelected = (i == dateInMonthIndex)
                            local dateStr = string.format("%02d", datesInMonth[i].day)
                            
                            if isSelected then
                                lcd.drawFilledRectangle(65, DatePosY, 63, 10, FORCE)
                                lcd.drawText(97, DatePosY + 2, dateStr, SMLSIZE + INVERS + CENTER)
                            else
                                lcd.drawFilledRectangle(65, DatePosY, 63, 10, ERASE)
                                lcd.drawText(97, DatePosY + 2, dateStr, SMLSIZE + CENTER)
                            end
                        end
                    end
                else
                    -- Right side prompt to select month
                    lcd.drawText(97, 32, "Select", SMLSIZE + CENTER)
                    lcd.drawText(97, 42, "Month", SMLSIZE + CENTER)
                end
            end
        end
    end
end

-----------Drawing functions
function drawBatIcon(x, y)
    lcd.drawFilledRectangle(x, y, 7, 5, FORCE)
    lcd.drawLine(x + 8, y + 1, x + 8, y + 3, SOLID, FORCE)
end

function drawFlashIcon(x, y)
    lcd.drawFilledRectangle(x + 3, y, 1, 7, FORCE)
    lcd.drawFilledRectangle(x, y + 3, 7, 1, FORCE)
    lcd.drawLine(x + 2, y + 1, x + 4, y + 5, SOLID, FORCE)
    lcd.drawLine(x + 5, y + 4, x + 1, y + 2, SOLID, FORCE)
end

function drawRotorIcon(x, y)
    lcd.drawFilledRectangle(x, y, 3, 2, FORCE)
    lcd.drawFilledRectangle(x + 6, y, 3, 2, FORCE)
    lcd.drawFilledRectangle(x + 4, y, 1, 5, FORCE)
end

function drawArrowIcon(x, y)
    lcd.drawLine(x + 3, y, x, y + 3, SOLID, FORCE)
    lcd.drawLine(x + 3, y, x + 6, y + 3, SOLID, FORCE)
    lcd.drawFilledRectangle(x + 2, y + 2, 3, 1, FORCE)
    lcd.drawFilledRectangle(x + 3, y + 1, 1, 5, FORCE)
end

function drawBEC(x, y)
    lcd.drawFilledRectangle(x, y + 1, 7, 1, FORCE)
    lcd.drawFilledRectangle(x, y + 3, 7, 1, FORCE)
    lcd.drawRectangle(x + 3, y, 6, 5, FORCE)
    lcd.drawFilledRectangle(x + 4, y + 2, 4, 1, FORCE)
end

function drawLogDetailUI()
    if showPage == 3 then
        -- Clear screen
        lcd.clear()
        
        -- Get currently selected log data
        if logReadData[logIndex] then
            local log = logReadData[logIndex]
            
            -- Status bar
            lcd.drawFilledRectangle(0, 0, 128, 8, FORCE)
            lcd.drawText(1, 1, "Log Detail", SMLSIZE + INVERS)
            lcd.drawText(127, 1, logIndex .. "/" .. logCount, SMLSIZE + RIGHT + INVERS)
            
            -- Middle separator line (to bottom of content area)
            lcd.drawLine(63, 10, 63, 64, SOLID, FORCE)
            
            -- Left column
            local leftY = 11
            local lineHeight = 8
            
            -- 1. Model Name
            lcd.drawText(2, leftY, "Model:", SMLSIZE + LEFT)
            local modelNameStr = log[2] or "Unknown"
            if string.len(modelNameStr) > 7 then
                modelNameStr = string.sub(modelNameStr, 1, 7)
            end
            lcd.drawText(35, leftY, modelNameStr, SMLSIZE + LEFT)
            leftY = leftY + lineHeight
            
            -- 2. Timer (flight duration)
            lcd.drawText(2, leftY, "Time:", SMLSIZE + LEFT)
            lcd.drawText(35, leftY, log[3] or "--", SMLSIZE + LEFT)
            leftY = leftY + lineHeight
            
            -- 3. Times (today's flight count)
            lcd.drawText(2, leftY, "Today#:", SMLSIZE + LEFT)
            lcd.drawText(42, leftY, log[4] or "--", SMLSIZE + LEFT)
            leftY = leftY + lineHeight
            
            -- 4. TotalFlights
            lcd.drawText(2, leftY, "Total:", SMLSIZE + LEFT)
            -- Get total flight count, prioritize value from log, if not exists read from RFStats.csv
            local totalFlights = log[11]
            if not totalFlights or totalFlights == "" or totalFlights == "0" then
                local currentModelName = getCurrentModelName()
                totalFlights = getModelTotalFlightsFromStats(currentModelName)
                if totalFlights == 0 then
                    -- If still 0, try using global variable
                    totalFlights = modelTotalFlights
                end
            end
            lcd.drawText(40, leftY, tostring(totalFlights), SMLSIZE + LEFT)
            
            -- Right column (start from Y=11, move up overall)
            local rightY = 11
            
            -- 5. MaxPower
            drawFlashIcon(65, rightY + 1)
            lcd.drawText(75, rightY, "Power:", SMLSIZE + LEFT)
            lcd.drawText(108, rightY, (log[8] or "--") .. "W", SMLSIZE + LEFT)
            rightY = rightY + lineHeight
            
            -- 6. MaxRPM
            drawRotorIcon(65, rightY + 1)
            lcd.drawText(75, rightY, "RPM:", SMLSIZE + LEFT)
            lcd.drawText(105, rightY, log[9] or "--", SMLSIZE + LEFT)
            rightY = rightY + lineHeight
            
            -- 7. LowBEC
            drawBEC(64, rightY + 1)
            lcd.drawText(75, rightY, "BEC:", SMLSIZE + LEFT)
            lcd.drawText(105, rightY, (log[10] or "--") .. "V", SMLSIZE + LEFT)
            rightY = rightY + lineHeight
            
            -- 8. LowVoltage
            drawBatIcon(65, rightY + 1)
            lcd.drawText(75, rightY, "MinV:", SMLSIZE + LEFT)
            lcd.drawText(105, rightY, (log[6] or "--") .. "V", SMLSIZE + LEFT)
            rightY = rightY + lineHeight
            
            -- 9. MaxCurrent
            drawFlashIcon(65, rightY + 1)
            lcd.drawText(75, rightY, "MaxI:", SMLSIZE + LEFT)
            lcd.drawText(105, rightY, (log[7] or "--") .. "A", SMLSIZE + LEFT)
            rightY = rightY + lineHeight
            
            -- 10. Capa - placed at bottom of right column
            drawBatIcon(65, rightY + 1)
            lcd.drawText(75, rightY, "Capa:", SMLSIZE + LEFT)
            lcd.drawText(105, rightY, (log[5] or "--") .. "mAh", SMLSIZE + LEFT)
        else
            -- If no log data
            lcd.drawFilledRectangle(0, 0, 128, 8, FORCE)
            lcd.drawText(1, 1, "Log Detail", SMLSIZE + INVERS)
            lcd.drawText(64, 32, "No data", SMLSIZE + CENTER)
        end
    end
end

function drawLogItem(Num, Name, Timer, PosY, Selected)
    if not Selected then
        lcd.drawFilledRectangle(0, PosY, 70, 10, SOLID)
        lcd.drawFilledRectangle(13, PosY + 1, 56, 8, ERASE)
        lcd.drawText(14, PosY + 2, Name, SMLSIZE)
        lcd.drawText(69, PosY + 2, Timer, SMLSIZE + RIGHT)
    else
        lcd.drawFilledRectangle(0, PosY, 73, 10, SOLID)
        lcd.drawText(14, PosY + 2, Name, SMLSIZE + INVERS)
        lcd.drawText(72, PosY + 2, Timer, SMLSIZE + RIGHT + INVERS)
    end
    lcd.drawText(2, PosY + 2, string.format("%02d", Num), SMLSIZE + INVERS)
end

return {
    run = run,
    background = background,
    init = init
}

