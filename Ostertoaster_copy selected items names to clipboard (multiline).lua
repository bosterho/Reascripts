--[[ 
* ReaScript Name: keyswitch chaser 
* Version: 1.0
* Author: Ostertoaster
--]] 

reaper.Undo_BeginBlock();
selected_items = {}
num_selected_items = reaper.CountSelectedMediaItems(-1)
for i = 0, num_selected_items-1 do
	selected_items[i] = reaper.GetSelectedMediaItem(-1, i)
end

clipboard_str = ""
for i = 0, num_selected_items-1 do
	curtake = reaper.GetMediaItemInfo_Value(selected_items[i],"I_CURTAKE")
	local curtake = reaper.GetActiveTake(selected_items[i]);
	local _,stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(curtake,"P_NAME","",0);
	clipboard_str = clipboard_str .. stringNeedBig .. "\n"
end
reaper.CF_SetClipboard(clipboard_str)
reaper.Undo_EndBlock('copy selected items names to clipboard (multiline)',-1);

