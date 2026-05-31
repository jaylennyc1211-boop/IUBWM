-- idle.lua
-- Simple proof-of-concept idle jiggle module for Roblox executor environments.
local Idle = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local conn
local enabled = false

function Idle.start()
    if enabled then return end
    enabled = true
    local player = Players.LocalPlayer
    if not player then
        warn("idle.lua: no LocalPlayer available")
        enabled = false
        return
    end

    local character = player.Character or player.CharacterAdded:Wait()
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        warn("idle.lua: no HumanoidRootPart")
        enabled = false
        return
    end

    conn = RunService.Heartbeat:Connect(function()
        if not enabled or not root then return end
        local dx = (math.random() - 0.5) / 40
        local dz = (math.random() - 0.5) / 40
        -- small local shove to avoid obvious teleport distance
        local cf = root.CFrame
        root.CFrame = cf + Vector3.new(dx, 0, dz)
    end)
end

function Idle.stop()
    enabled = false
    if conn then conn:Disconnect(); conn = nil end
end

function Idle.configure(opts) end

return Idle
