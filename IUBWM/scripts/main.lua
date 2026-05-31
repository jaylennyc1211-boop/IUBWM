-- IUBWM 1.6.2 — Insomniac Ultimate Breadwinner Macro
-- Full Roblox executor port of github.com/TNT20002220/IUBWM

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local VIM     = game:GetService("VirtualInputManager")
local cam     = workspace.CurrentCamera
local lp      = Players.LocalPlayer

-- ─── CONFIG (matches FormMain designer defaults) ──────────────────────────
local cfg = {
    mode           = 0,      -- 0=Custom 1=1Lane 2=Field 3=Idle 4=Thresh 5=Mixing
    autoClicker    = false,  clickDelay  = 200, clickVar   = 50,
    autoWalk       = false,
    autoToggle     = false,  toggleMs    = 10000,
    autoCam        = false,  camLeft     = true,
    reaping        = true,   -- initial harvest mode (true=reap/2, false=sow/1)
    autoInteract   = false,  interactDelay = 100, interactVar = 25,
    autoStop       = false,  autoStopMins  = 180,
    autoInvite     = false,
    homeX=0,  homeY=0,  inviteX=0,  inviteY=0,  closeX=0,  closeY=0,
    faucetX=0, faucetY=0, trickleTime=12, maxFlow=1200,
}

-- ─── STATE ────────────────────────────────────────────────────────────────
local running = false
local threads = {}
local uiStatus, uiAction, uiTimer  -- set by GUI

-- ─── INPUT ────────────────────────────────────────────────────────────────
local function kd(kc) pcall(function() VIM:SendKeyEvent(true,  kc, false, game) end) end
local function ku(kc) pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
local function kp(kc, ms) kd(kc); task.wait((ms or 50)/1000); ku(kc) end

local function cx() return math.floor(cam.ViewportSize.X/2) end
local function cy() return math.floor(cam.ViewportSize.Y/2) end

local function lmbdown(x,y)  pcall(function() VIM:SendMouseButtonEvent(x or cx(),y or cy(),0,true, game,0) end) end
local function lmbup(x,y)    pcall(function() VIM:SendMouseButtonEvent(x or cx(),y or cy(),0,false,game,0) end) end
local function rmbdown(x,y)  pcall(function() VIM:SendMouseButtonEvent(x or cx(),y or cy(),1,true, game,0) end) end
local function rmbup(x,y)    pcall(function() VIM:SendMouseButtonEvent(x or cx(),y or cy(),1,false,game,0) end) end
local function mmove(x,y)    pcall(function() VIM:SendMouseMoveEvent(x,y,game) end) end

local function lclick(x,y)
    lmbdown(x,y); task.wait(0.05); lmbup(x,y)
end

-- Replicates InputSimulator.Turn90Degrees: 26×±10px + ±8px = ±268px, RMB held
local function turn90(left)
    local dir = left and -1 or 1
    local ox = cx(); local oy = cy()
    rmbdown(ox, oy); task.wait(0.016)
    local x = ox
    for _ = 1, 26 do x = x + dir*10; mmove(x, oy); task.wait(0.001) end
    x = x + dir*8; mmove(x, oy); task.wait(0.016)
    rmbup(x, oy); task.wait(0.016)
    mmove(ox, oy)  -- reset to center
end

-- key 1 = sow, key 2 = reap  (matches ToggleHarvestMode in C#)
local function toggleHarvest()
    if cfg.reaping then
        cfg.reaping = false; kp(Enum.KeyCode.One, 50)
    else
        cfg.reaping = true;  kp(Enum.KeyCode.Two, 50)
    end
end

-- ─── FEATURE LOOPS ────────────────────────────────────────────────────────

local function loop_clicker()
    while running and cfg.autoClicker do
        lclick()
        local v = math.max(1, cfg.clickVar)
        task.wait(math.max(1, cfg.clickDelay + math.random(-v, v)) / 1000)
    end
end

local function loop_walk()
    while running and cfg.autoWalk do kd(Enum.KeyCode.W); task.wait(0.1) end
    ku(Enum.KeyCode.W)
end

-- AutoCam: rectangular laning — reap 9.4s/2.2s, sow 7.6s/1.6s
local function loop_cam()
    local R = {len=9.4, wid=2.2}
    local S = {len=7.6, wid=1.6}
    while running and cfg.autoCam do
        local t = cfg.reaping and R or S
        task.wait(t.len); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.wid); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.len); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.wid); if not running then break end; turn90(cfg.camLeft)
        if cfg.autoToggle then toggleHarvest() end
        -- drift correction nudge (original: ±1px)
        mmove(cx() + (cfg.camLeft and 1 or -1), cy()); task.wait(0.016); mmove(cx(), cy())
    end
