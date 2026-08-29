DPSMateFile("DPSMate_OptionsFuncs8.lua")
DPSMateMark("opt:FUNCS8")
-- Teil 8 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:FormatTime(time)
	if time>60 then
		local rest = ceil(mod(time, 60))
		if rest<10 then
			rest = "0"..rest
		end
		return floor(time/60)..":"..rest.."m"
	else
		return strformat("%.2f", time).."s"
	end
end

function DPSMate.Options:NewSegment(segname)
	-- Get name of this session
	local _,_,a = DPSMate.Modules.EDT:GetSortedTable(DPSMateEDT[2])
	local extra = ""
	if a[1] or segname~=nil then
		local name = segname
		if not segname then
			name = DPSMate:GetUserById(a[1]) or DPSMate.L["unknown"]
			extra = " - CBT: "..self:FormatTime(DPSMateCombatTime["current"])
		end
		if DPSMateSettings["onlybossfights"] then
			if DPSMate.BabbleBoss:Contains(name) then
				DPSMate.Options:CreateSegment(name..extra)
			end
		else
			DPSMate.Options:CreateSegment(name..extra)
		end
		
		DPSMateDamageDone[2] = {}
		DPSMateDamageTaken[2] = {}
		DPSMateEDD[2] = {}
		DPSMateEDT[2] = {}
		DPSMateTHealing[2] = {}
		DPSMateEHealing[2] = {}
		DPSMateOverhealing[2] = {}
		DPSMateEHealingTaken[2] = {}
		DPSMateHealingTaken[2] = {}
		DPSMateOverhealingTaken[2] = {}
		DPSMateAbsorbs[2] = {}
		DPSMateDeaths[2] = {}
		DPSMateInterrupts[2] = {}
		DPSMateDispels[2] = {}
		DPSMateAurasGained[2] = {}
		DPSMateThreat[2] = {}
		DPSMateFails[2] = {}
		DPSMateCCBreaker[2] = {}
		DPSMateCombatTime["current"] = 1
		DPSMateCombatTime["effective"][2] = {}
		DPSMate:SetStatusBarValue()
	end
	DPSMate.DB:Attempt(false)
end

function DPSMate.Options:CreateSegment(name)
	-- Need to add a new check
	local modes = {["DMGDone"] = DPSMateDamageDone[2], ["DMGTaken"] = DPSMateDamageTaken[2], ["EDDone"] = DPSMateEDD[2], ["EDTaken"] = DPSMateEDT[2], ["THealing"] = DPSMateTHealing[2], ["EHealing"] = DPSMateEHealing[2], ["OHealing"] = DPSMateOverhealing[2], ["EHealingTaken"] = DPSMateEHealingTaken[2], ["THealingTaken"] = DPSMateHealingTaken[2], ["Absorbs"] = DPSMateAbsorbs[2], ["Deaths"] = DPSMateDeaths[2], ["Interrupts"] = DPSMateInterrupts[2], ["Dispels"] = DPSMateDispels[2], ["Auras"] = DPSMateAurasGained[2]}
	
	tinsert(DPSMateHistory["names"], 1, name.." - "..GameTime_GetTime())
	for cat, val in pairs(modes) do
		tinsert(DPSMateHistory[cat], 1, DPSMate:CopyTable(val))
		if DPSMate:TableLength(DPSMateHistory[cat])>DPSMateSettings["datasegments"] then
			for i=DPSMateSettings["datasegments"]+1, DPSMate:TableLength(DPSMateHistory[cat]) do
				tremove(DPSMateHistory[cat], i)
			end
			tremove(DPSMateHistory[cat], DPSMateSettings["datasegments"]+1)
		end
		if DPSMate:TableLength(DPSMateCombatTime["segments"])>DPSMateSettings["datasegments"] then
			for i=DPSMateSettings["datasegments"]+1, DPSMate:TableLength(DPSMateCombatTime["segments"]) do
				tremove(DPSMateCombatTime["segments"], i)
			end
		end
	end
	tinsert(DPSMateCombatTime["segments"], 1, {[1]=DPSMateCombatTime["current"], [2]=DPSMateCombatTime["effective"][2]})
	DPSMate.Options:InitializeSegments()
end

