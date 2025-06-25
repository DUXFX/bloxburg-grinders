if getgenv().BLOXBURG_GRINDERS_LOADED then
    warn("[Bloxburg Grinders] Script is already loaded.")
    return
end
getgenv().BLOXBURG_GRINDERS_LOADED = true

--==============================================================================
-- EMBEDDED UI LIBRARY
--==============================================================================

local library = {}
library.flags = {}

function library:create_window(title, width)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BloxburgGrindersUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, width, 0, 300)
    mainFrame.Position = UDim2.new(0.5, -width / 2, 0.5, -150)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 80)
    mainFrame.BorderSizePixel = 2
    mainFrame.Draggable = true
    mainFrame.Active = true
    mainFrame.Parent = screenGui

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleBar.Parent = mainFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 1, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Text = title
    titleLabel.TextSize = 18
    titleLabel.Parent = titleBar

    local container = Instance.new("UIListLayout")
    container.Parent = mainFrame
    container.SortOrder = Enum.SortOrder.LayoutOrder
    container.Padding = UDim.new(0, 5)
    container.FillDirection = Enum.FillDirection.Vertical
    container.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local padding = Instance.new("UIPadding")
    padding.Parent = mainFrame
    padding.PaddingTop = UDim.new(0, 35)
    padding.PaddingLeft = UDim.new(0, 5)
    padding.PaddingRight = UDim.new(0, 5)

    library.mainFrame = mainFrame
    return library
end

function library:add_section(name)
    local sectionLabel = Instance.new("TextLabel")
    sectionLabel.Name = name
    sectionLabel.Size = UDim2.new(1, -10, 0, 25)
    sectionLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sectionLabel.BackgroundTransparency = 1
    sectionLabel.Font = Enum.Font.SourceSansBold
    sectionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    sectionLabel.TextSize = 16
    sectionLabel.Text = name
    sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
    sectionLabel.Parent = library.mainFrame
    return library
end

function library:add_toggle(text, flag, callback)
    library.flags[flag] = false
    local toggleButton = Instance.new("TextButton")
    toggleButton.Name = flag
    toggleButton.Size = UDim2.new(1, -10, 0, 30)
    toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.Font = Enum.Font.SourceSans
    toggleButton.TextSize = 16
    toggleButton.Text = text .. ": Off"
    toggleButton.Parent = library.mainFrame

    toggleButton.MouseButton1Click:Connect(function()
        library.flags[flag] = not library.flags[flag]
        if library.flags[flag] then
            toggleButton.Text = text .. ": On"
            toggleButton.BackgroundColor3 = Color3.fromRGB(80, 160, 80)
        else
            toggleButton.Text = text .. ": Off"
            toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        end
        if callback then
            callback(library.flags[flag])
        end
    end)
    return library
end

function library:add_label(text)
    local label = Instance.new("TextLabel")
    label.Name = "InfoLabel"
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.SourceSans
    label.TextColor3 = Color3.fromRGB(180, 180, 180)
    label.Text = text
    label.TextSize = 14
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = library.mainFrame
    return library
end

--==============================================================================
-- CORE SERVICES AND VARIABLES
--==============================================================================

-- Roblox Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local VirtualUserService = game:GetService("VirtualUser")

-- Player and Environment
local localPlayer = Players.LocalPlayer
local ourIdentity = getthreadidentity and getthreadidentity() or 8

-- Script Configuration
local config = {
    debugEnabled = true,
}

--==============================================================================
-- UTILITY FUNCTIONS
--==============================================================================

local utils = {}

function utils:debugLog(...)
    if config.debugEnabled then
        warn("[Bloxburg Grinders]", ...)
    end
end

function utils:waitFor(path, start, timeout)
    local segments = path:split(".")
    local current = start or game
    for i, segment in ipairs(segments) do
        local success, result = pcall(function()
            return current:WaitForChild(segment, timeout or 10)
        end)
        if not success or not result then
            utils:debugLog(`WaitFor failed at segment '{segment}' in path '{path}'`)
            return nil
        end
        current = result
    end
    return current
end

--==============================================================================
-- GAME MODULES & HANDLERS
--==============================================================================

local modules = utils:waitFor("PlayerScripts.Modules", localPlayer)
local jobHandler = require(utils:waitFor("JobHandler", modules))
local interactionHandler = require(utils:waitFor("InteractionHandler", modules))