end

-- AutoToggle: fires interval when autoCam is not driving it
local function loop_toggle()
    while running and cfg.autoToggle do
        if not cfg.autoCam then
            task.wait(cfg.toggleMs / 1000)
            if running then toggleHarvest() end
        else
            task.wait(0.1)
        end
    end
end

-- AutoInteract: mirrors RunLoop's autoInteract block (50ms main tick)
local function loop_interact()
    while running and cfg.autoInteract do
        local v = math.max(1, cfg.interactVar)
        kd(Enum.KeyCode.E)
        task.wait(math.random(1, v) / 1000)
        ku(Enum.KeyCode.E)
        task.wait(math.max(1, cfg.interactDelay + math.random(-v, v)) / 1000)
        task.wait(0.05)  -- mirrors the 50ms main loop tick
    end
    ku(Enum.KeyCode.E)
end

-- IdlingLoop — faithful port of FormMain.IdlingLoop
local function loop_idle()
    if uiAction then uiAction.Text = "..." end
    local inviteStart = tick()

    if cfg.autoInvite then
        if uiAction then uiAction.Text = "Invite" end
        mmove(cfg.homeX,   cfg.homeY);   task.wait(0.01); lclick(); task.wait(0.1)
        mmove(cfg.inviteX, cfg.inviteY); task.wait(0.01); lclick(); task.wait(0.1)
        mmove(cfg.closeX,  cfg.closeY);  task.wait(0.01); lclick()
    end

    while running do
        local wt = 500 * math.random(40, 60)
        if uiAction then uiAction.Text = "Wait "..math.floor(wt/1000).."s" end
        task.wait(wt / 1000)
        if not running then break end

        local r = math.random(0, 11)  -- r.Next(12) = 0..11

        if r == 0 then
            if cfg.autoInvite then
                local ht = 500 * math.random(120, 241)
                if uiAction then uiAction.Text = "Wait "..math.floor(ht/1000).."s (Host)" end
                task.wait(ht / 1000)
            end
        elseif r == 1 then
            if uiAction then uiAction.Text = "Move Left" end
            kd(Enum.KeyCode.A); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.A)
        elseif r == 2 then
            if uiAction then uiAction.Text = "Move Forward" end
            kd(Enum.KeyCode.W); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.W)
        elseif r == 3 then
            if uiAction then uiAction.Text = "Move Back" end
            kd(Enum.KeyCode.S); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.S)
        elseif r == 4 then
            if uiAction then uiAction.Text = "Move Right" end
            kd(Enum.KeyCode.D); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.D)
        elseif r == 5 then
            if uiAction then uiAction.Text = "Jump" end
            kp(Enum.KeyCode.Space, 50)
            kd(Enum.KeyCode.S); task.wait(1); ku(Enum.KeyCode.S)
        elseif r == 6 then
            if uiAction then uiAction.Text = "Turn Cam" end
            local ox,oy = cx(),cy(); rmbdown(ox,oy)
            local x = ox
            for _ = 1, math.random(20,100) do x=x+1; mmove(x,oy); task.wait(0.001) end
            rmbup(x,oy); mmove(ox,oy)
        elseif r == 7 then
            if uiAction then uiAction.Text = "Turn Cam" end
            local ox,oy = cx(),cy(); rmbdown(ox,oy)
            local x = ox
            for _ = 1, math.random(20,100) do x=x-1; mmove(x,oy); task.wait(0.001) end
            rmbup(x,oy); mmove(ox,oy)
        else  -- 8,9,10,11
            if uiAction then uiAction.Text = "Click" end
            lclick(); task.wait(0.1)
        end

        -- Invite timer check (5 minutes = 300s)
        if tick() - inviteStart >= 300 then
            if cfg.autoInvite then
                if uiAction then uiAction.Text = "Invite" end
                mmove(cfg.homeX,   cfg.homeY);   task.wait(0.01); lclick(); task.wait(0.1)
                mmove(cfg.inviteX, cfg.inviteY); task.wait(0.01); lclick(); task.wait(0.1)
                mmove(cfg.closeX,  cfg.closeY);  task.wait(0.01); lclick()
                kp(Enum.KeyCode.Space, 50)
                local dirs = {Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D}
                local dk = dirs[math.random(4)]
                kd(dk); task.wait(4); ku(dk)
            end
            inviteStart = tick()
        end
    end

    if uiAction then uiAction.Text = "..." end
