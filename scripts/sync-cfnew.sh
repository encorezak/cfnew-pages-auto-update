#!/usr/bin/env bash

set -euo pipefail

REPO_OWNER="${REPO_OWNER:-byJoey}"
REPO_NAME="${REPO_NAME:-cfnew}"
ASSET_NAME="${ASSET_NAME:-Pages.zip}"
TARGET_DIR="${TARGET_DIR:-site}"
VERSION_FILE="${VERSION_FILE:-.cfnew-release-version}"
API_URL="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"

echo "Fetching latest release metadata from ${API_URL}"
curl_args=(
  -fsSL
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
  -H "User-Agent: cfnew-auto-update"
)

if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  curl_args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

release_json="$(curl "${curl_args[@]}" "${API_URL}")"

export RELEASE_JSON="${release_json}"
export ASSET_NAME

tag_name="$(
  python3 - <<'PY'
import json
import os

data = json.loads(os.environ["RELEASE_JSON"])
print(data["tag_name"])
PY
)"

asset_url="$(
  python3 - <<'PY'
import json
import os
import sys

data = json.loads(os.environ["RELEASE_JSON"])
asset_name = os.environ["ASSET_NAME"]

for asset in data.get("assets", []):
    if asset.get("name") == asset_name:
        print(asset["browser_download_url"])
        break
else:
    sys.exit(f"Could not find asset: {asset_name}")
PY
)"

current_tag=""
if [[ -f "${VERSION_FILE}" ]]; then
  current_tag="$(<"${VERSION_FILE}")"
fi

if [[ "${current_tag}" == "${tag_name}" ]]; then
  echo "Latest release ${tag_name} is already synced. Nothing to do."
  exit 0
fi

work_dir="$(mktemp -d)"
archive_path="${work_dir}/${ASSET_NAME}"
extract_dir="${work_dir}/extracted"

cleanup() {
  rm -rf "${work_dir}"
}

trap cleanup EXIT

mkdir -p "${extract_dir}" "${TARGET_DIR}"

echo "Downloading ${ASSET_NAME} from ${asset_url}"
curl -fL "${asset_url}" -o "${archive_path}"

echo "Extracting archive into temporary directory"
unzip -oq "${archive_path}" -d "${extract_dir}"

echo "Syncing extracted files into ${TARGET_DIR}"
rsync -a --delete "${extract_dir}/" "${TARGET_DIR}/"

printf "%s\n" "${tag_name}" > "${VERSION_FILE}"
echo "Synced cfnew release ${tag_name} into ${TARGET_DIR}"
