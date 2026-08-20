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

## Grid Functions

### gmnav_grid_create(width, height, layout, slots)

Creates a navigation grid. Every cell starts walkable at cost 1.

**Parameters:**

- `width` (int) - Cells across
- `height` (int) - Cells down
- `layout` (struct) - From `gmnav_layout_create`
- `slots` (int, default: 4) - Maximum concurrent searches. Each holds three arrays sized to the cell count

**Returns:** Grid struct

**Example:**

```
grid = gmnav_grid_create(60, 40, layout, 4);
```

---

### gmnav_grid_node(grid, col, row)

Converts a column and row to a node id.

**Parameters:**

- `grid` (struct) - Navigation grid
- `col` (int) - Column
- `row` (int) - Row

**Returns:** int - Node id, or `GMNAV_NO_NODE` if out of bounds

**Example:**

```
var _n = gmnav_grid_node(grid, 5, 3);
```

---

### gmnav_grid_col(grid, node)

Column of a node id.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** int

**Example:**

```
var _c = gmnav_grid_col(grid, _node);
```

---

### gmnav_grid_row(grid, node)

Row of a node id.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** int

**Example:**

```
var _r = gmnav_grid_row(grid, _node);
```

---

### gmnav_grid_in_bounds(grid, col, row)

Whether a column and row lie inside the grid.

**Parameters:**

- `grid` (struct) - Navigation grid
- `col` (int) - Column
- `row` (int) - Row

**Returns:** bool

**Example:**

```
if (gmnav_grid_in_bounds(grid, _c, _r)) { }
```

---

### gmnav_grid_world_to_node(grid, x, y)

Node containing a world position.

**Parameters:**

- `grid` (struct) - Navigation grid
- `x` (real) - World x
- `y` (real) - World y

**Returns:** int - Node id, or `GMNAV_NO_NODE`

**Example:**

```
var _here = gmnav_grid_world_to_node(grid, x, y);
```

---

### gmnav_grid_node_to_world(grid, node)

World centre of a node.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** Array `[x, y]`

**Example:**

```
var _pos = gmnav_grid_node_to_world(grid, _node);
```

---

### gmnav_grid_is_blocked(grid, node)

Whether a node is blocked.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** bool

**Example:**

```
if (gmnav_grid_is_blocked(grid, _node)) { }
```

---

### gmnav_grid_has_flag(grid, node, flag)

Whether a node carries a flag bit.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id
- `flag` (int) - One of the `GMNAV_FLAG_*` macros

**Returns:** bool

**Example:**

```
if (gmnav_grid_has_flag(grid, _node, GMNAV_FLAG_WATER)) { }
```

---

### gmnav_grid_get_cost(grid, node)

Base terrain cost of a node. This is the grid's own cost, not a profile's resolved cost.

**Parameters:**

- `grid` (struct) - Navigation grid
- `node` (int) - Node id

**Returns:** real

**Example:**

```
var _c = gmnav_grid_get_cost(grid, _node);
```

---

### gmnav_grid_set_blocked(grid, col, row, blocked)

Blocks or unblocks one cell. Bumps the grid version only if the state actually changed.

**Parameters:**

- `grid` (struct) - Navigation grid
- `col` (int) - Column
- `row` (int) - Row
- `blocked` (bool) - New state

**Returns:** bool - False if out of bounds

**Example:**

```
gmnav_grid_set_blocked(grid, 5, 3, true);
```

---

### gmnav_grid_set_cost(grid, col, row, cost)

Sets a cell's terrain cost multiplier. Clamped at a minimum of 1, because a step cheaper than the heuristic assumes would break optimality. To make roads fast, make everything else slow.

**Parameters:**

- `grid` (struct) - Navigation grid
- `col` (int) - Column
- `row` (int) - Row
- `cost` (real) - Multiplier, clamped to at least 1

**Returns:** bool - False if out of bounds

**Example:**

```
gmnav_grid_set_cost(grid, 7, 6, 8);
```

---

### gmnav_grid_set_flag(grid, col, row, flag, on)

Sets or clears a flag bit on a cell.

**Parameters:**

- `grid` (struct) - Navigation grid
- `col` (int) - Column
- `row` (int) - Row
- `flag` (int) - One of the `GMNAV_FLAG_*` macros
- `on` (bool) - Set or clear

**Returns:** bool - False if out of bounds

**Example:**

```
gmnav_grid_set_flag(grid, 7, 6, GMNAV_FLAG_ONEWAY, true);
```

---

### gmnav_grid_fill_blocked(grid, c1, r1, c2, r2, blocked)

Blocks or unblocks a rectangle. Clamped to the grid, and bumps the version once for the whole operation.

**Parameters:**

- `grid` (struct) - Navigation grid
- `c1`, `r1`, `c2`, `r2` (int) - Rectangle corners, in either order
- `blocked` (bool) - New state

**Returns:** Nothing

**Example:**

```
gmnav_grid_fill_blocked(grid, 8, 1, 8, 7, true);
```

---

### gmnav_grid_import_tilemap(grid, tilemap, is_blocked)

Imports walkability from a tilemap layer. Assumes tilemap cell coordinates map one to one onto nav cells.

**Parameters:**

- `grid` (struct) - Navigation grid
- `tilemap` (id) - Tilemap element id
- `is_blocked` (function, optional) - Receives the raw tile index, returns bool. Defaults to "any non-empty tile blocks"

**Returns:** Nothing

**Example:**

```
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Tiles_Collision"));
```

---

### gmnav_grid_import_dsgrid(grid, ds_grid, is_blocked)

Imports walkability from a ds_grid.

**Parameters:**

- `grid` (struct) - Navigation grid
- `ds_grid` (id) - Source ds_grid
- `is_blocked` (function, optional) - Receives the cell value, returns bool. Defaults to "non-zero blocks"

**Returns:** Nothing

**Example:**

```
gmnav_grid_import_dsgrid(grid, my_collision_grid);
```

---

### gmnav_grid_import_callback(grid, fn)

Imports from any source. The callback receives `(col, row)` and returns either a bool, or a struct for full control.

**Parameters:**

