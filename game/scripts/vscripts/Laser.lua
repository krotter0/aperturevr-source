--[[
CONTENTS_EMPTY = 0
CONTENTS_SOLID = 0x1
CONTENTS_WINDOW = 0x2
CONTENTS_AUX = 0x4
CONTENTS_GRATE = 0x8
CONTENTS_SLIME = 0x10
CONTENTS_WATER = 0x20
CONTENTS_BLOCKLOS = 0x40
CONTENTS_OPAQUE = 0x80
CONTENTS_TESTFOGVOLUME = 0x100
CONTENTS_UNUSED = 0x200
CONTENTS_UNUSED6 = 0x400
CONTENTS_TEAM1 = 0x800
CONTENTS_TEAM2 = 0x1000
CONTENTS_IGNORE_NODRAW_OPAQUE = 0x2000
CONTENTS_MOVEABLE = 0x4000
CONTENTS_AREAPORTAL = 0x8000
CONTENTS_PLAYERCLIP = 0x10000
CONTENTS_MONSTERCLIP = 0x20000
CONTENTS_CURRENT_0 = 0x40000
CONTENTS_CURRENT_90 = 0x80000
CONTENTS_CURRENT_180 = 0x100000
CONTENTS_CURRENT_270 = 0x200000
CONTENTS_CURRENT_UP = 0x400000
CONTENTS_CURRENT_DOWN = 0x800000
CONTENTS_ORIGIN = 0x1000000
CONTENTS_MONSTER = 0x2000000
CONTENTS_DEBRIS = 0x4000000
CONTENTS_DETAIL = 0x8000000
CONTENTS_TRANSLUCENT = 0x10000000
CONTENTS_LADDER = 0x20000000
CONTENTS_HITBOX = 0x40000000
]]--

laserTraceMask = 0x1 + 0x4000 + 0x80 + 0x2000000 --MASK_OPAQUE_AND_NPCS
ptfxTypes = {
	--[0] = "particles/portal_laser.vpcf";
	--[1] = "particles/portal_laser_redirected.vpcf";
	--[2] = "particles/portal_laser_redirected_traced.vpcf";
	
	[0] = "particles/portal_laser_new_hit.vpcf";
	[1] = "particles/portal_laser_new_reflhit.vpcf";
	[2] = "particles/portal_laser_new_nohit.vpcf"; --parented
}
laserReactables = {
	{
		condition = function (ent, model, class, laserhitpos)
			return class == "prop_physics" and (model == "models/props/reflection_cube.vmdl" or model == "models/props/reflection_cube_rusted.vmdl")
		end;
		getRedirectionInfo = function(self, ent, laserForward, laserImpact)
			return ent:GetOrigin(), ent:GetForwardVector()
		end;
		redirectLaser = function(self, laserindex, ent, laserForward, laserImpact, ignoredEnts, doDamage)
			local origin, forward = self:getRedirectionInfo(ent, laserForward, laserImpact)
			return TraceLaser(laserindex + 1, ent:GetOrigin(), ent:GetForwardVector(), ent, ignoredEnts, nil, ent, doDamage)
		end;
		hasLaserInput = true;
		fxtype = 2;
	};
	{
		condition = function (ent, model, class, laserhitpos)
			return class == "prop_dynamic" and model == "models/props/reflective_panel.vmdl"
		end;
		getRedirectionInfo = function(self, ent, laserForward, laserImpact)
			local reflectionDirection = ent:GetForwardVector()
			local reflectedForward = laserForward - (2 * (laserForward:Dot(reflectionDirection)) * reflectionDirection)
			return laserImpact, reflectedForward
		end;
		redirectLaser = function(self, laserindex, ent, laserForward, laserImpact, ignoredEnts, doDamage)
			local origin, forward = self:getRedirectionInfo(ent, laserForward, laserImpact)
			return TraceLaser(laserindex + 1, origin, forward, ent, ignoredEnts, nil, nil, doDamage)
		end;
		dontIgnoreAfterRedirection = true;
		hasLaserInput = false;
		fxtype = 1;
	};
	{
		condition = function (ent, model, class, laserhitpos)
			if class == "prop_dynamic" then
				local targetpos
				local targetdist
				if model == "models/props/laser_catcher.vmdl" then
					targetpos = ent:GetOrigin() + ent:GetForwardVector() * 14 - ent:GetUpVector() * 14
					targetdist = 14
				elseif model == "models/props/laser_catcher_center.vmdl" then
					targetpos = ent:GetOrigin() + ent:GetForwardVector() * 14
					targetdist = 26
				else
					return false
				end
				
				return (laserhitpos - targetpos):Length() < targetdist
			end
			
			return false
		end;
		hasLaserInput = true;
		fxtype = 2;
	};
	{
		condition = function (ent, model, class)
			return class == "npc_turret_floor"
		end;
		hasLaserInput = true;
		fxtype = 0;
	};
	{
		condition = function (ent, model, class)
			return class == "prop_physics" and model == "models/combine_turrets/floor_turret_dead.vmdl"
		end;
		hasLaserInput = true;
		fxtype = 0;
	};
}

