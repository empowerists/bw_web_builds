#!/usr/bin/env bash
set -o pipefail -o errexit
BASEDIR=$(RL=$(readlink -n "$0"); SP="${RL:-$0}"; dirname "$(cd "$(dirname "${SP}")"; pwd)/$(basename "${SP}")")

# Error handling
handle_error() {
    read -n1 -r -p "FAILED: line $1, exit code $2. Press any key to exit..." _
    exit 1
}
trap 'handle_error $LINENO $?' ERR

# Load default script environment variables
# shellcheck source=.script_env
. "${BASEDIR}/.script_env"

pushd "${VAULT_FOLDER}"

VAULT_VERSION=$(get_web_vault_version)
# Check if the vault versions starts with 20 and isn't a 40 char hash
if [[ ${VAULT_VERSION} = 20* ]] && [ ${#VAULT_VERSION} -ne 40 ]; then
    VAULT_VERSION="v${VAULT_VERSION}"
fi
PATCH_FILENAME="${VAULT_VERSION}.patch"

if [ "$(git status --porcelain | wc -l)" -ge 1 ]; then
    git add -A
    git --no-pager diff --cached --no-color --minimal --abbrev=10 -- . \
      ':!package-lock.json' \
      ':!apps/web/src/app/layouts/password-manager-logo.ts' \
      ':!libs/auth/src/angular/icons/bitwarden-logo.icon.ts' \
      ':!libs/auth/src/angular/icons/bitwarden-shield.icon.ts' \
      ':!bitwarden_license/' \
      ':!apps/web/src/app/tools/access-intelligence/' \
      > "../patches/${PATCH_FILENAME}"
    git reset -q
    echo "Patch has been created here: patches/${PATCH_FILENAME}"
else
    echo "No changes found, skip generating a patch file."
fi

popd
