global XText
--global UniqueNamer
global PathAnalyzer
global XFile
global _app_controller

property _oldstring : ""
property _newstring : ""

on set_new_text(a_text)
	set my _newstring to a_text
end set_new_text

on set_old_text(a_text)
	set my _oldstring to a_text
end set_old_text

on replace_endding for a_list
	set old_length to length of _oldstring
	
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set old_name to PathAnalyzer's name_of(an_item)
		set old_name to call method "normalizedString:" of old_name with parameter 3
		if old_name ends with _oldstring then
			if old_length > 0 then
				set new_name to (text 1 thru (-1 - old_length) of old_name) & _newstring
			else
				set new_name to old_name & _newstring
			end if
			
			if new_name is not old_name then
				change_name for an_item by new_name
			end if
		end if
	end repeat
	return true
end replace_endding

on replace_beginning for a_list
	set old_length to length of _oldstring
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set old_name to PathAnalyzer's name_of(an_item)
		set old_name to call method "normalizedString:" of old_name with parameter 3
		if old_name starts with _oldstring then
			if old_length > 0 then
				set new_name to _newstring & (text (old_length + 1) thru -1 of old_name)
			else
				set new_name to _newstring & old_name
			end if
			if new_name is not old_name then
				change_name for an_item by new_name
			end if
		end if
	end repeat
	return true
end replace_beginning

on replace_containing for a_list
	set old_length to length of _oldstring
	if old_length < 1 then
		return false
	end if
	store_delimiters() of XText
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set old_name to PathAnalyzer's name_of(an_item)
		set old_name to call method "normalizedString:" of old_name with parameter 3
		if old_name contains _oldstring then
			set new_name to replace of XText for old_name from _oldstring by _newstring
			if new_name is not old_name then
				change_name for an_item by new_name
			end if
		end if
	end repeat
	restore_delimiters() of XText
	return true
end replace_containing

on replace_regexp for a_list
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set old_name to PathAnalyzer's name_of(an_item)
		--set new_name to call method "stringByReplacingOccurrencesOfRegex:withString:" of old_name with parameters {_oldstring, _newstring}
		set new_name to call method "regexReplace:withPattern:withString:" of _app_controller with parameters {old_name, _oldstring, _newstring}
		try
			get new_name
		on error
			return false
		end try
		if new_name is not old_name then
			change_name for an_item by new_name
		end if
	end repeat
	return true
end replace_regexp

on change_name for an_item by a_name
	try
		tell application "Finder"
			set name of item an_item to a_name
		end tell
	on error errMsg number errn
		if errn is in {-37, -48} then -- -48 : same name  -37: invalid name
			set a_location to PathAnalyzer's folder_of(an_item)
			set new_xfile to XFile's make_with(a_location)'s unique_child(a_name)
			--set a_name to do of UniqueNamer about a_name at a_location
			tell application "Finder"
				set name of item an_item to new_xfile's item_name()
			end tell
		else
			display dialog (errn as string) & return & errMsg
		end if
	end try
end change_name

on forceQuit about msg
	beep
	activate
	if (msg is not "Skip") then
		display dialog msg buttons {"OK"} default button "OK" with icon 0 -- stop icon
	end if
	error number -128
end forceQuit