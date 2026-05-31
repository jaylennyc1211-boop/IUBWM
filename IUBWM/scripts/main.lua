-- IUBWM 1.6.2 — Insomniac Ultimate Breadwinner Macro
-- Roblox executor port — github.com/TNT20002220/IUBWM

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local VIM     = game:GetService("VirtualInputManager")
local cam     = workspace.CurrentCamera
local lp      = Players.LocalPlayer

-- ── CONFIG  (defaults match FormMain designer) ────────────────────────────
local cfg = {
    mode = 0,  -- 0=Custom 1=1Lane 2=Field 3=Idle 4=Thresh 5=Mixing

    autoClicker=false,  clickDelay=200,    clickVar=50,
    autoWalk=false,
    autoToggle=false,   toggleMs=10000,
    autoCam=false,      camLeft=true,
    reaping=true,       -- true=reap(key2)  false=sow(key1)
    autoInteract=false, interactDelay=100, interactVar=25,

    autoStop=false,     autoStopMins=180,

    autoInvite=false,
    homeX=0, homeY=0, inviteX=0, inviteY=0, closeX=0, closeY=0,

    faucetX=0, faucetY=0, trickleTime=12, maxFlow=1200,
}

-- ── STATE ──────────────────────────────────────────────────────────────────
local running  = false
local threads  = {}
local ticks    = {}   -- ticks[cfgKey] = TextLabel "✓"
local uiStatus, uiAction, uiTimer

-- sync all checkbox visuals from cfg (called after preset changes)
local function syncUI()
    for k, lbl in pairs(ticks) do
        lbl.Text = cfg[k] and "✓" or ""
    end
end

-- ── INPUT ──────────────────────────────────────────────────────────────────
local function kd(kc) pcall(function() VIM:SendKeyEvent(true,  kc, false, game) end) end
local function ku(kc) pcall(function() VIM:SendKeyEvent(false, kc, false, game) end) end
local function kp(kc,ms) kd(kc); task.wait((ms or 50)/1000); ku(kc) end

local function scx() return math.floor(cam.ViewportSize.X/2) end
local function scy() return math.floor(cam.ViewportSize.Y/2) end

local function lmbdown(x,y) pcall(function() VIM:SendMouseButtonEvent(x or scx(),y or scy(),0,true, game,0) end) end
local function lmbup(x,y)   pcall(function() VIM:SendMouseButtonEvent(x or scx(),y or scy(),0,false,game,0) end) end
local function rmbdown(x,y) pcall(function() VIM:SendMouseButtonEvent(x or scx(),y or scy(),1,true, game,0) end) end
local function rmbup(x,y)   pcall(function() VIM:SendMouseButtonEvent(x or scx(),y or scy(),1,false,game,0) end) end
local function mm(x,y)      pcall(function() VIM:SendMouseMoveEvent(x,y,game) end) end
local function lclick(x,y)  lmbdown(x,y); task.wait(0.05); lmbup(x,y) end

-- Replicates InputSimulator.Turn90Degrees exactly:
-- 26 × ±10 px + ±8 px = ±268 px with RMB held
local function turn90(left)
    local d = left and -1 or 1
    local ox,oy = scx(),scy()
    rmbdown(ox,oy); task.wait(0.016)
    local x = ox
    for _ = 1,26 do x = x + d*10; mm(x,oy); task.wait(0.001) end
    x = x + d*8; mm(x,oy); task.wait(0.016)
    rmbup(x,oy);  task.wait(0.016)
    mm(ox,oy)
end

