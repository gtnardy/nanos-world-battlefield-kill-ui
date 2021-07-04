-- Spawns the UI Instance
KillHUDUI = WebUI("KillHUD", "file:///UI/index.html")

KillHUDUIConfiguration = {
	enable_autoscore = true,
	kill_score = 20,
	headshot_score = 20,
	current_damage_id = 1,
}

-- List of spawned HitMarks
HitMarks = {}

-- Helper for adding a Kill to the screen (skull)
function AddKill(name, is_headshot, score)
	KillHUDUI.CallEvent("AddKill", name, is_headshot, score)
end

Events.Subscribe("AddKill", AddKill)

-- Helper for adding score to the screen
function AddScore(score, id, label, use_current)
	KillHUDUI.CallEvent("AddScore", score, id, label, use_current)
end

Events.Subscribe("AddScore", AddScore)

Character:Subscribe("TakeDamage", function(character, damage, bone, type, from, instigator)
	local local_player = NanosWorld:GetLocalPlayer()

	-- If I was damaged, play Hit Taken sound and displays a Hit Mark
	if (character:GetPlayer() == local_player) then
		Sound(Vector(), "NanosWorld::A_HitTaken_Feedback", true)
		KillHUDUIConfiguration.current_damage_id = KillHUDUIConfiguration.current_damage_id + 1

		local location = Vector()
		if (instigator) then
			local character_instigator = instigator:GetControlledCharacter()

			if (character_instigator) then
				location = character_instigator:GetLocation()
			end
		end

		table.insert(HitMarks, { id = KillHUDUIConfiguration.current_damage_id, cooldown = 2000, location = location })
		return
	end

	-- If I was the causer, adds score
	if (instigator == local_player) then
		local local_character = local_player:GetControlledCharacter()

		if (local_character and local_character == character) then
			return
		end

		-- Play Hit audio feedback
		Sound(Vector(), "NanosWorld::A_Hit_Feedback", true)

		-- Headshot sound effect
		if (bone == "head" or bone == "neck_01") then
			Sound(Vector(), "NanosWorld::A_Headshot_Feedback", true)
		end

		-- If we should add score, or other package will do it
		if (KillHUDUIConfiguration.enable_autoscore) then
			AddScore(damage, "enemy_hit", "ENEMY HIT", true)
		end
	end
end)

-- When a character dies, check if I was the last one to do damage on him and displays on the screen as a kill
Character:Subscribe("Death", function(character, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator)
	local player = character:GetPlayer()

	local name = "BOT"
	local killer_name = "BOT"

	-- Attempts to get the player's name (if possessed by one)
	if (player) then
		name = player:GetName()
	end

	if (instigator) then
		killer_name = instigator:GetName()
	end

	-- Gets the lat hit bone and check if it was a Headshot
	local is_headshot = last_bone_damaged == "head" or last_bone_damaged == "neck_01"
	local is_suicide = instigator == player

	KillHUDUI.CallEvent("AddKillNotification", name, killer_name, is_headshot, is_suicide)

	if (instigator ~= NanosWorld.GetLocalPlayer()) then return end

	if (NanosWorld.GetLocalPlayer():GetControlledCharacter() == character) then
		return
	end

    -- Plays a sound kill feedback
	Sound(Vector(), "NanosWorld::A_Kill_Feedback", true)

	if (is_headshot) then
		if (KillHUDUIConfiguration.enable_autoscore) then
			AddScore(KillHUDUIConfiguration.headshot_score, "headshot", "HEADSHOT", false)
		end
	end

	AddKill(name, is_headshot, KillHUDUIConfiguration.kill_score)
end)

-- Event for configuring the Kill HUD
Events.Subscribe("ConfigureBattlefieldKillUI", function(enable_autoscore, kill_score, headshot_score)
	KillHUDUIConfiguration.enable_autoscore = enable_autoscore
	KillHUDUIConfiguration.kill_score = kill_score
	KillHUDUIConfiguration.headshot_score = headshot_score
end)

-- On Tick, updates all HitMarks
Client.Subscribe("Tick", function(delta_time)
	for k, h in ipairs(HitMarks) do
		h.cooldown = h.cooldown - delta_time * 1000
		if (h.cooldown <= 0) then
			KillHUDUI.CallEvent("UpdateDamageIndicator", h.id, false)
			table.remove(HitMarks, k)
		else
			local position2D = Render.Project(h.location)
			KillHUDUI.CallEvent("UpdateDamageIndicator", h.id, true, position2D.X, position2D.Y)
		end
	end
end)