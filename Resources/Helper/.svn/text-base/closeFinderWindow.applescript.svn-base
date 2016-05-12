on uppercase(s)
	set uc to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	set lc to "abcdefghijklmnopqrstuvwxyz"
	repeat with i from 1 to 26
		set AppleScript's text item delimiters to character i of lc
		set s to text items of s
		set AppleScript's text item delimiters to character i of uc
		set s to s as text
	end repeat
	set AppleScript's text item delimiters to ""
	return s
end uppercase

on lowercase(s)
	set uc to "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	set lc to "abcdefghijklmnopqrstuvwxyz"
	repeat with i from 1 to 26
		set AppleScript's text item delimiters to character i of uc
		set s to text items of s
		set AppleScript's text item delimiters to character i of lc
		set s to s as text
	end repeat
	set AppleScript's text item delimiters to ""
	return s
end lowercase

on close_finder_window(aName)
	tell application "Finder"
		set aName to my lowercase(aName)
		-- display dialog aName
		repeat with wnd in (get every Finder window)
			set t to target of wnd
			--set d to disk of t
			set n to my lowercase(name of t)
			-- display dialog n
			if n = aName then
				close wnd
				exit repeat
			end if
			
			set n to my lowercase(name of wnd)
			-- display dialog n
			if n = aName then
				close wnd
				exit repeat
			end if
			
		end repeat
	end tell
end close_finder_window