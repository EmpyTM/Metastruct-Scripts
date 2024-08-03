module("bhopbot", package.seeall)

local helpers = include("bhopbot/helpers.lua")
local utils = include("bhopbot/utils.lua")

local node_data = utils.load("bhopbot/test.txt")
node_positions = node_nata.positions or {}
node_connections = node_data.connections or {}

local SSJUMP_SPEED_MIN = 7000            -- Minimum speed for critical jumps
local STUCK_DETECTION_SECONDS = 5        -- Time in seconds between nodes to wait before entering potentially stuck mode

local bhop_mode_alt_tab_enabled = false  -- Enabled "Alt Tab mode" (will only bhop when not in focus)
local bhop_mode_head_enabled = false     -- Enabled "head mode" (wont bhop unless theres someone on the head)
local ssjump_enabled = false             -- Critical jumps
local turning_ratio = 3                  -- Sets the turning ratio (higher = snappier turns)

local current_node = 1

local is_stuck = false
local time_since = CurTime()

local function bhopbot()
    if bhop_mode_alt_tab_enabled and system.HasFocus() then
        time_since = CurTime()

        return
    end
    
    if bhop_mode_head_enabled and #helpers.get_players_sitting_on(LocalPlayer()) == 0 then 
        time_since = CurTime()

        return
    end

    -- Distance checking code and node recalculation
    local current_position = LocalPlayer():GetPos()
    local desired_position = node_positions[current_node]
    local x_y_difference = (desired_position - current_position) * Vector(1, 1, 0)
          x_y_difference = x_y_difference:Length()

    if x_y_difference < 500 then
        current_node = ( table.Random(node_connections[current_node]) )
        time_since = CurTime()
        is_stuck = false
    end
    
    is_stuck = ( CurTime() - time_since > STUCK_DETECTION_SECONDS ) and true or is_stuck
end
    
local function bhopbot_stuck()
    if bhop_mode_alt_tab_enabled and system.HasFocus() then return end
    
    local speed = ( LocalPlayer():GetVelocity() * Vector(1, 1, 0) ):Length()
    
    if is_stuck and speed < 150 then
        RunConsoleCommand("noclip")
    else
        if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP then
            RunConsoleCommand("noclip")
        end
    end
end
    
local function bhopbot_createmove(command)
    if bhop_mode_alt_tab_enabled and system.HasFocus() then return end

    local sitting_players = helpers.get_players_sitting_on(LocalPlayer())
    if bhop_mode_head_enabled and #sitting_players == 0 then return end
    
    if LocalPlayer():GetMoveType() == MOVETYPE_NOCLIP and not stuck then return end
    
    -- Shared rotation/movement code
    local current_position = LocalPlayer():GetPos()
    local desired_position = node_positions[current_node]
    
    local x_y_difference = (desired_position - current_position) * Vector(1, 1, 0)
    
    -- Rotation Code
    if stuck then
        command:SetViewAngles(LerpAngle(
            math.Clamp(FrameTime() * turning_ratio, 0, 1),
            LocalPlayer():EyeAngles(),
            (desired_position - current_position + Vector(0, 0, 64)):Angle()
        ))
    end

    if not stuck then
        local speed = (LocalPlayer():GetVelocity() * Vector(1, 1, 0)):Length()
        
        command:SetViewAngles(LerpAngle(
            math.Clamp(FrameTime() * turning_ratio, 0, 1),
            LocalPlayer():EyeAngles(),
            Angle(ssjump_enabled and speed > SSJUMP_SPEED_MIN and 89.5 or 0, x_y_difference:Angle().y, 0)
        ))
    end
    
    -- Movement Code
    local direction_offset = (LocalPlayer():EyeAngles() + Angle(0, 90, 0)):Forward():Dot(x_y_difference:GetNormalized())
    local local_velocity = LocalPlayer():WorldToLocal(LocalPlayer():GetPos() + LocalPlayer():GetVelocity())
        
    command:SetForwardMove(3000)
    command:SetSideMove(local_velocity.y * 150)

    local is_grounded = LocalPlayer():OnGround()
    local bit_func = is_grounded and "bor" or "band"
    local jump = is_grounded and IN_JUMP or bit.bnot(IN_JUMP)

    command:SetButtons(bit[bit_func](command:GetButtons(), jump))
end

local vector_up_64 = Vector(0, 0, 64)
local line_color = Color(0, 127, 255)

local function bhopbot_render_world()
    local desired_position = node_positions[current_node]
    local desired_position_height_offset = desired_position + vector_up_64

    render.DrawLine(desired_position, desired_position_height_offset, line_color, false)
