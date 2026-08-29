DPSMateFile("DPSMate_HealingAndAbsorbs_2.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.HealingAndAbsorbs:GetSettingValues(arr, cbt, k,ecbt)
	local name, value, perc, sortedTable, total, a, p, strt = {}, {}, {}, {}, 0, 0, "", {[1]="",[2]=""}
	if DPSMateSettings["windows"][k]["numberformat"] == 2 or DPSMateSettings["windows"][k]["numberformat"] == 4 then p = "K" end
	sortedTable, total, a = DPSMate.Modules.HealingAndAbsorbs:GetSortedTable(arr, k)
	for cat, val in pairs(sortedTable) do
		local va, tot, sort, varea, totr, sortr = DPSMate:FormatNumbers(val, total, sortedTable[1], k)
		if varea==0 then break end; if varea<=10000 then p = "" end
		local str = {[1]="",[2]="",[3]="",[4]=""}
		local pname = DPSMate:GetUserById(a[cat])
		if DPSMateSettings["columnshab"][1] then str[1] = " "..DPSMate:Commas(va, k)..p; strt[2] = DPSMate:Commas(tot, k)..p end
		if DPSMateSettings["columnshab"][3] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateSettings["columnshab"][2] then str[3] = "("..strformat("%.1f", va/cbt)..")"; strt[1] = "("..strformat("%.1f", tot/cbt)..")" end
		if DPSMateSettings["columnshab"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(name, pname)
		tinsert(value, str[3]..str[1]..str[4]..str[2])
		tinsert(perc, 100*(varea/sortr))
	end
	return name, value, perc, strt
end

