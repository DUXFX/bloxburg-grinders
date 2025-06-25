if getgenv().BLOXBURG_GRINDERS_LOADED then
    warn("[Bloxburg Grinders] Script is already loaded.")
    return
end
getgenv().BLOXBURG_GRINDERS_LOADED = true

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
    uiLibraryUrl = "https://raw.githubusercontent.com/iopsec/bloxburg-grinders/main/ui.lua"
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

local library = loadstring(game:HttpGet(config.uiLibraryUrl))()
if not library then
    warn("[Bloxburg Grinders] CRITICAL: Failed to load UI library.")
    return
end

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
-- PIZZA DELIVERY JOB MODULE (INSTANT TELEPORT)
--==============================================================================

local pizzaDeliveryJob = {
    isFarming = false,
    currentCustomer = nil,
    pizzaPlanetLocation = CFrame.new(1169, 15, 273) -- Safe spot at Pizza Planet
}

--- Teleports the player character instantly to a target CFrame.
function pizzaDeliveryJob:teleport(targetCFrame)
    local character = localPlayer.Character
    if not character or not character.PrimaryPart then return end
    
    local rootPart = character.PrimaryPart
    rootPart.Anchored = true
    rootPart.CFrame = targetCFrame
    task.wait() -- Allow physics to update
    rootPart.Anchored = false
    utils:debugLog("Teleport successful.")
end

--- Initiates the process of getting a pizza.
function pizzaDeliveryJob:getPizza()
    local pizzaBox = localPlayer.Character:FindFirstChild("Pizza Box")
    if pizzaBox then pizzaBox:Destroy() end -- Remove any old box

    local pizzaStack = utils:waitFor("Workspace.Environment.Locations.PizzaPlanet.Conveyor.MovingBoxes")
    if not pizzaStack or #pizzaStack:GetChildren() == 0 then
        utils:debugLog("No pizzas available on the conveyor.")
        return
    end
    
    self:teleport(self.pizzaPlanetLocation)
    task.wait(0.2)

    self.currentCustomer = nil -- Reset customer before getting a new one
    
    setthreadidentity(2)
    -- This action fires the remote event that our hook will capture
    interactionHandler:ShowMenu(pizzaStack:GetChildren()[1], pizzaStack:GetChildren()[1].Position, pizzaStack:GetChildren()[1])
    firesignal(utils:waitFor("PlayerGui._interactUI.Use.Button", localPlayer).Activated)
    setthreadidentity(ourIdentity)
    
    utils:debugLog("Pizza collection initiated. Waiting for customer assignment...")
end

--- Delivers the pizza to the current customer.
function pizzaDeliveryJob:deliverPizza()
    if not self.currentCustomer or not self.currentCustomer.PrimaryPart then
        utils:debugLog("Cannot deliver: Invalid customer.")
        return
    end

    local customerRoot = self.currentCustomer.PrimaryPart
    -- Teleport to a safe spot right in front of the customer
    local targetPosition = customerRoot.CFrame * CFrame.new(0, 0, 5)
    self:teleport(targetPosition)
    task.wait(0.5) -- Wait to ensure interaction is possible

    setthreadidentity(2)
    interactionHandler:ShowMenu(self.currentCustomer, customerRoot.Position, customerRoot)
    firesignal(utils:waitFor("PlayerGui._interactUI.Give.Button", localPlayer).Activated)
    setthreadidentity(ourIdentity)
    
    -- Wait for the pizza box to disappear from our character
    local timeout = 0
    repeat task.wait() timeout = timeout + 1 until not localPlayer.Character:FindFirstChild("Pizza Box") or not self.isFarming or timeout > 50

    if not localPlayer.Character:FindFirstChild("Pizza Box") then
        utils:debugLog("Delivery successful!")
    else
        utils:debugLog("Delivery failed, pizza box still present.")
    end
end

--- The main loop for pizza delivery.
function pizzaDeliveryJob:mainLoop()
    jobUtils:startShift("PizzaPlanetDelivery")

    while self.isFarming do
        local success, err = pcall(function()
            self:getPizza()
            
            -- Wait here for the hook to assign a customer
            local timeout = 0
            repeat 
                task.wait() 
                timeout = timeout + 1 
            until self.currentCustomer or not self.isFarming or timeout > 100 -- Wait up to 10 seconds

            if self.currentCustomer then
                utils:debugLog("Customer assigned. Proceeding to delivery.")
                task.wait(math.random(5, 10) / 10) -- Short pause before delivering
                self:deliverPizza()
                task.wait(math.random(10, 20) / 10) -- Short pause after delivering
            else
                utils:debugLog("Did not get a customer after 10 seconds. Retrying...")
                task.wait(3)
            end
        end)
        if not success then
            utils:debugLog("Error in Pizza Delivery loop:", err)
            task.wait(5) -- Wait after error
        end
    end
end

function pizzaDeliveryJob:toggleFarming(state)
    self.isFarming = state
    utils:debugLog("Pizza Delivery autofarm toggled:", state)
    if self.isFarming then
        task.spawn(function()
            self:mainLoop()
        end)
    end
end

--==============================================================================
-- METAMETHOD HOOKS (FOR PIZZA DELIVERY)
--==============================================================================

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    -- Intercept the server call that assigns a pizza customer
    if pizzaDeliveryJob.isFarming and method == "InvokeServer" and self.Name == "Remotes" and args[1] == "GetCustomer" then
        local customer = oldNamecall(self, ...)
        if typeof(customer) == "Instance" and customer:IsA("Model") then
            utils:debugLog("Hook captured customer:", customer.Name)
            pizzaDeliveryJob.currentCustomer = customer
        end
        return customer
    end

    return oldNamecall(self, ...)
end)


--==============================================================================
-- UI SETUP
--==============================================================================

library:create_window("Bloxburg Grinders", 250)

-- Hairdresser Tab
local hairTab = library:add_section("Stylez Hairdresser (Humanized)")
hairTab:add_toggle("Autofarm", "hair_farm", function(state)
    hairdresserJob:toggleFarming(state)
end)
hairTab:add_label("Uses human-like behavior to avoid detection.")

-- Pizza Delivery Tab
local pizzaTab = library:add_section("Pizza Delivery (Instant TP)")
pizzaTab:add_toggle("Autofarm", "pizza_farm", function(state)
    pizzaDeliveryJob:toggleFarming(state)
end)
pizzaTab:add_label("Uses instant teleport for max speed.")


utils:debugLog("Bloxburg Grinders - Multi-Job Autofarm loaded!")
