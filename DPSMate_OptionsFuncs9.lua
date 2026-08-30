DPSMateFile("DPSMate_OptionsFuncs9.lua")
DPSMateMark("opt:FUNCS9")
-- Teil 9 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:RemoveWindow()
	local selected = DPSMate_ConfigMenu and DPSMate_ConfigMenu.Selected
	if not selected or selected == "None" or selected == "" then return end
	local frame = _G("DPSMate_"..selected)
	local key
	if frame then
		frame:Hide()
		key = frame.Key
	else
		key = DPSMate:GetKeyByValInTT(DPSMateSettings["windows"], selected, "name")
	end
	if key then
		tremove(DPSMateSettings["windows"], key)
	end
	if DPSMate_RebuildWindowMenuButtons then
		DPSMate_RebuildWindowMenuButtons()
	end
	if UIDropDownMenu_SetSelectedValue and DPSMate_ConfigMenu_Tab_Window_Remove then
		pcall(UIDropDownMenu_SetSelectedValue, DPSMate_ConfigMenu_Tab_Window_Remove, "None")
	end
	if DPSMate_ConfigMenu then DPSMate_ConfigMenu.Selected = "None" end
	if DPSMate.Options.RefreshWindowDropDowns then
		DPSMate.Options:RefreshWindowDropDowns()
	end
	if DPSMate_ConfigMenu_Menu_Button1 then
		DPSMate_ConfigMenu_Menu_Button1.selected = true
	end
	local hl = _G("DPSMate_ConfigMenu_Menu_Button1Texture")
	if hl then hl:Show() end
end

function DPSMate.Options:CopyConfiguration()
	local fromName = _G("DPSMate_ConfigMenu_Tab_Window_ConfigFromText"):GetText()
	local toName = _G("DPSMate_ConfigMenu_Tab_Window_ConfigToText"):GetText()
	if fromName~="None" and toName~="None" then
		local fromKey = _G("DPSMate_"..fromName).Key
		local toKey = _G("DPSMate_"..toName).Key
		for cat, val in pairs(DPSMateSettings["windows"][fromKey]) do
			if cat~="name" and cat~="options" then
				DPSMateSettings["windows"][toKey][cat] = val
			end
		end
		DPSMate:InitializeFrames()
	end
end

function DPSMate.Options:Lock()
	DPSMateSettings.lock = true
	for _,val in pairs(DPSMateSettings["windows"]) do
		_G("DPSMate_"..val["name"].."_Resize"):Hide()
	end
	DPSMate:SendMessage(DPSMate.L["lockedallw"])
end

function DPSMate.Options:Unlock()
	DPSMateSettings.lock = false
	for _,val in pairs(DPSMateSettings["windows"]) do
		_G("DPSMate_"..val["name"].."_Resize"):Show()
	end
	DPSMate:SendMessage(DPSMate.L["unlockedallw"])
end

function DPSMate.Options:Hide(frame)
	DPSMateSettings["windows"][frame.Key]["hidden"] = true
	frame:Hide()
end

function DPSMate.Options:Show(frame)
	DPSMateSettings["windows"][frame.Key]["hidden"] = false
	frame:Show()
end

function DPSMate.Options:RemoveSegment(i)
	for cat, val in DPSMateHistory do
		tremove(DPSMateHistory[cat], i)
	end
	DPSMate.Options:InitializeSegments()
	DPSMate.Options.Dewdrop:Close()
end

function DPSMate.Options:ToggleTitleBarButtonState()
	local buttons = {"Config", "Reset", "Segments", "Filter", "Report", "Sync", "Enable"}
	for _, val in pairs(DPSMateSettings["windows"]) do
		local parent, i = _G("DPSMate_"..val["name"].."_Head"), 0
		for _, name in pairs(buttons) do
			local button = _G("DPSMate_"..val["name"].."_Head_"..name)
			if button then
				if val["titlebar"..strlower(name)] then
					button:ClearAllPoints()
					button:SetPoint("RIGHT", parent, "RIGHT", -i*15-2, 0)
					button:Show()
					i=i+1
				else
					button:Hide()
				end
			end
		end
	end
end

function DPSMate.Options:ToggleState()
	if DPSMateSettings["enable"] then
		DPSMateSettings["sync"] = false
		DPSMateSettings["enable"] = false
		DPSMate:Disable()
		for cat, val in DPSMateSettings["windows"] do
			_G("DPSMate_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(1,0,0,1)
			_G("DPSMate_"..val["name"].."_Head_Enable"):SetChecked(false)
		end
	else
		DPSMateSettings["enable"] = true
		DPSMate:Enable()
		for cat, val in DPSMateSettings["windows"] do
			_G("DPSMate_"..val["name"].."_Head_Enable"):SetChecked(true)
		end
	end
end

function DPSMate.Options:SetColor()
	local r,g,b = ColorPickerFrame:GetColorRGB()
	local swatch,frame
	swatch = _G(ColorPickerFrame.obj:GetName().."NormalTexture")
	frame = _G(ColorPickerFrame.obj:GetName().."_SwatchBg")
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b
	
	DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key][ColorPickerFrame.var] = {r,g,b}
	
	ColorPickerFrame.rfunc()
end

