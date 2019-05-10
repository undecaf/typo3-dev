#!/bin/sh
#
#  This script mounts a Docker volume at a directory so that container
#  files and directories appear to be owned by the current user.
#

# --------------------------------------------------------------------------

# Prints usage information and an optional error message to stdout or stderr
# and exits with error code 0 or 1, respectively.
#
# Arguments:
#   $1  (optional) error message: if specified then it is printed, and all
#       output is sent to stderr;  otherwise output goes to stdout.
#
usage() {
  local SCRIPT=$(basename $0)
  local REDIR=
  local EXIT_CODE=0

  if [ -n "$1" ]; then
    cat >&2 <<- EOF

*** $1 ***
EOF
    REDIR=">&2"
    EXIT_CODE=1
  fi

  eval "cat $REDIR" <<- EOF

Usage: $SCRIPT <volume-name> <mount-directory>
       $SCRIPT -h

  This script mounts a Docker volume at a directory so that container
  files and directories appear to be owned by the current user.

  At least the parent directory of <mount-directory> must exist, and
  <mount-directory> must be empty.

  Options:
    -h  Displays this text and exits.

EOF
  exit $EXIT_CODE
}


# --------------------------------------------------------------------------

set -e

# Process options
while getopts h OPT; do
  case "$OPT" in
    h)
      usage
      ;;
    \?)
      usage "Unknown option: $OPT"
      ;;
  esac
done

# At least the parent directory of the mount directory must exist
MAPPED_DIR=$(readlink -f "$2")
MAPPED_PARENT=$(dirname "$MAPPED_DIR")

if [ ! -d "$MAPPED_PARENT" ]; then
    usage "$MAPPED_PARENT is not a directory but was expected to be"
fi

mkdir -p "$MAPPED_DIR"

# Mount directory not empty?
[ -n "$(ls -A "$MAPPED_DIR")" ] && usage "$MAPPED_DIR is not empty, will not proceed"

# Get the volume mount point
VOL_DIR=$(sudo docker volume inspect --format '{{.Mountpoint}}' "$1") \
    || usage "Volume '$1' not found"

# Determine UID and GID of the volume owner
VOL_UID=$(sudo stat --format '%u' $VOL_DIR)
VOL_GID=$(sudo stat --format '%g' $VOL_DIR)

sudo bindfs \
    --map=$VOL_UID/$(id -u):@$VOL_GID/@$(id -g) \
    $VOL_DIR \
    "$MAPPED_DIR"

echo "Docker volume '$1' now mounted at directory $MAPPED_DIR"
echo "To unmount: sudo umount \"$MAPPED_DIR\""
