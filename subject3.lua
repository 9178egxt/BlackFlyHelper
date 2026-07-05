local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local DanceActive = false
local MusicPlaying = false
local GuiVisible = true
local AnimId = 97968838104258
local LoopTime = 12.65
local BgmId = "rbxassetid://11387174269"

local DanceRemote = Instance.new("RemoteEvent")
DanceRemote.Name = "SubjectThreeDanceSync"
DanceRemote.Parent = ReplicatedStorage

local PlayerDanceData = {}
for _, plr in ipairs(Players:GetPlayers()) do
    PlayerDanceData[plr] = {
        Playing = false,
        Animator = nil,
        Track = nil,
        Offset = 0
    }
end

local function onCharacterSpawn(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local Animator = Instance.new("Animator")
    Animator.Parent = Humanoid
    PlayerDanceData[LocalPlayer].Animator = Animator
    Humanoid.Died:Connect(function()
        task.wait(2.8)
        if LocalPlayer:IsDescendantOf(game.Players) then
            LocalPlayer:LoadCharacter()
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(onCharacterSpawn)

Players.PlayerAdded:Connect(function(joinedPlayer)
    joinedPlayer.CharacterAdded:Connect(function(newChar)
        local targetHumanoid = newChar:WaitForChild("Humanoid")
        local newAnimator = Instance.new("Animator")
        newAnimator.Parent = targetHumanoid
        PlayerDanceData[joinedPlayer] = {
            Playing = false,
            Animator = newAnimator,
            Track = nil,
            Offset = 0
        }
    end)
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    PlayerDanceData[leavingPlayer] = nil
end)

DanceRemote.OnServerEvent:Connect(function(sender, state, playbackOffset)
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            local targetChar = targetPlayer.Character
            if not targetChar then continue end
            local data = PlayerDanceData[targetPlayer]
            if not data then continue end
            data.Playing = state
            data.Offset = playbackOffset
        end)
    end
end)

local function createUi()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.Enabled = GuiVisible

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 240, 0, 420)
    MainFrame.Position = UDim2.new(0.82, 0, 0.45, 0)
    MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    MainFrame.BackgroundTransparency = 0.45
    MainFrame.BorderSizePixel = 0
    MainFrame.CornerRadius = UDim.new(0, 16)
    MainFrame.Parent = ScreenGui

    local btnStart = Instance.new("TextButton")
    btnStart.Size = UDim2.new(0, 200, 0, 85)
    btnStart.Position = UDim2.new(0.08, 0, 0.08, 0)
    btnStart.BackgroundColor3 = Color3.new(0.18, 0.62, 0.93)
    btnStart.BackgroundTransparency = 0.2
    btnStart.BorderSizePixel = 0
    btnStart.CornerRadius = UDim.new(0, 12)
    btnStart.Text = "Start Dance"
    btnStart.TextSize = 28
    btnStart.Font = Enum.Font.SourceSansBold
    btnStart.TextColor3 = Color3.new(1,1,1)
    btnStart.Parent = MainFrame

    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0, 200, 0, 85)
    btnStop.Position = UDim2.new(0.08, 0, 0.29, 0)
    btnStop.BackgroundColor3 = Color3.new(0.91, 0.26, 0.26)
    btnStop.BackgroundTransparency = 0.2
    btnStop.BorderSizePixel = 0
    btnStop.CornerRadius = UDim.new(0, 12)
    btnStop.Text = "Stop Dance"
    btnStop.TextSize = 28
    btnStop.Font = Enum.Font.SourceSansBold
    btnStop.TextColor3 = Color3.new(1,1,1)
    btnStop.Parent = MainFrame

    local btnMusic = Instance.new("TextButton")
    btnMusic.Size = UDim2.new(0, 200, 0, 85)
    btnMusic.Position = UDim2.new(0.08, 0, 0.5, 0)
    btnMusic.BackgroundColor3 = Color3.new(0.32, 0.81, 0.43)
    btnMusic.BackgroundTransparency = 0.2
    btnMusic.BorderSizePixel = 0
    btnMusic.CornerRadius = UDim.new(0, 12)
    btnMusic.Text = "Toggle Music"
    btnMusic.TextSize = 28
    btnMusic.Font = Enum.Font.SourceSansBold
    btnMusic.TextColor3 = Color3.new(1,1,1)
    btnMusic.Parent = MainFrame

    local btnHide = Instance.new("TextButton")
    btnHide.Size = UDim2.new(0, 200, 0, 85)
    btnHide.Position = UDim2.new(0.08, 0, 0.71, 0)
    btnHide.BackgroundColor3 = Color3.new(0.42, 0.42, 0.42)
    btnHide.BackgroundTransparency = 0.2
    btnHide.BorderSizePixel = 0
    btnHide.CornerRadius = UDim.new(0, 12)
    btnHide.Text = "Hide UI"
    btnHide.TextSize = 28
    btnHide.Font = Enum.Font.SourceSansBold
    btnHide.TextColor3 = Color3.new(1,1,1)
    btnHide.Parent = MainFrame

    local dragObject = require(game:GetService("CoreGui"):WaitForChild("Dragger"))
    dragObject:Add(MainFrame)

    btnStart.MouseButton1Click:Connect(function()
        DanceActive = true
        DanceRemote:FireServer(true, 0)
    end)

    btnStop.MouseButton1Click:Connect(function()
        DanceActive = false
        DanceRemote:FireServer(false, 0)
        FullMusic:Stop()
        for _, data in pairs(PlayerDanceData) do
            if data.Track then
                data.Track:Stop()
                data.Track = nil
            end
        end
    end)

    btnMusic.MouseButton1Click:Connect(function()
        MusicPlaying = not MusicPlaying
        if MusicPlaying then
            FullMusic:Play()
        else
            FullMusic:Stop()
        end
    end)

    btnHide.MouseButton1Click:Connect(function()
        GuiVisible = not GuiVisible
        ScreenGui.Enabled = GuiVisible
    end)

    return ScreenGui
