DPSMateFile("DPSMate_OptionsFuncs3c.lua")
DPSMateMark("opt:FUNCS3c")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:OnEvent(event)
	if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		DPSMate.Options:HideWhenSolo()
		if DPSMate.Options:IsInParty() then
			if DPSMateOptState.LastPartyNum == 0 then
				if DPSMateSettings["dataresetsjoinparty"] == 3 then
					if (GetTime()-DPSMateOptState.LastPopUp) > DPSMateOptState.TimeToNextPopUp and (DPSMate:TableLength(DPSMateUser) ~= 0 or DPSMate:TableLength(DPSMateUserCurrent) ~= 0) then
						DPSMate.Options:ShowResetPopUp()
						DPSMateOptState.LastPopUp = GetTime()
					end
				elseif DPSMateSettings["dataresetsjoinparty"] == 1 then
					DPSMate.Options:PopUpAccept(true, true)
				end
				DPSMate.DB:OnGroupUpdate()
			elseif DPSMateOptState.LastPartyNum ~= DPSMateOptState.PartyNum	then
				if DPSMateSettings["dataresetspartyamount"] == 3 then
					if (GetTime()-DPSMateOptState.LastPopUp) > DPSMateOptState.TimeToNextPopUp and (DPSMate:TableLength(DPSMateUser) ~= 0 or DPSMate:TableLength(DPSMateUserCurrent) ~= 0) then
						DPSMate.Options:ShowResetPopUp()
						DPSMateOptState.LastPopUp = GetTime()
					end
				elseif DPSMateSettings["dataresetspartyamount"] == 1 then
					DPSMate.Options:PopUpAccept(true)
				end
				DPSMate.DB:OnGroupUpdate()
			end
		else
			if DPSMateOptState.LastPartyNum > DPSMateOptState.PartyNum then
				if DPSMateSettings["dataresetsleaveparty"] == 3 then
					if (GetTime()-DPSMateOptState.LastPopUp) > DPSMateOptState.TimeToNextPopUp and (DPSMate:TableLength(DPSMateUser) ~= 0 or DPSMate:TableLength(DPSMateUserCurrent) ~= 0) then
						DPSMate.Options:ShowResetPopUp()
						DPSMateOptState.LastPopUp = GetTime()
					end
				elseif DPSMateSettings["dataresetsleaveparty"] == 1 then
					DPSMate.Options:PopUpAccept(true)
				end
				DPSMate.DB:OnGroupUpdate()
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		if DPSMateSettings["dataresetsworld"] == 3 then
			if (GetTime()-DPSMateOptState.LastPopUp) > DPSMateOptState.TimeToNextPopUp and (DPSMate:TableLength(DPSMateUser) ~= 0 or DPSMate:TableLength(DPSMateUserCurrent) ~= 0) then
				self:ShowResetPopUp()
				DPSMateOptState.LastPopUp = GetTime()
			end
		elseif DPSMateSettings["dataresetsworld"] == 1 and not self:IsInParty() then
			self:PopUpAccept(true)
		end
		if DPSMate.RestoreMiniMapPosition then
			pcall(function() DPSMate:RestoreMiniMapPosition() end)
		end
		if DPSMate.ApplyWindowVisibility then
			pcall(function() DPSMate:ApplyWindowVisibility() end)
		end
		self:HideInPvP()
		if DPSMateSettings["hideonlogin"] then
			for _, val in pairs(DPSMateSettings["windows"]) do
				local wf = _G("DPSMate_"..val["name"])
				if wf then DPSMate.Options:Hide(wf) end
			end
		end
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		DPSMate.DB:OnGroupUpdate()
	end
end

function DPSMate.Options:ShowResetPopUp()
	if DPSMateSettings["sync"] then
		if IsPartyLeader() or IsRaidOfficer() or IsRaidLeader() then
			DPSMate_PopUp:Show()
		end
	else
		DPSMate_PopUp:Show()
	end
end

