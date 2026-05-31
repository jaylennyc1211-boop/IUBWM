-- IUBWM v1.6 - Roblox Executor GUI
-- Port of the IUBWM desktop automation tool

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local cam          = workspace.CurrentCamera
local lp           = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================
local cfg = {
    mode           = 0,     -- 0=Custom, 1=1-Lane, 3=Idle, 4=Wheat, 5=Mixing
    autoClicker    = false, clickDelay  = 200, clickVar   = 50,
    autoWalk       = false,
    autoToggle     = false, toggleInterval = 1000,
    autoCam        = false, camLeftward = true, camReaping = true,
    autoInteract   = false, interactDelay = 100, interactVar = 25,
    autoStop       = false, autoStopMins = 30,
}

-- ============================================================
-- STATE
-- ============================================================
local running     = false
local threads     = {}
local statusLabel -- assigned during GUI build

-- ============================================================
-- INPUT HELPERS
-- ============================================================
local function keyDown(kc) pcall(function() VIM:SendKeyEvent(true,  kc, false, game) end) end
local function keyUp(kc)   pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
local function keyPress(kc, ms) keyDown(kc); task.wait((ms or 50)/1000); keyUp(kc) end

local function lmbClick()
    local x, y = math.floor(cam.ViewportSize.X/2), math.floor(cam.ViewportSize.Y/2)
    pcall(function() VIM:SendMouseButtonEvent(x, y, 0, true,  game, 0) end)
    task.wait(0.05)
    pcall(function() VIM:SendMouseButtonEvent(x, y, 0, false, game, 0) end)
end

-- ============================================================
-- FEATURE LOOPS
-- ============================================================
local function loop_autoClicker()
    while running and cfg.autoClicker do
        lmbClick()
        local d = cfg.clickDelay + math.random(
            -math.max(1, cfg.clickVar), math.max(1, cfg.clickVar))
        task.wait(math.max(1, d) / 1000)
    end
end

local function turnChar(leftward)
    local char = lp.Character; if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, leftward and math.rad(90) or math.rad(-90), 0)
end

local function toggleHarvest()
    cfg.camReaping = not cfg.camReaping
    keyPress(cfg.camReaping and Enum.KeyCode.Two or Enum.KeyCode.One, 50)
end

local function loop_autoCam()
    local REAP = {len = 9.4, wid = 2.2}
    local SOW  = {len = 7.6, wid = 1.6}
    while running and cfg.autoCam do
        local t = cfg.camReaping and REAP or SOW
        task.wait(t.len); if not running then break end; turnChar(cfg.camLeftward)
        task.wait(t.wid); if not running then break end; turnChar(cfg.camLeftward)
        task.wait(t.len); if not running then break end; turnChar(cfg.camLeftward)
        task.wait(t.wid); if not running then break end; turnChar(cfg.camLeftward)
        if cfg.autoToggle then toggleHarvest() end
    end
end

local function loop_autoToggle()
    while running and cfg.autoToggle do
        if not cfg.autoCam then
            task.wait(cfg.toggleInterval / 1000)
            if running then toggleHarvest() end
        else
            task.wait(0.1)
        end
    end
end

local function loop_autoInteract()
    while running and cfg.autoInteract do
        keyDown(Enum.KeyCode.E)
        task.wait(math.max(1, math.random(math.max(1, cfg.interactVar))) / 1000)
        keyUp(Enum.KeyCode.E)
        local d = cfg.interactDelay + math.random(
            -math.max(1, cfg.interactVar), math.max(1, cfg.interactVar))
        task.wait(math.max(1, d) / 1000)
    end
    keyUp(Enum.KeyCode.E)
end

local function loop_autoWalk()
    while running and cfg.autoWalk do
        keyDown(Enum.KeyCode.W); task.wait(0.1)
    end
    keyUp(Enum.KeyCode.W)
end

