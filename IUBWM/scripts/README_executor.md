Executor README

Purpose
- Host the `loader.lua`, `main.lua`, and `idle.lua` scripts publicly (for example on GitHub raw). Then execute the bootstrap with a common executor using `loadstring(game:HttpGet(url))()`.

Quick paste example (replace URL):

loadstring(game:HttpGet('https://raw.githubusercontent.com/<USER>/<REPO>/main/IUBWM/scripts/main.lua', true))()

Notes
- Edit `base` at the top of `main.lua` to point at the raw hosting path where the scripts live.
- Executors differ: the bootstrap tries `game:HttpGet`, `syn.request`, `http_request`, and `request` in that order.
- This repo originally contained OS-level automation; many features cannot be ported to Roblox. The included `idle.lua` is a simple proof-of-concept that jiggles `HumanoidRootPart` slightly.

Safety & ToS
- Running scripts that manipulate in-game behavior may violate Roblox Terms of Service or game rules. Use at your own risk.

Testing checklist
- Host scripts to a public raw URL.
- Paste the `loadstring(game:HttpGet(...))()` line into an executor (OpiumWare, etc.).
- Verify `"[main] bootstrap complete"` prints in the executor console.
- Call `_G.IUBWM.stopAll()` to stop the idle module.