- `grid` (struct) - Navigation grid
- `fn` (function) - Returns bool, or a struct with fields `blocked` (bool), `cost` (real), `flags` (int)

**Returns:** Nothing

**Example:**

```
gmnav_grid_import_callback(grid, function(_c, _r) {
    return { blocked: false, cost: 4, flags: GMNAV_FLAG_WATER };
});
```

---

### gmnav_grid_scratch_acquire(grid)

Takes a free search workspace. Called by searches, not usually by you.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** Slot struct, or `undefined` if all slots are busy

**Example:**

```
var _slot = gmnav_grid_scratch_acquire(grid);
```

---

### gmnav_grid_scratch_release(grid, slot)

Returns a workspace to the pool.

**Parameters:**

- `grid` (struct) - Navigation grid
- `slot` (struct) - Slot from `gmnav_grid_scratch_acquire`

**Returns:** Nothing

**Example:**

```
gmnav_grid_scratch_release(grid, _slot);
```

---

### gmnav_grid_scratch_flush(grid)

Frees every idle workspace. The grid stays usable, slots reallocate on next acquire.

**Parameters:**

- `grid` (struct) - Navigation grid

**Returns:** Nothing

**Example:**

```
gmnav_grid_scratch_flush(grid);
```

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

## Search Functions

### gmnav_search_create(grid, heuristic)

Creates a reusable search object. Create once and reuse, rather than one per request.

**Parameters:**

- `grid` (struct) - Navigation grid
- `heuristic` (enum, default: `gmnav_heuristic.AUTO`) - `AUTO` picks the strongest admissible heuristic for the layout

**Returns:** Search struct

**Example:**

```
search = gmnav_search_create(grid);
```

---

### gmnav_search_begin(search, start_node, goal_node, corner_cut, profile, need_clear)

Starts a search. Does no work beyond setup.

**Parameters:**

- `search` (struct) - Search object
- `start_node` (int) - Start node id
- `goal_node` (int) - Goal node id
- `corner_cut` (bool, default: false) - Allow diagonal steps between two diagonally opposed walls
- `profile` (struct, optional) - Cost profile from `gmnav_costprofile_create`
- `need_clear` (int, default: 0) - Minimum clearance required, 0 to ignore

**Returns:** bool - False on failure. Check `search.state`: `FAILED` means impossible, `IDLE` means no workspace was free and you should retry

**Example:**

```
gmnav_search_begin(search, _from, _to, false, soldier, 2);
```

---

### gmnav_search_step(search, budget)

Advances a search by a limited amount of work and returns. The budget counts heap pops, not expansions, so stale pops are still charged.

**Parameters:**

- `search` (struct) - Search object
- `budget` (int, default: `GMNAV_DEFAULT_BUDGET`) - Maximum heap pops this call

**Returns:** enum - `gmnav_state.WORKING`, `FOUND`, or `FAILED`

**Example:**

```
if (gmnav_search_step(search, 500) == gmnav_state.FOUND) { }
```

---

### gmnav_search_get_path(search)

The result path. Empty unless the state is `FOUND`.

**Parameters:**

- `search` (struct) - Search object

**Returns:** Array of node ids, start to goal inclusive

**Example:**

```
var _path = gmnav_search_get_path(search);
```

---

### gmnav_search_is_stale(search)

Whether the grid changed after this search began. A stale result is not guaranteed to be walkable, see Known Behaviours.

**Parameters:**

- `search` (struct) - Search object

**Returns:** bool

**Example:**

```
if (gmnav_search_is_stale(search)) { }
```

---

### gmnav_search_release(search)

Gives back the workspace but keeps the result. Called automatically when a search resolves.

**Parameters:**

- `search` (struct) - Search object

**Returns:** Nothing

**Example:**

```
gmnav_search_release(search);
```

---

### gmnav_search_abort(search)

Cancels and resets to `IDLE`. Safe at any time.

**Parameters:**

- `search` (struct) - Search object

**Returns:** Nothing

**Example:**

```
gmnav_search_abort(search);
```

---

## Scheduler Functions

### gmnav_scheduler_create(target, budget, concurrent)

Creates a scheduler that shares one frame budget across every search it runs. Works over a grid or a platformer graph, detected from the target.

**Parameters:**

- `target` (struct) - A grid, or a platformer graph
- `budget` (int, default: `GMNAV_DEFAULT_BUDGET`) - Heap pops per frame, shared by all active searches
- `concurrent` (int, default: 4) - Maximum simultaneous searches, capped by the target's workspace count

**Returns:** Scheduler struct

**Example:**

```
sched = gmnav_scheduler_create(grid, 2000, 4);
```

---

### gmnav_scheduler_request(sched, start_node, goal_node, priority, corner_cut, profile, need_clear)

Requests a path. Returns immediately with a ticket, before any work has happened.

**Parameters:**

- `sched` (struct) - Scheduler
- `start_node` (int) - Start node id, domain appropriate
- `goal_node` (int) - Goal node id
- `priority` (enum, default: `gmnav_priority.NORMAL`) - `LOW`, `NORMAL`, `HIGH`, or `IMMEDIATE`
- `corner_cut` (bool, default: false) - Grid domain only
- `profile` (struct, optional) - Grid domain only
- `need_clear` (int, default: 0) - Grid domain only

**Returns:** Ticket struct

**Example:**

```
ticket = gmnav_scheduler_request(sched, _from, _to, gmnav_priority.HIGH);
```

---

### gmnav_scheduler_update(sched)

Advances every active search under the shared budget. Call once per step, before anything reads a ticket.

**Parameters:**

- `sched` (struct) - Scheduler

**Returns:** Nothing

**Example:**

```
gmnav_scheduler_update(sched);
```

---

### gmnav_scheduler_cancel(sched, ticket)

Abandons a request. Safe whether queued, running, or already finished. Frees the workspace on the next update.

**Parameters:**

- `sched` (struct) - Scheduler
- `ticket` (struct) - Ticket to cancel

**Returns:** Nothing

**Example:**

```
gmnav_scheduler_cancel(sched, ticket);
```

---