local function loop_idle()
    while running do
        task.wait(0.5 * math.random(40, 60))
        if not running then break end
        local r = math.random(12)
        if r == 1 then
            task.wait(0.5 * math.random(60, 90))
        elseif r == 2 then
            keyDown(Enum.KeyCode.A); task.wait(0.5 * math.random(1,2)); keyUp(Enum.KeyCode.A)
        elseif r == 3 then
            keyDown(Enum.KeyCode.W); task.wait(0.5 * math.random(1,2)); keyUp(Enum.KeyCode.W)
        elseif r == 4 then
            keyDown(Enum.KeyCode.S); task.wait(0.5 * math.random(1,2)); keyUp(Enum.KeyCode.S)
        elseif r == 5 then
            keyDown(Enum.KeyCode.D); task.wait(0.5 * math.random(1,2)); keyUp(Enum.KeyCode.D)
        elseif r == 6 then
            keyPress(Enum.KeyCode.Space, 50)
            keyDown(Enum.KeyCode.S); task.wait(1); keyUp(Enum.KeyCode.S)
        elseif r == 7 then
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _ = 1, math.random(20, 100) do
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(1), 0); task.wait(0.001)
                end
            end
        elseif r == 8 then
            local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                for _ = 1, math.random(20, 100) do
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(-1), 0); task.wait(0.001)
                end
            end
        else
            lmbClick(); task.wait(0.1)
        end
    end
end

-- ============================================================
-- START / STOP
-- ============================================================
local HELD_KEYS = {
    Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
    Enum.KeyCode.E, Enum.KeyCode.Space, Enum.KeyCode.One, Enum.KeyCode.Two,
}

local function stopAll()
    running = false
    for _, t in ipairs(threads) do pcall(task.cancel, t) end
    threads = {}
    for _, kc in ipairs(HELD_KEYS) do keyUp(kc) end
    if statusLabel then statusLabel.Text = "Status: Stopped" end
end

local function spawnLoop(fn)
    table.insert(threads, task.spawn(fn))
end

local function startAll()
    if running then return end
    running = true
    if statusLabel then statusLabel.Text = "Status: Running" end

    local m = cfg.mode
    if m == 0 or m == 1 or m == 2 then
        if cfg.autoToggle then
            keyPress(cfg.camReaping and Enum.KeyCode.Two or Enum.KeyCode.One, 50)
            spawnLoop(loop_autoToggle)
        end
        if cfg.autoClicker then spawnLoop(loop_autoClicker) end
        if cfg.autoCam     then spawnLoop(loop_autoCam)     end
    end
    if m == 3 then spawnLoop(loop_idle) end
    if cfg.autoInteract then spawnLoop(loop_autoInteract) end
    if cfg.autoWalk     then spawnLoop(loop_autoWalk)     end
    if cfg.autoStop then
        spawnLoop(function()
            local endT = tick() + cfg.autoStopMins * 60
            while running and tick() < endT do task.wait(1) end
            if running then stopAll() end
        end)
    end
end

-- ============================================================
-- GUI
-- ============================================================
local guiParent
if type(gethui) == "function" then
    guiParent = gethui()
else
    guiParent = game:GetService("CoreGui")
end

local existing = guiParent:FindFirstChild("IUBWM_GUI")
if existing then existing:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name          = "IUBWM_GUI"
sg.ResetOnSpawn  = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent        = guiParent

local C = {
    bg      = Color3.fromRGB(22,  22,  32),
    panel   = Color3.fromRGB(32,  32,  48),
    accent  = Color3.fromRGB(75,  115, 215),
    btnGo   = Color3.fromRGB(45,  155, 75),
    btnStop = Color3.fromRGB(175, 55,  55),
    text    = Color3.fromRGB(220, 220, 230),
    dim     = Color3.fromRGB(130, 130, 155),
    check   = Color3.fromRGB(60,  200, 100),
    border  = Color3.fromRGB(50,  50,  72),
}

local function corner(parent, r)
    local u = Instance.new("UICorner"); u.CornerRadius = UDim.new(0, r or 6); u.Parent = parent
end

local function frame(parent, sz, pos, bg, r)
    local f = Instance.new("Frame")
    f.Size = sz; f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or C.bg; f.BorderSizePixel = 0; f.Parent = parent
    if r then corner(f, r) end
    return f
end

local function label(parent, txt, pos, sz, fs, col, xa, ya)
    local l = Instance.new("TextLabel")
    l.Text = txt; l.Position = pos; l.Size = sz
    l.BackgroundTransparency = 1; l.TextColor3 = col or C.text
    l.TextSize = fs or 13; l.Font = Enum.Font.GothamMedium
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = ya or Enum.TextYAlignment.Center
    l.Parent = parent; return l
end

local function button(parent, txt, pos, sz, bg)
    local b = Instance.new("TextButton")
    b.Text = txt; b.Position = pos; b.Size = sz
    b.BackgroundColor3 = bg or C.accent; b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13; b.Font = Enum.Font.GothamBold
    b.BorderSizePixel = 0; b.AutoButtonColor = true
    corner(b, 5); b.Parent = parent; return b
end

