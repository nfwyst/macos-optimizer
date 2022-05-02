#!/bin/bash

############################################################################################
#    WARNING:        THESE SCRIPTS AND CHANGES ARE NOT MEANT FOR ANYBODY BUT ME.
#    RUNNING THESE WILL MESS UP YOUR COMPUTER IN MYSTERIOUS AND USUALLY UNRECOVERABLE WAYS.
############################################################################################

if [[ "$(sw_vers -productVersion)" != 10\.15* ]]; then
  echo "This is only meant to run on macOS 10.15.* Catalina" >&2
  exit 1
fi

if [[ "${1-}" == "execed" ]]; then
  reply=
  printf "Are you pretty damn sure you want to run this? (Yes/No) "
  read -r reply
  if [[ $reply != Yes ]]; then
      echo "Needed a Yes to proceed" >&2
      exit 1
  fi
fi

LC_ALL=C
export LC_ALL

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
# shellcheck disable=SC2128
full_dir="$(cd "$(dirname "$BASH_SOURCE")" && pwd)"
cd "/Volumes/Macintosh HD"
if [[ "${1-}" != "execed" ]]; then
  exec "/Volumes/Macintosh HD${full_dir}/${BASH_SOURCE##*/}" execed
fi

disable() {
  local what kind
  what="$1"
  kind="$2"

  cd "/Volumes/Macintosh HD"
  # Yes, both without and with sudo - See https://www.chromium.org/developers/how-tos/debugging-on-os-x
  launchctl unload -wF "/System/Library/Launch${kind}s/${what}.plist" || true
  sudo launchctl unload -wF "/System/Library/Launch${kind}s/${what}.plist" || true
}

# Get active services: launchctl list | grep -v "\-\t0"
# Find a service: grep -lR [service] /System/Library/Launch* /Library/Launch* ~/Library/LaunchAgents

# Agents to disable
AGENTS_TO_DISABLE=()

# iCloud
AGENTS_TO_DISABLE+=(
  'com.apple.security.cloudkeychainproxy3'
	'com.apple.iCloudUserNotifications'
	'com.apple.icloud.findmydeviced.findmydevice-user-agent'
	'com.apple.icloud.fmfd'
	'com.apple.icloud.searchpartyuseragent'
	'com.apple.cloudd'
	'com.apple.cloudpaird'
	'com.apple.cloudphotod'
	'com.apple.followupd'
	'com.apple.protectedcloudstorage.protectedcloudkeysyncing'
)

# Safari useless stuff
AGENTS_TO_DISABLE+=(
  'com.apple.Safari.SafeBrowsing.Service'
  'com.apple.SafariBookmarksSyncAgent'
  'com.apple.SafariCloudHistoryPushAgent'
  'com.apple.SafariHistoryServiceAgent'
  'com.apple.SafariLaunchAgent'
  'com.apple.SafariNotificationAgent'
  'com.apple.SafariPlugInUpdateNotifier'
)

# iMessage / Facetime
AGENTS_TO_DISABLE+=(
  'com.apple.imagent'
  'com.apple.imautomatichistorydeletionagent'
  'com.apple.imtransferagent'
  'com.apple.avconferenced'
)

# reminder
AGENTS_TO_DISABLE+=(
  'com.apple.remindd'
)

# Map
AGENTS_TO_DISABLE+=(
  'com.apple.Maps.pushdaemon'
)

# Ad-related
AGENTS_TO_DISABLE+=(
  'com.apple.ap.adprivacyd'
  'com.apple.ap.adservicesd'
)

# Debugging process
AGENTS_TO_DISABLE+=(
  'com.apple.spindump_agent'
  'com.apple.ReportCrash'
  'com.apple.diagnostics_agent'
	'com.apple.ReportGPURestart'
	'com.apple.ReportPanic'
	'com.apple.DiagnosticReportCleanup'
	'com.apple.TrustEvaluationAgent'
)

