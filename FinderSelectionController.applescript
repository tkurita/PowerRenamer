property FinderSelection : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
	end tell
end __load__

property _ : __load__(proxy() of application (get "PowerRenamerLib"))
property _selected_items : {}

on get_finderselection()
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
	set my _selected_items to a_list
	set path_list to {}
	repeat with an_item in a_list
		set end of path_list to POSIX path of an_item
	end repeat
	return path_list
end get_finderselection

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