-- key1=sow, key2=reap  (matches ToggleHarvestMode in C#)
local function toggleHarvest()
    if cfg.reaping then cfg.reaping=false; kp(Enum.KeyCode.One,50)
    else               cfg.reaping=true;  kp(Enum.KeyCode.Two,50) end
end

-- ── LOOPS ──────────────────────────────────────────────────────────────────
local function loop_clicker()
    while running and cfg.autoClicker do
        lclick()
        local v = math.max(1,cfg.clickVar)
        task.wait(math.max(1, cfg.clickDelay + math.random(-v,v)) / 1000)
    end
end

local function loop_walk()
    while running and cfg.autoWalk do kd(Enum.KeyCode.W); task.wait(0.1) end
    ku(Enum.KeyCode.W)
end

-- AutoCam: rectangular laning — reap 9.4s/2.2s wide, sow 7.6s/1.6s wide
local function loop_cam()
    local R={len=9.4,wid=2.2}; local S={len=7.6,wid=1.6}
    while running and cfg.autoCam do
        local t = cfg.reaping and R or S
        task.wait(t.len); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.wid); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.len); if not running then break end; turn90(cfg.camLeft)
        task.wait(t.wid); if not running then break end; turn90(cfg.camLeft)
        if cfg.autoToggle then toggleHarvest() end
        -- original drift-correction nudge ±1 px
        mm(scx()+(cfg.camLeft and 1 or -1),scy()); task.wait(0.016); mm(scx(),scy())
    end
end

-- AutoToggle fires at interval only when AutoCam is not the driver
local function loop_toggle()
    while running and cfg.autoToggle do
        if not cfg.autoCam then
            task.wait(cfg.toggleMs/1000)
            if running then toggleHarvest() end
        else task.wait(0.1) end
    end
end

-- AutoInteract mirrors the 50ms main-loop tick from RunLoop in C#
local function loop_interact()
    while running and cfg.autoInteract do
        local v = math.max(1,cfg.interactVar)
        kd(Enum.KeyCode.E); task.wait(math.random(1,v)/1000); ku(Enum.KeyCode.E)
        task.wait(math.max(1, cfg.interactDelay + math.random(-v,v)) / 1000)
        task.wait(0.05)
    end
    ku(Enum.KeyCode.E)
end

-- IdlingLoop — faithful C# port
local function loop_idle()
    if uiAction then uiAction.Text="..." end
    local inviteStart = tick()

    if cfg.autoInvite then
        if uiAction then uiAction.Text="Invite" end
        mm(cfg.homeX,cfg.homeY);   task.wait(0.01); lclick(); task.wait(0.1)
        mm(cfg.inviteX,cfg.inviteY);task.wait(0.01); lclick(); task.wait(0.1)
        mm(cfg.closeX,cfg.closeY);  task.wait(0.01); lclick()
    end

    while running do
        local wt = 500*math.random(40,60)
        if uiAction then uiAction.Text="Wait "..math.floor(wt/1000).."s" end
        task.wait(wt/1000); if not running then break end

        local r = math.random(0,11)
        if r==0 then
            if cfg.autoInvite then
                local ht=500*math.random(120,241)
                if uiAction then uiAction.Text="Wait "..math.floor(ht/1000).."s (Host)" end
                task.wait(ht/1000)
            end
        elseif r==1 then
            if uiAction then uiAction.Text="Move Left"    end
            kd(Enum.KeyCode.A); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.A)
        elseif r==2 then
            if uiAction then uiAction.Text="Move Forward" end
            kd(Enum.KeyCode.W); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.W)
        elseif r==3 then
            if uiAction then uiAction.Text="Move Back"    end
            kd(Enum.KeyCode.S); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.S)
        elseif r==4 then
            if uiAction then uiAction.Text="Move Right"   end
            kd(Enum.KeyCode.D); task.wait(0.5*math.random(1,2)); ku(Enum.KeyCode.D)
        elseif r==5 then
            if uiAction then uiAction.Text="Jump" end
            kp(Enum.KeyCode.Space,50)
            kd(Enum.KeyCode.S); task.wait(1); ku(Enum.KeyCode.S)
        elseif r==6 then
            if uiAction then uiAction.Text="Turn Cam" end
            local ox,oy=scx(),scy(); rmbdown(ox,oy)
            local x=ox
            for _=1,math.random(20,100) do x=x+1; mm(x,oy); task.wait(0.001) end
            rmbup(x,oy); mm(ox,oy)
        elseif r==7 then
            if uiAction then uiAction.Text="Turn Cam" end
            local ox,oy=scx(),scy(); rmbdown(ox,oy)
            local x=ox
            for _=1,math.random(20,100) do x=x-1; mm(x,oy); task.wait(0.001) end
            rmbup(x,oy); mm(ox,oy)
        else
            if uiAction then uiAction.Text="Click" end
            lclick(); task.wait(0.1)
        end

        -- invite every 5 minutes
        if tick()-inviteStart >= 300 then
            inviteStart = tick()
            if cfg.autoInvite then
                if uiAction then uiAction.Text="Invite" end
                mm(cfg.homeX,cfg.homeY);    task.wait(0.01); lclick(); task.wait(0.1)
                mm(cfg.inviteX,cfg.inviteY);task.wait(0.01); lclick(); task.wait(0.1)
                mm(cfg.closeX,cfg.closeY);  task.wait(0.01); lclick()
                kp(Enum.KeyCode.Space,50)
                local dirs={Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D}
                local dk=dirs[math.random(4)]; kd(dk); task.wait(4); ku(dk)
            end
        end
    end
    if uiAction then uiAction.Text="..." end
