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
local PathfindingService = game:GetService("PathfindingService")

-- Player and Environment
local localPlayer = Players.LocalPlayer
local ourIdentity = getthreadidentity and getthreadidentity() or 8

-- Script Configuration
local config = {
    debugEnabled = true,
    uiLibraryUrl = "https://raw.githubusercontent.com/DUXFX/bloxburg-grinders/refs/heads/main/ui.lua"
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
local remotes = utils:waitFor("Remotes", modules)

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
    cachedFunctions = {}
}

function hairdresserJob:cacheGameFunctions()
    if self.cachedFunctions.doAction then return true end
    utils:debugLog("Searching for core game functions in memory (this runs only once)...")
    for _, func in ipairs(getgc(true)) do
        if typeof(func) == "function" then
            local info = getinfo(func)
            if info.name == "doAction" and info.source and string.find(info.source, "StylezHairdresser") then
                if getupvalue(func, 3) == localPlayer then
                    local styles = getupvalue(func, 6)
                    local colors = getupvalue(func, 8)
                    if type(styles) == "table" and type(colors) == "table" then
                        self.cachedFunctions.doAction = func
                        self.cachedFunctions.hairStyles = styles
                        self.cachedFunctions.hairColors = colors
                        utils:debugLog("Successfully cached and validated all required game functions.")
                        return true
                    end
                end
            end
        end
    end
    warn("[Bloxburg Grinders] CRITICAL: Could not cache hairdresser functions. Game update likely broke upvalue indexes.")
    return false
end

function hairdresserJob:getWorkstations()
    local workstationFolder = utils:waitFor("Workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations")
    if not workstationFolder then return {}, {} end

    local available, occupiedByPlayer = {}, nil
    for _, station in ipairs(workstationFolder:GetChildren()) do
        if station.Name == "Workstation" then
            if station.InUse.Value == localPlayer then
                occupiedByPlayer = station
                break 
            elseif tostring(station.InUse.Value) == "nil" then
                table.insert(available, station)
            end
        end
    end
    return available, occupiedByPlayer
end

function hairdresserJob:selectAndClaimWorkstation()
    local available, myStation = self:getWorkstations()
    if myStation then return myStation end 

    if #available == 0 then return nil end

    table.sort(available, function(a, b)
        return localPlayer:DistanceFromCharacter(a.Mirror.Position) < localPlayer:DistanceFromCharacter(b.Mirror.Position)
    end)
    
    local targetStation = available[1]
    
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
    
    return nil
end

function hairdresserJob:completeCustomerOrder(workstation)
    local npc = workstation.Occupied.Value
    if not npc or npc.Name ~= "StylezHairStudioCustomer" then
        repeat task.wait() until workstation.Occupied.Value and workstation.Occupied.Value.Name == "StylezHairStudioCustomer" or not self.isFarming
        if not self.isFarming then return end
        npc = workstation.Occupied.Value
        task.wait(math.random(8, 20) / 10)
    end

    local styleValue = utils:waitFor("Order.Style", npc)
    local colorValue = utils:waitFor("Order.Color", npc)
    if not styleValue or not colorValue then return end

    local styleIndex = table.find(self.cachedFunctions.hairStyles, styleValue.Value)
    local colorIndex = table.find(self.cachedFunctions.hairColors, colorValue.Value)
    if not styleIndex or not colorIndex then return end
    
    local styleNext = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Next", workstation)
    local styleBack = utils:waitFor("Mirror.HairdresserGUI.Frame.Style.Back", workstation)
    local colorNext = utils:waitFor("Mirror.HairdresserGUI.Frame.Color.Next", workstation)
    local colorBack = utils:waitFor("Mirror.HairdresserGUI.Frame.Color.Back", workstation)
    local doneButton = utils:waitFor("Mirror.HairdresserGUI.Frame.Done", workstation)

    for i = 2, styleIndex do
        firesignal(styleNext.Activated)
        task.wait(math.random(15, 30) / 100)
        if math.random() < 0.05 then
            firesignal(styleNext.Activated); task.wait(math.random(20, 40) / 100)
            firesignal(styleBack.Activated); task.wait(math.random(30, 50) / 100)
        end
    end
    
    task.wait(math.random(4, 9) / 10)

    for i = 2, colorIndex do
        firesignal(colorNext.Activated)
        task.wait(math.random(15, 30) / 100)
    end

    task.wait(math.random(5, 12) / 10)

    firesignal(doneButton.Activated)
    
    repeat task.wait() until workstation.Occupied.Value ~= npc or not self.isFarming
end

function hairdresserJob:mainLoop()
    jobUtils:startShift("StylezHairdresser")
    
    if not self:cacheGameFunctions() then
        self.isFarming = false
        library.flags.hair_farm = false
        return
    end

    while self.isFarming do
        local success, err = pcall(function()
            local workstation = self:selectAndClaimWorkstation()
            if workstation then
                self:completeCustomerOrder(workstation)
                task.wait(math.random(20, 45) / 10)
            else
                task.wait(5)
            end
        end)
        if not success then task.wait(5) end
    end
end

