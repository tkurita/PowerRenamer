property FinderSelection : missing value
property FileSorter : missing value
property XList : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
		set FileSorter to load("FileSorter")
		set XList to load("XList")
	end tell
end __load__

--property _ : __load__(proxy_with({autocollect:true}) of application (get "PowerRenamerLib"))
property _ : __load__(proxy() of application (get "PowerRenamerLib"))

on sub_finderselection()
	set a_picker to FinderSelection's make_for_item()
	tell a_picker
		set_use_insertion_location(false)
		set_resolve_alias(false)
		set_use_chooser(false)
	end tell
	try
		set a_list to a_picker's get_selection()
	on error msg number errno
		if errno is -128 then
			return {}
		else
			error msg number errno
		end if
	end try
	return a_list
end sub_finderselection

on convert_to_posix_path(a_list)
	if a_list is missing value then
		return {}
	end if
	set path_list to {}
	set a_xlist to XList's make_with(a_list)
	repeat while (a_xlist's has_next())
		set an_item to a_xlist's next()
		set end of path_list to POSIX path of an_item
	end repeat
	return path_list
end convert_to_posix_path

on get_finderselection()
	set a_list to sub_finderselection()
	return convert_to_posix_path(a_list)
end get_finderselection

on sorted_finderselection()
	script SorterDelegate
		on target_items_at(a_location)
			return sub_finderselection()
		end target_items_at
	end script
	set a_list to FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
	return convert_to_posix_path(a_list)
end sorted_finderselection

on sub_process_rename(pathes, newnames)
	repeat with n from 1 to length of pathes
		set an_item to POSIX file (item n of pathes)
		tell application "Finder"
			set name of item (an_item as Unicode text) to (item n of newnames)
		end tell
	end repeat
end sub_process_rename

on process_rename(pathes, newnames)
	tell user defaults
		set ignoring_flag to contents of default entry "ignoringFinderResponses"
	end tell
	if ignoring_flag then
		ignoring application responses
			sub_process_rename(pathes, newnames)
		end ignoring
	else
		sub_process_rename(pathes, newnames)
	end if
end process_rename

on select_items(a_list)
	repeat with an_item in a_list
		set a_file to POSIX file an_item
		tell application "Finder"
			set contents of an_item to (item (a_file as Unicode text))
		end tell
		-- set contents of an_item to (POSIX file an_item) as alias
	end repeat
	tell application "Finder"
		--select a_list
		set selection to a_list
	end tell
end select_items