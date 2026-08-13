#!/bin/zsh

osascript <<'APPLESCRIPT'
tell application "Safari"
    set result to do JavaScript "
        (() => {
            return document.querySelectorAll('article').length.toString();
        })()
    " in current tab of front window

    return result
end tell
APPLESCRIPT