function hairdresserJob:toggleFarming(state)
    self.isFarming = state
    utils:debugLog("Hairdresser autofarm toggled:", state)
    if self.isFarming then task.spawn(function() self:mainLoop() end) end
end

--==============================================================================
-- PIZZA DELIVERY JOB MODULE (INSTANT TELEPORT)
--==============================================================================

local pizzaDeliveryJob = {
    STATE = { IDLE = 0, FETCHING_PIZZA = 1, DELIVERING = 2 },
    pizzaPlanetLocation = CFrame.new(1169, 15, 273),
    currentStatus = ""
}
pizzaDeliveryJob.currentState = pizzaDeliveryJob.STATE.IDLE

function pizzaDeliveryJob:setStatus(status)
    self.currentStatus = status
    if library.labels.pizza_status then
        library.labels.pizza_status.Text = "Status: " .. status
    end
    utils:debugLog("Pizza Job Status:", status)
end

function pizzaDeliveryJob:teleport(targetCFrame)
    local character = localPlayer.Character
    if not character or not character.PrimaryPart then return end
    character.PrimaryPart.CFrame = targetCFrame
end

function pizzaDeliveryJob:getPizza()
    self:setStatus("Returning to Pizza Planet")
    self:teleport(self.pizzaPlanetLocation)
    task.wait(0.2)

    local pizzaBox = localPlayer.Character and localPlayer.Character:FindFirstChild("Pizza Box")
    if pizzaBox then pizzaBox:Destroy() end

    local pizzaStack = utils:waitFor("Workspace.Environment.Locations.PizzaPlanet.Conveyor.MovingBoxes")
    if not pizzaStack or #pizzaStack:GetChildren() == 0 then
        self:setStatus("No pizzas available, waiting...")
        return
    end
    
    self:setStatus("Requesting pizza & customer")
    self.currentState = self.STATE.FETCHING_PIZZA
    
    setthreadidentity(2)
    interactionHandler:ShowMenu(pizzaStack:GetChildren()[1], pizzaStack:GetChildren()[1].Position, pizzaStack:GetChildren()[1])
    firesignal(utils:waitFor("PlayerGui._interactUI.Use.Button", localPlayer).Activated)
    setthreadidentity(ourIdentity)
end

function pizzaDeliveryJob:deliverPizza()
    if not self.currentCustomer or not self.currentCustomer.PrimaryPart then
        self:setStatus("Error: Invalid customer data")
        self.currentState = self.STATE.IDLE
        return
    end

    self:setStatus("Teleporting to customer")
    local customerRoot = self.currentCustomer.PrimaryPart
    local targetPosition = customerRoot.CFrame * CFrame.new(0, 0, 5)
    self:teleport(targetPosition)
    task.wait(0.5)

    self:setStatus("Giving pizza to customer")
    setthreadidentity(2)
    interactionHandler:ShowMenu(self.currentCustomer, customerRoot.Position, customerRoot)
    firesignal(utils:waitFor("PlayerGui._interactUI.Give.Button", localPlayer).Activated)
    setthreadidentity(ourIdentity)
    
    self.currentState = self.STATE.IDLE
    self.currentCustomer = nil
end

function pizzaDeliveryJob:mainLoop()
    jobUtils:startShift("PizzaPlanetDelivery")
    self.currentState = self.STATE.IDLE

    while self.isFarming do
        local success, err = pcall(function()
            if self.currentState == self.STATE.IDLE then
                self:getPizza()
            elseif self.currentState == self.STATE.DELIVERING then
                self:deliverPizza()
            end
            task.wait(1) -- Main loop heartbeat
        end)
        if not success then
            self:setStatus("Error, resetting job...")
            utils:debugLog("Error in Pizza Delivery loop:", err)
            self.currentState = self.STATE.IDLE
            task.wait(5)
        end
    end
    self:setStatus("Disabled")
end

function pizzaDeliveryJob:toggleFarming(state)
    self.isFarming = state
    utils:debugLog("Pizza Delivery autofarm toggled:", state)
    if self.isFarming then
        task.spawn(function() self:mainLoop() end)
    else
        self:setStatus("Disabled")
        self.currentState = self.STATE.IDLE
    end
end

--==============================================================================
-- METAMETHOD HOOKS (FOR PIZZA DELIVERY)
--==============================================================================

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    
    if pizzaDeliveryJob.currentState == pizzaDeliveryJob.STATE.FETCHING_PIZZA and method == "InvokeServer" and self.Name == "Remotes" then
        local args = {...}
        if type(args[2]) == "table" and args[2].Action == "Take" and args[2].Object and args[2].Object.Name == "Pizza Box" then
            local result = oldNamecall(self, ...)
            if typeof(result) == "Instance" and result:IsA("Model") then
                utils:debugLog("Hook captured customer:", result.Name)
                pizzaDeliveryJob.currentCustomer = result
                pizzaDeliveryJob.currentState = pizzaDeliveryJob.STATE.DELIVERING
            end
            return result
        end
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
library.labels.pizza_status = pizzaTab:add_label("Status: Disabled")

utils:debugLog("Bloxburg Grinders - Multi-Job Autofarm loaded!")