-- Anti-AFK
localPlayer.Idled:Connect(function()
    VirtualUserService:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(0.2)
    VirtualUserService:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    utils:debugLog("Anti-AFK triggered.")
end)

--==============================================================================
-- JOB UTILS
--==============================================================================

local jobUtils = {}

function jobUtils:isWorking(jobName)
    setthreadidentity(2)
    local currentJob = jobHandler:GetJob()
    setthreadidentity(ourIdentity)
    return currentJob == jobName
end

function jobUtils:startShift(jobName)
    if jobUtils:isWorking(jobName) then return true end
    
    setthreadidentity(2)
    local currentJob = jobHandler:GetJob()
    if currentJob then
        jobHandler:EndShift(currentJob)
    end
    task.wait(1.5) -- Wait after ending previous shift
    jobHandler:GoToWork(jobName)
    setthreadidentity(ourIdentity)
    
    utils:debugLog(`Started shift for: {jobName}`)
    task.wait(2) -- Wait for teleport
end

--==============================================================================
-- HAIRDRESSER JOB MODULE
--==============================================================================

local hairdresserJob = {
    isFarming = false,
    cachedFunctions = {},
    cachedWorkstationData = {}
}

--- Caches core game functions to avoid repeated memory scans.
function hairdresserJob:cacheGameFunctions()
    if self.cachedFunctions.doAction then return end
    utils:debugLog("Searching for core game functions in memory (this runs only once)...")
    for _, func in ipairs(getgc(true)) do
        if typeof(func) == "function" then
            local info = getinfo(func)
            if info.name == "doAction" and info.source and string.find(info.source, "StylezHairdresser") then
                if getupvalue(func, 3) == localPlayer then
                    self.cachedFunctions.doAction = func
                    self.cachedFunctions.hairStyles = getupvalue(func, 6)
                    self.cachedFunctions.hairColors = getupvalue(func, 8)
                    utils:debugLog("Successfully cached all required game functions.")
                    return
                end
            end
        end
    end
end

function hairdresserJob:getWorkstations()
    local workstationFolder = utils:waitFor("Workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations")
    if not workstationFolder then return {}, {} end

    local available, occupiedByPlayer = {}, nil
    for _, station in ipairs(workstationFolder:GetChildren()) do
        if station.Name == "Workstation" then
            if station.InUse.Value == localPlayer then
                occupiedByPlayer = station
                break -- If we found our station, no need to check others
            elseif tostring(station.InUse.Value) == "nil" then
                table.insert(available, station)
            end
        end
    end
    return available, occupiedByPlayer
end

