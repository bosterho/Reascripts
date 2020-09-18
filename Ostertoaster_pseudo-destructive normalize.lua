--[[ 
* ReaScript Name: Ostertoaster_pseudo-destructive normalize
* Version: 1.0
* Author: Ostertoaster
* Author URI: https://forum.cockos.com/member.php?u=129256
--]] 

original_path = ""
applied_path = ""
function get_filename_for_selected_take_of_item(i)
	--  select only item at i
	for s = 0, num_selected_items - 1 do
		reaper.SetMediaItemSelected(item_array[s], false)
	end
	reaper.SetMediaItemSelected(item_array[i], true)

	local item = item_array[i]
	local curtake = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
	local take = reaper.GetTake(item, curtake)
	local pcm_source = reaper.GetMediaItemTake_Source(take)
	local filenamebuf = ""
	local filenamebuf = reaper.GetMediaSourceFileName(pcm_source, filenamebuf)
	filenamebuf = filenamebuf:match("(.+)%..+") -- remove extension
	filenamebuf = filenamebuf:gsub("\\", "/") -- switch to forward slashes
	return filenamebuf, pcm_source, take
end

-- need to put items in array so that when only one is selected, you can still iterate through them
item_array = {}
num_selected_items = reaper.CountSelectedMediaItems(-1)
for i = 0, num_selected_items - 1 do
	item_array[i] = reaper.GetSelectedMediaItem(-1, i)
end

for i = 0, num_selected_items - 1 do
	original_path, original_source, original_take = get_filename_for_selected_take_of_item(i)
	reaper.Main_OnCommand(40108, 0) -- Item properties: Normalize items
	reaper.Main_OnCommand(40209, 0) -- Item: Apply track/take FX to items
	applied_path, applied_source, applied_take = get_filename_for_selected_take_of_item(i)


	reaper.CF_SetMediaSourceOnline(original_source, false)
	local retval = nil
	local counter = 0
	while retval == nil do
		original_path_incremented = original_path .. "-orig_" .. tostring(counter) .. ".wav"
		retval = os.rename(original_path .. ".wav", original_path_incremented)
		counter = counter + 1 
	end
	local renamed_original_source = reaper.PCM_Source_CreateFromFile(original_path_incremented)
	reaper.SetMediaItemTake_Source(original_take, renamed_original_source)
				-- reaper.PCM_Source_Destroy(original_source) -- not sure this is needed???


	reaper.CF_SetMediaSourceOnline(applied_source, false)
	retval = os.rename(applied_path .. ".wav", original_path .. ".wav")
	normalized_source = reaper.PCM_Source_CreateFromFile(original_path .. ".wav")
	reaper.SetMediaItemTake_Source(applied_take, normalized_source)
				-- reaper.PCM_Source_Destroy(applied_source) -- not sure this is needed???
	local original_filename = original_path:match("^.+/(.+)$")

	--name the take so that it matches the name of the file it's using
	retval, stringNeedBig = reaper.GetSetMediaItemTakeInfo_String(applied_take, "P_NAME", original_filename .. ".wav", 1)

	-- don't know how to delete takes, but this works.
	reaper.Main_OnCommand(40126, 0) -- Take: Switch items to previous take
	reaper.Main_OnCommand(40129, 0) -- Take: Delete active take from items
	reaper.Main_OnCommand(40125, 0) -- Take: Switch items to next take
end

-- get back to original items selection
for s = 0, num_selected_items - 1 do
	reaper.SetMediaItemSelected(item_array[s], true)
end
