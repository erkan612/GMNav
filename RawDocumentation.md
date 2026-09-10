# GMNav - Raw Documentation

Complete function reference with parameters, return values, and usage examples.

---

## Layout Functions


### gmnav_layout_create(mode, tile_w, tile_h, neighbours, cost_mode, origin_x, origin_y)

Creates a layout descriptor. This decides where a cell lands on screen and which cells count as its neighbours. The search itself never reads it directly.

**Parameters:**

- `mode` (enum) - `gmnav_layout.ORTHO`, `ISO_DIAMOND`, `ISO_STAGGERED`, `HEX_POINTY`, or `HEX_FLAT`
- `tile_w` (real) - Tile bounding box width. For hex, the corner to corner span
- `tile_h` (real) - Tile bounding box height
- `neighbours` (enum, default: `gmnav_neighbours.EIGHT`) - `FOUR`, `EIGHT`, or `SIX`. Forced to `SIX` on hex layouts
- `cost_mode` (enum, default: `gmnav_costmode.LOGICAL`) - `LOGICAL` or `VISUAL`. Only meaningful on `ORTHO` and `ISO_DIAMOND`
- `origin_x` (real, default: 0) - World x of cell (0,0)
- `origin_y` (real, default: 0) - World y of cell (0,0)

**Returns:** Layout struct

**Example:**

```
layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
```

---

### gmnav_layout_cell_to_world(layout, col, row)

Converts a cell to the world position of its centre.

**Parameters:**

- `layout` (struct) - Layout descriptor
- `col` (int) - Column
- `row` (int) - Row

**Returns:** Array `[x, y]`

**Example:**

```
var _pos = gmnav_layout_cell_to_world(layout, 5, 3);
```

---

### gmnav_layout_world_to_cell(layout, x, y)

Converts a world position to the cell containing it. Uses cube coordinate rounding on hex, and nearest centre refinement on staggered isometric.

**Parameters:**

- `layout` (struct) - Layout descriptor
- `x` (real) - World x
- `y` (real) - World y

**Returns:** Array `[col, row]`

**Example:**

```
var _cell = gmnav_layout_world_to_cell(layout, mouse_x, mouse_y);
```

---

### gmnav_layout_cell_x(layout, col, row)

World x of a cell centre, without allocating an array. Use this in hot loops.

**Parameters:**

- `layout` (struct) - Layout descriptor
- `col` (int) - Column
- `row` (int) - Row

**Returns:** real

**Example:**

```
var _x = gmnav_layout_cell_x(layout, 5, 3);
```

---

### gmnav_layout_cell_y(layout, col, row)

World y of a cell centre, without allocating an array.

**Parameters:**

- `layout` (struct) - Layout descriptor
- `col` (int) - Column
- `row` (int) - Row

**Returns:** real

**Example:**

```
var _y = gmnav_layout_cell_y(layout, 5, 3);
```

---

### gmnav_layout_cell_parity(layout, col, row)

Returns which parity block of the neighbour table a cell uses. 0 for layouts with no parity, otherwise 0 or 1.

**Parameters:**

- `layout` (struct) - Layout descriptor
- `col` (int) - Column
- `row` (int) - Row

**Returns:** int - 0 or 1

**Example:**

```
var _p = gmnav_layout_cell_parity(layout, 5, 3);
```

---

### gmnav_parity(value)

Parity that is safe for negative numbers. GML's `%` returns -1 for `-3 % 2`, which would index a neighbour table out of bounds.

**Parameters:**

- `value` (int) - Any integer

**Returns:** int - 0 or 1

**Example:**

```
var _p = gmnav_parity(-3);   // 1, not -1
```

---

---

## Grid Functions


### gmnav_grid_create(width, height, layout, slots)

Creates a navigation grid. Cells start unblocked with a cost of 1.

**Parameters:**

- `width` (int) - Grid width in cells
- `height` (int) - Grid height in cells
- `layout` (struct) - Layout descriptor from `gmnav_layout_create`
- `slots` (int, default: 4) - Search workspaces the grid will lend out, which caps how many searches can run at once over this grid

**Returns:** Grid struct

**Example:**

```
grid = gmnav_grid_create(60, 40, layout);
```

---

### gmnav_grid_in_bounds(grid, col, row)

Whether a column and row fall inside the grid.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row

**Returns:** Boolean

---

### gmnav_grid_node(grid, col, row)

Converts a column and row to a node id.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row

**Returns:** Node id, or `GMNAV_NO_NODE` if out of bounds

**Example:**

```
var _n = gmnav_grid_node(grid, 12, 8);
```

---

### gmnav_grid_col(grid, node)

The column a node sits in. Resolves overlay nodes as well as base cells.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id, base or overlay

**Returns:** Column, or -1 if the node is invalid

---

### gmnav_grid_row(grid, node)

The row a node sits in. Resolves overlay nodes as well as base cells.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id, base or overlay

**Returns:** Row, or -1 if the node is invalid

---

### gmnav_grid_node_layer(grid, node)

Which layer a node belongs to. Base cells are layer 0.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id

**Returns:** Layer index, 0 for base cells, or -1 if the node is invalid

**Example:**

```
if (gmnav_grid_node_layer(grid, _n) > 0) {
    // standing on something raised
}
```

---

### gmnav_grid_world_to_node(grid, x, y, layer)

Converts a world position to a node on a named layer.

A point over a bridge has more than one answer, so the caller says which surface it meant. Layer 0 is the base grid and always resolves geometrically. A layer above 0 searches the overlay cells drawn at that position, accounting for the layer lift and each cell's own offset.

**Parameters:**

- `grid` (struct) - Grid
- `x` (real) - World x
- `y` (real) - World y
- `layer` (int, default: 0) - Which surface to ask about

**Returns:** Node id, or `GMNAV_NO_NODE` if that layer has no cell at that position

**Example:**

```
var _road = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 0);
var _deck = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 1);
```

---

### gmnav_grid_world_to_node_top(grid, x, y)

The topmost surface at a world position. Walks down from the highest layer and returns the first cell found, falling back to the base grid.

This is what "click on the thing you can see" usually means.

**Parameters:**

- `grid` (struct) - Grid
- `x` (real) - World x
- `y` (real) - World y

**Returns:** Node id, or `GMNAV_NO_NODE`

**Example:**

```
var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);
```

---

### gmnav_grid_node_to_world(grid, node)

The world position a node is drawn at. Applies the layer lift and any per-cell offset, so an overlay cell reports where it actually sits rather than where its column and row would put it.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id, base or overlay

**Returns:** Array `[x, y]`, or `[0, 0]` if the node is invalid

---

### gmnav_grid_is_blocked(grid, node)

Whether a node is impassable. Handles overlay nodes, and returns `true` for anything invalid.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id, base or overlay

**Returns:** Boolean

---

### gmnav_grid_cost(grid, node)

The base cost of entering a node. Overlay cells carry their own cost, independent of the ground beneath them.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Node id, base or overlay

**Returns:** Real, 1 or greater

---

### gmnav_grid_get_cost(grid, node)

The base cost of a base grid cell, without the overlay handling of `gmnav_grid_cost`. Slightly cheaper when you know the node is a base cell.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Base node id

**Returns:** Real

---

### gmnav_grid_has_flag(grid, node, flag)

Whether a base cell carries a flag.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Base node id
- `flag` (int) - Flag constant

**Returns:** Boolean

---

### gmnav_grid_set_blocked(grid, col, row, blocked)

Blocks or unblocks a cell. Bumps the grid version and records the cell as a recent edit, but only if the state actually changed, so a door re-asserting itself every step costs nothing.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row
- `blocked` (bool) - New state

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```
gmnav_grid_set_blocked(grid, 6, 6, true);
```

---

### gmnav_grid_set_cost(grid, col, row, cost)

Sets the terrain cost of a cell. Clamped to a minimum of 1, because a step cheaper than the heuristic assumes would break A\*'s optimality.

Express fast ground by making everything else slower rather than by going below 1.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row
- `cost` (real) - Multiplier for entering this cell, clamped to 1 or more

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```
gmnav_grid_set_cost(grid, 7, 6, 8);   // swamp
```

---

### gmnav_grid_set_flag(grid, col, row, flag, on)

Sets or clears a flag on a cell.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row
- `flag` (int) - Flag constant
- `on` (bool) - Whether to set or clear it

**Returns:** Boolean, `false` if the cell is out of bounds

---

### gmnav_grid_fill_blocked(grid, c1, r1, c2, r2, blocked)

Blocks or unblocks a rectangle. Bumps the version once for the whole rectangle rather than once per cell, and records the rectangle as a single recent edit.

**Parameters:**

- `grid` (struct) - Grid
- `c1`, `r1` (int) - One corner
- `c2`, `r2` (int) - The other corner
- `blocked` (bool) - New state

**Returns:** Boolean, whether anything actually changed

**Example:**

```
gmnav_grid_fill_blocked(grid, 10, 4, 10, 14, true);
```

---

### gmnav_grid_import_tilemap(grid, tilemap, is_blocked)

Reads blocked state from a tilemap layer.

**Parameters:**

- `grid` (struct) - Grid
- `tilemap` (id) - Tilemap element id
- `is_blocked` (function, default: undefined) - Given a tile index, returns whether it blocks. Defaults to treating any non-zero tile as solid

**Example:**

```
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Collision"));
```

---

### gmnav_grid_import_dsgrid(grid, ds_grid, is_blocked)

Reads blocked state from a ds_grid.

**Parameters:**

- `grid` (struct) - Grid
- `ds_grid` (id) - Source grid
- `is_blocked` (function, default: undefined) - Given a value, returns whether it blocks. Defaults to non-zero

---

### gmnav_grid_import_callback(grid, fn)

Fills the grid from a callback, one cell at a time.

Return a boolean for blocked state alone, or a struct with `blocked`, `flags` and `cost` to set all three.

**Parameters:**

- `grid` (struct) - Grid
- `fn` (function) - Called with `(col, row)`

**Example:**

```
gmnav_grid_import_callback(grid, function(_c, _r) {
    return { blocked : place_meeting(_c * 32 + 16, _r * 32 + 16, obj_wall),
             cost    : 1 };
});
```

---

### gmnav_grid_changed_since(grid, version, c1, r1, c2, r2)

Whether any edit since a given version touched a cell rectangle.

The grid keeps a ring of recent edit rectangles, so a caller holding a path can ask whether a change is any of its business rather than repathing on every edit anywhere on the map. If the version predates the oldest rectangle still held, the history needed has been overwritten and this returns `true`, degrading to conservative repathing rather than to silence.

**Parameters:**

- `grid` (struct) - Grid
- `version` (int) - The version the caller last checked at
- `c1`, `r1` (int) - One corner of the rectangle to test
- `c2`, `r2` (int) - The other corner

**Returns:** Boolean

**Example:**

```
if (gmnav_grid_changed_since(grid, my_version, c1, r1, c2, r2)) {
    // something relevant moved
}
```

---

### gmnav_grid_has_heights(grid)

Whether elevation has been set on this grid. The height array is not allocated until the first height is written.

