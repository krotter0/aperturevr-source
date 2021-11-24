local ptfxLaser = nil

local eyeAttachmentIndex = 0

local isTipped = false


local seePlayer = false

local skin = nil

function Spawn(spawnkeys)
	skin = spawnkeys:GetValue("SkinNumber")
end

function ActivateTurret(self, activationType)
	eyeAttachmentIndex = thisEntity:ScriptLookupAttachment("eyes")
	thisEntity:SetThink("SpeakThinkFunc", "SpeakThink", 0.4)
	if skin ~= nil then
		thisEntity:SetSkin(skin)
	end
end



function TurnToProp()
	local skin = 0
	local matgroup = thisEntity:GetMaterialGroupHash()
	if matgroup == -1757006133 then
		skin = 1
	elseif matgroup == -1211395692 then
		skin = 2
	end
	SpawnEntityFromTableAsynchronous("prop_physics", {
		vscripts = "TurretIgnitable.lua Dissolvable.lua";
		model = "models/combine_turrets/floor_turret_dead.vmdl";
		origin = thisEntity:GetOrigin();
		angles = thisEntity:GetAngles();
		skin = skin;
	}, function(ent)
		UTIL_Remove(thisEntity)
	end, thisEntity)
end


function IsPlayerInSight()
	local player = Entities:GetLocalPlayer()
	local enemyEyes = player:EyePosition()
	local midpoint = player:GetCenter()
	--DebugDrawSphere(midpoint, Vector(255,0,0), 255, 8, false, 0.5)
	--DebugDrawSphere(player:EyePosition(), Vector(255,0,0), 255, 8, false, 0.5)
	local eyepos = thisEntity:GetAttachmentOrigin(eyeAttachmentIndex)
	--local eyeforw = thisEntity:GetAttachmentForward(eyeAttachmentIndex)
	--local forw = thisEntity:GetForwardVector()
	
	
	
	local los = (enemyEyes - eyepos)
	local dist = los:Length()
	if dist > 1200 then return false end

	local angleToTarget = VectorToAngles(los)
	local flZDiff = math.abs((angleToTarget.x - thisEntity:GetAngles().x) % 360)
	if flZDiff > 180 then
		flZDiff = 360 - flZDiff
	end
	if flZDiff > 25.0 and dist > 64.0 then
		return false
	end
	
	
	if not FInViewCone(midpoint) then return false end
	
	local traceTable =
	{
		startpos = eyepos;
		endpos = enemyEyes;
		ignore = thisEntity;
		mask =  33636363
	}
	TraceLine(traceTable)
	if traceTable.hit then
		if traceTable.enthit ~= player then return false end
	end
	
	return true
end
function FInViewCone(vecSpot)
	local los = (vecSpot - thisEntity:EyePosition())
	los = Vector(los.x, los.y, 0):Normalized()

	local facingDir = AnglesToVector(thisEntity:EyeAngles())
	facingDir = Vector(facingDir.x, facingDir.y, 0):Normalized()


	local flDot = los:Dot(facingDir)

	if flDot > 0.4 then
		return true
	end

	return false
end

function SpeakThinkFunc()
	local tipped = thisEntity:GetUpVector():Dot(Vector(0,0,1)) < 0.5
	if isTipped ~= tipped then
		isTipped = tipped
		if tipped then
			thisEntity:EmitSound("Turret.Speak.Tipped")
		end
	end
	
	local sequence = thisEntity:GetSequence()
	local playerSight = not isTipped and (sequence == "deploy" or sequence == "fire" or sequence == "fire2" or IsPlayerInSight())
	if seePlayer ~= playerSight then
		seePlayer = playerSight
		if not playerSight and not isTipped then
			thisEntity:EmitSound("Turret.Speak.Lost")
		end
	end
	
	return 0.4
end