DPSMateFile("DPSMate_OptionsFuncs3a1.lua")
DPSMateMark("opt:FUNCS3a1")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:Logout()
	if DPSMateSettings["sync"] then
		if UnitInRaid("player") then
			DPSMate:SendMessage(DPSMate.L["syncreseterror"])
		else
			DPSMate.Options:PopUpAccept(true, true)
		end
	else
		DPSMate.Options:PopUpAccept(true, true)
	end
	--self:SumGraphData()
	DPSMate.Options.OldLogout()
end
-- Emberveil: ein Client-Global zu ersetzen kann fehlschlagen. Ungeschuetzt
-- braeche die Datei hier ab und alles danach fehlte.
local DPSMate_LogoutHook = function()
	if DPSMateSettings["dataresetslogout"] == 3 then
		DPSMate_Logout:Show() 
	elseif DPSMateSettings["dataresetslogout"] == 2 then
		DPSMate.Options.OldLogout()
	else
		DPSMate.Options:Logout()
	end
end
pcall(function() Logout = DPSMate_LogoutHook end)

-- Deprecated
