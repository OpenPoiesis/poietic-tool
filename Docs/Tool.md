# Command Line Tool

Poietic Flows includes a command-line tool to create, edit and run
Stock and Flow models.

Usage:

```sh
poietic <subcommand> [options]
```

To get help use `--help` either to the top-level tool or to any sub-command:
```sh
poietic --help
poietic edit --help
poietic edit add --help
```

Command summary:

| Command | Overview |
|:----|:----|
|`new`| Create an empty design |
|`info`| Get information about the design |
|`list`| List design content objects |
|`show`| Describe an object |
|`validate`| Validate the design for potential errors |
|`edit`| Edit an object or a selection of objects _(see subcommands below)_ |
|`import`| Import a plane into the design |
|`export`| Export current plane or a collection of objects |
|`run`| Run the simulation and generate output |
|`write-dot`| Write a Graphviz DOT file |
|`metamodel`| Describe the metamodel (various output formats)|
|`create-library`| Create a library of multiple models |
|`export-svg`| Export design as an SVG diagram |

Edit sub-commands:

| Command | Overview |
|:----|:----|
|`set`| Set an attribute value |
|`undo`| Undo last change |
|`redo`| Redo undone change |
|`add`| Create a new node or an unstructured object |
|`connect`| Create a new connection (edge) between two nodes |
|`remove`| Remove an object – a node or a connection |
|`auto-parameters`| Automatically connect parameter nodes: connect required, disconnect unused |
|`layout`| Lay out objects |
|`align`| Align objects on canvas |
|`prune-history`| Remove all undo/redo history |
|`create-plane`| Create a new plane or derive a copy from existing plane |
|`remove-plane`| Remove existing plane |


## Commons

Before describing the commands in detail, here are some commonalities of all
the commands.

### Specifying Design File

Most of the commands operate on a design file. Due to iterative usage of the
tool, the design file is not specified on each invocation explicitly.
The default design file name is `design.poietic`. To use another name either
specify an environment variable `POIETIC_DESIGN` or use the `-d` option.
The following three invocations are equivalent:

```bash
# Explicit
poietic new -d MyDesigns/my.poietic
poietic new --design MyDesigns/my.poietic

# Environment variable
export POIETIC_DESIGN=MyDesigns/my.poietic
poietic new
```

### Object References

Multiple commands operating on objects expect an object reference. For example
the `show` command or any of the `edit` sub-commands. Object reference can be
given directly either as object ID or as object name.

When an object ID is provided, it must exist in the current plane.

When an object name is provided and multiple objects carry the same name, then
one of the objects is selected arbitrarily. It is advised to reference objects
by their names only when it is assured that only one object with given name
exists.

### Metamodel and Object Types

To get the list of object types that the tool supports and to get more
information about the metamodel, run `poietic metamodel`. See the
Metamodel Command documentation for more information.


## New Command

Create a new, empty database. Usage:

```bash
USAGE: poietic new [--design <design>] [--import <import> ...]
```

Options:

- `-i`, `--import <import>`: Poietic plane to import into the first plane. See
  `import` command for more information.


During the creation of a new plane the user has an option to import one or
multiple planes that will be combined into the first plane of the design.

Example:

```
% poietic new --import ../poietic-examples/ThinkingInSystems/Capital.poietic
Importing from: ../PoieticExamples/ThinkingInSystems/Capital.poietic
Design created: design.poietic
```

See also: `auto-parameters` subcommand of `edit`.


## Info Command

Get information about the design.

Usage:

```bash
poietic info [--design <design>] [--plane <plane>]
```

Options:

- `--plane <plane>`: Plane ID or name. Default is current.

## List Command

List design content objects.

Usage:

```
poietic list [--design <design>] [--plane <plane>] [--type <type>] [<list-type>]
```

`--plane` Specifies which plane to list. If not specified, the default plane is used.

Lists `--type` types for objects and object-related properties:

- `all`: List all objects in the design in groups: unstructured objects, nodes and
   edges. Each entry contains object ID, object type name and object name.