end
    
local function bhopbot_render_hud()
    local speed = (LocalPlayer():GetVelocity() * Vector(1, 1, 0)):Length()

    draw.SimpleText("Current velocity: " .. speed,
    "BudgetLabel", 50, 50, color_white)
    
    draw.SimpleText("Stuck: " .. is_stuck,
    "BudgetLabel", 50, 70, color_white)
    
    draw.SimpleText("Time: " .. CurTime() - time_since,
    "BudgetLabel", 50, 90, color_white)
    
    draw.SimpleText("Head Mode: " .. bhop_mode_head_enabled,
    "BudgetLabel", 50, 110, color_white)

    draw.SimpleText("Alt-Tab Mode: " .. bhop_mode_alt_tab_enabled,
    "BudgetLabel", 50, 130, color_white)
end

function start_bhop_script()
    hook.Add("CreateMove", "bhopbot_createmove", bhopbot_createmove)
    hook.Add("PostDrawHUD", "bhopbot_render_hud", bhopbot_render_hud)
    hook.Add("PostDrawTranslucentRenderables", "bhopbot_render_world", bhopbot_render_world)
    hook.Add("Think", "bhopbot", bhopbot)

    timer.Create("bhopbot_stuck", 1, 0, bhopbot_stuck)
end

function stop_bhop_script()
    hook.Remove("CreateMove", "bhopbot_createmove")
    hook.Remove("PostDrawHUD", "bhopbot_render_hud")
    hook.Remove("PostDrawTranslucentRenderables", "bhopbot_render_world")
    hook.Remove("Think", "bhopbot")

    timer.Remove("bhopbot_stuck")
end

--[[ Command Parser ]]--

local allowed_users = {
    ["76561198051876445"] = true, --Empy
    ["76561198282073095"] = true, --Mavain
    ["76561198890518777"] = true, --Kotorin (Mavain alt)
}

commands = {}
commands.list = {}

function commands.add_command(name, callback, argtypes)
    commands.list[name] = {
        callback = callback,
        argtypes = argtypes or {}
    }
end

commands.add_command("start", function()
    start_bhop_script()
end)

commands.add_command("stop", function()
    stop_bhop_script()
end)

commands.add_command("reload", function()
    node_data = utils.load("bhopbot/text.txt")
    
    node_positions = node_data.node_positions
    node_connections = node_data.node_connections
    current_node = 1
end)

commands.add_command("head", function(state)
    bhop_mode_head_enabled = state
end, {"boolean"})

commands.add_command("alttab", function(state)
    bhop_mode_alt_tab_enabled = state
end, {"boolean"})

commands.add_command("turningratio", function(desired_ratio)
    turning_ratio = (desired_ratio == 0) and 20 or desired_ratio
end, {"number"})

commands.add_command("allow", function(ply)
    if not IsValid(ply) then return end

    allowed_users[ply:SteamID64()] = true
end, {"Player"})

commands.add_command("deny", function(ply)
    if not IsValid(ply) then return end

    allowed_users[ply:SteamID64()] = nil
end, {"Player"})

commands.add_command("isadded", function(ply)
    local name = ply:Name()
    local steamid64 = ply:SteamID64()
    chat.AddText(name, ": " .. allowed_users[steamid64])
end, "Player")

hook.Add("OnPlayerChat", "bhopbot_commands", function(ply, text)
    if not allowed_users[ply:SteamID64()] then return end
    
    local command_parts = {}
    for part in text:gmatch("([^%s]+)") do
        table.insert(command_parts, part)
    end

    if command_parts[1] ~= "@bhopbot" then return end

    if not commands.list[command_parts[2]] then
        chat.AddText("Invalid command.")

        return
    end

    local expected_arguments = commands.list[command_parts[2]].argtypes
    if #command_parts - 2 >= #expected_arguments then
        chat.AddText("Not enough arguments.")
        
        return
    end

    local passed_arguments = {}
    
    for i = 1, #expected_arguments do
        if expected_arguments[i] == "boolean" then
            table.insert(passed_arguments, tobool(command_parts[i + 2]))
        end
        if expected_arguments[i] == "number" then
            table.insert(passed_arguments, tonumber(command_parts[i + 2]))
        end
        if expected_arguments[i] == "Player" then
            table.insert(passed_arguments, helpers.find_player_by_name(command_parts[i + 2]))
        end
    end
    
    commands.list[command_parts[2]].callback(unpack(passed_arguments))
end)
