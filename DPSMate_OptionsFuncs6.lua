DPSMateFile("DPSMate_OptionsFuncs6.lua")
DPSMateMark("opt:FUNCS6")
-- Teil 6 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:BarTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Bars_BarTexture, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["bartexture"] = this.value
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:SetTexture(DPSMate.Options.statusbars[this.value])
		DPSMate_ConfigMenu_Tab_Bars_BarTexture.tex:Show()
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total"):SetStatusBarTexture(DPSMate.Options.statusbars[this.value])
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_Total_BG"):SetTexture(DPSMate.Options.statusbars[this.value])
		for i=1, 40 do
			_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i):SetStatusBarTexture(DPSMate.Options.statusbars[this.value])
			_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Child_StatusBar"..i.."_BG"):SetTexture(DPSMate.Options.statusbars[this.value])
		end
	end
	
	for name, path in pairs(DPSMate.Options.statusbars) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		if not button.tex then
			button.tex = button:CreateTexture("BG", "BACKGROUND")
			button.tex:SetTexture(path)
			button.tex:SetWidth(100)
			button.tex:SetHeight(20)
			button.tex:SetPoint("TOPLEFT", button, "TOPLEFT")
		end
		button.tex:Show()
		i=i+1
	end
end

function DPSMate.Options:TitleBarTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_TitleBar_BarTexture, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["titlebartexture"] = this.value
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:SetTexture(DPSMate.Options.statusbars[this.value])
		DPSMate_ConfigMenu_Tab_TitleBar_BarTexture.tex:Show()
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_Head_Background"):SetTexture(DPSMate.Options.statusbars[this.value])
    end
	
	for name, path in pairs(DPSMate.Options.statusbars) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		if not button.tex then
			button.tex = button:CreateTexture("BG", "BACKGROUND")
			button.tex:SetTexture(path)
			button.tex:SetWidth(100)
			button.tex:SetHeight(20)
			button.tex:SetPoint("TOPLEFT", button, "TOPLEFT")
		end
		button.tex:Show()
		i=i+1
	end
end

function DPSMate.Options:TitleBarFontDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_TitleBar_BarFont, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["titlebarfont"] = this.value
		if DPSMate_ApplyWindowFonts then
			DPSMate_ApplyWindowFonts(DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key])
		end
    end
	
	for name, path in pairs(DPSMate.Options.fonts) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(path, 16)
		i=i+1
	end
end

function DPSMate.Options:TitleBarFontFlagsDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_TitleBar_BarFontFlag, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["titlebarfontflag"] = this.value
		if DPSMate_ApplyWindowFonts then
			DPSMate_ApplyWindowFonts(DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key])
		end
    end
	
	for name, flag in pairs(DPSMate.Options.fontflags) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		_G("DropDownList1Button"..i.."NormalText"):SetFont(DPSMate.Options.fonts["FRIZQT"], 12, flag)
		i=i+1
	end
end

function DPSMate.Options:ContentBGTextureDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Content_BGDropDown, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgtexture"] = this.value
		_G("DPSMate_ConfigMenu_Tab_Content_BGDropDown_Texture"):SetBackdrop({ 
			bgFile = DPSMate.Options.bgtexture[this.value], 
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 12, edgeSize = 12, 
			insets = { left = 4, right = 4, top = 4, bottom = 4 }
		})
		_G("DPSMate_ConfigMenu_Tab_Content_BGDropDown_Texture"):SetBackdropColor(DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][1], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][2], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][3])
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_ScrollFrame_Background"):SetTexture(DPSMate.Options.bgtexture[this.value])
    end
	
	for name, path in pairs(DPSMate.Options.bgtexture) do
		UIDropDownMenu_AddButton{
			text = name,
			value = name,
			func = on_click,
		}
		local button = _G("DropDownList1Button"..i)
		button.path = path
		button.i = i
		button:SetScript("OnEnter", function()
			_G(this:GetName().."Highlight"):Show()
			_G("DropDownList1Backdrop"):SetBackdrop({ 
				bgFile = this.path, 
				edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, 
				insets = { left = 11, right = 12, top = 12, bottom = 11 }
			})
			_G("DropDownList1Backdrop"):SetBackdropColor(DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][1], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][2], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbgcolor"][3])
		end)
		i=i+1
	end
end

function DPSMate.Options:SelectDataResets(obj, case)
	local vars = {["DPSMate_ConfigMenu_Tab_DataResets_EnteringWorld"] = "dataresetsworld", ["DPSMate_ConfigMenu_Tab_DataResets_PartyMemberChanged"] = "dataresetspartyamount", ["DPSMate_ConfigMenu_Tab_DataResets_JoinParty"] = "dataresetsjoinparty", ["DPSMate_ConfigMenu_Tab_DataResets_LeaveParty"] = "dataresetsleaveparty", ["DPSMate_ConfigMenu_Tab_DataResets_Sync"] = "dataresetssync", ["DPSMate_ConfigMenu_Tab_DataResets_Logout"] = "dataresetslogout"}
	DPSMateSettings[vars[obj:GetName()]] = case
	UIDropDownMenu_SetSelectedValue(obj, case)
end

function DPSMate.Options:DataResetsDropDown()
	local btns = {DPSMate.L["yes"], DPSMate.L["no"], DPSMate.L["ask"]}
	
	local function on_click()
		DPSMate.Options:SelectDataResets(_G(UIDROPDOWNMENU_OPEN_MENU), this.value)
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
	
	if not DPSMate_ConfigMenu.visBars8 then
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_EnteringWorld, DPSMateSettings["dataresetsworld"])
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_JoinParty, DPSMateSettings["dataresetsjoinparty"])
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_PartyMemberChanged, DPSMateSettings["dataresetspartyamount"])
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_LeaveParty, DPSMateSettings["dataresetsleaveparty"])
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_Sync, DPSMateSettings["dataresetssync"])
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_DataResets_Logout, DPSMateSettings["dataresetslogout"])
	end
	DPSMate_ConfigMenu.visBars8 = true
end

function DPSMate.Options:NumberFormatDropDown()
	local btns = {DPSMate.L["normal"], DPSMate.L["condensed"], DPSMate.L["commas"], DPSMate.L["semicondensed"]}
	
	local function on_click()
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["numberformat"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Content_NumberFormat, DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["numberformat"])
		DPSMate:SetStatusBarValue()
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
end

