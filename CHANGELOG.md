# Changelog

## 3.0.0

- Display synchronized Spotify lyrics in a terminal using desktop MPRIS playback information.
- Load standard and enhanced LRC from local files or the cache, and look up timed lyrics through LRCLIB. Use word timestamps from enhanced LRC or Lyricsfile when available.
- Render pixel scrolling through Kitty Graphics or Sixel when supported. Fall back to terminal text elsewhere.
- Configure LRCLIB and terminal preferences with `--configure`. Use `--preview` to try the viewer without Spotify, or `--diagnose` to inspect the current playback and lyric source.
- Package the stable release for Arch Linux as `lyricsync`.
