DPSMateFile("DPSMate_OptionsFuncs7b.lua")
DPSMateMark("opt:FUNCS7b")
-- Teil 7 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:Report()
	local channel = UIDropDownMenu_GetSelectedValue(DPSMate_Report_Channel)
	DPSMateOptState.SelectedChannel = channel
	local arr, cbt, ecbt = DPSMate:GetMode(DPSMate_Report.PaKey)
	local chn, index, name, value, perc = nil, nil, nil, nil, nil
	name, value, perc, b = DPSMate:GetSettingValues(arr, cbt, DPSMate_Report.PaKey, ecbt)
	if (channel == DPSMate.L["whisper"]) then
		chn = "WHISPER"; index = DPSMate_Report_Editbox:GetText();
	elseif DPSMate:TContains(DPSMate.L["gchannel"], channel) then
		chn = strupper(channel)
	else
		chn = "CHANNEL"; index = GetChannelName(channel)
	end
	DPSMate_SendChat(DPSMate.L["name"].." - "..DPSMate.L["reportfor"]..DPSMate:GetModeName(DPSMate_Report.PaKey or 1).." - ".._G("DPSMate_"..DPSMateSettings["windows"][DPSMate_Report.PaKey or 1]["name"].."_Head_Font"):GetText().." - "..b[1]..b[2], chn, nil, index)
	for i=1, DPSMate_Report_Lines:GetValue() do
		if (not value[i] or value[i] == 0) then break end
		DPSMate_SendChat(i..". "..name[i].." -"..value[i], chn, nil, index)
	end
	DPSMate_Report:Hide()
end

local AbilityModes = {"damage", "dps", "healing", "hps", "OHPS", "overhealing", "effectivehealing", "effectivehps", "deaths", "interrupts", "dispels", "decurses", "curedisease", "curepoison", "liftmagic", "aurasgained", "auraslost", "aurasuptime", "procs", "casts", "ccbreaker"}
