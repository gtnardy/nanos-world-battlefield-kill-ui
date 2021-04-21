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
