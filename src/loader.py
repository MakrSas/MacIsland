"""Inject the Dynamic Island interposer into the next MenuBarAgent process."""

import fcntl
import os
from pathlib import Path
import re
import subprocess
import time


LAUNCHCTL = "/bin/launchctl"
SERVICE = f"gui/{os.getuid()}/com.apple.MenuBarAgent"
ENVIRONMENT_KEY = "DYLD_INSERT_LIBRARIES"
LIBRARY = str(Path.home() / "Library/MacIsland/island.dylib")


def menu_bar_agent_pid():
    """Return the current MenuBarAgent PID, or None while it is restarting."""
    try:
        output = subprocess.check_output([LAUNCHCTL, "print", SERVICE], text=True)
    except subprocess.CalledProcessError:
        return None
    match = re.search(r"^\s*pid = (\d+)", output, re.MULTILINE)
    return int(match.group(1)) if match else None


def main():
    library_path = Path(LIBRARY)
    if not library_path.is_file():
        raise RuntimeError("Missing island.dylib; no launch environment changed")

    # Prevent two login/reload events from racing while they temporarily change
    # the per-user launch environment.
    with (library_path.parent / "loader.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        domain = subprocess.check_output(
            [LAUNCHCTL, "print", f"gui/{os.getuid()}"], text=True
        )
        environment = re.search(
            r"^\tenvironment = \{\n(.*?)^\t\}", domain, re.MULTILINE | re.DOTALL
        )
        if environment is None:
            raise RuntimeError("Cannot establish prior launch environment")

        prior = re.search(
            rf"^\t\t{re.escape(ENVIRONMENT_KEY)} => (.*)$",
            environment.group(1),
            re.MULTILINE,
        )
        old_value = prior.group(1) if prior else None
        previous_pid = menu_bar_agent_pid()
        injected_value = library_path.as_posix()
        if old_value:
            injected_value = f"{old_value}:{injected_value}"

        try:
            subprocess.run(
                [LAUNCHCTL, "setenv", ENVIRONMENT_KEY, injected_value], check=True
            )
            subprocess.run([LAUNCHCTL, "kickstart", "-k", SERVICE], check=True)

            for _ in range(100):
                current_pid = menu_bar_agent_pid()
                if current_pid and current_pid != previous_pid:
                    print(f"MenuBarAgent started: {current_pid}", flush=True)
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError("MenuBarAgent did not report a new PID")
        finally:
            restore = (
                ["unsetenv", ENVIRONMENT_KEY]
                if old_value is None
                else ["setenv", ENVIRONMENT_KEY, old_value]
            )
            subprocess.run([LAUNCHCTL, *restore], check=True)
            print("Prior launch environment restored", flush=True)


if __name__ == "__main__":
    main()
