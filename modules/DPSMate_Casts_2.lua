DPSMateFile("DPSMate_Casts_2.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.Casts:GetSettingValues(arr, cbt, k)
	local name, value, perc, sortedTable, total, a, p, strt = {}, {}, {}, {}, 0, 0, "", {[1]="",[2]=""}
	
	sortedTable, total, a = DPSMate.Modules.Casts:GetSortedTable(arr, k)
	for cat, val in sortedTable do
		local dmg, tot, sort = val, total, sortedTable[1]
		if dmg==0 then break end;
		local str = {[1]="",[2]="",[3]=""}
		if DPSMateSettings["columnscasts"][1] then str[1] = " "..DPSMate:Commas(dmg, k)..p; strt[2] = DPSMate:Commas(tot, k)..p end
		if DPSMateSettings["columnscasts"][2] then str[3] = " ("..strformat("%.1f", 100*dmg/tot).."%)" end
		tinsert(name, a[cat])
		tinsert(value, str[2]..str[1]..str[3])
		tinsert(perc, 100*(dmg/sort))
	end
	return name, value, perc, strt
end

function DPSMate.Modules.Casts:ShowTooltip(user,k)
	local a,b,c = DPSMate.Modules.Casts:EvalTable(DPSMateUser[user], k)
	if DPSMateSettings["informativetooltips"] then
		for i=1, DPSMateSettings["subviewrows"] do
			if not c[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMate:GetAbilityById(c[i]),a[i].." ("..strformat("%.2f", 100*a[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

