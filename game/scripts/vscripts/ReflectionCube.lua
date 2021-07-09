local laserInputs = 0
local ptfx = nil
local state = false

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
	if thisEntity:GetContext("LaserInput") == "on" then
		state = true
		CreatePtfx()
	end
end

function AddLaserInput()
	laserInputs = laserInputs + 1
	SetLaserPtfx(true)
end

function RemoveLaserInput()
	laserInputs = laserInputs - 1
	SetLaserPtfx(laserInputs > 0)
end

function CreatePtfx()
	ptfx = ParticleManager:CreateParticle("particles/portal_refl_cube_redirectlight.vpcf", 1, thisEntity)
end

function SetLaserPtfx(s)
	if s == state then return end
	state = s
	if s then
		thisEntity:SetContext("LaserInput", "on", 0)
		
		CreatePtfx()
	else
		thisEntity:SetContext("LaserInput", "off", 0)
		
		ParticleManager:DestroyParticle(ptfx, false)
		ParticleManager:ReleaseParticleIndex(ptfx)
		ptfx = nil
	end
end