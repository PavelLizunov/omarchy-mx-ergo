#!/usr/bin/python3 -I
"""Bounded, validated user preferences; atomic replacement preserves the last file."""
import json
import math
import os
from pathlib import Path
import signal
import stat
import sys
import tempfile

MAX_BYTES = 65536
BUTTONS = {'back', 'forward', 'middle', 'tiltLeft', 'tiltRight'}
ACTIONS = {'default', 'workspace_next', 'workspace_prev', 'window_close', 'window_float',
           'window_fullscreen', 'window_next', 'overview', 'screenshot', 'media_play_pause',
           'media_next', 'media_prev', 'mute', 'tab_next', 'tab_prev', 'browser_back',
           'browser_forward', 'custom_shortcut', 'custom_command'}


def validate(raw):
    if len(raw.encode('utf-8')) > MAX_BYTES:
        raise ValueError('Preferences exceed 64 KiB')
    cfg = json.loads(raw)
    if not isinstance(cfg, dict):
        raise ValueError('Preferences must be an object')
    for key, value in cfg.items():
        if key == 'sensitivity':
            valid = type(value) in (int, float) and math.isfinite(value) and -1 <= value <= 1
        elif key == 'accelProfile':
            valid = value in ('adaptive', 'flat')
        elif key in ('naturalScroll', 'autoReconnect'):
            valid = type(value) is bool
        elif key in ('buttons', 'customShortcuts', 'customCommands'):
            valid = isinstance(value, dict) and set(value) <= BUTTONS
            if valid:
                limit = 256 if key == 'customShortcuts' else 2048
                valid = all(isinstance(v, str) and '\x00' not in v and
                            (v in ACTIONS if key == 'buttons' else len(v) <= limit)
                            for v in value.values())
        else:
            valid = False
        if not valid:
            raise ValueError('Invalid preference: ' + key)
    return cfg


def read(path):
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    except FileNotFoundError:
        return None
    with os.fdopen(fd, 'rb') as stream:
        if not stat.S_ISREG(os.fstat(stream.fileno()).st_mode):
            raise ValueError('Preferences must be a regular file')
        raw = stream.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise ValueError('Preferences exceed 64 KiB')
    return validate(raw.decode('utf-8'))


def write(path, raw):
    cfg = validate(raw)
    path.parent.mkdir(parents=True, exist_ok=True)
    # Never follow a final symlink or replace a special file.
    if path.is_symlink() or (path.exists() and not path.is_file()):
        raise ValueError('Preferences must be a regular file')
    fd, name = tempfile.mkstemp(prefix='.mx-ergo-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            json.dump(cfg, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    signal.alarm(5)
    if len(sys.argv) < 3:
        raise ValueError('Invalid arguments')
    action, path = sys.argv[1:3]
    if action == 'read' and len(sys.argv) == 3:
        print(json.dumps(read(Path(path))))
    elif action == 'write' and len(sys.argv) == 4:
        write(Path(path), sys.argv[3])
    else:
        raise ValueError('Invalid arguments')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError) as error:
        print('MX Ergo: ' + str(error), file=sys.stderr)
        sys.exit(1)
