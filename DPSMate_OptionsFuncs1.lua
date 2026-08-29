DPSMateFile("DPSMate_OptionsFuncs1.lua")
DPSMateMark("opt:FUNCS1")
-- Teil 1 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:SelectRealtime(obj, kind)
	if kind then
		local key = obj.Key or 1
		DPSMateSettings["windows"][key]["realtime"] = kind
		if not _G(obj:GetName().."_RealTime") then
			local f = CreateFrame("Frame", obj:GetName().."_RealTime", obj, "DPSMate_RealTime")
			local g = DPSMate.Options.graph:CreateGraphRealtime(f:GetName().."_Graph",f,"BOTTOMRIGHT","BOTTOMRIGHT",-5,5,190,150)
			g:SetAutoScale(true)
			g:SetGridSpacing(1.0,10.0)
			g:SetYMax(120)
			g:SetXAxis(-11,-1)
			g:SetFilterRadius(1)
			g:SetBarColors({0.2,0.0,0.0,0.4},{1.0,0.0,0.0,1.0})
			g:SetScript("OnUpdate",function() 
				if DPSMate.DB.loaded and DPSMateSettings["windows"][key]["realtime"] then
					g:OnUpdate(g)
					g:AddTimeData(DPSMate.DB:GetAlpha(key)) 
				end
			end)
			f:Show()
			g:Show()
		else
			 _G(obj:GetName().."_RealTime"):Show()
		end
		DPSMate.Options.Dewdrop:Close()
	end
end

