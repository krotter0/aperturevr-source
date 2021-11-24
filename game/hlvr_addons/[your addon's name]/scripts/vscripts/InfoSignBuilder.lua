local panelPanoramaString = nil
local restoreListener = nil
function Activate(activationType)
	if activationType == 2 then
		if restoreListener == nil then
			restoreListener = ListenToGameEvent("player_activate", Restore, nil)
		end
	else
		local chamberNum = EntityGroup[11]:GetName():sub(14)
		local chambersTotalNum = EntityGroup[12]:GetName():sub(14)
		local overlayType = EntityGroup[13]:GetName()
		local overlayNum = 0
		if overlayType == "overlayDirty" then
			overlayNum = RandomInt(1,3)
		end
		
		local iconsString = ""
		local iconsOnString = ""
		for i = 1, 10, 1 do
			local iconType = EntityGroup[i]:GetName():sub(14)
			iconsString = iconsString .. ";"..iconType
			
			local iconState = (EntityGroup[i]:GetClassname() == "info_target" and "1" or "0")
			iconsOnString = iconsOnString .. iconState
		end
		
		panelPanoramaString = "p2_info_panel:"..chamberNum..";"..chambersTotalNum..";"..iconsOnString..""..iconsString..";"..tostring(overlayNum)
		thisEntity:SetContext("PanelData", panelPanoramaString, 0)
	end
end
function SetPanelConfig()
	SendToConsole("@panorama_dispatch_event AddStyleToEachChild(\""..(panelPanoramaString or thisEntity:GetContext("PanelData")).."\")")
	thisEntity:SetContext("PanelOn", "on", 0)
end

function Restore()
	StopListeningToGameEvent(restoreListener)
	local context = thisEntity:GetContext("PanelData")
	if context ~= nil then
		panelPanoramaString = context
		if thisEntity:GetContext("PanelOn") == "on" then
			SendToConsole("@panorama_dispatch_event AddStyleToEachChild(\""..context.."\")")
		end
	end
end