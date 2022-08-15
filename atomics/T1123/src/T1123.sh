echo "Starting recording, make some noise for #{duration} seconds!"
osascript -e '
    on run argv
        set theFilePath to POSIX path of item 1 of argv
        set duration to item 2 of argv
        tell application "Quicktime Player"
            start (new audio recording)
            delay duration
            tell document "Audio Recording"
                pause #do not stop else it becomes a different document
                save it in POSIX file theFilePath
                stop
                close
            end tell
        end tell
    end run
'
echo "Recording complete"