### gmnav_scheduler_is_ready(ticket)

Whether a ticket resolved successfully.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** bool

**Example:**

```
if (gmnav_scheduler_is_ready(ticket)) { }
```

---

### gmnav_scheduler_get_path(ticket)

The resolved path.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** Array of node ids, empty unless found

**Example:**

```
var _path = gmnav_scheduler_get_path(ticket);
```

---

### gmnav_scheduler_get_links(ticket)

Link types used to enter each node of the path. Platformer domain only, empty on a grid scheduler.

**Parameters:**

- `ticket` (struct) - Ticket

**Returns:** Array of `gmnav_link` values, same length as the path

**Example:**

```
var _links = gmnav_scheduler_get_links(ticket);
```

---

### gmnav_scheduler_pending(sched)

How many requests are waiting for a workspace. If this stays high across frames, raise the budget or the workspace count.

**Parameters:**

- `sched` (struct) - Scheduler

**Returns:** int

**Example:**

```
if (gmnav_scheduler_pending(sched) > 20) { }
```

---

## Path Functions

### gmnav_path_create(grid, nodes)

Converts an array of node ids into world space waypoints.

**Parameters:**

- `grid` (struct) - Navigation grid
- `nodes` (array) - Node ids, from a search or a ticket

**Returns:** Path struct

**Example:**

```
path = gmnav_path_create(grid, gmnav_scheduler_get_path(ticket));
```

---

### gmnav_path_get_count(path)

Number of waypoints.

**Parameters:**

- `path` (struct) - Path object

**Returns:** int

**Example:**

```
var _n = gmnav_path_get_count(path);
```

---

### gmnav_path_get_x(path, index)

World x of a waypoint.

**Parameters:**

- `path` (struct) - Path object
- `index` (int) - Waypoint index

**Returns:** real

**Example:**

```
var _x = gmnav_path_get_x(path, 0);
```

---

### gmnav_path_get_y(path, index)

World y of a waypoint.

**Parameters:**

- `path` (struct) - Path object
- `index` (int) - Waypoint index

**Returns:** real

**Example:**

```
var _y = gmnav_path_get_y(path, 0);
```

---

### gmnav_path_get_length(path)

Total world length of the path.

**Parameters:**

- `path` (struct) - Path object

**Returns:** real

**Example:**

```
var _len = gmnav_path_get_length(path);
```

---

### gmnav_path_anchor_start(path, x, y)

Replaces the first waypoint with a real position. Grid paths start at a cell centre, so without this an agent standing off-centre snaps backwards on its first step.

**Parameters:**

- `path` (struct) - Path object
- `x` (real) - True start x
- `y` (real) - True start y

**Returns:** Nothing

**Example:**

```
gmnav_path_anchor_start(path, x, y);
```

---

### gmnav_path_anchor_end(path, x, y)

Replaces the last waypoint with the true goal position.

**Parameters:**

- `path` (struct) - Path object
- `x` (real) - True goal x
- `y` (real) - True goal y

**Returns:** Nothing

**Example:**

```
gmnav_path_anchor_end(path, target_x, target_y);
```

---

### gmnav_path_smooth(path)

String pulling. Walks forward from each kept waypoint to the furthest node still in line of sight and drops everything between, turning staircases into straight runs.

Does nothing on `ISO_STAGGERED` and hex layouts, where a straight line in cell coordinates does not correspond to a straight line on screen.

**Parameters:**

- `path` (struct) - Path object

**Returns:** Nothing

**Example:**

```
gmnav_path_smooth(path);
```

---

### gmnav_path_simplify(path, tolerance)

Drops waypoints that lie on a straight line between their neighbours. Safe on every layout, and it does not change the path's shape.

Clears `path.nodes`, because the waypoints no longer correspond one to one with cells. Run `gmnav_path_smooth` first if you want both.

**Parameters:**

- `path` (struct) - Path object
- `tolerance` (real, default: 0.01) - Collinearity threshold

**Returns:** Nothing

**Example:**

```
gmnav_path_simplify(path);
```

---

### gmnav_path_sample(path, distance)

Position at a given distance along the path, clamped at both ends.

**Parameters:**

- `path` (struct) - Path object
- `distance` (real) - Distance along the path in world units

**Returns:** Array `[x, y]`

**Example:**

```
var _pos = gmnav_path_sample(path, 128);
```

---

### gmnav_grid_line_clear(grid, c0, r0, c1, r1)

Supercover line test between two cells. True when every cell the segment touches is walkable.

Unlike Bresenham this visits every touched cell and refuses exact corner crossings unless both flanking cells are open, so it never approves a diagonal squeeze through a wall join.

**Parameters:**

- `grid` (struct) - Navigation grid
- `c0`, `r0` (int) - Start cell
- `c1`, `r1` (int) - End cell

**Returns:** bool

**Example:**

```
if (gmnav_grid_line_clear(grid, 5, 3, 12, 9)) { }
```

---

### gmnav_grid_node_line_clear(grid, a, b)

The same test between two node ids.

**Parameters:**

- `grid` (struct) - Navigation grid
- `a` (int) - Start node id
- `b` (int) - End node id

**Returns:** bool

**Example:**

```
if (gmnav_grid_node_line_clear(grid, _a, _b)) { }
```

---

## Cost Field Functions

### gmnav_costlayer_create(grid, name)

Creates an empty influence layer sized to the grid. Values are additive penalties in step units, 0 means no opinion.

**Parameters:**

- `grid` (struct) - Navigation grid
- `name` (string, default: "") - Label, for debugging

**Returns:** Layer struct

**Example:**

```
danger = gmnav_costlayer_create(grid, "danger");
```

---

### gmnav_costlayer_set(layer, col, row, value)

Sets one cell's value.

**Parameters:**

- `layer` (struct) - Cost layer
- `col` (int) - Column
- `row` (int) - Row
- `value` (real) - Penalty

**Returns:** bool - False if out of bounds

**Example:**

```
gmnav_costlayer_set(danger, 7, 6, 12);
```

---

### gmnav_costlayer_get(layer, col, row)

Reads one cell's value.

**Parameters:**

