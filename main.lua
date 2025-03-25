if BLOXBURG_GRINDERS_LOADED then
    warn("Only 1 instance of bloxburg grinders can be executed at once, to prevent issues.");
    return;
end

getgenv().BLOXBURG_GRINDERS_LOADED = true;

local debug_enabled = false;
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/iopsec/bloxburg-grinders/main/ui.lua"))();

-- utils
local utils = {} do
    function utils:debug_log(...)
        if debug_enabled then
            warn("[Bloxburg Grinders]", ...);
        end
    end
    
    function utils:find_from(path, start, wait_for_child)
        assert(typeof(path) == "string", "utils:find_from | expected \"path\" to be a string.")

        local path_segments = path:split(".");
        local base_instance = start;

        if not base_instance then
            local success, result = pcall(game.GetService, game, path_segments[1]);
            if not success or not result then
                return error(`utils:find_from | expected "start" ("{tostring(path_segments[1])}") to be an Instance or valid service.`, 0);
            end
            base_instance = game:GetService(table.remove(path_segments, 1));
        end
                
        for i, segment in next, path_segments do
            if segment == "LocalPlayer" then
                base_instance = base_instance[segment];
                continue;
            end

            if wait_for_child then
                base_instance = base_instance:WaitForChild(segment, 10);
                if not base_instance then
                    warn(`utils:find_from | Stalled at "{segment}" in path "{path}".\n\nTraceback: {debug.traceback()}`);
                    task.wait(9e9);
                end
            else
                base_instance = base_instance:FindFirstChild(segment);
            end

            if not base_instance then
                return nil;
            end
        end

        return base_instance;
    end

    function utils:find(path, start)
        return self:find_from(path, start);
    end

    function utils:wait_for(path, start)
        return self:find_from(path, start, true);
    end
end

-- variables
local player = utils:find_from("Players.LocalPlayer");
local modules = utils:wait_for("PlayerScripts.Modules", player);
local data_service = utils:wait_for("ReplicatedStorage.Modules.DataService");
local job_module = require(utils:wait_for("JobHandler", modules));
local interaction_module = require(utils:wait_for("InteractionHandler", modules));
local locations = utils:wait_for("Workspace.Environment.Locations");
local pathfinding_service = game:GetService("PathfindingService");
local virtual_user_service = game:GetService("VirtualUser")

-- anti afk
player.Idled:Connect(function()
    virtual_user_service:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame);
    task.wait(0.5);
    virtual_user_service:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame);
end)

-- pathfinding (copied from roblox <3)
local pathfinding = {} do
    function pathfinding:walk_to(target, no_jump)
        print("Finding path to", target)
        local path = pathfinding_service:CreatePath();
        local waypoints, next_waypoint_idx, reached_connection, blocked_connection;
        local completed = false;
        local _type = typeof(target);
        if not table.find({"BasePart", "CFrame", "Vector3"}, _type) then
            return error(`pathfinding:walk_to | "target" expected to be of type ("BasePart", "CFrame", "Vector3") got "{_type}".`, 0);
        end

        local character = player.Character or player.CharacterAdded:Wait();
        local humanoid = character:WaitForChild("Humanoid");
        local success, err_message = pcall(function()
            path:ComputeAsync(character.PrimaryPart.Position, _type == "Vector3" and target or target.Position);
        end)

        if success and path.Status == Enum.PathStatus.Success then
            waypoints = path:GetWaypoints();
            for i, v in next, waypoints do                
                humanoid:MoveTo(v.Position);

                if v.Action == Enum.PathWaypointAction.Jump and not no_jump then
                    task.spawn(function()
                        task.wait(0.15);
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping);
                    end);
                end

                humanoid.MoveToFinished:Wait();
            end

            blocked_connection = nil;

        else
            utils:debug_log("err")
            return error(`pathfinding:walk_to | Failed to compute path from {tostring(character.PrimaryPart.Position)} to {tostring(character.PrimaryPart.Position, _type == "Vector3" and target or target.Position)}`, 0);
        end
    end
end

-- interaction handler
local disable_interaction = false;
local old_show_menu; old_show_menu = hookfunction(interaction_module.ShowMenu, newcclosure(function(...)
    if not checkcaller() and disable_interaction == true then
        return;
    end
    return old_show_menu(...);
end))

