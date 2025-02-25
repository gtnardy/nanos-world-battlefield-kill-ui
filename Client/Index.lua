-- Spawns the UI Instance
KillHUDUI = WebUI("KillHUD", "file://UI/index.html")

KillHUDUIConfiguration = {
	enable_autodamagescore = true,
	kill_autoscore = 20,
	headshot_autoscore = 20,
}

-- List of spawned HitMarks
HitMarks = {}

-- Helper for adding a Kill to the screen (skull)
function AddKill(name, is_headshot, score)
	KillHUDUI:CallEvent("AddKill", name, is_headshot, score)
end

Events.Subscribe("AddKill", AddKill)

-- Helper for adding score to the screen
function AddScore(score, id, label, use_current)
	KillHUDUI:CallEvent("AddScore", score, id, label, use_current)
end

Events.Subscribe("AddScore", AddScore)

function OnCharacterDamage(character, damage, bone, type, from, instigator, causer)
	-- Skips 0 Damage
	if (damage == 0) then return end

	local local_player = Client.GetLocalPlayer()

	-- If I was damaged, play Hit Taken sound and displays a Hit Mark
	if (character:GetPlayer() == local_player) then
		Sound(Vector(), "nanos-world::A_HitTaken_Feedback", true)

		if (causer) then
			HitMarks[causer:GetID()] = {
				cooldown = 2000,
				location = causer:GetLocation(),
			}
		end

		return
	end

	-- If I was the causer, adds score
	if (instigator == local_player) then
		local local_character = local_player:GetControlledCharacter()

		if (local_character and local_character == character) then
			return
		end

		-- Play Hit audio feedback
		Sound(Vector(), "nanos-world::A_Hit_Feedback", true)

		-- Headshot sound effect
		if (bone == "head" or bone == "neck_01") then
			Sound(Vector(), "nanos-world::A_Headshot_Feedback", true)
		end

		-- If we should add score, or other package will do it
		if (KillHUDUIConfiguration.enable_autodamagescore) then
			-- Clamps the damage to Health
			local health = character:GetHealth()
			local true_damage = health < damage and health or damage

			AddScore(true_damage, "enemy_hit", "ENEMY HIT", true)
		end
	end
end

-- When a character dies, check if I was the last one to do damage on him and displays on the screen as a kill
function OnCharacterDeath(character, last_damage_taken, last_bone_damaged, damage_type_reason, hit_from_direction, instigator, causer)
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
	local is_suicide = instigator == player or damage_type_reason == DamageType.Fall or damage_type_reason == DamageType.RunOverProp
	local action = "killed"

	if (is_suicide) then
		action = "suicided"
	elseif (damage_type_reason == DamageType.Explosion) then
		action = "exploded"
	elseif (damage_type_reason == DamageType.Melee) then
		action = "slaughtered"
	elseif (damage_type_reason == DamageType.Punch) then
		action = "crumpled"
	elseif (damage_type_reason == DamageType.RunOverProp) then
		action = "prop killed"
	elseif (damage_type_reason == DamageType.RunOverVehicle) then
		action = "ran over"
	end

	KillHUDUI:CallEvent("AddKillNotification", name, killer_name, is_headshot, is_suicide, action)

	local local_player = Client.GetLocalPlayer()
	if (instigator ~= local_player) then return end

	if (local_player:GetControlledCharacter() == character) then
		return
	end

    -- Plays a sound kill feedback
	Sound(Vector(), "nanos-world::A_Kill_Feedback", true)

	if (is_headshot) then
		AddScore(KillHUDUIConfiguration.headshot_autoscore, "headshot", "HEADSHOT", false)
	end

	AddKill(name, is_headshot, KillHUDUIConfiguration.kill_autoscore)
end

-- Event for configuring the Kill HUD
Events.Subscribe("ConfigureBattlefieldKillUI", function(enable_autodamagescore, kill_autoscore, headshot_autoscore)
	KillHUDUIConfiguration.enable_autodamagescore = enable_autodamagescore
	KillHUDUIConfiguration.kill_autoscore = kill_autoscore
	KillHUDUIConfiguration.headshot_autoscore = headshot_autoscore
end)

Character.Subscribe("Death", OnCharacterDeath)
Character.Subscribe("TakeDamage", OnCharacterDamage)

CharacterSimple.Subscribe("Death", OnCharacterDeath)
CharacterSimple.Subscribe("TakeDamage", OnCharacterDamage)

-- On Tick, updates all HitMarks
Client.Subscribe("Tick", function(delta_time)
	for id, h in pairs(HitMarks) do
		h.cooldown = h.cooldown - delta_time * 1000
		if (h.cooldown <= 0) then
			KillHUDUI:CallEvent("UpdateDamageIndicator", id, false)
			HitMarks[id] = nil
		else
			local position2D = Client.ProjectWorldToScreen(h.location)
			KillHUDUI:CallEvent("UpdateDamageIndicator", id, true, position2D.X, position2D.Y)
		end
	end
end)