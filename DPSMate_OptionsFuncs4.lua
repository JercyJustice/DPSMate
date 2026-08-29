DPSMateFile("DPSMate_OptionsFuncs4.lua")
DPSMateMark("opt:FUNCS4")
-- Teil 4 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:PopUpAccept(bool, bypass)
	DPSMate_PopUp:Hide()
	if DPSMate.DB:InPartyOrRaid() and not bypass and DPSMateSettings["sync"] and bool then
		if IsPartyLeader() or IsRaidOfficer() or IsRaidLeader() then
		else
			DPSMate:SendMessage(DPSMate.L["resetnotofficererror"])
			return
		end
	else
		if bool then
			DPSMateDamageDone = {[1]={},[2]={}}
			DPSMateDamageTaken = {[1]={},[2]={}}
			DPSMateEDD = {[1]={},[2]={}}
			DPSMateEDT = {[1]={},[2]={}}
			DPSMateTHealing = {[1]={},[2]={}}
			DPSMateEHealing = {[1]={},[2]={}}
			DPSMateOverhealing = {[1]={},[2]={}}
			DPSMateHealingTaken = {[1]={},[2]={}}
			DPSMateEHealingTaken = {[1]={},[2]={}}
			DPSMateOverhealingTaken = {[1]={},[2]={}}
			DPSMateAbsorbs = {[1]={},[2]={}}
			DPSMateDispels = {[1]={},[2]={}}
			DPSMateDeaths = {[1]={},[2]={}}
			DPSMateInterrupts = {[1]={},[2]={}}
			DPSMateAurasGained = {[1]={},[2]={}}
			DPSMateThreat = {[1]={},[2]={}}
			DPSMateFails = {[1]={},[2]={}}
			DPSMateCCBreaker = {[1]={},[2]={}}
			DPSMateHistory = {
				names = {},
				DMGDone = {},
				DMGTaken = {},
				EDDone = {},
				EDTaken = {},
				THealing = {},
				EHealing = {},
				OHealing = {},
				EHealingTaken = {},
				THealingTaken = {},
				OHealingTaken = {},
				Absorbs = {},
				Deaths = {},
				Interrupts = {},
				Dispels = {},
				Auras = {},
				Threat = {},
				Fails = {},
				CCBreaker = {}
			}
			DPSMateCombatTime = {
				total = 1,
				current = 1,
				segments = {},
				effective = {
					[1] = {},
					[2] = {}
				},
			}
			DPSMateAttempts = {}
			DPSMateLoot = {}
			
			-- Get buffs of people after reset
			local type = "party"
			local num = GetNumPartyMembers()
			if num<=0 then
				type = "raid"
				num = GetNumRaidMembers()
			end
			for p=1, num do
				for i=1, 32 do
					GameTooltip:SetOwner(UIParent)
					GameTooltip:SetUnitBuff(type..p, i)
					local buff = GameTooltipTextLeft1:GetText()
					GameTooltip:Hide()
					if buff then
						DPSMate.DB:BuildBuffs(DPSMate.L["unknown"], UnitName(type..p), buff, false)
					end
				end
			end
			if type == "party" or num <= 0 then
				for i=0,31 do
					GameTooltip:SetOwner(UIParent)
					GameTooltip:SetPlayerBuff(i)
					local buff = GameTooltipTextLeft1:GetText()
					GameTooltip:Hide()
					if buff then
						DPSMate.DB:BuildBuffs(DPSMate.L["unknown"], UnitName("player"), buff, false)
					end
				end
			end
		else
			DPSMateDamageDone[2] = {}
			DPSMateDamageTaken[2] = {}
			DPSMateEDD[2] = {}
			DPSMateEDT[2] = {}
			DPSMateTHealing[2] = {}
			DPSMateEHealing[2] = {}
			DPSMateOverhealing[2] = {}
			DPSMateHealingTaken[2] = {}
			DPSMateEHealingTaken[2] = {}
			DPSMateOverhealingTaken[2] = {}
			DPSMateAbsorbs[2] = {}
			DPSMateDispels[2] = {}
			DPSMateDeaths[2] = {}
			DPSMateInterrupts[2] = {}
			DPSMateAurasGained[2] = {}
			DPSMateThreat[2] = {}
			DPSMateFails[2] = {}
			DPSMateCCBreaker[2] = {}
			DPSMateCombatTime["current"] = 1
		end
		DPSMate.Modules.DPS.DB = DPSMateDamageDone
		DPSMate.Modules.Damage.DB = DPSMateDamageDone
		DPSMate.Modules.DamageTaken.DB = DPSMateDamageTaken
		DPSMate.Modules.FriendlyFire.DB = DPSMateEDT
		DPSMate.Modules.FriendlyFireTaken.DB = DPSMateEDT
		DPSMate.Modules.DTPS.DB = DPSMateDamageTaken
		DPSMate.Modules.EDD.DB = DPSMateEDD
		DPSMate.Modules.EDT.DB = DPSMateEDT
		DPSMate.Modules.Healing.DB = DPSMateTHealing
		DPSMate.Modules.HPS.DB = DPSMateTHealing
		DPSMate.Modules.Overhealing.DB = DPSMateOverhealing
		DPSMate.Modules.EffectiveHealing.DB = DPSMateEHealing
		DPSMate.Modules.EffectiveHPS.DB = DPSMateEHealing
		DPSMate.Modules.HealingTaken.DB = DPSMateHealingTaken
		DPSMate.Modules.EffectiveHealingTaken.DB = DPSMateEHealingTaken
		DPSMate.Modules.Absorbs.DB = DPSMateAbsorbs
		DPSMate.Modules.AbsorbsTaken.DB = DPSMateAbsorbs
		DPSMate.Modules.HealingAndAbsorbs.DB = DPSMateAbsorbs
		DPSMate.Modules.Deaths.DB = DPSMateDeaths
		DPSMate.Modules.Dispels.DB = DPSMateDispels
		DPSMate.Modules.DispelsReceived.DB = DPSMateDispels
		DPSMate.Modules.Decurses.DB = DPSMateDispels
		DPSMate.Modules.DecursesReceived.DB = DPSMateDispels
		DPSMate.Modules.CureDisease.DB = DPSMateDispels
		DPSMate.Modules.CureDiseaseReceived.DB = DPSMateDispels
		DPSMate.Modules.CurePoison.DB = DPSMateDispels
		DPSMate.Modules.CurePoisonReceived.DB = DPSMateDispels
		DPSMate.Modules.LiftMagic.DB = DPSMateDispels
		DPSMate.Modules.LiftMagicReceived.DB = DPSMateDispels
		DPSMate.Modules.Interrupts.DB = DPSMateInterrupts
		DPSMate.Modules.AurasGained.DB = DPSMateAurasGained
		DPSMate.Modules.AurasLost.DB = DPSMateAurasGained
		DPSMate.Modules.AurasUptimers.DB = DPSMateAurasGained
		DPSMate.Modules.Procs.DB = DPSMateAurasGained
		DPSMate.Modules.Casts.DB = DPSMateEDT
		DPSMate.Modules.Threat.DB = DPSMateThreat
		DPSMate.Modules.TPS.DB = DPSMateThreat
		DPSMate.Modules.Fails.DB = DPSMateFails
		DPSMate.Modules.CCBreaker.DB = DPSMateCCBreaker
		DPSMate.Modules.OHPS.DB = DPSMateOverhealing
		DPSMate.Modules.OHealingTaken.DB = DPSMateOverhealingTaken
		DPSMate.Modules.Activity.DB = DPSMateCombatTime
		for _, val in pairs(DPSMateSettings["windows"]) do
			if not val["options"][2]["total"] and not val["options"][2]["currentfight"] then
				val["options"][2]["total"] = true
			end
		end
		DPSMate.Options:InitializeSegments()
		DPSMate:SetStatusBarValue()
	end
