#!/usr/bin/env python3
"""Start the localhost-only QA server independently of the terminal session."""
import os, pathlib, shutil, subprocess, time, urllib.request
root = pathlib.Path(__file__).resolve().parents[1]
url = 'http://localhost:8791/api/health'
try:
    with urllib.request.urlopen(url, timeout=2) as response:
        print('QA server already responds:', response.status)
except OSError:
    env = dict(os.environ, PORT='8791', HOST='127.0.0.1',
               DB_PATH='/private/tmp/mori-qa-flow-20261108.sqlite',
               ALLOWED_ORIGINS='http://localhost:8791')
    with open('/private/tmp/mori-qa-server.log', 'ab') as log:
        child = subprocess.Popen([shutil.which('node'), '--env-file=.env', 'src/index.js'],
            cwd=root / 'server', env=env, stdin=subprocess.DEVNULL,
            stdout=log, stderr=log, start_new_session=True)
    for _ in range(30):
        try:
            with urllib.request.urlopen(url, timeout=1) as response:
                print('QA server ready:', response.status, 'PID:', child.pid)
                break
        except OSError:
            time.sleep(.2)
    else:
        raise SystemExit('QA server failed. See /private/tmp/mori-qa-server.log')
