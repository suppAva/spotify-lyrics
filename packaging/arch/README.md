# Arch release and AUR submission

The upstream source is [suppAva/spotify-lyrics](https://github.com/suppAva/spotify-lyrics). The stable AUR package is `lyricsync`. Its recipe uses the GitHub source archive for the versioned tag and an exact SHA-256 digest. Leave a published tag in place, and release source changes under a new version.

## Before the tag

From the repository root, run the normal Rust checks and build a package from a local snapshot. The snapshot helper uses a temporary copy of the recipe with its own source URL and verified checksum.

```sh
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
cargo build --release --locked
packaging/arch/build-local.sh
```

With the source and release preparation committed on `main`, create and push the annotated tag:

```sh
git tag -a v3.0.0 -m 'LyricSync 3.0.0'
git push origin main
git push origin refs/tags/v3.0.0
```

## Verify the published archive

After the tag is visible on GitHub, run these commands from the repository root on Arch. Install `namcap` and `pacman-contrib` if needed. A fresh directory prevents `updpkgsums` from using an older cached copy. The `UNVERIFIED` checksum must be replaced before publication.

```sh
release_work=$(mktemp -d)
cp packaging/arch/PKGBUILD "$release_work/"
(
    set -eu
    cd "$release_work"
    export SRCDEST="$release_work" PKGDEST="$release_work"
    curl -fL https://github.com/suppAva/spotify-lyrics/archive/refs/tags/v3.0.0.tar.gz \
        -o lyricsync-3.0.0.tar.gz
    updpkgsums
    makepkg --verifysource
    makepkg --printsrcinfo > .SRCINFO
    makepkg --printsrcinfo | cmp - .SRCINFO
    bash -n PKGBUILD
    makepkg -s
    namcap PKGBUILD
    namcap lyricsync-3.0.0-1-x86_64.pkg.tar.zst
)
```

After the checks succeed, copy the verified recipe and metadata back to the repository:

```sh
cp "$release_work/PKGBUILD" "$release_work/.SRCINFO" packaging/arch/
git add packaging/arch/PKGBUILD packaging/arch/.SRCINFO
git commit -m 'Verify the LyricSync 3.0.0 AUR source archive'
git push origin main
```

Commit the digest to `main` after the tag. The AUR package uses the verified recipe from the AUR checkout to build the tagged application source. The checksum inside the tagged checkout does not participate in that build.

## Submit to the AUR

Before submitting, check [the AUR name search](https://aur.archlinux.org/packages?K=lyricsync) and [the official Arch package index](https://archlinux.org/packages/?q=lyricsync) again. The AUR account needs an SSH key. From the upstream checkout, use a new checkout outside the repository and commit only the submission files:

```sh
git clone ssh://aur@aur.archlinux.org/lyricsync.git ../lyricsync-aur
cp packaging/arch/PKGBUILD packaging/arch/.SRCINFO ../lyricsync-aur/
git -C ../lyricsync-aur add PKGBUILD .SRCINFO
git -C ../lyricsync-aur commit -m 'Add lyricsync 3.0.0-1'
git -C ../lyricsync-aur push -u origin HEAD:master
```

After publication, install with `yay -S lyricsync`. To install the locally verified archive instead, run:

```sh
sudo pacman -U "$release_work/lyricsync-3.0.0-1-x86_64.pkg.tar.zst"
lyricsync --version
```
