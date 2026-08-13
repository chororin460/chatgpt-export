#!/bin/zsh

osascript <<'APPLESCRIPT'
tell application "Safari"
    if (count of windows) = 0 then
        error "Safariのウインドウがありません。"
    end if

    set pageTitle to do JavaScript "document.title" in current tab of front window
    set pageURL to URL of current tab of front window

    return "TITLE: " & pageTitle & linefeed & "URL: " & pageURL
end tell
APPLESCRIPT