**Parameters:**

- `grid` (struct) - Grid

**Returns:** Boolean

---

### gmnav_grid_height(grid, node)

The elevation of a base cell.

**Parameters:**

- `grid` (struct) - Grid
- `node` (int) - Base node id

**Returns:** Real, 0 if the grid has no heights

---

### gmnav_grid_set_height(grid, col, row, z)

Sets the elevation of a cell, in whatever unit suits you. The value is never converted to pixels and never drawn; it exists so two cells can be compared.

Allocates the height array on first use. Does nothing if the value is unchanged.

**Parameters:**

- `grid` (struct) - Grid
- `col` (int) - Column
- `row` (int) - Row
- `z` (real) - Elevation

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```
gmnav_grid_set_height(grid, 12, 8, 3);
```

---

### gmnav_grid_fill_height(grid, c1, r1, c2, r2, z)

Sets the elevation of a rectangle. Bumps the version once if anything changed.

**Parameters:**

- `grid` (struct) - Grid
- `c1`, `r1` (int) - One corner
- `c2`, `r2` (int) - The other corner
- `z` (real) - Elevation

**Returns:** Boolean, whether anything changed

---

### gmnav_grid_step_blocked(grid, a, b, max_climb, max_drop)

Whether a step between two cells is refused by elevation limits.

Returns `false` when `max_climb` is undefined or the grid has no heights, so a grid carrying elevation behaves exactly as a flat one for any caller that has not opted in.

**Parameters:**

- `grid` (struct) - Grid
- `a` (int) - From node
- `b` (int) - To node
- `max_climb` (real) - Largest rise the unit can take, undefined to ignore heights
- `max_drop` (real) - Largest fall the unit can take

**Returns:** Boolean, `true` if the step is refused

---

### gmnav_grid_set_layer_lift(grid, lift)

How far apart layers are drawn, in pixels. Read by `gmnav_grid_node_to_world` and by every debug view, so an overlay cell reports and draws at the height it occupies.

Purely presentational. The search never reads it.

**Parameters:**

- `grid` (struct) - Grid
- `lift` (real) - Pixels per layer

**Example:**

```
gmnav_grid_set_layer_lift(grid, 24);
```

---

### gmnav_grid_layer_lift(grid)

The current layer lift, or 0 if none was set.

**Parameters:**

- `grid` (struct) - Grid

**Returns:** Real

---

### gmnav_grid_has_overlay(grid)

Whether an overlay has been attached to this grid.

**Parameters:**

- `grid` (struct) - Grid

**Returns:** Boolean

---

### gmnav_grid_scratch_acquire(grid)

Borrows a search workspace from the grid's pool. Workspaces are sized to cover base cells and overlay cells together, and grow if an overlay is attached after the workspace was first allocated.

You rarely call this directly; `gmnav_search_begin` does it for you.

**Parameters:**

- `grid` (struct) - Grid

**Returns:** Workspace struct, or `undefined` if all slots are busy

---

### gmnav_grid_scratch_release(grid, slot)

Returns a workspace to the pool.

**Parameters:**

- `grid` (struct) - Grid
- `slot` (struct) - Workspace to release

---

### gmnav_grid_scratch_flush(grid)

Frees every idle workspace. Busy ones are left alone. Useful on a level change, when the memory matters more than the next search's allocation cost.

**Parameters:**

- `grid` (struct) - Grid

---

---

## Overlay Functions


An overlay is a sparse set of extra walkable cells stacked over a grid, for what one height per cell cannot express: a bridge over a road, a walkway behind a cliff, a tower you can walk around.

Two rules keep an overlay from becoming a second map you maintain by hand.

**A link is only needed where the layer actually changes.** Cells on one layer are neighbours by the ordinary neighbour table, so a six cell walkway needs one link at each end and nothing in between.

**One layer per standable surface, not per unit of height.** A cliff three lifts tall is one layer drawn tall, not three layers stacked, because you cannot stand on the middle of a cliff face.

Overlay nodes are ordinary node ids, numbered past `grid.count`. Anywhere a node is accepted, an overlay node is accepted.

---

### gmnav_overlay_create(grid)

Creates an overlay and attaches it to a grid. A grid holds at most one.

**Parameters:**

- `grid` (struct) - Grid to attach to

**Returns:** Overlay struct

**Example:**

```
var _ov = gmnav_overlay_create(grid);
```

---

### gmnav_overlay_add(ov, col, row, layer)

Adds one walkable cell on a layer above the base grid.

Adding the same column, row and layer twice returns the existing node rather than creating a duplicate.

**Parameters:**

- `ov` (struct) - Overlay
- `col` (int) - Column
- `row` (int) - Row
- `layer` (int) - Layer index, 1 or greater

**Returns:** Node id, or `GMNAV_NO_NODE` if the layer is 0 or below

**Example:**

```
var _deck = gmnav_overlay_add(_ov, 5, 4, 1);
```

---

### gmnav_overlay_link(ov, a, b, type, both)

Authors an edge between two nodes, regardless of whether they are adjacent.

This is how a surface joins another surface. Either end may be a base node or an overlay node. Cost is derived from the world distance between them, so a stair is priced like the walk it represents.

**Parameters:**

- `ov` (struct) - Overlay
- `a` (int) - One node
- `b` (int) - The other node
- `type` (enum, default: `gmnav_link.STAIR`) - Link type, stored on the edge
- `both` (bool, default: `true`) - Whether the link works in both directions

**Example:**

```
gmnav_overlay_link(_ov, gmnav_grid_node(grid, 5, 3), _deck,
                   gmnav_link.STAIR, true);
```

---

### gmnav_overlay_finish(ov)

Bakes the overlay's edges and computes clearance for its cells.

Until this is called the overlay has cells but no connectivity. Call it once when you have finished authoring, and again after any change of shape: adding cells, adding links, or blocking a cell.

Changes of state alone do not require it. See `gmnav_overlay_set_cost`.

**Parameters:**

- `ov` (struct) - Overlay

**Example:**

```
gmnav_overlay_finish(_ov);
```

---

### gmnav_overlay_ramp(ov, nodes)

Spaces the offsets of a run of cells evenly, so the surface climbs in equal fractions of a layer rather than in one step.

Hand it the cells in order from the foot to the top. Steepness is a function of length: more cells give smaller steps. The order is not checked, and a ramp handed its cells backwards descends into the ground and connects to nothing at its far end.

The lowest cell sits one step above the ground it meets, by arithmetic, and that step is one over the number of cells.

**Parameters:**

- `ov` (struct) - Overlay
- `nodes` (array) - Overlay node ids, foot first

**Example:**

```
var _cells = [];
for (var _c = 4; _c <= 9; _c++) {
    array_push(_cells, gmnav_overlay_add(_ov, _c, 10, 1));
}
gmnav_overlay_ramp(_ov, _cells);
```

---

### gmnav_overlay_count(ov)

How many cells the overlay holds.

**Parameters:**

- `ov` (struct) - Overlay

**Returns:** Int

---

### gmnav_overlay_node_at(ov, col, row, layer)

The overlay node at a column, row and layer.

**Parameters:**

- `ov` (struct) - Overlay
- `col` (int) - Column
- `row` (int) - Row
- `layer` (int) - Layer index

**Returns:** Node id, or `GMNAV_NO_NODE`

---

### gmnav_overlay_col(ov, node)

The column of an overlay node.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id

**Returns:** Column, or -1

---

### gmnav_overlay_row(ov, node)

The row of an overlay node.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id

**Returns:** Row, or -1

---

### gmnav_overlay_layer(ov, node)

The layer of an overlay node.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id

**Returns:** Layer index, or -1

---

### gmnav_overlay_offset(ov, node)

How far below its layer a cell sits, as a fraction of one layer.

Zero means the cell is at its layer's nominal height, which is where a flat deck lives. Negative values sit below it, which is what a ramp uses.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id

**Returns:** Real

---

### gmnav_overlay_set_offset(ov, node, offset)

Sets a cell's offset from its layer.

This is drawn height, not navigation. It is read by `gmnav_grid_node_to_world` and by the debug renderer, and it is **not** consulted by `max_climb` or `max_drop`. For a slope only some units can take, use `gmnav_grid_set_height` on the base grid instead.

Bumps the grid version, since world positions and flow field vectors derive from it. Does nothing if the value is unchanged.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id
- `offset` (real) - Fraction of a layer, negative for below

**Returns:** Boolean, `false` if the node is not in this overlay

---

### gmnav_overlay_is_blocked(ov, node)

Whether an overlay cell is impassable. Returns `true` for anything outside the overlay.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id

**Returns:** Boolean

---

### gmnav_overlay_set_blocked(ov, node, on)

Blocks or unblocks an overlay cell, which is how a collapsing span works.

Blocking one span refuses that cell and leaves every other crossing on the map working. Bumps the grid version and records the cell as a recent edit, but only if the state changed.

Call `gmnav_overlay_finish` afterwards to prune the edges. Correctness does not depend on it, since a blocked cell is refused at expansion time either way, but leaving dead edges in place costs a little at every expansion.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id
- `on` (bool) - New state

**Returns:** Boolean, `false` if the node is not in this overlay

**Example:**

```
gmnav_overlay_set_blocked(_ov, _span, true);
gmnav_overlay_finish(_ov);
```

---

### gmnav_overlay_set_cost(ov, node, cost)

Sets the base cost of an overlay cell, independent of the ground beneath it. Clamped to a minimum of 1, as base grid cost is.

A span that is usually passable is better modelled as expensive than as blocked, because an expensive deck can never strand anybody.

**Parameters:**

- `ov` (struct) - Overlay
- `node` (int) - Overlay node id
- `cost` (real) - Multiplier for entering this cell

**Returns:** Boolean, `false` if the node is not in this overlay

---

---

## Clearance Functions


### gmnav_clearance_supported(grid)

Whether this grid's layout supports clearance. `ORTHO` and `ISO_DIAMOND` only.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** bool

**Example:**

```
if (gmnav_clearance_supported(grid)) gmnav_clearance_build(grid);
```

---

### gmnav_clearance_build(grid)

Computes clearance for the whole map with a two pass Chebyshev distance transform.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** bool - False if the layout is unsupported

**Example:**

```
gmnav_clearance_build(grid);
```

---

### gmnav_clearance_is_stale(grid)

Whether the clearance map is missing or out of date against the grid version.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** bool

**Example:**

```
if (gmnav_clearance_is_stale(grid)) { }
```

---

### gmnav_clearance_build_if_stale(grid)

Rebuilds only when needed.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** bool - Success status

**Example:**

```
gmnav_clearance_build_if_stale(grid);
```

---

### gmnav_clearance_at(grid, node)

Clearance value of a node. The largest `r` for which every cell within Chebyshev distance `r - 1` is open. 1 means a single cell fits, 2 means 3x3, 0 means blocked.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** int - 0 if unbuilt or blocked

**Example:**

```
var _room = gmnav_clearance_at(grid, _node);
```

---

### gmnav_clearance_for_radius(grid, radius)

Converts an agent radius in world units into the clearance value it requires. Uses the larger tile dimension, so wide agents on tall thin tiles are never under-served.

