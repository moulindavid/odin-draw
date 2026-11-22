# excalidraw-local

A local whiteboard for drawing and writing, built with Odin and raylib.

## Build

```sh
./build.sh
./build/excalidraw-local [board.json]
```

Without a file argument the board is saved to `untitled.json`. Drop a `.json` file on the window to open it.

## Shortcuts

| Key | Action |
|---|---|
| `V` `1` | Select |
| `R` `2` | Rectangle |
| `O` `3` | Ellipse |
| `A` `4` | Arrow |
| `L` `5` | Line |
| `P` `6` | Freehand |
| `T` `7` | Text |
| `Ctrl+S` | Save |
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo / Redo |
| `Delete` | Delete selection |
| Wheel | Zoom |
| `Space`+drag, middle drag | Pan |

## License

GPL-3.0
