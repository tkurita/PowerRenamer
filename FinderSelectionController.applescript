property FinderSelection : missing value
property FileSorter : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
		set FileSorter to load("FileSorter")
	end tell
end __load__

--property _ : __load__(proxy_with({autocollect:true}) of application (get "PowerRenamerLib"))
property _ : __load__(proxy() of application (get "PowerRenamerLib"))
property _selected_items : {}

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

on convert_to_posix_path()
	set path_list to {}
	if my _selected_items is missing value then
		set my _selected_items to {}
	end if
	repeat with an_item in my _selected_items
		set end of path_list to POSIX path of an_item
	end repeat
	return path_list
end convert_to_posix_path

on get_finderselection()
	set my _selected_items to sub_finderselection()
	return convert_to_posix_path()
end get_finderselection

on sorted_finderselection()
	script SorterDelegate
		on target_items_at(a_location)
			return sub_finderselection()
		end target_items_at
	end script
	set my _selected_items to FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
	return convert_to_posix_path()
end sorted_finderselection

on selected_items()
	return my _selected_items
end selected_items

on process_rename(oldnames, newnames)
	repeat with n from 1 to length of my _selected_items
		set newname to item n of newnames
		set oldname to item n of oldnames
		if newname is not oldname then
			tell application "Finder"
				set name of item (item n of my _selected_items) to item n of newnames
			end tell
		end if
	end repeat
end process_rename

on select_items(a_list)
	repeat with an_item in a_list
		set contents of an_item to (POSIX file an_item) as alias
	end repeat
	set my _selected_items to a_list
	tell application "Finder"
		--select a_list
		set selection to a_list
	end tell
end select_items