end

-- MixingLoop — port of FormMain.MixingLoop (Win32 cursor detection replaced with direct move)
local function loop_mixing()
    while running do
        local fx,fy = cfg.faucetX,cfg.faucetY
        mm(fx,fy); task.wait(0.03)
        lmbdown(fx,fy); task.wait(0.03)
        for i=1,20 do mm(fx+i*10,fy); task.wait(0.001) end
        task.wait(cfg.maxFlow/1000)
        for i=1,19 do mm(fx+(20-i)*10,fy); task.wait(0.003) end
        mm(fx+15,fy); task.wait(0.05); lmbup(fx+15,fy)
        for _=1,cfg.trickleTime*2 do
            if not running then break end; task.wait(0.5)
        end
        local x=fx+15
        for _=1,10 do x=x-26; mm(x,fy); task.wait(0.001) end
        x=x-8; mm(x,fy)
        kd(Enum.KeyCode.W); task.wait(1.7); ku(Enum.KeyCode.W)
        kp(Enum.KeyCode.E,50)
        for _=1,10 do x=x+52; mm(x,fy); task.wait(0.001) end
        mm(x+16,fy+4)
        kd(Enum.KeyCode.W); kd(Enum.KeyCode.D); task.wait(0.05); ku(Enum.KeyCode.D)
        task.wait(1.35)
        local v=math.max(1,cfg.interactVar)
        kp(Enum.KeyCode.E,math.random(1,v)); task.wait(0.2)
        kp(Enum.KeyCode.E,math.random(1,v))
        ku(Enum.KeyCode.W); kp(Enum.KeyCode.E,50); task.wait(1)
    end
end

-- ── START / STOP ───────────────────────────────────────────────────────────
local KEYS={Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
            Enum.KeyCode.E,Enum.KeyCode.Space,Enum.KeyCode.One,Enum.KeyCode.Two}

local function stopAll()
    running=false
    for _,t in ipairs(threads) do pcall(task.cancel,t) end
    threads={}
    for _,k in ipairs(KEYS) do ku(k) end
    if uiStatus then uiStatus.Text="● Stopped"; uiStatus.TextColor3=Color3.fromRGB(160,60,60) end
    if uiTimer  then uiTimer.Text="00:00:00" end
    if uiAction then uiAction.Text="..." end
end

local function sp(fn) table.insert(threads,task.spawn(fn)) end

local function startAll()
    if running then return end
    running=true
    if uiStatus then uiStatus.Text="● Running"; uiStatus.TextColor3=Color3.fromRGB(60,200,100) end
    local m=cfg.mode
    if m==0 or m==1 or m==2 then
        if cfg.autoToggle then
            kp(cfg.reaping and Enum.KeyCode.Two or Enum.KeyCode.One, 50)
            sp(loop_toggle)
        end
        if cfg.autoClicker then sp(loop_clicker) end
        if cfg.autoCam     then sp(loop_cam)     end
    end
    if m==3 then sp(loop_idle)   end
    if m==5 then sp(loop_mixing) end
    if cfg.autoInteract then sp(loop_interact) end
    if cfg.autoWalk     then sp(loop_walk)     end
    -- modes that force walk even when autoWalk checkbox is off
    if not cfg.autoWalk and (m==1 or m==4) then
        sp(function() while running do kd(Enum.KeyCode.W); task.wait(0.1) end; ku(Enum.KeyCode.W) end)
    end
    if cfg.autoStop then
        sp(function()
            local endT=tick()+cfg.autoStopMins*60
            while running and tick()<endT do
                task.wait(1)
                local r=math.max(0,math.floor(endT-tick()))
                if uiTimer then
                    uiTimer.Text=string.format("%02d:%02d:%02d",
                        math.floor(r/3600),math.floor(r%3600/60),r%60)
                end
            end
            if running then stopAll() end
        end)
    end