local laserPtfxs = {}
local entityInputs = {}

local relays = {}

local restoreListener = nil

function Activate(activateType)
	if activateType == 2 then
		if restoreListener == nil then
			restoreListener = ListenToGameEvent("player_activate", Restore, nil)
		end
	else
		UpdateRelays()
	end
	
end

function Restore()
	StopListeningToGameEvent(restoreListener)
	UpdateRelays()
	if thisEntity:GetContext("LaserOn") == "on" then
		thisEntity:SetThink("LaserThinkFunc", "LaserThink", 0.15)
	end
end

function UpdateRelays()
	for k,v in pairs(Entities:FindAllByName("laser_relay_point")) do
		table.insert(relays, {
			pos = (v:GetUpVector() * 19) + v:GetOrigin();
			ent = v;
		})
	end
end

function EnableLaser()
	thisEntity:EmitSound("Portal.LaserEmitter.On")
	thisEntity:StopSound("Portal.LaserEmitter.Off")
	
	LaserThinkFunc()
	thisEntity:SetThink("LaserThinkFunc", "LaserThink", 0.15)
	thisEntity:SetContext("LaserOn", "on", 0)
end

function DisableLaser()
	thisEntity:EmitSound("Portal.LaserEmitter.Off")
	thisEntity:StopSound("Portal.LaserEmitter.On")
	
	thisEntity:StopThink("LaserThink")
	
	ClearEntityInputs()
	RemoveLaserPtfxs()
	thisEntity:SetContext("LaserOn", "off", 0)
end

function ClearEntityInputs()
	for k, v in pairs(entityInputs) do
		RemoveLaserInputEntity(k)
	end
	entityInputs = {}
end
function RemoveLaserPtfxs()
	for k, v in pairs(laserPtfxs) do
		ParticleManager:DestroyParticle(v.ptfx, false)
		ParticleManager:ReleaseParticleIndex(v.ptfx)
		laserPtfxs[k] = nil
	end
	laserPtfxs = {}
end
function SetLaserPtfxContext()
	local contextString = ""
	for k, v in pairs(laserPtfxs) do
		contextString = contextString..tostring(v.ptfx).."a"
	end
	if contextString ~= "" then
		contextString = contextString:sub(0,-2)
	end
	thisEntity:SetContext("LaserPtfxs", contextString, 0)
end

