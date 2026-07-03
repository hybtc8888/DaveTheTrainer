#!/usr/bin/env bash
set -euo pipefail

APP_NAME="DaveTheTrainer"
OLD_APP_NAME="DaveTrainer"
SUDOERS_NAME="davethetrainer"
OLD_SUDOERS_NAME="davetrainer"

if [[ "${1:-}" != "--legacy-cleanup" ]]; then
  echo "Refusing to remove privileged legacy files without --legacy-cleanup" >&2
  echo "usage: $0 --legacy-cleanup" >&2
  exit 2
fi

sudo rm -f "/etc/sudoers.d/$SUDOERS_NAME"
sudo rm -f "/etc/sudoers.d/$OLD_SUDOERS_NAME"
sudo rm -rf "/Applications/$APP_NAME.app"
sudo rm -rf "/Applications/$OLD_APP_NAME.app"

echo "Removed /Applications/$APP_NAME.app"
echo "Removed /Applications/$OLD_APP_NAME.app"
echo "Removed /etc/sudoers.d/$SUDOERS_NAME"
echo "Removed /etc/sudoers.d/$OLD_SUDOERS_NAME"