function DPSMate.Options:CancelColor()
	local r = ColorPickerFrame.previousValues.r
	local g = ColorPickerFrame.previousValues.g
	local b = ColorPickerFrame.previousValues.b
	local swatch,frame
	swatch = _G(ColorPickerFrame.obj:GetName().."NormalTexture")
	frame = _G(ColorPickerFrame.obj:GetName().."_SwatchBg")
	swatch:SetVertexColor(r,g,b)
	frame.r = r
	frame.g = g
	frame.b = b
	
	DPSMateSettings["windows"][DPSMate_ConfigMenu_Menu.Key][ColorPickerFrame.var] = {r,g,b}
	
	ColorPickerFrame.rfunc()
end

function DPSMate.Options:OpenColorPicker(obj, var, func)
	if CloseMenus then CloseMenus() end
	if DPSMate_OpenColorPicker then
		DPSMate_OpenColorPicker(obj, var, func)
		return
	end
	button = _G(obj:GetName().."_SwatchBg")
	ColorPickerFrame.obj = obj
	ColorPickerFrame.var = var
	ColorPickerFrame.rfunc = func
	ColorPickerFrame.func = DPSMate.Options.SetColor
	ColorPickerFrame:SetColorRGB(button.r, button.g, button.b)
	ColorPickerFrame.previousValues = {r = button.r, g = button.g, b = button.b, opacity = button.opacity}
	ColorPickerFrame.cancelFunc = DPSMate.Options.CancelColor
	ColorPickerFrame:SetPoint("TOPLEFT", obj, "TOPRIGHT", 0, 0)
	ColorPickerFrame:SetFrameStrata("TOOLTIP")
	ColorPickerFrame:Show()
end

function DPSMate.Options:ShowTooltip(bar)
	bar = bar or this
	if not bar or not bar.user then return end
	if DPSMateSettings["showtooltips"] then
		local key, win
		if DPSMate_WindowKeyFromBar then
			key, win = DPSMate_WindowKeyFromBar(bar)
		end
		if not key then
			local p = bar.GetParent and bar:GetParent()
			p = p and p.GetParent and p:GetParent()
			p = p and p.GetParent and p:GetParent()
			key = p and p.Key
			win = p
		end
		if not key then return end
		DPSMate.TooltipKey = key
		if DPSMateSettings["tooltipanchor"] == 1 then
			GameTooltip:SetOwner(UIParent, "BOTTOMRIGHT")
		elseif DPSMateSettings["tooltipanchor"] == 2 then
			GameTooltip:SetOwner(win or UIParent, "RIGHT")
		elseif DPSMateSettings["tooltipanchor"] == 3 then
			GameTooltip:SetOwner(win or UIParent, "LEFT")
		elseif DPSMateSettings["tooltipanchor"] == 4 then
			GameTooltip:SetOwner(win or UIParent, "TOP")
		elseif DPSMateSettings["tooltipanchor"] == 5 then
			GameTooltip:SetOwner(win or UIParent, "TOPRIGHT")
		end
		local head = win and win.GetName and _G(win:GetName().."_Head_Font")
		local headText = ""
		if head and head.GetText then headText = head:GetText() or "" end
		GameTooltip:AddLine(bar.user.."'s "..headText, 1,1,1)
		local mode = DPSMateSettings["windows"][key] and DPSMateSettings["windows"][key]["CurMode"]
		local mod = mode and DPSMate.RegistredModules and DPSMate.RegistredModules[mode]
		if mod and mod.ShowTooltip then
			mod:ShowTooltip(bar.user, key)
		end
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(DPSMate.L["leftclickopend"])
		GameTooltip:AddLine(DPSMate.L["rightclickopenm"])
		GameTooltip:Show()
	end
end

function DPSMate.Options:InitializeHideShowWindow()
	local i = 1
	DPSMate.Options.Options[3]["args"]["hidewindow"]["args"] = {}
	DPSMate.Options.Options[3]["args"]["showwindow"]["args"] = {}
	for _,val in pairs(DPSMateSettings["windows"]) do
		DPSMate.Options.Options[3]["args"]["hidewindow"]["args"][val["name"]] = {
			order = i*10,
			type = 'execute',
			name = val["name"],
			desc = DPSMate.L["hide"].." "..val["name"],
			func = loadstring('DPSMate.Options:Hide(getglobal("DPSMate_'..val["name"]..'")); DPSMate.Options.Dewdrop:Close();'),
		}
		DPSMate.Options.Options[3]["args"]["showwindow"]["args"][val["name"]] = {
			order = i*10,
			type = 'execute',
			name = val["name"],
			desc = DPSMate.L["show"].." "..val["name"],
			func = loadstring('DPSMate.Options:Show(getglobal("DPSMate_'..val["name"]..'")); DPSMate.Options.Dewdrop:Close();'),
		}
		i=i+1
	end
end

function DPSMate.Options:CheckButton(name, id)
	if DPSMateSettings[name][id] then
		DPSMateSettings[name][id] = false
	else
		DPSMateSettings[name][id] = true
	end
	DPSMate:SetStatusBarValue()
end

function DPSMate.Options:ToggleSync()
	if DPSMateSettings["sync"] then
		DPSMateSettings["sync"] = false
		for _, val in pairs(DPSMateSettings["windows"]) do
			_G("DPSMate_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(1,0,0,1)
		end
	else
		DPSMateSettings["sync"] = true
		DPSMateSettings["enable"] = true
		for _, val in pairs(DPSMateSettings["windows"]) do
			_G("DPSMate_"..val["name"].."_Head_Enable"):SetChecked(true)
			_G("DPSMate_"..val["name"].."_Head_Sync"):GetNormalTexture():SetVertexColor(0.67,0.83,0.45,1)
		end
	end
end



