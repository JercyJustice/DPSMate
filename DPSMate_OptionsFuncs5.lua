DPSMateFile("DPSMate_OptionsFuncs5.lua")
DPSMateMark("opt:FUNCS5")
-- Teil 5 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:UpdateConfigModes(obj, o, p) 
	local line, lineplusoffset
	local TL = DPSMate:TableLength(DPSMate.ModuleNames)
	local path, t = obj:GetName().."_Button", {}
	if p then
		for cat, val in DPSMate.ModuleNames do
			if not DPSMate:TContains(DPSMateSettings["hiddenmodes"], val) then
				tinsert(t, 1, cat)
			end
		end
	else
		for cat, val in DPSMate.ModuleNames do
			if DPSMate:TContains(DPSMateSettings["hiddenmodes"], val) then
				tinsert(t, 1, cat)
			end
		end
	end
	local TL = DPSMate:TableLength(t)
	obj.offset = (obj.offset or 0) - o 
	if obj.offset > (TL-15) then obj.offset = (TL-15) end
	if obj.offset < 0 then obj.offset = 0 end
	for line=1, 15 do
		lineplusoffset = line + obj.offset
		if t[lineplusoffset] then
			_G(path..line.."Text"):SetText(t[lineplusoffset])
			_G(path..line):Show()
		else
			_G(path..line):Hide()
		end
		_G(path..line.."Texture"):Hide()
		_G(path..line.."Text"):SetTextColor(1,1,1,1)
		_G(path..line).selected = false
	end
end

DPSMate.Options.ShowMenu = UnitPopup_ShowMenu
local DPSMate_ShowMenuHook = function(dropdownMenu, which, unit, name, userData)
	DPSMate.Options:DropDownStyleReset()
	DPSMate.Options.ShowMenu(dropdownMenu, which, unit, name, userData)
end
if DPSMate.Options.ShowMenu then
	pcall(function() UnitPopup_ShowMenu = DPSMate_ShowMenuHook end)
end

DPSMate.Options.UIDDI = UIDropDownMenu_Initialize
local DPSMate_UIDDIHook = function(frame, initFunction, displayMode, level)
	pcall(function() DPSMate.Options:DropDownStyleReset() end)
	if DPSMate.Options.UIDDI then
		DPSMate.Options.UIDDI(frame, initFunction, displayMode, level)
	end
end
if DPSMate.Options.UIDDI then
	pcall(function() UIDropDownMenu_Initialize = DPSMate_UIDDIHook end)
end

function DPSMate.Options:ChannelDropDown()
	local channel, i = DPSMate.L["reportchannel"], 1
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_Report_Channel, this.value)
    end
	
	-- Adding dynamic channel
	for i=0,25 do
		local id, name = GetChannelName(i);
		if name then
			if not DPSMate:TContains(channel, name) then
				tinsert(channel, name)
			end
		end
	end
	
	-- Initializing channel
	for cat, val in pairs(channel) do
		UIDropDownMenu_AddButton{
			text = val,
			value = val,
			func = on_click,
		}
	end
	
	UIDropDownMenu_SetSelectedValue(DPSMate_Report_Channel, DPSMateOptState.SelectedChannel)
end

local function DPSMate_SetDropDownText(frame, value)
	if not frame then return end
	if UIDropDownMenu_SetSelectedValue then
		pcall(UIDropDownMenu_SetSelectedValue, frame, value)
	end
	local text = getglobal(frame:GetName().."Text")
	if text and text.SetText then
		local cur = text.GetText and text:GetText()
		if not cur or cur == "" then text:SetText(value) end
	end
end

function DPSMate.Options:RefreshWindowDropDowns()
	local dds = {
		DPSMate_ConfigMenu_Tab_Window_Remove,
		DPSMate_ConfigMenu_Tab_Window_ConfigFrom,
		DPSMate_ConfigMenu_Tab_Window_ConfigTo,
	}
	local i
	for i = 1, 3 do
		local dd = dds[i]
		if dd then
			dd.func = DPSMate.Options.WindowDropDown
			if UIDropDownMenu_Initialize then
				pcall(UIDropDownMenu_Initialize, dd, DPSMate.Options.WindowDropDown)
			end
			DPSMate_SetDropDownText(dd, "None")
		end
	end
end

function DPSMate.Options:WindowDropDown()
	local function on_click()
		local menu = UIDROPDOWNMENU_OPEN_MENU
		local frame = (type(menu) == "string" and getglobal(menu)) or (type(menu) == "table" and menu) or this
		if frame and frame.GetName and UIDropDownMenu_SetSelectedValue then
			pcall(UIDropDownMenu_SetSelectedValue, frame, this.value)
		end
		if frame and frame.GetName and frame:GetName() == "DPSMate_ConfigMenu_Tab_Window_Remove" then
			DPSMate_ConfigMenu.Selected = this.value
		end
	end

	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}

	local windows = DPSMateSettings and DPSMateSettings["windows"]
	if type(windows) == "table" then
		for _, val in pairs(windows) do
			if val and val["name"] then
				UIDropDownMenu_AddButton{
					text = val["name"],
					value = val["name"],
					func = on_click,
				}
			end
		end
	end

	DPSMate_SetDropDownText(DPSMate_ConfigMenu_Tab_Window_Remove, "None")
	DPSMate_SetDropDownText(DPSMate_ConfigMenu_Tab_Window_ConfigFrom, "None")
	DPSMate_SetDropDownText(DPSMate_ConfigMenu_Tab_Window_ConfigTo, "None")
	if DPSMate_ConfigMenu then DPSMate_ConfigMenu.vis = true end
end

function DPSMate.Options:BarFontDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Bars_BarFont, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["barfont"] = this.value
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

function DPSMate.Options:BarFontFlagsDropDown()
	local i = 1
	
	local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMate_ConfigMenu_Tab_Bars_BarFontFlag, this.value)
		DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key]["barfontflag"] = this.value
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