- `layer` (struct) - Cost layer
- `col` (int) - Column
- `row` (int) - Row

**Returns:** real - 0 if out of bounds

**Example:**

```
var _v = gmnav_costlayer_get(danger, 7, 6);
```

---

### gmnav_costlayer_clear(layer)

Zeroes the entire layer.

**Parameters:**

- `layer` (struct) - Cost layer

**Returns:** Nothing

**Example:**

```
gmnav_costlayer_clear(danger);
```

---

### gmnav_costlayer_stamp_radial(layer, wx, wy, radius, peak, falloff)

Stamps a radial falloff in world space. Overlapping stamps combine with max, not addition, so two turrets covering a cell make it dangerous rather than twice as dangerous, and re-stamping the same spot is idempotent.

**Parameters:**

- `layer` (struct) - Cost layer
- `wx` (real) - World x of the centre
- `wy` (real) - World y of the centre
- `radius` (real) - Reach in world units
- `peak` (real) - Value at the centre
- `falloff` (real, default: 1) - 1 linear, 2 quadratic, higher is a tighter core

**Returns:** Array `[c1, r1, c2, r2]` - The cell rect touched, for feeding into `gmnav_costprofile_bake_region`

**Example:**

```
var _rect = gmnav_costlayer_stamp_radial(danger, player_x, player_y, 200, 20, 2);
```

---

### gmnav_costlayer_clear_region(layer, c1, r1, c2, r2)

Zeroes a cell rect. Use before re-stamping a stamp that moved, passing the rect the previous stamp returned.

**Parameters:**

- `layer` (struct) - Cost layer
- `c1`, `r1`, `c2`, `r2` (int) - Rectangle corners

**Returns:** Nothing

**Example:**

```
gmnav_costlayer_clear_region(danger, _old[0], _old[1], _old[2], _old[3]);
```

---

### gmnav_costprofile_create(grid, name)

Creates a resolved cost profile. Pass this to a search, a scheduler request, an agent, or a flow field.

**Parameters:**

- `grid` (struct) - Navigation grid
- `name` (string, default: "") - Label, for debugging

**Returns:** Profile struct

**Example:**

```
soldier = gmnav_costprofile_create(grid, "soldier");
```

---

### gmnav_costprofile_add(profile, layer, weight)

Adds a layer to a profile with a weight. Weights live on the profile, not the layer, so several agent types can read one layer and disagree about it.

**Parameters:**

- `profile` (struct) - Cost profile
- `layer` (struct) - Cost layer
- `weight` (real, default: 1) - Multiplier. 0 ignores the layer entirely

**Returns:** Nothing

**Example:**

```
gmnav_costprofile_add(soldier, danger, 1);
```

---

### gmnav_costprofile_set_weight(profile, layer, weight)

Changes an existing layer's weight and marks the profile dirty.

**Parameters:**

- `profile` (struct) - Cost profile
- `layer` (struct) - Cost layer already added
- `weight` (real) - New multiplier

**Returns:** bool - False if the layer is not in this profile

**Example:**

```
gmnav_costprofile_set_weight(soldier, danger, 4);
```

---

### gmnav_costprofile_remove(profile, layer)

Removes a layer from a profile.

**Parameters:**

- `profile` (struct) - Cost profile
- `layer` (struct) - Cost layer

**Returns:** bool - False if the layer is not in this profile

**Example:**

```
gmnav_costprofile_remove(soldier, danger);
```

---

### gmnav_costprofile_is_dirty(profile)

Whether the profile needs rebaking. Goes dirty when a layer changes, a weight changes, or the grid's terrain changes.

**Parameters:**

- `profile` (struct) - Cost profile

**Returns:** bool

**Example:**

```
if (gmnav_costprofile_is_dirty(soldier)) { }
```

---

### gmnav_costprofile_bake(profile)

Flattens the base terrain cost and every weighted layer into one array the search reads directly. This is what keeps a twelve layer profile as cheap at search time as no profile at all.

Resolved cost is clamped to a minimum of 1, so negative weights make dangerous ground ordinary rather than attractive.

**Parameters:**

- `profile` (struct) - Cost profile

**Returns:** Nothing

**Example:**

```
gmnav_costprofile_bake(soldier);
```

---

### gmnav_costprofile_bake_if_dirty(profile)

Rebakes only when needed.

**Parameters:**

- `profile` (struct) - Cost profile

**Returns:** Nothing

**Example:**

```
gmnav_costprofile_bake_if_dirty(soldier);
```

---

### gmnav_costprofile_bake_region(profile, c1, r1, c2, r2)

Rebakes one cell rect. For a stamp that follows a moving target, this is a few hundred writes instead of the whole map.

Cover the old footprint as well as the new one, or the previous stamp stays burned into the resolved array. Does not clear the dirty flag, since it only guarantees the rectangle you named.

**Parameters:**

- `profile` (struct) - Cost profile
- `c1`, `r1`, `c2`, `r2` (int) - Rectangle corners

**Returns:** Nothing

**Example:**

```
gmnav_costprofile_bake_region(soldier, _new[0], _new[1], _new[2], _new[3]);
```

---

## Flow Field Functions

### gmnav_flowfield_create(grid, profile)

Creates a flow field. Allocates four arrays sized to the cell count, so keep one per goal, not one per agent.

**Parameters:**

- `grid` (struct) - Navigation grid
- `profile` (struct, optional) - Cost profile to build against

**Returns:** Field struct

**Example:**

```
field = gmnav_flowfield_create(grid);
```

---

### gmnav_flowfield_build(field, goal_nodes, max_dist)

Builds the field to completion. Suitable at level load, not during gameplay on a large map.

**Parameters:**

- `field` (struct) - Flow field
- `goal_nodes` (int or array) - One node id, or several. Multiple goals cost almost nothing extra and every cell points at its own nearest one
- `max_dist` (real, default: infinity) - Stop expanding past this cost, in step units

**Returns:** bool - Success status

**Example:**

```
gmnav_flowfield_build(field, [_exit_a, _exit_b, _exit_c], 40);
```

---

### gmnav_flowfield_begin(field, goal_nodes, max_dist)

