DPSMateFile("DPSMate_OptionsFuncs3b.lua")
DPSMateMark("opt:FUNCS3b")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:ActivateTestMode()
	if self.TestMode then
		self.TestMode = false
		if DPSMate_ClearTestFight then DPSMate_ClearTestFight() end
		DPSMate:SetStatusBarValue()
	else
		self.TestMode = true
		if DPSMate_SeedTestFight then DPSMate_SeedTestFight() end
	end
end

function DPSMate.Options:ToggleFilterClass(key, class)
	if DPSMateSettings["windows"][key]["filterclasses"][class] then
		DPSMateSettings["windows"][key]["filterclasses"][class] = false
	else
		DPSMateSettings["windows"][key]["filterclasses"][class] = true
	end
	DPSMate:SetStatusBarValue()
end

function DPSMate.Options:SimpleToggle(key, opt)
	if DPSMateSettings["windows"][key][opt] then
		DPSMateSettings["windows"][key][opt] = false
	else
		DPSMateSettings["windows"][key][opt] = true
	end
	DPSMate:SetStatusBarValue()
end