end

-- MixingLoop — port of FormMain.MixingLoop (cursor shape detection omitted)
local function loop_mixing()
    while running do
        local fx, fy = cfg.faucetX, cfg.faucetY

        -- Move to faucet, left-drag right 200px (full flow)
        mmove(fx, fy); task.wait(0.03)
        lmbdown(fx, fy); task.wait(0.03)
        for i = 1, 20 do mmove(fx + i*10, fy); task.wait(0.001) end
        task.wait(cfg.maxFlow / 1000)

        -- Drag back -190px + 15px net
        for i = 1, 19 do mmove(fx + (20-i)*10, fy); task.wait(0.003) end
        mmove(fx + 15, fy); task.wait(0.05)
        lmbup(fx + 15, fy)

        -- Trickle wait (trickleTime * 2 * 500ms)
        for _ = 1, cfg.trickleTime * 2 do
            if not running then break end
            task.wait(0.5)
        end

        -- Return mouse -268px (mirror of turn90), walk to interact
        local x = fx + 15
        for _ = 1, 10 do x = x - 26; mmove(x, fy); task.wait(0.001) end
        x = x - 8; mmove(x, fy)
        kd(Enum.KeyCode.W); task.wait(1.7); ku(Enum.KeyCode.W)
        kp(Enum.KeyCode.E, 50)

        -- Walk to mixing bowl position
        for _ = 1, 10 do x = x + 52; mmove(x, fy); task.wait(0.001) end
        mmove(x + 16, fy + 4)
        kd(Enum.KeyCode.W); kd(Enum.KeyCode.D); task.wait(0.05); ku(Enum.KeyCode.D)
        task.wait(1.35)
        local v = math.max(1, cfg.interactVar)
        kp(Enum.KeyCode.E, math.random(1, v)); task.wait(0.2)
        kp(Enum.KeyCode.E, math.random(1, v))
        ku(Enum.KeyCode.W)
        kp(Enum.KeyCode.E, 50)
        task.wait(1)
    end
end

-- ─── START / STOP ─────────────────────────────────────────────────────────
local KEYS = {
    Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
    Enum.KeyCode.E,Enum.KeyCode.Space,Enum.KeyCode.One,Enum.KeyCode.Two,
}

local function stopAll()
    running = false
    for _, t in ipairs(threads) do pcall(task.cancel, t) end
    threads = {}
    for _, k in ipairs(KEYS) do ku(k) end
    if uiStatus then uiStatus.Text = "● Stopped"; uiStatus.TextColor3 = Color3.fromRGB(160,60,60) end
    if uiTimer  then uiTimer.Text = "00:00:00" end
    if uiAction then uiAction.Text = "..." end
end

local function spawn_(fn) table.insert(threads, task.spawn(fn)) end

local function startAll()
    if running then return end
    running = true
    if uiStatus then uiStatus.Text = "● Running"; uiStatus.TextColor3 = Color3.fromRGB(60,200,100) end

    local m = cfg.mode
    if m == 0 or m == 1 or m == 2 then
        if cfg.autoToggle then
            kp(cfg.reaping and Enum.KeyCode.Two or Enum.KeyCode.One, 50)
            spawn_(loop_toggle)
        end
        if cfg.autoClicker then spawn_(loop_clicker) end
        if cfg.autoCam     then spawn_(loop_cam)     end
    end
    if m == 3 then spawn_(loop_idle)    end
    if m == 5 then spawn_(loop_mixing)  end
    if cfg.autoInteract then spawn_(loop_interact) end
    if cfg.autoWalk     then spawn_(loop_walk)     end

    -- modes that force walk (walk loop not otherwise started)
    if not cfg.autoWalk and (m == 1 or m == 4) then
        spawn_(function()
            while running do kd(Enum.KeyCode.W); task.wait(0.1) end
            ku(Enum.KeyCode.W)
        end)
    end

    if cfg.autoStop then
        spawn_(function()
            local secs = cfg.autoStopMins * 60
            local endT = tick() + secs
            while running and tick() < endT do
                task.wait(1)
                local rem = math.max(0, math.floor(endT - tick()))
                if uiTimer then
                    uiTimer.Text = string.format("%02d:%02d:%02d",
                        math.floor(rem/3600), math.floor(rem%3600/60), rem%60)
                end
            end
            if running then stopAll() end
        end)
    end
