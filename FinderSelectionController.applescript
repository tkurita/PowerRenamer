property FileSorter : missing value
property XList : missing value

on __load__(loader)
	tell loader
		set FileSorter to load("FileSorter")
		set XList to load("XList")
	end tell
end __load__

--property _ : __load__(proxy_with({autocollect:true}) of application (get "PowerRenamerLib"))
property _ : __load__(proxy() of application (get "PowerRenamerLib"))

on get_finderselection()
	--log "start get_finderselection"
	set text item delimiters to {return}
	tell application "Finder"
		set pathtable to selection as Unicode text
	end tell
	set a_list to every paragraph of pathtable
	--log "end get_finderselection"
	return a_list
end get_finderselection

on sorted_finderselection()
	script SorterDelegate
		on target_items_at(a_location)
			return get_finderselection()
		end target_items_at
	end script
	return FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
end sorted_finderselection

on sub_process_rename(pathes, newnames)
	repeat with n from 1 to length of pathes
		set an_item to item n of pathes
		tell application "Finder"
			set name of item an_item to (item n of newnames)
		end tell
	end repeat
end sub_process_rename

on process_rename(pathes, newnames)
	tell user defaults
		set ignoring_flag to contents of default entry "ignoringFinderResponses"
	end tell
	if ignoring_flag then
		--log "ignoring FInder"
		ignoring application responses
			sub_process_rename(pathes, newnames)
		end ignoring
	else
		--log "not ignoring FInder"
		sub_process_rename(pathes, newnames)
	end if
end process_rename

on select_items(a_list)
	repeat with an_item in a_list
		tell application "Finder"
			set contents of an_item to (item an_item)
		end tell
	end repeat
	tell application "Finder"
		--select a_list
		set selection to a_list
	end tell
end select_items