end

-- ══════════════════════════════════════════════════════════════════════════
-- GUI
-- ══════════════════════════════════════════════════════════════════════════
local guiRoot
if type(gethui)=="function" then pcall(function() guiRoot=gethui() end) end
guiRoot = guiRoot or game:GetService("CoreGui")
local prev=guiRoot:FindFirstChild("IUBWM_GUI")
if prev then prev:Destroy() end

local sg=Instance.new("ScreenGui")
sg.Name="IUBWM_GUI"; sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.Parent=guiRoot

-- colours
local BG  = Color3.fromRGB(15,15,22)
local PNL = Color3.fromRGB(25,25,38)
local BDR = Color3.fromRGB(48,48,68)
local ACC = Color3.fromRGB(97,35,12)    -- original WinForms button colour
local HOT = Color3.fromRGB(130,52,20)
local GO  = Color3.fromRGB(42,145,65)
local STP = Color3.fromRGB(158,48,48)
local TXT = Color3.fromRGB(220,220,230)
local DIM = Color3.fromRGB(120,120,145)
local GRN = Color3.fromRGB(55,195,95)
local WHT = Color3.new(1,1,1)

local function cr(r,parent)
    local u=Instance.new("UICorner"); u.CornerRadius=UDim.new(0,r); u.Parent=parent
end
local function newFrame(par,sz,pos,bg,r)
    local f=Instance.new("Frame"); f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or BG; f.BorderSizePixel=0; f.Parent=par
    if r then cr(r,f) end; return f
end
local function newLbl(par,txt,pos,sz,fs,col,xa)
    local l=Instance.new("TextLabel"); l.Text=txt; l.Position=pos; l.Size=sz
    l.BackgroundTransparency=1; l.TextColor3=col or TXT; l.TextSize=fs or 13
    l.Font=Enum.Font.GothamMedium; l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center; l.Parent=par; return l
end
local function newBtn(par,txt,pos,sz,bg,tc)
    local b=Instance.new("TextButton"); b.Text=txt; b.Position=pos; b.Size=sz
    b.BackgroundColor3=bg or ACC; b.TextColor3=tc or WHT
    b.TextSize=13; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.AutoButtonColor=true
    cr(5,b); b.Parent=par; return b
end
local function newTBox(par,val,pos,sz)
    local t=Instance.new("TextBox"); t.Text=tostring(val); t.Position=pos; t.Size=sz
    t.BackgroundColor3=BDR; t.TextColor3=TXT; t.TextSize=12
    t.Font=Enum.Font.Gotham; t.BorderSizePixel=0; t.ClearTextOnFocus=false
    cr(4,t); t.Parent=par; return t
end

-- number field for a cfg key
local function numField(par,key,x,y,w,label)
    if label then
        newLbl(par,label,UDim2.new(0,x,0,y),UDim2.new(0,24,0,16),10,DIM); x=x+22
    end
    local tb=newTBox(par,cfg[key],UDim2.new(0,x,0,y+1),UDim2.new(0,w or 52,0,17))
    tb.FocusLost:Connect(function()
        local n=tonumber(tb.Text)
        if n then cfg[key]=math.max(0,math.floor(n)) end
        tb.Text=tostring(cfg[key])
    end)
    return tb
end

