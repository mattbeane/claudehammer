--- Safety module for ClaudeAutoAllow
--- Handles allowlist/blocklist validation to prevent clicking dangerous buttons

local M = {}

-- Buttons we WILL auto-click (safe, permission-granting actions)
M.ALLOWED_BUTTONS = {
    -- Claude Code specific
    "Yes",
    "Yes, allow once",
    "Yes, during this session",
    "Yes, always for this project",
    "Allow",
    "Allow once",
    "Allow always",
    "Allow for this session",
    "Proceed",
    "Continue",
    "OK",
    "Confirm",
    "Accept",
    "Approve",
    "Run",
    "Execute",
    "Grant",
}

-- Buttons we will NEVER click, even if user adds them to allowlist
-- This is a safety net against misconfiguration
M.BLOCKED_BUTTONS = {
    -- Destructive actions
    "Delete",
    "Delete All",
    "Remove",
    "Remove All",
    "Unsubscribe",
    "Cancel subscription",
    "Revoke",
    "Terminate",
    "Destroy",
    "Erase",
    "Wipe",
    "Format",
    "Reset",
    "Reset All",
    "Clear all",
    "Clear data",
    "Factory reset",
    "Permanently delete",

    -- Financial/account actions
    "Purchase",
    "Buy",
    "Buy now",
    "Pay",
    "Pay now",
    "Subscribe",
    "Start subscription",
    "Upgrade",
    "Downgrade",
    "Add payment",
    "Charge",
    "Bill",

    -- Permission escalation
    "Grant admin",
    "Make admin",
    "Allow all",
    "Trust always",
    "Disable security",
    "Turn off protection",
    "Skip verification",

    -- Sending/sharing/publishing
    "Send",
    "Send All",
    "Send now",
    "Post",
    "Publish",
    "Share",
    "Share publicly",
    "Tweet",
    "Email",
    "Forward",
    "Broadcast",
    "Submit",
    "Upload",

    -- Account actions
    "Sign out",
    "Log out",
    "Deactivate",
    "Close account",
    "Delete account",
}

-- Suspicious keywords in window titles that should prevent auto-clicking
M.SUSPICIOUS_CONTEXTS = {
    "payment",
    "billing",
    "invoice",
    "subscription",
    "upgrade",
    "premium",
    "purchase",
    "checkout",
    "cart",
    "order",
    "delete",
    "remove",
    "unsubscribe",
    "cancel",
    "terminate",
    "password",
    "credential",
    "admin",
    "root",
    "sudo",
}

--- Check if a string exactly matches any item in a list (case-insensitive)
--- @param list table List of strings to match against
--- @param str string String to check
--- @return boolean
local function exactMatch(list, str)
    if not str then return false end
    local lower = str:lower()
    for _, item in ipairs(list) do
        if item:lower() == lower then
            return true
        end
    end
    return false
end

--- Check if a string contains any blocked keyword
--- @param str string String to check
--- @return boolean
local function containsBlocked(str)
    if not str then return false end
    local lower = str:lower()
    for _, blocked in ipairs(M.BLOCKED_BUTTONS) do
        if lower:find(blocked:lower(), 1, true) then
            return true
        end
    end
    return false
end

--- Check if context (window title) contains suspicious keywords
--- @param context string Window title or other context
--- @return boolean
local function containsSuspicious(context)
    if not context then return false end
    local lower = context:lower()
    for _, keyword in ipairs(M.SUSPICIOUS_CONTEXTS) do
        if lower:find(keyword, 1, true) then
            return true
        end
    end
    return false
end

--- Validate whether a button is safe to click
--- @param buttonTitle string The button's title/label
--- @param appName string The application name
--- @param windowTitle string|nil Optional window title for context
--- @param customAllowed table|nil Optional custom allowlist
--- @return boolean safe Whether the button is safe to click
--- @return string reason The reason for the decision
function M.isButtonSafe(buttonTitle, appName, windowTitle, customAllowed)
    -- 1. Exact match against hardcoded blocklist = NEVER (safety net)
    if exactMatch(M.BLOCKED_BUTTONS, buttonTitle) then
        return false, "blocked_exact"
    end

    -- 2. Fuzzy match against blocklist (button contains blocked word)
    if containsBlocked(buttonTitle) then
        return false, "blocked_fuzzy"
    end

    -- 3. Check window title for suspicious context
    if windowTitle and containsSuspicious(windowTitle) then
        return false, "suspicious_context"
    end

    -- 4. Check against allowlist (custom or default)
    local allowlist = customAllowed or M.ALLOWED_BUTTONS
    if exactMatch(allowlist, buttonTitle) then
        return true, "allowed"
    end

    -- 5. Default: don't click unknown buttons
    return false, "unknown"
end

--- Get a human-readable explanation for a safety decision
--- @param reason string The reason code from isButtonSafe
--- @return string
function M.explainReason(reason)
    local explanations = {
        blocked_exact = "Button is on the permanent blocklist",
        blocked_fuzzy = "Button contains a blocked keyword",
        suspicious_context = "Window context appears suspicious",
        allowed = "Button is on the allowlist",
        unknown = "Button not recognized (not auto-clicked)",
        wrong_app = "Not a monitored application",
    }
    return explanations[reason] or "Unknown reason"
end

return M
