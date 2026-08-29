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
			local prefix = "DPSMate_"..c["name"]
			local child = _G(prefix.."_ScrollFrame_Child")
			local indent = 2
			if c["classicons"] then indent = c["barheight"] or 19 end
			local maxBars = 40
			if DPSMate.MaxVisibleBars then maxBars = DPSMate:MaxVisibleBars(c) end
			if DPSMateSettings["showtotals"] then
				local tn = _G(prefix.."_ScrollFrame_Child_Total_Name")
				local tv = _G(prefix.."_ScrollFrame_Child_Total_Value")
				if tn then tn:SetText("Total") end
				if tv then tv:SetText("3000000") end
			end
			local i
			for i=1, 40 do
				local statusbar = _G(prefix.."_ScrollFrame_Child_StatusBar"..i)
				local name = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Name")
				local value = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Value")
				local texture = _G(prefix.."_ScrollFrame_Child_StatusBar"..i.."_Icon")
				if not statusbar then break end
				if i > maxBars then
					statusbar:Hide()
				else
					if child then child:SetHeight((i+1)*(c["barheight"]+c["barspacing"])) end
					statusbar:SetStatusBarColor(0.78,0.61,0.43, 1)
					local p = ""
					if c["ranks"] then p=i..". " end
					if name then name:SetText(p.."Test "..i) end
					if value then value:SetText("100000") end
					if texture then texture:SetTexture("Interface\\AddOns\\DPSMate\\images\\class\\warrior") end
					statusbar:SetValue(100)
					statusbar.user = nil
					statusbar:Show()
					local bw = child and child.GetWidth and child:GetWidth() or statusbar:GetWidth()
					DPSMate:LayoutBarText(statusbar, bw, indent)
				end
			end
			local frame = _G(prefix)
			if frame and DPSMate.LayoutHeadTitle then DPSMate:LayoutHeadTitle(frame) end
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

