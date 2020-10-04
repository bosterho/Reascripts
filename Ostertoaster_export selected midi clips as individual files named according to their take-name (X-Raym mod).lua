 -- Modified from X-Raym's action: Insert CC linear ramp events between selected ones if consecutive

selected = false -- new notes are selected


-- Console Message
function Msg(g)
	reaper.ShowConsoleMsg(tostring(g).."\n")
end

function GetCC(take, cc)
	return cc.selected, cc.muted, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3
end

function main() -- local (i, j, item, take, track)
	typebuf = ""
	initialFolder = reaper.GetExtState("export selected midi clips folder", 0)
	retval, initialFolder = reaper.JS_Dialog_BrowseForFolder("Choose Folder to save Selected Midi Clips in", initialFolder)
	if retval == 0 then goto exit end
	if initialFolder == "" then goto exit end
	if retval == -1 then reaper.ShowConsoleMsg("error setting save folder") ; goto exit end
	reaper.SetExtState("export selected midi clips folder", 0, initialFolder, true)

	num_selected_items = reaper.CountSelectedMediaItems(-1)
	reaper.Main_OnCommand(40639, 0) -- Take: Duplicate active take

	for i = 0, num_selected_items-1 do
		item = reaper.GetSelectedMediaItem(-1, i)
		cur_take = reaper.GetMediaItemInfo_Value(item, "I_CURTAKE")
		take = reaper.GetTake(item, cur_take)
		take_name = reaper.GetTakeName(take)
		fn = initialFolder .. "/" .. take_name .. ".mid"
		src = reaper.GetMediaItemTake_Source(take)
		typebuf = reaper.GetMediaSourceType(src, typebuf)
		if typebuf ~= "MIDI" then reaper.MB("This only works on midi items.", "wrong item type", 0); goto exit end

		-- interpolate CC points
		retval, notes, ccs, sysex = reaper.MIDI_CountEvts(take)
		if ccs > 0 then

			-- Store CC by types
			midi_cc = {}
			for j = 0, ccs - 1 do
				cc = {}
				retval, cc.selected, cc.muted, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3 = reaper.MIDI_GetCC(take, j)
				if not midi_cc[cc.msg2] then midi_cc[cc.msg2] = {} end
				table.insert(midi_cc[cc.msg2], cc)
			end

			-- Look for consecutive CC
			cc_events = {}
			cc_events_len = 0

			for key, val in pairs(midi_cc) do

				-- GET SELECTED NOTES (from 0 index)
				for k = 1, #val - 1 do

					a_selected, a_muted, a_ppqpos, a_chanmsg, a_chan, a_msg2, a_msg3 = GetCC(take, val[k])
					b_selected, b_muted, b_ppqpos, b_chanmsg, b_chan, b_msg2, b_msg3 = GetCC(take, val[k+1])

					-- INSERT NEW CCs
					interval = (b_ppqpos - a_ppqpos) / 32  -- CHANGED FROM ORIGINAL, so it just puts points every 32 ppq
					time_interval = (b_ppqpos - a_ppqpos) / interval

					for z = 1, interval - 1 do

						cc_events_len = cc_events_len + 1
						cc_events[cc_events_len] = {}

						c_ppqpos = a_ppqpos + time_interval * z
						c_msg3 = math.floor( ( (b_msg3 - a_msg3) / interval * z + a_msg3 )+ 0.5 )

						cc_events[cc_events_len].ppqpos = c_ppqpos
						cc_events[cc_events_len].chanmsg = a_chanmsg
						cc_events[cc_events_len].chan = a_chan
						cc_events[cc_events_len].msg2 = a_msg2
						cc_events[cc_events_len].msg3 = c_msg3

					end
				end
			end

			-- Insert Events
			for i, cc in ipairs(cc_events) do
				reaper.MIDI_InsertCC(take, selected, false, cc.ppqpos, cc.chanmsg, cc.chan, cc.msg2, cc.msg3)
			end
		end

		-- export midi items
		retval = reaper.CF_ExportMediaSource(src, fn)
	end
	reaper.Main_OnCommand(40129, 0) -- Take: Delete active take from items
	reaper.Main_OnCommand(41348, 0) -- Item: Remove all empty take lanes

	::exit::
end

-- RUN ---------------------
	reaper.Undo_BeginBlock() -- Begining of the undo block. Leave it at the top of your main function.

	main() -- Execute your main function
	reaper.UpdateArrange() -- Update the arrangement (often needed)

	reaper.Undo_EndBlock("Insert CC linear ramp events between selected ones if consecutive", -1) -- End of the undo block. Leave it at the bottom of your main function.