local function textbox(parent, def, pos, sz)
    local tb = Instance.new("TextBox")
    tb.Text = tostring(def); tb.Position = pos; tb.Size = sz
    tb.BackgroundColor3 = C.border; tb.TextColor3 = C.text
    tb.TextSize = 12; tb.Font = Enum.Font.Gotham
    tb.BorderSizePixel = 0; tb.ClearTextOnFocus = false
    corner(tb, 4); tb.Parent = parent; return tb
end

-- Window
local WIN_W, WIN_H = 430, 390
local win = frame(sg,
    UDim2.new(0, WIN_W, 0, WIN_H),
    UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2),
    C.bg, 10)
local stroke = Instance.new("UIStroke")
stroke.Color = C.border; stroke.Thickness = 1.5; stroke.Parent = win

-- Title bar
local titleBar = frame(win, UDim2.new(1,0,0,34), UDim2.new(0,0,0,0), C.panel, 10)
frame(titleBar, UDim2.new(1,0,0,17), UDim2.new(0,0,1,-17), C.panel) -- flatten bottom corners
label(titleBar, "IUBWM v1.6", UDim2.new(0,12,0,0), UDim2.new(1,-50,1,0), 15, C.text)
local closeBtn = button(titleBar, "X", UDim2.new(1,-32,0,3), UDim2.new(0,26,0,26), Color3.fromRGB(175,55,55))
closeBtn.MouseButton1Click:Connect(function() stopAll(); sg:Destroy() end)

-- Drag
local dragging, dragStart, winStart = false
titleBar.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    dragging = true; dragStart = i.Position; winStart = win.Position
end)
titleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        win.Position = UDim2.new(winStart.X.Scale, winStart.X.Offset + d.X,
                                  winStart.Y.Scale, winStart.Y.Offset + d.Y)
    end
end)

-- Content
local ct = frame(win, UDim2.new(1,-16,1,-44), UDim2.new(0,8,0,40), C.bg)
local Y = 0

local function sep()
    frame(ct, UDim2.new(1,0,0,1), UDim2.new(0,0,0,Y), C.border)
    Y = Y + 5
end

-- Mode selector
label(ct, "Mode:", UDim2.new(0,0,0,Y), UDim2.new(0,38,0,20), 12, C.dim)
local modeNames = {"Custom","1-Lane","Idle","Wheat","Mixing"}
local modeVals  = {0, 1, 3, 4, 5}
local modeBtns  = {}
local mx = 42
for i, name in ipairs(modeNames) do
    local b = button(ct, name, UDim2.new(0,mx,0,Y+1), UDim2.new(0,60,0,18), C.panel)
    b.TextSize = 11
    b.TextColor3 = C.dim
    modeBtns[i] = b
    mx = mx + 64
end
Y = Y + 24

local function refreshModeBtns(sel)
    for i,b in ipairs(modeBtns) do
        b.BackgroundColor3 = (i==sel) and C.accent or C.panel
        b.TextColor3       = (i==sel) and Color3.new(1,1,1) or C.dim
    end
end
refreshModeBtns(1)

for i, b in ipairs(modeBtns) do
    b.MouseButton1Click:Connect(function()
        cfg.mode = modeVals[i]
        refreshModeBtns(i)
        if modeVals[i] == 1 then -- 1-Lane preset
            cfg.autoClicker = true; cfg.clickDelay = 200; cfg.clickVar = 50
            cfg.autoWalk = true; cfg.autoToggle = true; cfg.toggleInterval = 1000
            cfg.autoCam = true; cfg.camReaping = true
        end
    end)
end

sep()

-- Checkbox row helper
local function checkRow(lbl, cfgKey, extras)
    local row = frame(ct, UDim2.new(1,0,0,22), UDim2.new(0,0,0,Y), C.bg)

    local box  = frame(row, UDim2.new(0,14,0,14), UDim2.new(0,1,0,4), C.border, 3)
    local tick = label(box, cfg[cfgKey] and "✓" or "",
        UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), 11, C.check,
        Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)

    label(row, lbl, UDim2.new(0,20,0,0), UDim2.new(0,90,1,0), 13, C.text)

    local clickZone = Instance.new("TextButton")
    clickZone.Size = UDim2.new(0,110,1,0); clickZone.BackgroundTransparency = 1
    clickZone.Text = ""; clickZone.Parent = row
    clickZone.MouseButton1Click:Connect(function()
        cfg[cfgKey] = not cfg[cfgKey]
        tick.Text = cfg[cfgKey] and "✓" or ""
    end)

    if extras then extras(row) end
    Y = Y + 24
    return row
end

