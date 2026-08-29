DPSMateFile("DPSMate_OptionsFuncs3b.lua")
DPSMateMark("opt:FUNCS3b")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:ActivateTestMode()
	if self.TestMode then
		self.TestMode = false
		DPSMate:SetStatusBarValue()
	else
		self.TestMode = true
		for k,c in DPSMateSettings.windows do
			if DPSMateSettings["showtotals"] then
				_G("DPSMate_"..c["name"].."_ScrollFrame_Child_Total_Name"):SetText("Total")
				_G("DPSMate_"..c["name"].."_ScrollFrame_Child_Total_Value"):SetText("3000000")
			end
			for i=1, 40 do
				local statusbar, name, value, texture, p = _G("DPSMate_"..c["name"].."_ScrollFrame_Child_StatusBar"..i), _G("DPSMate_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Name"), _G("DPSMate_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Value"), _G("DPSMate_"..c["name"].."_ScrollFrame_Child_StatusBar"..i.."_Icon"), ""
				_G("DPSMate_"..c["name"].."_ScrollFrame_Child"):SetHeight((i+1)*(c["barheight"]+c["barspacing"]))
				
				statusbar:SetStatusBarColor(0.78,0.61,0.43, 1)
				
				if c["ranks"] then p=i..". " else p="" end
				name:SetText(p.."Test "..i)
				value:SetText("100000")
				texture:SetTexture("Interface\\AddOns\\DPSMate\\images\\class\\warrior")
				statusbar:SetValue(100)
				
				statusbar.user = nil
				statusbar:Show()
			end
		end
	end
end

function DPSMate.Options:ToggleFilterClass(key, class)
	if DPSMateSettings["windows"][key]["filterclasses"][class] then
		DPSMateSettings["windows"][key]["filterclasses"][class] = false
	else
		DPSMateSettings["windows"][key]["filterclasses"][class] = true
	end
	DPSMate:SetStatusBarValue()
end

function DPSMate.Options:SimpleToggle(key, opt)
	if DPSMateSettings["windows"][key][opt] then
		DPSMateSettings["windows"][key][opt] = false
	else
		DPSMateSettings["windows"][key][opt] = true
	end
	DPSMate:SetStatusBarValue()
end

