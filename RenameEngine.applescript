global XText
global UniqueNamer
global PathAnalyzer
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
	set oldLength to length of _oldstring
	
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		tell application "Finder"
			set oldName to name of an_item
		end tell
		set oldName to call method "normalizedString:" of oldName with parameter 3
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		if oldName ends with _oldstring then
			if oldLength > 1 then
				set newName to (text 1 thru (-1 - oldLength) of oldName) & _newstring
			else
				set newName to _newstring
			end if
			
			if newName is not oldName then
				change_name for an_item by newName
			end if
		end if
	end repeat
	return true
end replace_endding

on replace_beginning for a_list
	set oldLength to length of _oldstring
	
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set oldName to PathAnalyzer's name_of(an_item)
		set oldName to call method "normalizedString:" of oldName with parameter 3
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		if oldName starts with _oldstring then
			if oldLength > 1 then
				set newName to _newstring & (text (oldLength + 1) thru -1 of oldName)
			else
				set newName to _newstring
			end if
			if newName is not oldName then
				--if not is_same_unicode(newName, oldName) then
				change_name for an_item by newName
			end if
		end if
	end repeat
	return true
end replace_beginning

on replace_containing for a_list
	set oldLength to length of _oldstring
	
	store_delimiters() of XText
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set oldName to PathAnalyzer's name_of(an_item)
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		set oldName to call method "normalizedString:" of oldName with parameter 3
		if oldName contains _oldstring then
			set newName to replace of XText for oldName from _oldstring by _newstring
			if newName is not oldName then
				change_name for an_item by newName
			end if
		end if
	end repeat
	restore_delimiters() of XText
	return true
end replace_containing

on replace_regexp for a_list
	repeat with ith from 1 to length of a_list
		set an_item to item ith of a_list
		set oldName to PathAnalyzer's name_of(an_item)
		set newName to call method "regexReplace:withPattern:withString:" of _app_controller with parameters {oldName, _oldstring, _newstring}
		try
			get newName
		on error
			return false
		end try
		if newName is not oldName then
			change_name for an_item by newName
		end if
	end repeat
	return true
end replace_regexp

on change_name for an_item by a_name
	try
		tell application "Finder"
			set name of file an_item to a_name
		end tell
		--renameFile an_item to a_name
	on error errMsg number errn
		if errn is in {-37, -48} then -- -48 : same name  -37: invalid name
			set theLocation to PathAnalyzer's folder_of(an_item)
			set a_name to do of UniqueNamer about a_name at theLocation
			tell application "Finder"
				set name of file an_item to a_name
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