-- Numeric input helper
local function numField(parent, cfgKey, x, lbl)
    label(parent, lbl, UDim2.new(0,x,0,3), UDim2.new(0,26,0,16), 10, C.dim)
    local tb = textbox(parent, cfg[cfgKey], UDim2.new(0,x+24,0,2), UDim2.new(0,40,0,18))
    tb.FocusLost:Connect(function()
        local n = tonumber(tb.Text)
        if n and n >= 0 then cfg[cfgKey] = math.floor(n) end
        tb.Text = tostring(cfg[cfgKey])
    end)
end

-- Toggle button pair helper
local function togglePair(parent, x, lbl1, lbl2, getter, setter)
    local b1 = button(parent, lbl1, UDim2.new(0,x,   0,2), UDim2.new(0,38,0,18),  getter() and C.accent or C.panel)
    local b2 = button(parent, lbl2, UDim2.new(0,x+40,0,2), UDim2.new(0,38,0,18), (not getter()) and C.accent or C.panel)
    b1.TextSize = 11; b2.TextSize = 11
    b1.TextColor3 = getter() and Color3.new(1,1,1) or C.dim
    b2.TextColor3 = (not getter()) and Color3.new(1,1,1) or C.dim
    local function refresh()
        b1.BackgroundColor3 = getter() and C.accent or C.panel
        b1.TextColor3       = getter() and Color3.new(1,1,1) or C.dim
        b2.BackgroundColor3 = (not getter()) and C.accent or C.panel
        b2.TextColor3       = (not getter()) and Color3.new(1,1,1) or C.dim
    end
    b1.MouseButton1Click:Connect(function() setter(true);  refresh() end)
    b2.MouseButton1Click:Connect(function() setter(false); refresh() end)
end

checkRow("AutoClicker", "autoClicker", function(row)
    numField(row, "clickDelay", 120, "Dly")
    numField(row, "clickVar",   190, "Var")
end)
checkRow("AutoWalk", "autoWalk")
checkRow("AutoToggle", "autoToggle", function(row)
    numField(row, "toggleInterval", 120, "ms")
end)
checkRow("AutoCam", "autoCam", function(row)
    togglePair(row, 120, "Left", "Right",
        function() return cfg.camLeftward end,
        function(v) cfg.camLeftward = v end)
    togglePair(row, 202, "Reap", "Sow",
        function() return cfg.camReaping end,
        function(v) cfg.camReaping = v end)
end)
checkRow("AutoInteract", "autoInteract", function(row)
    numField(row, "interactDelay", 120, "Dly")
    numField(row, "interactVar",   190, "Var")
end)

sep()

-- AutoStop row
do
    local row = frame(ct, UDim2.new(1,0,0,22), UDim2.new(0,0,0,Y), C.bg)
    local box  = frame(row, UDim2.new(0,14,0,14), UDim2.new(0,1,0,4), C.border, 3)
    local tick = label(box, "",
        UDim2.new(0,0,0,0), UDim2.new(1,0,1,0), 11, C.check,
        Enum.TextXAlignment.Center, Enum.TextYAlignment.Center)
    label(row, "AutoStop", UDim2.new(0,20,0,0), UDim2.new(0,70,1,0), 13, C.text)
    numField(row, "autoStopMins", 95, "min")
    statusLabel = label(row, "Status: Idle",
        UDim2.new(0,160,0,0), UDim2.new(1,-160,1,0), 12, C.dim,
        Enum.TextXAlignment.Right)

    local cz = Instance.new("TextButton")
    cz.Size = UDim2.new(0,95,1,0); cz.BackgroundTransparency = 1
    cz.Text = ""; cz.Parent = row
    cz.MouseButton1Click:Connect(function()
        cfg.autoStop = not cfg.autoStop
        tick.Text = cfg.autoStop and "✓" or ""
    end)
    Y = Y + 26
end

sep()
Y = Y + 2

-- Start / Stop
local startBtn = button(ct, "START  (F7)", UDim2.new(0,0,0,Y), UDim2.new(0.48,0,0,36), C.btnGo)
startBtn.TextSize = 15
local stopBtn  = button(ct, "STOP",        UDim2.new(0.52,0,0,Y), UDim2.new(0.48,0,0,36), C.btnStop)
stopBtn.TextSize = 15

startBtn.MouseButton1Click:Connect(startAll)
stopBtn.MouseButton1Click:Connect(stopAll)

-- F7 hotkey
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.F7 then
        if running then stopAll() else startAll() end
    end
end)

print("[IUBWM] GUI loaded. Press F7 or click START.")
