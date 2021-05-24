num_tracks = reaper.CountSelectedTracks(0)
for i = 0, num_tracks-1 do
	tr = reaper.GetSelectedTrack(0, i)
	bits_set=tonumber('111111'..'00000',2)
	if reaper.GetMediaTrackInfo_Value(tr, 'I_RECINPUT') == 1024 then
		-- reaper.ShowConsoleMsg("audio track set to midi track")
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', 4096+bits_set) -- set input to all MIDI
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECMON', 1) -- monitor input
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 1) -- arm track
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECMODE',0) -- record MIDI out   
	else
		-- reaper.ShowConsoleMsg("midi track set to audio track")
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECINPUT', 1024) -- set input to all MIDI
		reaper.SetMediaTrackInfo_Value(tr, 'I_RECMON', 0) -- monitor input
		-- reaper.SetMediaTrackInfo_Value(tr, 'I_RECARM', 1) -- arm track
		-- reaper.SetMediaTrackInfo_Value(tr, 'I_RECMODE',0) -- record MIDI out   
	end
end