local laserThinkTickCounter = 0
function LaserThinkFunc()
	--[[if laserThinkTickCounter % 7 == 0 then
		local lastUsedIndex, newInputs = TraceLaser(1, thisEntity:GetOrigin(), thisEntity:GetForwardVector(), nil, {})
		for k, v in pairs(laserPtfxs) do
			if k > lastUsedIndex and v ~= nil then
				ParticleManager:DestroyParticle(v.ptfx, false)
				laserPtfxs[k] = nil
			end
		end
		
		for k, v in pairs(entityInputs) do
			if not newInputs[k] and not k:IsNull() then
				RemoveLaserInputEntity(k)
			end
		end
		for k, v in pairs(newInputs) do
			if not entityInputs[k] and not k:IsNull() then
				AddLaserInputEntity(k)
			end
		end
		entityInputs = newInputs
		laserThinkTickCounter = 1
	else
		laserThinkTickCounter = laserThinkTickCounter + 1
		
		for k, v in pairs(laserPtfxs) do
			UpdateLaserPtfx(k)
		end
	end
	
	return 0.015]]--

	local doDamage = false
	laserThinkTickCounter = laserThinkTickCounter + 1
	if laserThinkTickCounter == 25 then
		doDamage = true
		laserThinkTickCounter = 0
	end
	
	local lastUsedIndex, newInputs = TraceLaser(1, thisEntity:GetOrigin(), thisEntity:GetForwardVector(), nil, {}, nil, nil, doDamage)
	for k, v in pairs(laserPtfxs) do
		if k > lastUsedIndex and v ~= nil then
			ParticleManager:DestroyParticle(v.ptfx, false)
			ParticleManager:ReleaseParticleIndex(v.ptfx)
			laserPtfxs[k] = nil
		end
	end
	
	for k, v in pairs(entityInputs) do
		if not newInputs[k] and not k:IsNull() then
			RemoveLaserInputEntity(k)
		end
	end
	for k, v in pairs(newInputs) do
		if not entityInputs[k] and not k:IsNull() then
			AddLaserInputEntity(k)
		end
	end
	entityInputs = newInputs
	SetLaserPtfxContext()
	return 0.015
end

function LaserTraceLine(traceOrigin, forward, selfEnt)
	local traceTable =
	{
		startpos = traceOrigin;
		endpos = traceOrigin + forward * 2048;
		ignore = selfEnt;
		mask =  laserTraceMask;
	}

	TraceLine(traceTable)
	return traceTable
end

function TraceLaser(index, origin, forwarddir, selfEnt, ignoredEnts, laserStart, laserEmitterEnt, doDamage)
	if laserStart == nil then
		laserStart = origin
	end
	--[[if laserEmitterEnt == nil then
		laserEmitterEnt = selfEnt
	end]]
	
	local traceTable = LaserTraceLine(origin, forwarddir, selfEnt)
	
	local returnval = index
	local returntable = {}
	local endPos = traceTable.endpos
	--DebugDrawSphere(endPos, Vector(0,0,255), 255, 8, false, 0.333)
	
	local endtarget = nil
	local endentity = nil
	local endtraced = true
	local fxtype = 0
	local normal = forwarddir * -1
	
	if traceTable.hit then
		normal = traceTable.normal
		endPos = traceTable.pos
		--DebugDrawLine(origin, traceTable.pos, 255, 0, 0, false, 0.15)
		local ent = traceTable.enthit
		if ent ~= nil then
			local model = ent:GetModelName()
			local class = ent:GetClassname()
			
			local reactableInfo = nil
			for k,v in pairs(laserReactables) do
				if v.condition(ent,model,class,endPos) then
					reactableInfo = v
					break
				end
			end
			
			if reactableInfo == nil then
				if doDamage and (ent:IsNPC() or ent:IsPlayer()) then
					ent:TakeDamage(CreateDamageInfo(thisEntity, thisEntity, Vector(0,0,0), traceTable.pos, 7, 0))
				end
			else
				if reactableInfo.redirectLaser then
					if not ignoredEnts[ent] or reactableInfo.dontIgnoreAfterRedirection then
						ignoredEnts[ent] = true
						returnval, returntable = reactableInfo:redirectLaser(index, ent, forwarddir, endPos, ignoredEnts, doDamage)
					end
				end
				
				if reactableInfo.hasLaserInput then
					returntable[ent] = true
				end
				fxtype = reactableInfo.fxtype
			end
		end
	end
	for k, v in pairs(relays) do
		if not returntable[v.ent] then
			--DebugDrawSphere(v.pos, Vector(255,255,0), 255, 14, false, 0.015 * 3)
			if (v.pos - LineClosestPointToPoint(origin, endPos, v.pos)):Length() < 14 then
				returntable[v.ent] = true
			end
		end
	end
	SetLaserPtfx(index, laserStart, tracepos, forwarddir, laserEmitterEnt, endPos, normal, fxtype)
	return returnval, returntable
end

function AddLaserInputEntity(ent)
	if entityInputs[ent] then return end
	--entityInputs[ent] = true
	if ent ~= nil then
		ent:GetOrCreatePrivateScriptScope():AddLaserInput()
	end
end

function RemoveLaserInputEntity(ent)
	if not entityInputs[ent] then return end
	--entityInputs[ent] = false
	if ent ~= nil then
		ent:GetOrCreatePrivateScriptScope():RemoveLaserInput()
	end