- `names`: list only names of objects.
- `formulas`: List arithmetic formulas in the form: `name = formula`, for example
  `growth_goal = capital * 0.1`.
- `pseudo-equations`: List equations for stocks.
- `graphical-functions`: List graphical function points.

Lists types for planes:

- `named-planes`: List of planes that have a name associated, such as application configuration
- `planes`: List of plane IDs.
- `history`: List plane IDs for undo and redo history.

## Show Command

Describe a design object.

Usage:

```sh
poietic show [--design <design>] [--plane <plane>] [--debug] <reference>
```

Arguments:

- `<reference>`: ID or a name of an object to be described.

Options:

- `--plane <plane>`: Plane to get object from. Default is current plane.
- `--debug`: Show detailed debug information.

The text output is grouped by traits of object's type.

Example:

```
% poietic show depreciation
Type                : FlowRate
Object ID           : 26
Snapshot ID         : 27
Topology            : node
Traits:             : Name, Formula, FlowRate, ComputedValue, NumericIndicator, DiagramNode

Attributes
name                : depreciation
formula             : capital / capital_lifetime
priority            : 0
z_index             : 0
```

## Import Command

Import a plane into the design.

Usage:

```sh
poietic import [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] [--identity <identity>] <file-name>
```

Arguments:

- `<file-name>`: Path to a poietic design to import from.

Options:

- `--plane <plane>`: Plane ID or name to base edits on. If not provided, current is used.
- `--replace <replace>`: Plane name to replace.
- `--append-history` / `--no-append-history`: If true, then the plane will be added to history (if not named). Default: `--append-history`.
- `--identity <identity>`: Object identity mode. Values: `require`, `auto`, `new`. Default: `require`.

Imports a poietic plane file or a bundle into the design. See documentation
of the plane file or a bundle for more information.

Notes:

- If the imported plane requires explicit object IDs, then the design
  the plane is being imported to must not contain objects with given IDs.
- The imported plane must contain only types the design supports.
- Topology type of the imported objects (node, edge, unstructured) is
  determined by the target design object types.

Current shortcomings, which might be resolved in the future:

- Imported plane has no way to specify edges between its objects and the target
  design objects.
- User has no way to ignore imported IDs, this should be an option.

See also: `auto-parameters` subcommand of `edit`.


## Validate Command

Validate design or a single plane.

Usage:

```sh
poietic validate [--design <design>] [--plane <plane>]
```

Options:

- `--plane <plane>`: Plane to be validated. Default: current plane.

## Export Command

Export current plane or a collection of objects.

Usage:

```sh
poietic export [--design <design>] [--plane <plane>] [--output <output>] [<references> ...]
```

Arguments:

- `<references>`: List of references of objects to be exported. Default: all objects in a plane.

Options:

- `--plane <plane>`: Plane to be exported. Default: current plane.
- `-o, --output <output>`: Output path. Default or '-' is standard output.

## Run Command

Run the simulation and generate output.

Usage:

```
poietic run [--design <design>] \
    [--start-time <start-time>] \
    [--steps <steps>] \
    [--time-delta <time-delta>] \
    [--solver <solver>] \
    [--output-format <output-format>] \
    [--variable <variable> ...] \
    [--parameter <parameter> ...] \
    [--plane <plane>] \
    [--output <output>]
```

Options:

- `--start-time <start-time>`: Initial time, overrides design-specified initial time.
- `-s, --steps <steps>`: Maximum number of steps to run, before end-time is reached.
- `-t, --time-delta <time-delta>`: Time delta, overrides design-specified time delta.
- `--solver <solver>`: Type of the solver to be used for computation. Default: `euler`.
- `-f, --output-format <output-format>`: Output format, see below.
- `-V, --variable <variable>`: Values to observe in the output; can be object IDs or object names.
  If not specified, all simulation variables are used.
- `-p, --parameter <parameter>`: Set (override) a numeric value of a parameter node in a
  form 'object_name=value'.
