#!/usr/bin/osascript -l JavaScript

# Specify log file path
var logFilePath = "/var/log/system.log";

# Create file instance
var file = $.NSFileManager.defaultManager.fileExistsAtPath(logFilePath);

# Check if file exists
if (file) {
    # Remove file
    $.NSFileManager.defaultManager.removeItemAtPath(logFilePath, error);
}