**Parameters:**

- `grid` (struct) - Navigation grid
- `radius` (real) - Agent radius in world units

**Returns:** int - At least 1

**Example:**

```
var _need = gmnav_clearance_for_radius(grid, agent.radius);
```

---

### gmnav_clearance_nearest(grid, node, need, max_rings)

Nearest node with sufficient clearance, searched outward in rings. Use when a goal is too tight for an agent, rather than failing the request.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Starting node id
- `need` (int) - Required clearance
- `max_rings` (int, default: 8) - How far to search

**Returns:** int - Node id, or `GMNAV_NO_NODE`

**Example:**

```
var _to = gmnav_clearance_nearest(grid, _wanted, _need);
```

---

---

## Search Functions


### gmnav_search_create(grid, heuristic)

Creates a reusable search object. A search borrows a workspace from the grid when it begins and returns it when it finishes, so creating one is cheap and holding one costs nothing while idle.

**Parameters:**

- `grid` (struct) - Grid to search over
- `heuristic` (enum, default: `gmnav_heuristic.AUTO`) - `AUTO` picks from the layout. `ZERO` turns the search into Dijkstra, which is useful for checking that a suspicious path really is optimal

**Returns:** Search struct

**Example:**

```
search = gmnav_search_create(grid);
```

---

### gmnav_search_begin(search, start_node, goal_node, corner_cut, profile, need_clear, max_climb, max_drop)

Sets a search up. Does not do any work; call `gmnav_search_step` to advance it.

Fails immediately if either end is out of bounds or blocked, or if no workspace is available.

**Parameters:**

- `search` (struct) - Search
- `start_node` (int) - Starting node, base or overlay
- `goal_node` (int) - Target node, base or overlay
- `corner_cut` (bool, default: `false`) - Whether a diagonal may pass between two wall corners. Leaving this off keeps paths walkable
- `profile` (struct, default: undefined) - Cost profile. Without one, base terrain cost is used
- `need_clear` (int, default: 0) - Clearance the unit needs, in cells. Values above 1 build clearance if it is missing or out of date
- `max_climb` (real, default: undefined) - Largest rise the unit can take. Undefined ignores elevation entirely
- `max_drop` (real, default: undefined) - Largest fall the unit can take

**Returns:** Boolean, whether the search started

**Example:**

```
if (gmnav_search_begin(search, _from, _to, false, profile, 2, 1, 3)) {
    // stepping from here
}
```

---

### gmnav_search_step(search, budget)

Advances a search by a limited amount of work and returns what happened.

The budget is counted in node expansions. Pass a small one and the search does a little and stops, keeping its frontier, costs and parent links alive in its workspace so the next call carries on from exactly where it left off.

**Parameters:**

- `search` (struct) - Search
- `budget` (int, default: the configured default) - Node expansions allowed this call

**Returns:** `gmnav_state.WORKING`, `FOUND` or `FAILED`

**Example:**

```
var _state = gmnav_search_step(search, 200);

if (_state == gmnav_state.FOUND) {
    var _path = gmnav_search_get_path(search);
}
```

---

### gmnav_search_get_path(search)

The path a finished search produced, from start to goal.

**Parameters:**

- `search` (struct) - Search

**Returns:** Array of node ids, empty if the search did not succeed

---

### gmnav_search_is_stale(search)

Whether the grid changed since this search began.

Stale means the result may no longer reflect the world. For a search that **completed** before the change, the path was correct when produced and nothing is corrupted. For one that was **suspended** mid-flight, settled cells are never revisited, so a wall landing on ground the search already crossed off goes unnoticed.

The contract is termination plus this flag, not path validity.

**Parameters:**

- `search` (struct) - Search

**Returns:** Boolean

---

### gmnav_search_release(search)

Returns the workspace and clears the result. Call this when you are done with a finished search and want the slot back for someone else.

**Parameters:**

- `search` (struct) - Search

---

### gmnav_search_abort(search)

Stops a search in progress and returns its workspace. Safe on a search that is idle or already finished.

**Parameters:**

- `search` (struct) - Search

---

---

## Scheduler Functions


The scheduler owns one budget shared across every search in flight, so frame cost is fixed regardless of how many agents are asking. What agent count changes is how long the queue takes to drain, not what a frame costs.

It dispatches on domain, so the same scheduler API drives a grid or a platformer graph.

---

### gmnav_scheduler_create(target, budget, concurrent)

Creates a scheduler over a grid or a platformer graph.

**Parameters:**

- `target` (struct) - A grid or a platformer graph. The domain is read from it
- `budget` (int, default: the configured default) - Node expansions per frame, across all searches combined
- `concurrent` (int, default: 4) - How many searches may be in flight at once, capped by how many workspaces the target can supply

**Returns:** Scheduler struct

**Example:**

```
sched = gmnav_scheduler_create(grid, 2000, 4);
```

---

### gmnav_scheduler_request(sched, start_node, goal_node, priority, corner_cut, profile, need_clear, max_climb, max_drop)

Queues a path request and returns a ticket immediately, before any work has happened.

A ticket is a receipt, not a path. Check it later.

`gmnav_priority.IMMEDIATE` bypasses the budget and runs to completion inside this call, but it does **not** bypass the workspace pool. If every workspace is busy there is nowhere to run, and the request quietly falls back into the queue to resolve later like any other. Check the ticket state rather than assuming a path arrived.

**Parameters:**

- `sched` (struct) - Scheduler
- `start_node` (int) - Starting node
- `goal_node` (int) - Target node
- `priority` (enum, default: `gmnav_priority.NORMAL`) - `LOW`, `NORMAL`, `HIGH` or `IMMEDIATE`
- `corner_cut` (bool, default: `false`) - Whether diagonals may squeeze between wall corners
- `profile` (struct, default: undefined) - Cost profile
- `need_clear` (int, default: 0) - Clearance the unit needs, in cells
- `max_climb` (real, default: undefined) - Largest rise the unit can take
- `max_drop` (real, default: undefined) - Largest fall the unit can take

**Returns:** Ticket struct

**Example:**

```
ticket = gmnav_scheduler_request(sched, _from, _to,
                                 gmnav_priority.NORMAL, false,
                                 profile, _need, 1, 3);
```

---

### gmnav_scheduler_update(sched)

Advances every search in flight, spending the budget across them. Unused budget from a search that finishes early cascades to the next one in the same frame, so the whole allowance keeps working.

Call once per frame, before your agents update.

**Parameters:**

- `sched` (struct) - Scheduler

---

### gmnav_scheduler_is_ready(ticket)

Whether a ticket has a path waiting.

This is `true` only for `FOUND`. A failed request is finished but not ready, so check `ticket.state` if you need to tell the difference.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** Boolean

---

### gmnav_scheduler_get_path(ticket)

The path a resolved ticket produced.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** Array of node ids, empty if the request did not succeed

---

### gmnav_scheduler_get_links(ticket)

How each node on a platformer path is reached. `links[i]` is the link type used to arrive at `path[i]`.

Empty on the grid domain.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** Array of `gmnav_link` values

**Example:**

```
var _path  = gmnav_scheduler_get_path(ticket);
var _links = gmnav_scheduler_get_links(ticket);
```

---

### gmnav_scheduler_cancel(sched, ticket)

Abandons a request. Safe at any point, whether the ticket is queued, running or already finished.

A running search frees its workspace on the next update, letting a waiting request take it. In a game where targets move often, cancelling stale requests is a real performance win rather than tidiness.

**Parameters:**

- `sched` (struct) - Scheduler
- `ticket` (struct) - Ticket to cancel

---

### gmnav_scheduler_pending(sched)

How many requests are waiting for a workspace.

This is the number to watch. A brief spike is a crowd asking at once and the queue doing its job. Pending that stays high frame after frame means requests are arriving faster than they are served, and on a map with frequent edits that is more often unnecessary repathing than an undersized budget.

**Parameters:**

- `sched` (struct) - Scheduler

**Returns:** Int

---

---

## Path Functions


A path object converts node ids into world waypoints and holds the result. Every waypoint sits at the centre of its cell, at the height that cell is drawn at, so an overlay cell reports where it actually sits.

---

### gmnav_path_create(grid, nodes)

Builds a path object from a list of nodes.

**Parameters:**

- `grid` (struct) - Grid the nodes belong to
- `nodes` (array) - Node ids, in order

**Returns:** Path struct

**Example:**

```
path = gmnav_path_create(grid, gmnav_search_get_path(search));
```

---

### gmnav_path_get_count(path)

How many waypoints the path holds.

**Parameters:**

- `path` (struct) - Path

**Returns:** Int

---

### gmnav_path_get_x(path, i)

The world x of a waypoint.

**Parameters:**

- `path` (struct) - Path
- `i` (int) - Waypoint index

**Returns:** Real

---

### gmnav_path_get_y(path, i)

The world y of a waypoint.

**Parameters:**

- `path` (struct) - Path
- `i` (int) - Waypoint index

**Returns:** Real

---

### gmnav_path_get_length(path)

Total world length of the path, in pixels.

**Parameters:**

- `path` (struct) - Path

**Returns:** Real

---

### gmnav_path_sample(path, dist)

The position a given distance along the path.

**Parameters:**

- `path` (struct) - Path
- `dist` (real) - Distance from the start, in pixels

**Returns:** Array `[x, y]`

---

### gmnav_path_anchor_start(path, x, y)

Replaces the first waypoint with a real position and recomputes the length.

A character is almost never standing exactly on a cell centre, so without this the opening move is a visible step backwards.

**Parameters:**

- `path` (struct) - Path
- `x` (real) - Where the character really is
- `y` (real) - Where the character really is

---

### gmnav_path_anchor_end(path, x, y)

Replaces the last waypoint with a real position and recomputes the length.

**Parameters:**

- `path` (struct) - Path
- `x` (real) - Where the target really is
- `y` (real) - Where the target really is

---

### gmnav_path_smooth(path, max_climb, max_drop, radius, headings, profile)

String pulling. Replaces runs of waypoints with straight lines wherever the line is walkable, which removes the staircase shape a grid search produces.

Refused on `ISO_STAGGERED`, `HEX_POINTY` and `HEX_FLAT`. On those layouts a straight line in cell coordinates says nothing reliable about whether a character could walk it, so the function returns without doing anything rather than returning a confidently wrong answer. `gmnav_path_simplify` works everywhere.

The line of sight test underneath visits every cell a line touches, and requires both flanking cells to be open at an exact corner crossing. A test that commits to one cell per step slips through the gap between two diagonal walls and reports clear, which produces smoothed paths that clip geometry.

Each optional argument closes a way the shortcut could be wrong:

**Parameters:**

- `path` (struct) - Path, modified in place
- `max_climb` (real, default: undefined) - Elevation limits. Without these a shortcut will cut straight up a cliff the search walked around, because a cliff is not blocked
- `max_drop` (real, default: undefined) - As above
- `radius` (real, default: 0) - Agent body radius. Without it, a line that fits the centre may not fit the shoulders
- `headings` (int, default: 0) - How many headings the result may use. 0 is unconstrained, 4 is cardinals, 8 adds diagonals. Constrains the shaping only, so the layout's neighbour set has to agree
- `profile` (struct, default: undefined) - Cost profile. Without it a shortcut will walk back through expensive ground the search deliberately avoided