-- checkbox for a cfg key; stores tick reference in ticks[]
local function checkbox(par,label,key,x,y,onChange)
    local box=newFrame(par,UDim2.new(0,14,0,14),UDim2.new(0,x,0,y+2),BDR,3)
    local tick=newLbl(box,cfg[key] and "✓" or "",
        UDim2.new(0,0,0,0),UDim2.new(1,0,1,0),11,GRN,Enum.TextXAlignment.Center)
    tick.TextYAlignment=Enum.TextYAlignment.Center
    ticks[key]=tick
    newLbl(par,label,UDim2.new(0,x+18,0,y),UDim2.new(0,120,0,18),13,TXT)
    local hit=Instance.new("TextButton")
    hit.Size=UDim2.new(0,140,0,18); hit.Position=UDim2.new(0,x,0,y)
    hit.BackgroundTransparency=1; hit.Text=""; hit.Parent=par
    hit.MouseButton1Click:Connect(function()
        cfg[key]=not cfg[key]; tick.Text=cfg[key] and "✓" or ""
        if onChange then onChange(cfg[key]) end
    end)
    return hit
end

-- radio pair (true=first, false=second)
local function radioPair(par,x,y,l1,l2,getF,setF)
    local b1=newBtn(par,l1,UDim2.new(0,x,   0,y),UDim2.new(0,46,0,17),getF() and HOT or PNL,getF() and WHT or DIM)
    local b2=newBtn(par,l2,UDim2.new(0,x+48,0,y),UDim2.new(0,46,0,17),(not getF()) and HOT or PNL,(not getF()) and WHT or DIM)
    b1.TextSize=11; b2.TextSize=11
    local function ref()
        b1.BackgroundColor3=getF() and HOT or PNL; b1.TextColor3=getF() and WHT or DIM
        b2.BackgroundColor3=(not getF()) and HOT or PNL; b2.TextColor3=(not getF()) and WHT or DIM
    end
    b1.MouseButton1Click:Connect(function() setF(true);  ref() end)
    b2.MouseButton1Click:Connect(function() setF(false); ref() end)
    return b1,b2
end

local function hline(par,y) newFrame(par,UDim2.new(1,0,0,1),UDim2.new(0,0,0,y),BDR) end
local function sectionHead(par,txt,y)
    newLbl(par,txt,UDim2.new(0,0,0,y),UDim2.new(1,0,0,14),10,DIM); hline(par,y+14)
    return y+17
end

-- ── Window ─────────────────────────────────────────────────────────────────
local WW,WH = 680,520
local win=newFrame(sg,UDim2.new(0,WW,0,WH),
    UDim2.new(0.5,-WW/2,0.5,-WH/2),BG,10)
local ws=Instance.new("UIStroke"); ws.Color=BDR; ws.Thickness=1.5; ws.Parent=win

-- title bar
local tbar=newFrame(win,UDim2.new(1,0,0,30),UDim2.new(0,0,0,0),PNL,10)
newFrame(tbar,UDim2.new(1,0,0,15),UDim2.new(0,0,1,-15),PNL)
newLbl(tbar,"IUBWM 1.6.2 — Insomniac Ultimate Breadwinner Macro",
    UDim2.new(0,10,0,0),UDim2.new(1,-38,1,0),13,TXT)
local xb=newBtn(tbar,"X",UDim2.new(1,-28,0,3),UDim2.new(0,24,0,24),STP)
xb.MouseButton1Click:Connect(function() stopAll(); sg:Destroy() end)

do  -- drag
    local on,ds,wp
    tbar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            on=true; ds=i.Position; wp=win.Position
        end
    end)
    tbar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then on=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if on and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            win.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y)
        end
    end)
end

-- content area
local ct=newFrame(win,UDim2.new(1,-10,1,-80),UDim2.new(0,5,0,34),BG)

-- ── MODE ROW ───────────────────────────────────────────────────────────────
newLbl(ct,"Mode:",UDim2.new(0,0,0,2),UDim2.new(0,36,0,18),11,DIM)
local MODE_NAMES={"Custom","1 Lane","Field","Idle","Thresh","Mixing"}
local MODE_VALS ={0,1,2,3,4,5}
local modeBtns={}
do
    local mx=38
    for i,nm in ipairs(MODE_NAMES) do
        local disabled=(nm=="Field")
        local b=newBtn(ct,nm,UDim2.new(0,mx,0,1),UDim2.new(0,62,0,18),
            disabled and BDR or PNL, disabled and BDR or DIM)
        b.TextSize=11
        if disabled then b.Active=false end
        modeBtns[i]=b; mx=mx+64
    end
