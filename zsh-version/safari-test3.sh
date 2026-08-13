#!/bin/zsh

OUTPUT_DIR="$HOME/Documents/ChatGPT"
mkdir -p "$OUTPUT_DIR"

RESULT=$(osascript <<'APPLESCRIPT'
tell application "Safari"

    set pageTitle to do JavaScript "document.title" in current tab of front window

    set messageText to do JavaScript "
        (() => {
            const nodes =
                [...document.querySelectorAll('[data-message-author-role]')];

            return nodes.map((node, index) => {
                const role =
                    node.getAttribute('data-message-author-role') || 'unknown';

                return '[' + (index + 1) + '] ' +
                       role.toUpperCase() +
                       '\n' +
                       node.innerText;
            }).join('\n\n--------------------\n\n');
        })()
    " in current tab of front window

    return pageTitle & "<<<SEPARATOR>>>" & messageText

end tell
APPLESCRIPT
)

printf '%s\n' "$RESULT"
