dissolveLength = 2.3
dissolveFadeoutStart = 2.15
dissolveThinkRate = 0.05

local dissolveStart = -1
local ptfx = nil

function Activate(activationType)
	if activationType == 2 then
		if thisEntity:GetContext("Dissolved") == "on" then
			UTIL_Remove(thisEntity)
			return
		end
	end
	local scope = thisEntity:GetPrivateScriptScope()
	if scope.ActivateTurretIgnitable ~= nil then
		scope:ActivateTurretIgnitable(activationType)
	end
end

function Dissolve()
	if dissolveStart >= 0 then return end
	thisEntity:SetContext("Dissolved", "on", 0)
	dissolveStart = Time()
	thisEntity:EmitSound("Portal.Dissolve")
	thisEntity:SetThink("DissolveThinkFunc", "DissolveThink", dissolveThinkRate)
	ptfx = ParticleManager:CreateParticle("particles/portal_dissolve.vpcf", 1, thisEntity)
	thisEntity:SetMass(0.03)
	
	DoEntFireByInstanceHandle(thisEntity, "DisablePickup", "", 0, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "DisableMotion", "", 0, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "DisablePhyscannonPickup", "", 0, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "EnableMotion", "", 0.03, thisEntity, thisEntity)
	DoEntFireByInstanceHandle(thisEntity, "RunScriptCode", "thisEntity:SetMass(0.03) thisEntity:ApplyAbsVelocityImpulse(Vector(0,0,100)) thisEntity:ApplyLocalAngularVelocityImpulse(Vector(700,700,700))", 0.12, thisEntity, thisEntity)
	
	if thisEntity:GetClassname() == "npc_turret_floor" then
		thisEntity:EmitSound("Turret.Speak.Dissolve")
		thisEntity:StopThink("SpeakThink")
		DoEntFireByInstanceHandle(thisEntity, "DepleteAmmo", "", 0, thisEntity, thisEntity)
		
		for k, v in pairs(thisEntity:GetChildren()) do
			local classname = v:GetClassname()
			if classname == "info_particle_system" or classname == "info_particle_target" then
				v:Kill()
			end
		end
	elseif thisEntity:GetModelName() == "models/combine_turrets/floor_turret_dead.vmdl" then
		thisEntity:EmitSound("Turret.Speak.Dissolve")
	end
end
function DissolveWithCallback()
	if dissolveStart >= 0 then return end
	Dissolve()
	DoEntFireByInstanceHandle(thisEntity, "FireUser2", "", 0, thisEntity, thisEntity)
end

function DissolveThinkFunc()
	local t = Time()
	local timeSinceDissolve = t - dissolveStart
	
	local dissolveColor = (1 - math.min(timeSinceDissolve / dissolveLength, 1)) * 255
	thisEntity:SetRenderColor(dissolveColor,dissolveColor,dissolveColor)
	
	local dissolveAlpha = (1 - (math.max(0, timeSinceDissolve - dissolveFadeoutStart) / (dissolveLength - dissolveFadeoutStart))) * 255
	thisEntity:SetRenderAlpha(dissolveAlpha)
	
	if timeSinceDissolve > dissolveLength then
		UTIL_Remove(thisEntity)
	else
		return dissolveThinkRate
	end
end