end

-- ─── GUI ──────────────────────────────────────────────────────────────────
local guiParent
if type(gethui)=="function" then pcall(function() guiParent=gethui() end) end
guiParent = guiParent or game:GetService("CoreGui")
local old = guiParent:FindFirstChild("IUBWM_GUI")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name="IUBWM_GUI"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=guiParent

local C = {
    bg      = Color3.fromRGB(20,20,30),
    panel   = Color3.fromRGB(30,30,45),
    border  = Color3.fromRGB(50,50,72),
    accent  = Color3.fromRGB(97,35,12),   -- original button color
    hot     = Color3.fromRGB(130,50,18),
    go      = Color3.fromRGB(45,150,70),
    stop    = Color3.fromRGB(160,50,50),
    text    = Color3.fromRGB(220,220,230),
    dim     = Color3.fromRGB(130,130,155),
    tick    = Color3.fromRGB(60,200,100),
    white   = Color3.new(1,1,1),
}

local function newF(par,sz,pos,bg,r)
    local f=Instance.new("Frame"); f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or C.bg; f.BorderSizePixel=0; f.Parent=par
    if r then local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,r); u.Parent=f end
    return f
end
local function newL(par,txt,pos,sz,fs,col,xa)
    local l=Instance.new("TextLabel"); l.Text=txt; l.Position=pos; l.Size=sz
    l.BackgroundTransparency=1; l.TextColor3=col or C.text; l.TextSize=fs or 13
    l.Font=Enum.Font.GothamMedium; l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center; l.Parent=par; return l
end
local function newB(par,txt,pos,sz,bg,tc)
    local b=Instance.new("TextButton"); b.Text=txt; b.Position=pos; b.Size=sz
    b.BackgroundColor3=bg or C.accent; b.TextColor3=tc or C.white
    b.TextSize=13; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.AutoButtonColor=true
    local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,5); u.Parent=b
    b.Parent=par; return b
end
local function newTB(par,val,pos,sz)
    local t=Instance.new("TextBox"); t.Text=tostring(val); t.Position=pos; t.Size=sz
    t.BackgroundColor3=C.border; t.TextColor3=C.text; t.TextSize=12
    t.Font=Enum.Font.Gotham; t.BorderSizePixel=0; t.ClearTextOnFocus=false
    local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,4); u.Parent=t
    t.Parent=par; return t
end

-- number field tied to cfg key
local function numF(par,key,x,y,w,lbl)
    if lbl then newL(par,lbl,UDim2.new(0,x,0,y),UDim2.new(0,26,0,16),10,C.dim); x=x+24 end
    local tb=newTB(par,cfg[key],UDim2.new(0,x,0,y+1),UDim2.new(0,w or 52,0,18))
    tb.FocusLost:Connect(function()
        local n=tonumber(tb.Text); if n then cfg[key]=math.max(0,math.floor(n)) end
        tb.Text=tostring(cfg[key])
    end)
    return tb
end

-- checkbox tied to cfg key, returns hit zone
local function chk(par,lbl,key,x,y,cb)
    local box=newF(par,UDim2.new(0,14,0,14),UDim2.new(0,x,0,y+2),C.border,3)
    local tick=newL(box,cfg[key] and "✓" or "",UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),11,C.tick,Enum.TextXAlignment.Center)
    tick.TextYAlignment=Enum.TextYAlignment.Center
    newL(par,lbl,UDim2.new(0,x+18,0,y),UDim2.new(0,110,0,18),13,C.text)
    local hit=Instance.new("TextButton"); hit.Size=UDim2.new(0,130,0,18)
    hit.Position=UDim2.new(0,x,0,y); hit.BackgroundTransparency=1; hit.Text=""; hit.Parent=par
    hit.MouseButton1Click:Connect(function()
        cfg[key]=not cfg[key]; tick.Text=cfg[key] and "✓" or ""
        if cb then cb(cfg[key]) end
    end)
    return hit, tick