**Example:**

```
gmnav_path_smooth(path, agent.max_climb, agent.max_drop,
                  agent.radius, agent.headings, agent.profile);
```

**Note on headings:** with a constraint set, this also rewrites a staircase into the fewest legal straight legs, proposing a corner the search never visited and checking each leg the same way a single leg is checked. Both corner orders are tried, and the staircase stands if neither passes. A single straight leg is always preferred over a pair.

---

### gmnav_path_simplify(path, tolerance, max_climb, max_drop)

Removes waypoints that lie on a straight line between their neighbours. Changes the path's shape not at all, so it is safe on every layout including the ones smoothing refuses.

Keeps any waypoint where the layer changes, because a lifted stair is nearly collinear on screen and a purely geometric test would delete it, losing the climb.

After simplifying, waypoints no longer correspond one to one with cells, so `path.nodes` is cleared. Run `gmnav_path_smooth` first if you want both.

**Parameters:**

- `path` (struct) - Path, modified in place
- `tolerance` (real, default: 0.01) - How close to collinear counts as collinear
- `max_climb` (real, default: undefined) - Elevation limits, for the same reason smoothing needs them
- `max_drop` (real, default: undefined) - As above

**Example:**

```
gmnav_path_simplify(path, 0.01, agent.max_climb, agent.max_drop);
```

---

### gmnav_path_curve(path, mode, radius, samples, body, min_turn)

Rounds the corners of a path, for anything with momentum that cannot turn instantly.

Every generated segment is validated against the same geometry the search used, body radius included. A corner whose arc would clip keeps its sharp corner, and under `SPLINE` a segment that would clip reverts to the straight line. In tight terrain a curved path is therefore only partly curved, which is the check working rather than the mode failing.

Refused on the same layouts as `gmnav_path_smooth`.

Unlike `simplify`, this leaves `path.nodes` intact, so scoped repathing still has a cell route to test against.

**Parameters:**

- `path` (struct) - Path, modified in place
- `mode` (enum, default: `gmnav_curve.NONE`) - `NONE` leaves the path alone. `CORNER` rounds each turn and leaves straight legs untouched. `SPLINE` runs a curve through every waypoint
- `radius` (real, default: 16) - How far back from each corner the rounding begins. Clamped to half of each adjacent leg, so two corners never consume the same segment
- `samples` (int, default: 4) - Points per arc. Four or five is plenty for movement
- `body` (real, default: 0) - Agent body radius
- `min_turn` (real, default: 5) - Angle in degrees below which a joint is left alone

**Example:**

```
gmnav_path_curve(path, gmnav_curve.CORNER, 40, 5, agent.radius);
```

**Note:** a spline passes through its waypoints but is not bounded by them, so it overshoots at the ends. `CORNER` is the safer default. Do not curve a path whose headings you constrained, since a curve contains every heading.

---

---

## Cost Field Functions


A layer holds one number per cell and knows nothing about who reads it. A profile blends several layers with weights and flattens the result into a single array, so the search does one lookup per neighbour regardless of how many layers went into it.

Weights belong to the profile rather than the layer, which is what lets three unit types share one danger map and disagree completely about how much they care.

---

### gmnav_costlayer_create(grid, name)

Creates an empty cost layer over a grid. Every cell starts at 0. The array covers overlay cells as well as base cells.

**Parameters:**

- `grid` (struct) - Grid
- `name` (string, default: "") - For your own bookkeeping

**Returns:** Layer struct

**Example:**

```
danger = gmnav_costlayer_create(grid, "turret");
```

---

### gmnav_costlayer_set(layer, col, row, value)

Sets the value of one base cell.

**Parameters:**

- `layer` (struct) - Layer
- `col` (int) - Column
- `row` (int) - Row
- `value` (real) - New value

**Returns:** Boolean, `false` if the cell is out of bounds

---

### gmnav_costlayer_get(layer, col, row)

The value of one base cell.

**Parameters:**

- `layer` (struct) - Layer
- `col` (int) - Column
- `row` (int) - Row

**Returns:** Real, 0 if out of bounds

---

### gmnav_costlayer_set_node(layer, node, value)

Sets the value of any node, base or overlay.

An overlay cell has no unique column and row, since it shares them with the ground beneath it, so this is how you price a deck.

**Parameters:**

- `layer` (struct) - Layer
- `node` (int) - Node id, base or overlay
- `value` (real) - New value

**Returns:** Boolean, `false` if the node is out of range

**Example:**

```
gmnav_costlayer_set_node(toll, _deck_node, 8);
```

---

### gmnav_costlayer_get_node(layer, node)

The value of any node, base or overlay.

**Parameters:**

- `layer` (struct) - Layer
- `node` (int) - Node id

**Returns:** Real, 0 if out of range

---

### gmnav_costlayer_clear(layer)

Resets every cell to 0.

**Parameters:**

- `layer` (struct) - Layer

---

### gmnav_costlayer_clear_region(layer, c1, r1, c2, r2)

Resets a rectangle to 0. Used with `gmnav_costprofile_bake_region` to move a threat without touching the rest of the map.

**Parameters:**

- `layer` (struct) - Layer
- `c1`, `r1` (int) - One corner
- `c2`, `r2` (int) - The other corner

---

### gmnav_costlayer_stamp_radial(layer, wx, wy, radius, peak, falloff)

Paints a circular blob of cost, with the peak at the centre falling off outward.

Stamps combine with **max** rather than adding, so two turrets covering the same cell make it dangerous rather than twice as dangerous, and restamping the same source at the same place changes nothing.

**Parameters:**

- `layer` (struct) - Layer
- `wx` (real) - World x of the centre
- `wy` (real) - World y of the centre
- `radius` (real) - Reach in pixels
- `peak` (real) - Value at the centre
- `falloff` (real, default: 1) - Exponent. 1 is linear, 2 falls off faster near the edge

**Returns:** Array `[c1, r1, c2, r2]`, the cells actually written

**Example:**

```
var _rect = gmnav_costlayer_stamp_radial(danger, px, py, 200, 20, 2);
```

**Note:** keep peaks within about an order of magnitude of the base cost of 1. A peak of 40 puts every reasonable profile weight far past the point where a unit's decision flips, so turning the weight up and down appears to do nothing.

---

### gmnav_costlayer_stamp_path(layer, points, width, peak, falloff)

Paints a band of cost along a polyline, with the peak on the centreline falling off to either side.

For anything linear: a road, a patrol route, a spreading fire, a player's recent trail. Approximating this with a chain of radial stamps produces a lumpy field and a bounding rectangle far larger than the band, which makes region rebaking far more expensive than it needs to be.

Work follows the route rather than the bounding box of the whole thing, so a long path across a map costs what its own length costs.

Combines with max, exactly as `stamp_radial` does.

**Parameters:**

- `layer` (struct) - Layer
- `points` (array) - World space `[x, y]` pairs, in order
- `width` (real) - Half width of the band, in pixels
- `peak` (real) - Value on the centreline
- `falloff` (real, default: 1) - Exponent

**Returns:** Array `[c1, r1, c2, r2]`, the cells actually written rather than the area scanned

**Example:**

```
var _rect = gmnav_costlayer_stamp_path(danger,
                [[x1, y1], [x2, y2], [x3, y3]], 56, 8, 1);
```

---

### gmnav_costprofile_create(grid, name)

Creates an empty cost profile. Its resolved array covers overlay cells as well as base cells.

**Parameters:**

- `grid` (struct) - Grid
- `name` (string, default: "") - For your own bookkeeping

**Returns:** Profile struct

**Example:**

```
soldier = gmnav_costprofile_create(grid, "soldier");
```

---

### gmnav_costprofile_add(profile, layer, weight)

Adds a layer to a profile with a weight.

A negative weight is legal, and resolved cost still clamps at 1, so it makes dangerous ground ordinary rather than attractive. Cost fields push; to pull a unit toward something, seed it as a goal in a flow field.

**Parameters:**

- `profile` (struct) - Profile
- `layer` (struct) - Layer to add
- `weight` (real, default: 1) - How much this profile cares

**Example:**

```
gmnav_costprofile_add(scout, danger, 4);
```

**Note:** this appends rather than replacing, so calling it twice with the same layer counts that layer twice. Use `gmnav_costprofile_set_weight` to change an existing weight.

---

### gmnav_costprofile_set_weight(profile, layer, weight)

Changes the weight of a layer already in the profile. Marks the profile dirty.

**Parameters:**

- `profile` (struct) - Profile
- `layer` (struct) - Layer already added
- `weight` (real) - New weight

**Returns:** Boolean, `false` if the layer is not in this profile

---

### gmnav_costprofile_remove(profile, layer)

Removes a layer from a profile.

**Parameters:**

- `profile` (struct) - Profile
- `layer` (struct) - Layer to remove

**Returns:** Boolean, `false` if the layer is not in this profile

---

### gmnav_costprofile_bake(profile)

Flattens every layer and weight into one array, so the search does a single lookup per neighbour.

Overlay cells are seeded from their own base cost, then weighted layers are applied, so a deck is priced independently of the ground beneath it. Resolved cost clamps at 1.

A twelve layer profile costs the search precisely what no profile costs. The work moved here, where you control when it happens.

**Parameters:**

- `profile` (struct) - Profile

**Example:**

```
gmnav_costprofile_bake(soldier);
```

---

### gmnav_costprofile_is_dirty(profile)

Whether the profile is out of date.

A profile goes dirty when any of its layers changes, when a weight changes, or when the grid's terrain changes. That last one catches a case people miss: block a wall or change a terrain cost, and every profile over that grid needs rebaking too.

**Parameters:**

- `profile` (struct) - Profile

**Returns:** Boolean

---

### gmnav_costprofile_bake_if_dirty(profile)

Bakes only if something changed. Safe to call every frame.

**Parameters:**

- `profile` (struct) - Profile

**Returns:** Boolean, whether a bake happened

---

### gmnav_costprofile_bake_region(profile, c1, r1, c2, r2)

Rebakes one rectangle, which is what makes a moving threat affordable. A full bake walks every cell; this walks the cells you name.

Does **not** clear the dirty flag, deliberately, because it only guarantees the rectangle you named. The rest of the map may still be out of date and pretending otherwise would hide bugs.

**Parameters:**

- `profile` (struct) - Profile
- `c1`, `r1` (int) - One corner
- `c2`, `r2` (int) - The other corner

**Example:**

```
gmnav_costlayer_clear_region(danger, _old[0], _old[1], _old[2], _old[3]);
var _new = gmnav_costlayer_stamp_path(danger, _route, 56, 8, 1);

gmnav_costprofile_bake_region(soldier, _old[0], _old[1], _old[2], _old[3]);
gmnav_costprofile_bake_region(soldier, _new[0], _new[1], _new[2], _new[3]);
```

