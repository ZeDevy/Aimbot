local function CreateAimbotModule()
    local Aimbot = {}
    local TweenService = game:GetService("TweenService")

    local AimbotFOV = 30
    local SmoothingFactor = 0.1
    local LockedPlayer = nil
    local OriginalCameraCFrame = nil
    local AimbotEnabled = false -- Added AimbotEnabled state

    function Aimbot:Initialize(camera)
        OriginalCameraCFrame = camera.CFrame
    end

    function Aimbot:CalculateAngleOffset(targetPosition, cameraCFrame)
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

    function Aimbot:LockOnTarget(camera, players)
        local closestPlayer = nil
        local closestAngle = AimbotFOV

        for _, player in ipairs(players) do
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetPosition = player.Character.HumanoidRootPart.Position
                local horizontalOffset, verticalOffset = self:CalculateAngleOffset(targetPosition, camera.CFrame)
                local angleMagnitude = math.deg(math.sqrt(horizontalOffset^2 + verticalOffset^2))

                if angleMagnitude < closestAngle then
                    closestAngle = angleMagnitude
                    closestPlayer = player
                end
            end
        end

        if closestPlayer then
            LockedPlayer = closestPlayer
            return true
        end
        
        return false
    end

    function Aimbot:AimAtTarget(camera)
        if LockedPlayer and LockedPlayer.Character and LockedPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPosition = LockedPlayer.Character.HumanoidRootPart.Position
            local horizontalOffset, verticalOffset = self:CalculateAngleOffset(targetPosition, camera.CFrame)

            local currentHorizontalAngle, currentVerticalAngle = self:CalculateAngleOffset(camera.CFrame.LookVector * 1000 + camera.CFrame.Position, camera.CFrame)
            horizontalOffset = currentHorizontalAngle + (horizontalOffset - currentHorizontalAngle) * SmoothingFactor
            verticalOffset = currentVerticalAngle + (verticalOffset - currentVerticalAngle) * SmoothingFactor

            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, targetPosition)
        end
    end

    function Aimbot:ResetCamera(camera)
        if OriginalCameraCFrame then
            camera.CFrame = OriginalCameraCFrame
            LockedPlayer = nil
        end
    end

    function Aimbot:AimbotOn(camera, players)
        if not AimbotEnabled then
            AimbotEnabled = true
            self:Initialize(camera) -- Initialize when turning on
            coroutine.wrap(function()
                while AimbotEnabled do
                    if self:LockOnTarget(camera, players) then
                        self:AimAtTarget(camera)
                    end
                    task.wait(0.01)
                end
            end)()
        end
    end

    function Aimbot:AimbotOff(camera)
        if AimbotEnabled then
            AimbotEnabled = false
            self:ResetCamera(camera)
        end
    end

    return Aimbot
end

return CreateAimbotModule