end

-- radio pair: two buttons, val=true selects first
local function radio(par,x,y,l1,l2,getF,setF)
    local function mk(lbl,px,isOn)
        return newB(par,lbl,UDim2.new(0,px,0,y),UDim2.new(0,46,0,18),
            isOn and C.hot or C.panel, isOn and C.white or C.dim)
    end
    local b1=mk(l1,x, getF())
    local b2=mk(l2,x+48, not getF())
    local function ref()
        b1.BackgroundColor3=getF() and C.hot or C.panel; b1.TextColor3=getF() and C.white or C.dim
        b2.BackgroundColor3=(not getF()) and C.hot or C.panel; b2.TextColor3=(not getF()) and C.white or C.dim
    end
    b1.TextSize=11; b2.TextSize=11
    b1.MouseButton1Click:Connect(function() setF(true);  ref() end)
    b2.MouseButton1Click:Connect(function() setF(false); ref() end)
    return b1,b2
end

-- ── Window ────────────────────────────────────────────────────────────────
local WW,WH = 700,510
local win=newF(sg,UDim2.new(0,WW,0,WH),UDim2.new(0.5,-WW/2,0.5,-WH/2),C.bg,10)
local ws2=Instance.new("UIStroke"); ws2.Color=C.border; ws2.Thickness=1.5; ws2.Parent=win

-- Title bar
local tbar=newF(win,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),C.panel,10)
newF(tbar,UDim2.new(1,0,0,15),UDim2.new(0,0,1,-15),C.panel)
newL(tbar,"IUBWM 1.6.2 — Insomniac Ultimate Breadwinner Macro",
    UDim2.new(0,10,0,0),UDim2.new(1,-40,1,0),13,C.text)
local xb=newB(tbar,"X",UDim2.new(1,-28,0,3),UDim2.new(0,24,0,24),C.stop)
xb.MouseButton1Click:Connect(function() stopAll(); sg:Destroy() end)

-- Drag
local drag_on,drag_s,drag_w
tbar.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then
        drag_on=true; drag_s=i.Position; drag_w=win.Position
    end
end)
tbar.InputEnded:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 then drag_on=false end
end)
UIS.InputChanged:Connect(function(i)
    if drag_on and i.UserInputType==Enum.UserInputType.MouseMovement then
        local d=i.Position-drag_s
        win.Position=UDim2.new(drag_w.X.Scale,drag_w.X.Offset+d.X,drag_w.Y.Scale,drag_w.Y.Offset+d.Y)
    end
end)

-- Content
local ct=newF(win,UDim2.new(1,-10,1,-80),UDim2.new(0,5,0,34),C.bg)

-- ── MODE ROW ──────────────────────────────────────────────────────────────
newL(ct,"Mode:",UDim2.new(0,0,0,2),UDim2.new(0,36,0,18),12,C.dim)
local mNames={"Custom","1 Lane","Field","Idle","Thresh","Mixing"}
local mVals ={0,1,2,3,4,5}
local mBtns={}
local mx=38
for i,nm in ipairs(mNames) do
    local dis=(nm=="Field")
    local b=newB(ct,nm,UDim2.new(0,mx,0,1),UDim2.new(0,62,0,18),
        dis and C.border or C.panel, dis and C.border or C.dim)
    b.TextSize=11; if dis then b.Active=false end
    mBtns[i]=b; mx=mx+64
end
mBtns[1].BackgroundColor3=C.hot; mBtns[1].TextColor3=C.white

local function selMode(idx)
    for i,b in ipairs(mBtns) do
        if mNames[i]~="Field" then
            b.BackgroundColor3=(i==idx) and C.hot or C.panel
            b.TextColor3=(i==idx) and C.white or C.dim
        end
    end
end

-- ── LEFT PANEL (x=0,w=235): custom options + laning ──────────────────────
local LP=newF(ct,UDim2.new(0,235,1,-26),UDim2.new(0,0,0,26),C.bg)
local ly=0

