DPSMateFile("DPSMate_OptionsFuncs7a.lua")
DPSMateMark("opt:FUNCS7a")
-- Teil 7 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:BorderStrataDropDown()
	local btns = {"Background", "Low", "High"}
	
	local function on_click()
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["borderstrata"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Content_BorderStrata, DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["borderstrata"])
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_Border"):SetFrameStrata(DPSMate.Options.stratas[this.value])
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
end

function DPSMate.Options:BorderTextureDropDown()
	local function on_click()
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["bordertexture"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Content_BorderTexture, DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["bordertexture"])
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_Border"):SetBackdrop({ 
																												  bgFile = "", 
																												  edgeFile = DPSMate.Options.bordertextures[this.value], tile = true, tileSize = 12, edgeSize = 10, 
																												  insets = { left = 5, right = 5, top = 3, bottom = 1 }
																												})
		_G("DPSMate_"..DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["name"].."_Border"):SetBackdropBorderColor(DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbordercolor"][1], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbordercolor"][2], DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["contentbordercolor"][3])
	end
	
	for val, _ in pairs(DPSMate.Options.bordertextures) do
		UIDropDownMenu_AddButton{
			text = val,
			value = val,
			func = on_click,
		}
	end
end

function DPSMate.Options:TooltipPositionDropDown()
	local btns = {DPSMate.L["default"], DPSMate.L["topright"], DPSMate.L["topleft"], DPSMate.L["left"], DPSMate.L["top"]}
	
	local function on_click()
		DPSMateSettings["tooltipanchor"] = this.value
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Tooltips_Position, DPSMateSettings["tooltipanchor"])
	end
	
	for val, name in pairs(btns) do
		UIDropDownMenu_AddButton{
			text = name,
			value = val,
			func = on_click,
		}
	end
	
	if not DPSMate_ConfigMenu.visBars10 then
		UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Tooltips_Position, DPSMateSettings["tooltipanchor"])
	end
	DPSMate_ConfigMenu.visBars10 = true
end

