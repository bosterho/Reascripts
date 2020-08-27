--[[ 
* ReaScript Name: keyswitch chaser 
* Version: 8/27/2020
* Author: Ostertoaster
* Author URI: https://forum.cockos.com/member.php?u=129256
--]] 

function msg(m)
	reaper.ShowConsoleMsg(string.format('%s\n', m))
end

function add_jsfx()
	local num_tracks = reaper.CountTracks(-1)
	for trackidx = 0, num_tracks-1 do
	    local tr = reaper.GetTrack(-1, trackidx)
		retval, track_name = reaper.GetTrackName(tr)
		if string.find(string.lower(track_name), "keyswitch") ~= nil then
		    reaper.TrackFX_AddByName(tr, 'ks_chase_helper.jsfx', false, -1000) --   -1000 adds as first item in chain
			reaper.TrackFX_SetParam(tr, 0, 0, trackidx)
		end
	end
end

function clear_jsfx()
	local num_tracks = reaper.CountTracks(-1)
	for trackidx = 0, num_tracks-1 do
	    local tr = reaper.GetTrack(0, trackidx)
	    local chain_pos = reaper.TrackFX_AddByName(tr, 'ks_chase_helper.jsfx', false, 0) -- 0 only queries first instance of effect
	    if chain_pos >= 0 then
		    reaper.TrackFX_Delete(tr, chain_pos)
		    --note: for some reason if you have added the jsfx manually, it won't delete it here.
		    --also note: if the jsfx has to be in a subfolder of the effects folder for it to actually get deleted.
		end
	end
end

function count_midi_notes(take)
	local pitch = {}
	local n = 0
	local retval = true
	while retval == true do
		retval, selected, muted, startppqpos, endppqpos, chan, pitch[n], vel = reaper.MIDI_GetNote(take, n)
		n=n+1
	end
	local num_notes = n - 1
	if pitch[num_notes - 1] ~= nil then
		last_pitch = pitch[num_notes - 1]
	end
	return num_notes, last_pitch
end

function loop()
	if reaper.GetPlayState() ~= prev_play_state or
	math.abs(reaper.GetCursorPosition() - prev_play_pos) > reaper.TimeMap2_QNToTime(-1, 0.25) then
		-- check on track names
		num_tracks = reaper.CountTracks(-1)
		for trackidx = 0, num_tracks-1 do
		    tr = reaper.GetTrack(-1, trackidx)
		    retval, track_name = reaper.GetTrackName(tr)
			if string.find(string.lower(track_name), "keyswitch") ~= nil then
			    local chain_pos = reaper.TrackFX_AddByName(tr, 'ks_chase_helper.jsfx', false, 0) -- 0 only queries first instance of effect
				if chain_pos == -1 then
					clear_jsfx()
					add_jsfx()
				end
			else
			    local chain_pos = reaper.TrackFX_AddByName(tr, 'ks_chase_helper.jsfx', false, 0) -- 0 only queries first instance of effect
			    if chain_pos >= 0 then
				    reaper.TrackFX_Delete(tr, chain_pos)
				end
			end
		end

		num_tracks = reaper.CountTracks(-1)
		for t = 0, num_tracks - 1 do
			tr = reaper.GetTrack(0, t)
			retval, track_name = reaper.GetTrackName(tr)
			if string.find(string.lower(track_name), "keyswitch") ~= nil then
				-- count midi clips that have notes in them and put them in a table
				num_filled_media_items = 0
				num_mediaitems = reaper.CountTrackMediaItems(tr)
				for i = 0, num_mediaitems - 1 do
					item = reaper.GetTrackMediaItem(tr, i)
					take = reaper.GetTake(item, 0)
					num_notes, last_pitch = count_midi_notes(take)
					if num_notes > 0 then
						filled_media_items[num_filled_media_items] = item
						num_filled_media_items = num_filled_media_items + 1
					end
				end
				if num_filled_media_items > 0 then
					play_pos = reaper.GetCursorPosition()
					prev_item_pos = 0
					for i = 1, num_filled_media_items - 1 do
						item_pos = reaper.GetMediaItemInfo_Value(filled_media_items[i], "D_POSITION")
						prev_item_pos = reaper.GetMediaItemInfo_Value(filled_media_items[i-1], "D_POSITION")
						if play_pos > prev_item_pos and play_pos < item_pos then
							take = reaper.GetTake(filled_media_items[i-1], 0)
							num_notes, last_pitch = count_midi_notes(take)
							if last_pitch ~= nil then
								reaper.gmem_write(t, last_pitch)	
							end
						end
					end
					last_item = filled_media_items[num_filled_media_items-1]
					last_item_pos = reaper.GetMediaItemInfo_Value(last_item, "D_POSITION")
					if play_pos > last_item_pos then
						take = reaper.GetTake(last_item, 0)
						num_notes, last_pitch = count_midi_notes(take)
						if last_pitch ~= nil then
							reaper.gmem_write(t, last_pitch)
						end
					end
				end
			end
		end
	end
	prev_play_pos = reaper.GetCursorPosition()
	prev_play_state = reaper.GetPlayState()
	reaper.defer(loop)
end



gmem_name = 'chase_mem'
reaper.gmem_attach(gmem_name)

JS_keyswitch_helper = ''
JS_keyswitch_helper = JS_keyswitch_helper .. 'desc:ks_chase_helper \n'
JS_keyswitch_helper = JS_keyswitch_helper .. 'slider1:trackidx_slider=0<0,9,1>-trackidx \n'
JS_keyswitch_helper = JS_keyswitch_helper .. 'options:gmem=' .. gmem_name .. '\n'
JS_keyswitch_helper = JS_keyswitch_helper .. '@block \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '	pdc_delay = 200; \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '	pdc_midi = 1.0; \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '	gmem[trackidx_slider] != 0 ? ( \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '		midisend(0, $x90, gmem[trackidx_slider], 100); \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '		midisend(3000, $x80, gmem[trackidx_slider], 100); \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '		gmem[trackidx_slider] = 0; \n'
JS_keyswitch_helper = JS_keyswitch_helper .. '	); \n'
	
JS_Folder_Name = "/Effects/utility/"
JS_FX_Name = "ks_chase_helper.jsfx"

Res_Path = reaper.GetResourcePath()
File_Patch = JS_Folder_Name .. JS_FX_Name
Full_Path = Res_Path .. File_Patch
JS_FILE = io.open(Full_Path, "w")
io.output(JS_FILE):write(JS_keyswitch_helper)
io.close(JS_FILE)
		
timer = 0
prev_play_pos = 0
prev_item_pos = 0
filled_media_items = {}
num_filled_media_items = 0

clear_jsfx() --if the script errored last time, it won't clear keyswitch helpers. This clears them just in case.
add_jsfx()
loop()
reaper.atexit(clear_jsfx)