local function lsep(lbl)
    if lbl then newL(LP,lbl,UDim2.new(0,0,0,ly),UDim2.new(1,0,0,16),10,C.dim) end
    newF(LP,UDim2.new(1,0,0,1),UDim2.new(0,0,0,ly+16),C.border)
    ly=ly+18
end

lsep("Custom Options")
-- AutoClicker
chk(LP,"AutoClicker","autoClicker",0,ly)
numF(LP,"clickDelay",130,ly,44,"Dly")
numF(LP,"clickVar",  185,ly,40,"Var")
ly=ly+22

-- AutoWalk
chk(LP,"AutoWalk","autoWalk",0,ly); ly=ly+22

-- AutoToggle
chk(LP,"AutoToggle","autoToggle",0,ly)
numF(LP,"toggleMs",130,ly,60,"ms"); ly=ly+22

-- AutoCam
chk(LP,"AutoCam","autoCam",0,ly)
newL(LP,"(uses Laning)",UDim2.new(0,130,0,ly),UDim2.new(0,100,0,18),10,C.dim)
ly=ly+22

-- AutoInteract
chk(LP,"AutoInteract","autoInteract",0,ly)
numF(LP,"interactDelay",130,ly,44,"Dly")
numF(LP,"interactVar",  185,ly,40,"Var")
ly=ly+26

lsep("Laning Options")
newL(LP,"Orientation:",UDim2.new(0,0,0,ly),UDim2.new(0,80,0,16),10,C.dim)
local vb=newB(LP,"Vertical",  UDim2.new(0,82,0,ly),UDim2.new(0,68,0,16),C.hot,C.white)
local hb=newB(LP,"Horizontal",UDim2.new(0,152,0,ly),UDim2.new(0,78,0,16),C.border,C.border)
vb.TextSize=10; hb.TextSize=10; hb.Active=false   -- Horizontal disabled in original
ly=ly+20

newL(LP,"Direction:",UDim2.new(0,0,0,ly),UDim2.new(0,65,0,16),10,C.dim)
radio(LP,66,ly,"Left","Right",
    function() return cfg.camLeft end,
    function(v) cfg.camLeft=v end)
ly=ly+20

newL(LP,"Harvest Mode:",UDim2.new(0,0,0,ly),UDim2.new(0,85,0,16),10,C.dim)
radio(LP,86,ly,"Reap","Sow",
    function() return cfg.reaping end,
    function(v) cfg.reaping=v end)
ly=ly+18
newL(LP,"AutoToggle+AutoCam depend on this",
    UDim2.new(0,0,0,ly),UDim2.new(1,0,0,28),9,C.dim)

-- ── RIGHT PANEL (x=240,w=455): autostop + mode-specific ──────────────────
local RP=newF(ct,UDim2.new(0,455,1,-26),UDim2.new(0,240,0,26),C.bg)
local ry=0

local function rsep(lbl)
    if lbl then newL(RP,lbl,UDim2.new(0,0,0,ry),UDim2.new(1,0,0,16),10,C.dim) end
    newF(RP,UDim2.new(1,0,0,1),UDim2.new(0,0,0,ry+16),C.border); ry=ry+18
end

rsep("Auto Stop")
chk(RP,"AutoStop","autoStop",0,ry)
numF(RP,"autoStopMins",108,ry,50,"min")
uiTimer=newL(RP,"00:00:00",UDim2.new(0,178,0,ry),UDim2.new(0,130,0,18),18,C.text)
ry=ry+28

-- Idle panel
local idleP=newF(RP,UDim2.new(1,0,0,220),UDim2.new(0,0,0,ry),C.bg)
idleP.Visible=false
do
    local iy=0
    rsep=nil  -- redeclare locally
    newL(idleP,"Idle Options",UDim2.new(0,0,0,iy),UDim2.new(1,0,0,16),10,C.dim)
    newF(idleP,UDim2.new(1,0,0,1),UDim2.new(0,0,0,iy+16),C.border); iy=iy+18
    chk(idleP,"AutoInvite","autoInvite",0,iy); iy=iy+22

    local function xyRow(par,lbl,xk,yk,yp)
        newL(par,lbl,UDim2.new(0,0,0,yp),UDim2.new(0,46,0,18),12,C.text)
        newL(par,"X:",UDim2.new(0,48,0,yp),UDim2.new(0,14,0,18),11,C.dim)
        numF(par,xk,62,yp,70)
        newL(par,"Y:",UDim2.new(0,138,0,yp),UDim2.new(0,14,0,18),11,C.dim)
        numF(par,yk,152,yp,70)
    end
    xyRow(idleP,"Home",  "homeX",  "homeY",  iy); iy=iy+22
    xyRow(idleP,"Invite","inviteX","inviteY",iy); iy=iy+22
    xyRow(idleP,"Close", "closeX", "closeY", iy); iy=iy+26
    uiAction=newL(idleP,"...",UDim2.new(0,0,0,iy),UDim2.new(1,0,0,40),22,C.text)
    uiAction.Font=Enum.Font.GothamBold
