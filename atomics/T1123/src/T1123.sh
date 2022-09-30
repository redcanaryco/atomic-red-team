OUTPATH=$1
DURSEC=$2
echo "Starting recording, make some noise for ${DURSEC} seconds!"
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
' "${OUTPATH}" ${DURSEC}

# check file is created and a decent size (empty recording is still ~62KB)
if [ -f "${OUTPATH}" ] ; then
   RECSIZE=`stat -f '%z' ${OUTPATH}`
   if [ $RECSIZE -gt 100000 ]; then
       echo "Audio data present" && exit 0
   fi
fi
echo "Failed"
exit 1