# Screentime
AGENTS_TO_DISABLE+=(
  'com.apple.ScreenTimeAgent'
  'com.apple.UsageTrackingAgent'
)

# Apple Music/Music.app
AGENTS_TO_DISABLE+=(
  'com.apple.AMPDeviceDiscoveryAgent'
  'com.apple.AMPLibraryAgent'
  'com.apple.AMPArtworkAgent'
)

# VoiceOver / accessibility-related stuff
AGENTS_TO_DISABLE+=(
	'com.apple.voicememod'
)

# Homekit
AGENTS_TO_DISABLE+=(
  'com.apple.homed'
	'com.apple.familycircled'
	'com.apple.familycontrols.useragent'
	'com.apple.familynotificationd'
)

# Contacts
AGENTS_TO_DISABLE+=(
  'com.apple.suggestd'
  'com.apple.AddressBook.abd'
  'com.apple.AddressBook.SourceSync'
  'com.apple.AddressBook.AssistantService'
  'com.apple.AddressBook.ContactsAccountsService'
  'com.apple.contacts.donation-agent'
  'com.apple.ContactsAgent'
)

# Phone Call Handoff
AGENTS_TO_DISABLE+=(
  'com.apple.rapportd-user'
  'com.apple.telephonyutilities.callservicesd'
)

# Photos
AGENTS_TO_DISABLE+=(
  'com.apple.photolibraryd'
	'com.apple.mediastream.mstreamd'
	'com.apple.photoanalysisd'
)

# Others
AGENTS_TO_DISABLE+=(
  'com.apple.SocialPushAgent'
  'com.apple.macos.studentd'
  'com.apple.CommCenter-osx'
  'com.apple.touristd' # Shows what's new but keeps lingering around talking back to apple
  # mediaanalysisd photos that's identifying faces and objects.  It is CPU intensive process
  'com.apple.mediaanalysisd'
  'com.apple.mediaremoteagent'
  'com.apple.parsecd'
  'com.apple.identityservicesd'
  'com.apple.parentalcontrols.check'
  'com.apple.syncdefaultsd'
)

# helpd is a macOS agent that manages software documentation.
AGENTS_TO_DISABLE+=(
  'com.apple.helpd'
)

# AirDrop
AGENTS_TO_DISABLE+=(
  'com.apple.sharingd'
)

# Screensharing
AGENTS_TO_DISABLE+=(
  'com.apple.screensharing.MessagesAgent'
	'com.apple.screensharing.agent'
	'com.apple.screensharing.menuextra'
)

# Siri
AGENTS_TO_DISABLE+=(
  'com.apple.siriknowledged'
	'com.apple.assistant_service'
	'com.apple.assistantd'
	'com.apple.Siri.agent'
	'com.apple.knowledge-agent'
	'com.apple.parsec-fbf'
)

# Sidecar
AGENTS_TO_DISABLE+=(
  'com.apple.sidecar-hid-relay'
	'com.apple.sidecar-relay'
)

# Keyboard services
AGENTS_TO_DISABLE+=(
  'com.apple.keyboardservicesd'
	'com.apple.KeyboardAccessAgent'
)

for agent in "${AGENTS_TO_DISABLE[@]}"; do
  disable "$agent" Agent
done

# Daemons to disable
DAEMONS_TO_DISABLE=()

# iCloud
DAEMONS_TO_DISABLE+=(
  'com.apple.analyticsd'
	'com.apple.icloud.findmydeviced'
	'com.apple.icloud.searchpartyd'
)

# Screensharing
DAEMONS_TO_DISABLE+=(
  'com.apple.screensharing'
)

# Game Center
DAEMONS_TO_DISABLE+=(
  'com.apple.GameController.gamecontrollerd'
)

for daemon in "${DAEMONS_TO_DISABLE[@]}"; do
  disable "$daemon" Daemon
done

defaults write com.apple.systempreferences AttentionPrefBundleIDs 0
killall Dock