end
modeBtns[1].BackgroundColor3=HOT; modeBtns[1].TextColor3=WHT

local function highlightMode(idx)
    for i,b in ipairs(modeBtns) do
        if MODE_NAMES[i]~="Field" then
            b.BackgroundColor3=(i==idx) and HOT or PNL
            b.TextColor3=(i==idx) and WHT or DIM
        end
    end
end

-- ── LEFT PANEL (custom options + laning) ───────────────────────────────────
local LP=newFrame(ct,UDim2.new(0,228,1,-26),UDim2.new(0,0,0,26),BG)
local ly=0

ly=sectionHead(LP,"Custom Options",ly)

checkbox(LP,"AutoClicker","autoClicker",0,ly)
numField(LP,"clickDelay",130,ly,44,"Dly")
numField(LP,"clickVar",  186,ly,38,"Var")
ly=ly+22

checkbox(LP,"AutoWalk","autoWalk",0,ly); ly=ly+22

checkbox(LP,"AutoToggle","autoToggle",0,ly)
numField(LP,"toggleMs",130,ly,64,"ms"); ly=ly+22

checkbox(LP,"AutoCam","autoCam",0,ly)
newLbl(LP,"(Laning→)",UDim2.new(0,130,0,ly),UDim2.new(0,90,0,18),10,DIM); ly=ly+22

checkbox(LP,"AutoInteract","autoInteract",0,ly)
numField(LP,"interactDelay",130,ly,44,"Dly")
numField(LP,"interactVar",  186,ly,38,"Var")
ly=ly+26

ly=sectionHead(LP,"Laning Options",ly)

newLbl(LP,"Orientation:",UDim2.new(0,0,0,ly),UDim2.new(0,78,0,16),10,DIM)
local vb=newBtn(LP,"Vertical",  UDim2.new(0,80,0,ly),UDim2.new(0,66,0,16),HOT,WHT)
local hb=newBtn(LP,"Horizontal",UDim2.new(0,148,0,ly),UDim2.new(0,76,0,16),BDR,BDR)
vb.TextSize=10; hb.TextSize=10; hb.Active=false
ly=ly+20

newLbl(LP,"Direction:",UDim2.new(0,0,0,ly),UDim2.new(0,62,0,16),10,DIM)
radioPair(LP,64,ly,"Left","Right",
    function() return cfg.camLeft end, function(v) cfg.camLeft=v end)
ly=ly+22

newLbl(LP,"Harvest Mode:",UDim2.new(0,0,0,ly),UDim2.new(0,84,0,16),10,DIM)
radioPair(LP,86,ly,"Reap","Sow",
    function() return cfg.reaping end, function(v) cfg.reaping=v end)
ly=ly+18
newLbl(LP,"AutoToggle + AutoCam depend on this",
    UDim2.new(0,0,0,ly),UDim2.new(1,0,0,28),9,DIM)

-- ── RIGHT PANEL ─────────────────────────────────────────────────────────────
local RP=newFrame(ct,UDim2.new(0,442,1,-26),UDim2.new(0,233,0,26),BG)
local ry=0

ry=sectionHead(RP,"Auto Stop",ry)
checkbox(RP,"AutoStop","autoStop",0,ry)
numField(RP,"autoStopMins",108,ry,52,"min")
uiTimer=newLbl(RP,"00:00:00",UDim2.new(0,178,0,ry),UDim2.new(0,150,0,18),18,TXT)
ry=ry+26

hline(RP,ry); ry=ry+4

-- ── Mode-specific panels (all children of RP, mutually exclusive) ──────────
-- Panel for Custom / 1Lane / Field / Thresh: nothing extra needed (all in LP)
local panelNone=newFrame(RP,UDim2.new(1,0,0,30),UDim2.new(0,0,0,ry),BG)
newLbl(panelNone,"Options are shown in the left panel.",
    UDim2.new(0,0,0,6),UDim2.new(1,0,0,18),11,DIM,Enum.TextXAlignment.Center)
panelNone.Visible=true