Starts a sliced build. Advance it with `gmnav_flowfield_step`.

**Parameters:**

- `field` (struct) - Flow field
- `goal_nodes` (int or array) - One or several goal node ids
- `max_dist` (real, default: infinity) - Distance cap

**Returns:** bool - False if no goal was valid

**Example:**

```
gmnav_flowfield_begin(field, _goal, 25);
```

---

### gmnav_flowfield_step(field, budget)

Advances the build. Runs the distance pass first, then the direction pass, both under the same budget.

**Parameters:**

- `field` (struct) - Flow field
- `budget` (int, default: `GMNAV_DEFAULT_BUDGET`) - Work units this call

**Returns:** enum - `gmnav_state.WORKING`, `FOUND`, or `FAILED`

**Example:**

```
if (gmnav_flowfield_step(field, 2000) == gmnav_state.FOUND) { }
```

---

### gmnav_flowfield_sample(field, x, y)

Direction an agent at this world position should move. Computed in world space, so it is correct on isometric and hex layouts where a cell offset is not a screen direction.

**Parameters:**

- `field` (struct) - Flow field
- `x` (real) - World x
- `y` (real) - World y

**Returns:** Array `[x, y]` - Normalised, or `[0, 0]` on an unreachable or goal cell

**Example:**

```
var _d = gmnav_flowfield_sample(field, x, y);
x += _d[0] * spd;
y += _d[1] * spd;
```

---

### gmnav_flowfield_cost_at(field, x, y)

Cost from this cell to the nearest goal, in step units.

**Parameters:**

- `field` (struct) - Flow field
- `x` (real) - World x
- `y` (real) - World y

**Returns:** real - `infinity` if unreachable or beyond `max_dist`

**Example:**

```
var _far = gmnav_flowfield_cost_at(field, x, y);
```

---

### gmnav_flowfield_is_reachable(field, x, y)

Whether a cell can reach any goal.

**Parameters:**

- `field` (struct) - Flow field
- `x` (real) - World x
- `y` (real) - World y

**Returns:** bool

**Example:**

```
if (!gmnav_flowfield_is_reachable(field, x, y)) { }
```

---

### gmnav_flowfield_is_ready(field)

Whether the build has completed.

**Parameters:**

- `field` (struct) - Flow field

**Returns:** bool

**Example:**

```
if (gmnav_flowfield_is_ready(field)) { }
```

---

### gmnav_flowfield_is_stale(field)

Whether the grid changed since the field was built. Fields do not self-repair, rebuild explicitly.

**Parameters:**

- `field` (struct) - Flow field

**Returns:** bool

**Example:**

```
if (gmnav_flowfield_is_stale(field)) gmnav_flowfield_begin(field, _goal);
```

---

## Agent Functions

### gmnav_agent_create(sched, x, y, radius, speed)

Creates an agent bound to a scheduler. The agent proposes a velocity and never moves your instance.

**Parameters:**

- `sched` (struct) - Scheduler
- `x` (real) - Starting world x
- `y` (real) - Starting world y
- `radius` (real, default: 8) - Used for avoidance and arrival
- `speed` (real, default: 2) - Maximum speed in pixels per frame

**Returns:** Agent struct

**Example:**

```
agent = gmnav_agent_create(sched, x, y, 12, 3);
```

---

### gmnav_agent_goto(agent, gx, gy, priority)

Asks the agent to walk to a world position. Requests a path from the scheduler and clears the arrival flag.

**Parameters:**

- `agent` (struct) - Agent
- `gx` (real) - Goal world x
- `gy` (real) - Goal world y
- `priority` (enum, default: `gmnav_priority.NORMAL`) - Request priority

**Returns:** bool - False if either endpoint is off the grid

**Example:**

```
gmnav_agent_goto(agent, mouse_x, mouse_y);
```

---

### gmnav_agent_update(agent, neighbours)

Steps the agent. Call once per frame, after `gmnav_scheduler_update`. Writes `vx` and `vy`, and never touches `x` or `y`.

**Parameters:**

- `agent` (struct) - Agent
- `neighbours` (array, optional) - Other agent structs, for separation steering

**Returns:** Nothing

**Example:**

```
gmnav_agent_update(agent, _nearby);
x += agent.vx;
y += agent.vy;
```

---

### gmnav_agent_stop(agent)

Drops the current goal and path. Velocity decays to zero rather than stopping dead.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** Nothing

**Example:**

```
gmnav_agent_stop(agent);
```

---

### gmnav_agent_has_path(agent)

Whether the agent currently holds a path.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** bool

**Example:**

```
if (!gmnav_agent_has_path(agent)) { }
```

---

### gmnav_agent_arrived(agent)

Whether the agent finished following its path. Latched, so it stays true until the next `goto` or `stop`. False after a failed request, since the agent never received a path.

This cannot be derived from `has_path`, because the path is cleared in the same update that completes the journey.

**Parameters:**

- `agent` (struct) - Agent

**Returns:** bool

**Example:**

```
if (gmnav_agent_arrived(agent)) gmnav_agent_goto(agent, _next.x, _next.y);
```

---

## Platformer Functions

### gmnav_movement_create(gravity, jump_vel, run_speed, max_fall, width, height, air_speed, jump_levels, jump_bias)

Describes how your character moves. Use your player controller's real numbers, not approximations. If `jump_vel` is even slightly generous the graph will contain links your character cannot traverse.

The arc simulation integrates in this order: gravity, clamp to terminal velocity, move X, then move Y. If your controller differs, long jumps land in the wrong place.

**Parameters:**

- `gravity` (real) - Downward acceleration per frame
- `jump_vel` (real) - Upward velocity at full jump, positive
- `run_speed` (real) - Horizontal speed on the ground
- `max_fall` (real) - Terminal downward velocity
- `width` (real) - Character width in world units
- `height` (real) - Character height in world units
- `air_speed` (real, optional) - Horizontal speed while airborne, defaults to `run_speed`
- `jump_levels` (int, default: 3) - How many jump strengths to sample between minimum and full. 1 for a fixed height jump
- `jump_bias` (real, default: 1.15) - Multiplier on jump link cost. On flat ground, walking and hopping cost exactly the same, so without a bias above 1 the AI bunny hops

