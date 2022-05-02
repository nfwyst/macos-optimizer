#!/bin/bash
#
#    THESE SCRIPTS AND CHANGES ARE NOT MEANT FOR ANYBODY BUT ME.
#    RUNNING THESE WILL MESS UP YOUR COMPUTER IN MYSTERIOUS AND USUALLY UNRECOVERABLE WAYS.
#

############################################################################################
#    WARNING:        THESE SCRIPTS AND CHANGES ARE NOT MEANT FOR ANYBODY BUT ME.
#    RUNNING THESE WILL MESS UP YOUR COMPUTER IN MYSTERIOUS AND USUALLY UNRECOVERABLE WAYS.
############################################################################################

if [[ "$(sw_vers -productVersion)" != 10\.15* ]]; then
    echo "This is only meant to run on macOS 10.15.* Catalina" >&2
    exit 1
fi

LC_ALL=C
export LC_ALL

me="${0##*/}"

set -o errexit
set -o nounset
set -o pipefail

IFS=$'\n\t'

# IMPORTANT: Don't forget to logout from your Apple ID in the settings before running it!
signed_out=false
if [[ -z "$(command -v mas)" && -n "$(command -v brew)" ]]; then
    brew install mas
fi
if ! mas signout; then
    echo "Could not sign out of the apple store automatically." >&2
else
    signed_out=true
fi
if ! $signed_out; then
    reply=
    while [[ "$reply" != "OK" ]]; do
        echo "Please sign out of apple store before proceeding. Type OK when ready or press Ctrl+c to abort."
        read -r reply
    done
fi

# IMPORTANT: You will need to run this script from Recovery. In fact, macOS Catalina brings read-only filesystem which prevent this script from working from the main OS.
if ! csrutil status | grep -q ' disabled.$'; then
    echo "System Integrity Protection is enabled. Can not proceed." >&2
    exit 1
fi
sudo mount -uw /

# This script needs to be run from the volume you wish to use.
# E.g. run it like this: cd /Volumes/Macintosh\ HD && sh /Volumes/Macintosh\ HD/Users/sabri/Desktop/disable.sh
full_dir="$(cd "$(dirname $BASH_SOURCE)" && pwd)"
cd "/Volumes/Macintosh HD"
if [[ "${1-}" != "execed" ]]; then
    exec "/Volumes/Macintosh HD${full_dir}/${BASH_SOURCE##*/}" execed
fi

enable() {
    local what kind
    what="$1"
    kind="$2"

    cd "/Volumes/Macintosh HD"
    # if [[ ! -e ./System/Library/Launch${kind}s/${what}.plist ]]; then
    #     if [[ -e ./System/Library/Launch${kind}s/${what}.plist.org ]]; then
    #         if sudo mv "./System/Library/Launch${kind}s/${what}.plist.org" "./System/Library/Launch${kind}s/${what}.plist"; then
    #             echo "SUCCESS: ${kind} ${what} enabled"
    launchctl load -w "/System/Library/Launch${kind}s/${what}.plist" || true
    sudo launchctl load -w "/System/Library/Launch${kind}s/${what}.plist" || true
    return
    # fi
    # fi
    # echo "FAILURE: ${kind} ${what} could not be enabled"
    # fi
}

# Agents to enable
AGENTS_TO_ENABLE=()

AGENTS_TO_ENABLE+=(
  'com.apple.imklaunchagent'
)

for agent in "${AGENTS_TO_ENABLE[@]}"; do
    enable "${agent}" Agent
done
