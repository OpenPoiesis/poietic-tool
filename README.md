# Poietic Tool

Command-line tool for manipulating and exploring Poietic Models, with support for
Stock and Flow simulation.

See also: [Full documentation](https://github.com/OpenPoiesis/poietic-tool/blob/main/Docs/Tool.md)
with all the commands.


## Installation

Available platforms: MacOS 14 (and later), Linux

To install the `poietic` command-line tool, run the following command in the
project's top-level directory:

```bash
./install
```

The tool will be installed in the Swift Package Manager's' `~/.swiftpm/bin`
directory. Make sure you have the directory in your `PATH`, if you do not, then
add the following to the end of your `~/.zshrc` or `~/.bashrc` file:

```bash
export PATH=~/.swiftpm/bin:$PATH
```

**Recommended** (optional): [Graphviz](https://graphviz.org) for visualising the design graph and [Gnuplot](http://www.gnuplot.info/docs_6.0/loc3434.html) for charts. The tool can generate output for both.

On MacOS with Homebrew:

```bash
brew install graphviz gnuplot
```

## Examples

The examples are located in the [Examples repository](https://github.com/OpenPoiesis/poietic-examples).
Follow instructions how to run them in the documentation contained within the
repository.


## Tool Overview

The Poietic Flows includes a command-line tool to create, edit and run
Stock and Flow models called `poietic`.

See the [Command Line Tool documentation](Docs/Tool.md).

Command summary:

- `new`: Create an empty design.
- `info`: Get information about the design
- `list`: List design content objects.
- `show`: Describe an object.
- `edit`: Edit an object or a selection of objects.
    - `set`: Set an attribute value
    - `undo`: Undo last change
    - `redo`: Redo undone change
    - `add`: Create a new node
    - `connect`: Create a new connection (edge) between two nodes
    - `remove`: Remove an object – a node or a connection
    - `auto-parameters`: Automatically connect parameter nodes: connect required, disconnect unused
    - `layout`: Lay out objects
    - `align`: Align objects on canvas
- `import`: Import a frame into the design.
- `run`: Run the simulation and generate output
- `write-dot`: Write a Graphviz DOT file.
- `metamodel`: Describe the metamodel (supports: text, markdown and HTML output)
- `create-library` Create a library of multiple models.

Use `--help` with a desired command to learn more.

### Pseudo-REPL

Think of this tool as [ed](https://en.wikipedia.org/wiki/Ed_(text_editor)) but
for data represented as a graph. At least for now.

The tool is designed in a way that it is by itself interactive for a single-user. 
For interactivity in a shell, set the `POIETIC_DESIGN` environment variable to
point to a file where the design is stored.

Example session, creates a simple bank account model:

```bash
poietic new
poietic info

poietic edit add Stock name=account formula=100
poietic edit add Auxiliary name=rate formula=0.02
poietic edit add Flow name=interest formula="account*rate"
poietic edit connect Fills interest account
poietic edit connect Parameter rate interest
poietic edit connect Parameter account interest
poietic info

poietic list formulas
```

Run the simulation:

```bash
poietic run
```

Make some mistakes:

```bash
poietic edit add Stock name=unwanted formula=0
poietic list formulas

poietic edit undo

poietic list formulas
```

If you have [Graphviz](https://graphviz.org) installed, then you can run the
following and then open the `diagram.png` image:

```bash
poietic write-dot --output diagram.dot -l name 
dot -Tpng -odiagram.png diagram.dot
```

Discover more design possibilities by exploring the metamodel in a HTML file:

```
poietic metamodel -f html > metamodel.html
```

The above command will create a `metamodel.html` file with full description of
currently available metamodel for the given design.


## Features

- Preserved history – Editing is non-destructive, can be reversed using undo
  and redo commands.
- Exports to different formats:
    - [Graphviz](https://graphviz.org) dot files
    - CSV
    - Charts to [Gnuplot](http://gnuplot.info)
- Stock, Flow, Auxiliary, Graphical function and more kinds of nodes. See
  [Metamodel](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/metamodel).
- Arithmetic expressions with built-in functions. See
  [Formulas](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/formulas).


## See Also

- [Formulas](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/formulas)
- [Metamodel](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/metamodel)

Underlying packages:

- Poietic Core: [repository](https://github.com/openpoiesis/poietic-core),
  [documentation](https://openpoiesis.github.io/poietic-core/documentation/poieticcore/)
- Poietic Flows: [repository](https://github.com/openpoiesis/poietic-flows),
  [documentation](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/)


## Author

[Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
