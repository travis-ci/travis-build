ARTIFACTS_DEST=$HOME/bin/artifacts
OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
if [[ $ARCH == x86_64 ]] ; then
  ARCH=amd64
fi

mkdir -p $(dirname "$ARTIFACTS_DEST")
curl -sL -o "$ARTIFACTS_DEST" https://s3.amazonaws.com/meatballhat/artifacts/stable/build/$OS/$ARCH/artifacts
chmod +x "$ARTIFACTS_DEST"

PATH="$(dirname "$ARTIFACTS_DEST"):$PATH" artifacts -v
