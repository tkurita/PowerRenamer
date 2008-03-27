property FinderSelection : missing value
property PathAnalyzer : missing value
property XText : missing value
property UniqueNamer : missing value
property _app_controller : missing value

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

property _mode_popup : missing value
property _oldTextObj : missing value
property _newTextObj : missing value
property _window_position : missing value

script ControlValueManager
	property _controls : {}
	
	on register_control(theControl, a_default_key, theDefaultValue)
		set theValue to readDefaultValue(a_default_key, theDefaultValue)
		
		set contents of theControl to theValue
		
		script ControlValue
			property _control_val_ref : theControl
			property _default_key : a_default_key
			property _current_value : theValue
			
			on current_value()
				return contents of _control_val_ref
			end current_value
			
			on writeDefaults()
				set _current_value to contents of _control_val_ref
				--set _current_value to contents of targetControl
				set contents of default entry _default_key of user defaults to _current_value
			end writeDefaults
		end script
		
		set end of _controls to ControlValue
		return ControlValue
	end register_control
	
	on writeAllDefaults()
		repeat with an_item in _controls
			writeDefaults() of an_item
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
	set an_item to alias ("Macintosh HD:Users:tkurita:Factories:Script factory:ProjectsX:PowerRenamer:test scripts:‚¾:" as Unicode text)
	tell application "Finder"
		set theName to name of an_item
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
	call method "remindDonation" of class "DonationReminder"
	set ComboBoxHistory to importScript("ComboBoxHistory")
	set RenameEngine to importScript("RenameEngine")
	set _app_controller to call method "delegate"
	show window "Main"
end launched

on will open theObject
	
	set _mode_popup to register_control(a reference to contents of popup button "modePopup" of box "SearchTextBox" of theObject, "ModeIndex", 0) of ControlValueManager
	set oldTextHistoryObj to makeObj("OldTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "OldText" of box "SearchTextBox" of theObject) of oldTextHistoryObj
	
	set _oldTextObj to register_control(a reference to contents of combo box "OldText" of box "SearchTextBox" of theObject, "LastOldText", "") of ControlValueManager
	
	set newTextHistoryObj to makeObj("NewTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "NewText" of box "ReplaceTextbox" of theObject) of newTextHistoryObj
	
	set _newTextObj to register_control(a reference to contents of combo box "NewText" of box "ReplaceTextBox" of theObject, "LastNewText", "") of ControlValueManager
	
	set _window_position to register_control(a reference to position of theObject, "WindowPosition", {0, 0}) of ControlValueManager
	if _window_position's current_value() is {0, 0} then
		center theObject
	end if
end will open

on clicked theObject
	--log "start clicked"
	set theName to name of theObject
	set theWindow to window of theObject
	
	if theName is "RenameButton" then
		set targetItems to getTargetItems()
		if targetItems is in {{}, missing value} then
			set theMessage to localized string "NoSelection"
			display dialog theMessage buttons {"OK"} default button "OK" attached to theWindow
			return
		end if
		
		RenameEngine's set_old_text(_oldTextObj's current_value())
		RenameEngine's set_new_text(_newTextObj's current_value())
		set a_mode to _mode_popup's current_value()
		if a_mode is 0 then
			set a_result to replaceContain of RenameEngine for targetItems
		else if a_mode is 1 then
			set a_result to replaceBeginning of RenameEngine for targetItems
		else if a_mode is 2 then
			set a_result to replaceEnd of RenameEngine for targetItems
		else if a_mode is 3 then
			set a_result to replaceRegularExp of RenameEngine for targetItems
		end if
		
		if a_result then
			writeAllDefaults() of ControlValueManager
			
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
	writeDefaults() of _window_position
	quit
end should close

on open theObject
	(*Add your script here.*)
end open

on getTargetItems()
	set a_picker to FinderSelection's make_for_item()'s set_use_insertion_location(false)
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