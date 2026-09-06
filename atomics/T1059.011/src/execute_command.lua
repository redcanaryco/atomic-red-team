-- This is a test file for Atomic Red Team T1059.011.
-- It shows that Lua can run commands, just like PowerShell or cmd.exe can.
-- It does two safe things:
-- 1. Opens Calculator (this proves Lua can start another program).
-- 2. Writes a small text file (this proves Lua can create files on its own).

print("Atomic Red Team T1059.011 test is running now.")

-- Step 1: open calculator
os.execute("calc.exe")

-- Step 2: write a small marker file so we can prove this ran
local temp_folder = os.getenv("TEMP")
local marker_path = temp_folder .. "\\T1059.011_lua_marker.txt"

local marker_file = io.open(marker_path, "w")
if marker_file then
    marker_file:write("This file was made by the Lua test for T1059.011.")
    marker_file:close()
    print("Marker file made at: " .. marker_path)
end

print("Test finished.")
