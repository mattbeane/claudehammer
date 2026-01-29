--- UI module for ClaudeAutoAllow
--- Handles menubar, alerts, sounds, and audit logging

local M = {}

-- Module state (set by init.lua)
M.spoon = nil
M.menubar = nil
M.recentActions = {}

-- Log file path
local LOG_PATH = os.getenv("HOME") .. "/.hammerspoon/claude-auto-allow.log"

--- Initialize the menubar
--- @param spoon table The main spoon object
function M.setupMenubar(spoon)
    M.spoon = spoon

    if not spoon.config.showMenubar then
        return
    end

    M.menubar = hs.menubar.new(true, "ClaudeAutoAllow")
    M.updateMenubarIcon()
    M.menubar:setTooltip("Claude Auto-Allow")
    M.menubar:setMenu(M.buildMenu)
end

--- Build the menubar menu
--- @return table Menu items
function M.buildMenu()
    local spoon = M.spoon
    local config = spoon.config
    local stats = spoon.stats

    local menu = {
        -- Status toggle
        {
            title = spoon.enabled and "✓ Enabled" or "○ Disabled",
            fn = function() spoon:toggle() end,
        },
        { title = "-" },

        -- Recent actions submenu
        {
            title = "Recent Actions",
            menu = M.buildRecentActionsMenu(),
        },

        -- Statistics submenu
        {
            title = "Statistics",
            menu = {
                { title = string.format("Today: %d clicks", stats.today or 0), disabled = true },
                { title = string.format("Total: %d clicks", stats.total or 0), disabled = true },
                { title = "-" },
                { title = stats.lastAction and string.format("Last: %s at %s", stats.lastAction, stats.lastActionTime or "?") or "No actions yet", disabled = true },
            },
        },

        { title = "-" },

        -- Settings submenu
        {
            title = "Settings",
            menu = {
                {
                    title = config.alertEnabled and "✓ Show Alerts" or "○ Show Alerts",
                    fn = function()
                        config.alertEnabled = not config.alertEnabled
                        require("config").save(config)
                    end,
                },
                {
                    title = config.soundEnabled and "✓ Play Sound" or "○ Play Sound",
                    fn = function()
                        config.soundEnabled = not config.soundEnabled
                        require("config").save(config)
                    end,
                },
                {
                    title = config.logEnabled and "✓ Audit Logging" or "○ Audit Logging",
                    fn = function()
                        config.logEnabled = not config.logEnabled
                        require("config").save(config)
                    end,
                },
            },
        },

        { title = "-" },

        -- Actions
        { title = "View Audit Log", fn = M.openAuditLog },
        { title = "Reload", fn = function() spoon:stop(); spoon:start() end },

        { title = "-" },

        -- About
        {
            title = "About",
            fn = M.showAbout,
        },
    }

    return menu
end

--- Build the recent actions submenu
--- @return table Menu items
function M.buildRecentActionsMenu()
    if #M.recentActions == 0 then
        return {{ title = "No actions yet", disabled = true }}
    end

    local menu = {}
    for i, action in ipairs(M.recentActions) do
        if i > 10 then break end  -- Show only last 10
        table.insert(menu, {
            title = string.format("%s - %s in %s", action.time, action.button, action.app),
            disabled = true,
        })
    end

    table.insert(menu, { title = "-" })
    table.insert(menu, {
        title = "View Full Log",
        fn = M.openAuditLog,
    })

    return menu
end

--- Update the menubar icon based on state
function M.updateMenubarIcon()
    if not M.menubar then return end

    local spoon = M.spoon
    if not spoon then return end

    -- Use text icons (PDF icons could be added later)
    if spoon.enabled then
        M.menubar:setTitle("⚡")  -- Lightning bolt = active
    else
        M.menubar:setTitle("⏸")   -- Pause = paused
    end
end

--- Flash the menubar to indicate a click happened
function M.flashMenubar()
    if not M.menubar then return end

    M.menubar:setTitle("✓")
    hs.timer.doAfter(0.5, function()
        M.updateMenubarIcon()
    end)
