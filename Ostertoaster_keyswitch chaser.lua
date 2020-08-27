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
		    reaper.TrackFX_AddByName(tr, 'keyswitch_chaser_helper.jsfx', false, -1000) --   -1000 adds as first item in chain
			reaper.TrackFX_SetParam(tr, 0, 0, trackidx)
		end
	end
end

function clear_jsfx()
	local num_tracks = reaper.CountTracks(-1)
	for trackidx = 0, num_tracks-1 do
	    local tr = reaper.GetTrack(0, trackidx)
	    local chain_pos = reaper.TrackFX_AddByName(tr, 'keyswitch_chaser_helper.jsfx', false, 0) -- 0 only queries first instance of effect
	    if chain_pos >= 0 then
		    reaper.TrackFX_Delete(tr, chain_pos)
		    --note: for some reason if you have added the jsfx manually, it won't delete it here.
		    --also note: if the jsfx has to be in a subfolder of the effects folder for it to actually get deleted.
		end
	end
end

function loop()
	if reaper.GetPlayState() ~= prev_play_state or
	math.abs(reaper.GetCursorPosition() - prev_pos) > reaper.TimeMap2_QNToTime(-1, 0.25) then
		-- check on track names whenever you play or pause.
		num_tracks = reaper.CountTracks(-1)
		for trackidx = 0, num_tracks-1 do
		    tr = reaper.GetTrack(-1, trackidx)
		    retval, track_name = reaper.GetTrackName(tr)
			if string.find(string.lower(track_name), "keyswitch") ~= nil then
			    local chain_pos = reaper.TrackFX_AddByName(tr, 'keyswitch_chaser_helper.jsfx', false, 0) -- 0 only queries first instance of effect
				if chain_pos == -1 then
					clear_jsfx()
					add_jsfx()
				end
			else
			    local chain_pos = reaper.TrackFX_AddByName(tr, 'keyswitch_chaser_helper.jsfx', false, 0) -- 0 only queries first instance of effect
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
				num_mediaitems = reaper.CountTrackMediaItems(tr)
				play_pos = reaper.GetCursorPosition()
				prev_pos = 0
				prev_length = 0
				prev_item = reaper.GetTrackMediaItem(tr, 0)
				if num_mediaitems > 0 then
					for i = 1, num_mediaitems - 1 do
						item = reaper.GetTrackMediaItem(tr, i)
						pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
						length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
						if play_pos > prev_pos and play_pos < pos then
							take = reaper.GetTake(prev_item, 0)
							--find last note in midi clip
							n=0
							retval = true
							while retval == true do
								retval, selected, muted, startppqpos, endppqpos, chan, pitch[n], vel = reaper.MIDI_GetNote(take, n)
								n=n+1
							end
							reaper.gmem_write(t, pitch[n-2])	
						end
						prev_pos = pos
						prev_length = length
						prev_item = item
					end
					--this takes care of the last keyswitch clip on each track
					if play_pos > prev_pos then
						take = reaper.GetTake(prev_item, 0)
						n=0
						retval = true
						while retval == true do
							retval, selected, muted, startppqpos, endppqpos, chan, pitch[n], vel = reaper.MIDI_GetNote(take, n)
							n=n+1
						end
						reaper.gmem_write(t, pitch[n-2])	
					end
				end
			end
		end
	end
	prev_pos = reaper.GetCursorPosition()
	prev_play_state = reaper.GetPlayState()
	reaper.defer(loop)
end

reaper.gmem_attach('chase_mem')
pitch = {}
timer = 0
prev_pos = 0

-- reaper.Undo_BeginBlock()
clear_jsfx() --if the script errored last time, it won't clear keyswitch helpers. This clears them just in case.
add_jsfx()
loop()
reaper.atexit(clear_jsfx)
-- reaper.Undo_EndBlock(undo_text..track_name, 0)
