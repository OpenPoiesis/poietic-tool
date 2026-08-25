# Advanced Commands and Options

Advanced option summary:

| Option | Overview |
|:----|:----|
| `--plane PLANE` | base edits on an existing plane by ID or name |
| `--replace NAME` | replace existing named plane, discarding the old one |
| `--no-append-history` | do not add the resulting edited plane to the undo/redo history |

The options are available to most of the `edit` sub-commands.

Advanced `edit` sub-commands:

| Command | Overview |
|:----|:----|
|`prune-history`| Remove all undo/redo planes from the design, keep only current plane and
  the planes not in the history |
|`create-plane`| Create a new plane or derive a copy from existing plane |
|`remove-plane`| Remove existing plane |

## Named Planes

The design contains a list of planes with names assigned to them. Those are typically planes used
by an application and are typically not part of the history. Wherever a plane reference
is used in the command-line tool, a plane name can be used.

Known plane names:

- `settings` – application settings for the design, such as zoom level, canvas view position, etc.
    It should contain at least one object of type `DiagramSettings`. See the metamodel, using the
    `metamodel DiagramSettings` command for more information.

### Replacing Named Planes

When editing a named plane using `--plane configuration` and it is intended to replace an
existing plane with the edited one, then `--replace configuration` can be used. The old plane
will be discarded and removed from the design. History will not be altered.

## Derive

When editing a plane, a new plane can be derived from a concrete existing plane using
`--plane PLANE` option. The `PLANE` can be either a plane ID or a plane name.

## Skipping History

When performing edits, result can be added to the design without being added to the undo/redo
history. Use the `--no-append-history` option.
