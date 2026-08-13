#!/bin/zsh

set -euo pipefail

OUTPUT_DIR="$HOME/Documents/ChatGPT"
mkdir -p "$OUTPUT_DIR"

PAGE_URL=$(osascript <<'APPLESCRIPT'
tell application "Safari"
    if (count of windows) = 0 then
        error "Safariのウインドウがありません。"
    end if
    return URL of current tab of front window
end tell
APPLESCRIPT
)

if [[ "$PAGE_URL" != https://chatgpt.com/* ]]; then
    print -u2 "Error: Safariの最前面タブがChatGPTではありません。"
    print -u2 "URL: $PAGE_URL"
    exit 1
fi

PAGE_TITLE=$(osascript <<'APPLESCRIPT'
tell application "Safari"
    return do JavaScript "document.title" in current tab of front window
end tell
APPLESCRIPT
)

MARKDOWN=$(osascript <<'APPLESCRIPT'
tell application "Safari"
    set jsCode to "
        (() => {
            function childrenToMarkdown(node) {
                return [...node.childNodes].map(toMarkdown).join('');
            }

            function normalizeText(text) {
                return text.replace(/\\u00a0/g, ' ');
            }

            function detectLanguage(codeNode, code) {
                if (codeNode) {
                    for (const className of codeNode.classList) {
                        if (className.startsWith('language-')) {
                            return {
                                language: className.slice('language-'.length).toLowerCase(),
                                code
                            };
                        }
                    }
                }

                const aliases = {
                    'powershell': 'powershell',
                    'shell': 'bash',
                    'bash': 'bash',
                    'zsh': 'zsh',
                    'python': 'python',
                    'javascript': 'javascript',
                    'typescript': 'typescript',
                    'java': 'java',
                    'c': 'c',
                    'c++': 'cpp',
                    'c#': 'csharp',
                    'swift': 'swift',
                    'go': 'go',
                    'rust': 'rust',
                    'ruby': 'ruby',
                    'php': 'php',
                    'sql': 'sql',
                    'json': 'json',
                    'yaml': 'yaml',
                    'yml': 'yaml',
                    'xml': 'xml',
                    'html': 'html',
                    'css': 'css',
                    'markdown': 'markdown',
                    'text': 'text',
                    'plaintext': 'text'
                };

                const lines = code.split('\\n');
                const firstNonEmpty = lines.findIndex(line => line.trim() !== '');

                if (firstNonEmpty >= 0) {
                    const label = lines[firstNonEmpty].trim().toLowerCase();
                    if (aliases[label]) {
                        lines.splice(firstNonEmpty, 1);
                        while (lines.length && lines[0].trim() === '') {
                            lines.shift();
                        }
                        return {
                            language: aliases[label],
                            code: lines.join('\\n')
                        };
                    }
                }

                return { language: '', code };
            }

            function toMarkdown(node) {
                if (node.nodeType === Node.TEXT_NODE) {
                    return normalizeText(node.textContent || '');
                }

                if (node.nodeType !== Node.ELEMENT_NODE) {
                    return '';
                }

                const tag = node.tagName.toLowerCase();

                if (tag === 'script' || tag === 'style' || tag === 'button' || tag === 'svg') {
                    return '';
                }

                if (tag === 'pre') {
                    const codeNode = node.querySelector('code');
                    let code = (codeNode ? codeNode.innerText : node.innerText)
                        .replace(/^\\n+/, '')
                        .replace(/\\n+$/, '');

                    const detected = detectLanguage(codeNode, code);
                    code = detected.code
                        .replace(/^\\n+/, '')
                        .replace(/\\n+$/, '');

                    return '\\n```' + detected.language + '\\n' + code + '\\n```\\n\\n';
                }

                if (tag === 'code') {
                    const content = childrenToMarkdown(node).trim();
                    if (content.includes('`')) {
                        return '``' + content + '``';
                    }
                    return '`' + content + '`';
                }

                const content = childrenToMarkdown(node);

                switch (tag) {
                    case 'h1':
                        return '# ' + content.trim() + '\\n\\n';
                    case 'h2':
                        return '## ' + content.trim() + '\\n\\n';
                    case 'h3':
                        return '### ' + content.trim() + '\\n\\n';
                    case 'h4':
                        return '#### ' + content.trim() + '\\n\\n';
                    case 'h5':
                        return '##### ' + content.trim() + '\\n\\n';
                    case 'h6':
                        return '###### ' + content.trim() + '\\n\\n';
                    case 'p':
                        return content.trim() + '\\n\\n';
                    case 'br':
                        return '\\n';
                    case 'strong':
                    case 'b':
                        return '**' + content + '**';
                    case 'em':
                    case 'i':
                        return '*' + content + '*';
                    case 'del':
                    case 's':
                        return '~~' + content + '~~';
                    case 'a': {
                        const href = node.getAttribute('href') || '';
                        const label = content.trim() || href;
                        return href ? '[' + label + '](' + href + ')' : label;
                    }
                    case 'blockquote':
                        return content.trim().split('\\n').map(line => '> ' + line).join('\\n') + '\\n\\n';
                    case 'ul':
                        return content + '\\n';
                    case 'ol': {
                        let index = 0;
                        return [...node.children].map(child => {
                            if (child.tagName.toLowerCase() !== 'li') {
                                return toMarkdown(child);
                            }
                            index += 1;
                            const item = childrenToMarkdown(child).trim().replace(/\\n+/g, '\\n  ');
                            return index + '. ' + item + '\\n';
                        }).join('') + '\\n';
                    }
                    case 'li': {
                        const item = content.trim().replace(/\\n+/g, '\\n  ');
                        return '- ' + item + '\\n';
                    }
                    case 'hr':
                        return '\\n---\\n\\n';
                    default:
                        return content;
                }
            }

            function cleanMarkdown(text) {
                return text
                    .replace(/[ \\t]+\\n/g, '\\n')
                    .replace(/\\n{3,}/g, '\\n\\n')
                    .trim();
            }

            const nodes = [...document.querySelectorAll('[data-message-author-role]')];

            if (nodes.length === 0) {
                throw new Error('ChatGPTの会話メッセージが見つかりません。');
            }

            let promptNo = 0;
            let responseNo = 0;
            const parts = ['# ' + document.title, ''];

            for (const node of nodes) {
                const role = node.getAttribute('data-message-author-role') || 'unknown';
                const markdown = cleanMarkdown(childrenToMarkdown(node));

                if (!markdown) {
                    continue;
                }

                if (role === 'user') {
                    promptNo += 1;
                    parts.push('## PROMPT ' + promptNo, '', markdown, '');
                } else if (role === 'assistant') {
                    responseNo += 1;
                    parts.push('## RESPONSE ' + responseNo, '', markdown, '');
                } else {
                    parts.push('## ' + role.toUpperCase(), '', markdown, '');
                }
            }

            return parts.join('\\n').trim() + '\\n';
        })()
    "

    return do JavaScript jsCode in current tab of front window
end tell
APPLESCRIPT
)

SAFE_TITLE=$(printf '%s' "$PAGE_TITLE" \
    | tr '/:' '__' \
    | tr '\n\r\t' '   ' \
    | sed -E 's/[[:space:]]+$//; s/^[[:space:]]+//')

if [[ -z "$SAFE_TITLE" ]]; then
    SAFE_TITLE="ChatGPT"
fi

OUTPUT_FILE="$OUTPUT_DIR/$SAFE_TITLE.md"
printf '%s\n' "$MARKDOWN" > "$OUTPUT_FILE"

print "Saved: $OUTPUT_FILE"
