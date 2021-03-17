property FileSorter : "@module"
property XList : "@module"
property _only_local_ : true
property _ : script "ModuleLoader"'s setup(me)

on get_finderselection() -- has problem on external drives, deprecated
	set text item delimiters to {return}
	with timeout of 3600 seconds
		tell application "Finder"
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
        tell application "Finder"
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
			--return get_finderselection()
            return get_finderselection_as_posix_path()
		end target_items_at
	end script
	with timeout of 3600 seconds
		set a_list to FileSorter's make_with_delegate(SorterDelegate)'s sorted_items()
	end timeout
	return a_list
end sorted_finderselection

on sub_process_rename(pathes, newnames) --deprecated
	repeat with n from 1 to length of pathes
		set an_item to item n of pathes
		tell application "Finder"
			set name of item an_item to (item n of newnames)
		end tell
	end repeat
end sub_process_rename

on process_rename(pathes, newnames, ignore_responses) --deprecated
	if ignore_responses then
		-- log "ignoring Finder"
		ignoring application responses
			sub_process_rename(pathes, newnames)
		end ignoring
	else
		-- log "not ignoring FInder"
		sub_process_rename(pathes, newnames)
	end if
end process_rename

on do_log(msg)
    do shell script "logger -p user.warning  -t PoserRenamer -s " & quoted form of msg
end do_log

on process_rename_posix_pathes(pathes, newnames)
    set x_newnames to XList's make_with(newnames)
    
    script DoRename
        on do(x)
            -- do_log(x)
            tell application "Finder"
                set name of item ((x as POSIX file) as text) to (x_newnames's next())
            end tell
        end do
    end script

    ignoring application responses
        -- log "ignoring FInder"
        XList's make_with(pathes)'s each_rush(DoRename)
    end ignoring
end process_rename


on select_items(a_list)
	repeat with an_item in a_list
		tell application "Finder"
			set contents of an_item to (item an_item)
		end tell
	end repeat
	with timeout of 3600 seconds
		tell application "Finder"
			--select a_list
			set selection to a_list
		end tell
	end timeout
end select_items