function DPSMate.Options:InitializeSegments()
	local i=1
	DPSMate.Options.Options[2]["args"] = {
		total = {
			order = 10,
			type = 'toggle',
			name = DPSMate.L["total"],
			desc = DPSMate.L["totalmode"],
			get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["total"] end,
			set = function() DPSMate.Options:ToggleDrewDrop(2, "total", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
		},
		currentFight = {
			order = 20,
			type = 'toggle',
			name = DPSMate.L["mcurrent"],
			desc = DPSMate.L["currentmode"],
			get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["currentfight"] end,
			set = function() DPSMate.Options:ToggleDrewDrop(2, "currentfight", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
		},
	}
	DPSMate.Options.Options[3]["args"]["deletesegment"]["args"] = {}
	for cat, val in pairs(DPSMateHistory["DMGDone"]) do
		if not val then break end
		DPSMate.Options.Options[2]["args"]["segment"..i] = {
			order = 20+i*10,
			type = 'toggle',
			name = i..". "..DPSMateHistory["names"][i],
			desc = DPSMate.L["fdetailsfor"]..DPSMateHistory["names"][i],
			get = loadstring('return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][2]["segment'..i..'"];'),
			set = loadstring('DPSMate.Options:ToggleDrewDrop(2, "segment'..i..'", DPSMate.Options.Dewdrop:GetOpenedParent());'),
		}
		DPSMate.Options.Options[3]["args"]["deletesegment"]["args"]["segment"..i] = {
			order = i*10,
			type = 'execute',
			name = i..". "..DPSMateHistory["names"][i],
			desc = DPSMate.L["removesegmentof"]..DPSMateHistory["names"][i],
			func = loadstring('DPSMate.Options:RemoveSegment('..i..');'),
		}
		i=i+1
	end
end

function DPSMate.Options:OnVerticalScroll(obj, arg1, pre, spec)
	pre = pre or 20
	local maxScroll = _G(obj:GetName().."_Child"):GetHeight()-100
	if spec then maxScroll = maxScroll + 100 end
	local Scroll = obj:GetVerticalScroll()
	local toScroll = (Scroll - (pre*arg1))
	if toScroll < 0 or maxScroll < 0 then
		obj:SetVerticalScroll(0)
	elseif toScroll > maxScroll then
		obj:SetVerticalScroll(maxScroll)
	else
		obj:SetVerticalScroll(toScroll)
	end
end

function DPSMate.Options:CreateWindow()
	local na = string.gsub(DPSMate_ConfigMenu_Tab_Window_Editbox:GetText(), "%s", "")
	if (na and not DPSMate:GetKeyByValInTT(DPSMateSettings["windows"], na, "name") and na~="") then
		tinsert(DPSMateSettings["windows"], {
			name = na,
			options = {
				[1] = {
					damage = true
				},
				[2] = {
					total = true
				}
			},
			CurMode = "damage",
			hidden = false,
			scale = 1,
			barfont = "ARIALN",
			barfontsize = 14,
			barfontflag = "Outline",
			bartexture = "Healbot",
			barspacing = 1,
			barheight = 19,
			classicons = true,
			ranks = true,
			titlebar = true,
			titlebarfont = "FRIZQT",
			titlebarfontflag = "None",
			titlebarfontsize = 12,
			titlebarheight = 18,
			titlebarreport = true,
			titlebarreset = true,
			titlebarsegments = true,
			titlebarconfig = false,
			titlebarenable = false,
			titlebarfilter = true,
			titlebarsync = false,
			titlebartexture = "Healbot",
			titlebarbgcolor = {0,0,0},
			titlebarfontcolor = {1.0,0.82,0.0},
			barfontcolor = {1.0,1.0,1.0},
			contentbgtexture = "UI-Tooltip-Background",
			contentbgcolor = {0,0,0},
			bgbarcolor = {1,1,1},
			numberformat = 1,
			opacity = 1,
			bgopacity = 1,
			titlebaropacity = 1,
			filterclasses = {
				warrior = true,
				rogue = true,
				priest = true,
				hunter = true,
				mage = true,
				warlock = true,
				paladin = true,
				shaman = true,
				druid = true,
			},
			filterpeople = "",
			grouponly = false,
			realtime = false,
			cbtdisplay = false,
			barbg = false,
			totopacity = 1.0,
			borderopacity = 1.0,
			contentbordercolor = {0,0,0},
			borderstrata = 1,
			bordertexture = "UI-Tooltip-Border",
		})
		local TL = DPSMate:TableLength(DPSMateSettings["windows"])
		if not _G("DPSMate_"..na) then
			local fr=CreateFrame("Frame", "DPSMate_"..na, UIParent, "DPSMate_Statusframe")
			fr.Key=TL
		end
		if DPSMate_RebuildWindowMenuButtons then
			DPSMate_RebuildWindowMenuButtons()
		end
		DPSMate:InitializeFrames()
		_G("DPSMate_"..na.."_Head_Font"):SetText(DPSMate.L["damage"])
		_G("DPSMate_"..na.."_ScrollFrame_Child"):SetWidth(150)
		_G("DPSMate_"..na.."_ScrollFrame"):SetHeight(84)
		DPSMate:SetStatusBarValue()
	end
end