- `--plane <plane>`: Plane name or ID to run. Default: current plane.
- `-o, --output <output>`: Output path. Default or '-' is standard output.

Output formats:

- `csv`: Create a CSV file where columns represent either builtin-variables
  (such as time) or value of one simulation object (stock, flow, auxiliary.
  Column names are object or variable names. Row is a simulation step.
- `gnuplot`: Create an output for chart objects, one gnuplot file per chart,
  to be processed later by [gnuplot](http://gnuplot.info).


### Simulation Defaults

The `run` command is trying to get simulation defaults contained within the
design. The defaults are stored in a singleton object of type `Simulation`.
Run the metamodel command for more information about the list of options
that can be set for the simulation defaults:

```bash
poietic metamodel Simulation
```


### Gnuplot Output

To process the generated gnuplot files run: `gnuplot *.gnuplot`.


## Editing Commands

There are multiple commands for model editing:

- `set`: Set an attribute value
- `undo`: Undo last change
- `redo`: Redo undone change
- `add`: Create a new node or an unstructured object
- `connect`: Create a new connection (edge) between two nodes
- `remove`: Remove an object – a node or a connection
- `auto-parameters`: Automatically connect parameter nodes: connect required, disconnect unused
- `layout`: Lay out objects
- `align`: Align objects on canvas
- `prune-history`: Remove all undo/redo history
- `create-plane`: Create a new plane or derive a copy from existing plane
- `remove-plane`: Remove existing plane

All edit commands alter the history which can be reversed. The editing commands
are not destructive to the design, simply use `undo` and `redo` edit commands
to revert undesired changes.

### Set Attribute Command

Set an attribute value.

Usage:

```sh
poietic edit set [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] <reference> <attribute-name> <value>
```

Arguments:

- `reference`: ID or a name of an object to be modified. See the section
  about object references for more information.
- `attribute-name`: Name of the attribute to be set.
- `value`: Attribute value to be set.

The type of the attribute is determined by the object type. The following rules
apply:

- If the type is a string, the value is used as-is.
- If the type is numeric or boolean, the value must be convertible to the type.
- If the type is a point, the value is `[x, y]`, for example: `"[100, 0]"` for
  a point at `x=100` and `y=0`.
- If the type is an array, then the value string is a JSON representation of
  the array, for example: `"[10, 20, 30, 40]"`

### Undo Command

Undo last change.

The previous plane in the history will become the current plane. All planes
that are undone are preserved until a next change. On a change, the planes
held in the undo-buffer are removed.

### Redo Command

Redo last undone change.

The next plane in the history after the current plane will become current.

### Add Object Command

Create a new node or an unstructured object.

Usage:

```sh
poietic edit add [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] <type-name> [<attribute-assignments> ...]
```

Examples:

```
poietic edit add Stock name=account formula=100
poietic edit add FlowRate name=expenses formula=50
```

Arguments:

- `<type-name>`: Type of the object to be created.
- `<attribute-assignments>`: Attributes to be set in form 'attribute=value'.

To get a list of types that can be created, run:

```sh
poietic metamodel
```

To get more information about the type and its attributes, run:

```sh
poietic metamodel TYPE_NAME
```

For example:

```sh
poietic metamodel Stock
poietic metamodel DesignInfo
```

### Connect Command

Create a new connection (edge) between two nodes.

Usage:

```sh
poietic edit connect [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] <type-name> <origin> <target>
```

Arguments:

- `type-name`: Type of the connection to be created
- `origin`: Reference to the connection's origin node
- `target`: Reference to the connection's target node

See section about Object References for more information.

_Note:_ To set attributes on an edge use the `edit set` command. Currently it is
not possible to set attributes during edge creation.


### Remove Command

Remove an object – a node or a connection.

Usage: 
```sh
poietic edit remove [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] <reference>
```

Arguments:

- `reference`: Object to be removed. See Object References for more information.

If the object is a node and there are any edges connected with the node, then
all the edges are removed as well.

### Auto-Parameters Command

Automatically connect parameter nodes: connect required, disconnect unused.

```sh
poietic edit auto-parameters [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] [--verbose]
```

Options:

- `-v, --verbose`: Print IDs of created and removed edges.

The Stock and Flow model requires that all parameters used in formulas
must be connected to their corresponding nodes. Moreover, there must be no
connected parameters that are not used in the model. If this requirement is not
satisfied, the simulation planning/validation fails and it will be not
possible to simulate it. This is a design principle, not a fussiness of the
simulation planner.

This command connects the required parameter nodes and removes connections
from the nodes that are not used in the formulas.

### Layout Command

Lay out objects in 2D space.

_Note_: This is a preview feature. Use with caution.

Usage:

```sh
poietic edit layout [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] [--layout <layout>] [<references> ...]
```

Arguments:

- `references`: Objects to be laid out. If not specified, then all objects
  with a position attribute or with the DiagramBlock trait are considered.

Options:

- `--layout`: Type of the layout to use.

Currently there is only one layout style: `circle`, which lays out the nodes
in a circle in order as specified.

### Align Command

Align objects on canvas.

_Note_: Preliminary functionality, a preview of a possibility. Might not
function to full satisfaction.

Usage:

```sh
poietic edit align [--design <design>] [--plane <plane>] [--replace <replace>] [--append-history] [--no-append-history] <mode> [--spacing <spacing>] <references> ...
```

Arguments:

- `mode`: Alignment mode – see below.
- `references`: Objects to be aligned.

Options:

- `--spacing <spacing>`: Spacing between objects (default: 10.0).

Alignment modes:

- Alignment: `left`, `center-horizontal`, `right`, `top`,
  `center-vertical`, `bottom`
- Offset: `offset-horizontal`, `offset-vertical`
- Spread: `spread-horizontal`, `spread-vertical`


### Prune History Command

Remove all planes in the undo/redo history and keep just the current plane.

Usage:

```sh
poietic edit prune-history [--design <design>]
```

### Create Plane Command

Create a new plane or derive a copy from existing plane.

Usage:

```sh
poietic edit create-plane [--design <design>] [--derive <derive>] [--name <name>] [--id <id>] [--force] [--append-history]
```

Options:

- `--derive <derive>`: Derive an existing plane.
- `--name <name>`: Create a named plane with given name.
- `--id <id>`: Create a plane with given id.
- `--force`: Replace existing named plane.
- `--append-history`: Append plane to the undo history.

### Remove Plane Command

Remove a plane.

Usage:

```sh
poietic edit remove-plane [--design <design>] <references> ...
```

Arguments:

- `<references>`: IDs or names of planes to be removed.

## Metamodel Command

Show information about the metamodel and object types.

Options:

- `-f`/`--output-format`: Output format. Available: `text` (default), `markdown` and
`html`.

Usage:

```sh
 poietic metamodel [--output-format <output-format>] [<object-type>]
```

If `object-type` is provided, then the command lists all attributes of the 
object type and their description. If `object-type` is not provided, then the
command lists all object types and constraints.

Example output of `poietic metamodel` (trimmed):

```
TYPES AND COMPONENTS

DesignInfo (unstructured)
    title (string)
        - Design title
    author (string)
        - Author of the design
    ...
...

Stock (node)
    name (string)
        - Object name
    color (string)
        - Colour name
    formula (string)
        - Arithmetic formula or a constant value represented by the node
    allows_negative (bool)
        - Flag whether the stock can contain a negative value
    position (point)
    ...
...

FlowRate (node)
    name (string)
        - Object name
    color (string)
        - Colour name
    formula (string)
        - Arithmetic formula or a constant value represented by the node
    position (point)
    ...
...

Simulation (unstructured)
    initial_time (double)
        - Initial simulation time
    time_delta (double)
        - Advancement of time for each simulation step
    end_time (double)
        - Final simulation time
    steps (int)
        - Number of steps the simulation is run by default [deprecated]
    solver_type (string)
        - Solver type name

...

```

Output of `poietic metamodel Stock`:

```
Stock (node)
    name (string)
        - Object name
    formula (string)
        - Arithmetic formula or a constant value represented by the node.
    allows_negative (bool)
        - Flag whether the stock can contain a negative value.
    position (point)
    z_index (int)
```

Try:

```
poietic metamodel Flow
poietic metamodel Stock
poietic metamodel DesignInfo
poietic metamodel Simulation
```

Create a `metamodel.html` file with full description of currently available
metamodel:

```
poietic metamodel -f html > metamodel.html
```


## Create Library Command

Create a library info referencing multiple models. The command creates a
library description from a given list of design files. The library info is used
by the Poietic Server (preview).

_Note_: This is a preview feature. Use with caution.

Use:

```sh
poietic create-library [--output-file <output-file>] <designs> ...
```

The command takes a list of design files (_important_: not a list of planes).
The command extracts `DesignInfo` from the designs. If multiple instances of
`DesignInfo` are present, then one is chosen arbitrarily.


See also: [Poietic Server](https://github.com/OpenPoiesis/poietic-server)
(preview package, unstable).



## Write Graphviz Dot File Command

Write a [Graphviz](https://graphviz.org) DOT file.

_Note:_ This command is not using Graphviz directly, it just generates a file
that is processable by the Graphviz toolkit.

Usage:

```sh
poietic write-dot [--design <design>] \
                    [--name <name>] \
                    [--output <output>] \
                    [--label-attribute <label-attribute>] \
                    [--missing-label <missing-label>] \
                    [--plane <plane>]
```

Options:

- `-n, --name <name>`: Name of the graph in the output file (default: output)
- `-o, --output <output>`:   Path to a DOT file where the output will be
   written. (default: output.dot)
- `-l, --label-attribute <label-attribute>`: Node attribute that will be used
   as node label (default: id).
- `-m, --missing-label <missing-label>`: Label used if the node has no label
   attribute (default: `(none)`)
- `--plane <plane>`: Plane ID or name.

Practical options:
- Use `-l name` to display node name
- Use `-l formula` to display arithmetic formula of the node.

If you have Graphviz installed, then to process the generated file
(assuming default `output.dot` output), run:

```
dot -Tpng -odiagram.png output.dot
```

This will create `diagram.png` file with the design diagram.


## Export SVG Command

Export design as an SVG diagram.

Usage:

```sh
poietic export-svg [--design <design>] [--output <output>] [--pictogram-scale <pictogram-scale>] [--pictogram-line-width <pictogram-line-width>] [--zoom <zoom>] [--plane <plane>] [--pictograms <pictograms>]
```

Options:

- `-o, --output <output>`: Output file path (default: diagram.svg).
- `--pictogram-scale <pictogram-scale>`: Scale of pictograms (default: 0.5).
- `--pictogram-line-width <pictogram-line-width>`: Scale of pictograms (default: 1.0).
- `--zoom <zoom>`: Zoom level in % (default: 100.0).
- `--plane <plane>`: Plane name or ID. Default: current plane.
- `--pictograms <pictograms>`: File with pictogram collection.


Pictograms are created by the `pictogram` tool in the [Diagramming](https://github.com/openpoiesis/poietic-diagram))
package.

## Future

The tool is currently using only one domain: PoieticFlows, however it serves two distinct
purposes. One is model editing and the other is simulation or domain-specific
functionality. It should be split into two tools, one part of the PoieticCore
and the other part of PoieticFlows, or in the future, other packages with
simulation capabilities.

The nice to have commands and functionalities:

- `repair` – attempt to repair a broken design or a design of older versions
- `compare` or `diff` – compare two designs
- `merge` merge two or more designs, with rules and conflict resolution
- `edit change-type` – change object type
- `edit unset` - remove an attribute
- more input/output in JSON or CSV format