**Note:** rebake **both** rectangles, the area vacated and the area newly covered. Skip the old one and the threat stays burned into the resolved array permanently. And do it once per profile that reads the layer; a profile that misses the update simply holds an older world.

---

---

## Flow Field Functions


A flow field inverts the problem. Instead of searching from each agent toward the goal, it spreads outward from the goal once and records how far every cell is from it, so an agent reads a direction instead of running a search.

Many agents, few destinations, stable goals is where a field belongs. Below roughly thirty agents, individual searches are cheaper.

---

### gmnav_flowfield_create(grid, profile, max_climb, max_drop)

Creates a flow field over a grid. Its arrays cover overlay cells as well as base cells, and grow if an overlay is attached later.

Elevation limits are applied in reverse while building, because a field is built outward from the goal but walked inward toward it. A field built to a goal on top of a cliff is not the same field as one built to a goal at its foot.

**Parameters:**

- `grid` (struct) - Grid
- `profile` (struct, default: undefined) - Cost profile the field is built under
- `max_climb` (real, default: undefined) - Largest rise a unit reading this field can take
- `max_drop` (real, default: undefined) - Largest fall

**Returns:** Field struct

**Example:**

```
field = gmnav_flowfield_create(grid, soldier);
```

---

### gmnav_flowfield_build(field, goal_nodes, max_dist)

Builds the whole field at once, both passes. The right choice at level load and the wrong one mid-combat.

Seed several goals and each cell records the distance to the nearest one, so every agent flows to whichever is cheapest for it and the map partitions itself along the natural watersheds. Several goals cost very little over one.

**Parameters:**

- `field` (struct) - Field
- `goal_nodes` (int or array) - One node id, or an array of them
- `max_dist` (real, default: infinity) - Stop expanding past this distance. Cells beyond it report unreachable

**Returns:** Boolean, whether any goal was usable

**Example:**

```
gmnav_flowfield_build(field, [exit_a, exit_b, exit_c]);
```

---

### gmnav_flowfield_begin(field, goal_nodes, max_dist)

Starts a sliced build. Follow with `gmnav_flowfield_step` once per frame.

**Parameters:**

- `field` (struct) - Field
- `goal_nodes` (int or array) - One node id, or an array of them
- `max_dist` (real, default: infinity) - Distance cap

**Returns:** Boolean, whether any goal was usable

---

### gmnav_flowfield_step(field, budget)

Advances a sliced build. Both passes slice: the distance sweep over reachable cells, and the direction pass over every cell.

The second pass is the expensive half, because it touches every cell in the grid rather than only the reachable ones.

**Parameters:**

- `field` (struct) - Field
- `budget` (int, default: the configured default) - Work allowed this call

**Returns:** `gmnav_state.WORKING`, `FOUND` or `FAILED`

**Example:**

```
if (gmnav_flowfield_step(field, 2000) == gmnav_state.FOUND) {
    // ready to sample
}
```

---

### gmnav_flowfield_is_ready(field)

Whether the field has finished building.

**Parameters:**

- `field` (struct) - Field

**Returns:** Boolean

---

### gmnav_flowfield_is_stale(field)

Whether the grid changed since the field was built.

Flow fields do not repair themselves. A field built before an edit still describes the old world, arrows and all, and rebuilding one is far more expensive than repathing a single agent.

**Parameters:**

- `field` (struct) - Field

**Returns:** Boolean

---

### gmnav_flowfield_sample(field, x, y, layer)

The direction to travel from a world position, as a normalised vector.

Directions are computed in world space rather than from raw cell offsets. On a square grid those agree; on isometric or hex they do not, and deriving the vector from the offset would send every agent in the wrong direction while the debug overlay looked entirely correct.

**Parameters:**

- `field` (struct) - Field
- `x` (real) - World x
- `y` (real) - World y
- `layer` (int, default: 0) - Which surface to ask about

**Returns:** Array `[dx, dy]`, or `[0, 0]` if the cell is unreachable or has no direction

**Example:**

```
var _d = gmnav_flowfield_sample(field, x, y, agent_layer);

x += _d[0] * spd;
y += _d[1] * spd;
```

---

### gmnav_flowfield_next(field, node)

The node a cell steps to, rather than the direction it points.

A direction vector cannot express a change of surface. Where a step crosses from one layer to another, this is what tells you so, and it is what a caller should read when a route may involve stairs or a bridge.

**Parameters:**

- `field` (struct) - Field
- `node` (int) - Node id, base or overlay

**Returns:** Node id, or `GMNAV_NO_NODE` at a goal or an unreached cell

**Example:**

```
var _nx = gmnav_flowfield_next(field, _here);

if (_nx != GMNAV_NO_NODE
&&  gmnav_grid_node_layer(grid, _nx) != my_layer) {
    // this step changes surface
}
```

---

### gmnav_flowfield_cost_at(field, x, y, layer)

The distance from a world position to the nearest seeded goal, in path cost.

More useful than it looks. This is a true travel cost with walls, terrain and danger all accounted for, which makes it a far better input to a decision than straight line distance, at one array lookup for every unit on the map.

**Parameters:**

- `field` (struct) - Field
- `x` (real) - World x
- `y` (real) - World y
- `layer` (int, default: 0) - Which surface to ask about

**Returns:** Real, or infinity if unreachable

---

### gmnav_flowfield_is_reachable(field, x, y, layer)

Whether a world position can reach any seeded goal.

Cells beyond a distance cap report `false`, the same as genuinely unreachable ones, so your code needs no special case.

**Parameters:**

- `field` (struct) - Field
- `x` (real) - World x
- `y` (real) - World y
- `layer` (int, default: 0) - Which surface to ask about

**Returns:** Boolean

---

---

## Agent Functions


An agent wraps a path with steering, arrival and optional local avoidance.

It writes a desired velocity and does not move your instances. Your game already has movement and collision, and a navigation library that moved things directly would be a second movement system racing the first.

Everything an agent does is available to a project using its own agent class. It stores preferences and forwards them to the framework calls that do the work; it invents nothing.

---

### gmnav_agent_create(sched, x, y, radius, speed)

Creates an agent.

**Parameters:**

- `sched` (struct) - Scheduler it requests paths from
- `x` (real) - Starting world x
- `y` (real) - Starting world y
- `radius` (real, default: 8) - Body radius, used for avoidance and passed to smoothing
- `speed` (real, default: 2) - Units per frame

**Returns:** Agent struct

**Example:**

```
agent = gmnav_agent_create(sched, x, y, 8, 2.5);
```

---

### gmnav_agent_goto(agent, gx, gy, priority, goal_layer)

Requests a path to a world position. When it arrives the agent smooths it, anchors both ends, curves it if asked, and starts steering.

The goal layer is remembered, so a repath asks for the same surface rather than whatever is at ground level.

Clears the arrived and failed latches.

**Parameters:**

- `agent` (struct) - Agent
- `gx` (real) - World x of the goal
- `gy` (real) - World y of the goal
- `priority` (enum, default: `gmnav_priority.NORMAL`) - Request priority
- `goal_layer` (int, default: 0) - Which surface the goal is on

**Returns:** Boolean, `false` if either end could not be resolved to a node

**Example:**

```
gmnav_agent_goto(agent, mouse_x, mouse_y, gmnav_priority.NORMAL, 1);
```

---

### gmnav_agent_update(agent, neighbours)

Advances the agent by one frame. Collects a resolved ticket, repaths if a change landed on the route still to walk, advances waypoints, and writes `vx` and `vy`.

Does not write `x` or `y`. Ever.

Local avoidance needs a neighbour list, which you supply, because your game almost certainly already has a spatial index and GMNav does not keep one. A neighbour needs only `x`, `y` and `radius`.

**Parameters:**

- `agent` (struct) - Agent
- `neighbours` (array, default: undefined) - Nearby agents to push away from

**Example:**

```
gmnav_scheduler_update(sched);
gmnav_agent_update(agent, _near);

x += agent.vx;
y += agent.vy;
agent.x = x;
agent.y = y;
```

---

### gmnav_agent_stop(agent)

Drops the goal, cancels any request in flight, and clears the path. Velocity decays rather than cutting to zero.

**Parameters:**

- `agent` (struct) - Agent

---

### gmnav_agent_has_path(agent)

Whether the agent currently holds a path.

Not a substitute for `gmnav_agent_arrived`. The path is cleared on the same frame a journey completes, so anything reading this would miss the moment entirely.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** Boolean

---

### gmnav_agent_arrived(agent)

Whether the agent finished its last journey.

Latched, so you can ask whenever suits you. Stays true until the next `goto` or `stop`, which is what makes patrol routes a single `if`.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** Boolean

**Example:**

```
if (gmnav_agent_arrived(agent)) {
    gmnav_agent_goto(agent, next_x, next_y);
}
```

---

### gmnav_agent_failed(agent)

Whether the last goal could not be routed to.

Latched like `arrived`, and cleared by the next `goto` or `stop`. Without it, a failed request and a completed journey both end with no goal and no ticket, and a caller cannot tell them apart.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** Boolean

**Example:**

```
if (gmnav_agent_failed(agent)) {
    // no route. Wait, attack the obstacle, or pick another objective
}
```

---

### gmnav_agent_layer(agent)

Which surface the agent is currently standing on.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** Layer index, 0 for the base grid

---

---

## Platformer Functions


Side view connectivity is not grid adjacency. Two ledges can touch on screen and be unreachable from each other, and two ledges far apart can be connected perfectly well. Connectivity is a property of how your character moves, so the graph is established by simulating your character's actual jump arcs against your actual collision data.

Platformer graphs require an `ORTHO` layout.

---

### gmnav_movement_create(gravity, jump_vel, run_speed, max_fall, width, height, air_speed, jump_levels, jump_bias)

Describes how your character moves. Everything the bake produces depends on this.

These must be your player controller's real numbers. If `jump_vel` is even slightly generous the graph contains links your character physically cannot traverse, and an agent will walk to a ledge, jump, miss, land, walk back, and try again forever.

**Parameters:**

- `gravity` (real) - Added to vertical velocity each frame
- `jump_vel` (real) - Jump velocity at full strength, positive
- `run_speed` (real) - Horizontal speed on the ground
- `max_fall` (real) - Terminal fall speed
- `width` (real) - Character width
- `height` (real) - Character height
- `air_speed` (real, default: `run_speed`) - Horizontal speed in the air. At the default the character has no air momentum, which makes long diagonal jumps impossible and can quietly turn a platform into a one way trap. Most platformers want this at or above `run_speed`
- `jump_levels` (int, default: 3) - How many jump strengths are sampled between half power and full. Controls arc quality, not just how many jumps are tried. Set to 1 for a fixed jump character and cut the bake cost by two thirds
- `jump_bias` (real, default: 1.15) - Multiplier on jump link costs. On level ground, hopping costs exactly what walking costs, so without a bias the search chooses arbitrarily between them and you get an AI that bunny hops everywhere

**Returns:** Movement struct

**Example:**

```
move = gmnav_movement_create(0.5, 8, 3, 9, 12, 24, undefined, 3);
```

---

### gmnav_platgraph_create(grid, movement)

