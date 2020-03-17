property FileSorter : "@module"
property _only_local_ : true
property _ : script "ModuleLoader"'s setup(me)

on get_finderselection()
	set text item delimiters to {return}
	with timeout of 3600 seconds
		tell application "Finder"
			set pathtable to selection as Unicode text
		end tell
	end timeout
	set a_list to every paragraph of pathtable
	return a_list
end get_finderselection

on initialize()
end initialize

on sorted_finderselection()
	script SorterDelegate
		on target_items_at(a_location)
			return get_finderselection()
		end target_items_at
	end script
	with timeout of 3600 seconds
		set a_list to FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
	end timeout
	return a_list
end sorted_finderselection

on sub_process_rename(pathes, newnames)
	repeat with n from 1 to length of pathes
		set an_item to item n of pathes
		tell application "Finder"
			set name of item an_item to (item n of newnames)
		end tell
	end repeat
end sub_process_rename

on process_rename(pathes, newnames, ignore_responses)
	if ignore_responses then
		-- log "ignoring FInder"
		ignoring application responses
			sub_process_rename(pathes, newnames)
		end ignoring
	else
		-- log "not ignoring FInder"
		sub_process_rename(pathes, newnames)
	end if
end process_rename

on select_items(a_list)
	repeat with an_item in a_list
		tell application "Finder"
			set contents of an_item to (item an_item)
		end tell
	end repeat
	with timeout of 3600 seconds
		tell application "Finder"
			--select a_list
			set selection to a_list
		end tell
	end timeout
end select_items
