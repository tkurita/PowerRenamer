global XText
global UniqueNamer
global PathAnalyzer

property oldString : ""
property newString : ""

on replaceEnd for theList
	set oldLength to length of oldString
	
	repeat with ith from 1 to length of theList
		set theItem to item ith of theList
		tell application "Finder"
			set oldName to name of theItem
		end tell
		set oldName to call method "normalizedString:" of oldName with parameter 3
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		if oldName ends with oldString then
			if oldLength > 1 then
				set newName to (text 1 thru (-1 - oldLength) of oldName) & newString
			else
				set newName to newString
			end if
			
			if newName is not oldName then
				setName for theItem by newName
			end if
		end if
	end repeat
end replaceEnd

on replaceBeginning for theList
	set oldLength to length of oldString
	
	repeat with ith from 1 to length of theList
		set theItem to item ith of theList
		tell application "Finder"
			set oldName to name of theItem
		end tell
		set oldName to call method "normalizedString:" of oldName with parameter 3
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		if oldName starts with oldString then
			if oldLength > 1 then
				set newName to newString & (text (oldLength + 1) thru -1 of oldName)
			else
				set newName to newString
			end if
			if newName is not oldName then
				--if not is_same_unicode(newName, oldName) then
				setName for theItem by newName
			end if
		end if
	end repeat
end replaceBeginning

on replaceContaine for theList
	set oldLength to length of oldString
	
	store_delimiters() of XText
	repeat with ith from 1 to length of theList
		set theItem to item ith of theList
		tell application "Finder"
			set oldName to name of theItem
		end tell
		--set oldName to NormalizeUnicode oldName normalizationForm "NFKC"
		set oldName to call method "normalizedString:" of oldName with parameter 3
		if oldName contains oldString then
			set newName to replace of XText for oldName from oldString by newString
			if newName is not oldName then
				setName for theItem by newName
			end if
		end if
	end repeat
	restore_delimiters() of XText
end replaceContaine

on replaceRegularExp for theList
	repeat with ith from 1 to length of theList
		set theItem to item ith of theList
		set oldName to PathAnalyzer's name_of(theItem)
		set newName to call method "replaceForPattern:withString:" of oldName with parameters {oldString, newString}
		if newName is not oldName then
			setName for theItem by newName
		end if
	end repeat
end replaceRegularExp

on setName for theItem by theName
	try
		tell application "Finder"
			set name of theItem to theName
		end tell
		--renameFile theitem to theName
	on error errMsg number errn
		if errn is in {-37, -48} then -- -48 : same name  -37: invalid name
			set theLocation to PathAnalyzer's folder_of(theItem)
			set theName to do of UniqueNamer about theName at theLocation
			tell application "Finder"
				set name of theItem to theName
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