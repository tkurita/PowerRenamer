property FileSorter : module
property _ : boot (module loader of application (get "PowerRenamerLib")) for me

on get_finderselection_tiger()
	tell application "Finder"
		set a_list to selection
	end tell
	repeat with an_item in a_list
		set contents of an_item to an_item as Unicode text
	end repeat
	return a_list
end get_finderselection_tiger

on get_finderselection_leopard()
	set text item delimiters to {return}
	tell application "Finder"
		set pathtable to selection as Unicode text
	end tell
	set a_list to every paragraph of pathtable
	return a_list
end get_finderselection_leopard

property get_finderselection : get_finderselection_tiger

on initialize()
	considering numeric strings
		set is_leopard to (AppleScript's version as Unicode text) is greater than or equal to "2"
	end considering
	if is_leopard then
		set get_finderselection to get_finderselection_leopard
	else
		set get_finderselection to get_finderselection_tiger
	end if
end initialize

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