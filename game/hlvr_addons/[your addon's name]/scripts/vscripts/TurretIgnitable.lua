local wasIgnited = false
local ptfxBurn = nil
local explosionEntity = nil

local restoreListener = nil
function ActivateTurretIgnitable(self, activationType)
	if activationType == 2 then
		if restoreListener == nil then
			restoreListener = ListenToGameEvent("player_activate", Restore, nil)
		end
	end
	if thisEntity:GetClassname() == "npc_turret_floor" then
		thisEntity:GetPrivateScriptScope():ActivateTurret(activationType)
	end
end

function Restore()
	StopListeningToGameEvent(restoreListener)
	if thisEntity:GetContext("LaserOn") == "on" then
		Remove()
	end
end

function Ignite()
	if wasIgnited then return end
	thisEntity:SetContext("LaserOn", "on", 0)
	
	ptfxBurn = ParticleManager:CreateParticle("particles/fire_01/env_fire_large.vpcf", 1, thisEntity)
	wasIgnited = true
	
	--DoEntFireByInstanceHandle(thisEntity, "Disable", "", 0, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "DepleteAmmo", "", 0, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "FireUser3", "", 0, thisEntity, thisEntity)
	
	thisEntity:EmitSound("Turret.Speak.OnFire")
	
	thisEntity:SetThink("Explode", "ExplodeThink", 1.5)
	thisEntity:StopThink("SpeakThink")
	
	SpawnEntityFromTableAsynchronous("env_explosion", {
		explosion_custom_effect = "particles/creatures/manhack/manhack_death.vpcf";
		explosion_custom_sound = "NPC_Manhack.Die_Explode";
	}, function(ent)
		explosionEntity = ent
		ent:SetParent(thisEntity, "explosion")
		ent:SetLocalOrigin(Vector(0,0,0))
	end, self)
end

function Explode()
	DoEntFireByInstanceHandle(explosionEntity, "Explode", "", 0, thisEntity, thisEntity)
	Remove()
end

function Remove()
	UTIL_Remove(thisEntity)
end

function AddLaserInput()
	Ignite()
end

function RemoveLaserInput()
end