**Returns:** Movement struct

**Example:**

```
move = gmnav_movement_create(0.5, 8, 3, 9, 12, 24);
```

---

### gmnav_platgraph_create(grid, movement)

Creates a platformer graph over a grid. Requires an `ORTHO` layout.

**Parameters:**

- `grid` (struct) - Navigation grid
- `movement` (struct) - From `gmnav_movement_create`

**Returns:** Platformer graph struct

**Example:**

```
pgraph = gmnav_platgraph_create(grid, move);
```

---

### gmnav_platgraph_bake(pgraph)

Bakes the graph to completion. Extracts standing positions, then simulates `2 + 3 x jump_levels` arcs from each. Level load only.

**Parameters:**

- `pgraph` (struct) - Platformer graph

**Returns:** bool - Success status

**Example:**

```
gmnav_platgraph_bake(pgraph);
```

---

### gmnav_platgraph_bake_begin(pgraph)

Starts a sliced bake.

**Parameters:**

- `pgraph` (struct) - Platformer graph

**Returns:** Nothing

**Example:**

```
gmnav_platgraph_bake_begin(pgraph);
```

---

### gmnav_platgraph_bake_step(pgraph, budget)

Advances the bake. The budget counts cells during the surface phase and nodes during the link phase, so the same number costs very different amounts in each.

**Parameters:**

- `pgraph` (struct) - Platformer graph
- `budget` (int, default: 256) - Work units this call

**Returns:** enum - Current `gmnav_bake` phase

**Example:**

```
if (gmnav_platgraph_bake_step(pgraph, 256) == gmnav_bake.DONE) { }
```

---

### gmnav_platgraph_is_ready(pgraph)

Whether the bake has completed.

**Parameters:**

- `pgraph` (struct) - Platformer graph

**Returns:** bool

**Example:**

```
if (gmnav_platgraph_is_ready(pgraph)) { }
```

---

### gmnav_platgraph_is_stale(pgraph)

Whether the underlying grid changed since the bake.

**Parameters:**

- `pgraph` (struct) - Platformer graph

**Returns:** bool

**Example:**

```
if (gmnav_platgraph_is_stale(pgraph)) gmnav_platgraph_bake_begin(pgraph);
```

---

### gmnav_platgraph_node_at(pgraph, x, y, max_drop_cells)

Platform node the character is standing on. Searches downward, so it also works while airborne, finding the ledge below.

**Parameters:**

- `pgraph` (struct) - Platformer graph
- `x` (real) - World x
- `y` (real) - World y, at the character's feet
- `max_drop_cells` (int, default: 4) - How far down to look

**Returns:** int - Platform node id, or `GMNAV_NO_NODE`

**Example:**

```
var _from = gmnav_platgraph_node_at(pgraph, x, y);
```

---

### gmnav_platgraph_node_world(pgraph, pnode)

World position of a platform node, at the character's feet and horizontally centred in the cell.

**Parameters:**

- `pgraph` (struct) - Platformer graph
- `pnode` (int) - Platform node id

**Returns:** Array `[x, y]`

**Example:**

```
var _pos = gmnav_platgraph_node_world(pgraph, _node);
```

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

## Debug Functions

All drawing functions belong in a Draw event and work in world space, except `gmnav_debug_draw_stats`, which belongs in Draw GUI.

### gmnav_debug_config()

Creates a settings struct for the debug renderer.

**Parameters:** None

**Returns:** Struct with fields:

- `alpha` (real, default: 0.35) - Fill opacity
- `line_alpha` (real, default: 0.9) - Line opacity
- `line_width` (real, default: 2) - Path line thickness
- `show_labels` (bool, default: false) - Per cell numeric text, very slow
- `cull` (bool, default: true) - Skip cells outside the camera. Set false in rooms with no view enabled, or nothing will draw
- `cull_pad` (real, default: 64) - Margin around the view
- `max_cells` (int, default: `GMNAV_DBG_MAX_CELLS`) - Per call ceiling before bailing out with a console warning

**Example:**

```
cfg = gmnav_debug_config();
cfg.cull = false;
```

---

### gmnav_debug_draw_grid(grid, cfg)

Fills blocked cells, in the layout's real shape. The cheapest useful overlay, and the fastest way to confirm GMNav's idea of your world matches your own.

**Parameters:**

- `grid` (struct) - Navigation grid
- `cfg` (struct, optional) - Debug config

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_grid(grid);
```

---

### gmnav_debug_draw_clearance(grid, cfg)

Clearance map as a green ramp. Darker is tighter.

**Parameters:**

- `grid` (struct) - Navigation grid
- `cfg` (struct, optional) - Debug config

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_clearance(grid);
```

---

### gmnav_debug_draw_costs(grid, profile, cfg)

Resolved cost as a red ramp. Pass a profile to see what a specific agent type actually pays, rather than base terrain.

**Parameters:**

- `grid` (struct) - Navigation grid
- `profile` (struct, optional) - Cost profile
- `cfg` (struct, optional) - Debug config

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_costs(grid, soldier);
```

---

### gmnav_debug_draw_flowfield(field, cfg, show_dist)

Direction arrows and a distance ramp. Any arrow pointing into a wall means the field is wrong, not the steering.

**Parameters:**

- `field` (struct) - Flow field
- `cfg` (struct, optional) - Debug config
- `show_dist` (bool, default: true) - Also shade cells by distance

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_flowfield(field);
```

---

### gmnav_debug_draw_path(grid, path, cfg, colour)

Draws a node id path.

**Parameters:**

- `grid` (struct) - Navigation grid
- `path` (array) - Node ids
- `cfg` (struct, optional) - Debug config
- `colour` (int, default: `GMNAV_DBG_PATH`) - Line colour

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_path(grid, gmnav_search_get_path(search));
```

---

### gmnav_debug_draw_path_object(path, cfg, colour)

Draws a path object, which after smoothing is not the same shape as the raw node path.

**Parameters:**

- `path` (struct) - Path object
- `cfg` (struct, optional) - Debug config
- `colour` (int, default: `GMNAV_DBG_PATH`) - Line colour

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_path_object(agent.path);
```