end

function DPSMate.Options:OpenMenu(b, obj)
	for _, val in pairs(DPSMateSettings.windows) do
		if DPSMate.Options.Dewdrop:IsOpen(_G("DPSMate_"..val["name"])) then
			DPSMate.Options.Dewdrop:Close()
			return
		end
		if DPSMate.Options.Dewdrop:IsRegistered(_G("DPSMate_"..val["name"])) then DPSMate.Options.Dewdrop:Unregister(_G("DPSMate_"..val["name"])) end
	end
	DPSMate.Options.Dewdrop:Register(obj,
		'children', function() 
			DPSMate.Options.Dewdrop:FeedAceOptionsTable(DPSMate.Options.Options[b]) 
		end,
		'cursorX', true,
		'cursorY', true,
		'dontHook', true
	)
	DPSMate.Options.Dewdrop:Open(obj)
end

function DPSMate.Options:ToggleDrewDrop(i, obj, pa)
	if not DPSMate:WindowsExist() then return end
	for cat, _ in pairs(DPSMateSettings["windows"][pa.Key]["options"][i]) do
		DPSMateSettings["windows"][pa.Key]["options"][i][cat] = false
	end
	DPSMateSettings["windows"][pa.Key]["options"][i][obj] = true
	if i == 1 then
		_G(pa:GetName().."_Head_Font"):SetText(DPSMate.Options.Options[i]["args"][obj].name)
		DPSMateSettings["windows"][pa.Key]["CurMode"] = obj
	end
	DPSMate.Options.Dewdrop:Close()
	if DPSMate.DB.loaded then DPSMate:SetStatusBarValue() end
	return true
