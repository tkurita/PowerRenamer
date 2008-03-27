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

on replaceEnd for theList
	set oldLength to length of _oldstring
	
	repeat with ith from 1 to length of theList
		set an_item to item ith of theList
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
				setName for an_item by newName
			end if
		end if
	end repeat
	return true
end replaceEnd

on replaceBeginning for theList
	set oldLength to length of _oldstring
	
	repeat with ith from 1 to length of theList
		set an_item to item ith of theList
		tell application "Finder"
			set oldName to name of an_item
		end tell
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
				setName for an_item by newName
			end if
		end if
	end repeat
	return true
end replaceBeginning

on replaceContain for theList
	set oldLength to length of _oldstring
	
	store_delimiters() of XText
	repeat with ith from 1 to length of theList
		set an_item to item ith of theList
		tell application "Finder"
			set oldName to name of an_item
		end tell
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		set oldName to call method "normalizedString:" of oldName with parameter 3
		if oldName contains _oldstring then
			set newName to replace of XText for oldName from _oldstring by _newstring
			if newName is not oldName then
				setName for an_item by newName
			end if
		end if
	end repeat
	restore_delimiters() of XText
	return true
end replaceContain

on replaceRegularExp for theList
	repeat with ith from 1 to length of theList
		set an_item to item ith of theList
		set oldName to PathAnalyzer's name_of(an_item)
		set newName to call method "regexReplace:withPattern:withString:" of _app_controller with parameters {oldName, _oldstring, _newstring}
		--set newName to call method "replaceForPattern:withString:" of oldName with parameters {_oldstring, _newstring}
		try
			get newName
		on error
			return false
		end try
		if newName is not oldName then
			setName for an_item by newName
		end if
	end repeat
	return true
end replaceRegularExp

on setName for an_item by theName
	try
		tell application "Finder"
			set name of an_item to theName
		end tell
		--renameFile an_item to theName
	on error errMsg number errn
		if errn is in {-37, -48} then -- -48 : same name  -37: invalid name
			set theLocation to PathAnalyzer's folder_of(an_item)
			set theName to do of UniqueNamer about theName at theLocation
			tell application "Finder"
				set name of an_item to theName
			end tell
		else
			display dialog (errn as string) & return & errMsg
		end if
	end try
end setName

on forceQuit about theMessage
	beep
	activate
	if (theMessage is not "Skip") then
		display dialog theMessage buttons {"OK"} default button "OK" with icon 0 -- stop icon
	end if
	error number -128
end forceQuit