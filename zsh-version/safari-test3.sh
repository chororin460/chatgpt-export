#!/bin/zsh

osascript <<'APPLESCRIPT'
tell application "Safari"

    set pageTitle to do JavaScript "document.title" in current tab of front window

    set jsCode to "
        (() => {
            const nodes = [...document.querySelectorAll('[data-message-author-role]')];

            return nodes.map((node, index) => {
                const role =
                    node.getAttribute('data-message-author-role') || 'unknown';

                return '[' + (index + 1) + '] ' +
                       role.toUpperCase() +
                       '\\n' +
                       node.innerText;
            }).join('\\n\\n--------------------\\n\\n');
        })()
    "

    set resultText to do JavaScript jsCode in current tab of front window

    return pageTitle & "<<<SEPARATOR>>>" & resultText

end tell
APPLESCRIPT