end

--- Show an on-screen alert
--- @param message string The message to show
--- @param duration number|nil Duration in seconds (default from config)
function M.showAlert(message, duration)
    local config = M.spoon and M.spoon.config or {}
    if not config.alertEnabled then return end

    duration = duration or config.alertDurationSec or 1

    hs.alert.show(message, {
        strokeWidth = 0,
        fillColor = { white = 0, alpha = 0.75 },
        textColor = { white = 1, alpha = 1 },
        textSize = 14,
        radius = 8,
        padding = 12,
    }, duration)
end

--- Play a subtle sound
function M.playSound()
    local config = M.spoon and M.spoon.config or {}
    if not config.soundEnabled then return end

    local sound = hs.sound.getByName("Pop")
    if sound then
        sound:volume(0.3)
        sound:play()
    end
end

--- Log an action to the audit log
--- @param buttonTitle string What button was clicked
--- @param appName string Which app it was in
--- @param reason string|nil Why it was allowed
function M.logAction(buttonTitle, appName, reason)
    local config = M.spoon and M.spoon.config or {}
    if not config.logEnabled then return end

    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("[%s] Clicked '%s' in %s%s\n",
        timestamp,
        buttonTitle,
        appName,
        reason and string.format(" (%s)", reason) or ""
    )

    -- Append to file
    local file = io.open(LOG_PATH, "a")
    if file then
        file:write(entry)
        file:close()
    end

    -- Keep in memory
    table.insert(M.recentActions, 1, {
        time = os.date("%H:%M:%S"),
        button = buttonTitle,
        app = appName,
        reason = reason,
    })

    -- Trim to max
    local maxRecent = config.maxRecentActions or 50
    while #M.recentActions > maxRecent do
        table.remove(M.recentActions)
    end
end

--- Open the audit log in the default text editor
function M.openAuditLog()
    -- Create file if it doesn't exist
    local file = io.open(LOG_PATH, "a")
    if file then
        file:close()
    end

    hs.execute("open " .. LOG_PATH)
end

--- Show the about dialog
function M.showAbout()
    local message = [[
Claude Auto-Allow v1.0

Automatically clicks "Allow" and "Yes" buttons
in Claude Code permission dialogs.

SAFETY:
• Only clicks pre-approved buttons
• Never clicks Delete, Purchase, etc.
• All actions logged to audit file

CONTROLS:
• Click menubar icon to toggle
• Cmd+Shift+A to toggle (if bound)

github.com/mattbeane/ClaudeAutoAllow
]]

    hs.dialog.alert(
        100, 100,
        function() end,
        "About Claude Auto-Allow",
        message,
        "OK"
    )
end

--- Show the first-run welcome dialog
function M.showWelcome()
    local message = [[
Welcome to Claude Auto-Allow!

This tool automatically clicks "Allow" and "Yes"
buttons in Claude Code permission dialogs.

SAFETY FEATURES:
• Only clicks pre-approved safe buttons
• Never clicks Delete, Purchase, Send, etc.
• All actions logged for your review

CONTROLS:
• ⚡ in menubar = active
• Click to see recent actions & toggle
• View audit log anytime from menu

Happy coding!
]]

    hs.dialog.alert(
        100, 100,
        function() end,
        "Claude Auto-Allow",
        message,
        "Let's go!"
    )
end

--- Handle a successful button click (call all feedback methods)
--- @param buttonTitle string What was clicked
--- @param appName string Which app
--- @param reason string|nil Why it was allowed
function M.onButtonClicked(buttonTitle, appName, reason)
    M.flashMenubar()
    M.playSound()
    M.showAlert(string.format("Auto-allowed: %s", buttonTitle))
    M.logAction(buttonTitle, appName, reason)
end

--- Clean up menubar on stop
function M.cleanup()
    if M.menubar then
        M.menubar:delete()
        M.menubar = nil
    end
end

return M
