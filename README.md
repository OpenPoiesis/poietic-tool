# Poietic Tool

Command-line tool for manipulating and exploring Poietic Models, with support for
Stock and Flow simulation.

[Full documentation](Docs/Tool.md) with all the commands.


## Installation

Available platforms: MacOS 15 (and later), Linux

To install the `poietic` command-line tool, run the following command in the
project's top-level directory:

```bash
./install
```

The tool will be installed in the Swift Package Manager's `~/.swiftpm/bin`
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

## Quick Start

Detailed documentation can be found here: [Command Line Tool documentation](Docs/Tool.md).

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
|`export-svg`| Export design as a SVG diagram |

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

Use `--help` with a desired command to learn more.

### Pseudo-REPL

Think of this tool as [ed](https://en.wikipedia.org/wiki/Ed_(text_editor)) but
for data represented as a graph.

The tool is designed in a way that it is by itself interactive for a single-user. 
For interactivity in a shell, set the `POIETIC_DESIGN` environment variable to
point to a file where the design is stored.

Example session, creates a simple bank account model:

```bash
poietic new
poietic info

poietic edit add Stock name=account formula=100
poietic edit add Auxiliary name=rate formula=0.02
poietic edit add FlowRate name=interest formula="account * rate"
poietic edit connect Flow interest account
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


**Problem Domain**

- Modelling in the [Stock and Flow](https://en.wikipedia.org/wiki/Stock_and_flow) problem domain.
- Computational objects included: Stock, FlowRate, Auxiliary, Graphical function, Delay and Smooth. See [Metamodel](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/metamodel) for details.

**Editing**

- Command-line model editing with undo/redo history
- Export diagrams to SVG or [Graphviz](https://graphviz.org)
- Export results to CSV and [Gnuplot](http://gnuplot.info)


## Examples

See [Examples repository](https://github.com/OpenPoiesis/poietic-examples).

Follow instructions how to run them in the documentation contained within the
repository.

## See Also

- [Formulas](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/formulas)
- [Metamodel](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/metamodel)

Underlying packages:

- Poietic Core: [repository](https://github.com/openpoiesis/poietic-core),
  [documentation](https://openpoiesis.github.io/poietic-core/documentation/poieticcore/)
- Poietic Flows: [repository](https://github.com/openpoiesis/poietic-flows),
  [documentation](https://openpoiesis.github.io/poietic-flows/documentation/poieticflows/)


## Contributing

_All humans are more than welcome to contribute to the project._

Read more in the [Contribution Policy](CONTRIBUTING.md) file.


## Author

[Stefan Urbanek](mailto:stefan.urbanek@gmail.com)
