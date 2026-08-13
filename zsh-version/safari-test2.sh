#!/bin/zsh

osascript <<'APPLESCRIPT'
tell application "Safari"
    set result to do JavaScript "
        (() => {
            const byRole =
                document.querySelectorAll('[data-message-author-role]').length;

            const byTurn =
                document.querySelectorAll('section[data-testid^=\"conversation-turn-\"]').length;

            return 'data-message-author-role=' + byRole +
                   ', conversation-turn=' + byTurn;
        })()
    " in current tab of front window

    return result
end tell
APPLESCRIPT
