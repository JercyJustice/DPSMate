DPSMateFile("DPSMate_OptionsFuncs3d.lua")
DPSMateMark("opt:FUNCS3d")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:IsInBattleground()
	for i=1, 4 do
		local status, mapName, instanceID, lowestlevel, highestlevel, teamSize, registeredMatch = GetBattlefieldStatus(i)
		if status == "active" and DPSMateSettings["hideinpvp"] then
			return true
		end
	end
	return false
end

function DPSMate.Options:HideInPvP()
	for _, val in pairs(DPSMateSettings["windows"]) do
		local frame = _G("DPSMate_"..val["name"])
		if frame and DPSMate.Options:IsInBattleground() then
			frame:Hide()
			if DPSMateSettings["disablewhilehidden"] then
				DPSMate:Disable()
			end
		end
	end
	DPSMate.Options:HideWhenSolo()
end

function DPSMate.Options:HideWhenSolo()
	for _, val in pairs(DPSMateSettings["windows"]) do
		local frame = _G("DPSMate_"..val["name"])
		if frame and DPSMateSettings["hidewhensolo"] and not DPSMate.Options:IsInBattleground() then
			if GetNumPartyMembers() == 0 then
				frame:Hide()
				if DPSMateSettings["disablewhilehidden"] then
					DPSMate:Disable()
				end
			else
				if not val["hidden"] then
					frame:Show()
				end
				DPSMate:Enable()
			end
		end
	end
end

function DPSMate.Options:IsInParty()
	DPSMateOptState.LastPartyNum = DPSMateOptState.PartyNum
	if UnitInRaid("player") then
		DPSMateOptState.PartyNum = GetNumRaidMembers()
		return true
	elseif GetNumPartyMembers() > 0 then
		DPSMateOptState.PartyNum = GetNumPartyMembers()
		return true
	else
		DPSMateOptState.PartyNum = 0
		return false
	end
end


