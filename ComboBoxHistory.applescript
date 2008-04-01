on addValueFromComboBox()
	set a_value to contents of contents of my _target_control
	addValue(a_value)
end addValueFromComboBox

on addValue(a_value)
	if a_value is not my _ignoring_value then
		if a_value is not in my _values then
			set beginning of my _values to a_value
			if length of my _values > my _maxNum then
				set my _values to items 1 thru (my _maxNum) of my _values
			end if
		else
			set tmpList to {}
			repeat with ith from 1 to (length of my _values)
				set tmpValue to item ith of my _values
				if tmpValue is not a_value then
					set beginning of tmpList to tmpValue
				end if
			end repeat
			set beginning of tmpList to a_value
			set my _values to tmpList
		end if
	end if
end addValue

on setComboBox(theComboBox)
	set my _target_control to theComboBox
	repeat with an_item in my _values
		make new combo box item at the end of combo box items of my _target_control with data an_item
	end repeat
end setComboBox

on writeDefaults()
	set contents of default entry (my _default_entry_name) of user defaults to my _values
end writeDefaults

on make_with(a_default_entry_name, a_list)
	if exists default entry a_default_entry_name of user defaults then
		set a_list to contents of default entry a_default_entry_name of user defaults
	else
		make new default entry at end of default entries of user defaults with properties {name:a_default_entry_name, contents:a_list}
	end if
	
	script ComboBoxHisotry
		property _values : a_list
		property _maxNum : 10
		property _target_control : missing value
		property _default_entry_name : a_default_entry_name
		property _ignoring_value : ""
	end script
	
	return ComboBoxHisotry
end make_with