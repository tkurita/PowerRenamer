property FinderSelection : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
	end tell
end __load__

property _ : __load__(proxy() of application (get "PowerRenamerLib"))

on run
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
	repeat with an_item in a_list
		set contents of an_item to POSIX path of an_item
	end repeat
	return a_list
end run