on makeObj(theDefaultEntryName, a_list)
	if exists default entry theDefaultEntryName of user defaults then
		set a_list to contents of default entry theDefaultEntryName of user defaults
	else
		make new default entry at end of default entries of user defaults with properties {name:theDefaultEntryName, contents:a_list}
	end if
	
	script ComboBoxHisotry
		property valueList : a_list
		property maxNum : 10
		property isChanged : false
		property targetComboBox : missing value
		property defaultEntryName : theDefaultEntryName
		property ignoringValue : ""
		
		on addValueFromComboBox()
			set theValue to contents of contents of targetComboBox
			addValue(theValue)
		end addValueFromComboBox
		
		on addValue(theValue)
			if theValue is not ignoringValue then
				if theValue is not in valueList then
					set beginning of valueList to theValue
					if length of valueList > maxNum then
						set valueList to items 1 thru maxNum of valueList
					end if
				else
					set tmpList to {}
					repeat with ith from 1 to (length of valueList)
						set tmpValue to item ith of valueList
						if tmpValue is not theValue then
							set beginning of tmpList to tmpValue
						end if
					end repeat
					set beginning of tmpList to theValue
					set valueList to tmpList
				end if
			end if
		end addValue
		
		on setComboBox(theComboBox)
			set targetComboBox to theComboBox
			repeat with an_item in valueList
				make new combo box item at the end of combo box items of targetComboBox with data an_item
			end repeat
		end setComboBox
		
		on writeDefaults()
			set contents of default entry defaultEntryName of user defaults to valueList
		end writeDefaults
	end script
	
	return ComboBoxHisotry
end makeObj