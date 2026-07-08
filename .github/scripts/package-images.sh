#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:?platform required (e.g. linux/amd64)}"
ARCH_SUFFIX="${2:?arch suffix required (e.g. amd64)}"
ARCHIVE_NAME="${3:?archive name required (e.g. x86-64-images.tar.gz)}"
IMAGES="${4:?comma-separated docker images required}"

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

sanitize_image_name() {
  local name="${1//\//_}"
  name="${name//:/_}"
  printf '%s' "$name"
}

tar_files=()

IFS=',' read -r -a image_array <<< "$IMAGES"
for image in "${image_array[@]}"; do
  image="$(trim "$image")"
  [ -z "$image" ] && continue

  safe_name="$(sanitize_image_name "$image")"
  tar_file="${safe_name}-${ARCH_SUFFIX}.tar"

  docker pull "${image}" --platform "${PLATFORM}"
  docker save "${image}" -o "${tar_file}"
  tar_files+=("${tar_file}")
done

if [ "${#tar_files[@]}" -eq 0 ]; then
  echo "Error: No valid Docker images were provided."
  exit 1
fi

tar -czf "${ARCHIVE_NAME}" "${tar_files[@]}"
rm -f "${tar_files[@]}"

echo "Created ${ARCHIVE_NAME} with ${#tar_files[@]} image(s)."
