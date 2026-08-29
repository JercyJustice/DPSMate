DPSMateFile("DPSMate_FriendlyFireTaken_3.lua")
-- Global Variables
-- Register the moodule
local tinsert = table.insert
local strformat = string.format
function DPSMate.Modules.FriendlyFireTaken:OpenDetails(obj, key, bool)
	if bool then
		DPSMate.Modules.DetailsFFT:UpdateCompare(obj, key, bool)
	else
		DPSMate.Modules.DetailsFFT:UpdateDetails(obj, key)
	end
end

function DPSMate.Modules.FriendlyFireTaken:OpenTotalDetails(obj, key)
	DPSMate.Modules.DetailsFFTTotal:UpdateDetails(obj, key)
end


