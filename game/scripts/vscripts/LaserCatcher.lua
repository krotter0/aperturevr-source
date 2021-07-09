local laserInputs = 0
local state = false
local ptfx = nil
local centered = false

local rusted = false

local restoreListener = nil
function Activate(activateType)
	if activateType == 2 then
		if restoreListener == nil then
			restoreListener = ListenToGameEvent("player_activate", Restore, nil)
		end
	else
		Init()
	end
end

function Init()
	centered = thisEntity:GetModelName() == "models/props/laser_catcher_center.vmdl"
	local matGroup = thisEntity:GetMaterialGroupHash()
	rusted = matGroup == -1757006133 or matGroup == 624850687
end

function Restore()
	StopListeningToGameEvent(restoreListener)
	Init()
	if thisEntity:GetContext("LaserInput") == "on" then
		state = true
		thisEntity:EmitSound("Portal.LaserCatcher.OnLoop")
		SetPtfx()
	end
end

function SetPtfx()
	local ptfxName = centered and "particles/portal_laser_catcher_center.vpcf" or "particles/portal_laser_catcher.vpcf"
	
	ptfx = ParticleManager:CreateParticle(ptfxName, 1, thisEntity)
	ParticleManager:SetParticleControlEnt(ptfx, 0, thisEntity, 5, "particle_emitter", Vector(0,0,0), true)
end

function AddLaserInput()
	laserInputs = laserInputs + 1
	SetLaserState(true)
end

function RemoveLaserInput()
	laserInputs = laserInputs - 1
	SetLaserState(laserInputs > 0)
end

function SetLaserState(s)
	if s == state then return end
	state = s
	
	if state then
		thisEntity:SetContext("LaserInput", "on", 0)
		
		thisEntity:SetSkin(rusted and 3 or 1)
		thisEntity:EmitSound("Portal.LaserCatcher.On")
		thisEntity:EmitSound("Portal.LaserCatcher.OnLoop")
		thisEntity:StopSound("Portal.LaserCatcher.Off")
		
		SetPtfx()
		
		DoEntFireByInstanceHandle(thisEntity, "FireUser1", "", 0, thisEntity, thisEntity)
	else
		thisEntity:SetContext("LaserInput", "off", 0)
		
		thisEntity:SetSkin(rusted and 2 or 0)
		thisEntity:EmitSound("Portal.LaserCatcher.Off")
		thisEntity:StopSound("Portal.LaserCatcher.On")
		thisEntity:StopSound("Portal.LaserCatcher.OnLoop")
		ParticleManager:DestroyParticle(ptfx, false)
		ParticleManager:ReleaseParticleIndex(ptfx)
		ptfx = nil
		
		DoEntFireByInstanceHandle(thisEntity, "FireUser2", "", 0, thisEntity, thisEntity)
	end
end