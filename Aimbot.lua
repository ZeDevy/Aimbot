local ImGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Roblox-ImGUI/refs/heads/main/ImGui.lua", true))()

if Window then
    Window:Close()
end

Window = ImGui:CreateWindow({
    Title = "Run.gm",
    Size = UDim2.new(0, 385, 0, 400),
})
Window:Center()

local ConsoleTab = Window:CreateTab({ Name = "Console" })
Window:ShowTab(ConsoleTab)

local Row2 = ConsoleTab:Row()
local Row3 = ConsoleTab:Row()

ConsoleTab:Separator({
    Text = "Console Example:"
})

local Console = ConsoleTab:Console({
    Text = "Console example",
    ReadOnly = true,
    LineNumbers = false,
    Border = false,
    Fill = true,
    Enabled = true,
    AutoScroll = true,
    RichText = true,
    MaxLines = 50
})

local function PrintGameInfo()
    local GameId = game.GameId
    local JobId = game.JobId

    Console:AppendText("[INFO] Game ID: " .. GameId)
    Console:AppendText("[INFO] Job ID: " .. JobId)
end

PrintGameInfo()

Row2:Button({
    Text = "Clear",
    Callback = function() Console:Clear() end
})

Row2:Button({
    Text = "Copy"
})

Row2:Button({
    Text = "Pause",
    Callback = function(self)
        local Paused = shared.Pause
        Paused = not (Paused or false)
        shared.Pause = Paused
        
        self.Text = Paused and "Paused" or "Pause"
        Console.Enabled = not Paused
    end,
})

Row2:Fill()

local TweenService = game:GetService("TweenService")

local plr = game.Players.LocalPlayer
local Camera = game.workspace.CurrentCamera
local AimbotEnabled = false
local LockedPlayer = nil
local OriginalCameraCFrame = Camera.CFrame
local AimbotFOV = 30
local SmoothingFactor = 0.1

local function calculateAngleOffset(targetPosition, cameraCFrame)
    local direction = (targetPosition - cameraCFrame.Position).Unit
    local horizontalAngle = math.atan2(direction.X, direction.Z)
    local verticalAngle = math.asin(direction.Y)

    local cameraDirection = cameraCFrame.LookVector
    local cameraHorizontalAngle = math.atan2(cameraDirection.X, cameraDirection.Z)
    local cameraVerticalAngle = math.asin(cameraDirection.Y)

    local horizontalOffset = horizontalAngle - cameraHorizontalAngle
    local verticalOffset = verticalAngle - cameraVerticalAngle

    return horizontalOffset, verticalOffset
end

local function Aimbot()
    if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPosition = LockedPlayer.Character.HumanoidRootPart.Position
        local horizontalOffset, verticalOffset = calculateAngleOffset(targetPosition, Camera.CFrame)

        local currentHorizontalAngle, currentVerticalAngle = calculateAngleOffset(Camera.CFrame.LookVector * 1000 + Camera.CFrame.Position, Camera.CFrame)
        horizontalOffset = currentHorizontalAngle + (horizontalOffset - currentHorizontalAngle) * SmoothingFactor
        verticalOffset = currentVerticalAngle + (verticalOffset - currentVerticalAngle) * SmoothingFactor

        local newLookVector = Vector3.new(
            math.sin(horizontalOffset),
            math.sin(verticalOffset),
            math.cos(horizontalOffset)
        )

        Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPosition)

    else
        Console:AppendText("[Aimbot] Error: Locked player is no longer valid.")
        AimbotEnabled = false
        LockedPlayer = nil
    end
end

local function FindTarget()
    local players = game.Players:GetPlayers()
    local closestPlayer = nil
    local closestAngle = AimbotFOV

    for _, player in ipairs(players) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = player.Character.HumanoidRootPart.Position
            local horizontalOffset, verticalOffset = calculateAngleOffset(targetPosition, Camera.CFrame)
            local angleMagnitude = math.deg(math.sqrt(horizontalOffset^2 + verticalOffset^2))

            if angleMagnitude < closestAngle then
                closestAngle = angleMagnitude
                closestPlayer = player
            end
        end
    end

    return closestPlayer
end

Row3:Button({
    Text = "Toggle Aimbot",
    Callback = function()
        AimbotEnabled = not AimbotEnabled
        if AimbotEnabled then
            LockedPlayer = FindTarget()
            if LockedPlayer then
                Console:AppendText("[Aimbot] Aimbot locked onto: " .. LockedPlayer.Name)
                while AimbotEnabled do
                    Aimbot()
                    task.wait(0.01)
                end
            else
                Console:AppendText("[Aimbot] Error: No valid target found.")
                AimbotEnabled = false
            end
            
            if not AimbotEnabled then
               Camera.CFrame = OriginalCameraCFrame
               LockedPlayer = nil
            end
        else
            Console:AppendText("[Aimbot] Aimbot disabled")
            Camera.CFrame = OriginalCameraCFrame
            LockedPlayer = nil
        end
    end
})
