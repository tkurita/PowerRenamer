property FileSorter : "@module"
property XList : "@module"
property _only_local_ : true
property _ : script "ModuleLoader"'s setup(me)

on do_log(msg)
    -- do shell script "logger -p user.warning  -t PoserRenamer -s " & quoted form of msg
    display alert "PowerRenamer: "&msg
end do_log

on get_finderselection() -- return HFS paths
	set text item delimiters to {return}
	with timeout of 3600 seconds
		tell application id "com.apple.finder"
			set pathtable to selection as Unicode text
		end tell
	end timeout
	set a_list to every paragraph of pathtable
	return a_list
end get_finderselection

on initialize()
end initialize

on get_finderselection_as_posix_path()
    with timeout of 3600 seconds
        tell application id "com.apple.finder"
            set a_list to selection
        end tell
    end timeout
    script ToPosixPath
        on do(x)
            return POSIX path of (x as «class furl»)
        end do
    end script
    return XList's make_with(a_list)'s map_as_list(ToPosixPath)
end get_finderselection_as_posix_path

on sorted_finderselection()
	script SorterDelegate
		on target_items_at(a_location)
			return get_finderselection() -- FileSorter rquires HFS paths
		end target_items_at
	end script
	with timeout of 3600 seconds
		set a_list to FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
	end timeout
    script ToPosixPath
        on do(x)
        -- Conversion of HFS paths obtained with Finder must be processed with Finder.
            tell application id "com.apple.finder"
                return POSIX path of ((item x) as «class furl»)
            end tell
        end do
    end script
    return XList's make_with(a_list)'s map_as_list(ToPosixPath)
end sorted_finderselection

on sub_process_rename(paths, newnames) --deprecated
	repeat with n from 1 to length of paths
		set an_item to item n of paths
		tell application id "com.apple.finder"
			set name of item an_item to (item n of newnames)
		end tell
	end repeat
end sub_process_rename

on process_rename(paths, newnames, ignore_responses) --deprecated
	if ignore_responses then
		-- log "ignoring Finder"
		ignoring application responses
			sub_process_rename(paths, newnames)
		end ignoring
	else
		-- log "not ignoring FInder"
		sub_process_rename(paths, newnames)
	end if
end process_rename

on process_rename_posix_paths(paths, newnames)
    set x_newnames to XList's make_with(newnames)
    
    script DoRename
        on do(x)
            -- do_log(x)
            tell application id "com.apple.finder"
                set name of item ((x as POSIX file) as text) to (x_newnames's next())
            end tell
        end do
    end script

    ignoring application responses
        XList's make_with(paths)'s each_rush(DoRename)
    end ignoring
end process_rename

on select_posix_paths(a_list)
    script ToItem
        on do(x)
            return x as POSIX file
        end do
    end script
    set item_list to XList's make_with(a_list)'s map_as_list(ToItem)
    with timeout of 3600 seconds
        tell application id "com.apple.finder"
            select item_list
        end tell
    end timeout
end select_posix_paths

on select_items(a_list) -- deprecated
	repeat with an_item in a_list
		tell application id "com.apple.finder"
			set contents of an_item to (item an_item)
		end tell
	end repeat
	with timeout of 3600 seconds
		tell application id "com.apple.finder"
			--select a_list
			set selection to a_list
		end tell
	end timeout
end select_items