Creates an empty platformer graph. Nothing is computed until you bake.

**Parameters:**

- `grid` (struct) - Grid holding the level's collision, `ORTHO` only
- `movement` (struct) - Movement model

**Returns:** Platformer graph struct

---

### gmnav_platgraph_bake(pg)

Finds every standing position and generates every link, to completion. A level load operation.

A cell is a standing position when it is open, the cell below it is solid or one way, and the character's whole box fits there without clipping. That last condition makes headroom a level design question: a platform needs enough room beneath it for anything that walks under it.

**Parameters:**

- `pg` (struct) - Platformer graph

**Returns:** Boolean, whether the bake completed

**Example:**

```
gmnav_platgraph_bake(pgraph);
```

---

### gmnav_platgraph_bake_begin(pg)

Starts a sliced bake. Follow with `gmnav_platgraph_bake_step` once per frame, during a loading screen.

**Parameters:**

- `pg` (struct) - Platformer graph

---

### gmnav_platgraph_bake_step(pg, budget)

Advances a sliced bake.

**Parameters:**

- `pg` (struct) - Platformer graph
- `budget` (int, default: 256) - Work allowed this call

**Returns:** `gmnav_bake.SURFACES`, `LINKS` or `DONE`

**Example:**

```
if (gmnav_platgraph_bake_step(pgraph, 256) == gmnav_bake.DONE) {
    // ready
}
```

---

### gmnav_platgraph_is_ready(pg)

Whether the graph has finished baking.

**Parameters:**

- `pg` (struct) - Platformer graph

**Returns:** Boolean

---

### gmnav_platgraph_is_stale(pg)

Whether the grid changed since the bake. A graph describes the level as it was baked; break a platform and the arcs that used it describe something that no longer exists.

**Parameters:**

- `pg` (struct) - Platformer graph

**Returns:** Boolean

---

### gmnav_platgraph_node_at(pg, x, y, max_drop_cells)

The platform node at or below a world position.

Searches downward, so it works while the character is airborne, finding the ledge beneath it.

**Parameters:**

- `pg` (struct) - Platformer graph
- `x` (real) - World x
- `y` (real) - World y of the feet
- `max_drop_cells` (int, default: 4) - How far down to look

**Returns:** Platform node index, or `GMNAV_NO_NODE`

---

### gmnav_platgraph_node_world(pg, pnode)

The world position of a platform node, at the surface the character stands on.

**Parameters:**

- `pg` (struct) - Platformer graph
- `pnode` (int) - Platform node index

**Returns:** Array `[x, y]`

---

### gmnav_platgraph_link_get(pg, from, to)

The link between two platform nodes, so you can perform it yourself.

**Parameters:**

- `pg` (struct) - Platformer graph
- `from` (int) - Platform node index
- `to` (int) - Platform node index

**Returns:** Struct `{ type, cost, vx, vy, x, y }`, or `undefined` if no such link exists

`type` is `gmnav_link.WALK`, `FALL` or `JUMP`. `cost` is in frames. `vx` and `vy` are the launch velocity that produced the link. `x` and `y` are where it lands.

**Example:**

```
var _lk = gmnav_platgraph_link_get(pgraph, _from, _to);

if (_lk.type == gmnav_link.JUMP) {
    hsp = _lk.vx;
    vsp = _lk.vy;
}
```

---

### gmnav_platgraph_solid(pg, x, y, vy)

The same collision test the bake used, exposed so your character controller can stay in sync with it.

Using this rather than your own test is what keeps a replayed arc landing where the graph promised.

**Parameters:**

- `pg` (struct) - Platformer graph
- `x` (real) - World x of the character centre
- `y` (real) - World y of the feet
- `vy` (real, default: 0) - Vertical velocity, used to decide whether a one way platform blocks

**Returns:** Boolean

**Example:**

```
vy = min(vy + move.gravity, move.max_fall);

var _nx = x + vx;
if (gmnav_platgraph_solid(pgraph, _nx, y, 0)) vx = 0; else x = _nx;

var _ny = y + vy;
if (gmnav_platgraph_solid(pgraph, x, _ny, vy)) {
    // landed, or hit a ceiling if vy < 0
} else {
    y = _ny;
}
```

**Note:** integrate in the same order the bake did, gravity then horizontal then vertical, testing each separately. A different order drifts by a fraction of a pixel per frame, which is invisible on short hops and lands long jumps in the wrong place.

---

---

## Platform Agent Functions


Chapter 10's division of labour leaves the jumping to you, which is right for a character with an animation state machine you care about and a lot of work for a bat.

The platform agent follows a baked graph itself, replaying each link's stored launch velocity. It is the one place in GMNav that moves something, because arc replay is only correct if the stepping order matches the bake exactly, so the replay has to own the stepping.

Use it for characters whose movement is entirely the navigation's business. Use `gmnav_platgraph_link_get` for anything your game wants to interrupt.

---

### gmnav_platagent_create(sched, x, y)

Creates a platform agent and snaps it to the nearest standing position at or below the given position.

**Parameters:**

- `sched` (struct) - A scheduler created over a platformer graph
- `x` (real) - World x
- `y` (real) - World y of the feet

**Returns:** Platform agent struct

**Example:**

```
psched = gmnav_scheduler_create(pgraph, 1500);
hero   = gmnav_platagent_create(psched, x, y);
```

---

### gmnav_platagent_goto(pa, x, y, priority)

Requests a route to a world position.

Called mid-arc, the agent finishes the arc it committed to and routes from the node it is about to land on. Interrupting a ballistic trajectory halfway is not something the graph can price, and a character that changes direction in mid-air reads as weightless.

**Parameters:**

- `pa` (struct) - Platform agent
- `x` (real) - World x of the goal
- `y` (real) - World y of the goal
- `priority` (enum, default: `gmnav_priority.NORMAL`) - Request priority

**Returns:** Boolean, `false` if either end has no standing position

---

### gmnav_platagent_update(pa)

Advances the agent by one frame, integrating its own position.

Unlike every other part of GMNav, this writes `pa.x` and `pa.y`. Read them out afterwards.

**Parameters:**

- `pa` (struct) - Platform agent

**Example:**

```
gmnav_scheduler_update(psched);
gmnav_platagent_update(hero);

x = hero.x;
y = hero.y;
```

---

### gmnav_platagent_stop(pa)

Drops the route, cancels any request in flight, and snaps the agent back to its current node. Safe to call mid-arc.

**Parameters:**

- `pa` (struct) - Platform agent

---

### gmnav_platagent_arrived(pa)

Whether the agent finished its last route. Latched, cleared by the next `goto` or `stop`.

**Parameters:**

- `pa` (struct) - Platform agent

**Returns:** Boolean

---

### gmnav_platagent_airborne(pa)

Whether the agent is mid-arc right now, on a `FALL` or `JUMP` link.

This is how you pick a jump animation without inspecting the link yourself.

**Parameters:**

- `pa` (struct) - Platform agent

**Returns:** Boolean

---

### gmnav_platagent_has_route(pa)

Whether the agent still has links left to perform.

**Parameters:**

- `pa` (struct) - Platform agent

**Returns:** Boolean

---

### pa.desync

Not a function, but the field worth watching.

The agent counts frames where its own position disagreed with what the replay expected. In normal operation it stays at zero. A non-zero value means the movement model does not match the level, something else moved the character, or the collision data changed after the bake.

It is the cheapest signal you have that the model and the level have drifted apart.

---

---

## Graph Search Functions


These mirror the grid search functions, over a platformer graph rather than a grid. Use the scheduler instead unless you need direct control.

### gmnav_graphsearch_create(pgraph)

Creates a reusable search over a platformer graph.

**Parameters:**

- `pgraph` (struct) - Platformer graph

**Returns:** Graph search struct

**Example:**

```
gs = gmnav_graphsearch_create(pgraph);
```

---

### gmnav_graphsearch_begin(gs, start, goal)

Starts a search between platform node ids.

**Parameters:**

- `gs` (struct) - Graph search
- `start` (int) - Start platform node id
- `goal` (int) - Goal platform node id

**Returns:** bool - False with state `FAILED` when impossible, false with state `IDLE` when no workspace is free

**Example:**

```
gmnav_graphsearch_begin(gs, _from, _to);
```

---

### gmnav_graphsearch_step(gs, budget)

Advances the search. The budget counts heap pops.

**Parameters:**

- `gs` (struct) - Graph search
- `budget` (int, default: `GMNAV_DEFAULT_BUDGET`) - Maximum pops this call

**Returns:** enum - `gmnav_state.WORKING`, `FOUND`, or `FAILED`

**Example:**

```
gmnav_graphsearch_step(gs, 200);
```

---

### gmnav_graphsearch_solve(gs, start, goal)

Begins and runs to completion in one call.

**Parameters:**

- `gs` (struct) - Graph search
- `start` (int) - Start platform node id
- `goal` (int) - Goal platform node id

**Returns:** bool - Whether a path was found

**Example:**

```
if (gmnav_graphsearch_solve(gs, _from, _to)) { }
```

---

### gmnav_graphsearch_get_path(gs)

The result path.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** Array of platform node ids

**Example:**

```
var _path = gmnav_graphsearch_get_path(gs);
```

---

### gmnav_graphsearch_get_links(gs)

Link type used to enter each node of the path. Index 0 is always `WALK` and means nothing, since nothing was used to reach the start.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** Array of `gmnav_link` values, same length as the path

**Example:**

```
var _links = gmnav_graphsearch_get_links(gs);
```

---

### gmnav_graphsearch_get_points(gs)

World waypoints for a solved path. Pair with `gmnav_graphsearch_get_links` to know how each one is reached.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** Array of `[x, y]` arrays

**Example:**

```
var _pts = gmnav_graphsearch_get_points(gs);
```

---

### gmnav_graphsearch_is_stale(gs)

Whether the underlying grid changed since the search began.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** bool

**Example:**

```
if (gmnav_graphsearch_is_stale(gs)) { }
```

---

### gmnav_graphsearch_release(gs)

Gives back the workspace, keeps the result.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** Nothing

**Example:**

```
gmnav_graphsearch_release(gs);
```

---

### gmnav_graphsearch_abort(gs)

Cancels and resets to `IDLE`.

**Parameters:**

- `gs` (struct) - Graph search

**Returns:** Nothing

**Example:**

```
gmnav_graphsearch_abort(gs);
```

---

---

## Debug Functions


Every view understands overlays, drawing raised cells at the height they occupy with a thin line dropping to the ground cell beneath.

Each view answers one question. The fastest route to a diagnosis is picking the view whose question matches your symptom rather than turning everything on.

---

### gmnav_debug_config()

Creates a config struct for the debug views.

**Returns:** Config struct with `cull`, `cull_pad`, `alpha`, `line_alpha`, `line_width` and `max_cells`

**Example:**

```
cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.3;
```

**Note:** culling reads the current camera. In a room with no view enabled there is nothing to cull against, so everything is drawn rather than nothing.

---

### gmnav_debug_draw_grid(grid, cfg)

Blocked cells, base and overlay.

**Parameters:**

