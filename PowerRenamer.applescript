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
		set a_value to readDefaultValue(a_default_key, theDefaultValue)
		
		set contents of theControl to a_value
		
		script ControlValue
			property _control_val_ref : theControl
			property _default_key : a_default_key
			property _current_value : a_value
			
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
		set a_name to name of an_item
	end tell
	set a_text to "‚¾" as Unicode text
	--set a_name to call method "normalizedString:" of a_name with parameter 3
	log a_name contains a_text
	--set a_result to call method "isEqualToNormalizedString:" of a_name with parameter ("‚¾" as Unicode text)
	--log (a_name as Unicode text) starts with ("‚¾" as Unicode text)
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
	set oldTextHistoryObj to make_with("OldTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "OldText" of box "SearchTextBox" of theObject) of oldTextHistoryObj
	
	set _oldTextObj to register_control(a reference to contents of combo box "OldText" of box "SearchTextBox" of theObject, "LastOldText", "") of ControlValueManager
	
	set newTextHistoryObj to make_with("NewTextHistory", {}) of ComboBoxHistory
	setComboBox(combo box "NewText" of box "ReplaceTextbox" of theObject) of newTextHistoryObj
	
	set _newTextObj to register_control(a reference to contents of combo box "NewText" of box "ReplaceTextBox" of theObject, "LastNewText", "") of ControlValueManager
	
	set _window_position to register_control(a reference to position of theObject, "WindowPosition", {0, 0}) of ControlValueManager
	if _window_position's current_value() is {0, 0} then
		center theObject
	end if
end will open

on clicked theObject
	--log "start clicked"
	set a_name to name of theObject
	set a_window to window of theObject
	
	if a_name is "RenameButton" then
		set pathes to target_items()
		if pathes is in {{}, missing value} then
			set msg to localized string "NoSelection"
			display dialog msg buttons {"OK"} default button "OK" attached to a_window
			return
		end if
		
		RenameEngine's set_old_text(_oldTextObj's current_value())
		RenameEngine's set_new_text(_newTextObj's current_value())
		set a_mode to _mode_popup's current_value()
		if a_mode is 0 then
			set a_result to replace_containing of RenameEngine for pathes
		else if a_mode is 1 then
			set a_result to replace_beginning of RenameEngine for pathes
		else if a_mode is 2 then
			set a_result to replace_endding of RenameEngine for pathes
		else if a_mode is 3 then
			set a_result to replace_regexp of RenameEngine for pathes
		end if
		
		if a_result then
			writeAllDefaults() of ControlValueManager
			
			addValueFromComboBox() of oldTextHistoryObj
			writeDefaults() of oldTextHistoryObj
			
			addValueFromComboBox() of newTextHistoryObj
			writeDefaults() of newTextHistoryObj
			
			hide a_window
			quit
		end if
	else
		close a_window
	end if
end clicked

on should close theObject
	writeDefaults() of _window_position
	quit
end should close

on open theObject
	(*Add your script here.*)
end open

on target_items()
	set a_picker to FinderSelection's make_for_item()
	tell a_picker
		set_use_insertion_location(false)
		set_resolve_alias(false)
		set_prompt_message("Choose items to rename.")
		set_use_chooser(false)
	end tell
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
end target_items