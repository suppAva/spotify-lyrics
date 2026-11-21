# LyricSync

LyricSync 3 is a native Linux terminal viewer for Spotify-synchronized lyrics. One left-aligned document scrolls past a configurable vertical focus point. Recent and upcoming lines stay visible, wrapped lines move together, and real word timestamps add a mint karaoke highlight. The renderer writes foreground styles and leaves the background to the terminal.

## Install on Arch Linux

### From the AUR

Once the stable `lyricsync` package is published on the AUR, install it with:

```sh
yay -S lyricsync
```

For a local package before publication, build from your checkout using [the local Arch packaging instructions](#local-arch-package).

### From source

LyricSync requires Linux and Rust 1.88 or later. On Arch, install the system dependencies:

```sh
sudo pacman -S --needed base-devel rust cairo pango glib2 libfyaml libunistring playerctl curl coreutils
```

On other Linux distributions, install the equivalent packages, including development libraries for Cairo, Pango, GLib, libfyaml, and libunistring. Cargo can build LyricSync without downloading Rust crates. It does not install system packages.

```sh
cargo build --release --locked --offline
cargo install --locked --offline --path .
```

Ensure `${CARGO_HOME:-$HOME/.cargo}/bin` is on your PATH. If needed, add it to your shell startup file and open a new terminal:

```sh
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:$PATH"
```

You can also copy `target/release/lyricsync` to a user-owned bin directory on PATH. The installed binary works from any directory. From the source checkout you can try `./target/release/lyricsync` before installing it.

## Run

On your first run, set up LyricSync:

```sh
lyricsync --configure
```

Choose **Auto-detect**, **Kitty**, **Ghostty**, **WezTerm**, **Contour**, **Rio**, **Konsole**, **foot**, **xterm**, **Alacritty**, or **Other (text)**. Then enter a contact email for LRCLIB, or type `offline` to use local files and the cache. If you already ran `lyricsync --auth`, press Enter at the email prompt to keep your saved contact.

With desktop Spotify playing in the same session, run:

```sh
lyricsync
```

**Auto-detect** tries the Kitty graphics protocol first, then Sixel if the terminal advertises it. If graphics or pixel dimensions are unavailable, LyricSync draws terminal text. Choose **Alacritty** for synchronized text updates, or **Other (text)** to skip graphics detection. Use `--text` to select text for one run or `--graphics` to try pixel rendering even with a text profile. Fish, Bash, and Zsh can launch the same command.

| Terminal | Rendering |
| --- | --- |
| Kitty, Ghostty, WezTerm, Contour, Rio, Konsole | Kitty graphics if the capability probe succeeds |
| foot, xterm, other terminals that advertise Sixel | Sixel. xterm needs a Sixel-capable configuration, such as `xterm -ti vt340` |
| Alacritty | Synchronized text frames. Vertical movement follows whole terminal rows |
| Other terminals | Text fallback |

LyricSync saves the setup and contact under `${XDG_CONFIG_HOME:-$HOME/.config}/lyricsync` with owner-only permissions. Run `--configure` again to change the terminal or switch between online and offline, or `--auth` to update just the saved email. An existing `LYRICSYNC_LRCLIB_CONTACT` environment variable overrides the saved contact. LRCLIB receives the contact in the User-Agent and the track metadata needed to search. Spotify playback uses the desktop MPRIS interface and needs no OAuth credentials. [LRCLIB API documentation](https://lrclib.net/docs)

| Key | Action |
| --- | --- |
| `Q` or `Ctrl+C` | Quit and restore the terminal |
| `+` / `-` | Advance/delay displayed lyrics by 100 ms for this run |
| `R` | Reload the local override or ask the provider again |

Use `lyricsync --offline` to start with local and cached lyrics before setup or to skip online lookup for one run. Run `lyricsync -h` or `lyricsync --help` for all options.

## How lyrics are loaded

- Put UTF-8 LRC files in `${XDG_DATA_HOME:-$HOME/.local/share}/lyricsync/lyrics`, or pass `--lyrics-dir PATH`. LyricSync tries `spotify-TRACK_ID.lrc` first, then `Artist - Title.lrc`. In the second form, encode literal `%`, `/`, and backslash as `%25`, `%2F`, and `%5C`. The Spotify-reported artist and title supply the filename. Optional `[ar:]`, `[ti:]`, and `[al:]` tags must agree with available track metadata.
- Inspect the exact tags with `playerctl --player=spotify metadata --format '{{artist}} - {{title}} | {{xesam:url}} | {{mpris:trackid}}'`.
- The cache lives in `${XDG_CACHE_HOME:-$HOME/.cache}/lyricsync/v3`. Cached records are revalidated before display. Matching v2 cache entries are imported on demand. Online lookup checks track and artist names, album when present, and duration within two seconds. Conflicting search matches are skipped. The provider can still contain inaccurate transcriptions or timing, so a recording-specific LRC is the way to override them.
- LRCLIB attribution and lookup status appear in `--diagnose`, and in the optional `--log-file PATH` log. The active viewport contains lyrics only by default. Keep cached lyrics for personal playback and respect the rights that apply to their text.

Standard LRC, repeated line timestamps, and `[offset:]` work. Enhanced LRC uses angle-bracket start timestamps such as `[00:12.70]<00:12.70>Місто <00:13.40>дрімає`. Word times in LRCLIB’s Lyricsfile 1.0 payload are used when present and valid. When only line timing is available, LyricSync styles the line as a whole. Repeated LRC timestamps reuse the line text, with enhanced timing associated only with its first timestamp. [Lyricsfile timing specification](https://github.com/tranxuanthang/lyricsfile/blob/main/SPECIFICATION.md)

## Configuration

Save these overrides to `${XDG_CONFIG_HOME:-$HOME/.config}/lyricsync/config.toml`. Omitted values use the defaults shown. `--config PATH` selects another file. The configuration reader accepts the tables and scalar forms below, using simple quoted strings, booleans, integers and a decimal focus value.

```toml
[appearance]
left_padding = 4
line_spacing = 2
focus_position = 0.45
theme = "lavender"
show_previous = true
show_upcoming = true
gradient = true
fallback = ""

[animation]
enabled = true
target_fps = 60
scroll_duration_ms = 650
color_transition_ms = 350
easing = "ease_in_out_cubic"
pulse = true

[sync]
offset_ms = 0
word_highlighting = true

[spotify]
player = "spotify"
poll_interval_ms = 200

[lyrics]
provider = "lrclib"
cache_enabled = true
offline = false
```

Padding accepts 0–32 cells, spacing 0–8 rows, and focus 0.15–0.85 of the viewport height. Frame pacing accepts 15–60 FPS, animation durations 0–2000 ms, Spotify polling 100–2000 ms, and sync offsets ±60,000 ms. Positive offsets advance the lyrics. Scrolling advances by whole terminal rows at a steady cadence. The scroll duration sets the travel time for eight rows or more, and shorter moves finish sooner. Highlight easing also accepts `ease_out_cubic` and `spring`. Use `--reduced-motion` to disable scroll and color interpolation for one run. `NO_COLOR=1` uses text emphasis and underlining. Terminal capabilities determine truecolor or 256-color output.

### Kitty and Hyprland

If you want the desktop to show through the lyrics window, you can add `background_opacity 0.87` to your Kitty profile. Hyprland controls compositor blur separately. LyricSync leaves the terminal background at its default. The pixel renderer uses Pango’s system monospace font and draws a transparent image, so the font may differ from the terminal’s text font. Sixel uses a limited color palette and binary transparency, which can make glyph edges look sharper. [Kitty background opacity](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.background_opacity)

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Blank window | Start a track and run `lyricsync --diagnose` from the same Kitty session. It reports Spotify, the saved contact, and the lyric source or lookup failure. |
| `playerctl` missing | Install the `playerctl` package. It is required for live Spotify sync, including `--offline`. `--preview` works without it. |
| Spotify unavailable | Run `playerctl --player=spotify status` from the same desktop session. Open the native Spotify client and play a track. Brave and other players are excluded. |
| Online lookup disabled | Run `lyricsync --configure` and enter an email. Check for a stale `LYRICSYNC_LRCLIB_CONTACT` override if you have set it before. |
| No synchronized lyrics | Try a different recording or supply a track-specific LRC. Untimed text cannot follow playback. |
| Timing leads or lags | Adjust with `+` or `-`. To keep the setting, update `[sync].offset_ms`. |
| Text boxes or clipped wide glyphs | Check for UTF-8 and a Kitty font or fallback with the required glyphs. Unicode character widths can differ across terminals. |
| Need more context | Use `lyricsync --diagnose` or `lyricsync --log-file ./lyricsync.log`. |

## Preview and screenshots

```sh
lyricsync --preview examples/demo.lrc
```

Run from the checkout or pass an absolute path to the original demo. Preview works before setup and uses the same renderer detection as Spotify playback. Resize the terminal while the text scrolls. The Ukrainian word-timed line appears around 00:13. Capture the Kitty window with your usual screenshot or recording tool. Use the original demo for published screenshots and GIFs.

## Architecture and contributing

- `playback.rs` owns the playback worker. It reads Spotify metadata and position with one formatted `playerctl` call per sample.
- `provider.rs` handles local precedence, HTTPS through curl, strict LRCLIB matching, and private cache writes. Lookups run in cancellable workers. Generation checks discard stale results.
- `lyrics.rs` shares one timed representation across LRC, enhanced LRC, and Lyricsfile input. System libfyaml reads the provider’s JSON and YAML.
- `layout.rs` uses libunistring to wrap grapheme clusters. `motion.rs` and `view.rs` calculate scrolling and color in document coordinates. `terminal.rs` probes capabilities, writes changed text rows, and restores terminal settings on exit.
- `graphics.rs` rasterizes styled lyrics with Cairo and Pango. Graphics-capable terminals receive Kitty Graphics or Sixel frames.
- The UI uses monotonic time and bounded interpolation between Spotify position reports. It targets 60 FPS during playback and active transitions, skips unchanged output, and slows down while paused or waiting for lyrics. Kitty receives each changed frame as a synchronized update. Player polling has its own schedule.

Before submitting changes, run:

```sh
cargo fmt --check
cargo clippy --locked --all-targets -- -D warnings
cargo test --locked
cargo build --release --locked
```

Use original lyrics in fixtures. Include a targeted regression test for parser, timing, or rendering changes. For visual changes, include a recording with the demo at a narrow and a wide terminal size. The project uses the [MIT license](LICENSE).

### Local Arch package

Run the helper as your regular user after installing the Arch build dependencies above. It packages a snapshot of the checkout, verifies that snapshot's checksum, and writes the resulting package to `packaging/arch/dist/` by default.

```sh
packaging/arch/build-local.sh
sudo pacman -U packaging/arch/dist/lyricsync-3.0.0-1-x86_64.pkg.tar.zst
```

The package installs `/usr/bin/lyricsync`, the MIT license, documentation, and the demo. Check an installed package with `pacman -Qi lyricsync`. Spotify runs separately in the same desktop session. LRCLIB is needed for online lookups. The offline mode uses local files and the cache.

See the [changelog](CHANGELOG.md) for release notes and the [Arch release instructions](https://github.com/suppAva/spotify-lyrics/blob/main/packaging/arch/README.md) for verifying the tagged archive and preparing the AUR submission.
