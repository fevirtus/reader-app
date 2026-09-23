#!/usr/bin/env python3
"""Run TTS regression tests in an isolated package, including background playback."""
import argparse
import os
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('device', help='ADB/Flutter device ID')
    parser.add_argument('--target', default='integration_test/tts_device_test.dart',
                        choices=['integration_test/tts_device_test.dart',
                                 'integration_test/sleep_timer_device_test.dart'])
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    env = dict(os.environ, READER_DEVICE_TEST='1')
    adb = ['adb', '-s', args.device]

    def original_path():
        return subprocess.run(
            [*adb, 'shell', 'pm', 'path', 'dev.fevirtus.reader'],
            check=False, capture_output=True, text=True,
        ).stdout.strip()

    before = original_path()
    process = subprocess.Popen(
        ['flutter', 'test', args.target, '-d', args.device],
        cwd=root, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, bufsize=1,
    )
    try:
        for line in process.stdout:
            print(line, end='', flush=True)
            if 'BACKGROUND_TEST_READY' in line:
                subprocess.run([*adb, 'shell', 'input', 'keyevent', 'KEYCODE_HOME'], check=True)
            elif 'BACKGROUND_TEST_DONE' in line:
                subprocess.run([
                    *adb, 'shell', 'monkey', '-p', 'dev.fevirtus.reader.test',
                    '-c', 'android.intent.category.LAUNCHER', '1',
                ], check=True, stdout=subprocess.DEVNULL)
        code = process.wait()
    finally:
        if process.poll() is None:
            process.terminate()
            process.wait()
        if before and original_path() != before:
            raise RuntimeError('Original Play Store package changed unexpectedly')
    return code


if __name__ == '__main__':
    sys.exit(main())
