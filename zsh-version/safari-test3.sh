#!/bin/zsh

OUTPUT_DIR="$HOME/Documents/ChatGPT"
mkdir -p "$OUTPUT_DIR"

RESULT=$(osascript <<'APPLESCRIPT'
tell application "Safari"

    set pageTitle to do JavaScript "document.title" in current tab of front window

    set markdownText to do JavaScript "
        (() => {

            // ChatGPTの会話を抽出

            return markdown;
        })()
    " in current tab of front window

    return pageTitle & \"<<<SEPARATOR>>>\" & markdownText

end tell
APPLESCRIPT
)