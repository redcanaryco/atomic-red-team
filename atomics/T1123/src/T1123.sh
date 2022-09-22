echo "Starting recording, make some noise for $2 seconds!"
osascript -e '
    on run argv
        set theFilePath to POSIX path of item 1 of argv
        set durn to item 2 of argv
        tell application "Quicktime Player"
            start (new audio recording)
            repeat durn times
                log (durn)
                delay 1
                set durn to (durn - 1)
            end repeat
            tell document "Audio Recording"
                pause
                save it in POSIX file theFilePath
                stop
                close
            end tell
            close
        end tell
    end run
' "$1" $2
RECSIZE=`cat $1 | wc -c`
if [ $RECSIZE -gt 100000 ]; then
    echo "Recording complete"
else echo "Failed" && exit 1
fi