end

function DPSMate.Options:UpdateDetails(obj, bool, objname)
	if objname then
		obj = _G(objname)
	end
	local key = obj:GetParent():GetParent():GetParent().Key
	if obj.user then
		DPSMate.RegistredModules[DPSMateSettings["windows"][key]["CurMode"]]:OpenDetails(obj, key, bool)
	else
		DPSMate:SendMessage(DPSMate.L["findusererror"])
	end
end

function DPSMate.Options:UpdateTotalDetails(obj)
	local key = obj:GetParent():GetParent():GetParent().Key
	DPSMate.RegistredModules[DPSMateSettings["windows"][key]["CurMode"]]:OpenTotalDetails(obj, key)
end

function DPSMate.Options:DropDownStyleReset()
	for i=1, 20 do
		local button = _G("DropDownList1Button"..i)
		local font = _G("DropDownList1Button"..i.."NormalText")
		if font and font.SetFont then
			font:SetFont(STANDARD_TEXT_FONT, UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT or 10)
		end
		if button and button.SetScript then
			button:SetScript("OnEnter", function()
				if ( this.hasArrow ) then
					ToggleDropDownMenu(this:GetParent():GetID() + 1, this.value);
				else
					CloseDropDownMenus(this:GetParent():GetID() + 1);
				end
				local hl = getglobal(this:GetName().."Highlight")
				if hl then hl:Show() end
				if UIDropDownMenu_StopCounting then UIDropDownMenu_StopCounting(this:GetParent()) end
				if ( this.tooltipTitle ) then
					GameTooltip_AddNewbieTip(this.tooltipTitle, 1.0, 1.0, 1.0, this.tooltipText, 1);
				end
			end)
		end
		local backdrop = _G("DropDownList1Backdrop")
		if backdrop and backdrop.SetBackdrop then
			backdrop:SetBackdrop({
				bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32,
				insets = { left = 11, right = 12, top = 12, bottom = 11 }
			})
		end
		if button and button.tex then
			button.tex:Hide()
		end
	end
end

