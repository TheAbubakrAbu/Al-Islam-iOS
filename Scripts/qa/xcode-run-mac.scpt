-- xcode-run-mac.scpt <project path> <log file>: in Xcode, select the QA-Mac scheme and "My Mac (Designed for
-- iPad)", run, and append the action's status to the log until it ends. Xcode must be running with the
-- project open (or openable); AppleScript control of Xcode needs the one-time Automation approval.
on run argv
    set projPath to item 1 of argv
    set logFile to item 2 of argv
    my logLine(logFile, "start")
    tell application "Xcode"
      with timeout of 900 seconds
        -- Xcode keeps the scheme it read when the project opened and does not reliably notice a
        -- changed QA-Mac.xcscheme on disk: close the project and open it again (through
        -- LaunchServices: the AppleScript `open` command timed out at two minutes on 2026-10-12).
        -- Find it first, close it after: closing inside a loop over the live document list invalidates
        -- the list ("Can't get item 2 of every workspace document", 2026-10-12).
        set openDoc to missing value
        set docList to every workspace document
        repeat with d in docList
            try
                if (path of d) is projPath then set openDoc to d
            end try
        end repeat
        if openDoc is not missing value then
            close openDoc saving no
            my logLine(logFile, "closed the project to re-read the scheme")
            delay 2
        end if
        do shell script "open -a Xcode " & quoted form of projPath
        delay 6
        set ws to missing value
        repeat with i from 1 to 20
            -- A snapshot of the list, inside a try: Xcode adds and removes its own documents while a
            -- project opens, and a live list changes under the loop ("Can't get item 2", 2026-10-12).
            try
                set docList to every workspace document
                repeat with d in docList
                    if (path of d) is projPath then set ws to d
                end repeat
            end try
            if ws is not missing value then exit repeat
            delay 3
        end repeat
        if ws is missing value then
            my logLine(logFile, "project did not open")
            return
        end if
        set waited to 0
        repeat until (loaded of ws) or waited > 120
            delay 3
            set waited to waited + 3
        end repeat
        set active scheme of ws to (first scheme of ws whose name is "QA-Mac")
        my logLine(logFile, "scheme: " & (name of active scheme of ws))
        set active run destination of ws to (first run destination of ws whose name is "My Mac (Designed for iPad)")
        my logLine(logFile, "destination set")
        set r to run ws
        set lastStatus to ""
        set waited to 0
        repeat while waited < 1500
            set theStatus to "unknown"
            try
                set theStatus to (status of r) as string
            end try
            if theStatus is not lastStatus then
                my logLine(logFile, "status: " & theStatus & " at " & waited & " s")
                set lastStatus to theStatus
            end if
            if theStatus is in {"succeeded", "failed", "error occurred", "cancelled"} then exit repeat
            delay 5
            set waited to waited + 5
        end repeat
        try
            set em to (error message of r) as string
            my logLine(logFile, "error message: " & em)
        end try
      end timeout
    end tell
    my logLine(logFile, "end")
end run
on logLine(f, t)
    do shell script "echo \"$(date '+%H:%M:%S') \"" & quoted form of t & " >> " & quoted form of f
end logLine