--- Selects a workstation with some randomness to appear more human.
function hairdresserJob:selectAndClaimWorkstation()
    local available, myStation = self:getWorkstations()
    if myStation then return myStation end -- Already have a station

    if #available == 0 then
        utils:debugLog("No available workstations found.")
        return nil
    end

    -- Sort by distance
    table.sort(available, function(a, b)
        return localPlayer:DistanceFromCharacter(a.Mirror.Position) < localPlayer:DistanceFromCharacter(b.Mirror.Position)
    end)
    
    -- Choose a station. 70% chance to pick the closest, 30% to pick the 2nd/3rd closest.
    local targetStation
    local choice = math.random()
    if choice < 0.7 or #available < 2 then
        targetStation = available[1]
    else
        targetStation = available[math.min(#available, math.random(2, 3))]
    end
    
    utils:debugLog("Selected workstation:", targetStation:GetFullName())
    
    -- Claim it
    (localPlayer.Character or localPlayer.CharacterAdded:Wait()).Humanoid:MoveTo(targetStation.Mat.Position)
    local nextButton = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Next", targetStation)
    local backButton = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Back", targetStation)

    local attempts = 0
    repeat
        firesignal(nextButton.Activated); task.wait()
        firesignal(backButton.Activated); task.wait(0.2)
        attempts = attempts + 1
    until targetStation.InUse.Value == localPlayer or attempts > 15

    if targetStation.InUse.Value == localPlayer then
        utils:debugLog("Successfully claimed workstation.")
        return targetStation
    end
    utils:debugLog("Failed to claim workstation.")
    return nil
end

--- The core function to complete a customer order with humanized actions.
function hairdresserJob:completeCustomerOrder(workstation)
    local npc = workstation.Occupied.Value
    if not npc or npc.Name ~= "StylezHairStudioCustomer" then
        utils:debugLog("Waiting for customer...")
        repeat task.wait() until workstation.Occupied.Value and workstation.Occupied.Value.Name == "StylezHairStudioCustomer" or not self.isFarming
        if not self.isFarming then return end
        npc = workstation.Occupied.Value
        utils:debugLog("New customer arrived.")
        task.wait(math.random(8, 20) / 10) -- "Thinking time" before starting
    end

    local styleValue = utils:waitFor("Order.Style", npc)
    local colorValue = utils:waitFor("Order.Color", npc)
    if not styleValue or not colorValue then return end -- Error or customer left

    local styleIndex = table.find(self.cachedFunctions.hairStyles, styleValue.Value)
    local colorIndex = table.find(self.cachedFunctions.hairColors, colorValue.Value)
    if not styleIndex or not colorIndex then return end

    utils:debugLog(`Processing order: Style {styleIndex}, Color {colorIndex}`)
    
    local styleNext = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Next", workstation)
    local styleBack = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Back", workstation)
    local colorNext = utils:waitFor("Mirror.HairdresserGUI.Frame.Color.Next", workstation)
    local colorBack = utils:waitFor("Mirror.HairdresserGUI.Frame.Color.Back", workstation)
    local doneButton = utils:waitFor("Mirror.HairdresserGUI.Frame.Done", workstation)

    -- Click through styles
    for i = 2, styleIndex do
        firesignal(styleNext.Activated)
        task.wait(math.random(15, 30) / 100)
        -- 5% chance to "overshoot" and correct
        if math.random() < 0.05 then
            utils:debugLog("Simulating style selection mistake...")
            firesignal(styleNext.Activated); task.wait(math.random(20, 40) / 100)
            firesignal(styleBack.Activated); task.wait(math.random(30, 50) / 100)
        end
    end
    
    task.wait(math.random(4, 9) / 10) -- Pause between style and color

    -- Click through colors
    for i = 2, colorIndex do
        firesignal(colorNext.Activated)
        task.wait(math.random(15, 30) / 100)
    end

    task.wait(math.random(5, 12) / 10) -- Final pause before finishing

    firesignal(doneButton.Activated)
    utils:debugLog("Order completed.")
    
    repeat task.wait() until workstation.Occupied.Value ~= npc or not self.isFarming
end

--- The main farming loop.
function hairdresserJob:mainLoop()
    -- Ensure we are on the right job
    jobUtils:startShift("StylezHairdresser")
    
    -- Ensure functions are cached before starting
    self:cacheGameFunctions()
    if not self.cachedFunctions.doAction then
        warn("[Bloxburg Grinders] Could not find core game functions. Stopping farm.")
        self.isFarming = false
        library.flags.hair_farm = false
        return
    end

    while self.isFarming do
        local success, err = pcall(function()
            local workstation = self:selectAndClaimWorkstation()
            if workstation then
                self:completeCustomerOrder(workstation)
                -- Take a "break" after finishing
                local breakTime = math.random(20, 45) / 10 -- 2 to 4.5 second break
                utils:debugLog(`Taking a {string.format("%.1f", breakTime)}s break.`)
                task.wait(breakTime)
            else
                utils:debugLog("Failed to get a workstation, trying again in 5s.")
                task.wait(5)
            end
        end)

        if not success then
            utils:debugLog("An error occurred in the main loop:", err)
            task.wait(5) -- Wait after an error before retrying
        end
    end
end

--- Toggles the farm on and off.
function hairdresserJob:toggleFarming(state)
    self.isFarming = state
    utils:debugLog("Hairdresser autofarm toggled:", state)

    if self.isFarming then
        task.spawn(function()
            self:mainLoop()
        end)
    end
end

--==============================================================================
-- UI SETUP
--==============================================================================

library:create_window("Bloxburg Grinders", 250)
local hairTab = library:add_section("Stylez Hairdresser (Humanized)")

hairTab:add_toggle("Autofarm", "hair_farm", function(state)
    hairdresserJob:toggleFarming(state)
end)

hairTab:add_label("This version uses human-like behavior to avoid detection.")

utils:debugLog("Bloxburg Grinders - Humanized Autofarm loaded!")