---

### gmnav_debug_draw_search(search, cfg)

Open and closed sets of a search in flight. Draws nothing once a search resolves, because the workspace has been released. Its purpose is watching a frontier expand across frames under a small budget.

**Parameters:**

- `search` (struct) - Search object
- `cfg` (struct, optional) - Debug config

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_search(search);
```

---

### gmnav_debug_draw_platgraph(pgraph, cfg, types, focus)

Platform nodes and links, coloured by type. White is walk, blue is fall, orange is jump, with arrowheads showing direction.

On a dense graph, draw everything at once and the arcs overlap into noise. Pass a focus node to isolate one ledge, which is how you actually read it.

**Parameters:**

- `pgraph` (struct) - Platformer graph
- `cfg` (struct, optional) - Debug config
- `types` (int, default: 7) - Bitmask, 1 walk, 2 fall, 4 jump
- `focus` (int, default: -1) - Platform node id to isolate, or -1 for all

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_platgraph(pgraph, cfg, 4);          // jumps only
gmnav_debug_draw_platgraph(pgraph, cfg, 7, _node);   // one ledge
```

---

### gmnav_debug_draw_agent(agent, cfg)

Agent body, radius, velocity, current target waypoint and goal. A stale path draws in red rather than yellow.

**Parameters:**

