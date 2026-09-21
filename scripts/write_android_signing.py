"""Write Java properties without corrupting special characters in signing secrets."""

import os
from pathlib import Path


def escape_property(value: str) -> str:
    escaped = []
    for char in value:
        if char in "\\ :=#!":
            escaped.append("\\" + char)
        elif char == "\n":
            escaped.append("\\n")
        elif char == "\r":
            escaped.append("\\r")
        elif char == "\t":
            escaped.append("\\t")
        elif not 32 <= ord(char) <= 126:
            encoded = char.encode("utf-16-be")
            escaped.extend("\\u" + encoded[i:i + 2].hex() for i in range(0, len(encoded), 2))
        else:
            escaped.append(char)
    return "".join(escaped)


def main() -> None:
    values = {
        "storeFile": "release.keystore",
        "storePassword": os.environ["ANDROID_KEYSTORE_PASSWORD"],
        "keyAlias": os.environ["RESOLVED_KEY_ALIAS"],
        "keyPassword": os.environ["ANDROID_KEY_PASSWORD"],
    }
    target = Path("android/key.properties")
    target.touch(mode=0o600, exist_ok=True)
    target.chmod(0o600)
    target.write_text("".join(f"{key}={escape_property(value)}\n" for key, value in values.items()), encoding="ascii")


if __name__ == "__main__":
    main()
