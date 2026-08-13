#!/bin/zsh

osascript <<'APPLESCRIPT'
tell application "Safari"

    set pageTitle to do JavaScript "document.title" in current tab of front window

    set jsCode to "
        (() => {
            function childrenToMarkdown(node) {
                return [...node.childNodes].map(toMarkdown).join('');
            }

            function normalizeText(text) {
                return text.replace(/\\u00a0/g, ' ');
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
                    const code = (codeNode ? codeNode.innerText : node.innerText).replace(/\\n$/, '');

                    let language = '';
                    if (codeNode) {
                        for (const className of codeNode.classList) {
                            if (className.startsWith('language-')) {
                                language = className.slice('language-'.length);
                                break;
                            }
                        }
                    }

                    return '\\n```' + language + '\\n' + code + '\\n```\\n\\n';
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

    set markdownText to do JavaScript jsCode in current tab of front window

    return markdownText

end tell
APPLESCRIPT
