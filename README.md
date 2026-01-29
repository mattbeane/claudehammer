# ClaudeHammer ⚡🔨

**Stop babysitting Claude Code permission prompts.**

Claude Code asks for permission constantly—even when you've already said "always allow." This interrupts your flow and defeats the purpose of an AI coding assistant.

ClaudeHammer uses Hammerspoon to automatically click "Allow" and "Yes" buttons in your terminal. It's like having a very patient intern who just clicks "Yes" for you.

## Safety First

| ✅ Auto-clicks | ❌ Never clicks |
|---------------|-----------------|
| Yes | Delete |
| Allow | Remove |
| Confirm | Purchase |
| OK | Send |
| Proceed | Unsubscribe |
| Continue | Subscribe |
| Accept | Share |

- **Full audit log** of every click at `~/.hammerspoon/claude-auto-allow.log`
- **One-click pause** from menubar
- **Hardcoded blocklist** prevents dangerous clicks even if misconfigured
- **Open source** - inspect the code yourself

## Quick Install

```bash
# Requires Homebrew
brew install --cask hammerspoon

# Install ClaudeHammer
curl -sL https://raw.githubusercontent.com/mattbeane/claudehammer/main/install.sh | bash
```

## Manual Install

1. [Download the latest release](https://github.com/mattbeane/claudehammer/releases)
2. Double-click `ClaudeAutoAllow.spoon.zip` to extract
3. Double-click `ClaudeAutoAllow.spoon` to install
4. Add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("ClaudeAutoAllow"):start()
```

5. Reload Hammerspoon (click menubar icon → Reload Config)

## After Install

1. **Grant Accessibility permissions** when prompted
   - System Settings → Privacy & Security → Accessibility → Enable Hammerspoon
2. Look for **⚡** in your menubar (active) or **⏸** (paused)
3. Start using Claude Code!

## Supported Terminals

- Terminal.app ✓
- iTerm2 ✓
- Warp ✓
- Kitty ✓
- Alacritty ✓
- Ghostty ✓
- WezTerm ✓
- Hyper ✓
- Rio ✓
- Tabby ✓

## Configuration

```lua
-- Basic usage
hs.loadSpoon("ClaudeAutoAllow"):start()

-- Add a toggle hotkey
spoon.ClaudeAutoAllow:bindHotkeys({
    toggle = {{"cmd", "shift"}, "A"}
})

-- Disable sound (already off by default)
spoon.ClaudeAutoAllow.config.soundEnabled = false

-- Disable on-screen alerts
spoon.ClaudeAutoAllow.config.alertEnabled = false

-- Add a custom button to the allowlist
spoon.ClaudeAutoAllow:addAllowedButton("My Custom Button")

-- Only monitor specific terminals
spoon.ClaudeAutoAllow:setTargetApps({"iTerm2", "Terminal"})
```

## Menubar

Click the **⚡** icon to:
- Toggle on/off
- View recent auto-clicks
- See click statistics
- Open the audit log
- Adjust settings

## FAQ

**Q: Is this safe?**
A: Yes. The hardcoded blocklist prevents clicking anything destructive (Delete, Purchase, Send, etc.) even if you misconfigure it. Every click is logged.

**Q: Why not just use `--dangerously-skip-permissions`?**
A: That flag is all-or-nothing and doesn't work in the Claude desktop app. This gives you auto-approve UX with per-action logging.

**Q: Will this click on things outside Claude Code?**
A: No. It only operates on configured terminal apps, only on buttons in the allowlist.

**Q: Can I add my own buttons to auto-click?**
A: Yes, use `:addAllowedButton("Button Text")`. The blocklist still applies.

**Q: How do I audit what it clicked?**
A: Click the menubar icon → View Audit Log, or open `~/.hammerspoon/claude-auto-allow.log`

## Troubleshooting

### "Hammerspoon needs Accessibility permissions"

1. System Settings → Privacy & Security → Accessibility
2. Click the + button
3. Add Hammerspoon from Applications
4. Ensure the checkbox is enabled
5. Reload Hammerspoon

### Not clicking buttons

1. Check that your terminal is in the target list (see Configuration)
2. Ensure the button text matches the allowlist exactly
3. Check the Hammerspoon console for errors (menubar icon → Console)

### Clicking too slowly

The default poll interval is 1.5 seconds. For faster response:

```lua
spoon.ClaudeAutoAllow.config.pollIntervalSec = 0.5
```

## Development

```bash
# Clone to Spoons directory
cd ~/.hammerspoon/Spoons
git clone https://github.com/mattbeane/claudehammer.git ClaudeAutoAllow.spoon

# Edit files and reload Hammerspoon to test
```

## License

MIT - Use at your own risk, but it's probably fine.

## Credits

Built by [Matt Beane](https://github.com/mattbeane) with Claude.

Inspired by everyone who's ever clicked "Yes" 47 times in one Claude Code session.