- `grid` (struct) - Grid
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_clearance(grid, cfg)

How much room there is around each cell. Brighter is more room.

The view to reach for when a large unit refuses a route that looks passable, because the answer is almost always a doorway one cell narrower than you remembered.

**Parameters:**

- `grid` (struct) - Grid
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_costs(grid, profile, cfg)

What one agent type pays for each cell.

Pass the profile rather than the grid alone, or you see only base terrain, which is rarely the thing you are debugging.

**Parameters:**

- `grid` (struct) - Grid
- `profile` (struct, default: undefined) - Cost profile
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_flowfield(field, cfg, show_dist)

An arrow and a distance shade per cell, with a circle marking each goal.

**Any arrow pointing into a wall means the field is wrong, not the steering.**

**Parameters:**

- `field` (struct) - Flow field
- `cfg` (struct, default: undefined) - Debug config
- `show_dist` (bool, default: `true`) - Whether to shade cells by distance

---

### gmnav_debug_draw_reach(grid, cfg, need_clear)

Colours each connected component differently.

One colour means everything is reachable from everything else. Two means your map is in two pieces, and you can see where the seam is. Walks authored links as well as ordinary adjacency, so a deck joined by stairs reads as part of the floor it connects to.

The clearance argument is the point of it. A map that is one component for a rat can be five islands for an ogre.

**Parameters:**

- `grid` (struct) - Grid
- `cfg` (struct, default: undefined) - Debug config
- `need_clear` (int, default: 0) - Only consider cells with at least this clearance

**Example:**

```
gmnav_debug_draw_reach(grid, cfg, 2);
```

---

### gmnav_debug_draw_path(grid, path, cfg, colour)

A node path. Dots are sized largest at the ends, medium at direction changes, small elsewhere.

**Parameters:**

- `grid` (struct) - Grid
- `path` (array) - Node ids
- `cfg` (struct, default: undefined) - Debug config
- `colour` (int, default: `GMNAV_DBG_PATH`) - Line colour

---

### gmnav_debug_draw_path_object(path, cfg, colour)

A path object, after smoothing or curving.

**Parameters:**

- `path` (struct) - Path object
- `cfg` (struct, default: undefined) - Debug config
- `colour` (int, default: `GMNAV_DBG_PATH`) - Line colour

---

### gmnav_debug_draw_search(search, cfg)

An in-flight frontier: open cells and closed cells drawn differently.

Renders only while a search holds a workspace. Once it finishes it releases the slot and this draws nothing, which is the point. It exists to watch a frontier expand across frames under a small budget.

**Parameters:**

- `search` (struct) - Search
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_agent(agent, cfg)

Body, velocity, path, current target and goal.

The solid ring is the waypoint being steered at right now, and a fainter ring marks the next real corner. A ring that never advances is an agent making no progress toward it. A red path rather than the usual colour means it has gone stale and not yet been replaced.

**Parameters:**

- `agent` (struct) - Agent
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_platgraph(pg, cfg, types, focus)

Ledges and links, colour coded by type.

561 links drawn at once is a scribble. Isolating a single node is how you actually read it.

**Parameters:**

- `pg` (struct) - Platformer graph
- `cfg` (struct, default: undefined) - Debug config
- `types` (int, default: 7) - Bitmask, 1 for walk, 2 for fall, 4 for jump
- `focus` (int, default: -1) - Draw only links touching this node

**Example:**

```
gmnav_debug_draw_platgraph(pgraph, cfg, 4);            // jumps only
gmnav_debug_draw_platgraph(pgraph, cfg, 7, node_id);   // one ledge
```

---

### gmnav_debug_draw_heights(grid, cfg, max_z)

Per-cell elevation, shaded.

**Parameters:**

- `grid` (struct) - Grid
- `cfg` (struct, default: undefined) - Debug config
- `max_z` (real, default: undefined) - Top of the shading range. Derived from the grid if omitted

---

### gmnav_debug_draw_steps(grid, max_climb, max_drop, cfg)

Which steps a unit with given limits is refused, drawn per edge. The view for working out why a route takes a long way round on sloped terrain.

**Parameters:**

- `grid` (struct) - Grid
- `max_climb` (real) - Largest rise
- `max_drop` (real) - Largest fall
- `cfg` (struct, default: undefined) - Debug config

---

### gmnav_debug_draw_stats(sched, x, y)

Budget, queue length, active searches and workspace use. Draw in a Draw GUI event.

The one to leave on longest. Watch **pending**.

**Parameters:**

- `sched` (struct) - Scheduler
- `x` (real, default: 8) - Screen x
- `y` (real, default: 8) - Screen y

---

### gmnav_debug_search_text(search)

A one line summary of a search's state, for your own overlays.

**Parameters:**

- `search` (struct) - Search

**Returns:** String

---

---

## Enum Reference


```
gmnav_layout      ORTHO, ISO_DIAMOND, ISO_STAGGERED, HEX_POINTY, HEX_FLAT
gmnav_neighbours  FOUR, EIGHT, SIX
gmnav_costmode    LOGICAL, VISUAL
gmnav_heuristic   AUTO, ZERO
gmnav_state       IDLE, WORKING, FOUND, FAILED
gmnav_priority    LOW, NORMAL, HIGH, IMMEDIATE
gmnav_domain      GRID, PLATFORM
gmnav_link        WALK, FALL, JUMP, STAIR
gmnav_bake        IDLE, SURFACES, LINKS, DONE
gmnav_curve       NONE, CORNER, SPLINE
gmnav_pmode       GROUND, LINK, SETTLE
```

`gmnav_link.STAIR` is used by authored overlay links. `gmnav_curve` selects a path curving mode. `gmnav_pmode` is the platform agent's internal state and is not something you set.

---

---

## Config Reference


### gmnav_init(overrides)

Initialises GMNav's settings, replacing the tuning macros earlier versions used. Call once, before creating anything.

Every setting has a default, so calling it with no arguments is normal. Unknown keys are ignored with a debug message rather than silently accepted.

**Parameters:**

- `overrides` (struct, default: undefined) - Settings to change from their defaults

**Example:**

```
gmnav_init();

gmnav_init({
    DEFAULT_BUDGET : 3000,
    EDIT_RING      : 64
});
```

---

The settings it accepts:

| Setting | Default | What it does |
|---|---|---|
| `PLAT_MAX_SIM` | 300 | Hard cap on simulated frames per arc |
| `PLAT_MAX_LINKS` | 24 | Most outgoing links kept per platform node |
| `PLAT_FALL_WALK_CELLS` | 4 | How far a fall may walk to reach a ledge edge |
| `DEFAULT_BUDGET` | 2000 | Node expansions per frame when none is given |
| `HEAP_INIT` | 256 | Initial open set capacity |
| `MAX_STEPS` | 1000000 | Hard abort guard per search |
| `CLEARANCE_MAX` | 16 | Largest clearance value stored per cell |
| `EDIT_RING` | 32 | Recent grid edits kept for scoped repathing |

`EDIT_RING` is read when a grid is created, so changing it affects grids made afterwards. A larger ring holds more history and costs a slightly longer scan; a smaller one overflows sooner and falls back to conservative repathing more often.

---

---

## Macro Reference


```
GMNAV_NO_NODE         -1
GMNAV_INF             infinity
GMNAV_FLAG_BLOCKED    1
GMNAV_FLAG_ONEWAY     2
```

Debug colours are `GMNAV_DBG_BLOCKED`, `GMNAV_DBG_PATH`, `GMNAV_DBG_GOAL`, `GMNAV_DBG_AGENT`, `GMNAV_DBG_OPEN`, `GMNAV_DBG_CLOSED` and `GMNAV_DBG_DECK`.

---

---

## Struct Reference

Fields you are expected to read or write are listed. Internal scratch used during a build is not.

### Grid

| Field | Type | Description |
| --- | --- | --- |
| `domain` | enum | Always `gmnav_domain.GRID` |
| `width`, `height` | int | Dimensions in cells |
| `count` | int | `width * height`. Overlay node ids begin here |
| `layout` | struct | Layout descriptor |
| `flags` | array | One packed integer per cell |
| `cost` | array | Base terrain cost per cell |
| `clear` | array | Clearance values, `undefined` until built |
| `clear_v` | int | Grid version the clearance was built at |
| `height_z` | array | Elevation per cell, `undefined` until the first height is set |
| `layer_lift` | real | Pixels between layers, absent until set |
| `overlay` | struct | Attached overlay, absent until one is created |
| `version` | int | Bumped on every genuine mutation |
| `edit_cap` | int | Recent edit rectangles kept. Set from config at creation, do not write to it |
| `edit_lost` | int | Newest version whose rectangle has been overwritten |
| `slots` | array | Search workspaces |
| `slot_max` | int | Workspace count |

### Layout

| Field | Type | Description |
| --- | --- | --- |
| `mode` | enum | `gmnav_layout` member |
| `tile_w`, `tile_h` | real | Tile bounding box |
| `neighbours` | enum | `gmnav_neighbours` member |
| `cost_mode` | enum | `gmnav_costmode` member |
| `origin_x`, `origin_y` | real | World origin of cell (0,0) |
| `parity_axis` | int | 0 none, 1 row parity, 2 column parity |
| `nb_count` | int | Neighbours per parity block |
| `nb_dc`, `nb_dr` | array | Neighbour offsets, both parity blocks |
| `nb_cost` | array | Per step cost, normalised so the cheapest is 1 |
| `step_min_world` | real | Shortest possible step in pixels |

### Overlay

| Field | Type | Description |
| --- | --- | --- |
| `grid` | struct | Grid it is attached to |
| `base` | int | Id offset. Overlay cell 0 is this node id |
| `count` | int | Cells held |
| `max_layer` | int | Highest layer index in use |
| `col`, `row`, `layer` | array | Position per cell |
| `flags` | array | One packed integer per cell |
| `cost` | array | Base cost per cell, independent of the ground below |
| `clear` | array | Clearance per cell, computed by `finish` |
| `offset` | array | Fraction of a layer each cell sits below its own |
| `links` | array | Authored crossings, kept so `finish` can re-run |
| `edge_start`, `edge_to`, `edge_cost`, `edge_type` | array | Adjacency out of overlay cells, CSR |
| `up_start`, `up_to`, `up_cost`, `up_type` | array | Authored links out of base cells, CSR over the base grid |
| `ready` | bool | Whether authoring has happened since the last `finish` |

### Search

| Field | Type | Description |
| --- | --- | --- |
| `state` | enum | `gmnav_state` member |
| `start`, `goal` | int | Node ids |
| `h_mode` | enum | Resolved heuristic |
| `corner_cut` | bool | Whether diagonal squeezes are allowed |
| `profile` | struct | Cost profile, or `undefined` |
| `need_clear` | int | Minimum clearance required |
| `max_climb`, `max_drop` | real | Elevation limits, `undefined` to ignore heights |
| `relax` | int | Steps from the start where clearance is relaxed, default 2 |
| `stale` | bool | Grid changed after this search began |
| `expansions` | int | Cells settled |
| `pops` | int | Heap entries popped, including stale ones |
| `slot_g_final` | real | Total cost of the found path |
| `result` | array | Node ids |