- `agent` (struct) - Agent
- `cfg` (struct, optional) - Debug config

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_agent(agent);
```

---

### gmnav_debug_draw_stats(sched, x, y)

Scheduler load panel. Draw in a Draw GUI event. If `pending` stays above zero across frames, requests are arriving faster than they are served.

**Parameters:**

- `sched` (struct) - Scheduler
- `x` (real, default: 8) - GUI x
- `y` (real, default: 8) - GUI y

**Returns:** Nothing

**Example:**

```
gmnav_debug_draw_stats(sched);
```

---

### gmnav_debug_search_text(search)

One line summary of a search, for overlaying near an agent.

**Parameters:**

- `search` (struct) - Search object

**Returns:** string

**Example:**

```
draw_text(x, y - 40, gmnav_debug_search_text(search));
```

---

## Enum Reference

### gmnav_layout

| Member | Description |
| --- | --- |
| `ORTHO` | Square or rectangular grid |
| `ISO_DIAMOND` | 2:1 diamond isometric. Same graph as `ORTHO`, drawn rotated |
| `ISO_STAGGERED` | Offset rows, neighbours depend on row parity |
| `HEX_POINTY` | Pointy top hexagons |
| `HEX_FLAT` | Flat top hexagons |

### gmnav_neighbours

| Member | Description |
| --- | --- |
| `FOUR` | Cardinal only |
| `EIGHT` | Cardinal and diagonal |
| `SIX` | Hex. Forced on hex layouts |

### gmnav_costmode

| Member | Description |
| --- | --- |
| `LOGICAL` | One grid step costs one unit, tile shape ignored |
| `VISUAL` | Step cost scales with on-screen distance |

### gmnav_heuristic

| Member | Description |
| --- | --- |
| `AUTO` | Picks the strongest admissible heuristic for the layout |
| `ZERO` | No heuristic, degrades A\* to Dijkstra. Optimal by construction, so it is the reference for optimality checks |
| `MANHATTAN` | 4-way grids |
| `OCTILE` | 8-way grids |
| `CHEBYSHEV` | Diagonal cost equal to cardinal |
| `EUCLIDEAN` | World distance divided by the shortest step. Universal fallback |
| `HEX` | True hex distance via cube coordinates |

### gmnav_state

| Member | Description |
| --- | --- |
| `IDLE` | Not started, or starved of a workspace. Retry later |
| `WORKING` | Suspended mid search |
| `FOUND` | A path is available |
| `FAILED` | Genuinely impossible. Do not retry |

### gmnav_priority

| Member | Description |
| --- | --- |
| `LOW` | Background traffic |
| `NORMAL` | Default |
| `HIGH` | Jumps the queue, still subject to the budget |
| `IMMEDIATE` | Bypasses the budget, resolves within the call. Does **not** bypass the workspace pool, so it can still fail |

### gmnav_link

| Member | Description |
| --- | --- |
| `WALK` | Along a contiguous ledge |
| `FALL` | Stepped off an edge, no jump input |
| `JUMP` | Ballistic arc from a jump input |

### gmnav_bake

| Member | Description |
| --- | --- |
| `IDLE` | Not started |
| `SURFACES` | Extracting standing positions |
| `LINKS` | Generating links |
| `DONE` | Ready to search |

### gmnav_domain

| Member | Description |
| --- | --- |
| `GRID` | Cell graph, grid A\* |
| `PLATFORM` | CSR link graph, side view A\* |

---

## Macro Reference

| Macro | Value | Description |
| --- | --- | --- |
| `GMNAV_VERSION` | "1.0.0" | Framework version string |
| `GMNAV_NO_NODE` | -1 | Returned wherever a node id is invalid |
| `GMNAV_INF` | `infinity` | Unreachable cost |
| `GMNAV_SQRT2` | 1.4142135623730951 | Diagonal step cost |
| `GMNAV_DEFAULT_BUDGET` | 2000 | Node expansions per frame, all searches combined |
| `GMNAV_HEAP_INIT` | 256 | Initial open set capacity |
| `GMNAV_MAX_STEPS` | 1000000 | Hard abort guard per search |
| `GMNAV_CLEARANCE_MAX` | 16 | Clearance flood ceiling |
| `GMNAV_PLAT_MAX_SIM` | 300 | Maximum simulated frames per arc |
| `GMNAV_PLAT_MAX_LINKS` | 24 | Maximum outgoing links kept per platform node |
| `GMNAV_DBG_MAX_CELLS` | 8000 | Cells per debug draw call before bailing out |

### Cell flags

| Macro | Bit | Description |
| --- | --- | --- |
| `GMNAV_FLAG_BLOCKED` | 0x0001 | Impassable |
| `GMNAV_FLAG_ONEWAY` | 0x0002 | One way platform, solid only from above |
| `GMNAV_FLAG_LINK` | 0x0004 | Endpoint of an off graph link |
| `GMNAV_FLAG_WATER` | 0x0008 | Free for your own use |
| `GMNAV_FLAG_DANGER` | 0x0010 | Free for your own use |
| `GMNAV_FLAG_USER0` to `USER3` | 0x1000 to 0x8000 | Reserved for the host game |

---

## Struct Reference

### Grid

| Field | Type | Description |
| --- | --- | --- |
| `domain` | enum | Always `gmnav_domain.GRID` |
| `width`, `height` | int | Dimensions in cells |
| `count` | int | `width * height` |
| `layout` | struct | Layout descriptor |
| `flags` | array | One packed integer per cell |
| `cost` | array | Base terrain cost per cell |
| `clear` | array | Clearance values, `undefined` until built |
| `clear_v` | int | Grid version the clearance was built at |
| `version` | int | Bumped on every genuine mutation |
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

### Search

| Field | Type | Description |
| --- | --- | --- |
| `state` | enum | `gmnav_state` member |
| `start`, `goal` | int | Node ids |
| `h_mode` | enum | Resolved heuristic |
| `corner_cut` | bool | Whether diagonal squeezes are allowed |
| `profile` | struct | Cost profile, or `undefined` |
| `need_clear` | int | Minimum clearance required |
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
| `path` | array | Node ids, empty unless found |
| `links` | array | `gmnav_link` values, platformer domain only |
| `stale` | bool | Grid changed while this request was in flight |
| `cancelled` | bool | Abandoned by the caller |

### Path

| Field | Type | Description |
| --- | --- | --- |
| `nodes` | array | Node ids. Cleared by `gmnav_path_simplify` |
| `px`, `py` | array | World coordinates per waypoint |
| `count` | int | Waypoint count |
| `length` | real | Total world length |
| `stale` | bool | Copied from the search that produced it |

### Agent

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `x`, `y` | real | - | Position. Yours to write, the agent never touches it |
| `vx`, `vy` | real | 0 | Proposed velocity. Written every update |
| `radius` | real | 8 | Used for avoidance and arrival |
| `speed` | real | 2 | Maximum speed |
| `accel` | real | 0.35 | How fast desired velocity is approached, 0 to 1 |
| `arrive_dist` | real | 24 | Start easing off inside this range |
| `reach_dist` | real | 4 | Close enough, journey complete |
| `arrived` | bool | false | Latched until the next `goto` or `stop` |
| `profile` | struct | `undefined` | Cost profile, passed on every request |
| `need_clear` | int | 0 | Minimum clearance, passed on every request |
| `repath_gap` | int | 20 | Frames between repath attempts |
| `avoid_str` | real | 1.0 | Separation strength, 0 disables |
| `avoid_range` | real | 3.0 | Separation reach, in multiples of radius |
| `seek_i` | int | 1 | Index of the waypoint being steered toward |

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
| `node_x`, `node_y` | array | World position per platform node |
| `max_step` | real | Longest possible single frame displacement |
| `phase` | enum | `gmnav_bake` member |

### Flow field

| Field | Type | Description |
| --- | --- | --- |
| `dist` | array | Cost to the nearest goal per cell |
| `dirx`, `diry` | array | Normalised direction per cell |
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

These are all deliberate, all verified by the test suite, and all likely to surprise you at least once.

### A single blocked row does not seal an ISO_STAGGERED map

In staggered isometric, rows two apart are exactly one tile apart vertically, so they are screen-cardinal neighbours and the table carries steps of `(0, +2)` and `(0, -2)`. A wall one row deep leaves every vertical connection intact and agents hop straight over it.

Wall two consecutive rows. On `ORTHO` the same single row seals normally.

### A suspended search can return a path through a wall

Cells a search has already settled carry costs and parent links committed under the old world, and settled cells are never revisited. If terrain changes on ground the search already crossed, that change is never noticed.

The contract is **termination plus the stale flag**, not path validity. Check `ticket.stale` before acting on a result. The agent layer already does.

GMNav deliberately does not restart searches that notice the version moved, because in a game where terrain changes every second such a search would never complete.

### Clearance is relaxed near the start

An agent standing somewhere too tight for it would otherwise be stuck forever, since every neighbouring cell is equally tight. GMNav ignores the clearance requirement for the first `search.relax` steps, default 2.

The cost is that a wide agent visibly clips geometry for those first steps. Set `relax = 0` to fail instead.

### Fall links are duplicated along ledge edges

A fall's internal walk phase moves at `run_speed`, the same as a walk edge, so "walk one tile then fall" and "fall from one tile earlier" tie exactly. Every node within two tiles of a ledge generates a tied fall link. Harmless, but it explains fall counts looking higher than expected.

### Flat ground ties exactly between walking and jumping

Horizontal speed is the same on the ground and in the air, so hopping across level terrain costs precisely what walking costs. `jump_bias`, default 1.15, breaks the tie toward walking. At 1.0 the AI bunny hops, which is arithmetically correct and looks absurd.

### Terrain cost cannot go below 1

`gmnav_grid_set_cost` clamps, and so does profile baking. A step cheaper than the heuristic assumes would silently break A\*'s optimality guarantee. To make roads fast, raise the cost of everything else.

### Smoothing refuses to run on some layouts

On `ISO_STAGGERED` and hex, cell adjacency and screen geometry have come apart, so a line of sight test in cell space says nothing reliable about the world. `gmnav_path_smooth` returns without doing anything rather than returning a confidently wrong answer. `gmnav_path_simplify` works everywhere.

### IMMEDIATE is not a guarantee

It bypasses the frame budget, not the workspace pool. With every workspace busy it falls back into the queue and resolves later. Check `ticket.state` rather than assuming a path arrived.

---

## Internal Functions

Functions prefixed `__gmnav_` are internal and may change without notice.

`gmnav_heap_*` is the binary min-heap backing every search. It is unprefixed for historical reasons but is not part of the public surface.
