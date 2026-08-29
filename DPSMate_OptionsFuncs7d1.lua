DPSMateFile("DPSMate_OptionsFuncs7d1.lua")
DPSMateMark("opt:FUNCS7d1")
-- Teil 7 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:InializePlayerDewDrop(obj)
	local channel, i = DPSMate.L["gchannel"], 1
	local path = DPSMate.Options.Options[4]["args"]["report"]["args"]
	-- Name
	DPSMate.Options.Options[4]["args"]["player"] = {
		order = 1,
		type = "header",
		name = obj.user,
	}
	DPSMate.Options.Options[4]["args"]["details"] = {
		order = 2,
		type = "execute",
		name = DPSMate.L["opendetails"],
		desc = DPSMate.L["opendetails"],
		func = function() DPSMate.Options:UpdateDetails(obj); DPSMate.Options.Dewdrop:Close() end,
	}
	
	-- Report channel
	for i=0, 25 do
		local id, name = GetChannelName(i);
		if name then
			if not DPSMate:TContains(channel, name) then
				tinsert(channel, name)
			end
		end
	end
	
	for cat, val in channel do
		path["a"..cat] = {
			order = 10*cat+10,
			type = "execute",
			name = val,
			desc = DPSMate.L["reportdetails"],
			func = loadstring('DPSMate.Options:ReportUserDetails(DPSMate.Options.Dewdrop:GetOpenedParent(), "'..val..'"); DPSMate.Options.Dewdrop:Close()'),
		}
	end
	
	-- Compare with player
	DPSMate.Options.Options[4]["args"]["compare"]["args"] = {}
	path = DPSMate.Options.Options[4]["args"]["compare"]["args"]
	local Key = obj:GetParent():GetParent():GetParent().Key
	local db,cbt = DPSMate:GetMode(Key)
	local temp = ''
	local a = DPSMate:GetSettingValues(db, cbt, Key, 0)
	for cat, name in a do
		if name and name ~= obj.user then
			if DPSMateSettings["windows"][Key]["grouponly"] then
				if DPSMate.Parser.TargetParty[name] then
					if temp=='' then
						temp = '"'..name..'"'
					else
						temp = temp..',"'..name..'"'
					end
				end
			else
				if temp=='' then
					temp = '"'..name..'"'
				else
					temp = temp..',"'..name..'"'
				end
			end
		end
	end
	-- No clue what is wrong here. Fuck it
	temp = assert(loadstring('return {'..temp..'}')) ();
	sort(temp)
	
	local mode = _G(obj:GetParent():GetParent():GetParent():GetName().."_Head_Font"):GetText()
	for mo, ti in strgfind(mode, "(.+) %[(.+)%]") do
		mode = mo
	end
	
	for cat, val in temp do
		if cat>100 then break end
		if not strfind(val, "%s") or CompareExcept[mode] then
			path["Arg"..cat] = {
				order = 1,
				type = "execute",
				name = "|cFF"..hexClassColor[DPSMateUser[val][2] or "warrior"]..val.."|r",
				desc = DPSMate.L["opendetails"],
				func = loadstring('DPSMate.Options:UpdateDetails(nil, "'..val..'", "'..obj:GetName()..'"); DPSMate.Options.Dewdrop:Close()'),
			}
		end
	end
end



