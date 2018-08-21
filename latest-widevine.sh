# Shamelessly stolen from user ruario on Github
# https://gist.github.com/ruario/3c873d43eb20553d5014bd4d29fe37f1
#!/usr/bin/env bash

available () {
  command -v $1 >/dev/null 2>&1
}

# Make sure we have wget or curl
if available wget; then
  SILENT_DL="wget -qO-"
  LOUD_DL="wget"
elif available curl; then
  SILENT_DL="curl -s"
  LOUD_DL="curl -O"
else
  echo "Install wget or curl" >&2
  exit 1
fi

# Use the architecture of the current machine or whatever the user has set
# externally
ARCH=${ARCH:-$(uname -m)}

if [ "$ARCH" = "x86_64" ]; then
  WIDEVINE_ARCH="x64"
elif [[ "$ARCH" = i?86 ]]; then
  WIDEVINE_ARCH="ia32"
else
  echo "The architecture $ARCH is not supported." >&2
  exit 1
fi


# Set Output dir
WIDEVINE_INSTALL_DIR=${WIDEVINE_INSTALL_DIR:-/opt/google/chrome}

# Set temp dir
TMP=${TMP:-/tmp}

# Set staging dir
STAGINGDIR=$TMP/widevine-staging

# Work out the latest Widevine version
WIDEVINE_VERSION=${WIDEVINE_VERSION:-$($SILENT_DL https://dl.google.com/widevine-cdm/current.txt)}

# Error out if $CDMVERISON is unset, e.g. because previous command failed
if [ -z $WIDEVINE_VERSION ]; then
  echo "Could not work out the latest version; exiting" >&2
  exit 1
fi

# Don't start repackaging if the same version is already installed
if [ -e "$WIDEVINE_INSTALL_DIR/widevine-$WIDEVINE_VERSION" ] ; then
  echo "The latest Widevine ($WIDEVINE_VERSION) is already installed"
  exit 0
fi

# If the staging directory is already present from the past, clear it down
# and re-create it.
if [ -d "$STAGINGDIR" ]; then
  rm -fr "$STAGINGDIR"
fi

set -e
mkdir -p "$STAGINGDIR"
cd "$STAGINGDIR"

# Now get the latest widevine zip for the users architecture
$LOUD_DL "https://dl.google.com/widevine-cdm/${WIDEVINE_VERSION}-linux-${WIDEVINE_ARCH}.zip"

# Extract the contents of Widevine package
if available unzip; then
  unzip "${WIDEVINE_VERSION}-linux-${WIDEVINE_ARCH}.zip"
elif available bsdtar; then
  bsdtar xf "${WIDEVINE_VERSION}-linux-${WIDEVINE_ARCH}.zip"
else
  echo "Install unzip or bsdtar" >&2
  exit 1
fi

# Add version number file
touch "widevine-$WIDEVINE_VERSION"

# Escalate privileges if needed and copy files into place
if [ "$UID" = 0 ]; then
  install -Dm644 libwidevinecdm.so "$WIDEVINE_INSTALL_DIR/libwidevinecdm.so"
  install -Dm644 "widevine-$WIDEVINE_VERSION" "$WIDEVINE_INSTALL_DIR/widevine-$WIDEVINE_VERSION"
elif [ -r /etc/os-release ] && grep -qx 'ID=ubuntu' /etc/os-release; then
  echo "Calling sudo ... If prompted, please enter your password so Widevine can be copied into place"
  sudo install -Dm644 libwidevinecdm.so "$WIDEVINE_INSTALL_DIR/libwidevinecdm.so"
  if [ -e "$WIDEVINE_INSTALL_DIR/libwidevinecdm.so" ]; then
    sudo install -Dm644 "widevine-$WIDEVINE_VERSION" "$WIDEVINE_INSTALL_DIR/widevine-$CMDVERSION"
  else
    echo "Something went wrong installing libwidevinecdm.so" >&2
    exit 1
  fi
else
  echo "Please enter your root password so Widevine can be copied into place"
  su -c "sh -c \"install -Dm644 libwidevinecdm.so $WIDEVINE_INSTALL_DIR/libwidevinecdm.so && install -Dm644 widevine-$WIDEVINE_VERSION $WIDEVINE_INSTALL_DIR/widevine-$WIDEVINE_VERSION\""
fi

# Tell the user we are done
echo "Widevine ($WIDEVINE_VERSION) installed into $WIDEVINE_INSTALL_DIR"
