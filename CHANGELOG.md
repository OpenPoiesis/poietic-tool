
# CHANGELOG

> This is in reverse chronological order – newest at the top.

## Poietic (next)

- **Breaking change:** `set` command has now `set-multiple` usage, and `set-multiple` is removed.
Use: `poietic edit set rabbits formula=100 color=white`
- `metamodel` command prints whether the attribute is optional and prints default value.
- New `ln(x)` built-in function (from PoieticCore)
- Formalised support of CJK characters in variable names (from PoieticCore)
- (FIX) Corrected error reporting on invalid number literals in formulas (from PoieticCore).
- (FIX) `info` command prints absolute design path.
- (FIX) `run` command prints display name only for object variables, not internals.
- (FIX) `write-dot` command redirects to stdout when path is `'-'`.
- (FIX) `auto-parameters` fixed regression where nodes were parameter nodes were deleted instead of edges. (from PoieticFlows)