### Ticket

| Field | Type | Description |
| --- | --- | --- |
| `state` | enum | `gmnav_state` member |
| `priority` | enum | `gmnav_priority` member |
| `seq` | int | Arrival order, used for FIFO within a priority band |
| `start`, `goal` | int | Node ids |
| `corner_cut` | bool | Passed to the search |
| `profile` | struct | Passed to the search |
| `need_clear` | int | Passed to the search |
| `max_climb`, `max_drop` | real | Passed to the search |
| `path` | array | Node ids, empty unless found |
| `links` | array | `gmnav_link` values, platformer domain only |
| `stale` | bool | Grid changed while this request was in flight |
| `cancelled` | bool | Abandoned by the caller |

### Path

| Field | Type | Description |
| --- | --- | --- |
| `grid` | struct | Grid the nodes belong to |
| `nodes` | array | Node ids. Cleared by `gmnav_path_simplify`, kept by `gmnav_path_curve` |
| `px`, `py` | array | World coordinates per waypoint |
| `count` | int | Waypoint count |
| `length` | real | Total world length |
| `stale` | bool | Copied from the search that produced it |
| `version` | int | Grid version when the path was built, used for scoped repathing |

### Cost layer

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | For your own bookkeeping |
| `grid` | struct | Grid it covers |
| `values` | array | One value per node, base cells and overlay cells |
| `version` | int | Bumped on every change, watched by profiles |

### Cost profile

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | For your own bookkeeping |
| `grid` | struct | Grid it covers |
| `layers` | array | Layers in this profile |
| `weights` | array | Weight per layer, same order |
| `resolved` | array | Flattened cost per node, what the search reads |
| `baked` | bool | Whether a bake has happened at all |

### Agent

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `x`, `y` | real | - | Position. Yours to write, the agent never touches it |
| `vx`, `vy` | real | 0 | Proposed velocity. Written every update |
| `radius` | real | 8 | Used for avoidance, arrival, and passed to smoothing |
| `speed` | real | 2 | Maximum speed |
| `accel` | real | 0.35 | How fast desired velocity is approached, 0 to 1 |
| `arrive_dist` | real | 24 | Start easing off inside this range |
| `reach_dist` | real | 4 | Close enough, journey complete |
| `arrived` | bool | false | Latched until the next `goto` or `stop` |
| `failed` | bool | false | Last goal could not be routed to. Latched the same way |
| `layer` | int | 0 | Surface the agent is standing on |
| `goal_layer` | int | 0 | Surface the goal is on, remembered so a repath asks for the same one |
| `profile` | struct | `undefined` | Cost profile, passed on every request and to smoothing |
| `need_clear` | int | 0 | Minimum clearance, passed on every request |
| `max_climb`, `max_drop` | real | `undefined` | Elevation limits, passed on every request and to smoothing |
| `headings` | int | 0 | Headings smoothing may use. 0 unconstrained, 4 cardinals, 8 with diagonals |
| `curve_mode` | enum | `gmnav_curve.NONE` | Curve applied after smoothing and anchoring |
| `curve_radius` | real | 16 | Corner radius when curving |
| `curve_steps` | int | 4 | Samples per arc when curving |
| `repath_gap` | int | 20 | Frames between repath attempts |
| `avoid_str` | real | 1.0 | Separation strength, 0 disables |
| `avoid_range` | real | 3.0 | Separation reach, in multiples of radius |
| `path` | struct | `undefined` | Current path object |
| `ticket` | struct | `undefined` | Request in flight |
| `seek_i` | int | 1 | Index of the waypoint being steered toward |

### Movement

| Field | Type | Description |
| --- | --- | --- |
| `gravity` | real | Added to vertical velocity each frame |
| `jump_vel` | real | Jump velocity at full strength, positive |
| `run_speed` | real | Horizontal speed on the ground |
| `air_speed` | real | Horizontal speed in the air, defaults to `run_speed` |
| `max_fall` | real | Terminal fall speed |
| `width`, `height` | real | Character box |
| `jump_levels` | int | Jump strengths sampled between `jump_min` and full |
| `jump_min` | real | Weakest sampled jump, as a fraction of full |
| `jump_bias` | real | Multiplier on jump link costs, breaking ties toward walking |

### Platformer graph

| Field | Type | Description |
| --- | --- | --- |
| `domain` | enum | Always `gmnav_domain.PLATFORM` |
| `grid` | struct | Underlying navigation grid |
| `move` | struct | Movement model |
| `nodes` | array | Platform node to grid node |
| `node_of` | array | Grid node to platform node, -1 where none |
| `count` | int | Standing positions found |
| `edge_start` | array | CSR row offsets, length `count + 1` |
| `edge_to` | array | Destination platform node per edge |
| `edge_cost` | array | Traversal cost in frames per edge |
| `edge_type` | array | `gmnav_link` value per edge |
| `edge_vx`, `edge_vy` | array | Launch velocity that produced each edge |
| `node_x`, `node_y` | array | World position per platform node |
| `max_step` | real | Longest possible single frame displacement |
| `phase` | enum | `gmnav_bake` member |

### Platform agent

| Field | Type | Description |
| --- | --- | --- |
| `x`, `y` | real | Position. Written by `gmnav_platagent_update`, unlike every other agent |
| `vx`, `vy` | real | Current velocity during an arc |
| `node` | int | Platform node the agent is on or heading to |
| `mode` | enum | `gmnav_pmode` member, internal state |
| `face` | int | Last horizontal direction, 1 or -1 |
| `path` | array | Platform node ids |
| `links` | array | `gmnav_link` value per step |
| `seek` | int | Index of the link being performed |
| `link` | struct | The link currently being performed |
| `arrived` | bool | Latched until the next `goto` or `stop` |
| `failed` | bool | Last goal could not be routed to |
| `desync` | int | Frames where the replay and the world disagreed. Should stay 0 |

### Flow field

| Field | Type | Description |
| --- | --- | --- |
| `grid` | struct | Grid it covers |
| `profile` | struct | Cost profile it was built under, or `undefined` |
| `max_climb`, `max_drop` | real | Elevation limits applied while building |
| `dist` | array | Cost to the nearest goal per node, base cells and overlay cells |
| `dirx`, `diry` | array | Normalised world space direction per node |
| `next` | array | Node each cell steps to, `GMNAV_NO_NODE` at a goal. Read this when a step may change layer |
| `mark` | array | Generation stamp, `+gen` open, `-gen` closed |
| `gen` | int | Current build generation |
| `goals` | array | Seeded goal node ids |
| `max_dist` | real | Distance cap |
| `state` | enum | `gmnav_state` member |

### Scheduler

| Field | Type | Description |
| --- | --- | --- |
| `domain` | enum | `gmnav_domain` member, detected from the target |
| `target` | struct | Grid or platformer graph |
| `grid` | struct | Underlying grid, for world to node conversion |
| `budget` | int | Heap pops per frame, shared |
| `concurrent` | int | Maximum simultaneous searches |
| `queue` | array | Waiting tickets |
| `active` | array | Tickets holding a workspace |
| `pool` | array | Recycled search objects |
| `last_pops` | int | Pops used on the previous update |
| `last_active` | int | Searches running on the previous update |

---

## Known Behaviours


**A free cell is not a free position.** `gmnav_grid_is_blocked` asks about a cell. An agent with a radius needs a position its whole body fits in, and a point two pixels from a wall sits in a perfectly open cell. This is what clearance is for.

**Agents that never register arrival.** `reach_dist` defaults to 4 pixels. If an agent cannot physically reach within 4 pixels of its goal, because its body is stopped by a wall first, it never latches `arrived` and keeps pushing. Raise `reach_dist` past the agent radius, or validate goals against the body.

**Avoidance is separation, not reciprocal avoidance.** It stops crowds stacking into one pixel, which is what most games need. It will not resolve two agents walking into each other in a one tile corridor: both push symmetrically, both stall, and neither yields. Plan for that at the design level with wider passages or one way routes.

**Avoidance does not know about walls.** It repels agents from other agents only. When a crowd compresses against geometry it will push bodies into walls, and your movement code absorbs that.

**Editing the grid does not rebuild anything.** Flow fields, clearance and platformer graphs go out of date and say so. Rebuilding is your call, because only you know whether it is worth the frame.

**A suspended search does not re-validate.** Settled cells are never revisited, so a wall landing on ground a search has already crossed off goes unnoticed. The contract is termination plus the stale flag, not path validity.

**Smoothing needs telling about everything.** Elevation limits, body radius, headings and cost profile each close a way a shortcut could be wrong. Without them a shortcut will climb a cliff, clip a corner, take an illegal heading, or walk back through ground the search paid to avoid.

**Smoothing and curving are refused on staggered and hex.** On those layouts a straight line in cell coordinates says nothing reliable about whether a character could walk it. `gmnav_path_simplify` works everywhere.

**A deck narrower than a body will not smooth.** The corridor test asks whether the whole body fits along the line, and a one cell wide bridge cannot contain a wider body, so every shortcut across it is refused and every deck cell survives as a waypoint. That is correct rather than wasteful.

**Overlay offsets are drawn height, not climb cost.** They are read by world positions and the debug renderer, and are not consulted by `max_climb` or `max_drop`. For a slope only some units can take, use `gmnav_grid_set_height`.

**The surface between two cells belongs to your renderer.** A path across a ramp is a straight interpolation between two cell centres, so it looks right only if your ramp is drawn interpolated too.

**Cost cannot attract.** A negative profile weight is legal and resolved cost still clamps at 1, which is the same guarantee as the cost floor. Cost fields push; to pull a unit toward something, seed it as a goal in a flow field.

**Stamp peaks want to be modest.** Within about an order of magnitude of the base cost of 1. A peak far above that puts every reasonable weight past the point where a unit's decision flips, so tuning the weight appears to do nothing.

**Region baking is per profile.** A moving threat read by three unit types needs all three profiles rebaked, over both the old and the new rectangle.

**`gmnav_costprofile_add` appends.** Calling it twice with the same layer counts that layer twice. Use `gmnav_costprofile_set_weight` to change an existing weight.

**`gmnav_scheduler_is_ready` means found, not finished.** A failed request is finished but not ready. Check `ticket.state` if you need to tell the difference.

**`IMMEDIATE` bypasses the budget, not the workspace pool.** If every workspace is busy the request falls back into the queue and resolves later like any other.

**`GMNAV_FLAG_ONEWAY` is partial.** Standing on and jumping up through a one way platform work. Dropping down through one is not implemented, so a one way deck stacked over a solid ledge routes the long way round.

**Clearance is available on `ORTHO` and `ISO_DIAMOND` only.** On staggered and hex a Chebyshev radius in cell indices does not correspond to a disc in world space, so `gmnav_clearance_build` returns `false` and clearance requirements are ignored rather than failing every request.

---

---

## Internal Functions


Functions prefixed `__gmnav_` are internal and may change without notice.

`gmnav_heap_*` is the binary min-heap backing every search. It is unprefixed for historical reasons but is not part of the public surface.

---