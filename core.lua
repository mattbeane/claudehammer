--- Core detection and clicking module for ClaudeAutoAllow
--- Handles watching for buttons and clicking them safely

local M = {}

-- Module state
M.spoon = nil
M.windowFilter = nil
M.pollTimer = nil
M.appWatcher = nil
M.lastClickTime = 0

-- Dependencies (loaded in init)
local safety = nil
local ui = nil
local configMod = nil

--- Initialize core with dependencies
--- @param spoon table The main spoon object
--- @param deps table Dependencies {safety, ui, config}
function M.init(spoon, deps)
    M.spoon = spoon
    safety = deps.safety
    ui = deps.ui
    configMod = deps.config
end

--- Check if an app name is in the target list
--- @param appName string The application name
--- @return boolean
local function isTargetApp(appName)
    if not appName then return false end
    local config = M.spoon and M.spoon.config or {}
    local targets = config.targetApps or {}

    for _, target in ipairs(targets) do
        if appName == target then
            return true
        end
    end
    return false
end

--- Search a window's UI tree for buttons and click safe ones
--- @param win userdata Hammerspoon window object
--- @return boolean clicked Whether a button was clicked
local function scanAndClickButtons(win)
    if not win then return false end

    local spoon = M.spoon
    if not spoon or not spoon.enabled then return false end

    local config = spoon.config

    -- Debounce: don't click too rapidly
    local now = hs.timer.secondsSinceEpoch() * 1000
    if (now - M.lastClickTime) < (config.debounceMs or 300) then
        return false
    end

    -- Verify it's a target app
    local app = win:application()
    if not app then return false end

    local appName = app:name()
    if not isTargetApp(appName) then
        return false
    end

    -- Get accessibility element
    local axWin = hs.axuielement.windowElement(win)
    if not axWin then return false end

    -- Get window title for context checking
    local windowTitle = win:title()

    -- Search for buttons
    local maxDepth = config.maxSearchDepth or 4
    local buttons = axWin:elementSearch({
        AXRole = "AXButton"
    }, { depth = maxDepth })

    if not buttons or #buttons == 0 then
        return false
    end

    -- Check each button
    for _, button in ipairs(buttons) do
        local title = button:attributeValue("AXTitle")
        if title and title ~= "" then
            -- Merge custom allowed buttons with defaults
            local customAllowed = config.customAllowedButtons
            local mergedAllowed = nil
            if customAllowed and #customAllowed > 0 then
                mergedAllowed = {}
                for _, b in ipairs(safety.ALLOWED_BUTTONS) do
                    table.insert(mergedAllowed, b)
                end
                for _, b in ipairs(customAllowed) do
                    table.insert(mergedAllowed, b)
                end
            end

            -- Check safety
            local safe, reason = safety.isButtonSafe(
                title,
                appName,
                windowTitle,
                mergedAllowed
            )

            if safe then
                -- Click it!
                local success = button:performAction("AXPress")

                if success then
                    M.lastClickTime = now

                    -- Update stats
                    spoon.stats = configMod.incrementStats(spoon.stats, title)

                    -- Trigger UI feedback
                    ui.onButtonClicked(title, appName, reason)

                    return true
                end
            end
        end
    end

    return false
end

--- Set up window filter to watch for target apps
function M.setupWatchers()
    local config = M.spoon and M.spoon.config or {}
    local targets = config.targetApps or {}

    -- Window filter for target apps
    M.windowFilter = hs.window.filter.new(targets)

    -- React to window creation
    M.windowFilter:subscribe(hs.window.filter.windowCreated, function(win)
        hs.timer.doAfter((config.uiRenderDelayMs or 100) / 1000, function()
            scanAndClickButtons(win)
        end)
    end)

    -- React to window focus
    M.windowFilter:subscribe(hs.window.filter.windowFocused, function(win)
        hs.timer.doAfter((config.uiRenderDelayMs or 100) / 1000, function()
            scanAndClickButtons(win)
        end)
    end)

    -- Backup polling (catches dialogs that don't trigger events)
    local pollInterval = config.pollIntervalSec or 1.5
    M.pollTimer = hs.timer.doEvery(pollInterval, function()
        if not M.spoon or not M.spoon.enabled then return end

        local focusedWin = hs.window.focusedWindow()
        if focusedWin then
            scanAndClickButtons(focusedWin)
        end
    end)

    -- Watch for app launches to catch new terminal instances
    M.appWatcher = hs.application.watcher.new(function(appName, eventType, app)
        if eventType == hs.application.watcher.launched then
            if isTargetApp(appName) then
                -- Give app time to create windows
                hs.timer.doAfter(1, function()
                    local wins = app:allWindows()
                    for _, win in ipairs(wins) do
                        scanAndClickButtons(win)
                    end
                end)
            end
        end
    end)
    M.appWatcher:start()
end

--- Clean up all watchers
function M.cleanup()
    if M.windowFilter then
        M.windowFilter:unsubscribeAll()
        M.windowFilter = nil
    end

    if M.pollTimer then
        M.pollTimer:stop()
        M.pollTimer = nil
    end

    if M.appWatcher then
        M.appWatcher:stop()
        M.appWatcher = nil
    end
end

--- Force a scan of all target app windows (useful for manual trigger)
function M.scanAllWindows()
    local config = M.spoon and M.spoon.config or {}
    local targets = config.targetApps or {}

    for _, appName in ipairs(targets) do
        local app = hs.application.get(appName)
        if app then
            local wins = app:allWindows()
            for _, win in ipairs(wins) do
                if scanAndClickButtons(win) then
                    return true  -- Stop after first click
                end
            end
        end
    end
    return false
end

return M
