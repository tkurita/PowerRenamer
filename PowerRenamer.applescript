property FinderSelection : missing value
property PathAnalyzer : missing value
property XText : missing value
property UniqueNamer : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
		set PathAnalyzer to load("PathAnalyzer")
		set XText to PathAnalyzer's XText
		set UniqueNamer to load("UniqueNamer")
	end tell
end __load__

property _ : __load__(proxy() of application (get "PowerRenamerLib"))

property ComboBoxHistory : missing value
property RenameEngine : missing value

property oldTextHistoryObj : missing value
property newTextHistoryObj : missing value

property modeIndexObj : missing value
property _oldTextObj : missing value
property _newTextObj : missing value
property windowPosition : missing value

script ControlValueManager
	property controlList : {}
	
	on registControl(theControl, theDefaultKey, theDefaultValue)
		set theValue to readDefaultValue(theDefaultKey, theDefaultValue)
		
		set contents of theControl to theValue
		
		script ControlValueObj
			property targetControlValue : theControl
			property defaultKey : theDefaultKey
			property currentValue : theValue
			
			on writeDefaults()
				set currentValue to contents of targetControlValue
				--set currentValue to contents of targetControl
				set contents of default entry defaultKey of user defaults to currentValue
			end writeDefaults
		end script
		
		set end of controlList to ControlValueObj
		return ControlValueObj
	end registControl
	
	on writeAllDefaults()
		repeat with theItem in controlList
			writeDefaults() of theItem
		end repeat
	end writeAllDefaults
	
	on readDefaultValue(entryName, defaultValue)
		tell user defaults
			if exists default entry entryName then
				return contents of default entry entryName
			else
				make new default entry at end of default entries with properties {name:entryName, contents:defaultValue}
				return defaultValue
			end if
		end tell
	end readDefaultValue
end script

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on launched theObject
	(*
	set theItem to alias ("Macintosh HD:Users:tkurita:Factories:Script factory:ProjectsX:PowerRenamer:test scripts:‚¾:" as Unicode text)
	tell application "Finder"
		set theName to name of theItem
	end tell
	set a_text to "‚¾" as Unicode text
	--set theName to call method "normalizedString:" of theName with parameter 3
	log theName contains a_text
	--set a_result to call method "isEqualToNormalizedString:" of theName with parameter ("‚¾" as Unicode text)
	--log (theName as Unicode text) starts with ("‚¾" as Unicode text)
	--log a_result
	quit
	*)
	--log "launched"
	--log "sucsess OSAXChecker"
	call method "remindDonation" of class "DonationReminder"
	set ComboBoxHistory to importScript("ComboBoxHistory")
	set RenameEngine to importScript("RenameEngine")
	show window "Main"
end launched

on will open theObject
	
	set modeIndexObj to registControl(a reference to contents of popup button "modePopup" of box "SearchTextBox" of theObject, "ModeIndex", 0) of ControlValueManager
	set oldTextHistoryObj to makeObj("OldTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "OldText" of box "SearchTextBox" of theObject) of oldTextHistoryObj
	
	set _oldTextObj to registControl(a reference to contents of combo box "OldText" of box "SearchTextBox" of theObject, "LastOldText", "") of ControlValueManager
	
	set newTextHistoryObj to makeObj("NewTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "NewText" of box "ReplaceTextbox" of theObject) of newTextHistoryObj
	
	set _newTextObj to registControl(a reference to contents of combo box "NewText" of box "ReplaceTextBox" of theObject, "LastNewText", "") of ControlValueManager
	
	set windowPosition to registControl(a reference to position of theObject, "WindowPosition", {0, 0}) of ControlValueManager
	if currentValue of windowPosition is {0, 0} then
		center theObject
	end if
end will open

on clicked theObject
	set theName to name of theObject
	set theWindow to window of theObject
	
	if theName is "RenameButton" then
		set targetItems to getTargetItems()
		if targetItems is {} then
			set theMessage to localized string "NoSelection"
			display dialog theMessage buttons {"OK"} default button "OK" attached to theWindow
			return
		end if
		
		writeAllDefaults() of ControlValueManager
		set _oldstring of RenameEngine to currentValue of _oldTextObj
		set _newstring of RenameEngine to currentValue of _newTextObj
		
		if currentValue of modeIndexObj is 0 then
			set a_result to replaceContain of RenameEngine for targetItems
		else if currentValue of modeIndexObj is 1 then
			set a_result to replaceBeginning of RenameEngine for targetItems
		else if currentValue of modeIndexObj is 2 then
			set a_result to replaceEnd of RenameEngine for targetItems
		else if currentValue of modeIndexObj is 3 then
			set a_result to replaceRegularExp of RenameEngine for targetItems
		end if
		
		if a_result then
			addValueFromComboBox() of oldTextHistoryObj
			writeDefaults() of oldTextHistoryObj
			
			addValueFromComboBox() of newTextHistoryObj
			writeDefaults() of newTextHistoryObj
			
			hide theWindow
			quit
		end if
	else
		close theWindow
	end if
end clicked

on should close theObject
	writeDefaults() of windowPosition
	quit
end should close

on open theObject
	(*Add your script here.*)
end open

on getTargetItems()
	set a_picker to FinderSelection's make_for_item()
	a_picker's set_prompt_message("Choose items to rename.")
	a_picker's set_use_chooser(false)
	try
		set a_list to a_picker's get_selection()
	on error msg number errno
		if errno is -128 then
			quit
			return
		else
			error msg number errno
		end if
	end try
	
	return a_list
end getTargetItems