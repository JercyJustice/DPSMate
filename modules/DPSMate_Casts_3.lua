DPSMateFile("DPSMate_Casts_3.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.Casts:OpenDetails(obj, key, bool)
	if bool then
		DPSMate.Modules.DetailsCasts:UpdateCompare(obj, key, bool)
	else
		DPSMate.Modules.DetailsCasts:UpdateDetails(obj, key)
	end
end

function DPSMate.Modules.Casts:OpenTotalDetails(obj, key)
	DPSMate.Modules.DetailsCastsTotal:UpdateDetails(obj, key)
end

