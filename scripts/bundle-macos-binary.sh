#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <source_binary> <bundle_dir>" >&2
  exit 1
fi

SOURCE_BINARY="$1"
BUNDLE_DIR="$2"

if [ ! -f "${SOURCE_BINARY}" ]; then
  echo "source binary not found: ${SOURCE_BINARY}" >&2
  exit 1
fi

mkdir -p "${BUNDLE_DIR}"
rm -rf "${BUNDLE_DIR}/lib"
cp "${SOURCE_BINARY}" "${BUNDLE_DIR}/graphql-engine"
chmod +x "${BUNDLE_DIR}/graphql-engine"
chmod u+w "${BUNDLE_DIR}/graphql-engine"

QUEUE_FILES=()
QUEUE_SOURCES=()
PROCESSED_FILES=()

contains() {
  local needle="$1"
  shift
  for item in "$@"; do
    if [ "${item}" = "${needle}" ]; then
      return 0
    fi
  done
  return 1
}

enqueue() {
  local file_path="$1"
  local source_path="${2:-}"

  if contains "${file_path}" "${PROCESSED_FILES[@]:-}"; then
    return
  fi
  if contains "${file_path}" "${QUEUE_FILES[@]:-}"; then
    return
  fi

  QUEUE_FILES+=("${file_path}")
  QUEUE_SOURCES+=("${source_path}")
}

get_rpaths() {
  local file_path="$1"
  otool -l "${file_path}" | awk '
    $1 == "cmd" && $2 == "LC_RPATH" {
      getline
      getline
      print $2
    }
  '
}

resolve_dep_path() {
  local dep="$1"
  local current_file="$2"

  case "${dep}" in
    /System/*|/usr/lib/*)
      return 1
      ;;
    /*)
      if [ -f "${dep}" ]; then
        printf '%s\n' "${dep}"
        return 0
      fi
      ;;
    @rpath/*)
      local rel_path="${dep#@rpath/}"
      while IFS= read -r rpath; do
        [ -n "${rpath}" ] || continue
        local base_dir="${rpath}"
        case "${rpath}" in
          @loader_path/*)
            base_dir="$(dirname "${current_file}")/${rpath#@loader_path/}"
            ;;
          @executable_path/*)
            base_dir="${BUNDLE_DIR}/${rpath#@executable_path/}"
            ;;
        esac
        local candidate="${base_dir}/${rel_path}"
        if [ -f "${candidate}" ]; then
          printf '%s\n' "${candidate}"
          return 0
        fi
      done < <(get_rpaths "${current_file}")
      ;;
    @loader_path/*)
      local candidate="$(dirname "${current_file}")/${dep#@loader_path/}"
      if [ -f "${candidate}" ]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
      ;;
    @executable_path/*)
      local candidate="${BUNDLE_DIR}/${dep#@executable_path/}"
      if [ -f "${candidate}" ]; then
        printf '%s\n' "${candidate}"
        return 0
      fi
      ;;
  esac

  local dep_name
  dep_name="$(basename "${dep}")"
  while IFS= read -r match; do
    [ -n "${match}" ] || continue
    printf '%s\n' "${match}"
    return 0
  done < <(
    find "${HOME}/.cabal/store" \
         "${HOME}/.ghcup" \
         "$(pwd)/graphql-engine-src/dist-newstyle" \
         "/opt/homebrew/opt/libpq/lib" \
         "/opt/homebrew/opt/unixodbc/lib" \
         "/opt/homebrew/opt/openssl@3/lib" \
         -type f -name "${dep_name}" 2>/dev/null
  )

  return 1
}

process_binary() {
  local file_path="$1"
  local source_path="${2:-}"

  if [ -n "${source_path}" ]; then
    install_name_tool -id "@executable_path/lib${source_path}" "${file_path}"
  fi

  while IFS= read -r dep; do
    [ -n "${dep}" ] || continue

    case "${dep}" in
      /System/*|/usr/lib/*)
        continue
        ;;
      @executable_path/lib/*)
        continue
        ;;
    esac

    local resolved_path
    if ! resolved_path="$(resolve_dep_path "${dep}" "${file_path}")"; then
      echo "unable to resolve dependency ${dep} for ${file_path}" >&2
      return 1
    fi

    local dest_path="${BUNDLE_DIR}/lib${resolved_path}"
    local rewritten="@executable_path/lib${resolved_path}"

    if [ ! -f "${dest_path}" ]; then
      mkdir -p "$(dirname "${dest_path}")"
      cp "${resolved_path}" "${dest_path}"
      chmod u+w "${dest_path}" || true
      enqueue "${dest_path}" "${resolved_path}"
    fi

    install_name_tool -change "${dep}" "${rewritten}" "${file_path}"
  done < <(otool -L "${file_path}" | tail -n +2 | awk '{print $1}')
}

enqueue "${BUNDLE_DIR}/graphql-engine" ""

idx=0
while [ "${idx}" -lt "${#QUEUE_FILES[@]}" ]; do
  current_file="${QUEUE_FILES[$idx]}"
  current_source="${QUEUE_SOURCES[$idx]}"
  idx=$((idx + 1))

  if contains "${current_file}" "${PROCESSED_FILES[@]:-}"; then
    continue
  fi
  PROCESSED_FILES+=("${current_file}")

  process_binary "${current_file}" "${current_source}"
done

while IFS= read -r dylib_path; do
  [ -n "${dylib_path}" ] || continue
  codesign --force --sign - "${dylib_path}"
done < <(find "${BUNDLE_DIR}/lib" -type f -name '*.dylib' | sort)
codesign --force --sign - "${BUNDLE_DIR}/graphql-engine"

echo "bundled ${#PROCESSED_FILES[@]} Mach-O files into ${BUNDLE_DIR}"