end

local FullMusic = Instance.new("Sound")
FullMusic.SoundId = BgmId
FullMusic.Looped = true
FullMusic.Volume = 0.72
FullMusic.Parent = SoundService

RunService.RenderStepped:Connect(function()
    if not DanceActive then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        local data = PlayerDanceData[plr]
        local char = plr.Character
        if not char or not data.Playing or not data.Animator then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then continue end
        if not data.Track then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://"..AnimId
            data.Track = data.Animator:LoadAnimation(anim)
            data.Track.Looped = true
            data.Track:Play(0,1,1)
            data.Track.TimePosition = data.Offset
        end
        if math.abs(data.Track.TimePosition - data.Offset) > 0.09 then
            data.Track.TimePosition = data.Offset
        end
    end
end)

task.spawn(function()
    while task.wait(0.11) do
        if DanceActive then
            DanceRemote:FireServer(true, os.clock()%LoopTime)
        end
    end
end)

createUi()
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local DanceActive = false
local MusicPlaying = false
local GuiVisible = true
local AnimId = 97968838104258
local LoopTime = 12.65
local BgmId = "rbxassetid://11387174269"

local DanceRemote = Instance.new("RemoteEvent")
DanceRemote.Name = "SubjectThreeDanceSync"
DanceRemote.Parent = ReplicatedStorage

local PlayerDanceData = {}
for _, plr in ipairs(Players:GetPlayers()) do
    PlayerDanceData[plr] = {
        Playing = false,
        Animator = nil,
        Track = nil,
        Offset = 0
    }
end

