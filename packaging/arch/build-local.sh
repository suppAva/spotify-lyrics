#!/usr/bin/env bash
set -euo pipefail

recipe_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
project_dir=$(cd -- "$recipe_dir/../.." && pwd)
output_dir=${PKGDEST:-"$recipe_dir/dist"}
mkdir -p -- "$output_dir"
output_dir=$(cd -- "$output_dir" && pwd)

stage=$(mktemp -d)
trap 'rm -rf -- "$stage"' EXIT

version=$(sed -n 's/^version = "\([0-9][0-9.]*\)"$/\1/p' "$project_dir/Cargo.toml")
recipe_version=$(sed -n 's/^pkgver=//p' "$recipe_dir/PKGBUILD")
if [[ -z "$version" || "$version" != "$recipe_version" ]]; then
    printf 'Cargo.toml and PKGBUILD must have the same release version.\n' >&2
    exit 1
fi

archive="lyricsync-$version.tar.gz"
# Mirror the release archive's root directory and keep the upstream recipe intact.
tar -C "$project_dir" --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
    --transform="s,^,spotify-lyrics-$version/," \
    -cf - Cargo.toml Cargo.lock LICENSE README.md CHANGELOG.md src tests examples |
    gzip -n > "$stage/$archive"
read -r checksum _ < <(sha256sum -- "$stage/$archive")
sed -E \
    -e "s|^source=\(.*\)$|source=(\"$archive\")|" \
    -e "s|^sha256sums=\(.*\)$|sha256sums=('$checksum')|" \
    "$recipe_dir/PKGBUILD" > "$stage/PKGBUILD"

cd -- "$stage"
PKGDEST="$output_dir" SRCDEST="$stage" BUILDDIR="$stage" makepkg "$@"