local interaction = {} do
    function interaction:click_btn(text)
        for _, v in next, utils:wait_for("PlayerGui._interactUI", player):GetChildren() do
            if v:FindFirstChild("Button") and v.Button:FindFirstChild("TextLabel") and v.Button.TextLabel.Text == text then
                getconnections(v.Button.Activated)[1]:Fire();
            end
        end
    end

    function interaction:quick_interact(model, text, specified_part)
        local part = specified_part or model.PrimaryPart or model:FindFirstChildOfClass("MeshPart") or model:FindFirstChildOfClass("BasePart");
        interaction_module:ShowMenu(model, part.Position, part);
        self:click_btn(text);
    end
end

-- hairdressers
local hairdressers = {
    do_actions = {}
} do
    function hairdressers:start_shift()
        job_module:GoToWork("StylezHairdresser");
    end

    function hairdressers:get_do_actions()
        if #hairdressers.do_actions == 4 then
            return hairdressers.do_actions;
        end

        for _, v in next, getgc() do
            if typeof(v) == "function" and getfenv(v).script.Name == "StylezHairdresser" and getinfo(v).name == "doAction" then
                hairdressers.do_actions[#hairdressers.do_actions + 1] = v;
            end
        end

        return hairdressers.do_actions;
    end

    function hairdressers:get_our_func()
        for _, hairdresser_func in next, hairdressers:get_do_actions() do
            if getupvalue(hairdresser_func, 3) == player then
                return hairdresser_func;
            end
        end
    end

    function hairdressers:get_workstations()
        local workstation_folder = utils:wait_for("StylezHairStudio.HairdresserWorkstations", locations);
        
        if not workstation_folder then
            return error("hairdressers:get_workstations | Failed to find workstation_folder.", 0);
        end

        local workstations = {};
        
        for _, workstation in next, workstation_folder:GetChildren() do
            if workstation.Name == "Workstation" and table.find({player.Name, "nil"}, tostring(workstation.InUse.Value)) then
                workstations[#workstations + 1] = workstation;
            end
        end

        return workstations;
    end

    function hairdressers:get_nearest_workstation()
        local workstations = self:get_workstations();
        local closest_workstation, distance = nil, math.huge;

        if workstations then
            for _, v in next, workstations do
                local workstation_distance = player:DistanceFromCharacter(v.Mirror.Position);
                if distance > workstation_distance then
                    distance = workstation_distance;
                    closest_workstation = v
                end
            end
            return closest_workstation;
        end
    end

    function hairdressers:claim_workstation(workstation)
        player.Character.Humanoid:MoveTo(workstation.Mat.Position);
        
        local next_button = utils:wait_for("Mirror.HairdresserGUI.Frame.Style.Next", workstation);
        local back_button = utils:wait_for("Mirror.HairdresserGUI.Frame.Style.Back", workstation);
        repeat
            getconnections(next_button.Activated)[1].Function();
            task.wait();
            getconnections(back_button.Activated)[1].Function();
            task.wait(0.1);
        until workstation.InUse.Value ~= nil

        if workstation.InUse.Value ~= player then
            return self:claim_workstation(self:get_nearest_workstation());
        end

        return workstation;
    end

    function hairdressers:get_workstation()
        local workstations = self:get_workstations();

        if workstations then
            for _, v in next, workstations do
                if v.InUse.Value == player then
                    return v
                end
            end
            
            local workstation = self:get_nearest_workstation();
            if workstation then
                return self:claim_workstation(workstation);
            end
        end
    end

    function hairdressers:get_order_idx(npc)
        local style, style_idx = utils:wait_for("Order.Style", npc), nil;
        local color, color_idx = utils:wait_for("Order.Color", npc), nil;

        local hair_styles = getupvalue(hairdressers.do_actions[1], 6);
        local hair_colors = getupvalue(hairdressers.do_actions[1], 8);

        if style and color then 
            for i, v in next, hair_styles do
                if tostring(v) == style.Value then
                    style_idx = i;
                    break;
                end
            end

            for i, v in next, hair_colors do
                if tostring(v) == color.Value then
                    color_idx = i;
                    break;
                end
            end

            return {style_idx, color_idx};
        end
    end

    function hairdressers:complete_order()
        local workstation = self:get_workstation();
        if workstation then
            local our_func = self:get_our_func();
            if our_func then
                local style_next_button = utils:wait_for("Mirror.HairdresserGUI.Frame.Style.Next", workstation);
                local color_next_button = utils:wait_for("Mirror.HairdresserGUI.Frame.Color.Next", workstation);
                local done_button = utils:wait_for("Mirror.HairdresserGUI.Frame.Done", workstation);
                local npc = workstation.Occupied.Value;
                if npc ~= nil then
                    local order_idx = self:get_order_idx(npc);
                    if order_idx then
                        for i=1, order_idx[1] do
                            if i==1 then
                                continue;
                            end
                            getconnections(style_next_button.Activated)[1].Function();
                            task.wait(library.flags.hair_farm_legit and math.random(3, 6)/10 or 0);
                        end
                        task.wait(library.flags.hair_farm_legit and math.random(3, 6)/10 or 0);
                        for i=1, order_idx[2] do
                            if i==1 then
                                continue;
                            end
                            getconnections(color_next_button.Activated)[1].Function();
                            task.wait(library.flags.hair_farm_legit and math.random(3, 6)/10 or 0);
                        end
                        task.wait(library.flags.hair_farm_legit and math.random(3, 6)/10 or 0);
                        getconnections(done_button.Activated)[1].Function();
                        repeat task.wait() until workstation.Occupied.Value ~= npc
                        repeat task.wait() until tostring(workstation.Occupied.Value) == "StylezHairStudioCustomer"
                        task.wait(1);
                    else
                        self:complete_order();
                    end
                end
            end
        end
    end

    function hairdressers:toggle_farming(state)
        if state then
            if not job_module.IsWorking() then
                hairdressers:start_shift();
            end
    
            hairdressers:get_workstation();
    
            task.spawn(function()
                while library.flags.hair_farm do
                    hairdressers:complete_order();
                    task.wait(1);
                end
            end);
        end
    end
end


-- ice cream
local ice_cream = { farming = false, connections = {}, orders_completed = 0 } do
    local positions = {
        cup_station = Vector3.new(929, 13, 1049),
        flavour_station = Vector3.new(933, 13, 1051),
        topping_station = Vector3.new(926, 13, 1046),
        front_counter = Vector3.new(942, 13, 1042)
    };

    function ice_cream:get_workstation()
        local workstations = utils:wait_for("BensIceCream.CustomerTargets", locations):GetChildren();
        for _, workstation in next, workstations do
            local customer = workstation.Occupied.Value;
            if customer and customer.Order.Value == "" then
                return workstation, customer;
            end
        end
    end

    function ice_cream:toggle_farming(state)
        if typeof(state) == "boolean" then
            self.farming = state;
        else
            self.farming = not self.farming;
        end

        if not self.farming then
            disable_interaction = false;
            self.orders_completed = 0;
            return
        end

        disable_interaction = true;

        if job_module:GetJob() ~= "BensIceCreamSeller" then
            job_module:GoToWork("BensIceCreamSeller");
            task.wait(1);
            player.Character.Humanoid:MoveTo(positions.front_counter);
            repeat task.wait() until 5 >= player:DistanceFromCharacter(positions.front_counter);
        end
        
        coroutine.wrap(function()
            local current_order;
            while self.farming do
                current_order = self.orders_completed;
                task.wait(10);
                if current_order == self.orders_completed and self.farming then
                    self:toggle_farming(false);
                    self:toggle_farming(true);
                    self.orders_completed = current_order;
                end
            end
        end)();
        
        coroutine.wrap(function()
            while self.farming do
                local workstation, customer = self:get_workstation();
                if workstation and customer then
                    local table_objs = utils:wait_for("BensIceCream.TableObjects", locations);
                    
                    local flavor1 = utils:wait_for("Order.Flavor1", customer).Value;
                    local flavor2 = utils:wait_for("Order.Flavor2", customer).Value;
                    local topping = utils:wait_for("Order.Topping", customer).Value;
                    
                    utils:debug_log(`Order {self.orders_completed + 1} - Making a {flavor1} + {flavor2}{topping ~= "" and " with " .. topping or ""}.`);

                    pathfinding:walk_to(positions.cup_station, true);

                    repeat
                        interaction:quick_interact(table_objs.IceCreamCups, "Take");
                        task.wait(0.5)
                    until player.Character:FindFirstChild("Ice Cream Cup") or self.farming == false;

                    if self.farming == false then
                        return;
                    end

                    task.wait(.5);

                    if library.flags.ice_farm_legit then
                        player.Character.Humanoid:MoveTo(positions.flavour_station);
                        player.Character.Humanoid.MoveToFinished:Wait();
                    end

                    interaction:quick_interact(table_objs:FindFirstChild(flavor1), "Add");
                    task.wait(library.flags.ice_farm_legit and math.random(5, 13)/10 or 0.25);
                    interaction:quick_interact(table_objs:FindFirstChild(flavor2), "Add");
                    task.wait(library.flags.ice_farm_legit and math.random(5, 13)/10 or 0.25);


                    if topping ~= "" then
                        if library.flags.ice_farm_legit then
                            player.Character.Humanoid:MoveTo(positions.topping_station);
                            player.Character.Humanoid.MoveToFinished:Wait();
                        end
                        interaction:quick_interact(table_objs:FindFirstChild(topping), "Add");
                        task.wait(library.flags.ice_farm_legit and math.random(3, 5)/10 or 0.1)
                    end

                    local customer_position = customer.HumanoidRootPart.Position;
                    local customer_direction = (customer_position - player.Character.HumanoidRootPart.Position).unit;

                    player.Character.Humanoid:MoveTo(customer_position - customer_direction * 4.5);
                    player.Character.Humanoid.MoveToFinished:Wait();
                    task.wait(0.25);

                    interaction:quick_interact(customer, "Give");

                    self.orders_completed += 1;

                    repeat task.wait() until workstation.Occupied.Value ~= customer;
                    utils:debug_log(`Order {self.orders_completed} completed.`);
                    
                    task.wait(0.5);
                else
                    player.Character.Humanoid:MoveTo(positions.front_counter);
                    player.Character.Humanoid.MoveToFinished:Wait();
                end
            end
        end)();
    end
end

-- supermarket cashier
local supermarket_cashier = { farming = false,  orders_completed = 0 }; do
    function supermarket_cashier:get_workstations()
        local workstation_folder = utils:wait_for("Supermarket.CashierWorkstations", locations);
        
        if not workstation_folder then
            return error("supermarket_cashier:get_workstations | Failed to find workstation_folder.", 0);
        end

        local workstations = {};
        
        for _, workstation in next, workstation_folder:GetChildren() do
            if workstation.Name == "Workstation" and table.find({player.Name, "nil"}, tostring(workstation.InUse.Value)) then
                workstations[#workstations + 1] = workstation;
            end
        end

        return workstations;
    end
    
    function supermarket_cashier:get_nearest_workstation()
        local workstations = self:get_workstations();
        local closest_workstation, distance = nil, math.huge;

        if workstations then
            for _, v in next, workstations do
                local workstation_distance = player:DistanceFromCharacter(v.Scanner.Position);
                if distance > workstation_distance then
                    distance = workstation_distance;
                    closest_workstation = v
                end
            end
            return closest_workstation;
        end
    end

    function supermarket_cashier:claim_workstation()
        local workstation = self:get_nearest_workstation();
        pathfinding:walk_to(workstation.Scanner.Position - Vector3.new(4, 0, 0), true);
        interaction:quick_interact(workstation.BagHolder, "Take");
        return workstation;
    end

    function supermarket_cashier:get_workstation()
        local workstations = self:get_workstations();
        for _, v in next, workstations do
            if v.InUse.Value == player then
                return v;
            end
        end
    end

    function supermarket_cashier:needs_restocking()
        local workstation = self:get_workstation();
        if not workstation then
            workstation = supermarket_cashier:claim_workstation();
        end

        return workstation.BagsLeft.Value == 0;
    end

    function supermarket_cashier:restock()
        local workstation = self:get_workstation();
        if not self:needs_restocking() then
            return;
        end
        
        if not utils:find("BFF Bags", player.Character) then
            local crate = utils:wait_for("Supermarket.Crates.BagCrate", locations);
            
            pathfinding:walk_to(crate.Position + Vector3.new(5, 0, -5));
            task.wait(0.5);
            repeat
                interaction:quick_interact(crate, "Take", crate);
                task.wait(0.25);
            until utils:find("BFF Bags", player.Character);
        end

        pathfinding:walk_to(workstation.Scanner.Position - Vector3.new(4, 0, 0));

        repeat
            interaction:quick_interact(workstation.BagHolder, "Restock", workstation.BagHolder.PrimaryPart);
            task.wait(0.25);
        until self:needs_restocking() == false;
    end

    function supermarket_cashier:get_current_bag_count(workstation)
        local bag_count = 8;
        for _, v in next, workstation.Bags:GetChildren() do
            bag_count -= v.Transparency
        end
        return bag_count;
    end

    function supermarket_cashier:on_dropped_food(workstation, food)
        if not self.farming then
            return;
        end
        local food_dropped = utils:wait_for("Status.PlacedObjects", workstation.Occupied.Value).Value;
        if food_dropped / 3 > self:get_current_bag_count(workstation) then
            self:restock();
            interaction:quick_interact(workstation.BagHolder, "Take");
            task.wait(0.05);
        end
        interaction:quick_interact(food, "Scan", food);
        task.wait(0.05);
    end

    function supermarket_cashier:complete_order()
        if job_module:GetJob() ~= "SupermarketCashier" or not self.farming then
            return;
        end

        self.food_dropped = 0;

        local workstation = self:get_workstation();
        
        if not workstation then
            workstation = self:claim_workstation();
        end
        
        self:restock();

        if not self.farming then
            return;
        end

        repeat task.wait() until workstation.Occupied.Value ~= nil;

        local customer = workstation.Occupied.Value;
        
        if customer ~= nil then
            repeat
                for _, v in next, workstation.DroppedFood:GetChildren() do
                    self:on_dropped_food(workstation, v);
                    task.wait(library.flags.market_cashier_farm_legit and math.random(4, 10)/10 or 0.05);
                end
                task.wait(library.flags.market_cashier_farm_legit and math.random(4, 10)/10 or 0.05);
            until utils:wait_for("Status.PlacedObjects", customer).Value == utils:wait_for("Status.ScannedObjects", customer).Value and 3 >= (customer.Head.Position - workstation.CustomerTarget_2.Position).Magnitude
            
            local done_button = utils:wait_for("Display.Screen.CashierGUI.Frame.Done", workstation);
            getconnections(done_button.Activated)[1]:Fire();

            repeat task.wait() until workstation.Occupied.Value ~= customer;

            self.orders_completed += 1;
        end
    end

    function supermarket_cashier:toggle_farming(state)
        if typeof(state) == "boolean" then
            self.farming = state;
        else
            self.farming = not self.farming;
        end

        if not self.farming then
            disable_interaction = false;
            self.orders_completed = 0;
            return
        end

        disable_interaction = true;

        if job_module:GetJob() ~= "SupermarketCashier" then
            job_module:GoToWork("SupermarketCashier");
            self:claim_workstation();
        end
        
        coroutine.wrap(function()
            local current_order;
            while self.farming do
                current_order = self.orders_completed;
                task.wait(30);
                if current_order == self.orders_completed and self.farming then
                    self:toggle_farming(false);
                    self:toggle_farming(true);
                    self.orders_completed = current_order;
                end
            end
        end)();
        
        coroutine.wrap(function()
            while self.farming do
                self:complete_order();
            end
        end)();
    end
end

library:create_window("Bloxburg Grinders", 250);

local hair_tab = library:add_section("Hairdressers");
local ice_cream_tab = library:add_section("Ben's Ice Cream");
local supermarket_cashier_tab = library:add_section("Supermarket Cashier");

hair_tab:add_toggle("Autofarm", "hair_farm", function(state)
    hairdressers:toggle_farming(state);
end);

hair_tab:add_toggle("Legit Mode", "hair_farm_legit", function() end);

ice_cream_tab:add_toggle("Autofarm", "ice_farm", function(state)
    ice_cream:toggle_farming(state);
end);

ice_cream_tab:add_toggle("Legit Mode", "ice_farm_legit", function() end);

supermarket_cashier_tab:add_toggle("Autofarm", "market_cashier_farm", function(state)
    supermarket_cashier:toggle_farming(state);
end);

supermarket_cashier_tab:add_toggle("Legit Mode", "market_cashier_farm_legit", function() end);