end

-- Mixing panel
local mixP=newF(RP,UDim2.new(1,0,0,130),UDim2.new(0,0,0,ry),C.bg)
mixP.Visible=false
do
    local my=0
    newL(mixP,"Mixing Options",UDim2.new(0,0,0,my),UDim2.new(1,0,0,16),10,C.dim)
    newF(mixP,UDim2.new(1,0,0,1),UDim2.new(0,0,0,my+16),C.border); my=my+18
    newL(mixP,"Faucet",UDim2.new(0,0,0,my),UDim2.new(0,44,0,18),12,C.text)
    newL(mixP,"X:",UDim2.new(0,46,0,my),UDim2.new(0,14,0,18),11,C.dim)
    numF(mixP,"faucetX",60,my,70)
    newL(mixP,"Y:",UDim2.new(0,136,0,my),UDim2.new(0,14,0,18),11,C.dim)
    numF(mixP,"faucetY",150,my,70); my=my+22
    newL(mixP,"Trickle (s):",UDim2.new(0,0,0,my),UDim2.new(0,80,0,18),12,C.text)
    numF(mixP,"trickleTime",82,my,60); my=my+22
    newL(mixP,"Max Flow (ms):",UDim2.new(0,0,0,my),UDim2.new(0,95,0,18),12,C.text)
    numF(mixP,"maxFlow",98,my,70)
end

-- Wire mode buttons
for i,btn in ipairs(mBtns) do
    if mNames[i]~="Field" then
        btn.MouseButton1Click:Connect(function()
            local mv=mVals[i]; cfg.mode=mv; selMode(i)
            -- presets
            if mv==1 then  -- 1 Lane: force clicker+walk+toggle(1ms)+cam(reap)
                cfg.autoClicker=true; cfg.clickDelay=200; cfg.clickVar=50
                cfg.autoWalk=true; cfg.autoToggle=true; cfg.toggleMs=1
                cfg.autoCam=true; cfg.reaping=true; cfg.autoInteract=false
            elseif mv==4 then  -- Thresh: walk+interact
                cfg.autoWalk=true; cfg.autoInteract=true
                cfg.interactDelay=100; cfg.interactVar=25; cfg.autoClicker=false
            end
            idleP.Visible=(mv==3); mixP.Visible=(mv==5)
        end)
    end
end

-- ── BOTTOM BAR ────────────────────────────────────────────────────────────
local bY=WH-44
uiStatus=newL(win,"● Idle",UDim2.new(0,8,0,bY-16),UDim2.new(1,-16,0,14),11,C.dim,Enum.TextXAlignment.Center)

local startB=newB(win,"START  (F7)",UDim2.new(0,5,0,bY),UDim2.new(0.48,0,0,38),C.go)
startB.TextSize=16
local stopB=newB(win,"STOP  (F7)",UDim2.new(0.52,0,0,bY),UDim2.new(0.48,-5,0,38),C.stop)
stopB.TextSize=16

startB.MouseButton1Click:Connect(function()
    startAll()
    uiStatus.Text="● Running"; uiStatus.TextColor3=Color3.fromRGB(60,200,100)
end)
stopB.MouseButton1Click:Connect(stopAll)

UIS.InputBegan:Connect(function(inp,gp)
    if gp then return end
    if inp.KeyCode==Enum.KeyCode.F7 then
        if running then stopAll()
        else
            startAll()
            uiStatus.Text="● Running"; uiStatus.TextColor3=Color3.fromRGB(60,200,100)
        end
    end
end)

print("[IUBWM 1.6.2] GUI loaded. Press F7 or click START.")