end

function UpdateLaserPtfx(index)
	local data = laserPtfxs[index]
	
	local traceTable
	if data.parent then
		data.pos = data.parent:GetOrigin()
		data.forward = data.parent:GetForwardVector()
	end
	traceTable = LaserTraceLine(data.pos, data.forward, data.parent)
	
	
	if traceTable.hit then
		data.endpos = traceTable.pos
		data.normal = traceTable.normal
	else
		data.endpos = traceTable.endpos
		data.normal = data.forward * -1
	end
	laserPtfxs[index] = data
	--local newForward = (traceTable.endpos - traceTable.startpos):Normalized()
	
	--DebugDrawLine(data.pos, data.endpos, 255, 0, 0, false, 0.03)
	--DebugDrawSphere(data.pos, Vector(255,0,0), 255, 8, false, 0.03)
	--DebugDrawSphere(data.endpos, Vector(255,255,0), 255, 8, false, 0.03)
	SetLaserPtfxControlPoints(data)
	
	--DebugDrawSphere(LineClosestPointToPoint(data.pos, data.endpos, Entities:GetLocalPlayer():GetOrigin()), Vector(0,0,255), 255, 16, false, 0.03)
	
end

function SetLaserPtfxControlPoints(ptfxData)
	if ptfxData.parent then
		ParticleManager:SetParticleControlEnt(ptfxData.ptfx, 1, ptfxData.parent, 1, nil, Vector(0,0,0), true)
	else
		ParticleManager:SetParticleControl(ptfxData.ptfx, 1, ptfxData.pos)
		ParticleManager:SetParticleControlForward(ptfxData.ptfx, 1, ptfxData.forward)
	end
	ParticleManager:SetParticleControl(ptfxData.ptfx, 3,  ptfxData.endpos)
	ParticleManager:SetParticleControlForward(ptfxData.ptfx, 3,  ptfxData.normal)
end

function SetLaserPtfx(index, pos, tracepos, forward, parent, endpos, normal, ptfxtype)
	local fx = laserPtfxs[index]
	local rerouted = endtarget ~= nil
	
	
	if fx == nil or fx.fxtype ~= ptfxtype or fx.parent ~= parent then
		if fx ~= nil then
			ParticleManager:DestroyParticle(fx.ptfx, false)
			ParticleManager:ReleaseParticleIndex(fx.ptfx)
		end
		
		local fxName = ptfxTypes[ptfxtype]
		fx = { 
			ptfx = ParticleManager:CreateParticle(fxName, 1, parent or Entities:GetLocalPlayer());
			fxtype = ptfxtype;
		}
	end
	fx.pos = pos
	fx.forward = forward
	fx.parent = parent
	fx.tracepos = tracepos
	fx.endpos = endpos
	fx.normal = normal
	laserPtfxs[index] = fx
	
	--DebugDrawLine(fx.pos, fx.endpos, 0, 255, 0, false, 0.03)
	--DebugDrawSphere(fx.pos, Vector(255,0,0), 255, 8, false, 0.03)
	--DebugDrawSphere(fx.endpos, Vector(255,255,0), 255, 8, false, 0.03)
	
	SetLaserPtfxControlPoints(fx)
	--DebugDrawSphere(LineClosestPointToPoint(fx.pos, fx.endpos, Entities:GetLocalPlayer():GetOrigin()), Vector(0,0,255), 255, 16, false, 0.03)
end

function LineClosestPointToPoint(linestart, lineend, point)
	local d = (lineend - linestart):Normalized()
	local point = linestart + (d * (point - linestart):Dot(d))
	
	local tV = (point - linestart) / (lineend - linestart)
	
	local t
	if tV.x == tV.x and math.floor(linestart.x * 100 + 0.5) ~= math.floor(lineend.x * 100 + 0.5) then
		t = tV.x
	elseif tV.y == tV.y and math.floor(linestart.y * 100 + 0.5) ~= math.floor(lineend.y * 100 + 0.5) then
		t = tV.y
	elseif tV.z == tV.z then
		t = tV.z
	else
		return linestart
	end
	if t > 1 then
		return lineend
	elseif t < 0 then
		return linestart
	else
		return point
	end
end