local function onCharacterSpawn(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    local Animator = Instance.new("Animator")
    Animator.Parent = Humanoid
    PlayerDanceData[LocalPlayer].Animator = Animator
    Humanoid.Died:Connect(function()
        task.wait(2.8)
        if LocalPlayer:IsDescendantOf(game.Players) then
            LocalPlayer:LoadCharacter()
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(onCharacterSpawn)

Players.PlayerAdded:Connect(function(joinedPlayer)
    joinedPlayer.CharacterAdded:Connect(function(newChar)
        local targetHumanoid = newChar:WaitForChild("Humanoid")
        local newAnimator = Instance.new("Animator")
        newAnimator.Parent = targetHumanoid
        PlayerDanceData[joinedPlayer] = {
            Playing = false,
            Animator = newAnimator,
            Track = nil,
            Offset = 0
        }
    end)
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)
    PlayerDanceData[leavingPlayer] = nil
end)

DanceRemote.OnServerEvent:Connect(function(sender, state, playbackOffset)
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        task.spawn(function()
            local targetChar = targetPlayer.Character
            if not targetChar then continue end
            local data = PlayerDanceData[targetPlayer]
            if not data then continue end
            data.Playing = state
            data.Offset = playbackOffset
        end)
    end
end)

local function createUi()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer.PlayerGui
    ScreenGui.Enabled = GuiVisible

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 240, 0, 520)
    MainFrame.Position = UDim2.new(0.82, 0, 0.45, 0)
    MainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    MainFrame.BackgroundTransparency = 0.45
    MainFrame.BorderSizePixel = 0
    MainFrame.CornerRadius = UDim.new(0, 16)
    MainFrame.Parent = ScreenGui

    local btnStart = Instance.new("TextButton")
    btnStart.Size = UDim2.new(0, 200, 0, 85)
    btnStart.Position = UDim2.new(0.08, 0, 0.08, 0)
    btnStart.BackgroundColor3 = Color3.new(0.18, 0.62, 0.93)
    btnStart.BackgroundTransparency = 0.2
    btnStart.BorderSizePixel = 0
    btnStart.CornerRadius = UDim.new(0, 12)
    btnStart.Text = "Start Dance"
    btnStart.TextSize = 28
    btnStart.Font = Enum.Font.SourceSansBold
    btnStart.TextColor3 = Color3.new(1,1,1)
    btnStart.Parent = MainFrame

    local btnStop = Instance.new("TextButton")
    btnStop.Size = UDim2.new(0, 200, 0, 85)
    btnStop.Position = UDim2.new(0.08, 0, 0.22, 0)
    btnStop.BackgroundColor3 = Color3.new(0.91, 0.26, 0.26)
    btnStop.BackgroundTransparency = 0.2
    btnStop.BorderSizePixel = 0
    btnStop.CornerRadius = UDim.new(0, 12)
    btnStop.Text = "Stop Dance"
    btnStop.TextSize = 28
    btnStop.Font = Enum.Font.SourceSansBold
    btnStop.TextColor3 = Color3.new(1,1,1)
    btnStop.Parent = MainFrame

    local btnMusic = Instance.new("TextButton")
    btnMusic.Size = UDim2.new(0, 200, 0, 85)
    btnMusic.Position = UDim2.new(0.08, 0, 0.36, 0)
    btnMusic.BackgroundColor3 = Color3.new(0.32, 0.81, 0.43)
    btnMusic.BackgroundTransparency = 0.2
    btnMusic.BorderSizePixel = 0
    btnMusic.CornerRadius = UDim.new(0, 12)
    btnMusic.Text = "Toggle Music"
    btnMusic.TextSize = 28
    btnMusic.Font = Enum.Font.SourceSansBold
    btnMusic.TextColor3 = Color3.new(1,1,1)
    btnMusic.Parent = MainFrame

    local btnKickFly = Instance.new("TextButton")
    btnKickFly.Size = UDim2.new(0, 200, 0, 85)
    btnKickFly.Position = UDim2.new(0.08, 0, 0.50, 0)
    btnKickFly.BackgroundColor3 = Color3.new(0.75, 0.15, 0.15)
    btnKickFly.BackgroundTransparency = 0.2
    btnKickFly.BorderSizePixel = 0
    btnKickFly.CornerRadius = UDim.new(0, 12)
    btnKickFly.Text = "Kick & Fly"
    btnKickFly.TextSize = 28
    btnKickFly.Font = Enum.Font.SourceSansBold
    btnKickFly.TextColor3 = Color3.new(1,1,1)
    btnKickFly.Parent = MainFrame

    local btnHide = Instance.new("TextButton")
    btnHide.Size = UDim2.new(0, 200, 0, 85)
    btnHide.Position = UDim2.new(0.08, 0, 0.64, 0)
    btnHide.BackgroundColor3 = Color3.new(0.42, 0.42, 0.42)
    btnHide.BackgroundTransparency = 0.2
    btnHide.BorderSizePixel = 0
    btnHide.CornerRadius = UDim.new(0, 12)
    btnHide.Text = "Hide UI"
    btnHide.TextSize = 28
    btnHide.Font = Enum.Font.SourceSansBold
    btnHide.TextColor3 = Color3.new(1,1,1)
    btnHide.Parent = MainFrame

    local dragObject = require(game:GetService("CoreGui"):WaitForChild("Dragger"))
    dragObject:Add(MainFrame)

    btnStart.MouseButton1Click:Connect(function()
        DanceActive = true
        DanceRemote:FireServer(true, 0)
    end)

    btnStop.MouseButton1Click:Connect(function()
        DanceActive = false
        DanceRemote:FireServer(false, 0)
        FullMusic:Stop()
        for _, data in pairs(PlayerDanceData) do
            if data.Track then
                data.Track:Stop()
                data.Track = nil
            end
        end
    end)

    btnMusic.MouseButton1Click:Connect(function()
        MusicPlaying = not MusicPlaying
        if MusicPlaying then
            FullMusic:Play()
        else
            FullMusic:Stop()
        end
    end)

    btnKickFly.MouseButton1Click:Connect(function()
        local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local char = plr.Character
            local humRoot = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")
            if not humRoot or not humanoid then continue end
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
            humRoot.Velocity = Vector3.new(math.random(-120,120), 160, math.random(-120,120))
            task.wait(4)
            plr:Kick("Kicked by dance script")
        end
    end)

    btnHide.MouseButton1Click:Connect(function()
        GuiVisible = not GuiVisible
        ScreenGui.Enabled = GuiVisible
    end)

    return ScreenGui
end

local FullMusic = Instance.new("Sound")
FullMusic.SoundId = BgmId
FullMusic.Looped = true
FullMusic.Volume = 0.72
FullMusic.Parent = SoundService

RunService.RenderStepped:Connect(function()
    if not DanceActive then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        local data = PlayerDanceData[plr]
        local char = plr.Character
        if not char or not data.Playing or not data.Animator then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then continue end
        if not data.Track then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://"..AnimId
            data.Track = data.Animator:LoadAnimation(anim)
            data.Track.Looped = true
            data.Track:Play(0,1,1)
            data.Track.TimePosition = data.Offset
        end
        if math.abs(data.Track.TimePosition - data.Offset) > 0.09 then
            data.Track.TimePosition = data.Offset
        end
    end
end)

task.spawn(function()
    while task.wait(0.11) do
        if DanceActive then
            DanceRemote:FireServer(true, os.clock()%LoopTime)
        end
    end
end)

createUi()
