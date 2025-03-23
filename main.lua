-- utils (these are pasted from wally)
local utils = {} do
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

    function utils:dist_between(p1, p2)
        return (p1 - p2).Magnitude;
    end

    function utils:get_position()
        local player = utils:find_from("Players.LocalPlayer");
        local character = player.Character or player.CharacterAdded:Wait();
        return character.PrimaryPart.Position;
    end
end

-- variables
local player = utils:find_from("Players.LocalPlayer");
local modules = utils:wait_for("PlayerScripts.Modules", player);
local job_module = require(utils:wait_for("JobHandler", modules));
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
    local path = pathfinding_service:CreatePath({
        AgentRadius = 3,
        AgentHeight = 6,
        AgentCanClimb = true,
        AgentCanJump = true
    });

    local waypoints, next_waypoint_idx, reached_connection, blocked_connection;
    local completed = false;

    function pathfinding:walk_to(target, yield)
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

            blocked_connection = path.Blocked:Connect(function(blocked_waypoint_idx)
                if blocked_waypoint_idx >= next_waypoint_idx then
                    blocked_connection:Disconnect();
                    self:walk_to(target, yield or false);
                end
            end);

            if not reached_connection then
                reached_connection = humanoid.MoveToFinished:Connect(function(reached)
                    if reached and next_waypoint_idx < #waypoints then
                        next_waypoint_idx += 1;
                        humanoid:MoveTo(waypoints[next_waypoint_idx].Position);
                    else
                        completed = true;
                        reached_connection:Disconnect();
                        blocked_connection:Disconnect();
                    end
                end)
            end
            
            next_waypoint_idx = 2;
            humanoid:MoveTo(waypoints[next_waypoint_idx].Position);
        else
            return error(`pathfinding:walk_to | Failed to compute path from {tostring(character.PrimaryPart.Position)} to {tostring(character.PrimaryPart.Position, _type == "Vector3" and target or target.Position)}`, 0);
        end

        if yield then
            repeat task.wait() until completed
            completed = false;
        end
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
        local workstation_folder = utils:wait_for("Workspace.Environment.Locations.StylezHairStudio.HairdresserWorkstations");
        
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
        local current_position = utils:get_position();
        local workstations = self:get_workstations();
        local closest_workstation, distance = nil, math.huge;

        if workstations then
            for _, v in next, workstations do
                local workstation_distance = utils:dist_between(current_position, v.Mirror.Position);
                if distance > workstation_distance then
                    distance = workstation_distance;
                    closest_workstation = v
                end
            end
            return closest_workstation;
        end
    end

    function hairdressers:claim_workstation(workstation)
        pathfinding:walk_to(workstation.Mat.Position, true);
        
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
                            task.wait(0.1);
                        end
                        task.wait(0.1);
                        for i=1, order_idx[2] do
                            if i==1 then
                                continue;
                            end
                            getconnections(color_next_button.Activated)[1].Function();
                            task.wait(0.1);
                        end
                        task.wait(0.1);
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
end

local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/iopsec/bloxburg-grinders/main/ui.lua"))();

library:create_window("Bloxburg Grinders", 250);

local hair_tab = library:add_section("Hairdressers");

hair_tab:add_toggle("Autofarm", "hair_farm", function(state)
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
end);