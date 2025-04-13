# Advanced Commands and Options

Advanced option summary:

| Option | Overview |
|:----|:----|
| `--derive FRAME` | derive an existing frame by ID or name |
| `--replace NAME` | replace existing named frame, discarding the old one |
| `--no-append-history` | do not add the resulting edited frame to the undo/redo history |

The options are available to most of the `edit` sub-commands.

Advanced `edit` sub-commands:

| Command | Overview |
|:----|:----|
|`prune-history`| Remove all undo/redo frames from the design, keep only current frame and
  the frames not in the history |
|`create-frame`| Create a new frame or derive a copy from existing frame |
|`remove-frame`| Remove existing frame |

## Named Frames

The design contains a list of frames with names assigned to them. Those are typically frames used
by an application and are typically not part of the history. Wherever a frame reference
is used in the command-line tool, a frame name can be used.

Known frame names:

- `settings` – application settings for the design, such as zoom level, canvas view position, etc.
    It should contain at least one object of type `DiagramSettings`. See the metamodel, using the
    `metamodel DiagramSettings` command for more information.

### Replacing Named Frames

When editing a named frame using `--derive configuration` and it is intended to replace an
existing frame with the edited one, then `--replace configuration` can be used. The old frame
will be discarded and removed from the design. History will not be altered.

## Derive

When editing a frame, a new frame can be derived from a concrete existing frame using
`--derive FRAME` option. The `FRAME` can be either a frame ID or a frame name.

## Skipping History

When performing edits, result can be added to the design without being added to the undo/redo
history. Use the `--no-append-history` option.

