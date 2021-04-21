-- Stores the UI Instance
KillHUDUI = nil

-- Creates a WebUI for the Inventory when the package loads
Package:Subscribe("Load", function()
    KillHUDUI = WebUI("KillHUD", "file:///UI/index.html")
end)

-- Destroys the WebUI when the package unloads
Package:Subscribe("Unload", function()
    KillHUDUI:Destroy()
end)

-- When a character takes damage, checks if I was the causer and displays it on the screen
Character:Subscribe("TakeDamage", function(charact, damage, bone, type, from, instigator)
    -- If I was not the causer, just ignore it
    if (instigator ~= NanosWorld:GetLocalPlayer()) then return end

	Client:SendChatMessage("Hit: " .. bone)

	Sound(Vector(0, 0, 0), "NanosWorld::A_Hit_Feedback", true)

	if (bone == "head" or last_bone_damaged == "neck_01") then
		Sound(Vector(0, 0, 0), "NanosWorld::A_Headshot_Feedback", true)
	end

    KillHUDUI:CallEvent("AddScore", {damage, "enemy_hit", "ENEMY HIT", true})
end)

-- When a character dies, check if I was the last one to do damage on him and displays on the screen as a kill
Character:Subscribe("Death", function(charact, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator)
    if (instigator ~= NanosWorld:GetLocalPlayer()) then return end

    local player = charact:GetPlayer()

    local name = "BOT"

    -- Attempts to get the player's name (if possessed by one)
    if (player) then
        name = player:GetName()
    end

    -- Gets the lat hit bone and check if it was a Headshot
    local is_headshot = last_bone_damaged == "head" or last_bone_damaged == "neck_01"

	Sound(Vector(0, 0, 0), "NanosWorld::A_Kill_Feedback", true)

	if (is_headshot) then
		Sound(Vector(0, 0, 0), "NanosWorld::A_Headshot_Feedback", true)
	end

    KillHUDUI:CallEvent("AddKill", {name, is_headshot})
end)


Client:Subscribe("Tick", function(delta_time)
    -- Gets the middle of the screen
    local viewport_2D_center = Render:GetViewportSize() / 2

    -- Deprojects to get the 3D Location for the middle of the screen
    local viewport_3D = Render:Deproject(viewport_2D_center)

    -- Makes a trace with the 3D Location and it's direction multiplied by 5000
    -- Meaning it will trace 5000 units in that direction
    local trace_max_distance = 5000

    local start_location = viewport_3D.Position
    local end_location = viewport_3D.Position + viewport_3D.Direction * trace_max_distance

    -- Last parameter as true means it will draw a Debug Line in the traced segment
    local trace_result = Client:Trace(start_location, end_location, CollisionChannel.WorldStatic, true, true, true, true)

    -- If hit something draws a Debug Point at the location
    if (trace_result.Success) then

        -- Makes the point Red or Green if hit an Actor
        local color = Color(1, 0, 0) -- Red

        Package:Log(trace_result.SurfaceType)
        Package:Log(trace_result.ActorName)
        Package:Log(trace_result.ComponentName)
        if (trace_result.Entity) then
            color = Color(0, 1, 0) -- Green
            
            -- Here you can check which actor you hit like
            -- if (trace_result.Actor:GetType() == "Character") then ...
            -- Currently only Character, Vehicles and Props are returned, if you want more you can request and we will add
        end

        -- Draws a Debug Point at the Hit location for 3 seconds with tickness 1
        Client:DrawDebugPoint(trace_result.Location, color, 3, 1)
    end
end)