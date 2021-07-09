local laserInputs = 0
local ptfx = nil

function IsOn()
	return thisEntity:GetContext("LaserInput") == "on"
end

local restoreListener = nil
function Activate(activateType)
	if activateType == 2 then
		if restoreListener == nil then
			restoreListener = ListenToGameEvent("player_activate", Restore, nil)
		end
	end
end

function Restore()
	StopListeningToGameEvent(restoreListener)
	if IsOn() then
		SetPtfx()
		thisEntity:EmitSound("Portal.LaserCatcher.OnLoop")
	end
end

function AddLaserInput()
	laserInputs = laserInputs + 1
	SetLaserState(true)
end

function RemoveLaserInput()
	laserInputs = laserInputs - 1
	SetLaserState(laserInputs > 0)
end

function SetPtfx()
	ptfx = ParticleManager:CreateParticle("particles/portal_laser_catcher.vpcf", 1, thisEntity)
	ParticleManager:SetParticleControlEnt(ptfx, 0, thisEntity, 5, "particle_emitter", Vector(0,0,0), true)
end

function SetLaserState(s)
	if s == (IsOn()) then return end
	
	if s then
		thisEntity:SetContext("LaserInput", "on", 0)
		
		--thisEntity:SetGraphParameterBool("spin", true)
		thisEntity:SetSequence("spin")
		SetPtfx()
		
		thisEntity:EmitSound("Portal.LaserCatcher.On")
		thisEntity:EmitSound("Portal.LaserCatcher.OnLoop")
		thisEntity:StopSound("Portal.LaserCatcher.Off")
		
		DoEntFireByInstanceHandle(thisEntity, "FireUser1", "", 0, thisEntity, thisEntity)
	else
		thisEntity:SetContext("LaserInput", "off", 0)
		
		--thisEntity:SetGraphParameterBool("spin", false)
		thisEntity:SetSequence("idle")
		if ptfx ~= nil then
			ParticleManager:DestroyParticle(ptfx, false)
			ParticleManager:ReleaseParticleIndex(ptfx)
			ptfx = nil
		end
		
		thisEntity:EmitSound("Portal.LaserCatcher.Off")
		thisEntity:StopSound("Portal.LaserCatcher.OnLoop")
		thisEntity:StopSound("Portal.LaserCatcher.On")
		
		DoEntFireByInstanceHandle(thisEntity, "FireUser2", "", 0, thisEntity, thisEntity)
	end
end