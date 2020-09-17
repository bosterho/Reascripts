--[[ 
* ReaScript Name: display marker text and color in video processor
* Version: 1.0
* Author: Ostertoaster
* Author URI: https://forum.cockos.com/member.php?u=129256
--]] 

region_name = "" ; prev_region_name = ""
marker_name = "" ; prev_marker_name = ""
prev_name = "" ; name = ""
red_slot = 100 ; green_slot = 101 ; blue_slot = 102 ;
red = 0 ; green = 0 ; blue = 0 ;


retval, retvals_csv = reaper.GetUserInputs("Options", 2, "show regions,show markers", "1,1")
if retval == false or retvals_csv == "0,0" then goto exit end
retvals_csv = retvals_csv .. ",0,0" -- don't understand %s*(.-), need to fix this some other time.
local show_regions, show_markers = retvals_csv:match("%s*(.-),%s*(.-),%s*(.-),%s*(.-)")
if show_markers == "1" then show_markers = true else show_markers = false end
if show_regions == "1" then show_regions = true else show_regions = false end

reaper.gmem_attach('markers')
function loop()
	if reaper.GetPlayState() ~= 0 then
		position = reaper.GetPlayPositionEx(0) + 0.75 -- fix latency
	else
		position = reaper.GetCursorPositionEx(0)
	end
	if isrgn == false then region_name = ""	end
	markeridx, regionidx = reaper.GetLastMarkerAndCurRegion(0, position)
	if show_markers == true then
		marker_retval, _, _, _, marker_name, _, color = reaper.EnumProjectMarkers3(-1, markeridx)
		if marker_retval > 0 then 
			name = marker_name 
			red, green, blue = reaper.ColorFromNative(color)
		end
	end

	-- this overwrites name and color
	if show_regions == true then
		region_retval, isrgn, _, _, region_name, _, color = reaper.EnumProjectMarkers3(-1, regionidx)
		if region_retval > 0 then 
			name = region_name 
			red, green, blue = reaper.ColorFromNative(color)
		end
		if show_markers == false then -- without this, it wouldn't clear the text while in-between regions
			if region_retval == 0 then
				name = ""
				red = 0 ; green = 0; blue = 0
			end
		end
	end

	-- this is for the beginning of project, where you're not in either a region or a marker
	if marker_retval == 0 and region_retval == 0 then
		name = ""
	end

	-- write name and color to global memory
	reaper.gmem_write(red_slot, red) 
	reaper.gmem_write(green_slot, green) 
	reaper.gmem_write(blue_slot, blue) 
	if name ~= prev_name then
		reaper.gmem_write(0, name:len())
		for i = 1, name:len() do
			reaper.gmem_write(i, string.byte(name:sub(i,i)))
		end
	end
	prev_name = name

	reaper.runloop(loop)
	::exit::
end
loop()
::exit::
