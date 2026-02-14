# ClaudeHammer ⚡🔨

## ⚠️ DEFUNCT — No Longer Needed

**ClaudeHammer has been retired.** Claude Code now obeys `CLAUDE.md` permission instructions natively (as of Opus 4.6). The desktop app and CLI both respect your configured permission tiers without needing external automation to click approval dialogs.

If you're still using ClaudeHammer, you can safely uninstall it and configure your `CLAUDE.md` instead. See Anthropic's [CLAUDE.md documentation](https://docs.anthropic.com/en/docs/claude-code/memory#claudemd) for details.

> "This is now defunct. CLAUDE.md actually obeys with Opus 4.6. Desktop app no longer bugging me. Shutting Claudehammer down. Custom software is practically free. Build, use, trash, whatevs."
> — [@mattbeane](https://x.com/mattbeane)

---

## What This Was

ClaudeHammer was a Hammerspoon-based macOS utility that automatically clicked "Allow" and "Yes" in Claude Code permission dialogs. It was built for knowledge workers (researchers, analysts, writers) who found constant permission prompts flow-breaking.

It worked well for its time, but the problem it solved no longer exists.

## Uninstall

```bash
# Remove the spoon
rm -rf ~/.hammerspoon/Spoons/ClaudeAutoAllow.spoon

# Remove from config (edit this file and delete the ClaudeHammer lines)
open ~/.hammerspoon/init.lua

# Optionally remove Hammerspoon entirely (if you don't use it for anything else)
brew uninstall --cask hammerspoon
```

## License

MIT

## Credits

Built by [Matt Beane](https://github.com/mattbeane) (a researcher, not a developer) with Claude.

Born from the realization that clicking "Yes" 50 times per hour is not a good use of anyone's time. Died because the upstream problem got fixed.
