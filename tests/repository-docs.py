#!/usr/bin/env python3
"""Check current documentation contracts without claiming runtime acceptance."""
from pathlib import Path
import re
import shlex
import sys
from urllib.parse import unquote, urlsplit

ACTIVE = ('AGENTS.md', 'CLAUDE.md', 'DEVELOPMENT.md')
REFERENCES = ('README.md', 'MODULES.md', 'HANDBOOK.md', 'BACKLOG.md',
              'DESIGN.md', 'assets/README.md', 'docs/guide.md')


def anchors(text):
    result, seen = set(), {}
    for line in text.splitlines():
        match = re.match(r'^#{1,6}\s+(.+)', line)
        if not match:
            continue
        slug = re.sub(r'[^\w -]', '', re.sub(r'[`*_~]', '', match[1].lower())).replace(' ', '-')
        count = seen.get(slug, 0)
        seen[slug] = count + 1
        result.add(slug if not count else f'{slug}-{count}')
    result.update(re.findall(r'<a\s+(?:id|name)="([^"]+)"', text))
    return result


def check(root):
    errors = []
    for name in ACTIVE + REFERENCES:
        path = root / name
        if not path.is_file():
            errors.append(f'{name}: missing required document')
            continue
        text = path.read_text()
        links = re.findall(r'\[[^\]]*\]\(([^\s)]+)', text)
        links += re.findall(r'(?:href|src)="([^\"]+)"', text)
        for link in links:
            url = urlsplit(link)
            if url.scheme or url.netloc:
                continue
            target = (path.parent / unquote(url.path)).resolve() if url.path else path
            if not target.exists():
                errors.append(f'{name}: missing local target {link}')
            elif url.fragment and target.suffix == '.md' and unquote(url.fragment) not in anchors(target.read_text()):
                errors.append(f'{name}: missing anchor {link}')
    for name in ACTIVE:
        if name not in (root / 'DEVELOPMENT.md').read_text():
            errors.append(f'DEVELOPMENT.md: active set omits {name}')
    if not 8 <= len((root / 'AGENTS.md').read_text().splitlines()) <= 25:
        errors.append('AGENTS.md: entry must remain short (8-25 lines)')
    panel = (root / 'ErgoPanel.qml').read_text()
    model = (root / 'ErgoModel.qml').read_text()
    handbook = (root / 'HANDBOOK.md').read_text()
    modules = (root / 'MODULES.md').read_text()
    backlog = (root / 'BACKLOG.md').read_text()
    for prop, value in [('preferredWidth', 736), ('contentHeight', 650)]:
        if not re.search(rf'property real {prop}: Style\.space\({value}\)', panel):
            errors.append(f'ErgoPanel.qml: recheck documented {prop}')
    if 'Style.space(736)' not in handbook or 'Style.space(650)' not in handbook:
        errors.append('HANDBOOK.md: missing current frame dimensions')
    if 'fixed 736 by 650' not in modules or 'fixed 736 by 650' not in backlog:
        errors.append('MODULES/BACKLOG: missing fixed-frame contract')
    stale = ('popup widens while editing', 'button editor replaces the diagram',
             'Confirming an assignment returns', 'replacement editor', '40-second overall')
    if any(term in handbook + modules + backlog for term in stale):
        errors.append('Current references contain obsolete interface/watchdog facts')
    finish = re.search(r'function finishButtonEdit\(\) \{([^}]+)\}', panel)
    if not finish or 'editingButton = false' in finish[1] or 'keeps the editor open' not in handbook:
        errors.append('HANDBOOK/source: recheck in-place assignment contract')
    if 'settingsDeadline.interval = 60000' not in model or '60-second overall watchdog' not in handbook:
        errors.append('HANDBOOK/source: recheck settings watchdog contract')
    if 'failed' not in backlog or 'Backtab' not in backlog or 'unchanged' not in backlog:
        errors.append('BACKLOG.md: original Backtab failure and unchanged-assertion recheck must stay visible')
    development = (root / 'DEVELOPMENT.md').read_text()
    if 'pre-existing failure blocks a full product PASS, not independent verified hygiene' not in development:
        errors.append('DEVELOPMENT.md: distinguish original failures from independent change gates')
    runner = (root / 'tests/run.sh').read_text()
    scheduled = set()
    for line in runner.splitlines():
        tokens = shlex.split(line, comments=True)
        if tokens and tokens[0] in ('node', 'python3', 'bash'):
            scheduled.update(token for token in tokens[1:] if token.startswith('$plugin_dir/tests/'))
    tests = sorted(path for path in (root / 'tests').iterdir()
                   if path.suffix in ('.py', '.js', '.sh') and path.name != 'run.sh')
    for path in tests:
        if f'$plugin_dir/tests/{path.name}' not in scheduled:
            errors.append(f'tests/run.sh: missing test entry {path.name}')
    if '/tests/ui' not in runner or "root / 'tests/profiles-ui'" not in (root / 'tests/profiles-ui.py').read_text():
        errors.append('QML interaction test directories are not covered by the runner')
    return errors


if __name__ == '__main__':
    root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors = check(root)
    for error in errors:
        print('FAIL: ' + error)
    if errors:
        raise SystemExit(1)
    print('PASS: active-set, current document links/facts and test-runner coverage; no runtime PASS implied.')
