DPSMateFile("DPSMate_OptionsFuncs7c.lua")
DPSMateMark("opt:FUNCS7c")
-- Teil 7 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:ReportUserDetails(obj, channel, name)
	local Key, user = obj:GetParent():GetParent():GetParent().Key, obj.user
	local _, cbt, ecbt = DPSMate:GetMode(Key)
	local a,b,c
	if DPSMateSettings["windows"][Key]["CurMode"] == "deaths" then
		a,b,c = DPSMate.RegistredModules[DPSMateSettings["windows"][Key]["CurMode"]]:EvalTable(DPSMateUser[user], Key)
	else
		a,b,c = DPSMate.RegistredModules[DPSMateSettings["windows"][Key]["CurMode"]]:EvalTable(DPSMateUser[user], Key, cbt, ecbt)
	end
	local chn, index
	if (channel == DPSMate.L["whisper"]) then
		chn = "WHISPER"; index = name;
	elseif DPSMate:TContains(DPSMate.L["gchannel"], channel) then
		chn = strupper(channel)
	else
		chn = "CHANNEL"; index = GetChannelName(channel)
	end
	local bb = ""
	if not b and not a then
		return
	end
	if b~=0 then
		bb = " - "..strformat("%.2f", b)
	end
	DPSMate_SendChat(DPSMate.L["name"].." - "..DPSMate.L["reportof"].." "..user.."'s ".._G("DPSMate_"..DPSMateSettings["windows"][Key]["name"].."_Head_Font"):GetText().." - "..DPSMate:GetModeName(Key)..bb, chn, nil, index)
	for i=1, 10 do
		if (not a[i]) then break end
		local p
		if type(c[i])=="table" then p = strformat("%.2f", c[i][1]).." ("..strformat("%.2f", 100*c[i][1]/b).."%)" else p = strformat("%.2f", c[i]).." ("..strformat("%.2f", 100*c[i]/b).."%)" end
		if DPSMateSettings["windows"][Key]["CurMode"] == "deaths" then
			local type = " (HIT)"
			if c[i][3]==1 then type=" (CRIT)" elseif c[i][3]==2 then type=" (CRUSH)" end
			if c[i][2]==1 then
				DPSMate_SendChat(i..". |cFF8cff80"..DPSMate:GetAbilityById(a[i]).." => ".."+"..c[i][1]..type.."|r", chn, nil, index)
			else
				DPSMate_SendChat(i..". |cFFFF8080"..DPSMate:GetAbilityById(a[i]).." => ".."-"..c[i][1]..type.."|r", chn, nil, index)
			end
		else
			if DPSMateSettings["windows"][Key]["CurMode"] == "fails" then
				DPSMate_SendChat(i..". "..DPSMate.Modules.Fails:Type(a[i]).." - "..p, chn, nil, index)
			else
				if DPSMate:TContains(AbilityModes, DPSMateSettings["windows"][Key]["CurMode"]) then
					DPSMate_SendChat(i..". "..DPSMate:GetAbilityById(a[i]).." - "..p, chn, nil, index)
				else
					DPSMate_SendChat(i..". "..DPSMate:GetUserById(a[i]).." - "..p, chn, nil, index)
				end
			end
		end
	end
end

local hexClassColor = {
	warrior = "C79C6E",
	rogue = "FFF569",
	priest = "FFFFFF",
	druid = "FF7D0A",
	warlock = "9482C9",
	mage = "69CCF0",
	hunter = "ABD473",
	paladin = "F58CBA",
	shaman = "0070DE",
}

local CompareExcept = {
	[DPSMate.L["enemydamagedone"]] = true,
	[DPSMate.L["enemydamagetaken"]] = true
}
