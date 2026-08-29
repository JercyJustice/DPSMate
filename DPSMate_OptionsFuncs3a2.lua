DPSMateFile("DPSMate_OptionsFuncs3a2.lua")
DPSMateMark("opt:FUNCS3a2")
-- Teil 3 der Options-Funktionen. Aufgeteilt, weil der Client diese Datei
-- als Ganzes nicht ausfuehrt; aufgeteilt kommt der Grossteil durch.
DPSMateOptState = DPSMateOptState or { LastPopUp = 0, TimeToNextPopUp = 1, PartyNum = 0, LastPartyNum = 0 }
if DPSMateOptState.SelectedChannel == nil then DPSMateOptState.SelectedChannel = DPSMate.L["raid"] end
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local strgfind = string.gfind

function DPSMate.Options:SumGraphData()
	for i=1,2 do
		-- Damage done
		for k,v in DPSMateDamageDone[i] do
			DPSMateDamageDone[i][k]["i"][1] = DPSMate:GetSummarizedTable(v["i"][1])
		end
		
		-- EDT
		for k,v in DPSMateEDT[i] do
			for key, var in v do 
				DPSMateEDT[i][k][key]["i"][1] = DPSMate:GetSummarizedTable(var["i"][1])
			end
		end
		
		-- EDD
		for k,v in DPSMateEDD[i] do
			for key, var in v do 
				DPSMateEDD[i][k][key]["i"][1] = DPSMate:GetSummarizedTable(var["i"][1])
			end
		end
		
		-- Damage taken
		for k,v in DPSMateDamageTaken[i] do
			DPSMateDamageTaken[i][k]["i"][1] = DPSMate:GetSummarizedTable(v["i"][1])
		end
		
		-- Ehealing
		for k,v in DPSMateEHealing[i] do
			DPSMateEHealing[i][k]["i"][2] = DPSMate:GetSummarizedTable(v["i"][2])
		end
		
		-- Thealing
		for k,v in DPSMateTHealing[i] do
			DPSMateTHealing[i][k]["i"][2] = DPSMate:GetSummarizedTable(v["i"][2])
		end
		
		-- Overhealing
		for k,v in DPSMateOverhealing[i] do
			DPSMateOverhealing[i][k]["i"][2] = DPSMate:GetSummarizedTable(v["i"][2])
		end
		
		-- Ehealing taken
		for k,v in DPSMateEHealingTaken[i] do
			DPSMateEHealingTaken[i][k]["i"][2] = DPSMate:GetSummarizedTable(v["i"][2])
		end
		
		-- Thealing taken
		for k,v in DPSMateHealingTaken[i] do
			DPSMateHealingTaken[i][k]["i"][2] = DPSMate:GetSummarizedTable(v["i"][2])
		end
	end
end