-- Idle panel
local idleP=newFrame(RP,UDim2.new(1,0,0,260),UDim2.new(0,0,0,ry),BG)
idleP.Visible=false
do
    local iy=0
    iy=sectionHead(idleP,"Idle Options",iy)
    checkbox(idleP,"AutoInvite","autoInvite",0,iy); iy=iy+22
    local function xyRow(lbl,xk,yk)
        newLbl(idleP,lbl,UDim2.new(0,0,0,iy),UDim2.new(0,44,0,18),12,TXT)
        newLbl(idleP,"X:",UDim2.new(0,46,0,iy),UDim2.new(0,14,0,18),11,DIM)
        numField(idleP,xk,60,iy,68)
        newLbl(idleP,"Y:",UDim2.new(0,134,0,iy),UDim2.new(0,14,0,18),11,DIM)
        numField(idleP,yk,148,iy,68)
        iy=iy+22
    end
    xyRow("Home",  "homeX",  "homeY")
    xyRow("Invite","inviteX","inviteY")
    xyRow("Close", "closeX", "closeY")
    iy=iy+4
    uiAction=newLbl(idleP,"...",UDim2.new(0,0,0,iy),UDim2.new(1,0,0,44),24,TXT)
    uiAction.Font=Enum.Font.GothamBold
end

-- Mixing panel
local mixP=newFrame(RP,UDim2.new(1,0,0,140),UDim2.new(0,0,0,ry),BG)
mixP.Visible=false
do
    local my=0
    my=sectionHead(mixP,"Mixing Options",my)
    newLbl(mixP,"Faucet",UDim2.new(0,0,0,my),UDim2.new(0,42,0,18),12,TXT)
    newLbl(mixP,"X:",UDim2.new(0,44,0,my),UDim2.new(0,14,0,18),11,DIM)
    numField(mixP,"faucetX",58,my,70)
    newLbl(mixP,"Y:",UDim2.new(0,134,0,my),UDim2.new(0,14,0,18),11,DIM)
    numField(mixP,"faucetY",148,my,70); my=my+22
    newLbl(mixP,"Trickle (s):",UDim2.new(0,0,0,my),UDim2.new(0,78,0,18),12,TXT)
    numField(mixP,"trickleTime",80,my,60); my=my+22
    newLbl(mixP,"Max Flow (ms):",UDim2.new(0,0,0,my),UDim2.new(0,95,0,18),12,TXT)
    numField(mixP,"maxFlow",98,my,72)
end

-- ── Mode button wiring ──────────────────────────────────────────────────────
for i,btn in ipairs(modeBtns) do
    if MODE_NAMES[i]~="Field" then
        btn.MouseButton1Click:Connect(function()
            local mv=MODE_VALS[i]
            cfg.mode=mv
            highlightMode(i)

            -- apply presets
            if mv==1 then  -- 1 Lane
                cfg.autoClicker=true;  cfg.clickDelay=200; cfg.clickVar=50
                cfg.autoWalk=true;     cfg.autoToggle=true; cfg.toggleMs=1
                cfg.autoCam=true;      cfg.reaping=true;   cfg.autoInteract=false
            elseif mv==4 then  -- Thresh
                cfg.autoWalk=true; cfg.autoInteract=true
                cfg.interactDelay=100; cfg.interactVar=25; cfg.autoClicker=false
            end
            syncUI()  -- update all checkbox ticks to match cfg

            -- show the right panel section
            panelNone.Visible = (mv==0 or mv==1 or mv==2 or mv==4)
            idleP.Visible     = (mv==3)
            mixP.Visible      = (mv==5)
        end)
    end
end

-- ── Bottom bar ──────────────────────────────────────────────────────────────
local bY=WH-44
uiStatus=newLbl(win,"● Idle",
    UDim2.new(0,8,0,bY-16),UDim2.new(1,-16,0,14),11,DIM,Enum.TextXAlignment.Center)

local startB=newBtn(win,"START  (F7)",UDim2.new(0,5,0,bY),UDim2.new(0.48,0,0,38),GO)
local stopB =newBtn(win,"STOP  (F7)", UDim2.new(0.52,0,0,bY),UDim2.new(0.48,-5,0,38),STP)
startB.TextSize=16; stopB.TextSize=16

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

print("[IUBWM 1.6.2] Loaded. Press F7 or click START.")
