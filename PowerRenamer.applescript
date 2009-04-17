property FinderSelection : missing value
property XFile : missing value
property PathAnalyzer : missing value
property XText : missing value
--property UniqueNamer : missing value
property _app_controller : missing value

on __load__(loader)
	tell loader
		set FinderSelection to load("FinderSelection")
		set XFile to load("XFile")
		set PathAnalyzer to load("PathAnalyzer")
		set XText to PathAnalyzer's XText
		--set UniqueNamer to load("UniqueNamer")
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

on importScript(scriptName)
	tell main bundle
		set scriptPath to path for script scriptName extension "scpt"
	end tell
	return load script POSIX file scriptPath
end importScript

on launched theObject
	(*
	set an_item to alias ("Macintosh HD:Users:tkurita:Factories:Script factory:ProjectsX:PowerRenamer:test scripts:だ:" as Unicode text)
	tell application "Finder"
		set a_name to name of an_item
	end tell
	set a_text to "だ" as Unicode text
	--set a_name to call method "normalizedString:" of a_name with parameter 3
	log a_name contains a_text
	--set a_result to call method "isEqualToNormalizedString:" of a_name with parameter ("だ" as Unicode text)
	--log (a_name as Unicode text) starts with ("だ" as Unicode text)
	--log a_result
	quit
	*)
	--log "launched"
	call method "remindDonation" of class "DonationReminder"
	set ComboBoxHistory to importScript("ComboBoxHistory")
	set RenameEngine to importScript("RenameEngine")
	--set ControlValueManager to importScript("ControlValueManager")
	set _app_controller to call method "delegate"
	show window "Main"
end launched

on will open theObject
	
	--set _mode_popup to register_control(a reference to contents of popup button "modePopup" of box "SearchTextBox" of theObject, "ModeIndex", 0) of ControlValueManager
	set oldTextHistoryObj to make_with("OldTextHistory", {}) of ComboBoxHistory
	set_combobox(combo box "OldText" of box "SearchTextBox" of theObject) of oldTextHistoryObj
	
	--set _oldTextObj to register_control(a reference to contents of combo box "OldText" of box "SearchTextBox" of theObject, "LastOldText", "") of ControlValueManager
	
	set newTextHistoryObj to make_with("NewTextHistory", {}) of ComboBoxHistory
	set_combobox(combo box "NewText" of box "ReplaceTextbox" of theObject) of newTextHistoryObj
	
	--set _newTextObj to register_control(a reference to contents of combo box "NewText" of box "ReplaceTextBox" of theObject, "LastNewText", "") of ControlValueManager
	
	--set _window_position to register_control(a reference to position of theObject, "WindowPosition", {0, 0}) of ControlValueManager
	(*
	if _window_position's current_value() is {0, 0} then
		center theObject
	end if
	*)
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
			if (not a_result) and (_oldTextObj's current_value() is "") then
				display alert (localized string "EnterSearchText") attached to a_window
			end if
		else if a_mode is 1 then
			set a_result to replace_beginning of RenameEngine for pathes
		else if a_mode is 2 then
			set a_result to replace_endding of RenameEngine for pathes
		else if a_mode is 3 then
			set a_result to replace_regexp of RenameEngine for pathes
		end if
		
		if a_result then
			--write_all_defaults() of ControlValueManager
			
			add_value_from_combobox() of oldTextHistoryObj
			write_defaults() of oldTextHistoryObj
			
			add_value_from_combobox() of newTextHistoryObj
			write_defaults() of newTextHistoryObj
			
			hide a_window
			quit
		end if
	else
		close a_window
	end if
end clicked

on should close theObject
	write_defaults() of _window_position
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