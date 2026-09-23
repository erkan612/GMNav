# GMNav Documentation

If you are new to the framework, read [Getting Started](GettingStarted.md)
first. This document assumes you know roughly what a grid, a scheduler and an
agent are, and answers questions about specific calls.

---

## What do I want to do?

Most questions about a navigation framework are task shaped rather than
function shaped. Start here and follow the links.

### Getting something to move

| I want to | Look at |
|---|---|
| Set the framework up | `gmnav_init` |
| Describe how my tiles are shaped | `gmnav_layout_create` |
| Build a map of where units can walk | `gmnav_grid_create`, `gmnav_grid_import_tilemap` |
| Mark walls by hand | `gmnav_grid_set_blocked`, `gmnav_grid_fill_blocked` |
| Get paths without stalling my game | `gmnav_scheduler_create`, `gmnav_scheduler_update` |
| Send a unit somewhere | `gmnav_agent_create`, `gmnav_agent_goto` |
| Know when it got there, or could not | `gmnav_agent_arrived`, `gmnav_agent_failed` |

### Making routes look sensible

| I want to | Look at |
|---|---|
| Remove the staircase shape from a path | `gmnav_path_smooth` |
| Keep a unit to four or eight directions | `gmnav_path_smooth` with `headings` |
| Round the corners for something with momentum | `gmnav_path_curve` |
| Stop a unit snapping backwards when it starts | `gmnav_path_anchor_start` |

### Making units behave differently from each other

| I want to | Look at |
|---|---|
| Make some ground expensive rather than solid | `gmnav_grid_set_cost` |
| Mark danger that only some units care about | `gmnav_costlayer_create`, `gmnav_costprofile_add` |
| Paint danger in a blob or along a route | `gmnav_costlayer_stamp_radial`, `gmnav_costlayer_stamp_path` |
| Move that danger every frame affordably | `gmnav_costlayer_clear_region`, `gmnav_costprofile_bake_region` |
| Stop a big unit using a small doorway | `gmnav_clearance_build`, `gmnav_clearance_for_radius` |

### Crowds

| I want to | Look at |
|---|---|
| Send hundreds of units to one place | `gmnav_flowfield_create`, `gmnav_flowfield_build` |
| Send everyone to their own nearest exit | `gmnav_flowfield_build` with several goals |
| Ask how far a unit really is from something | `gmnav_flowfield_cost_at` |
| Stop units standing inside each other | `gmnav_agent_update` with a neighbour list |

### Ground that is not flat

| I want to | Look at |
|---|---|
| Make a cliff that can be jumped down but not climbed | `gmnav_grid_set_height`, and `max_climb` on a request |
| Build a bridge over a road | `gmnav_overlay_create`, `gmnav_overlay_link` |
| Make a slope rather than a step | `gmnav_overlay_ramp` |
| Work out which surface the player clicked | `gmnav_grid_world_to_node_top` |

### Side view games

| I want to | Look at |
|---|---|
| Work out which ledges connect | `gmnav_movement_create`, `gmnav_platgraph_bake` |
| Find out how to reach the next ledge | `gmnav_platgraph_link_get` |
| Let the framework do the jumping | `gmnav_platagent_create` |

### When something is wrong

| The symptom | The view |
|---|---|
| A route exists but the unit refuses it | `gmnav_debug_draw_reach` |
| A big unit refuses a passable looking gap | `gmnav_debug_draw_clearance` |
| A unit takes a strange but legal route | `gmnav_debug_draw_costs` |
| Units walk into walls following a field | `gmnav_debug_draw_flowfield` |
| Paths arrive late | `gmnav_debug_draw_stats` |
| A unit stutters or orbits | `gmnav_debug_draw_agent` |

---

## Layout Functions

A layout describes the shape of your tiles and which cells count as neighbours.
It is the only part of GMNav that knows about pixels.

This matters more than it sounds. The search itself walks `(col, row)` pairs and
asks the layout what connects to what, so isometric and hexagonal maps are not a
separate navigation system, they are a different layout handed to the same
search.

---

### gmnav_layout_create

**Syntax:**

```gml
gmnav_layout_create(mode, tile_w, tile_h, neighbours, cost_mode, origin_x, origin_y);
```

| Argument | Type | Description |
|---|---|---|
| mode | Enum | A `gmnav_layout` member, the projection |
| tile_w | Real | Tile width in pixels |
| tile_h | Real | Tile height in pixels |
| neighbours | Enum | Optional, default `gmnav_neighbours.EIGHT` |
| cost_mode | Enum | Optional, default `gmnav_costmode.LOGICAL` |
| origin_x | Real | Optional, default 0. World x of cell (0,0) |
| origin_y | Real | Optional, default 0. World y of cell (0,0) |

**Returns:** Struct

**Example:**

```gml
// a plain top down map on 32 pixel tiles
layout = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32);

// the same map, but units may only face four ways
layout = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32, gmnav_neighbours.FOUR);

// a classic 2:1 isometric map, offset so cell (0,0) sits at 200,200
layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32,
                             gmnav_neighbours.EIGHT,
                             gmnav_costmode.LOGICAL, 200, 200);
```

The above code builds three different layouts, any of which can be handed to
`gmnav_grid_create`. Everything downstream, costs, clearance, flow fields and
agents, works identically regardless of which one you chose.

The `tile_w` and `tile_h` arguments are the tile's bounding box, not its drawn
sprite. For an isometric diamond drawn 64 wide and 32 tall, pass 64 and 32 even
though the diamond's points touch only the middle of each edge.

`neighbours` decides which steps exist. `EIGHT` is the default and allows
diagonals. `FOUR` gives cardinal movement only, which suits grid locked tactics
games and anything with four directional sprites, and the heuristic switches
from octile to Manhattan automatically so it stays honest. `SIX` is for hex
layouts and should always be used with them.

`cost_mode` only has an effect on `ORTHO` and `ISO_DIAMOND`, and only matters
when your tiles are not square. `LOGICAL` counts moves, so every cardinal step
costs 1 and every diagonal 1.4142 regardless of tile shape, which is what a turn
based game wants. `VISUAL` counts pixels, so a step's cost reflects the distance
actually covered on screen, which is what a real time game wants. Staggered and
hex layouts always measure geometrically, because their offset coordinates are
not a metric space and logical counting there would be meaningless rather than
merely different.

`origin_x` and `origin_y` shift the whole grid in world space. Use them when
your map does not start at the top left of the room, for instance to leave space
for a HUD.

**Note:** a layout is immutable once created. If you need to change tile size or
neighbour count, build a new layout and a new grid.

**See also:** `gmnav_grid_create`, `gmnav_layout_cell_to_world`,
`gmnav_layout_world_to_cell`

---

### gmnav_layout_cell_to_world

**Syntax:**

```gml
gmnav_layout_cell_to_world(layout, col, row);
```

| Argument | Type | Description |
|---|---|---|
| layout | Struct | The layout |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Array, `[x, y]`

**Example:**

```gml
// draw a marker on every cell of the top row
for (var _c = 0; _c < grid.width; _c++) {
    var _p = gmnav_layout_cell_to_world(layout, _c, 0);
    draw_circle(_p[0], _p[1], 3, false);
}
```

The above code walks a row of cells and draws at the centre of each. The
returned position is always the centre of the cell, whatever the projection, so
on a hex layout you get the middle of the hexagon rather than a corner.

This function does not know about elevation or layers, because a layout does not
know about them either. For a node that might be raised, use
`gmnav_grid_node_to_world` instead, which applies the layer lift and any
per-cell offset before returning.

Bounds are not checked. Passing a column outside the grid returns the position
that cell would occupy if it existed, which is occasionally useful and
occasionally a bug.

**See also:** `gmnav_layout_world_to_cell`, `gmnav_grid_node_to_world`

---

### gmnav_layout_world_to_cell

**Syntax:**

```gml
gmnav_layout_world_to_cell(layout, x, y);
```

| Argument | Type | Description |
|---|---|---|
| layout | Struct | The layout |
| x | Real | World x |
| y | Real | World y |

**Returns:** Array, `[col, row]`

**Example:**

```gml
var _cr = gmnav_layout_world_to_cell(layout, mouse_x, mouse_y);

if (gmnav_grid_in_bounds(grid, _cr[0], _cr[1])) {
    show_debug_message("mouse is over cell "
        + string(_cr[0]) + ", " + string(_cr[1]));
}
```

The above code converts the mouse position into a column and row, then checks
whether that cell actually exists before using it. The conversion itself has no
idea how big your grid is, so it will happily return negative values or
coordinates past the far edge, which is why the bounds check is there.

How the conversion works differs by projection, and the differences are worth
knowing because they explain the accuracy you can expect. Orthogonal is a
division. Diamond isometric solves two linear equations, which is exact. Hex
converts to axial coordinates, rounds in cube space where the three axes must
sum to zero, and converts back, because rounding axial coordinates directly
picks the wrong cell near hex edges. Staggered isometric has no clean inverse at
all, so GMNav takes an approximate cell, checks its true neighbours, and keeps
whichever centre is genuinely nearest.

**Tip:** a useful sanity check for your own project is to convert every cell to
world and straight back. If any cell does not round trip, your tile dimensions
or origin are wrong, and everything downstream will be subtly off.

For picking a cell that a unit could actually stand on, prefer
`gmnav_grid_world_to_node`, which returns a node id and handles layers.

**See also:** `gmnav_layout_cell_to_world`, `gmnav_grid_world_to_node`,
`gmnav_grid_world_to_node_top`

---

### gmnav_layout_cell_x

**Syntax:**

```gml
gmnav_layout_cell_x(layout, col, row);
```

| Argument | Type | Description |
|---|---|---|
| layout | Struct | The layout |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Real

**Example:**

```gml
// a cheaper inner loop than calling cell_to_world and reading [0]
for (var _r = 0; _r < grid.height; _r++) {
    for (var _c = 0; _c < grid.width; _c++) {
        var _x = gmnav_layout_cell_x(layout, _c, _r);
        var _y = gmnav_layout_cell_y(layout, _c, _r);

        draw_sprite(spr_tile, 0, _x, _y);
    }
}
```

The above code draws a sprite on every cell. This function and
`gmnav_layout_cell_y` return the same values `gmnav_layout_cell_to_world` does,
one at a time, which avoids allocating an array per cell.

On a map of any size that matters. A 200 by 200 grid drawn every frame is 40,000
array allocations if you use `cell_to_world`, and none if you use these.

Note that the row still affects the x position on isometric and staggered
layouts, which is why both arguments are required even though you are only
asking for one coordinate.

**See also:** `gmnav_layout_cell_y`, `gmnav_layout_cell_to_world`

---

### gmnav_layout_cell_y

**Syntax:**

```gml
gmnav_layout_cell_y(layout, col, row);
```

| Argument | Type | Description |
|---|---|---|
| layout | Struct | The layout |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Real

**Example:**

```gml
// sort instances by the row they stand on, for a painter's algorithm
with (obj_unit) {
    var _cr = gmnav_layout_world_to_cell(other.layout, x, y);
    depth   = -gmnav_layout_cell_y(other.layout, _cr[0], _cr[1]);
}
```

The above code gives every unit a depth based on the y position of the cell it
occupies, which is the usual way to make units in front draw over units behind
on an isometric map.

The column affects the y position on isometric and staggered layouts, so both
arguments are required.

**See also:** `gmnav_layout_cell_x`, `gmnav_layout_cell_to_world`

---

### gmnav_layout_cell_parity

**Syntax:**

```gml
gmnav_layout_cell_parity(layout, col, row);
```

| Argument | Type | Description |
|---|---|---|
| layout | Struct | The layout |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Integer, 0 or 1

**Example:**

```gml
// stagger a decoration so it lines up with the offset rows
var _p = gmnav_layout_cell_parity(layout, _c, _r);
var _x = gmnav_layout_cell_x(layout, _c, _r);

draw_sprite(spr_grass, _p, _x, gmnav_layout_cell_y(layout, _c, _r));
```

The above code picks one of two sprite frames depending on whether a cell sits
on an odd or even offset row.

On layouts where rows or columns are offset from each other, staggered isometric
and both hex orientations, which cells count as neighbours depends on whether
the row or column is odd or even. This function tells you which case a given
cell falls into. On orthogonal and diamond isometric there is no offset, so it
always returns 0.

You rarely need this directly, since the search handles parity itself. It is
here for code that walks neighbours by hand, and for drawing code that needs to
match the offset pattern.

**See also:** `gmnav_parity`

---

### gmnav_parity

**Syntax:**

```gml
gmnav_parity(value);
```

| Argument | Type | Description |
|---|---|---|
| value | Integer | Any integer, positive or negative |

**Returns:** Integer, 0 or 1

**Example:**

```gml
gmnav_parity(4);    // 0
gmnav_parity(5);    // 1
gmnav_parity(-3);   // 1, where -3 % 2 would give you -1
```

The above shows why this exists rather than using the modulo operator directly.
GML's `%` keeps the sign of the left operand, so a negative coordinate produces
a negative result and any code branching on it takes the wrong path.

Grid coordinates are rarely negative, but neighbour offsets are, and a cell on
the edge of the map can produce one during a neighbour scan. This function
always returns 0 or 1.

**See also:** `gmnav_layout_cell_parity`

---

## Grid Functions

A grid is the map. It holds one flag set and one cost value per cell, and it
lends out the workspaces searches run in.

Grid functions divide into three groups: making one and finding your way around
it, changing it, and the extras for elevation and stacked surfaces. This part
covers the first group.

Throughout, a **node** is an integer identifying one cell. For base grid cells
it is `row * width + col`. Cells belonging to an overlay are numbered past
`grid.count`, and most functions here accept either.

---

### gmnav_grid_create

**Syntax:**

```gml
gmnav_grid_create(width, height, layout, slots);
```

| Argument | Type | Description |
|---|---|---|
| width | Integer | Grid width in cells |
| height | Integer | Grid height in cells |
| layout | Struct | A layout from `gmnav_layout_create` |
| slots | Integer | Optional, default 4. Search workspaces to lend out |

**Returns:** Struct

**Example:**

```gml
// Create event
gmnav_init();

tile   = 32;
layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);

gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Collision"));
```

The above code builds a grid sized to the room and fills it from a collision
tilemap. Every cell starts unblocked with a cost of 1, so a grid you never touch
is an open field.

The `slots` argument is the number of searches that can be in flight over this
grid at once. Each one needs its own workspace, which is several arrays sized to
your cell count, so on a 500 by 500 map four workspaces is around 24 megabytes
and forty would be 240 for no benefit at all, since they would all be sharing
the same per-frame budget anyway. Four is a sensible default and the scheduler
caps its own concurrency at whatever the grid can supply.

Running four at a time rather than one is worth it for a reason that is not
obvious: a search that finishes early hands its unused budget to the next one in
the same frame. With one search at a time, a request needing thirty expansions
would waste the rest of the allowance.

**Note:** call `gmnav_init` before this, or anything that reads a config value
will fail. Once per game is enough.

**See also:** `gmnav_init`, `gmnav_layout_create`, `gmnav_scheduler_create`

---

### gmnav_grid_in_bounds

**Syntax:**

```gml
gmnav_grid_in_bounds(grid, col, row);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Boolean

**Example:**

```gml
// look at the eight cells around a unit, without falling off the map
var _cr = gmnav_layout_world_to_cell(layout, x, y);

for (var _dy = -1; _dy <= 1; _dy++) {
    for (var _dx = -1; _dx <= 1; _dx++) {
        var _c = _cr[0] + _dx;
        var _r = _cr[1] + _dy;

        if (!gmnav_grid_in_bounds(grid, _c, _r)) continue;

        // safe to use _c and _r now
    }
}
```

The above code scans a three by three block around a unit and skips anything
outside the map.

You mostly need this when you are working in columns and rows rather than nodes.
If you are about to call `gmnav_grid_node` anyway, that already returns
`GMNAV_NO_NODE` for out of bounds coordinates, so checking twice is wasted work.

**See also:** `gmnav_grid_node`

---

### gmnav_grid_node

**Syntax:**

```gml
gmnav_grid_node(grid, col, row);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Integer, or `GMNAV_NO_NODE`

**Example:**

```gml
var _goal = gmnav_grid_node(grid, 12, 8);

if (_goal != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _goal)) {
    ticket = gmnav_scheduler_request(sched, my_node, _goal);
} else {
    show_debug_message("that cell is not somewhere you can stand");
}
```

The above code turns a column and row into the node id every search function
expects, then checks two separate things before using it: that the cell exists,
and that it is not solid.

Both checks matter, and they fail differently. An out of bounds cell returns
`GMNAV_NO_NODE`, which is -1, and passing that to the scheduler is safe but the
request simply fails. A cell that exists but is blocked returns a real node id,
and the request also fails, but for a reason you might want to tell the player
about.

A node for a base cell is `row * width + col` and you can compute it yourself.
Using this function means the bounds check happens for you. Node ids belonging
to an overlay cannot be computed this way, since they are not laid out
arithmetically; use `gmnav_overlay_node_at` for those.

**See also:** `gmnav_grid_col`, `gmnav_grid_row`, `gmnav_grid_world_to_node`,
`gmnav_overlay_node_at`

---

### gmnav_grid_col

**Syntax:**

```gml
gmnav_grid_col(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Integer, or -1 if the node is invalid

**Example:**

```gml
// print a path in a form you can read
var _out = "";

for (var _i = 0; _i < array_length(path); _i++) {
    _out += "(" + string(gmnav_grid_col(grid, path[_i]))
          + "," + string(gmnav_grid_row(grid, path[_i])) + ") ";
}

show_debug_message(_out);
```

The above code turns an array of node ids into readable coordinates, which is
the first thing you will want when a path is doing something unexpected.

This resolves overlay nodes as well as base cells, so a path that crosses a
bridge prints sensibly rather than producing nonsense for the raised cells. Note
that an overlay cell shares its column and row with whatever sits beneath it, so
coordinates alone do not tell you which surface a node is on. Use
`gmnav_grid_node_layer` for that.

**See also:** `gmnav_grid_row`, `gmnav_grid_node_layer`, `gmnav_grid_node`

---

### gmnav_grid_row

**Syntax:**

```gml
gmnav_grid_row(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Integer, or -1 if the node is invalid

**Example:**

```gml
// does this path ever enter the southern half of the map?
var _south = false;

for (var _i = 0; _i < array_length(path); _i++) {
    if (gmnav_grid_row(grid, path[_i]) > grid.height div 2) {
        _south = true;
        break;
    }
}
```

The above code inspects a path by region, which is the kind of question you ask
when deciding whether a unit is about to wander somewhere it should not.

Like `gmnav_grid_col`, this resolves overlay nodes too.

**See also:** `gmnav_grid_col`, `gmnav_grid_node`

---

### gmnav_grid_node_layer

**Syntax:**

```gml
gmnav_grid_node_layer(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id |

**Returns:** Integer, 0 for base cells, or -1 if the node is invalid

**Example:**

```gml
// play a different footstep sound on a wooden bridge
var _n = gmnav_grid_world_to_node(grid, x, y, my_layer);

if (gmnav_grid_node_layer(grid, _n) > 0) {
    audio_play_sound(snd_step_wood, 1, false);
} else {
    audio_play_sound(snd_step_stone, 1, false);
}
```

The above code asks which surface a unit is standing on and reacts to it.

Layer 0 is always the base grid. Anything above that is an overlay cell, and the
number is the layer index you passed to `gmnav_overlay_add` when you created it.
On a map with no overlay every node returns 0.

This is also how you detect that a step crosses surfaces, which matters when
following a flow field: comparing the layer of your current node against the
layer of `gmnav_flowfield_next` tells you a transition is about to happen, which
a direction vector alone cannot express.

**See also:** `gmnav_overlay_layer`, `gmnav_flowfield_next`,
`gmnav_agent_layer`

---

### gmnav_grid_world_to_node

**Syntax:**

```gml
gmnav_grid_world_to_node(grid, x, y, layer);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| x | Real | World x |
| y | Real | World y |
| layer | Integer | Optional, default 0. Which surface to ask about |

**Returns:** Integer, or `GMNAV_NO_NODE`

**Example:**

```gml
// the player clicked. Which surface did they mean?
var _road = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 0);
var _deck = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 1);

if (send_to_bridge && _deck != GMNAV_NO_NODE) {
    gmnav_agent_goto(agent, mouse_x, mouse_y, gmnav_priority.NORMAL, 1);
} else if (_road != GMNAV_NO_NODE) {
    gmnav_agent_goto(agent, mouse_x, mouse_y);
}
```

The above code resolves the same screen position on two different surfaces and
lets the game decide which one the player meant.

That decision cannot be made here, which is why the layer is an argument rather
than something the function works out. A point over a bridge genuinely has more
than one answer, and which is correct depends on your camera, your controls and
what the player was looking at. GMNav owns none of those.

Layer 0 resolves geometrically and always returns something if the position is
inside the grid. A layer above 0 searches the overlay cells drawn at that
position, accounting for the layer lift and each cell's own offset, and returns
`GMNAV_NO_NODE` if that surface has no cell there.

If you just want whatever is visible, use `gmnav_grid_world_to_node_top`.

**See also:** `gmnav_grid_world_to_node_top`, `gmnav_grid_node_to_world`,
`gmnav_agent_goto`

---

### gmnav_grid_world_to_node_top

**Syntax:**

```gml
gmnav_grid_world_to_node_top(grid, x, y);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| x | Real | World x |
| y | Real | World y |

**Returns:** Integer, or `GMNAV_NO_NODE`

**Example:**

```gml
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        var _p = gmnav_grid_node_to_world(grid, _n);

        gmnav_agent_goto(agent, _p[0], _p[1], gmnav_priority.NORMAL,
                         gmnav_grid_node_layer(grid, _n));
    }
}
```

The above code is the standard click to move handler for a map with raised
surfaces. It finds the topmost thing under the cursor, checks it is walkable,
and sends the agent there on the correct layer.

The function walks down from the highest layer in the overlay and returns the
first cell it finds, falling back to the base grid. That is usually what
"click on the thing you can see" means, since a bridge drawn over a road is the
thing the player is looking at.

Note the example passes the layer to `gmnav_agent_goto` as well as the position.
Without it the agent would resolve the destination at ground level and walk
under the bridge instead of onto it.

**See also:** `gmnav_grid_world_to_node`, `gmnav_grid_node_layer`

---

### gmnav_grid_node_to_world

**Syntax:**

```gml
gmnav_grid_node_to_world(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Array, `[x, y]`

**Example:**

```gml
// draw a path, including the parts that climb a bridge
for (var _i = 0; _i < array_length(path) - 1; _i++) {
    var _a = gmnav_grid_node_to_world(grid, path[_i]);
    var _b = gmnav_grid_node_to_world(grid, path[_i + 1]);

    draw_line(_a[0], _a[1], _b[0], _b[1]);
}
```

The above code draws a route by converting each node to a position.

The important difference from `gmnav_layout_cell_to_world` is that this applies
the layer lift and any per-cell offset, so a node on a raised surface reports
where it is actually drawn rather than where its column and row would put it.
Using the layout function instead is the usual cause of a path that draws
flattened against the ground while the bridge floats above it.

Invalid nodes return `[0, 0]` rather than failing, so check your node if you get
a line to the top left corner of the room.

**See also:** `gmnav_layout_cell_to_world`, `gmnav_grid_world_to_node`

---

### gmnav_grid_is_blocked

**Syntax:**

```gml
gmnav_grid_is_blocked(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Boolean

**Example:**

```gml
// is any part of this path now solid?
var _bad = 0;

for (var _i = 0; _i < array_length(path); _i++) {
    if (gmnav_grid_is_blocked(grid, path[_i])) _bad++;
}

if (_bad > 0) {
    show_debug_message(string(_bad) + " cells on this route are now walls");
}
```

The above code checks whether a path the unit is following has been invalidated
by something that changed. It is worth knowing that a path which was correct
when produced can become wrong later, and that GMNav will not repair it behind
your back unless you are using the agent layer.

This returns `true` for anything invalid, including `GMNAV_NO_NODE`, which makes
it safe to chain after a lookup that might have failed.

**Careful:** a free cell is not a free position. This asks about a cell, and a
unit with a radius needs somewhere its whole body fits. A point two pixels from
a wall sits in a perfectly open cell. That is what clearance is for.

**See also:** `gmnav_grid_set_blocked`, `gmnav_clearance_at`

---

### gmnav_grid_cost

**Syntax:**

```gml
gmnav_grid_cost(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Real, 1 or greater

**Example:**

```gml
// how expensive is the ground under this unit?
var _n = gmnav_grid_world_to_node(grid, x, y);
var _c = gmnav_grid_cost(grid, _n);

if (_c > 1) {
    // slow the unit down to match what the pathfinder thinks it costs
    move_speed = base_speed / _c;
}
```

The above code reads the terrain cost of a cell and uses it for something other
than pathfinding, which is a good habit: if your search thinks mud is three
times as expensive and your movement code lets units sprint through it, the
paths will look wrong to the player even though they are optimal.

This is the **base** cost only, what you set with `gmnav_grid_set_cost`. It does
not include anything from a cost layer or profile. For the cost a particular
unit type actually pays, read `profile.resolved[node]` after baking.

Overlay cells carry their own cost independent of the ground beneath them, and
this returns that.

**See also:** `gmnav_grid_set_cost`, `gmnav_grid_get_cost`,
`gmnav_costprofile_bake`

---

### gmnav_grid_get_cost

**Syntax:**

```gml
gmnav_grid_get_cost(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Base node id only |

**Returns:** Real

**Example:**

```gml
// sum the base cost of a route, base cells only
var _total = 0;

for (var _i = 0; _i < array_length(path); _i++) {
    if (path[_i] >= grid.count) continue;   // skip overlay nodes

    _total += gmnav_grid_get_cost(grid, path[_i]);
}
```

The above code totals terrain cost while skipping anything raised.

This is the same as `gmnav_grid_cost` without the overlay handling, so it is
slightly cheaper when you already know the node is a base cell. Passing an
overlay node reads past the end of the cost array, so only use it when you have
checked, as the example does.

In practice `gmnav_grid_cost` is the one to reach for. This exists for inner
loops where the check is wasted work.

**See also:** `gmnav_grid_cost`

---

### gmnav_grid_has_flag

**Syntax:**

```gml
gmnav_grid_has_flag(grid, node, flag);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Base node id |
| flag | Integer | A flag constant |

**Returns:** Boolean

**Example:**

```gml
// is the character standing on a platform it can drop through?
var _n = gmnav_grid_world_to_node(grid, x, y + 1);

if (gmnav_grid_has_flag(grid, _n, GMNAV_FLAG_ONEWAY)) {
    can_drop_through = true;
}
```

The above code checks for a one way platform beneath a character, which is the
sort of thing a side view controller needs every frame.

Flags are a bitmask, so several can be set on one cell. GMNav defines
`GMNAV_FLAG_BLOCKED` and `GMNAV_FLAG_ONEWAY`, and the remaining bits are yours
to use for whatever your game needs, since nothing in the framework reads them.

Base cells only. Overlay cells have their own flags, reachable through
`gmnav_overlay_is_blocked`.

**See also:** `gmnav_grid_set_flag`, `gmnav_grid_is_blocked`

---

## Grid Functions, continued

This part covers changing a grid after it exists, filling one from data you
already have, and asking what changed recently.

Every function here that genuinely alters something bumps the grid's version and
records what it touched. Functions that are handed a value identical to the one
already there do neither, which matters more than it sounds: a door object that
re-asserts its own state every step is a completely normal thing to write, and
if every assertion counted as a change then every search in your game would be
permanently out of date and every agent would repath forever.

---

### gmnav_grid_set_blocked

**Syntax:**

```gml
gmnav_grid_set_blocked(grid, col, row, blocked);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |
| blocked | Boolean | New state |

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```gml
// a door that opens and closes
function door_set(_grid, _col, _row, _open) {
    var _before = _grid.version;

    gmnav_grid_set_blocked(_grid, _col, _row, !_open);

    return (_grid.version != _before);   // did anything actually change?
}
```

The above code wraps the call in something a door object can run every step
without consequence. If the door is already in the state you asked for, the
version does not move, nothing is marked out of date, and no agent repaths.
Returning whether anything changed lets the caller play a sound or start an
animation only on the frames it matters.

That pattern is worth adopting for anything that describes its own state
continuously rather than announcing changes.

**Tip:** for something that is usually passable, consider making it expensive
instead of solid with `gmnav_grid_set_cost`. An expensive door routes units
around it when there is a reasonable alternative and through it when there is
not, and unlike a blocked one it can never make a destination unreachable.

**See also:** `gmnav_grid_fill_blocked`, `gmnav_grid_is_blocked`,
`gmnav_grid_set_cost`

---

### gmnav_grid_set_cost

**Syntax:**

```gml
gmnav_grid_set_cost(grid, col, row, cost);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |
| cost | Real | Multiplier for entering this cell, clamped to 1 or more |

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```gml
// a band of swamp four rows deep
for (var _r = 6; _r <= 9; _r++) {
    for (var _c = 1; _c < grid.width - 1; _c++) {
        gmnav_grid_set_cost(grid, _c, _r, 8);
    }
}
```

The above code makes a region expensive without making it impassable, which is
the single most useful thing in this whole document. Units will cross the swamp
if the alternative is long enough and walk round it if it is not, and you did
not write any logic to make that happen.

Two things about the value. It is a multiplier on entering the cell, not on
leaving it, so walking out of swamp is free. And it is clamped to a minimum of
1, which is not a limitation but a guarantee: the heuristic assumes every step
costs at least 1, and a cheaper cell would make the estimate an overestimate,
which quietly breaks A\*'s optimality and gives you worse routes with no error
anywhere.

So to make roads fast, do not set the road below 1. Set everything else above
it:

```gml
// wrong, silently clamped back to 1
gmnav_grid_set_cost(grid, _road_c, _road_r, 0.5);

// right, roads stay at 1 and grass gets dearer
gmnav_grid_set_cost(grid, _grass_c, _grass_r, 2);
```

Cheapest thing is 1 is a habit worth adopting from the start, because
retrofitting it into a finished map is tedious.

**See also:** `gmnav_grid_cost`, `gmnav_costlayer_create`

---

### gmnav_grid_set_flag

**Syntax:**

```gml
gmnav_grid_set_flag(grid, col, row, flag, on);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |
| flag | Integer | A flag constant |
| on | Boolean | Whether to set or clear it |

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```gml
// mark the wooden platforms in a side view level as one way
for (var _c = 4; _c <= 12; _c++) {
    gmnav_grid_set_flag(grid, _c, 9, GMNAV_FLAG_ONEWAY, true);
}
```

The above code marks a run of cells as a platform a character can jump up
through but not fall down through. The platformer bake reads this when
simulating arcs, so links that would pass down through the platform are never
generated.

Flags are a bitmask and several can be set at once. `GMNAV_FLAG_BLOCKED` and
`GMNAV_FLAG_ONEWAY` are the two GMNav uses; the remaining bits are yours. If you
want to tag cells as "indoors" or "faction territory" for your own code, this is
a reasonable place to keep it, since nothing in the framework will touch bits it
does not own.

Setting `GMNAV_FLAG_BLOCKED` through this function works, but
`gmnav_grid_set_blocked` is clearer and does the same job.

**See also:** `gmnav_grid_has_flag`, `gmnav_grid_set_blocked`

---

### gmnav_grid_fill_blocked

**Syntax:**

```gml
gmnav_grid_fill_blocked(grid, c1, r1, c2, r2, blocked);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| c1 | Integer | One corner column |
| r1 | Integer | One corner row |
| c2 | Integer | Other corner column |
| r2 | Integer | Other corner row |
| blocked | Boolean | New state |

**Returns:** Boolean, whether anything actually changed

**Example:**

```gml
// walls around the edge of the map
gmnav_grid_fill_blocked(grid, 0, 0, grid.width - 1, 0, true);
gmnav_grid_fill_blocked(grid, 0, grid.height - 1, grid.width - 1, grid.height - 1, true);
gmnav_grid_fill_blocked(grid, 0, 0, 0, grid.height - 1, true);
gmnav_grid_fill_blocked(grid, grid.width - 1, 0, grid.width - 1, grid.height - 1, true);

// and a building in the middle
gmnav_grid_fill_blocked(grid, 10, 4, 14, 9, true);
```

The above code walls the border and drops a solid block into the map, which is
how most hand built test levels start.

The corners can be given in any order, and the rectangle is clipped to the grid,
so you do not need to bounds check first. The version is bumped **once** for the
whole rectangle rather than once per cell, and the rectangle is recorded as a
single recent edit, which keeps the edit history useful when you are filling
large areas.

The return value tells you whether any cell actually changed, which is the same
no-op discipline `gmnav_grid_set_blocked` follows. Re-filling a rectangle that
is already in the state you asked for costs the loop and nothing else.

**See also:** `gmnav_grid_set_blocked`, `gmnav_grid_changed_since`

---

### gmnav_grid_import_tilemap

**Syntax:**

```gml
gmnav_grid_import_tilemap(grid, tilemap, is_blocked);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| tilemap | Id | A tilemap element id |
| is_blocked | Function | Optional. Given a tile index, returns whether it blocks |

**Returns:** N/A

**Example:**

```gml
// anything not empty is a wall
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Collision"));

// or decide per tile index
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Tiles"),
    function(_tile) {
        return (_tile >= 16 && _tile <= 31);   // the wall tiles in my tileset
    });
```

The above code fills the grid from a tilemap two different ways. Without a
callback, any tile index other than zero counts as solid, which is right when
you have a dedicated collision layer. With one, you decide, which is right when
your visual tileset and your collision are the same layer.

The import reads as much of the tilemap as overlaps the grid, so a mismatch in
size is not an error, it just leaves the rest of the grid untouched.

Note that this sets blocked state only. Terrain cost is left alone, so you can
import collision from a tilemap and then apply costs separately without the
import wiping them.

**See also:** `gmnav_grid_import_dsgrid`, `gmnav_grid_import_callback`

---

### gmnav_grid_import_dsgrid

**Syntax:**

```gml
gmnav_grid_import_dsgrid(grid, ds_grid, is_blocked);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| ds_grid | Id | Source ds_grid |
| is_blocked | Function | Optional. Given a value, returns whether it blocks |

**Returns:** N/A

**Example:**

```gml
// a level generator that works in a ds_grid
var _map = ds_grid_create(40, 30);
generate_dungeon(_map);

gmnav_grid_import_dsgrid(grid, _map, function(_v) {
    return (_v == TILE_WALL || _v == TILE_WATER);
});

ds_grid_destroy(_map);
```

The above code takes the output of a procedural generator and turns it into a
navigation grid. This is the usual path for generated levels, since most
generators already work in a grid of integers.

Without a callback, any non-zero value counts as solid.

As with the tilemap import, only blocked state is written, and only the
overlapping region is read.

**See also:** `gmnav_grid_import_tilemap`, `gmnav_grid_import_callback`

---

### gmnav_grid_import_callback

**Syntax:**

```gml
gmnav_grid_import_callback(grid, fn);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| fn | Function | Called with `(col, row)` for every cell |

**Returns:** N/A

**Example:**

```gml
// build the grid from instances in the room, with costs
gmnav_grid_import_callback(grid, function(_c, _r) {
    var _x = _c * 32 + 16;
    var _y = _r * 32 + 16;

    if (place_meeting(_x, _y, obj_wall)) {
        return { blocked : true };
    }

    if (place_meeting(_x, _y, obj_mud)) {
        return { blocked : false, cost : 3 };
    }

    return { blocked : false, cost : 1 };
});
```

The above code fills the grid from what is actually placed in the room, setting
both blocked state and terrain cost in one pass.

Return a boolean for blocked state alone, or a struct to set more. The struct
accepts `blocked`, `cost` and `flags`, and anything you leave out keeps its
current value, except `cost`, which defaults to 1 when you return a struct at
all.

This is the slowest of the three imports, since it calls into GML once per cell,
so it belongs at level load rather than in a Step event. On a large map consider
building a ds_grid first and importing that instead.

**Careful:** `place_meeting` uses the calling instance's collision mask, so
inside a method the results depend on which object is running it. If the grid
looks wrong in a way that follows your controller object around, that is why.

**See also:** `gmnav_grid_import_tilemap`, `gmnav_grid_import_dsgrid`

---

### gmnav_grid_changed_since

**Syntax:**

```gml
gmnav_grid_changed_since(grid, version, c1, r1, c2, r2);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| version | Integer | The version the caller last checked at |
| c1 | Integer | One corner column |
| r1 | Integer | One corner row |
| c2 | Integer | Other corner column |
| r2 | Integer | Other corner row |

**Returns:** Boolean

**Example:**

```gml
// only repath if a change landed on the part of the route still to walk
var _relevant = false;

for (var _i = seek_index; _i < array_length(path) - 1; _i++) {
    var _ac = gmnav_grid_col(grid, path[_i]);
    var _ar = gmnav_grid_row(grid, path[_i]);
    var _bc = gmnav_grid_col(grid, path[_i + 1]);
    var _br = gmnav_grid_row(grid, path[_i + 1]);

    if (gmnav_grid_changed_since(grid, my_version,
            min(_ac, _bc), min(_ar, _br),
            max(_ac, _bc), max(_ar, _br))) {
        _relevant = true;
        break;
    }
}

if (_relevant) request_new_path();
else          my_version = grid.version;
```

The above code is what the agent layer does internally, written out so you can
do the same in your own agent class. It tests the bounding box of each remaining
leg of the route against the edits that have happened since it last looked.

Why this exists is worth understanding. The grid version is a single integer for
the whole map, so it tells you something changed but not where. On a map where
changes are rare that is fine. On a tower defense where the player places a wall
every second, every agent sees the version move, every agent asks for a new
path, and you get two hundred requests for one wall that most of them were
nowhere near. The scheduler holds your frame rate while that happens, so it does
not look like a performance problem, it looks like every path arriving late
forever.

Note the `else` branch. Moving your stamp forward when nothing concerned you is
what makes the check cheap: the next frame's test is a single integer comparison
until something else changes.

The grid keeps a limited ring of recent rectangles. If your version is older
than anything still held, the history you needed has been overwritten and the
function returns `true`, which degrades to the old behaviour of repathing on any
change rather than to silently missing one. The ring size is the `EDIT_RING`
config setting.

**See also:** `gmnav_init`, `gmnav_agent_update`

---

## Grid Functions, elevation and workspaces

The last of the grid functions. Elevation, the connection to an overlay, and the
pool of workspaces searches run in.

Nothing here is needed for a flat map. A grid with no heights set and no overlay
attached behaves exactly as it did before any of this existed, and the arrays
backing it are not even allocated until you use them.

---

### gmnav_grid_has_heights

**Syntax:**

```gml
gmnav_grid_has_heights(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean

**Example:**

```gml
// only show the elevation overlay on maps that have any
if (gmnav_grid_has_heights(grid)) {
    gmnav_debug_draw_heights(grid, cfg);
}
```

The above code avoids drawing a view that would be empty.

The height array is allocated lazily, on the first call to
`gmnav_grid_set_height` or `gmnav_grid_fill_height`. Before that it does not
exist, and every height related function returns as though the map were flat.
That is why a project that never touches elevation pays nothing for it.

**See also:** `gmnav_grid_set_height`, `gmnav_grid_height`

---

### gmnav_grid_height

**Syntax:**

```gml
gmnav_grid_height(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Base node id |

**Returns:** Real, 0 if the grid has no heights

**Example:**

```gml
// make a unit's sprite sit correctly on sloped ground
var _n = gmnav_grid_world_to_node(grid, x, y);
var _z = gmnav_grid_height(grid, _n);

draw_sprite(sprite_index, image_index, x, y - _z * 8);
```

The above code reads a cell's elevation and uses it to offset the drawing, which
is one way to make a unit look like it is standing on the hill the pathfinder
thinks it is standing on.

The value is in whatever unit you chose when you set it. GMNav never converts it
to pixels, never compares it against your tile size, and never draws it. It
exists so that two cells can be compared against a unit's climb and drop limits,
and that is the whole of its job. The multiplier in the example is the game
deciding what one unit of height looks like.

Base cells only. Overlay cells express height through their layer and offset
instead, which is a different mechanism for a different problem.

**See also:** `gmnav_grid_set_height`, `gmnav_overlay_offset`

---

### gmnav_grid_set_height

**Syntax:**

```gml
gmnav_grid_set_height(grid, col, row, z);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| col | Integer | Column |
| row | Integer | Row |
| z | Real | Elevation |

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```gml
// a ramp climbing east, one step per cell
for (var _i = 0; _i < 4; _i++) {
    gmnav_grid_set_height(grid, 8 + _i, 10, _i + 1);
}

// the plateau it leads to
gmnav_grid_fill_height(grid, 12, 6, 20, 14, 4);
```

The above code builds a ramp and a plateau. There is no ramp type and no slope
flag in GMNav, because there does not need to be one: a ramp is a run of cells
whose heights step up by an amount the unit can manage.

That makes steepness a design decision rather than a setting. If a unit's
`max_climb` is 1, the four cell ramp above works and a single step of 4 would
not. If you want a ledge only a mountaineer can take, give it one big step and
let ordinary units walk around.

Units decide for themselves what they can manage, by passing `max_climb` and
`max_drop` on a request. A grid can carry elevation that only some units care
about, and a unit with no limits set ignores heights entirely.

The most useful consequence is one you get without writing it. A climb limit
smaller than a drop limit, which is what almost everything that walks looks
like, makes every cliff on your map one way. There is no flag for that anywhere
in the framework.

**See also:** `gmnav_grid_fill_height`, `gmnav_grid_step_blocked`,
`gmnav_scheduler_request`

---

### gmnav_grid_fill_height

**Syntax:**

```gml
gmnav_grid_fill_height(grid, c1, r1, c2, r2, z);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| c1 | Integer | One corner column |
| r1 | Integer | One corner row |
| c2 | Integer | Other corner column |
| r2 | Integer | Other corner row |
| z | Real | Elevation |

**Returns:** Boolean, whether anything changed

**Example:**

```gml
// three terraces
gmnav_grid_fill_height(grid,  2,  2, 10, 18, 0);
gmnav_grid_fill_height(grid, 11,  2, 18, 18, 2);
gmnav_grid_fill_height(grid, 19,  2, 28, 18, 4);
```

The above code builds a map that rises in two steps from west to east. With a
climb limit of 1 no unit can get up either step, and the map is effectively
three separate regions. With a climb limit of 2 the whole thing is walkable but
a unit that can only drop 1 cannot come back down.

That asymmetry is worth playing with before you commit to numbers, because it is
where elevation stops being decoration and starts being level design.

Corners can be given in any order and the rectangle is clipped to the grid. The
version is bumped once for the whole fill.

**See also:** `gmnav_grid_set_height`

---

### gmnav_grid_step_blocked

**Syntax:**

```gml
gmnav_grid_step_blocked(grid, a, b, max_climb, max_drop);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| a | Integer | From node |
| b | Integer | To node |
| max_climb | Real | Largest rise the unit can take, `undefined` to ignore heights |
| max_drop | Real | Largest fall the unit can take |

**Returns:** Boolean, `true` if the step is refused

**Example:**

```gml
// can this unit step from where it is to the cell it is facing?
var _here  = gmnav_grid_world_to_node(grid, x, y);
var _ahead = gmnav_grid_node(grid, gmnav_grid_col(grid, _here) + facing, 
                                   gmnav_grid_row(grid, _here));

if (_ahead != GMNAV_NO_NODE
&& !gmnav_grid_is_blocked(grid, _ahead)
&& !gmnav_grid_step_blocked(grid, _here, _ahead, max_climb, max_drop)) {
    // the step is legal
}
```

The above code checks a single step the way the search does, which is useful
when your movement code needs to agree with the pathfinder about what is
possible. A unit that can path somewhere but then refuses to walk the first step
is a frustrating bug, and it usually comes from the two disagreeing about a
ledge.

Note the three separate checks. The cell has to exist, it has to be unblocked,
and the height difference has to be within limits. They fail for different
reasons and you may want to react differently to each.

Returns `false` when `max_climb` is `undefined` or the grid has no heights, so
passing a unit's limits blindly is safe on a flat map.

**See also:** `gmnav_grid_set_height`, `gmnav_debug_draw_steps`

---

### gmnav_grid_set_layer_lift

**Syntax:**

```gml
gmnav_grid_set_layer_lift(grid, lift);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| lift | Real | Pixels between layers |

**Returns:** N/A

**Example:**

```gml
gmnav_grid_set_layer_lift(grid, 24);

// a deck cell now reports 24 pixels higher than the road beneath it
var _deck = gmnav_overlay_node_at(grid.overlay, 5, 5, 1);
var _p    = gmnav_grid_node_to_world(grid, _deck);
```

The above code tells GMNav how far apart your layers are drawn, so that
`gmnav_grid_node_to_world` reports where a raised cell actually sits.

This is purely presentational. The search never reads it, costs do not change,
and a bridge is exactly as easy to cross whether the lift is 0 or 100. What it
affects is world positions, which in turn affects path drawing, flow field
direction vectors, picking, and every debug view.

Set it to match whatever your renderer does. If your bridges are drawn 24 pixels
above the road, pass 24. Leave it unset and raised cells report at the same
position as the ground beneath them, which makes a path across a bridge draw
flattened against the road.

**See also:** `gmnav_grid_layer_lift`, `gmnav_grid_node_to_world`,
`gmnav_overlay_set_offset`

---

### gmnav_grid_layer_lift

**Syntax:**

```gml
gmnav_grid_layer_lift(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Real, 0 if none was set

**Example:**

```gml
// draw a support post under each deck cell
var _lift = gmnav_grid_layer_lift(grid);
var _p    = gmnav_grid_node_to_world(grid, _deck_node);

draw_line_width(_p[0], _p[1], _p[0], _p[1] + _lift, 3);
```

The above code uses the lift to draw the gap between a raised cell and the
ground below it, which is the sort of thing your own renderer needs to know.

Returns 0 on a grid where it was never set, so arithmetic using it is safe on a
flat map.

**See also:** `gmnav_grid_set_layer_lift`

---

### gmnav_grid_has_overlay

**Syntax:**

```gml
gmnav_grid_has_overlay(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean

**Example:**

```gml
// a helper that works on any map, layered or not
function surface_at(_grid, _x, _y) {
    if (gmnav_grid_has_overlay(_grid)) {
        return gmnav_grid_world_to_node_top(_grid, _x, _y);
    }
    return gmnav_grid_world_to_node(_grid, _x, _y);
}
```

The above code avoids the layer walk on maps that have no layers. In practice
`gmnav_grid_world_to_node_top` already falls back to the base grid when there is
no overlay, so the check is an optimisation rather than a correctness
requirement.

Where it does matter is code that reaches into `grid.overlay` directly. That
field does not exist until an overlay is created, so guard with this before
touching it.

**See also:** `gmnav_overlay_create`, `gmnav_grid_world_to_node_top`

---

### gmnav_grid_scratch_acquire

**Syntax:**

```gml
gmnav_grid_scratch_acquire(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Struct, or `undefined` if every slot is busy

**Example:**

```gml
var _slot = gmnav_grid_scratch_acquire(grid);

if (_slot == undefined) {
    // every workspace is in use. Try again next frame
    exit;
}

// ... use it ...

gmnav_grid_scratch_release(grid, _slot);
```

The above code borrows a workspace and hands it back. You will almost never
write this, because `gmnav_search_begin` does it for you and the scheduler does
it for that.

A workspace is the memory a search thinks in: arrays for cost so far, parent
links, visit marks and depth, all sized to your cell count plus any overlay
cells. They are allocated once by the grid and lent out, which is why the number
of simultaneous searches is small and deliberate rather than unlimited.

It is here for code that drives searches by hand and wants to know whether one
can start before committing to it. Forgetting to release a workspace leaks a
slot permanently, so if searches mysteriously stop starting after a while, look
for a path through your code that acquires without releasing.

**See also:** `gmnav_grid_scratch_release`, `gmnav_search_begin`

---

### gmnav_grid_scratch_release

**Syntax:**

```gml
gmnav_grid_scratch_release(grid, slot);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| slot | Struct | The workspace to return |

**Returns:** N/A

**Example:**

```gml
gmnav_grid_scratch_release(grid, _slot);
_slot = undefined;
```

The above code returns a workspace to the pool and clears the local reference,
which is worth doing because a released workspace will be handed to someone else
and reading it afterwards gives you their data.

Releasing does not free the memory, it marks the slot available. That is the
point: the arrays are expensive to allocate and cheap to reuse.

Passing `undefined` is safe and does nothing.

**See also:** `gmnav_grid_scratch_acquire`, `gmnav_grid_scratch_flush`

---

### gmnav_grid_scratch_flush

**Syntax:**

```gml
gmnav_grid_scratch_flush(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** N/A

**Example:**

```gml
// leaving this level, give the memory back
gmnav_grid_scratch_flush(grid);
```

The above code frees every idle workspace. Busy ones are left alone, so calling
this while searches are running is safe and simply does less.

On a large map the workspaces are the biggest thing GMNav holds, several arrays
sized to your cell count each. Flushing before a room change means that memory
is returned rather than sitting reserved for a grid you are about to discard.

The cost of flushing is that the next search has to allocate again, so this
belongs at a level transition rather than anywhere in normal play.

**See also:** `gmnav_grid_scratch_acquire`

---

## Overlay Functions

An overlay is a sparse set of extra walkable cells stacked over a grid.

It exists because one height per cell cannot describe a bridge over a road. That
cell has two answers: there is ground at the bottom and a deck above it, both
walkable, and a unit on one is not on the other. No height value satisfies that,
and neither does a finer grid, because the problem is not resolution.

**Sparse** matters. You are not allocating a second grid, you are listing the
handful of cells that exist above the first one. A twenty cell bridge costs
twenty cells.

Two rules keep an overlay from becoming a second map you maintain by hand, and
both are worth learning before you write any of this.

**A link is only needed where the layer actually changes.** Cells on one layer
are neighbours by the ordinary neighbour table, exactly as base cells are. A six
cell walkway needs a link at each end and nothing in between.

**One layer per standable surface, not per unit of height.** A cliff three lifts
tall is one layer drawn tall, not three layers stacked, because you cannot stand
on the middle of a cliff face.

Overlay nodes are ordinary node ids, numbered past `grid.count`. Anywhere a node
is accepted, an overlay node is accepted.

---

### gmnav_overlay_create

**Syntax:**

```gml
gmnav_overlay_create(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid to attach to |

**Returns:** Struct

**Example:**

```gml
// Create event, after the grid exists
var _ov = gmnav_overlay_create(grid);

// ... add cells and links ...

gmnav_overlay_finish(_ov);
gmnav_grid_set_layer_lift(grid, 24);
```

The above code is the shape every overlay follows: create, author, finish, and
tell the grid how far apart the layers are drawn.

A grid holds at most one overlay, and creating a second one replaces the first.
The overlay is reachable afterwards as `grid.overlay`, so you do not need to
keep the returned reference if you would rather not.

At this point the overlay exists but has no cells and no connectivity. Nothing
will change about your map until you add something.

**See also:** `gmnav_overlay_add`, `gmnav_overlay_finish`,
`gmnav_grid_has_overlay`

---

### gmnav_overlay_add

**Syntax:**

```gml
gmnav_overlay_add(ov, col, row, layer);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| col | Integer | Column |
| row | Integer | Row |
| layer | Integer | Layer index, 1 or greater |

**Returns:** Integer node id, or `GMNAV_NO_NODE` if the layer is 0 or below

**Example:**

```gml
// a three cell bridge crossing a road at column 5
var _a = gmnav_overlay_add(_ov, 5, 4, 1);
var _b = gmnav_overlay_add(_ov, 5, 5, 1);
var _c = gmnav_overlay_add(_ov, 5, 6, 1);
```

The above code creates three walkable cells on layer 1, directly above the base
cells at those coordinates. Note what it does **not** do: it does not link them
to each other. They are on the same layer and therefore already neighbours, and
adding links between them would be redundant work at every expansion for the
rest of the game.

Layer 0 is the base grid and cannot be added to, which is why passing it returns
nothing. Layer numbers above 1 are for maps with more than two surfaces at the
same coordinates, a walkway over a bridge over a road.

Adding the same column, row and layer twice returns the existing node rather
than creating a duplicate, so an authoring loop that overlaps itself is safe.

The returned node is an ordinary node id. Keep it if you are about to link it;
otherwise you can find it again with `gmnav_overlay_node_at`.

**See also:** `gmnav_overlay_link`, `gmnav_overlay_node_at`,
`gmnav_overlay_finish`

---

### gmnav_overlay_link

**Syntax:**

```gml
gmnav_overlay_link(ov, a, b, type, both);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| a | Integer | One node, base or overlay |
| b | Integer | The other node |
| type | Enum | Optional, default `gmnav_link.STAIR` |
| both | Boolean | Optional, default `true`. Whether the link works both ways |

**Returns:** N/A

**Example:**

```gml
// join the bridge to the ground at each end
gmnav_overlay_link(_ov, gmnav_grid_node(grid, 5, 3), _a, gmnav_link.STAIR, true);
gmnav_overlay_link(_ov, _c, gmnav_grid_node(grid, 5, 7), gmnav_link.STAIR, true);
```

The above code is the entire connectivity of a bridge. Two links, one at each
end, and the three deck cells join to each other by themselves.

A link joins two nodes regardless of whether they are adjacent, which is what
makes it a different thing from ordinary neighbourhood. Either end may be a base
node or an overlay node, so this is how a deck reaches the ground, how two decks
at different layers reach each other, and how anything reaches anything the
neighbour table would never have connected.

Cost is derived from the world distance between the two nodes, so a stair is
priced like the walk it represents rather than as a free teleport. That means a
tall stair costs more than a short one and the search will prefer the short one,
which is usually right.

Setting `both` to `false` gives you a one way connection. A drop you can take
downward but not climb back up is the obvious use.

**Tip:** the `type` argument is stored on the edge but nothing in the framework
reads it back to change behaviour. It is there so your own code can tell a stair
from a ladder when it inspects a route.

**See also:** `gmnav_overlay_add`, `gmnav_overlay_finish`

---

### gmnav_overlay_finish

**Syntax:**

```gml
gmnav_overlay_finish(ov);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |

**Returns:** N/A

**Example:**

```gml
gmnav_overlay_finish(_ov);
```

The above code bakes everything you authored into the form the search actually
walks, and computes clearance for the overlay's cells.

Until this runs the overlay has cells and a list of links but no connectivity,
so searches behave as though it were not there. Call it once when you have
finished authoring.

Call it **again** after any change of shape: adding cells, adding links, or
blocking a cell. Changes of state alone do not need it. Setting a cell's cost,
or its offset, takes effect immediately.

Blocking is the case worth being careful about, because it sits in between. A
blocked cell is refused at expansion time whether or not you re-finish, so
correctness does not depend on it. What re-finishing does is prune the dead
edges, so you are not walking edges that lead nowhere at every expansion for the
rest of the level.

**Note:** this is a full rebuild of the overlay's adjacency, so it belongs at
level load or at a deliberate moment, not in a Step event.

**See also:** `gmnav_overlay_add`, `gmnav_overlay_link`,
`gmnav_overlay_set_blocked`

---

### gmnav_overlay_ramp

**Syntax:**

```gml
gmnav_overlay_ramp(ov, nodes);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| nodes | Array | Overlay node ids, foot first |

**Returns:** N/A

**Example:**

```gml
// a six cell slope climbing east onto a deck
var _cells = [];

for (var _c = 4; _c <= 9; _c++) {
    array_push(_cells, gmnav_overlay_add(_ov, _c, 10, 1));
}

gmnav_overlay_ramp(_ov, _cells);

// the flat deck it leads onto
for (var _c2 = 10; _c2 <= 15; _c2++) {
    gmnav_overlay_add(_ov, _c2, 10, 1);
}

// and one link, at the foot
gmnav_overlay_link(_ov, gmnav_grid_node(grid, 3, 10), _cells[0],
                   gmnav_link.STAIR, true);
```

The above code builds a slope and the deck it leads to as one connected surface,
joined to the ground by a single link.

The helper spaces the cells' offsets evenly, so a six cell ramp climbs in sixths
of a layer. That makes steepness a function of length: a longer ramp is gentler.
If you want a gentler slope, add cells rather than looking for a setting.

**The order matters and nothing checks it.** Hand the cells in from the foot to
the top. A ramp handed its cells backwards descends from the deck into the
ground and connects to nothing at its far end, which shows up as a route that
refuses to exist for no visible reason. If a ramp you have just authored will
not path, that is the first thing to check.

For a ramp descending in the other direction, build the array from its low end
rather than reversing the offsets by hand.

One detail that surprises people: the lowest cell does not sit at ground level.
Six cells divide the layer into sixths, so the foot sits one sixth of a layer
above the ground it meets. There is always a small step at the foot and its size
is one over the number of cells. On most tile sizes nobody notices; on a short
ramp with a tall lift it is visible, and the fix is a longer ramp.

**Careful:** offsets are drawn height, not climb cost. They are not consulted by
`max_climb` or `max_drop`. A ramp on an overlay is walkable because its cells
are neighbours on one layer, however steeply it is drawn. For a slope only some
units can climb, use `gmnav_grid_set_height` on the base grid instead.

**See also:** `gmnav_overlay_set_offset`, `gmnav_grid_set_height`

---

### gmnav_overlay_count

**Syntax:**

```gml
gmnav_overlay_count(ov);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |

**Returns:** Integer

**Example:**

```gml
// walk every overlay cell, whatever layer it is on
var _ov = grid.overlay;

for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
    var _n = _ov.base + _i;

    if (gmnav_overlay_layer(_ov, _n) != 1) continue;

    gmnav_costlayer_set_node(danger, _n, 12);
}
```

The above code makes every cell on layer 1 dangerous, which is how you price a
bridge or a cliff top. It is also the pattern for any operation the stamps
cannot do, since `gmnav_costlayer_stamp_radial` and `stamp_path` work in world
space and only reach base cells.

Note `_ov.base + _i` as the way to turn an overlay index into a node id. Overlay
cells are numbered consecutively from `base`, so iterating them is a plain loop.

**See also:** `gmnav_overlay_layer`, `gmnav_costlayer_set_node`

---

### gmnav_overlay_node_at

**Syntax:**

```gml
gmnav_overlay_node_at(ov, col, row, layer);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| col | Integer | Column |
| row | Integer | Row |
| layer | Integer | Layer index |

**Returns:** Integer node id, or `GMNAV_NO_NODE`

**Example:**

```gml
// collapse the middle of the bridge
var _span = gmnav_overlay_node_at(grid.overlay, 5, 5, 1);

if (_span != GMNAV_NO_NODE) {
    gmnav_overlay_set_blocked(grid.overlay, _span, true);
    gmnav_overlay_finish(grid.overlay);
}
```

The above code finds a deck cell by its coordinates and blocks it, which is how
a bridge gets destroyed mid-game.

This is the counterpart to `gmnav_grid_node` for raised surfaces. Overlay node
ids are not laid out arithmetically, so you cannot compute one, and this lookup
is the only way to find a cell you did not keep the id of.

Returns `GMNAV_NO_NODE` when that layer has no cell at those coordinates, which
is the normal case for most of your map.

**See also:** `gmnav_overlay_add`, `gmnav_grid_world_to_node`

---

### gmnav_overlay_col

**Syntax:**

```gml
gmnav_overlay_col(ov, node);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |

**Returns:** Integer, or -1

**Example:**

```gml
// which column does this bridge occupy?
var _c = gmnav_overlay_col(grid.overlay, _deck_node);
```

The above code reads a deck cell's column.

In most code `gmnav_grid_col` is the better call, since it accepts base and
overlay nodes alike and you rarely know in advance which you have. This one is
for code already working inside the overlay, where the check is wasted.

**See also:** `gmnav_grid_col`, `gmnav_overlay_row`

---

### gmnav_overlay_row

**Syntax:**

```gml
gmnav_overlay_row(ov, node);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |

**Returns:** Integer, or -1

**Example:**

```gml
var _r = gmnav_overlay_row(grid.overlay, _deck_node);
```

As with `gmnav_overlay_col`, prefer `gmnav_grid_row` unless you are already
certain the node belongs to the overlay.

**See also:** `gmnav_grid_row`, `gmnav_overlay_col`

---

### gmnav_overlay_layer

**Syntax:**

```gml
gmnav_overlay_layer(ov, node);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |

**Returns:** Integer, or -1

**Example:**

```gml
// count how many cells sit on each layer
var _tally = [0, 0, 0, 0];
var _ov    = grid.overlay;

for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
    var _l = gmnav_overlay_layer(_ov, _ov.base + _i);
    if (_l >= 0 && _l < 4) _tally[_l]++;
}
```

The above code surveys an overlay, which is a quick way to confirm a level built
by a generator came out the shape you expected.

For a node that might be a base cell, use `gmnav_grid_node_layer` instead, which
returns 0 for those rather than -1.

**See also:** `gmnav_grid_node_layer`, `gmnav_overlay_count`

---

### gmnav_overlay_offset

**Syntax:**

```gml
gmnav_overlay_offset(ov, node);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |

**Returns:** Real

**Example:**

```gml
// draw a ramp cell at its real height
var _off  = gmnav_overlay_offset(grid.overlay, _n);
var _lift = gmnav_grid_layer_lift(grid);
var _p    = gmnav_grid_node_to_world(grid, _n);

// _p already includes the offset. This is how to get it separately
show_debug_message("this cell sits " + string(abs(_off) * _lift)
    + " pixels below its layer");
```

The above code reads how far below its layer a cell sits.

Zero means the cell is at its layer's nominal height, which is where a flat deck
lives. Negative values sit below it, which is what a ramp uses. Positive values
are legal and sit above, occasionally useful for a raised lip or a kerb.

You mostly do not need this directly, because `gmnav_grid_node_to_world` already
applies it. Reach for it when your renderer needs to interpolate a surface
between two cells, which is a job the framework leaves to you: a path across a
ramp is a straight line between two cell centres, and whether that line looks
like it lies on the slope depends on how you drew the slope.

**See also:** `gmnav_overlay_set_offset`, `gmnav_grid_node_to_world`

---

### gmnav_overlay_set_offset

**Syntax:**

```gml
gmnav_overlay_set_offset(ov, node, offset);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |
| offset | Real | Fraction of a layer, negative for below |

**Returns:** Boolean, `false` if the node is not in this overlay

**Example:**

```gml
// a two cell step up onto a deck, by hand
gmnav_overlay_set_offset(_ov, _low,  -0.66);
gmnav_overlay_set_offset(_ov, _high, -0.33);
```

The above code sets offsets manually, which is what you do when
`gmnav_overlay_ramp` does not fit: a slope that is not evenly spaced, a kerb, or
a surface that dips in the middle.

For an ordinary slope use the ramp helper instead, which computes the spacing
for you and is much harder to get wrong.

Setting the same value twice does nothing. A real change bumps the grid version,
because world positions and flow field direction vectors both derive from
offsets, so anything caching those needs to know.

**Careful:** this is drawn height, not navigation. It is not consulted by
`max_climb` or `max_drop`, and a surface offset steeply is exactly as walkable
as a flat one. For a slope only some units can take, use
`gmnav_grid_set_height`.

**See also:** `gmnav_overlay_ramp`, `gmnav_overlay_offset`

---

### gmnav_overlay_is_blocked

**Syntax:**

```gml
gmnav_overlay_is_blocked(ov, node);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |

**Returns:** Boolean

**Example:**

```gml
// has any part of this bridge collapsed?
var _broken = false;

for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
    if (gmnav_overlay_is_blocked(_ov, _ov.base + _i)) {
        _broken = true;
        break;
    }
}
```

The above code surveys an overlay for damage.

Returns `true` for anything outside the overlay, which makes it safe after a
lookup that might have failed.

For a node that might be a base cell, `gmnav_grid_is_blocked` handles both.

**See also:** `gmnav_overlay_set_blocked`, `gmnav_grid_is_blocked`

---

### gmnav_overlay_set_blocked

**Syntax:**

```gml
gmnav_overlay_set_blocked(ov, node, on);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |
| on | Boolean | New state |

**Returns:** Boolean, `false` if the node is not in this overlay

**Example:**

```gml
// the cannon hits the bridge
function bridge_collapse(_ov, _col, _row) {
    var _n = gmnav_overlay_node_at(_ov, _col, _row, 1);
    if (_n == GMNAV_NO_NODE) return false;

    gmnav_overlay_set_blocked(_ov, _n, true);
    gmnav_overlay_finish(_ov);

    return true;
}
```

The above code destroys one span of a bridge and rebuilds the overlay's
adjacency so the dead edges are pruned.

Blocking one span refuses that cell and leaves every other crossing on the map
working. Units already on the far side will find another route or report failure
honestly, and units mid-crossing will repath when they notice, assuming you are
using the agent layer or checking staleness yourself.

The version is bumped and the cell is recorded as a recent edit, but only if the
state actually changed, so calling this every step from a damage handler is
harmless.

**Tip:** for something that is usually passable, consider
`gmnav_overlay_set_cost` instead. A rickety bridge that is merely expensive can
never strand anybody, and a blocked one can.

**See also:** `gmnav_overlay_is_blocked`, `gmnav_overlay_set_cost`,
`gmnav_overlay_finish`

---

### gmnav_overlay_set_cost

**Syntax:**

```gml
gmnav_overlay_set_cost(ov, node, cost);
```

| Argument | Type | Description |
|---|---|---|
| ov | Struct | The overlay |
| node | Integer | Overlay node id |
| cost | Real | Multiplier for entering this cell, clamped to 1 or more |

**Returns:** Boolean, `false` if the node is not in this overlay

**Example:**

```gml
// a rope bridge that units would rather not use
for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
    gmnav_overlay_set_cost(_ov, _ov.base + _i, 6);
}
```

The above code makes an entire bridge expensive without making it impassable.
Units cross it when the alternative is long enough and walk round when it is
not, and unlike blocking it, this can never make a destination unreachable.

The cost belongs to the deck and not to the ground beneath it, which is the
whole point of the overlay mechanism. Dear ground under a bridge does not make
the bridge dear, and an expensive bridge does not slow anyone walking underneath
it.

Clamped to a minimum of 1 for the same reason base grid cost is: a step cheaper
than the heuristic assumes would break the search's optimality.

Takes effect immediately. No `finish` required.

**See also:** `gmnav_grid_set_cost`, `gmnav_costlayer_set_node`

---

## Clearance Functions

Pathfinding treats units as points. A cell is walkable or it is not, and the
search gives the same answer whether the thing walking is a rat or a siege golem
four tiles across. That is fine right up until your game has both.

Clearance is a number per cell recording how much room there is around it.
Precisely: **a cell's clearance is the largest `r` for which every cell within
Chebyshev distance `r - 1` is open.** So 1 means a single cell fits, 2 means a
3 by 3 block fits, 3 means 5 by 5, and 0 means the cell is blocked.

The consequence worth internalising: a doorway three cells wide has clearance
**2** at its centre and 1 at its edges. Width three does not mean clearance
three. The value describes the room around a cell, not the width of the passage
it sits in.

One grid then serves every unit size, and which route a unit gets falls out of a
single integer on its request.

---

### gmnav_clearance_supported

**Syntax:**

```gml
gmnav_clearance_supported(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_clearance_supported(grid)) {
    gmnav_clearance_build(grid);
    agent.need_clear = gmnav_clearance_for_radius(grid, agent.radius);
} else {
    agent.need_clear = 0;   // this layout cannot answer the question
}
```

The above code sets a unit's clearance requirement only on layouts where the
number would mean something.

Clearance works on `ORTHO` and `ISO_DIAMOND` only. On staggered and hex layouts
a Chebyshev radius in cell indices does not correspond to a disc in world space,
so the number would be meaningless rather than merely approximate, and GMNav
would rather say so than hand you a value you cannot trust.

On unsupported layouts `gmnav_clearance_build` returns `false` and clearance
requirements on requests are ignored rather than failing every one of them, so
a project that sets `need_clear` blindly still works. The example is being
tidy rather than avoiding a crash.

**See also:** `gmnav_clearance_build`, `gmnav_layout_create`

---

### gmnav_clearance_build

**Syntax:**

```gml
gmnav_clearance_build(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean, `false` on an unsupported layout

**Example:**

```gml
// Create event, after the map is finished
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Collision"));
gmnav_clearance_build(grid);
```

The above code computes clearance for the whole map, once, after the walls are
in place.

How it does that is worth knowing, because the obvious approach is unusable. To
check radius `r` directly you would test `(2r-1)²` cells for every cell in the
map, which grows quadratically as units get bigger and reaches millions of
checks on a large map. Instead GMNav uses a distance transform: two sweeps over
the grid, four neighbour lookups each. The forward sweep runs top left to bottom
right taking the smallest of four already-computed neighbours and adding one;
the backward sweep does the mirror image and keeps whichever value is smaller.

Two passes, four lookups each, and unlike the box scan the cost is the same for
radius 2 and radius 20.

The result is stored on the grid, so it is built once and read by every search.
Build it after your map is complete, not before.

**Note:** any edit to the grid invalidates this. See
`gmnav_clearance_build_if_stale`.

**See also:** `gmnav_clearance_build_if_stale`, `gmnav_clearance_at`

---

### gmnav_clearance_is_stale

**Syntax:**

```gml
gmnav_clearance_is_stale(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean

**Example:**

```gml
// rebuild at a moment that suits you rather than mid-combat
if (gmnav_clearance_is_stale(grid) && !in_combat) {
    gmnav_clearance_build(grid);
}
```

The above code defers an expensive rebuild to a quiet moment.

Clearance derives from the grid, so blocking a cell, opening a door or importing
a new map all make it out of date. This tells you it happened.

A search that needs clearance will rebuild automatically if it finds the data
stale, so you cannot accidentally route a golem through a wall that appeared.
But that rebuild is a full two pass sweep of the whole map, and it will happen
inside whichever search triggers it. On a map that changes constantly, deciding
when that cost lands is better than letting it fall wherever it happens to.

**See also:** `gmnav_clearance_build_if_stale`, `gmnav_grid_changed_since`

---

### gmnav_clearance_build_if_stale

**Syntax:**

```gml
gmnav_clearance_build_if_stale(grid);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |

**Returns:** Boolean, whether a rebuild happened

**Example:**

```gml
// after a wall comes down
destroy_wall_at(_col, _row);
gmnav_grid_set_blocked(grid, _col, _row, false);

gmnav_clearance_build_if_stale(grid);
```

The above code rebuilds clearance immediately after a change, which is the right
call when changes are occasional and you would rather not think about it.

This is the same as checking `gmnav_clearance_is_stale` and building, in one
call. It does nothing if the data is current, so it is safe to call after any
edit whether or not that edit mattered.

If your terrain changes every frame, do not call this every frame. Batch your
edits and rebuild once, or rebuild at a deliberate moment.

**See also:** `gmnav_clearance_build`, `gmnav_clearance_is_stale`

---

### gmnav_clearance_at

**Syntax:**

```gml
gmnav_clearance_at(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Integer, 0 for a blocked cell

**Example:**

```gml
// why won't the ogre go through this door?
var _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);

show_debug_message("clearance here is "
    + string(gmnav_clearance_at(grid, _n))
    + ", the ogre needs " + string(ogre.need_clear));
```

The above code answers the most common clearance question directly. Usually the
answer is that the doorway is one cell narrower than you remembered.

Values are capped at the `CLEARANCE_MAX` config setting, 16 by default, so a
cell in the middle of a vast open field reports 16 rather than its true
distance from anything. That cap exists because no unit needs more and the
number is stored per cell.

Out of bounds nodes return 0, the same as blocked ones.

Overlay cells have their own clearance, computed by `gmnav_overlay_finish`. A
deck two cells wide reports 1 at its edges, which is correct and is why a bodied
unit cannot smooth a path across a narrow bridge.

**See also:** `gmnav_clearance_for_radius`, `gmnav_debug_draw_clearance`

---

### gmnav_clearance_for_radius

**Syntax:**

```gml
gmnav_clearance_for_radius(grid, radius);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| radius | Real | The unit's body radius in pixels |

**Returns:** Integer, 1 or greater

**Example:**

```gml
rat     = gmnav_agent_create(sched, x, y, 6,  2.5);
soldier = gmnav_agent_create(sched, x, y, 14, 2.0);
ogre    = gmnav_agent_create(sched, x, y, 26, 1.4);

rat.need_clear     = gmnav_clearance_for_radius(grid, rat.radius);
soldier.need_clear = gmnav_clearance_for_radius(grid, soldier.radius);
ogre.need_clear    = gmnav_clearance_for_radius(grid, ogre.radius);
```

The above code gives three units of different sizes the right clearance
requirement each, from one grid and one clearance map.

Use this rather than guessing a cell count. It accounts for your tile size and
uses the larger tile dimension, so a wide unit on tall thin tiles is never under
served. On 32 pixel tiles a radius of 8 needs 1, a radius of 24 needs 2, and a
radius of 40 needs 3.

What you get for that single integer is four different behaviours from one map:
the rat takes the narrow gap, the soldier takes a wider one, the ogre detours to
the widest, and a unit nothing fits gets an honest `FAILED` rather than a route
it cannot walk.

**Design note:** that last case is worth planning for. If your game has units
needing clearance 4, some passage somewhere needs to be seven cells wide, and no
amount of pathfinding will invent it.

**See also:** `gmnav_clearance_at`, `gmnav_scheduler_request`

---

### gmnav_clearance_nearest

**Syntax:**

```gml
gmnav_clearance_nearest(grid, node, need, max_rings);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | The cell you wanted |
| need | Integer | Clearance required |
| max_rings | Integer | Optional. How far out to search |

**Returns:** Integer node id, or `GMNAV_NO_NODE`

**Example:**

```gml
// the player clicked a spot too tight for this unit. Get as close as we can
var _wanted = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);
var _goal   = gmnav_clearance_nearest(grid, _wanted, ogre.need_clear);

if (_goal != GMNAV_NO_NODE) {
    var _p = gmnav_grid_node_to_world(grid, _goal);
    gmnav_agent_goto(ogre, _p[0], _p[1]);
} else {
    show_debug_message("nowhere nearby fits this unit");
}
```

The above code turns a refusal into an approximation, which is usually what the
player meant. Telling an ogre to stand in a doorway it cannot fit through should
walk it to the doorway, not produce nothing.

The search expands outward in rings from the cell you asked for and returns the
first one that genuinely fits. If the original cell already has enough
clearance, it returns that unchanged, so calling it unconditionally costs almost
nothing in the common case.

`max_rings` bounds how far it will look. Without a limit, a goal deep inside a
region nothing fits will search a long way before giving up.

**See also:** `gmnav_clearance_for_radius`, `gmnav_agent_goto`

---

## Search Functions

A search object is the low level way to get a path. You create one, begin it,
and step it until it finishes.

Most projects never touch these, because the scheduler drives them for you and
handles the budget across every search at once. Reach for this layer when you
want a path outside the normal flow: a menu previewing a route, a level
validator checking that every spawn can reach every objective, or a tool.

---

### gmnav_search_create

**Syntax:**

```gml
gmnav_search_create(grid, heuristic);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid to search over |
| heuristic | Enum | Optional, default `gmnav_heuristic.AUTO` |

**Returns:** Struct

**Example:**

```gml
// keep one around, reuse it
search = gmnav_search_create(grid);
```

The above code makes a reusable search object. Creating one is cheap: it holds
no memory of its own until it begins, because the arrays it thinks in are
borrowed from the grid's workspace pool and returned when it finishes.

`AUTO` picks the right heuristic from your layout. On an eight direction square
or diamond grid that is octile, the exact straight line distance counting
diagonals at their proper price. On four direction it is Manhattan, because
octile would overestimate. On hex it is true hex distance via cube coordinates.
On staggered, where cell offsets are not a metric space at all, it falls back to
world distance divided by the shortest possible step, which converts pixels into
step units and keeps the estimate honest.

`ZERO` turns the search into Dijkstra's algorithm, which explores evenly in all
directions and does far more work for the same answer. That sounds useless and
mostly is, but it is genuinely valuable for one thing: if you suspect a path is
wrong, run the same query with `ZERO` and compare the total cost. Dijkstra is
optimal by construction, so if the two disagree the problem is the heuristic
rather than your map.

**See also:** `gmnav_search_begin`, `gmnav_scheduler_create`

---

### gmnav_search_begin

**Syntax:**

```gml
gmnav_search_begin(search, start_node, goal_node, corner_cut, profile, need_clear, max_climb, max_drop);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |
| start_node | Integer | Starting node, base or overlay |
| goal_node | Integer | Target node, base or overlay |
| corner_cut | Boolean | Optional, default `false` |
| profile | Struct | Optional, default `undefined`. A cost profile |
| need_clear | Integer | Optional, default 0. Clearance required |
| max_climb | Real | Optional, default `undefined`. Largest rise |
| max_drop | Real | Optional, default `undefined`. Largest fall |

**Returns:** Boolean, whether the search started

**Example:**

```gml
if (!gmnav_search_begin(search, _from, _to, false, profile, 2, 1, 3)) {
    // one end was blocked or out of bounds, or no workspace was free
    show_debug_message("could not start");
}
```

The above code sets a search up for a wide unit that can climb 1 and drop 3,
paying attention to a cost profile.

It does no work. Nothing has been searched when this returns; call
`gmnav_search_step` to actually advance it.

It fails, returning `false`, in three cases worth telling apart. Either end
being out of bounds or blocked is a caller mistake and usually means a lookup
you did not check. No workspace being available is transient and means every
slot is busy, so trying again next frame is the right response.

The optional arguments are how one grid serves different units. Note that
`need_clear` above 1 will build clearance if it is missing or out of date, which
can be an expensive surprise inside an otherwise cheap call. Build it deliberately
if that matters.

`corner_cut` allows a diagonal to pass between two wall corners. It is off by
default because the gap is mathematical rather than physical, and a character
taking that step clips through both corners. Turn it on if your game wants that,
some top down shooters and roguelikes do, and accept the clipping.

**See also:** `gmnav_search_step`, `gmnav_scheduler_request`

---

### gmnav_search_step

**Syntax:**

```gml
gmnav_search_step(search, budget);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |
| budget | Integer | Optional. Node expansions allowed this call |

**Returns:** Enum, a `gmnav_state` member

**Example:**

```gml
// spread one search over several frames
var _state = gmnav_search_step(search, 200);

switch (_state) {
    case gmnav_state.FOUND:
        path = gmnav_search_get_path(search);
        gmnav_search_release(search);
        break;

    case gmnav_state.FAILED:
        show_debug_message("no route");
        gmnav_search_release(search);
        break;

    // WORKING: come back next frame
}
```

The above code advances a search a little and handles all three outcomes.

The budget is counted in node expansions. Pass a small one and the search does a
little and stops, keeping its frontier, its costs so far and its parent links
alive in its workspace, so the next call carries on from exactly where it left
off. Nothing is thrown away and nothing is recomputed. The search does not know
or care that four frames passed between two of its steps.

That is the core idea the whole framework is arranged around. A search that runs
to completion costs whatever it costs, and forty of them landing on one frame
costs forty times that, all at once. Splitting the work is what makes the cost
predictable.

Passing a very large budget runs it to completion in one call, which is fine for
a tool or a level load and is exactly what you should not do during gameplay.

Note the `release` calls. A finished search still holds its workspace until you
give it back.

**See also:** `gmnav_search_get_path`, `gmnav_search_release`

---

### gmnav_search_get_path

**Syntax:**

```gml
gmnav_search_get_path(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |

**Returns:** Array of node ids, empty if the search did not succeed

**Example:**

```gml
var _nodes = gmnav_search_get_path(search);

if (array_length(_nodes) > 0) {
    path = gmnav_path_create(grid, _nodes);
    gmnav_path_smooth(path);
}
```

The above code takes the raw result and turns it into a path object with world
coordinates, which is what you need before anything can walk it.

The array runs from start to goal and contains every cell the route passes
through, so it is longer than you probably want to follow directly. A corner to
corner route on a modest map is commonly thirty or forty entries with about four
real corners in it. That is what `gmnav_path_smooth` is for.

Returns an empty array rather than `undefined` when the search failed, so
checking the length is enough.

**See also:** `gmnav_path_create`, `gmnav_path_smooth`

---

### gmnav_search_is_stale

**Syntax:**

```gml
gmnav_search_is_stale(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |

**Returns:** Boolean

**Example:**

```gml
if (_state == gmnav_state.FOUND) {
    if (gmnav_search_is_stale(search)) {
        // the world moved while this was thinking. Ask again
        request_again();
    } else {
        path = gmnav_search_get_path(search);
    }
}
```

The above code refuses a result that may no longer describe the map.

What this promises, and what it deliberately does not, is worth being precise
about.

A search that **completed** before the change produced a real path. It may no
longer be a good one, and it may now route through a wall that appeared, but it
was correct when produced and nothing is corrupted.

A search that was **suspended** when the change happened is different. Cells it
already settled carry a cost and a parent link decided under the old world, and
settled cells are never revisited. That is not an oversight, it is the property
that makes A\* efficient. So a wall landing on ground the search has already
crossed off is simply never noticed.

The contract is therefore: the search will terminate, it will report stale, and
it does **not** promise the path is walkable. Treat this flag as a correctness
signal rather than a nice to have.

You might reasonably ask why GMNav does not just restart a search that notices
the version moved. In a tower defense where the player places a wall every
second, the version bumps constantly, a restarting search never completes, and
no agent ever receives a path. The failure mode of the cure is worse than the
disease.

**See also:** `gmnav_grid_changed_since`, `gmnav_scheduler_request`

---

### gmnav_search_release

**Syntax:**

```gml
gmnav_search_release(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |

**Returns:** N/A

**Example:**

```gml
path = gmnav_search_get_path(search);
gmnav_search_release(search);
```

The above code takes the result and then gives the workspace back, in that
order, because releasing clears the result.

A finished search holds its workspace until you release it. Since the grid lends
out a small fixed number, typically four, forgetting to release means slots
disappear one by one until nothing can start. If searches stop working after a
while in a long session, this is where to look.

The search object itself stays usable. You can begin it again immediately.

**See also:** `gmnav_search_abort`, `gmnav_grid_scratch_release`

---

### gmnav_search_abort

**Syntax:**

```gml
gmnav_search_abort(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |

**Returns:** N/A

**Example:**

```gml
// the target died while we were still looking for it
if (!instance_exists(target)) {
    gmnav_search_abort(search);
}
```

The above code stops a search that is no longer wanted and hands its workspace
straight back, so something else can use it this frame rather than waiting for a
search nobody cares about to finish.

Safe on a search that is idle or already finished, so you do not need to check
its state first.

The difference from `gmnav_search_release` is intent rather than mechanism:
abort is for a search in progress, release is for one that has finished and
whose result you have taken. Both return the workspace.

**See also:** `gmnav_search_release`, `gmnav_scheduler_cancel`

---

## Scheduler Functions

The scheduler is the reason GMNav exists.

A game running at 60 frames per second has 16.6 milliseconds to do everything.
Put forty guards in a fortress, trip an alarm, and every one of them asks for a
path on the same frame. If each search runs to completion before your game
continues, that frame is gone, and so is the next one.

You cannot fix that by optimising the search. Even at twice the speed, forty of
them still land at once and the eighty first agent still ruins everything. The
problem is not that any single search is slow, it is that the total work is
unbounded and arrives all at once.

So the scheduler owns **one** budget shared across every search in flight, not
one per agent. Peak cost per frame is whatever you said it was, whether ten
agents are asking or two hundred. What agent count changes is how long the queue
takes to drain, and that trade, responsiveness degrading gracefully instead of
frame rate falling off a cliff, is the whole proposition. A guard who takes an
extra second to work out a route looks like a guard who hesitated. A game that
drops to 20 fps looks broken.

It dispatches on domain, so the same API drives a grid or a platformer graph.

---

### gmnav_scheduler_create

**Syntax:**

```gml
gmnav_scheduler_create(target, budget, concurrent);
```

| Argument | Type | Description |
|---|---|---|
| target | Struct | A grid or a platformer graph |
| budget | Integer | Optional. Node expansions per frame, across all searches |
| concurrent | Integer | Optional, default 4. Searches in flight at once |

**Returns:** Struct

**Example:**

```gml
// one scheduler for the top down map
sched = gmnav_scheduler_create(grid, 2000, 4);

// and another for the side view graph, if your game has both
psched = gmnav_scheduler_create(pgraph, 1500);
```

The above code creates two schedulers over two different targets. The domain is
read from what you pass, so nothing else about the API changes between them.

The budget is the only knob that matters, and it is an honest trade in both
directions. Lower it and paths take longer to arrive. Raise it and frames cost
more. 2000 is a sensible starting point on a mid-sized grid: lower it until you
see paths visibly lagging, then go back up one step.

`concurrent` is capped by how many workspaces the target can supply, so asking
for more than the grid's `slots` gets you the grid's `slots`. Four is
deliberate rather than arbitrary. Each in-flight search needs its own arrays
sized to your cell count, so on a 500 by 500 map four is around 24 megabytes and
forty would be 240 for no benefit, since they would all share the same budget
anyway.

Running four rather than one is worth it for a reason that is not obvious: a
search that finishes early hands its unused budget to the next one in the same
frame. With one at a time, a request needing thirty expansions wastes the rest of
the allowance.

**See also:** `gmnav_scheduler_update`, `gmnav_scheduler_request`,
`gmnav_grid_create`

---

### gmnav_scheduler_request

**Syntax:**

```gml
gmnav_scheduler_request(sched, start_node, goal_node, priority, corner_cut, profile, need_clear, max_climb, max_drop);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | The scheduler |
| start_node | Integer | Where the unit is |
| goal_node | Integer | Where it wants to be |
| priority | Enum | Optional, default `gmnav_priority.NORMAL` |
| corner_cut | Boolean | Optional, default `false` |
| profile | Struct | Optional, default `undefined`. A cost profile |
| need_clear | Integer | Optional, default 0. Clearance required |
| max_climb | Real | Optional, default `undefined`. Largest rise |
| max_drop | Real | Optional, default `undefined`. Largest fall |

**Returns:** Struct, a ticket

**Example:**

```gml
// Step event
if (ticket == undefined && wants_to_move) {
    ticket = gmnav_scheduler_request(sched, my_node, goal_node,
                                     gmnav_priority.NORMAL);
}

gmnav_scheduler_update(sched);

if (ticket != undefined) {
    if (ticket.state == gmnav_state.FOUND) {
        path   = gmnav_scheduler_get_path(ticket);
        ticket = undefined;
    } else if (ticket.state == gmnav_state.FAILED) {
        show_debug_message("no route exists");
        ticket = undefined;
    }
}
```

The above code asks for a path and polls for the answer over the following
frames. The important thing to understand is that the ticket comes back
**immediately**, before any work has been done, and it is a receipt rather than
a path. The search runs inside `gmnav_scheduler_update`, a little each frame.

Because of that your code handles three states rather than two. `FOUND` means a
path is waiting. `FAILED` means no route exists and never will unless the map
changes. Anything else means it is still going. Clearing your own reference once
you have dealt with it, as above, is what stops you reading the same result
forever.

The optional arguments are how one grid serves different kinds of unit. A wide
unit passes `need_clear` so it is not routed through a doorway it cannot fit; a
cautious unit passes a `profile` so it pays more to cross dangerous ground; a
unit that cannot climb passes `max_climb` and `max_drop` so a cliff becomes one
way for it. None of these change the map, only what this one request is willing
to walk.

**Priority** orders the queue into bands, and within a band the oldest request
goes first. That second rule matters more than it looks: without it, a fresh
request with the same priority as one that has been waiting two seconds is
indistinguishable from it, and the queue can keep reshuffling around its own
oldest member.

What priority does **not** do is create capacity. If high priority requests
arrive faster than workspaces free up, the backlog grows without limit and
anything below them never runs at all. If every request in your game is `HIGH`
you have exactly the queue you would have had with no priorities, plus false
confidence. Reserve it for genuinely urgent, genuinely rare things.

**`IMMEDIATE` is not the promise its name suggests.** It bypasses the budget and
runs to completion inside this call, which is genuinely useful for placing an
NPC at level start, a menu previewing a route, or a cutscene. It does not bypass
the workspace pool. If four searches are already mid-flight holding all four
workspaces, there is nowhere to run, and the request quietly falls back into the
queue to resolve later like any other. So this is a bug waiting to happen:

```gml
var _t = gmnav_scheduler_request(sched, _a, _b, gmnav_priority.IMMEDIATE);
var _p = gmnav_scheduler_get_path(_t);   // may be empty, and you did not check
```

Check `_t.state` instead.

**See also:** `gmnav_scheduler_update`, `gmnav_scheduler_get_path`,
`gmnav_scheduler_cancel`, `gmnav_agent_goto`

---

### gmnav_scheduler_update

**Syntax:**

```gml
gmnav_scheduler_update(sched);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | The scheduler |

**Returns:** N/A

**Example:**

```gml
// Step event of your controller, once per frame
gmnav_scheduler_update(sched);

with (obj_unit) {
    gmnav_agent_update(agent);
    x += agent.vx;
    y += agent.vy;
}
```

The above code advances every search in flight and then lets the units act on
the results. The order matters: update the scheduler first, so a path that
resolved this frame is available to the agent that asked for it rather than
sitting unused until the next one.

This is where the work actually happens. Requests are pulled off the queue as
workspaces free up, each running search is advanced, and unused budget from a
search that finishes early cascades to the next one in the same frame so nothing
is wasted.

Call it exactly once per frame per scheduler. Calling it twice does not break
anything but doubles your frame cost, which defeats the point.

**See also:** `gmnav_scheduler_request`, `gmnav_scheduler_pending`

---

### gmnav_scheduler_is_ready

**Syntax:**

```gml
gmnav_scheduler_is_ready(ticket);
```

| Argument | Type | Description |
|---|---|---|
| ticket | Struct | The ticket |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_scheduler_is_ready(ticket)) {
    path   = gmnav_scheduler_get_path(ticket);
    ticket = undefined;
}
```

The above code collects a finished path.

**Careful:** this returns `true` only for `FOUND`. A request that failed is
finished but not ready, so code shaped like the example above will hold onto a
failed ticket forever, checking it every frame and never clearing it. That looks
like a unit that decided to stand still for no reason.

If you need to tell the two apart, and you usually do, check `ticket.state`
against both `gmnav_state.FOUND` and `gmnav_state.FAILED` as the
`gmnav_scheduler_request` example does.

**See also:** `gmnav_scheduler_get_path`, `gmnav_scheduler_request`

---

### gmnav_scheduler_get_path

**Syntax:**

```gml
gmnav_scheduler_get_path(ticket);
```

| Argument | Type | Description |
|---|---|---|
| ticket | Struct | The ticket |

**Returns:** Array of node ids, empty if the request did not succeed

**Example:**

```gml
var _nodes = gmnav_scheduler_get_path(ticket);

if (array_length(_nodes) > 0) {
    path = gmnav_path_create(grid, _nodes);

    gmnav_path_smooth(path, agent.max_climb, agent.max_drop,
                      agent.radius, agent.headings, agent.profile);
    gmnav_path_anchor_start(path, x, y);
    gmnav_path_anchor_end(path, goal_x, goal_y);
}
```

The above code takes a finished result through the full pipeline: raw nodes into
a path object, smoothed, then anchored at both ends so the unit does not snap
backwards to a cell centre when it starts moving.

That is what `gmnav_agent` does internally, written out for a project using its
own agent class.

The array is the raw cell route, so it has far more waypoints than corners.
Smoothing is what removes them, and all five of those arguments matter: without
them a shortcut can climb a cliff, clip a corner with the unit's shoulders, take
a heading the unit cannot face, or walk back through expensive ground the search
paid to avoid.

**See also:** `gmnav_path_create`, `gmnav_path_smooth`,
`gmnav_scheduler_get_links`

---

### gmnav_scheduler_get_links

**Syntax:**

```gml
gmnav_scheduler_get_links(ticket);
```

| Argument | Type | Description |
|---|---|---|
| ticket | Struct | The ticket |

**Returns:** Array of `gmnav_link` values, empty on the grid domain

**Example:**

```gml
var _path  = gmnav_scheduler_get_path(ticket);
var _links = gmnav_scheduler_get_links(ticket);

// _links[i] is how you reach _path[i]
switch (_links[seek]) {
    case gmnav_link.WALK:
        // run toward the next node's x
        break;

    case gmnav_link.FALL:
        // run toward the edge and keep running, gravity does the rest
        break;

    case gmnav_link.JUMP:
        // run toward the target and press jump at the right moment
        break;
}
```

The above code reads a platformer route and branches on how each step is to be
performed. This is the boundary between what GMNav does and what your character
controller does: the framework tells you a jump is needed and where it lands, it
does not press the button.

That is deliberate. Variable jump height, coyote time, input buffering, air
control and animation states all differ per project, and a library guessing at
them would be wrong for everyone.

`_links[i]` describes how you arrive at `_path[i]`, so the two arrays line up
and the first entry is your starting node with no link needed.

Empty on the grid domain, where every step is simply a move to an adjacent cell.

**See also:** `gmnav_platgraph_link_get`, `gmnav_platagent_create`

---

### gmnav_scheduler_cancel

**Syntax:**

```gml
gmnav_scheduler_cancel(sched, ticket);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | The scheduler |
| ticket | Struct | The ticket to abandon |

**Returns:** N/A

**Example:**

```gml
// the guard lost sight of the player. Stop looking for a route to them
if (!can_see_target && ticket != undefined) {
    gmnav_scheduler_cancel(sched, ticket);
    ticket = undefined;
}
```

The above code abandons a request nobody wants any more.

Agents change their minds constantly. The player moves, a target dies, a guard
loses interest. In a game where that happens often, cancelling stale requests is
a real performance win rather than tidiness: a cancelled search frees its
workspace on the next update and lets a waiting request take it, so the queue
drains faster for everyone else.

Safe at any point, whether the ticket is queued, running or already finished.
Cancelling a finished ticket simply discards the result.

**See also:** `gmnav_scheduler_request`, `gmnav_search_abort`

---

### gmnav_scheduler_pending

**Syntax:**

```gml
gmnav_scheduler_pending(sched);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | The scheduler |

**Returns:** Integer

**Example:**

```gml
// watch for a queue that never drains
if (gmnav_scheduler_pending(sched) > 50) {
    backlog_frames++;
} else {
    backlog_frames = 0;
}

if (backlog_frames > 120) {
    show_debug_message("the queue has been full for two seconds");
}
```

The above code distinguishes a spike from a problem, which is the distinction
that matters.

A brief spike is normal and means a crowd just asked at once. Pending that stays
high frame after frame means requests are arriving faster than you are serving
them, and the queue will grow without limit.

The obvious response is to raise the budget, and it is often the wrong one.
Before doing that, ask whether those requests should exist at all. On a map with
frequent edits, permanently high pending is more often unnecessary repathing
than an undersized allowance, because a single global version counter means
every agent reacts to every change whether or not it was anywhere near them.
Raising the budget hides that by doing the pointless work faster.

`gmnav_grid_changed_since` is the tool for the other response.

**See also:** `gmnav_debug_draw_stats`, `gmnav_grid_changed_since`

---

## Path Functions

A search returns an array of integers. Nothing in your game moves.

A path object closes that gap. It converts node ids into world waypoints and
holds the result, and the functions here reshape that result into something a
character can actually walk.

The usual pipeline is: create, smooth, anchor both ends, optionally curve. The
agent layer does all of it for you; this section is for projects driving paths
themselves, which most eventually do.

Every waypoint sits at the centre of its cell, at the height that cell is drawn
at, so a node on a bridge reports where the bridge is rather than where the road
beneath it is.

---

### gmnav_path_create

**Syntax:**

```gml
gmnav_path_create(grid, nodes);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid the nodes belong to |
| nodes | Array | Node ids, in order |

**Returns:** Struct

**Example:**

```gml
var _nodes = gmnav_scheduler_get_path(ticket);

if (array_length(_nodes) > 0) {
    path = gmnav_path_create(grid, _nodes);
}
```

The above code turns a finished search result into something with world
coordinates in it.

The path keeps its own copy of the node list in `path.nodes`, alongside the
world positions in `path.px` and `path.py`. That node list is what lets later
functions reason about layers and cost, so it matters which of the reshaping
functions preserve it. `gmnav_path_smooth` and `gmnav_path_curve` keep it;
`gmnav_path_simplify` clears it, because after simplifying the waypoints no
longer correspond one to one with cells.

An empty array gives you an empty path rather than an error, which keeps the
calling code simple.

**See also:** `gmnav_path_smooth`, `gmnav_scheduler_get_path`

---

### gmnav_path_get_count

**Syntax:**

```gml
gmnav_path_get_count(path);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |

**Returns:** Integer

**Example:**

```gml
// how much did smoothing actually save?
var _raw = gmnav_path_get_count(path);

gmnav_path_smooth(path);

show_debug_message(string(_raw) + " waypoints became "
    + string(gmnav_path_get_count(path)));
```

The above code measures what smoothing did, which is worth doing once on a real
map because the numbers are usually larger than people expect. A corner to
corner route with about four real turns in it commonly starts at thirty or forty
waypoints.

You can also read `path.count` directly. The function exists for consistency
with the other accessors.

**See also:** `gmnav_path_get_x`, `gmnav_path_smooth`

---

### gmnav_path_get_x

**Syntax:**

```gml
gmnav_path_get_x(path, i);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |
| i | Integer | Waypoint index |

**Returns:** Real

**Example:**

```gml
// draw the route
for (var _i = 0; _i < gmnav_path_get_count(path) - 1; _i++) {
    draw_line(gmnav_path_get_x(path, _i),     gmnav_path_get_y(path, _i),
              gmnav_path_get_x(path, _i + 1), gmnav_path_get_y(path, _i + 1));
}
```

The above code draws a path as a series of straight segments.

Note what that means on a ramp: the waypoints sit at each cell's own height and
the line between them is a straight interpolation. If your renderer draws the
ramp as stepped flat cells, the line visibly floats above the steps in the
middle of each span. If it interpolates the surface, the same line lies on it.
The navigation is identical either way; only the picture differs, and the
surface between two cells is your renderer's business.

For tight loops, reading `path.px[i]` directly avoids the call overhead.

**See also:** `gmnav_path_get_y`, `gmnav_path_sample`

---

### gmnav_path_get_y

**Syntax:**

```gml
gmnav_path_get_y(path, i);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |
| i | Integer | Waypoint index |

**Returns:** Real

**Example:**

```gml
// steer toward the current waypoint
var _tx = gmnav_path_get_x(path, seek);
var _ty = gmnav_path_get_y(path, seek);

var _d = point_distance(x, y, _tx, _ty);

if (_d < reach_dist) {
    seek++;
} else {
    var _dir = point_direction(x, y, _tx, _ty);
    x += lengthdir_x(spd, _dir);
    y += lengthdir_y(spd, _dir);
}
```

The above code is the core of any path follower: head for the current waypoint,
advance when you reach it.

Two things that follower is missing, and they both bite at speed. If waypoints
are twenty pixels apart and the unit moves thirty pixels per frame, it passes
several in one step, so advancing one per frame leaves it steering at points it
has already gone past and curving backwards. Drain every reached waypoint in the
same update instead. And a reach distance smaller than the unit's speed is a
target it can never land inside, so it orbits forever; use
`max(reach_dist, speed)`.

`gmnav_agent_update` handles both.

**See also:** `gmnav_path_get_x`, `gmnav_agent_update`

---

### gmnav_path_get_length

**Syntax:**

```gml
gmnav_path_get_length(path);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |

**Returns:** Real

**Example:**

```gml
// is this trip worth making?
var _direct = gmnav_path_get_length(path_to_target);
var _via    = gmnav_path_get_length(path_to_heal)
            + gmnav_path_get_length(path_heal_to_target);

if (_via - _direct < healing_is_worth) {
    go_via_heal_zone();
}
```

The above code compares a direct route against a detour, which is how you turn
navigation into a decision. The framework can tell you what a diversion costs;
whether that price is worth paying depends on the unit's health, its aggression
and what your designer wants, and none of that is navigation.

For a crowd, `gmnav_flowfield_cost_at` gives you the same kind of number for
every unit at once without running any searches.

The length is in pixels and is recalculated whenever the path is reshaped, so
reading it after smoothing gives you the smoothed length. Smoothed paths are
usually **shorter** than raw ones, because the staircase was never the shortest
route between two points, only the shortest one that follows cell centres.

**See also:** `gmnav_path_sample`, `gmnav_flowfield_cost_at`

---

### gmnav_path_sample

**Syntax:**

```gml
gmnav_path_sample(path, dist);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |
| dist | Real | Distance from the start, in pixels |

**Returns:** Array, `[x, y]`

**Example:**

```gml
// a scout marker running ahead of the unit along its own route
var _walked = point_distance(start_x, start_y, x, y);
var _ahead  = gmnav_path_sample(path, _walked + 120);

draw_sprite(spr_marker, 0, _ahead[0], _ahead[1]);
```

The above code finds a point further along the route than the unit has reached,
which is useful for lookahead: aiming a turret, previewing where a unit is
about to go, or placing a formation leader.

Distances past the end of the path return the final waypoint, and negative
distances return the first, so you do not need to clamp.

This walks the path from the beginning each call, so it is fine occasionally and
wasteful in a loop over hundreds of units every frame.

**See also:** `gmnav_path_get_length`

---

### gmnav_path_anchor_start

**Syntax:**

```gml
gmnav_path_anchor_start(path, x, y);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |
| x | Real | Where the character really is |
| y | Real | Where the character really is |

**Returns:** N/A

**Example:**

```gml
path = gmnav_path_create(grid, _nodes);
gmnav_path_smooth(path);

gmnav_path_anchor_start(path, x, y);
gmnav_path_anchor_end(path, goal_x, goal_y);
```

The above code replaces the first and last waypoints with real positions.

Without this the opening move is a visible snap backwards. Every waypoint sits
at a cell centre, and your character is almost never standing exactly on one, so
the first waypoint is slightly behind it and the unit walks the wrong way for a
frame before setting off properly.

Anchor **after** smoothing, not before. Smoothing works on the cell route, and
anchoring first means the shaping pass is reasoning about a waypoint that is no
longer at a cell centre.

The path's length is recalculated, so anything reading it afterwards gets the
real figure.

**See also:** `gmnav_path_anchor_end`, `gmnav_path_smooth`

---

### gmnav_path_anchor_end

**Syntax:**

```gml
gmnav_path_anchor_end(path, x, y);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path |
| x | Real | Where the target really is |
| y | Real | Where the target really is |

**Returns:** N/A

**Example:**

```gml
// walk to the exact spot the player clicked, not the middle of its cell
gmnav_path_anchor_end(path, mouse_x, mouse_y);
```

The above code makes the unit stop where it was told rather than at the nearest
cell centre, which on 32 pixel tiles can be sixteen pixels out in both
directions.

**Careful:** the position you anchor to should be somewhere the unit can
actually stand. Anchoring to a point two pixels from a wall gives you a
destination its body cannot reach, and a unit that never registers arrival will
keep pushing against the wall forever. Either validate the point against the
unit's radius or raise its `reach_dist` past that radius.

**See also:** `gmnav_path_anchor_start`, `gmnav_clearance_nearest`

---

### gmnav_path_smooth

**Syntax:**

```gml
gmnav_path_smooth(path, max_climb, max_drop, radius, headings, profile);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path, modified in place |
| max_climb | Real | Optional. Largest rise the unit can take |
| max_drop | Real | Optional. Largest fall |
| radius | Real | Optional, default 0. Body radius |
| headings | Integer | Optional, default 0. Permitted headings |
| profile | Struct | Optional. Cost profile |

**Returns:** N/A

**Example:**

```gml
// everything the unit knows about itself, handed to the shaping pass
gmnav_path_smooth(path, agent.max_climb, agent.max_drop,
                  agent.radius, agent.headings, agent.profile);
```

The above code is the call you almost always want. Each optional argument closes
a different way a shortcut could be wrong, and leaving one out does not produce
an error, it produces a path that is quietly wrong in that specific way.

**What it does.** A grid search returns a staircase: a straight line chopped into
single cell steps, with far more corners than the route really has. Smoothing
walks the route asking how far ahead it can see in a straight line, jumps there,
and repeats. The result usually has a fraction of the waypoints and is slightly
**shorter**, because the staircase was never the shortest route, only the
shortest one following cell centres.

**Why each argument matters.**

`max_climb` and `max_drop`: a cliff is not blocked. Both the top and the bottom
are perfectly open cells and the line between them is clear in exactly the sense
the corridor test means, so without limits the search walks around to the ramp
and smoothing then cuts straight up the cliff face.

`radius`: the corridor test otherwise asks whether the centre line fits, not the
body. A smoothed path will graze a corner the unit's shoulders cannot clear,
which looks like clipping and gets diagnosed as a collision bug.

`headings`: 0 leaves the result unconstrained, 4 permits cardinals only, 8 adds
true diagonals. Without this, a grid searched with `gmnav_neighbours.FOUR`
correctly returns a cardinal route and smoothing collapses it into one long
diagonal the unit cannot walk. Note that this constrains the **shaping**, not
the search, so the layout's neighbour set has to agree: setting 4 on an eight
direction grid does not give you cardinal movement, because the diagonals are
already in the route and smoothing can only remove waypoints.

With a heading constraint set, this also rewrites a staircase into the fewest
legal straight legs rather than merely refusing illegal shortcuts, which it does
by proposing a corner the search never visited and checking both legs the same
way a single leg is checked.

`profile`: without it, A\* routes carefully around expensive ground and smoothing
string pulls straight back through it, undoing every cost layer in your project.

**Refused on staggered and hex.** On those layouts a straight line in cell
coordinates says nothing reliable about whether a character could walk it, so
this returns without doing anything rather than returning a confidently wrong
answer. `gmnav_path_simplify` works everywhere.

**See also:** `gmnav_path_simplify`, `gmnav_path_curve`,
`gmnav_path_anchor_start`

---

### gmnav_path_simplify

**Syntax:**

```gml
gmnav_path_simplify(path, tolerance, max_climb, max_drop);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path, modified in place |
| tolerance | Real | Optional, default 0.01. How close to collinear counts |
| max_climb | Real | Optional. Largest rise |
| max_drop | Real | Optional. Largest fall |

**Returns:** N/A

**Example:**

```gml
// the safe fallback on a hex or staggered map
if (grid.layout.mode == gmnav_layout.ORTHO
||  grid.layout.mode == gmnav_layout.ISO_DIAMOND) {
    gmnav_path_smooth(path, climb, drop, radius);
}

gmnav_path_simplify(path, 0.01, climb, drop);
```

The above code smooths where smoothing is safe and simplifies everywhere.

The difference between the two is worth being clear about. Smoothing **changes
the shape** of the route, replacing runs of waypoints with straight lines that
cut corners the original did not. Simplify only removes waypoints that already
lie on a straight line between their neighbours, so the path it produces is
geometrically identical to the one it was given. That is why it is safe on every
layout: it cannot introduce a segment that clips anything, because it does not
introduce segments at all.

It is also much cheaper, and on a raw cell route it removes most of the
waypoints, which is most of the win for none of the risk.

The elevation limits are still needed, for a reason that is easy to miss: a ramp
seen from above is a straight line. Its waypoints are collinear in every
direction except the one that matters, so a purely geometric test deletes them
and the path silently loses the climb. Layer changes are preserved
unconditionally, since a lifted stair is nearly collinear on screen too.

**Note:** this clears `path.nodes`, because after simplifying the waypoints no
longer correspond one to one with cells. Run `gmnav_path_smooth` first if you
want both, and be aware that anything relying on the node list, such as scoped
repathing, will fall back to its conservative behaviour afterwards.

**See also:** `gmnav_path_smooth`, `gmnav_path_curve`

---

### gmnav_path_curve

**Syntax:**

```gml
gmnav_path_curve(path, mode, radius, samples, body, min_turn);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | The path, modified in place |
| mode | Enum | Optional, default `gmnav_curve.NONE` |
| radius | Real | Optional, default 16. Corner radius in pixels |
| samples | Integer | Optional, default 4. Points per arc |
| body | Real | Optional, default 0. Body radius |
| min_turn | Real | Optional, default 5. Degrees below which a joint is left alone |

**Returns:** N/A

**Example:**

```gml
// a vehicle with a turning radius
gmnav_path_curve(path, gmnav_curve.CORNER, 40, 5, agent.radius);
```

The above code rounds the corners of a path so something with momentum can
follow it. A path made of straight legs meeting at hard corners is an honest
description of a route and a poor description of movement: a vehicle has a
turning radius, a boat carries its heading, a character with a turn animation
needs frames to face a new direction.

**The modes.** `CORNER` rounds each turn to a radius and leaves straight legs
untouched, so a corridor still reads as a corridor and only the joints change.
This is what most games want. `SPLINE` runs a curve through every waypoint so
nothing stays straight, which suits things that never travel in straight lines
anyway: flying units, boats, camera paths. `NONE` is the default and changes
nothing, so adding the call to existing code is harmless until you ask for
something.

A spline passes through its waypoints but is not bounded by them, so it
overshoots at the ends of a sharp turn. That is inherent to the technique and
the main reason `CORNER` is the safer default.

**Everything generated is checked.** A rounded corner cuts across the inside of a
turn, which means it occupies ground the original path did not, and sometimes
that ground has a wall in it. Every segment the curve generates is tested
against the same geometry the search used, body radius included. A corner whose
arc would clip keeps its sharp corner; under `SPLINE` a segment that would clip
reverts to the straight line.

Expect the consequence: in tight terrain a curved path is only **partly** curved.
Corners in the open round nicely, corners in doorways stay sharp, and the same
call produces different amounts of smoothing in different parts of one map. That
is the check working, not the mode failing.

`radius` is clamped to half of each adjacent leg, so two corners close together
never consume the same segment and a short leg simply gets a tighter curve. You
can set it larger than your corridors without breaking anything.

**When not to.** Do not curve a path whose headings you constrained, since a
curve contains every heading and the two features answer opposite questions. In
a map that is mostly corridors most corners will refuse the arc anyway, so check
that it visibly helps before leaving it on. And if your movement code already
eases toward its target, as `gmnav_agent_update` does, you may already have a
curved trajectory from a cornered path, and curving as well gives you two
smoothing systems in series.

**Refused on staggered and hex**, for the same reason smoothing is.

**Note:** unlike `gmnav_path_simplify`, this keeps `path.nodes` intact, so scoped
repathing still has a cell route to test against.

**See also:** `gmnav_path_smooth`, `gmnav_agent_create`

---

## Cost Field Functions

Terrain cost describes the ground. It is a property of the map, the same for
everyone, and it does not change.

Most of what makes AI look thoughtful is not about the ground at all. It is
about things that move, things only some units care about, and things that are
true right now and will not be in ten seconds. An enemy that flanks instead of
charging, a wounded unit that takes the long way home to stay off open ground, a
scout that hugs cover while a berserker ignores it entirely.

None of that needs new pathfinding. It needs the search given a different set of
numbers, and cost fields are how you produce those cleanly.

A **layer** is one value per cell and nothing else. It knows nothing about the
terrain, nothing about who is reading it, and nothing about other layers. That
independence is the point: you can author threat without thinking about
territory, and territory without thinking about threat.

A **profile** blends layers with weights and flattens the result into a single
array. Weights live on the profile rather than the layer, which is what lets
three unit types share one danger map and disagree completely about it.

---

### gmnav_costlayer_create

**Syntax:**

```gml
gmnav_costlayer_create(grid, name);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| name | String | Optional. For your own bookkeeping |

**Returns:** Struct

**Example:**

```gml
danger    = gmnav_costlayer_create(grid, "turret fire");
territory = gmnav_costlayer_create(grid, "enemy ground");
noise     = gmnav_costlayer_create(grid, "how loud it is here");
```

The above code creates three independent layers. Each is authored by whoever
owns that concept, and every combination of them is a weight table rather than
new code.

Every cell starts at 0, and the array covers overlay cells as well as base
cells, so a bridge can carry a value independent of the road beneath it.

The name is never read by the framework. It is there so a layer is identifiable
when you are looking at one in the debugger.

**See also:** `gmnav_costlayer_set`, `gmnav_costprofile_create`

---

### gmnav_costlayer_set

**Syntax:**

```gml
gmnav_costlayer_set(layer, col, row, value);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| col | Integer | Column |
| row | Integer | Row |
| value | Real | New value |

**Returns:** Boolean, `false` if the cell is out of bounds

**Example:**

```gml
// mark the cells a guard can see
for (var _i = 0; _i < array_length(visible_cells); _i++) {
    var _c = visible_cells[_i][0];
    var _r = visible_cells[_i][1];

    gmnav_costlayer_set(danger, _c, _r, 6);
}
```

The above code writes a value into specific cells, which is the most direct way
to author a layer when you already know exactly which cells you mean.

This writes to **base** cells. An overlay cell shares its column and row with
whatever sits beneath it, so there is no way to address one here; use
`gmnav_costlayer_set_node` for those.

The value replaces whatever was there. It does not accumulate, unlike the
stamps, which combine with max.

**See also:** `gmnav_costlayer_set_node`, `gmnav_costlayer_stamp_radial`

---

### gmnav_costlayer_get

**Syntax:**

```gml
gmnav_costlayer_get(layer, col, row);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| col | Integer | Column |
| row | Integer | Row |

**Returns:** Real, 0 if out of bounds

**Example:**

```gml
// how exposed is the cell the unit is standing in?
var _cr = gmnav_layout_world_to_cell(layout, x, y);

if (gmnav_costlayer_get(danger, _cr[0], _cr[1]) > 4) {
    start_taking_cover();
}
```

The above code uses a navigation layer for something other than navigation,
which is worth doing. If your pathfinder knows a cell is dangerous, your
behaviour code may as well know too, and reading the same number keeps the two
consistent.

Base cells only, as with `gmnav_costlayer_set`.

**See also:** `gmnav_costlayer_get_node`

---

### gmnav_costlayer_set_node

**Syntax:**

```gml
gmnav_costlayer_set_node(layer, node, value);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| node | Integer | Node id, base or overlay |
| value | Real | New value |

**Returns:** Boolean, `false` if the node is out of range

**Example:**

```gml
// the bridge is exposed. The road underneath is not
var _ov = grid.overlay;

for (var _i = 0; _i < gmnav_overlay_count(_ov); _i++) {
    var _n = _ov.base + _i;

    if (gmnav_overlay_layer(_ov, _n) != 1) continue;

    gmnav_costlayer_set_node(danger, _n, 10);
}
```

The above code prices an entire raised surface without touching the ground below
it.

This is the only way to author cost on an overlay cell, because such a cell has
no unique column and row to address it by. The node form is also handy on base
cells when you already have a node from a search result and would rather not
convert it back to coordinates.

**Note:** the stamps, `gmnav_costlayer_stamp_radial` and
`gmnav_costlayer_stamp_path`, work in world space and only reach base cells. If
your map has bridges or cliff tops and you author all your hazards by stamping,
every raised surface will be silently free of danger and nothing will warn you.
The loop above is the workaround.

**See also:** `gmnav_costlayer_get_node`, `gmnav_overlay_count`

---

### gmnav_costlayer_get_node

**Syntax:**

```gml
gmnav_costlayer_get_node(layer, node);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| node | Integer | Node id, base or overlay |

**Returns:** Real, 0 if out of range

**Example:**

```gml
// how much danger did this route actually pick up?
var _total = 0;

for (var _i = 0; _i < array_length(path); _i++) {
    _total += gmnav_costlayer_get_node(danger, path[_i]);
}

show_debug_message("route exposure: " + string(_total));
```

The above code measures a route against a layer, which is the honest test of
whether a cost field is doing what you meant. A cautious unit's route should
accumulate close to nothing while a reckless one's picks up a great deal, and if
both come out the same then the weights are not where you think they are.

**Careful:** this reads the waypoints, and after smoothing those are the corners
rather than every cell the route crosses. To measure what the drawn line
actually passes through, sample along each segment instead.

**See also:** `gmnav_costlayer_set_node`

---

### gmnav_costlayer_clear

**Syntax:**

```gml
gmnav_costlayer_clear(layer);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |

**Returns:** N/A

**Example:**

```gml
// start the danger map fresh each time the alert level changes
gmnav_costlayer_clear(danger);

with (obj_turret) {
    gmnav_costlayer_stamp_radial(other.danger, x, y, range, 8, 2);
}

gmnav_costprofile_bake(soldier);
```

The above code rebuilds a whole layer from scratch, which is the simplest
approach when the set of sources changes rather than just their positions.

Clearing walks every cell, and rebaking afterwards walks every cell again, so
this is a level load or an occasional event rather than a per frame operation.
For something that moves continuously, use `gmnav_costlayer_clear_region` and
rebake only the rectangles involved.

**See also:** `gmnav_costlayer_clear_region`, `gmnav_costprofile_bake`

---

### gmnav_costlayer_clear_region

**Syntax:**

```gml
gmnav_costlayer_clear_region(layer, c1, r1, c2, r2, ov_layer);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| c1 | Integer | One corner column |
| r1 | Integer | One corner row |
| c2 | Integer | Other corner column |
| r2 | Integer | Other corner row |
| ov_layer | Integer | Optional, default 0. Which surface to clear |

**Returns:** N/A

**Example:**

```gml
// the turret moved. Erase where it was, stamp where it is
gmnav_costlayer_clear_region(danger, old_rect[0], old_rect[1],
                                     old_rect[2], old_rect[3]);

var _new = gmnav_costlayer_stamp_radial(danger, x, y, 200, 8, 2);

gmnav_costprofile_bake_region(soldier, old_rect[0], old_rect[1],
                                       old_rect[2], old_rect[3]);
gmnav_costprofile_bake_region(soldier, _new[0], _new[1], _new[2], _new[3]);

old_rect = _new;
```

The above code moves a threat affordably, and it is the pattern to internalise
for anything that moves continuously.

**Both rectangles, always.** Clear and rebake the area being vacated as well as
the area newly covered. Skip the old one and the previous threat stays burned
into the resolved array permanently, so your turret leaves a trail of phantom
danger behind it that nothing ever removes.

The saving scales with map size, which is the point. On a small map a stamp's
rectangle might be a third of the cells and the saving is modest. On a 500 by
500 map the same stamp is a fraction of a percent of a full rebake, which is the
difference between influence maps being a nice idea and being something you can
afford every frame.

**`ov_layer` selects which surface is cleared.** `0` clears base cells, `1` or
higher clears the overlay layer with that index. Note that the region is always
in cell coordinates; an overlay cell uses the same `(col, row)` as the base cell
it sits over, so the same rect applies to both surfaces. That means a single
rect is correct for both — you just have to call the function twice if you want
to clear both, once with `ov_layer` 0 and once with the layer you want.

Clearing an overlay surface does not touch the base cells underneath it, and
vice versa. That is the point of the argument, and it matches the separation
that already exists between `set` and `set_node`.

**See also:** `gmnav_costprofile_bake_region`, `gmnav_costlayer_stamp_radial`,
`gmnav_costlayer_stamp_path`

---

### gmnav_costlayer_stamp_radial

**Syntax:**

```gml
gmnav_costlayer_stamp_radial(layer, wx, wy, radius, peak, falloff, ov_layer);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| wx | Real | World x of the centre |
| wy | Real | World y of the centre |
| radius | Real | Reach in pixels |
| peak | Real | Value at the centre |
| falloff | Real | Optional, default 1. Falloff exponent |
| ov_layer | Integer | Optional, default 0. Which surface to paint |

**Returns:** Array, `[c1, r1, c2, r2]`, the cells actually written

**Example:**

```gml
// a turret covering the middle of the battlefield
var _rect = gmnav_costlayer_stamp_radial(danger, turret_x, turret_y, 200, 8, 2);

// the same stamp, painting the deck of a bridge instead of the road
var _deck_rect = gmnav_costlayer_stamp_radial(danger, turret_x, turret_y,
                                              200, 8, 2, 1);
```

The above code paints a blob of cost with the peak at the centre falling off
outward. A falloff of 1 is linear; 2 falls off faster near the edge, which reads
as a hot core with a soft fringe.

**`ov_layer` names which surface the stamp writes to.** `0` is the base grid,
which is what every call before this version did. `1` or higher writes cells on
that overlay layer instead, using the world positions the cells are actually
drawn at, so the radius is measured against the surface as you see it. The two
are entirely separate: a radial stamp over a bridge hits either the road or the
deck, not both. Call twice if you want both. The returned rectangle is the
bounding box of the cells actually written, on the surface you asked for.

**Stamps combine with max, not with plus.** Two turrets covering the same cell
make it dangerous, not twice as dangerous. That is deliberate: adding would mean
a cluster of five guards produces a hazard five times worse than any of them,
which grows without limit and swamps every other layer in the profile. It also
makes stamping idempotent, so restamping the same source in the same place
changes nothing and a missed clear does not compound frame after frame.

If you genuinely want additive behaviour, that is what separate layers are for.
Layers add to each other; stamps within a layer do not.

**Keep the peak modest.** Within about an order of magnitude of the base cost of
1. A search picks the cheaper of two routes, so a unit never partially avoids a
hazard, it flips at the point where the numbers cross, and what a designer tunes
is where that point sits. A peak of 40 against a base of 1 puts every reasonable
profile weight far past the flip, so turning the weight up and down appears to
do nothing at all.

The returned rectangle is the cells actually written, not the box scanned, which
is what makes region rebaking tight.

**See also:** `gmnav_costlayer_stamp_path`, `gmnav_costlayer_clear_region`,
`gmnav_costprofile_bake_region`

---

### gmnav_costlayer_stamp_path

**Syntax:**

```gml
gmnav_costlayer_stamp_path(layer, points, width, peak, falloff, ov_layer);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| points | Array | World space `[x, y]` pairs, in order |
| width | Real | Half width of the band, in pixels |
| peak | Real | Value on the centreline |
| falloff | Real | Optional, default 1. Falloff exponent |
| ov_layer | Integer | Optional, default 0. Which surface to paint |

**Returns:** Array, `[c1, r1, c2, r2]`, the cells actually written

**Example:**

```gml
// the stretch of lane the guard is about to walk
var _ahead = [[x, y], [x + lengthdir_x(180, dir), y + lengthdir_y(180, dir)]];
var _rect  = gmnav_costlayer_stamp_path(danger, _ahead, 56, 8, 1);

// the same band, painting a raised walkway instead of the ground
var _deck_rect = gmnav_costlayer_stamp_path(danger, _ahead, 56, 8, 1, 1);
```

The above code paints danger along the route a patrol is about to take rather
than around where it currently is. That difference is what separates units that
dodge where a guard is standing from units that get out of its way, which a
person watching would call anticipation. It costs nothing extra, since the
function takes a polyline either way.

Use this for anything linear: a road, a patrol route, a spreading fire, a
player's recent trail so pursuers spread out instead of following single file.
Approximating a line with a chain of radial stamps produces a lumpy field with
bulges at every sample point, and a bounding rectangle far larger than the band
itself, which makes region rebaking far more expensive than it needs to be.

Work follows the route rather than the bounding box of the whole thing, so a
long path across a map costs what its own length costs rather than what its
extent costs.

**`ov_layer` works exactly as it does on `stamp_radial`**, and the two branches
are implemented differently on purpose. The base branch iterates the polyline's
segments and finds the cells each one covers. The overlay branch iterates the
overlay's cells and finds the nearest segment to each one, which is cheaper when
the overlay is small relative to the map, and is the common case. Same result
either way.

Everything from `gmnav_costlayer_stamp_radial` applies: max combining, modest
peaks, and the returned rectangle being what was written. The rect is in cell
coordinates, so it works equally well as an argument to `clear_region` and
`bake_region` with the same `ov_layer` value.

**See also:** `gmnav_costlayer_stamp_radial`, `gmnav_costlayer_clear_region`,
`gmnav_costprofile_bake_region`

---

### gmnav_costprofile_create

**Syntax:**

```gml
gmnav_costprofile_create(grid, name);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| name | String | Optional. For your own bookkeeping |

**Returns:** Struct

**Example:**

```gml
berserker = gmnav_costprofile_create(grid, "berserker");
soldier   = gmnav_costprofile_create(grid, "soldier");
scout     = gmnav_costprofile_create(grid, "scout");
```

The above code creates three profiles that will read the same layers and
disagree about them.

A profile starts empty, which resolves to base terrain cost alone, so a profile
with no layers added behaves exactly as passing no profile at all.

Its resolved array covers overlay cells as well as base cells.

**See also:** `gmnav_costprofile_add`, `gmnav_costprofile_bake`

---

### gmnav_costprofile_add

**Syntax:**

```gml
gmnav_costprofile_add(profile, layer, weight);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |
| layer | Struct | The layer to add |
| weight | Real | Optional, default 1. How much this profile cares |

**Returns:** N/A

**Example:**

```gml
gmnav_costprofile_add(berserker, danger, 0);   // does not care at all
gmnav_costprofile_add(soldier,   danger, 1);   // cares normally
gmnav_costprofile_add(scout,     danger, 4);   // cares a great deal

gmnav_costprofile_bake(berserker);
gmnav_costprofile_bake(soldier);
gmnav_costprofile_bake(scout);
```

The above code is the whole of "make the AI look smart". Three unit types, one
shared danger map, three different opinions. When the turret moves you update one
layer and all three profiles pick up the change.

You wrote no flanking logic. There is no prefer-cover behaviour anywhere. There
is a number per cell and a weight per unit type, and the arc comes out of the
arithmetic.

**Careful:** this **appends**. Calling it twice with the same layer adds that
layer to the profile twice and the weights sum, which produces a profile that
cares twice as much as you asked and no error anywhere. To change an existing
weight, use `gmnav_costprofile_set_weight`.

A negative weight is legal and resolved cost still clamps at 1, so it makes
dangerous ground **ordinary** rather than attractive. Cost fields push; to pull a
unit toward something, seed it as a goal in a flow field.

**See also:** `gmnav_costprofile_set_weight`, `gmnav_costprofile_bake`

---

### gmnav_costprofile_set_weight

**Syntax:**

```gml
gmnav_costprofile_set_weight(profile, layer, weight);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |
| layer | Struct | A layer already in the profile |
| weight | Real | New weight |

**Returns:** Boolean, `false` if the layer is not in this profile

**Example:**

```gml
// the unit is wounded. It starts caring about danger
gmnav_costprofile_set_weight(soldier, danger, wounded ? 4 : 1);
gmnav_costprofile_bake(soldier);
```

The above code changes a unit type's temperament at runtime.

This is the function to reach for whenever a weight needs to change, rather than
calling `gmnav_costprofile_add` again, which would append a duplicate.

Note that changing a weight marks the profile dirty and requires a full rebake,
since every cell's resolved value depends on it. That is a whole-map pass, so it
belongs on an event rather than in a Step event. If you need two temperaments
available at once, bake two profiles at level load and swap which one the unit
points at instead.

**See also:** `gmnav_costprofile_add`, `gmnav_costprofile_bake`

---

### gmnav_costprofile_remove

**Syntax:**

```gml
gmnav_costprofile_remove(profile, layer);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |
| layer | Struct | The layer to remove |

**Returns:** Boolean, `false` if the layer is not in this profile

**Example:**

```gml
// the war is over. Nobody cares about enemy territory any more
gmnav_costprofile_remove(soldier, territory);
gmnav_costprofile_bake(soldier);
```

The above code drops a layer from a profile entirely.

Setting the weight to 0 achieves the same routing result and is cheaper to
reverse, so prefer that for something temporary. Removing is for a layer you are
about to destroy or one that will never be relevant again, since it also stops
the profile watching that layer for changes.

**See also:** `gmnav_costprofile_set_weight`

---

### gmnav_costprofile_bake

**Syntax:**

```gml
gmnav_costprofile_bake(profile);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |

**Returns:** N/A

**Example:**

```gml
gmnav_costprofile_add(soldier, danger,    1);
gmnav_costprofile_add(soldier, territory, 1);
gmnav_costprofile_bake(soldier);
```

The above code flattens every layer and weight into one array.

**Why this exists rather than resolving on demand.** You could compute cost when
the search asks for it: loop the layers, multiply each by its weight, add them
up. It works, it is simple, and it puts a loop over every layer **inside the
innermost loop of A\***, which runs millions of times. A three layer profile
would make every path in your game roughly four times slower.

Baking walks every cell once, combines base terrain cost with each weighted
layer, and writes the result into a flat array. The search then does exactly one
array lookup per neighbour, the same as it would with no profile at all. A twelve
layer profile costs the search precisely what no profile costs; the work moved
to bake time, where you control when it happens.

Overlay cells are seeded from their own base cost and then weighted layers are
applied, so a deck is priced independently of the ground beneath it. Resolved
cost clamps at 1 throughout, for the same reason terrain cost does.

**See also:** `gmnav_costprofile_bake_if_dirty`, `gmnav_costprofile_bake_region`

---

### gmnav_costprofile_is_dirty

**Syntax:**

```gml
gmnav_costprofile_is_dirty(profile);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_costprofile_is_dirty(soldier) && !in_combat) {
    gmnav_costprofile_bake(soldier);
}
```

The above code defers a full rebake to a quiet moment.

A profile goes dirty when any of its layers changes, when a weight changes, or
when the **grid's** terrain changes. That last one catches a case people miss:
block a wall or change a terrain cost, and every profile over that grid needs
rebaking too, because base cost is part of what they bake.

**See also:** `gmnav_costprofile_bake_if_dirty`

---

### gmnav_costprofile_bake_if_dirty

**Syntax:**

```gml
gmnav_costprofile_bake_if_dirty(profile);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |

**Returns:** Boolean, whether a bake happened

**Example:**

```gml
// Step event. Costs nothing on the frames nothing changed
gmnav_costprofile_bake_if_dirty(soldier);
```

The above code keeps a profile current without you tracking what changed.

Safe to call every frame, since it does nothing when the profile is clean. What
it does **not** do is spread the work: when a bake is needed it happens entirely
inside this call, which on a large map is a visible frame cost. For anything
changing continuously, `gmnav_costprofile_bake_region` is the answer.

**See also:** `gmnav_costprofile_bake`, `gmnav_costprofile_bake_region`

---

### gmnav_costprofile_bake_region

**Syntax:**

```gml
gmnav_costprofile_bake_region(profile, c1, r1, c2, r2, ov_layer);
```

| Argument | Type | Description |
|---|---|---|
| profile | Struct | The profile |
| c1 | Integer | One corner column |
| r1 | Integer | One corner row |
| c2 | Integer | Other corner column |
| r2 | Integer | Other corner row |
| ov_layer | Integer | Optional, default 0. Which surface to bake |

**Returns:** N/A

**Example:**

```gml
// three unit types read the same layer, so all three need both rectangles
var _profiles = [berserker, soldier, scout];

for (var _i = 0; _i < 3; _i++) {
    gmnav_costprofile_bake_region(_profiles[_i],
        old_rect[0], old_rect[1], old_rect[2], old_rect[3]);

    gmnav_costprofile_bake_region(_profiles[_i],
        new_rect[0], new_rect[1], new_rect[2], new_rect[3]);
}

// and if the change was on a bridge deck, the same rect with ov_layer 1
for (var _i = 0; _i < 3; _i++) {
    gmnav_costprofile_bake_region(_profiles[_i],
        old_rect[0], old_rect[1], old_rect[2], old_rect[3], 1);

    gmnav_costprofile_bake_region(_profiles[_i],
        new_rect[0], new_rect[1], new_rect[2], new_rect[3], 1);
}
```

The above code updates every profile that reads a moving layer. This is what
makes influence maps affordable rather than a nice idea.

**`ov_layer` matches the argument on the layer functions.** After stamping or
clearing an overlay layer with `ov_layer` set, call this with the same value and
the same rect to refresh the profile's resolved values for that surface. Without
it, the profile still holds the old resolved values on that layer, and searches
will see stale costs. A stamp on a deck is invisible to the search until this
runs with `ov_layer` set to that deck's layer.

**Region baking is per profile.** A profile that misses the update is not stale
in any way the framework can tell you about, it simply holds an older world and
routes accordingly. If one unit type is behaving as though a threat has not
moved, this is the first thing to check.

**It does not clear the dirty flag**, deliberately. It only guarantees the
rectangle you named, and the rest of the map may still be out of date. Pretending
otherwise would hide bugs, so `gmnav_costprofile_is_dirty` keeps returning `true`
until a full bake happens.

**See also:** `gmnav_costlayer_clear_region`, `gmnav_costprofile_bake`,
`gmnav_costlayer_stamp_radial`

---

## Flow Field Functions

When a thousand units chase the same target, running a thousand searches is the
wrong shape of solution. Every one of them searches the same map toward the same
destination and computes very nearly the same answer as the thousand beside it.

A flow field turns that inside out. Instead of searching from each agent inward
to the goal, it spreads outward from the goal once and records how far every
cell is from it. An agent then does not search at all: it looks at its own cell,
reads a direction, and steps. That is one array lookup and a multiply.

The rule of thumb is **many agents, few destinations, stable goals**. Tower
defense creeps, a fleeing crowd, an RTS move order, zombies converging on a
player. Below roughly thirty agents individual searches are cheaper, and a dozen
guards patrolling to a dozen different waypoints is not a flow field problem at
all.

---

### gmnav_flowfield_create

**Syntax:**

```gml
gmnav_flowfield_create(grid, profile, max_climb, max_drop);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| profile | Struct | Optional. Cost profile the field is built under |
| max_climb | Real | Optional. Largest rise a unit reading this field can take |
| max_drop | Real | Optional. Largest fall |

**Returns:** Struct

**Example:**

```gml
field = gmnav_flowfield_create(grid, soldier, 1, 3);
```

The above code creates a field that respects a cost profile and a unit's
elevation limits.

A field bakes in one profile and one set of limits, which is the main thing that
decides whether flow fields suit your game. Chapter 6's berserker and scout
disagree about danger, so they need separate fields, and three unit types with
different weights means three builds. At that point the economics shift back
toward individual searches.

**Elevation is tested in reverse while building**, because a field is built
outward from the goal but walked inward toward it. A field built to a goal on
top of a cliff is not the same field as one built to a goal at its foot, even on
identical terrain. Build the field for the journey you mean.

Arrays cover overlay cells as well as base cells, and grow if an overlay is
attached after the field was created.

**See also:** `gmnav_flowfield_build`, `gmnav_costprofile_create`

---

### gmnav_flowfield_build

**Syntax:**

```gml
gmnav_flowfield_build(field, goal_nodes, max_dist);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| goal_nodes | Integer or Array | One node id, or several |
| max_dist | Real | Optional. Stop expanding past this distance |

**Returns:** Boolean, whether any goal was usable

**Example:**

```gml
// everyone runs to their own nearest exit
gmnav_flowfield_build(field, [exit_north, exit_south, exit_east]);

// or bound the build, for a field that follows the player
gmnav_flowfield_build(field, player_node, 25);
```

The above code shows the two things that make fields worth using.

**Several goals cost almost nothing over one.** Each cell records the distance to
the **nearest** seeded goal and the direction points that way, so the map
partitions itself into catchment areas along the natural watersheds. Every agent
flows to whichever goal is cheapest for it. "Run to the nearest exit", "retreat
to the closest friendly spawn", "route to whichever repair station is free" all
become one pass and an array, where three separate fields would have cost three
full builds and then needed per agent logic to choose between them.

**Capping bounds the work.** An uncapped field expands over the entire reachable
map, which is often more than you need. Enemies chasing a player only need
directions within some radius; beyond that they can idle or fall back to A\*.
Cells outside the cap report `infinity` from `cost_at` and `false` from
`is_reachable`, the same as genuinely unreachable ones, so your code needs no
special case. On a large map the saving is large, because a fixed radius covers
a shrinking fraction of a growing map.

This runs both passes to completion, which is right at level load and wrong mid
combat. Use `gmnav_flowfield_begin` and `gmnav_flowfield_step` for anything
large.

**See also:** `gmnav_flowfield_begin`, `gmnav_flowfield_sample`

---

### gmnav_flowfield_begin

**Syntax:**

```gml
gmnav_flowfield_begin(field, goal_nodes, max_dist);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| goal_nodes | Integer or Array | One node id, or several |
| max_dist | Real | Optional. Distance cap |

**Returns:** Boolean, whether any goal was usable

**Example:**

```gml
gmnav_flowfield_begin(field, goal_node);
building = true;
```

The above code starts a sliced build. Nothing is computed yet; call
`gmnav_flowfield_step` each frame until it finishes.

The field keeps serving its **previous** contents while a new build is in
progress, so agents reading it do not stall. They will follow slightly stale
directions for a few frames, which almost always looks better than freezing.

**See also:** `gmnav_flowfield_step`, `gmnav_flowfield_build`

---

### gmnav_flowfield_step

**Syntax:**

```gml
gmnav_flowfield_step(field, budget);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| budget | Integer | Optional. Work allowed this call |

**Returns:** Enum, a `gmnav_state` member

**Example:**

```gml
if (building) {
    if (gmnav_flowfield_step(field, 2000) == gmnav_state.FOUND) {
        building = false;
    }
}
```

The above code spreads a build across frames.

Both passes slice. **Pass one** is Dijkstra from the goal with no heuristic at
all, since a heuristic biases a search toward one destination and here you want
every cell, and it touches only reachable cells. **Pass two** walks every cell in
the grid, reachable or not, and writes the direction pointing at whichever
neighbour has the lowest distance.

The second pass is the expensive half, which surprises people. On a 500 by 500
map it is 250,000 cells with an eight neighbour scan each, regardless of how
much of the map is actually walkable.

**See also:** `gmnav_flowfield_begin`, `gmnav_flowfield_is_ready`

---

### gmnav_flowfield_is_ready

**Syntax:**

```gml
gmnav_flowfield_is_ready(field);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_flowfield_is_ready(field)) {
    var _d = gmnav_flowfield_sample(field, x, y);
    x += _d[0] * spd;
    y += _d[1] * spd;
}
```

The above code waits for a field before using it.

Sampling an unfinished field is safe and returns whatever it currently holds,
which during a rebuild is the previous contents, so this check is about
correctness of behaviour rather than avoiding an error.

**See also:** `gmnav_flowfield_step`, `gmnav_flowfield_is_stale`

---

### gmnav_flowfield_is_stale

**Syntax:**

```gml
gmnav_flowfield_is_stale(field);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_flowfield_is_stale(field) && !building) {
    gmnav_flowfield_begin(field, goal_node);
    building = true;
}
```

The above code rebuilds when the world has moved underneath a field.

**Flow fields do not repair themselves.** A field built before an edit still
describes the old world, arrows and all, and nothing will fix it unless you ask.
This is where fields earn their reputation for being awkward in destructible
games: rebuilding one is far more expensive than repathing a single agent, so a
map that changes every few seconds shifts the economics back toward individual
searches.

Note the `building` guard. Without it, a map that changes constantly restarts
the build every frame and it never completes.

**See also:** `gmnav_flowfield_begin`, `gmnav_grid_changed_since`

---

### gmnav_flowfield_sample

**Syntax:**

```gml
gmnav_flowfield_sample(field, x, y, layer);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| x | Real | World x |
| y | Real | World y |
| layer | Integer | Optional, default 0. Which surface to ask about |

**Returns:** Array, `[dx, dy]`, normalised. `[0, 0]` if unreachable

**Example:**

```gml
// the entire per agent cost of a flow field
var _d = gmnav_flowfield_sample(field, x, y, my_layer);

x += _d[0] * spd;
y += _d[1] * spd;
```

The above code is the whole of it. No ticket, no scheduler, no waiting.

Directions are computed in **world space**, by converting both cells to pixel
coordinates and subtracting, rather than from the raw cell offset. On a square
grid those give the same answer so it looks like a pointless indirection. On
isometric or hex it very much is not: a cell offset of `(1, 0)` is not a
rightward move on screen, and deriving the vector from the offset would send
every agent in the wrong direction on any non-orthogonal layout while the debug
overlay looked entirely correct.

Pass the unit's layer on a map with raised surfaces, or a unit on a bridge reads
the road beneath it.

**Careful:** a direction vector cannot express a change of surface. Where a step
crosses from one layer to another, sampling gives you a heading toward a place
the unit cannot reach by moving in that direction. Use `gmnav_flowfield_next`
to detect those.

**See also:** `gmnav_flowfield_next`, `gmnav_flowfield_cost_at`

---

### gmnav_flowfield_next

**Syntax:**

```gml
gmnav_flowfield_next(field, node);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| node | Integer | Node id, base or overlay |

**Returns:** Integer node id, or `GMNAV_NO_NODE` at a goal or unreached cell

**Example:**

```gml
// follow the field, but walk stairs properly
var _here = gmnav_grid_world_to_node(grid, x, y, my_layer);
var _next = gmnav_flowfield_next(field, _here);

if (_next != GMNAV_NO_NODE) {
    var _nl = gmnav_grid_node_layer(grid, _next);

    if (_nl != my_layer) {
        // this step changes surface. Walk to the node itself
        my_layer = _nl;
        seek_node(_next);
    } else {
        var _d = gmnav_flowfield_sample(field, x, y, my_layer);
        x += _d[0] * spd;
        y += _d[1] * spd;
    }
}
```

The above code is the pattern for following a field on a map with bridges: use
the cheap vector on ordinary ground, and walk to the node itself when the step
crosses layers.

This tells you **which node** a cell steps to rather than which direction, so a
layer transition is a fact rather than something inferred from a heading. It is
also useful on flat maps for verification, since walking `next` from any cell
should always reach a goal and never loop.

**See also:** `gmnav_flowfield_sample`, `gmnav_grid_node_layer`

---

### gmnav_flowfield_cost_at

**Syntax:**

```gml
gmnav_flowfield_cost_at(field, x, y, layer);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| x | Real | World x |
| y | Real | World y |
| layer | Integer | Optional, default 0 |

**Returns:** Real, or infinity if unreachable

**Example:**

```gml
// who is closest to the objective? Decide who reinforces and who retreats
var _mine = gmnav_flowfield_cost_at(field, x, y);

if (_mine < 20)      role = "defend";
else if (_mine < 60) role = "reinforce";
else                 role = "hold position";
```

The above code turns a navigation query into a behaviour decision.

This is more useful than it looks, and it is the answer to "can cost attract".
It is a **real travel cost** with walls, terrain and danger all accounted for,
available for every unit on the map at one array lookup, which makes it a far
better input to a decision than straight line distance. A unit twenty pixels
from the objective on the other side of a wall is not close to it.

Build one field seeded at every heal zone, pickup or objective and each unit can
read its own true cost to the nearest one without running any searches at all.
Whether that cost is worth paying is your game's decision; the framework prices
it.

**See also:** `gmnav_flowfield_is_reachable`, `gmnav_path_get_length`

---

### gmnav_flowfield_is_reachable

**Syntax:**

```gml
gmnav_flowfield_is_reachable(field, x, y, layer);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The field |
| x | Real | World x |
| y | Real | World y |
| layer | Integer | Optional, default 0 |

**Returns:** Boolean

**Example:**

```gml
// do not spawn anything that cannot get to the objective
if (gmnav_flowfield_is_reachable(field, spawn_x, spawn_y)) {
    instance_create_layer(spawn_x, spawn_y, "Units", obj_creep);
}
```

The above code validates a spawn point against the map's actual connectivity,
which catches a level authoring mistake before it becomes a unit standing still
forever.

Cells outside a distance cap report `false`, the same as genuinely unreachable
ones. That is deliberate so your code needs no special case, but it means this
answers "can it get there **given this field**" rather than "does a route exist
at all". On a capped field they are different questions.

**See also:** `gmnav_flowfield_cost_at`, `gmnav_debug_draw_reach`

---

## Agent Functions

An agent wraps a path with steering, arrival and optional local avoidance.

It writes a desired velocity and **does not move your instances**. Your game
already has movement and collision, and a navigation library that moved things
directly would be a second movement system racing the first: your collision
pushes the character out of a wall, the library puts it back, and you get jitter
that is genuinely unpleasant to debug. By proposing a velocity and stopping,
GMNav stays advisory. You can clamp it, scale it, ignore it while the character
is stunned, or run it through `move_and_collide`.

Everything an agent does is a public call. It stores preferences and forwards
them to the framework functions that do the work; it invents nothing. A project
writing its own agent class loses no capability.

---

### gmnav_agent_create

**Syntax:**

```gml
gmnav_agent_create(sched, x, y, radius, speed);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | Scheduler it requests paths from |
| x | Real | Starting world x |
| y | Real | Starting world y |
| radius | Real | Optional, default 8. Body radius |
| speed | Real | Optional, default 2. Units per frame |

**Returns:** Struct

**Example:**

```gml
// Create event
agent = gmnav_agent_create(sched, x, y, 8, 2.5);

agent.profile    = soldier;
agent.need_clear = gmnav_clearance_for_radius(grid, 8);
agent.max_climb  = 1;
agent.max_drop   = 3;
agent.headings   = 0;
```

The above code creates an agent and tells it everything about the unit it
represents. Those fields are forwarded on every request and to every shaping
pass, so setting them once here is enough.

The radius does three jobs: local avoidance, arrival distance, and the body
check during smoothing that stops a shortcut grazing a corner the unit's
shoulders cannot clear.

All fields are writable at any time. Changing `speed` mid journey is fine;
changing `profile` or `need_clear` affects the next request rather than the
current path.

**See also:** `gmnav_agent_goto`, `gmnav_agent_update`

---

### gmnav_agent_goto

**Syntax:**

```gml
gmnav_agent_goto(agent, gx, gy, priority, goal_layer);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |
| gx | Real | World x of the goal |
| gy | Real | World y of the goal |
| priority | Enum | Optional, default `gmnav_priority.NORMAL` |
| goal_layer | Integer | Optional, default 0. Which surface the goal is on |

**Returns:** Boolean, `false` if either end could not be resolved

**Example:**

```gml
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        var _p = gmnav_grid_node_to_world(grid, _n);

        gmnav_agent_goto(agent, _p[0], _p[1], gmnav_priority.NORMAL,
                         gmnav_grid_node_layer(grid, _n));
    }
}
```

The above code is the standard click to move handler for a map with raised
surfaces. Note the layer being passed: without it the agent resolves the
destination at ground level and walks **under** the bridge it was told to walk
onto.

The goal layer is remembered, so a repath later asks for the same surface rather
than whatever happens to be at ground level.

This cancels any request already in flight, clears the arrived and failed
latches, and requests a new path. When it arrives the agent smooths it, anchors
both ends, curves it if asked, and starts steering. You never touch a ticket.

Returning `false` means the framework could not turn your coordinates into
nodes, which is different from failing to find a route. A route that turns out
not to exist reports through `gmnav_agent_failed` later.

**See also:** `gmnav_agent_failed`, `gmnav_agent_arrived`

---

### gmnav_agent_update

**Syntax:**

```gml
gmnav_agent_update(agent, neighbours);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |
| neighbours | Array | Optional. Nearby agents to push away from |

**Returns:** N/A

**Example:**

```gml
// Step event
var _near = [];

with (obj_unit) {
    if (id != other.id && point_distance(x, y, other.x, other.y) < 64) {
        array_push(_near, agent);
    }
}

gmnav_agent_update(agent, _near);

x += agent.vx;
y += agent.vy;
agent.x = x;
agent.y = y;
```

The above code updates an agent and applies its velocity. Note the last two
lines: the agent needs telling where the unit actually ended up, since your
collision may not have let it go where it wanted.

Each call collects a resolved ticket if one arrived, repaths if a change
landed on the part of the route still to walk, advances waypoints, and writes
`vx` and `vy`. It does **not** write `x` or `y`.

**Local avoidance is opt-in.** The `neighbours` argument is what turns it on.
Pass `undefined` and the avoidance block is skipped entirely — the agent
follows its path with no awareness of anything around it. This is why the
demo's click-to-move code sometimes looks like the agents are walking through
each other: the demo is passing a neighbour list, but if it is not, they
genuinely have no interaction.

**The mode is chosen per agent.** Set `agent.avoid_mode` to `BASIC`,
`CONTEXT`, or `FOLLOW`. See the Avoidance section for what each mode does and
what the per-agent tuning fields are.

**The path always wins.** The push returned by the avoidance model is
projected onto the plane perpendicular to the desired direction, so whichever
part of it opposes the path is stripped before being applied. An agent can be
steered sideways or slowed down by a crowd, but it cannot be pushed backward
along its own path. This is what stops a crowd from freezing an agent in
place — before this rule existed, a ring of neighbours could sum to a push
exactly opposite the goal and produce zero net velocity.

**Local avoidance is separation, not reciprocal avoidance.** It stops crowds
stacking into one pixel, which is what most games need. It will not resolve
two agents walking directly into each other in a one tile corridor: both push
symmetrically, both stall, and neither yields. If your game has narrow
corridors and two way traffic, plan for that at the design level with wider
passages, one way routes, or letting agents pass through each other.

It also does not know about walls in BASIC or FOLLOW mode. When a crowd
compresses against geometry it pushes bodies into walls and your movement code
absorbs that. CONTEXT does probe for walls, and is the mode to reach for when
this matters.

**See also:** `gmnav_agent_create`, `gmnav_scheduler_update`

---

### gmnav_agent_stop

**Syntax:**

```gml
gmnav_agent_stop(agent);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |

**Returns:** N/A

**Example:**

```gml
if (stunned) {
    gmnav_agent_stop(agent);
}
```

The above code halts an agent.

Drops the goal, cancels any request in flight, and clears the path. Velocity
decays rather than cutting to zero, so the unit slows over a few frames instead
of stopping dead.

Clears both the arrived and failed latches, so a unit that had arrived no longer
reports so afterwards.

**See also:** `gmnav_agent_goto`

---

### gmnav_agent_has_path

**Syntax:**

```gml
gmnav_agent_has_path(agent);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |

**Returns:** Boolean

**Example:**

```gml
// play a walk animation only while actually travelling
sprite_index = gmnav_agent_has_path(agent) ? spr_walk : spr_idle;
```

The above code uses path possession for presentation, which is what it is good
for.

**Careful:** this is not a substitute for `gmnav_agent_arrived`. The path is
cleared on the same frame the journey completes, so code watching this to detect
arrival misses the moment entirely and sees only that the agent stopped having a
path, which is also true when it failed or was stopped.

**See also:** `gmnav_agent_arrived`, `gmnav_agent_failed`

---

### gmnav_agent_arrived

**Syntax:**

```gml
gmnav_agent_arrived(agent);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |

**Returns:** Boolean

**Example:**

```gml
// a patrol route, in one if
if (gmnav_agent_arrived(agent)) {
    patrol_index = (patrol_index + 1) mod array_length(patrol_points);

    var _p = patrol_points[patrol_index];
    gmnav_agent_goto(agent, _p[0], _p[1]);
}
```

The above code is a complete patrol loop. That it is this short is the point of
the latch.

The flag stays `true` until the next `goto` or `stop`, so you can ask whenever
suits you rather than catching a single frame. It is specifically **not** derived
from whether the agent currently has a path, because the path is cleared on the
same frame the journey completes.

Arrival itself is governed by two distances on the agent. `arrive_dist`, 24 by
default, is where it starts easing off. `reach_dist`, 4 by default, is close
enough to count as done.

**Careful:** if a unit cannot physically get within `reach_dist` of its goal,
because its body is stopped by a wall first, it never latches and keeps pushing.
Raise `reach_dist` past the unit's radius, or validate goals against the body
with `gmnav_clearance_nearest`.

**See also:** `gmnav_agent_failed`, `gmnav_clearance_nearest`

---

### gmnav_agent_failed

**Syntax:**

```gml
gmnav_agent_failed(agent);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_agent_failed(agent)) {
    // no route. Decide what that means for this unit
    if (can_attack_obstacle) attack_nearest_wall();
    else                     give_up_and_hold();
}
```

The above code handles a refusal, which is a normal outcome rather than an
error, especially on maps with size limits or one way terrain.

Latched like `arrived` and cleared by the next `goto` or `stop`. Without it a
failed request and a completed journey look identical, since both end with no
goal and no ticket, and a unit that quietly stops for no visible reason is a
confusing thing to debug.

GMNav can tell you a route is impossible. It cannot tell you what to do about
it, and that decision belongs in your game: wait, attack the barricade, pick a
different objective, shout for help.

**See also:** `gmnav_agent_arrived`, `gmnav_clearance_nearest`

---

### gmnav_agent_layer

**Syntax:**

```gml
gmnav_agent_layer(agent);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |

**Returns:** Integer, 0 for the base grid

**Example:**

```gml
// draw units on the bridge above units on the road
depth = -y - gmnav_agent_layer(agent) * 1000;
```

The above code uses the agent's surface to sort it into the right drawing order,
which is the usual reason your game needs to know.

The agent tracks this itself as it crosses links, so you do not need to maintain
it. It is also what gets passed to the scheduler when the agent repaths, which
is why an agent on a bridge asks for a route from the bridge rather than from
the road beneath it.

**See also:** `gmnav_grid_node_layer`, `gmnav_agent_goto`

---

## Avoidance

Local avoidance steers agents away from each other, and in one of the modes
away from walls. It is separate from pathfinding — the search decides which
route, avoidance decides how the agent moves along it. A path can be perfectly
optimal and still produce a crowd that jitters, stalls, or shoves itself into
a doorway. The avoidance model is what decides how it looks in motion.

Three models ship with the framework. They share the same API — the agent's
`avoid_mode` field selects which one runs — and every behaviour that used to
be a hardcoded constant is now a per-agent field, so different units in the
same crowd can react to each other differently.

Every mode returns a push vector and a speed scale. The push is added to the
desired direction, with the part that opposes the path stripped out. The scale
multiplies the desired speed, which is how FOLLOW slows a crowd into a queue
without moving anyone off their path.

### The three modes

### BASIC

The default. Agents within range push each other apart. The push is a
separation force, strongest at contact and falling off with distance, and the
sum is normalised to one unit before being applied.

BASIC is cheap, correct, and open ground looks fine. At a chokepoint it
becomes chaotic — agents press into walls, get shoved off their path by
neighbours behind them, and pass through each other in tight corridors. That
is its documented behaviour, not a bug. If you need a crowd that files through
a door instead of fighting for it, use FOLLOW.

### CONTEXT

Probes 16 directions around the agent and scores each for three things:

- how well it points toward the goal
- how much neighbour danger is in that direction
- whether it faces a wall

The best-scoring direction wins, and the push is the difference between that
direction and the desired one. An agent with a wall dead ahead is pushed
sideways. An agent with a neighbour dead ahead is pushed around them. Neither
case is hardcoded.

Handles corners and doorways because the wall check is a full line test, not
a point sample. Costs more than BASIC — every probe runs a short supercover
walk against the grid.

### FOLLOW

Queue formation. The agent looks for neighbours directly ahead in a narrow
cone and scales its speed down based on the tightest gap it sees. Nothing is
pushed off the path — the agent just moves slower when someone is in front of
it. A crowd files naturally behind its leader.

Two agents side by side, both heading the same direction, ignore each other.
Only the cone ahead counts.

The separation force is still there, but weaker than BASIC's and only active
when bodies overlap. Lower `follow_sep` further for a patient queue, raise it
for a crowd that jostles.

### Choosing a mode

If you have to pick one, FOLLOW handles the widest range of situations
without embarrassing itself. BASIC is right for open spaces and large crowds
where the extra cost of CONTEXT or FOLLOW is not worth it. CONTEXT is right
for a small number of units that need to steer around walls and each other
precisely, and can afford the cost.

The three modes can be mixed in one crowd. A tower defense might use BASIC
for its two hundred creeps and CONTEXT for the single boss.

### Per-agent fields

Every field defaults to something reasonable, so an agent works without
setting anything. All of them are writable at any time, and take effect on
the next `gmnav_agent_update`.

| Field | Default | Used by | Description |
|---|---|---|---|
| `avoid_mode` | `gmnav_avoid.BASIC` | all | Which model runs |
| `avoid_str` | 1.0 | all | Overall strength multiplier. 0 disables avoidance |
| `avoid_range` | 3.0 | all | Reach in multiples of the agent's radius |
| `basic_clear_div` | 3.0 | BASIC | Clearance that produces a full-strength push |
| `basic_clear_min` | 0.15 | BASIC | Floor on the clearance scale |
| `basic_open_min` | 0.2 | BASIC | Same floor for the fallback when clearance was not built |
| `cs_probes` | 16 | CONTEXT | How many directions are sampled |
| `cs_wall_weight` | 2.0 | CONTEXT | How hard a wall rejects a direction |
| `cs_wall_range` | 2.5 | CONTEXT | How far ahead a probe looks for a wall, in radius units |
| `cs_danger_weight` | 1.5 | CONTEXT | How much a blocked neighbour penalises a probe |
| `follow_gap` | 1.6 | FOLLOW | Full speed at this gap, in radius-sum units |
| `follow_min` | 0.9 | FOLLOW | Hard stop just below this gap |
| `follow_floor` | 0.15 | FOLLOW | Slowest the queue can go. Zero deadlocks |
| `follow_cone` | 0.4 | FOLLOW | Half-width of the ahead cone |
| `follow_sep` | 0.3 | FOLLOW | Separation strength when bodies overlap |
| `follow_sep_range` | 1.5 | FOLLOW | How close before separation kicks in |

### Avoidance and the path

When the framework combines the push with the desired direction, it strips
whatever part of the push points backward along the path. The path always
wins — avoidance can steer an agent sideways, but it can never stop one dead.
Without this, a crowd pressing from behind can cancel an agent's forward
motion entirely, and the agent stands frozen with a valid path and no visible
reason.

The upshot is that a crowded agent moves slower along its path than a lone
one, and may drift sideways into a lane that has less congestion, but it
never gives up on reaching its goal.

### The neighbour list

Avoidance requires a neighbour list. `gmnav_agent_update(agent, neighbours)`
only runs the avoidance block when `_neighbours` is not `undefined`, and
silently skips it otherwise.

The framework does not keep a spatial index. It could, but your game almost
certainly already has one, and a navigation library maintaining a second one
in parallel would be a source of bugs rather than a convenience. So you supply
the list.

A neighbour only needs three fields: `x`, `y`, and `radius`. Anything with
those three works, so an agent can be a `gmnav_agent`, a game object, or a
bare struct.

---

## Platformer Functions

Side view connectivity is not grid adjacency. Two ledges can touch on screen and
be unreachable from each other; two ledges far apart can be connected perfectly
well. Whether you can get from one to the other depends on gravity, jump
velocity, run speed and the shape of everything in between.

So GMNav does not guess. It simulates your character's actual jump arcs against
your actual collision data and keeps the ones that land. A jump link exists in
the graph only because a simulated character made that jump.

Platformer graphs require an `ORTHO` layout.

---

### gmnav_movement_create

**Syntax:**

```gml
gmnav_movement_create(gravity, jump_vel, run_speed, max_fall, width, height, air_speed, jump_levels, jump_bias);
```

| Argument | Type | Description |
|---|---|---|
| gravity | Real | Added to vertical velocity each frame |
| jump_vel | Real | Jump velocity at full strength, positive |
| run_speed | Real | Horizontal speed on the ground |
| max_fall | Real | Terminal fall speed |
| width | Real | Character width |
| height | Real | Character height |
| air_speed | Real | Optional, defaults to `run_speed` |
| jump_levels | Integer | Optional, default 3. Jump strengths sampled |
| jump_bias | Real | Optional, default 1.15. Multiplier on jump link costs |

**Returns:** Struct

**Example:**

```gml
move = gmnav_movement_create(0.5, 12, 3, 12, 20, 44, 4, 7);
```

The above code describes a character with gravity 0.5, a jump velocity of 12, a
run speed of 3, terminal fall 12, a 20 by 44 body, air speed 4 and seven sampled
jump strengths.

**These must be your player controller's real numbers.** Everything the bake
produces depends on them, and the framework has no way to check. If `jump_vel`
is even slightly generous the graph contains links your character physically
cannot traverse, and an agent will walk to a ledge, jump, miss, land, walk back
and try again forever. That failure looks like a pathfinding bug and is a data
entry mistake.

**`air_speed` defaults to `run_speed`, and that default is often wrong.** At the
default the character drifts sideways in flight exactly as fast as it walks,
which makes long diagonal jumps impossible and can quietly turn a platform into
a one way trap: reachable coming down, unreachable going back up, with nothing
in your level saying so. Most platformers want this at or above `run_speed`.

**`jump_levels` controls arc quality, not just variety.** It is how many jump
strengths get sampled between half power and full. The default of 3 is cheap but
coarse, and arcs overshoot on gaps that fall near a sampling boundary. Seven to
nine gives noticeably flatter, more natural arcs. Bake time scales linearly with
it, so set it to 1 for a fixed jump character and cut the bake cost by two
thirds.

**`jump_bias` stops bunny hopping.** On level ground a hop covers the same
distance as a walk for the same number of frames, so without a bias the search
chooses arbitrarily between them and you get an AI that jumps everywhere for no
reason. The default nudges it toward walking when both work.

**See also:** `gmnav_platgraph_create`, `gmnav_platgraph_bake`

---

### gmnav_platgraph_create

**Syntax:**

```gml
gmnav_platgraph_create(grid, movement);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | Grid holding the level's collision, `ORTHO` only |
| movement | Struct | Movement model |

**Returns:** Struct

**Example:**

```gml
pgraph = gmnav_platgraph_create(grid, move);
```

The above code creates an empty graph. Nothing is computed until you bake, so
this call is cheap and can happen before your level is finished.

The graph holds a reference to the grid rather than a copy, so edits to the grid
are visible to `gmnav_platgraph_is_stale`, though they do not update the baked
links.

**See also:** `gmnav_platgraph_bake`, `gmnav_movement_create`

---

### gmnav_platgraph_bake

**Syntax:**

```gml
gmnav_platgraph_bake(pg);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |

**Returns:** Boolean, whether the bake completed

**Example:**

```gml
// level load
gmnav_platgraph_bake(pgraph);
```

The above code finds every standing position and generates every link, to
completion. This is a level load operation and not something to run during play.

**What counts as a standing position.** A cell qualifies when it is open, the
cell below it is solid or one way, and the character's whole box fits there
without clipping. That last condition makes headroom a level design question
rather than a rendering one: a platform needs enough room beneath it for
anything that walks under it, and a corridor one cell too short for your
character simply has no standing positions in it.

**How links are generated.** For every standing position, the baker simulates
walking to each neighbour, running off each edge, and jumping at each sampled
strength in each direction. Each simulation integrates frame by frame under your
gravity and collision until it lands, hits something, or exceeds the frame cap.
Arcs that land on a standing position become links priced in frames; everything
else is discarded.

That is why the graph is honest, and also why it is one way in places. A ledge
you can drop off but not jump back up to produces a link in one direction only,
without anybody authoring that.

**See also:** `gmnav_platgraph_bake_begin`, `gmnav_platgraph_is_ready`

---

### gmnav_platgraph_bake_begin

**Syntax:**

```gml
gmnav_platgraph_bake_begin(pg);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |

**Returns:** N/A

**Example:**

```gml
gmnav_platgraph_bake_begin(pgraph);
```

The above code starts a sliced bake, for showing a loading bar rather than
freezing.

Follow with `gmnav_platgraph_bake_step` each frame.

**See also:** `gmnav_platgraph_bake_step`

---

### gmnav_platgraph_bake_step

**Syntax:**

```gml
gmnav_platgraph_bake_step(pg, budget);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| budget | Integer | Optional, default 256. Work allowed this call |

**Returns:** Enum, a `gmnav_bake` member

**Example:**

```gml
var _phase = gmnav_platgraph_bake_step(pgraph, 256);

switch (_phase) {
    case gmnav_bake.SURFACES: loading_text = "finding ledges";     break;
    case gmnav_bake.LINKS:    loading_text = "simulating jumps";   break;
    case gmnav_bake.DONE:     room_goto(rm_level);                 break;
}
```

The above code drives a sliced bake and reports which phase it is in, which is
enough for a two stage progress display.

The phases are sequential. `SURFACES` scans for standing positions, which is
fast. `LINKS` simulates arcs from each of them, which is the expensive part and
scales with `jump_levels`.

**See also:** `gmnav_platgraph_bake_begin`, `gmnav_movement_create`

---

### gmnav_platgraph_is_ready

**Syntax:**

```gml
gmnav_platgraph_is_ready(pg);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_platgraph_is_ready(pgraph)) {
    gmnav_scheduler_update(psched);
}
```

The above code waits for a bake before driving the scheduler over it.

Requests against an unbaked graph fail rather than crashing, so this is about
avoiding pointless work rather than avoiding an error.

**See also:** `gmnav_platgraph_bake`

---

### gmnav_platgraph_is_stale

**Syntax:**

```gml
gmnav_platgraph_is_stale(pg);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |

**Returns:** Boolean

**Example:**

```gml
// a platform was destroyed
if (gmnav_platgraph_is_stale(pgraph)) {
    gmnav_platgraph_bake_begin(pgraph);
    rebaking = true;
}
```

The above code notices that the level no longer matches the graph.

A graph describes the level as it was baked. Break a platform and every arc that
used it describes something that no longer exists, so agents will jump at gaps
that are now wider and land in space.

Rebaking is expensive, far more so than rebuilding clearance or a cost profile,
because it re-simulates every arc. A side view game with genuinely destructible
terrain is the case GMNav handles least gracefully, and the honest advice is to
rebake at deliberate moments rather than continuously.

**See also:** `gmnav_platgraph_bake_begin`

---

### gmnav_platgraph_node_at

**Syntax:**

```gml
gmnav_platgraph_node_at(pg, x, y, max_drop_cells);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| x | Real | World x |
| y | Real | World y of the feet |
| max_drop_cells | Integer | Optional, default 4. How far down to look |

**Returns:** Integer platform node index, or `GMNAV_NO_NODE`

**Example:**

```gml
// where is this character, in graph terms?
var _here = gmnav_platgraph_node_at(pgraph, x, y);

if (_here != GMNAV_NO_NODE) {
    ticket = gmnav_scheduler_request(psched, _here, _target);
}
```

The above code finds the platform node a character is standing on, which is the
starting point for any request.

It searches **downward**, which is what makes it work while the character is
airborne: mid jump it finds the ledge below, so a request made in flight starts
from somewhere sensible rather than failing.

`max_drop_cells` bounds that search. Raise it for a character that falls a long
way; lower it if you would rather a request fail than start from a ledge far
below.

**See also:** `gmnav_platgraph_node_world`, `gmnav_scheduler_request`

---

### gmnav_platgraph_node_world

**Syntax:**

```gml
gmnav_platgraph_node_world(pg, pnode);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| pnode | Integer | Platform node index |

**Returns:** Array, `[x, y]`

**Example:**

```gml
// draw the route as a series of ledges
for (var _i = 0; _i < array_length(path); _i++) {
    var _p = gmnav_platgraph_node_world(pgraph, path[_i]);
    draw_circle(_p[0], _p[1], 4, false);
}
```

The above code marks each ledge on a platformer route.

The position returned is the surface the character stands on, not the centre of
the cell, so drawing there puts a marker at foot level.

Note that platform node indices are **not** grid node ids. They index the
graph's own list of standing positions, so passing one to a grid function gives
you nonsense.

**See also:** `gmnav_platgraph_node_at`

---

### gmnav_platgraph_link_get

**Syntax:**

```gml
gmnav_platgraph_link_get(pg, from, to);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| from | Integer | Platform node index |
| to | Integer | Platform node index |

**Returns:** Struct `{ type, cost, vx, vy, x, y }`, or `undefined`

**Example:**

```gml
var _lk = gmnav_platgraph_link_get(pgraph, path[seek], path[seek + 1]);

if (_lk != undefined) {
    switch (_lk.type) {
        case gmnav_link.WALK:
            hsp = sign(_lk.x - x) * move.run_speed;
            break;

        case gmnav_link.FALL:
            hsp = sign(_lk.x - x) * move.run_speed;   // run off the edge
            break;

        case gmnav_link.JUMP:
            hsp = _lk.vx;
            vsp = _lk.vy;                             // launch
            break;
    }
}
```

The above code reads how to reach the next ledge and performs it, which is the
boundary between GMNav and your character controller.

`type` is the kind of move. `cost` is in frames. `vx` and `vy` are the launch
velocity that produced this link during the bake, and `x` and `y` are where it
lands.

The velocity is the important part. Apply it and integrate under the same
gravity in the same order the bake used, and the character lands exactly where
the graph promised, because it is the same computation. Use different numbers or
a different order and the arc drifts, invisibly on short hops and by whole
ledges on long jumps.

**See also:** `gmnav_platgraph_solid`, `gmnav_scheduler_get_links`

---

### gmnav_platgraph_solid

**Syntax:**

```gml
gmnav_platgraph_solid(pg, x, y, vy);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| x | Real | World x of the character centre |
| y | Real | World y of the feet |
| vy | Real | Optional, default 0. Vertical velocity |

**Returns:** Boolean

**Example:**

```gml
// the integration order the bake used. Match it exactly
vsp = min(vsp + move.gravity, move.max_fall);

var _nx = x + hsp;
if (gmnav_platgraph_solid(pgraph, _nx, y, 0)) hsp = 0; else x = _nx;

var _ny = y + vsp;
if (gmnav_platgraph_solid(pgraph, x, _ny, vsp)) {
    if (vsp > 0) on_ground = true;
    vsp = 0;
} else {
    y = _ny;
}
```

The above code is a character controller that stays in sync with the graph.

**Gravity, then horizontal, then vertical, testing each separately.** That order
is not a style preference, it is what the baker did, and a different order drifts
by a fraction of a pixel per frame. Over a short hop nobody notices. Over a long
jump the character lands somewhere the graph never said it would, on a ledge
that may not be there.

Using this function rather than your own collision test is the other half of
staying in sync, since it is literally the test the bake ran.

The `vy` argument matters for one way platforms: a downward velocity is blocked
by one, an upward velocity passes through.

**See also:** `gmnav_platgraph_link_get`, `gmnav_platagent_update`

---

## Platform Agent Functions

Chapter 10's division of labour, where GMNav says a jump is needed and your
controller performs it, is right for a character with an animation state machine
you care about. It is a lot of work for a bat.

The platform agent follows a baked graph itself, replaying each link's stored
launch velocity.

**This is the one place in GMNav that moves something**, and the reason is
specific: arc replay is only correct if the stepping order matches the bake
exactly, so the replay has to own the stepping. Everywhere else the framework
proposes and your code disposes, because your game already owns movement. Here,
handing you a velocity and hoping you integrate it identically would be handing
you a bug.

Use it for characters whose movement is entirely the navigation's business. Use
`gmnav_platgraph_link_get` for anything your game wants to interrupt.

---

### gmnav_platagent_create

**Syntax:**

```gml
gmnav_platagent_create(sched, x, y);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | A scheduler created over a platformer graph |
| x | Real | World x |
| y | Real | World y of the feet |

**Returns:** Struct

**Example:**

```gml
psched = gmnav_scheduler_create(pgraph, 1500);
bat    = gmnav_platagent_create(psched, x, y);
```

The above code creates a platform agent, which snaps to the nearest standing
position at or below the position you gave it.

The scheduler must have been created over a platformer graph rather than a grid,
since the agent asks it for platformer routes.

**See also:** `gmnav_platagent_goto`, `gmnav_scheduler_create`

---

### gmnav_platagent_goto

**Syntax:**

```gml
gmnav_platagent_goto(pa, x, y, priority);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |
| x | Real | World x of the goal |
| y | Real | World y of the goal |
| priority | Enum | Optional, default `gmnav_priority.NORMAL` |

**Returns:** Boolean, `false` if either end has no standing position

**Example:**

```gml
// chase the player, re-aiming every second
if (chase_timer <= 0) {
    gmnav_platagent_goto(bat, obj_player.x, obj_player.y);
    chase_timer = room_speed;
}
```

The above code retargets a pursuing character periodically.

**Called mid-arc, the agent finishes the arc it committed to** and routes from
the node it is about to land on. That is deliberate: interrupting a ballistic
trajectory halfway is not something the graph can price, and a character that
changes direction in mid-air reads as weightless. So retargeting during a jump
is safe and simply takes effect on landing.

Returns `false` when either end has no standing position nearby, which usually
means the target is in mid-air or inside geometry.

**See also:** `gmnav_platagent_update`, `gmnav_platagent_arrived`

---

### gmnav_platagent_update

**Syntax:**

```gml
gmnav_platagent_update(pa);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |

**Returns:** N/A

**Example:**

```gml
// Step event
gmnav_scheduler_update(psched);
gmnav_platagent_update(bat);

x = bat.x;
y = bat.y;

sprite_index = gmnav_platagent_airborne(bat) ? spr_bat_fly : spr_bat_walk;
```

The above code advances the agent and reads its position back out.

Note the direction of that assignment. Everywhere else in GMNav you write your
position into the framework; here the framework writes its position and you read
it. Anything your game does to `x` or `y` between updates is fighting the
replay, which is why a character that can be knocked back, grabbed or pushed by
a moving platform is a poor fit for this.

**See also:** `gmnav_platagent_airborne`, `gmnav_platgraph_link_get`

---

### gmnav_platagent_stop

**Syntax:**

```gml
gmnav_platagent_stop(pa);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |

**Returns:** N/A

**Example:**

```gml
if (stunned) gmnav_platagent_stop(bat);
```

The above code halts the agent.

Drops the route, cancels any request in flight, and snaps the agent back to its
current node. Safe to call mid-arc, though the snap means a character stopped in
flight lands immediately rather than completing its jump, which may or may not
be what your game wants to look like.

**See also:** `gmnav_platagent_goto`

---

### gmnav_platagent_arrived

**Syntax:**

```gml
gmnav_platagent_arrived(pa);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_platagent_arrived(bat)) {
    perch_and_screech();
}
```

The above code reacts to a completed route.

Latched, like the grid agent's equivalent, so it stays `true` until the next
`goto` or `stop` and you can check it whenever suits you.

**See also:** `gmnav_platagent_has_route`

---

### gmnav_platagent_airborne

**Syntax:**

```gml
gmnav_platagent_airborne(pa);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |

**Returns:** Boolean

**Example:**

```gml
if (gmnav_platagent_airborne(bat)) {
    sprite_index = (bat.vy < 0) ? spr_jump_rise : spr_jump_fall;
} else {
    sprite_index = (abs(bat.vx) > 0.1) ? spr_walk : spr_idle;
}
```

The above code picks an animation from the agent's state, using the vertical
velocity to tell a rise from a fall.

True for exactly the frames the character is performing a `FALL` or `JUMP` link.
This is how you pick a jump animation without inspecting links yourself.

What it does not give you is anticipation frames, landing recovery or turning,
which remain your animation system's business.

**See also:** `gmnav_platagent_update`

---

### gmnav_platagent_has_route

**Syntax:**

```gml
gmnav_platagent_has_route(pa);
```

| Argument | Type | Description |
|---|---|---|
| pa | Struct | The platform agent |

**Returns:** Boolean

**Example:**

```gml
if (!gmnav_platagent_has_route(bat) && !gmnav_platagent_arrived(bat)) {
    // nothing to do and did not get anywhere. Wander instead
    pick_random_perch();
}
```

The above code distinguishes an idle agent from a finished one, which together
cover the cases where a character needs something new to do.

True while links remain to be performed.

**See also:** `gmnav_platagent_arrived`

---

### pa.desync

Not a function, but the field worth watching during development.

**Example:**

```gml
if (bat.desync > 0) {
    show_debug_message("bat desync: " + string(bat.desync));
}
```

The agent counts frames where its own position disagreed with what the replay
expected. In normal operation this stays at **zero**, so any non-zero value is
telling you something, and there are only three ways it happens.

**The movement model does not match the level.** The numbers in
`gmnav_movement_create` must be your controller's real ones. A graph baked with
a jump velocity the character does not have produces links that fall short.

**Something else moved the character.** Knockback, a moving platform, a scripted
push. The replay assumed it owned the position and it did not.

**The collision data changed after the bake.** The graph describes the level as
it was baked.

It costs nothing to check and it is the cheapest signal you have that the model
and the level have drifted apart.

**See also:** `gmnav_movement_create`, `gmnav_platgraph_is_stale`

---

## Graph Search Functions

The platformer domain does not search a grid, it searches a graph: a list of
nodes and a list of edges between them, with no geometry implied.

These functions are that search. They are domain agnostic, so anything you can
express as nodes and edges can be searched with them, and the scheduler uses
them for the platformer domain rather than having a second A\* of its own.

Most projects never call these directly. The scheduler does it for you.

---

### gmnav_graph_search_create

**Syntax:**

```gml
gmnav_graph_search_create(graph);
```

| Argument | Type | Description |
|---|---|---|
| graph | Struct | A platformer graph, or any struct with the same edge arrays |

**Returns:** Struct

**Example:**

```gml
gsearch = gmnav_graph_search_create(pgraph);
```

The above code creates a reusable search over a graph.

What the graph must provide is `edge_start`, `edge_to`, `edge_cost` and
`edge_type` in compressed sparse row form, plus `node_x` and `node_y` for the
heuristic. A platformer graph has all of those, which is why this works on one
without either side knowing about the other.

**See also:** `gmnav_graph_search_begin`, `gmnav_platgraph_create`

---

### gmnav_graph_search_begin

**Syntax:**

```gml
gmnav_graph_search_begin(search, start, goal);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |
| start | Integer | Starting node index |
| goal | Integer | Target node index |

**Returns:** Boolean, whether the search started

**Example:**

```gml
if (gmnav_graph_search_begin(gsearch, _from, _to)) {
    searching = true;
}
```

The above code sets a graph search up. It does no work; call
`gmnav_graph_search_step` to advance it.

Indices are into the graph's own node list, not grid node ids. For a platformer
graph, `gmnav_platgraph_node_at` is how you get one.

**See also:** `gmnav_graph_search_step`, `gmnav_platgraph_node_at`

---

### gmnav_graph_search_step

**Syntax:**

```gml
gmnav_graph_search_step(search, budget);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |
| budget | Integer | Optional. Node expansions allowed this call |

**Returns:** Enum, a `gmnav_state` member

**Example:**

```gml
if (gmnav_graph_search_step(gsearch, 200) == gmnav_state.FOUND) {
    path  = gmnav_graph_search_get_path(gsearch);
    links = gmnav_graph_search_get_links(gsearch);
}
```

The above code advances a graph search and collects both halves of its result.

Resumable in exactly the same way a grid search is, and for the same reason. The
heuristic is straight line world distance between nodes, which is admissible
because no link can cover ground faster than a straight line at the character's
own top speed.

**See also:** `gmnav_graph_search_get_path`, `gmnav_search_step`

---

### gmnav_graph_search_get_path

**Syntax:**

```gml
gmnav_graph_search_get_path(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |

**Returns:** Array of node indices, empty if the search did not succeed

**Example:**

```gml
var _nodes = gmnav_graph_search_get_path(gsearch);
```

The above code takes the route. Entries are graph node indices, so pair them
with `gmnav_platgraph_node_world` to get positions.

**See also:** `gmnav_graph_search_get_links`

---

### gmnav_graph_search_get_links

**Syntax:**

```gml
gmnav_graph_search_get_links(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |

**Returns:** Array of `gmnav_link` values

**Example:**

```gml
var _links = gmnav_graph_search_get_links(gsearch);

// _links[i] is how you reach _path[i]
```

The above code takes the other half of the result.

This is what makes a graph route usable. On a grid, every step is a move to an
adjacent cell and the shape of the move is obvious. On a graph it is not: two
nodes joined by an edge might be joined by a walk, a fall or a jump, and your
controller has to know which.

**See also:** `gmnav_scheduler_get_links`, `gmnav_platgraph_link_get`

---

### gmnav_graph_search_release

**Syntax:**

```gml
gmnav_graph_search_release(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |

**Returns:** N/A

**Example:**

```gml
gmnav_graph_search_release(gsearch);
```

The above code returns the workspace and clears the result. As with grid
searches, forgetting this leaks a slot.

**See also:** `gmnav_graph_search_abort`, `gmnav_search_release`

---

### gmnav_graph_search_abort

**Syntax:**

```gml
gmnav_graph_search_abort(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The graph search |

**Returns:** N/A

**Example:**

```gml
gmnav_graph_search_abort(gsearch);
```

The above code stops a search in progress and hands its workspace back. Safe on
one that is idle or finished.

**See also:** `gmnav_graph_search_release`

---

## Debug Functions

Almost everything in this framework is invisible. A clearance map is an array of
small integers, a cost profile is another array, a flow field is three more. The
one thing you can normally see is the agent, and the agent is the end of a long
chain of decisions any one of which could be why it is behaving oddly.

Each view answers **one question**. The fastest route to a diagnosis is picking
the view whose question matches your symptom rather than turning everything on,
which mostly produces a colourful picture that is hard to read and isolates
nothing.

Every view understands overlays, drawing raised cells at the height they occupy
with a thin line dropping to the ground cell beneath.

---

### gmnav_debug_config

**Syntax:**

```gml
gmnav_debug_config();
```

**Returns:** Struct with `cull`, `cull_pad`, `alpha`, `line_alpha`, `line_width`
and `max_cells`

**Example:**

```gml
cfg = gmnav_debug_config();

cfg.alpha     = 0.25;   // fainter, so the game underneath stays readable
cfg.cull      = false;  // draw the whole map, not just what the camera sees
cfg.max_cells = 20000;  // raise the safety limit on a big map
```

The above code makes one config and tunes it. Keep a single config and pass it
to every view, so a change applies everywhere.

**Culling** reads the current camera and skips anything off screen, which is what
you want on a large map. In a room with no view enabled there is nothing to cull
against, so everything is drawn rather than nothing. Turn it off when you are
deliberately inspecting geometry outside the camera.

**`max_cells`** is a safety limit. Each view stops after this many cells and logs
that it did, which on a very large map with culling off is what stands between
you and a frame that takes a second to draw. If a view looks truncated, that is
why.

**See also:** `gmnav_debug_draw_grid`

---

### gmnav_debug_draw_grid

**Syntax:**

```gml
gmnav_debug_draw_grid(grid, cfg);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
// Draw event
gmnav_debug_draw_grid(grid, cfg);
```

The above code shades every blocked cell.

**The question it answers:** is this cell solid? Which sounds trivial until the
first time your imported collision does not match the walls you can see, and it
turns out your tilemap has an origin offset or your tile size is wrong.

Draws in the layout's own cell shape, so hexes are hexes and isometric cells are
diamonds, which makes a coordinate mismatch obvious rather than subtle.

**See also:** `gmnav_debug_draw_reach`

---

### gmnav_debug_draw_clearance

**Syntax:**

```gml
gmnav_debug_draw_clearance(grid, cfg);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_clearance(grid, cfg);
```

The above code shades cells by how much room is around them, brighter for more.

**The question it answers:** how much room is there? Reach for it when a large
unit refuses a route that looks perfectly passable. The answer is almost always
a doorway one cell narrower than you remembered, and this makes it visible
immediately.

Shows nothing if clearance has not been built, and nothing on staggered or hex
layouts where it is unsupported.

**See also:** `gmnav_clearance_build`, `gmnav_debug_draw_reach`

---

### gmnav_debug_draw_costs

**Syntax:**

```gml
gmnav_debug_draw_costs(grid, profile, cfg);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| profile | Struct | Optional. Cost profile |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
// what does the scout see?
gmnav_debug_draw_costs(grid, scout, cfg);
```

The above code shades cells by what **that profile** pays for them.

**The question it answers:** what does this unit type pay? Reach for it when a
unit takes a strange but legal route, which usually means it is avoiding
something you forgot you authored.

Pass the profile. Without one you see base terrain cost only, which is rarely
what you are debugging, since the interesting behaviour comes from the layers.
Switching which profile you pass is the fastest way to see why two unit types
disagree.

**See also:** `gmnav_costprofile_bake`

---

### gmnav_debug_draw_flowfield

**Syntax:**

```gml
gmnav_debug_draw_flowfield(field, cfg, show_dist);
```

| Argument | Type | Description |
|---|---|---|
| field | Struct | The flow field |
| cfg | Struct | Optional. Debug config |
| show_dist | Boolean | Optional, default `true`. Shade cells by distance |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_flowfield(field, cfg);
```

The above code draws an arrow per cell, shaded by distance, with a circle at
each goal.

**The question it answers:** which way, and how far?

**Any arrow pointing into a wall means the field is wrong, not the steering.**
That single rule is the fastest diagnosis in the framework. Arrows are computed
in world space, so they are trustworthy on isometric and hex where a cell offset
is not a screen direction. If they look right and your units still walk into
geometry, stop looking at the field and look at your movement code. If they look
wrong, stop looking at your movement code.

The distance shading is the other half. Shading that spreads smoothly outward
from the goal is working. A hard edge where it stops is either a distance cap or
a genuinely unreachable region, and which one will be obvious from where it sits.

**See also:** `gmnav_flowfield_build`, `gmnav_debug_draw_reach`

---

### gmnav_debug_draw_reach

**Syntax:**

```gml
gmnav_debug_draw_reach(grid, cfg, need_clear);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| cfg | Struct | Optional. Debug config |
| need_clear | Integer | Optional, default 0. Only consider cells with at least this clearance |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_reach(grid, cfg);      // everyone
gmnav_debug_draw_reach(grid, cfg, 2);   // what can a big unit reach?
```

The above code colours each connected component differently.

**The question it answers:** can this size get there at all? This is the view for
a `FAILED` search on a map that looks walkable, which is the failure that wastes
the most time.

One colour means everything is reachable from everything else. Two colours mean
your map is in two pieces and you can see exactly where the seam is.

The clearance argument is the point of it. A map that is one component for a rat
can be five islands for an ogre, because a doorway one cell too narrow is a wall
to anything that does not fit.

It walks authored links as well as ordinary adjacency, so a deck joined by
stairs reads as part of the floor it connects to. If a bridge shows up in a
different colour from the ground at **both** its ends, its links are missing,
which is a level authoring bug the search would otherwise report as a mysterious
failure.

**See also:** `gmnav_clearance_for_radius`, `gmnav_agent_failed`

---

### gmnav_debug_draw_path

**Syntax:**

```gml
gmnav_debug_draw_path(grid, path, cfg, colour);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| path | Array | Node ids |
| cfg | Struct | Optional. Debug config |
| colour | Integer | Optional, default `GMNAV_DBG_PATH` |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_path(grid, raw_nodes, cfg, c_yellow);
```

The above code draws a raw node route.

Dots are sized by role: largest at the ends, medium at direction changes, small
elsewhere. On a raw route most waypoints are collinear filler and read as small,
which makes the real corners stand out and shows at a glance how much smoothing
has to gain.

**See also:** `gmnav_debug_draw_path_object`

---

### gmnav_debug_draw_path_object

**Syntax:**

```gml
gmnav_debug_draw_path_object(path, cfg, colour);
```

| Argument | Type | Description |
|---|---|---|
| path | Struct | A path object |
| cfg | Struct | Optional. Debug config |
| colour | Integer | Optional, default `GMNAV_DBG_PATH` |

**Returns:** N/A

**Example:**

```gml
// compare before and after
gmnav_debug_draw_path(grid, raw_nodes, cfg, c_gray);
gmnav_debug_draw_path_object(smoothed, cfg, c_lime);
```

The above code draws a raw route and its smoothed version together, which is the
clearest way to see what smoothing did and whether it did something you did not
want.

**See also:** `gmnav_path_smooth`

---

### gmnav_debug_draw_search

**Syntax:**

```gml
gmnav_debug_draw_search(search, cfg);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_search(search, cfg);
```

The above code shades the frontier: open cells one colour, settled cells
another.

**The question it answers:** where has it looked so far?

**It draws nothing unless a search is in flight**, which is the point rather than
a bug. A search holds its workspace only while running, and the view exists to
watch a frontier expand across frames under a small budget. Give it a large
budget and it completes inside one frame with nothing to watch.

The shape of the boundary tells you whether the heuristic is working. A frontier
that pushes toward the goal is A\* doing its job. One that spreads evenly in all
directions is behaving like Dijkstra, which usually means the heuristic is zero
or the map has made it useless.

**See also:** `gmnav_search_step`

---

### gmnav_debug_draw_agent

**Syntax:**

```gml
gmnav_debug_draw_agent(agent, cfg);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_agent(agent, cfg);
```

The above code draws the agent's body, velocity, path, current target and goal.

**The question it answers:** what is it steering at?

The **solid ring** sits on the waypoint being steered at right now, and a fainter
ring marks the next real corner. A ring that never advances is an agent making
no progress toward it, usually because `reach_dist` is smaller than its speed
and it can never land inside its own target. A ring advancing every frame is an
agent passing waypoints faster than it can steer at them.

A path drawn with a waypoint in **every cell** rather than at corners is telling
you smoothing refused those shortcuts, usually a body too wide for the corridor
or a profile making the shortcut dear.

A **red** path rather than the usual colour means it has gone stale and not yet
been replaced. Briefly is normal; persistently means repathing is failing or
rate limited harder than you meant.

**See also:** `gmnav_agent_update`

---

### gmnav_debug_draw_platgraph

**Syntax:**

```gml
gmnav_debug_draw_platgraph(pg, cfg, types, focus);
```

| Argument | Type | Description |
|---|---|---|
| pg | Struct | The platformer graph |
| cfg | Struct | Optional. Debug config |
| types | Integer | Optional, default 7. Bitmask: 1 walk, 2 fall, 4 jump |
| focus | Integer | Optional, default -1. Draw only links touching this node |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_platgraph(pgraph, cfg, 4);              // jumps only
gmnav_debug_draw_platgraph(pgraph, cfg, 7, hover_node);  // one ledge
```

The above code filters the view, which is the only way to read it.

A modest level bakes into several hundred links, and drawing them all at once is
a scribble. Filtering to jumps alone shows you the interesting connectivity;
focusing on a single node shows you exactly what that ledge can reach, which is
how you answer "why will nothing jump to this platform".

**Note:** arcs are drawn as a cosmetic bow rather than the real simulated
trajectory, so use this to read connectivity rather than to judge whether an arc
clears an obstacle.

**See also:** `gmnav_platgraph_bake`

---

### gmnav_debug_draw_heights

**Syntax:**

```gml
gmnav_debug_draw_heights(grid, cfg, max_z);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| cfg | Struct | Optional. Debug config |
| max_z | Real | Optional. Top of the shading range |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_heights(grid, cfg);
```

The above code shades cells by elevation.

**The question it answers:** how high is this ground? Useful for confirming that
an imported or generated heightmap came out the shape you expected, before you
start wondering why routes avoid a hill.

`max_z` fixes the top of the shading range. Without it the range is derived from
the grid, so a single very tall cell flattens the contrast everywhere else.

**See also:** `gmnav_grid_set_height`, `gmnav_debug_draw_steps`

---

### gmnav_debug_draw_steps

**Syntax:**

```gml
gmnav_debug_draw_steps(grid, max_climb, max_drop, cfg);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| max_climb | Real | Largest rise |
| max_drop | Real | Largest fall |
| cfg | Struct | Optional. Debug config |

**Returns:** N/A

**Example:**

```gml
gmnav_debug_draw_steps(grid, 1, 3, cfg);
```

The above code marks every step a unit with those limits is refused, drawn per
edge rather than per cell.

**The question it answers:** which way can this unit actually go? This is the
view for a route that takes a long way round on sloped terrain, and it makes
one-way terrain visible: an edge refused in one direction and allowed in the
other is exactly what a cliff looks like.

**See also:** `gmnav_grid_step_blocked`

---

### gmnav_debug_draw_stats

**Syntax:**

```gml
gmnav_debug_draw_stats(sched, x, y);
```

| Argument | Type | Description |
|---|---|---|
| sched | Struct | The scheduler |
| x | Real | Optional, default 8. Screen x |
| y | Real | Optional, default 8. Screen y |

**Returns:** N/A

**Example:**

```gml
// Draw GUI event
gmnav_debug_draw_stats(sched, 8, 8);
```

The above code shows budget, queue length, active searches and workspace use.

**The question it answers:** is the budget holding? This is the one to leave on
longest, and the number to watch is **pending**.

A brief spike is a crowd asking at once and the queue doing its job. Pending
that stays high frame after frame means requests are arriving faster than they
are served.

Before raising the budget, ask whether those requests should exist. On a map
with frequent edits, permanently high pending is more often unnecessary
repathing than an undersized allowance, and raising the budget hides it by doing
the pointless work faster.

Draw this in a **Draw GUI** event, not Draw, or it will scroll away with the
camera.

**See also:** `gmnav_scheduler_pending`, `gmnav_grid_changed_since`

---

### gmnav_debug_search_text

**Syntax:**

```gml
gmnav_debug_search_text(search);
```

| Argument | Type | Description |
|---|---|---|
| search | Struct | The search |

**Returns:** String

**Example:**

```gml
draw_text(8, 200, gmnav_debug_search_text(search));
```

The above code prints a one line summary of a search's state for your own
overlay, when you want the numbers without the full stats panel.

**See also:** `gmnav_debug_draw_stats`

---

## Util Functions

`GMNav/Util/GMNav_Util.gml` is a convenience module. Every function in it
composes public calls and decides nothing. It exists because the same three
or four lines get written in every project, and writing them by hand gets old.

Nothing here is required. Delete the folder and the rest of the framework is
unaffected. The functions are grouped by what a caller is usually trying to
do, and none of them hide a decision you might want to make differently.

### Grid setup

Building a grid that matches the room, or one that matches a tilemap, is
the first thing every project does. These three cover the common shapes.

### gmnav_util_grid_for_room

```gml
gmnav_util_grid_for_room(tile_w, tile_h, mode, neighbours);
```

| Argument | Type | Description |
|---|---|---|
| tile_w | Real | Tile width in pixels |
| tile_h | Real | Optional, defaults to tile_w. Tile height |
| mode | Enum | Optional, default ORTHO. A `gmnav_layout` member |
| neighbours | Enum | Optional, default EIGHT. A `gmnav_neighbours` member |

**Returns:** Grid struct

A grid sized to fit the room, with a matching layout. Square tiles when
`tile_h` is left out, which is the common case.

**Example:**

```gml
// the plain case, 32 pixel tiles filling the room
grid = gmnav_util_grid_for_room(32);

// isometric, 64 by 32
grid = gmnav_util_grid_for_room(64, 32, gmnav_layout.ISO_DIAMOND);
```

The above replaces the two-line grid setup that appears in every demo. Same
grid, same layout, one call.

### gmnav_util_border_blocked

```gml
gmnav_util_border_blocked(grid, thickness);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| thickness | Integer | Optional, default 1. How many cells thick the border is |

**Returns:** Boolean, whether anything changed

Walls around the edge of the map. Every demo writes this by hand, usually as
four `gmnav_grid_fill_blocked` calls. This does the same thing with one call
and handles any thickness.

**Example:**

```gml
gmnav_util_border_blocked(grid);      // one cell thick
gmnav_util_border_blocked(grid, 3);   // three cells thick
```

The return value follows the same no-op discipline the rest of the grid
functions use: re-asserting an existing border does nothing and does not bump
the version.

### gmnav_util_grid_from_tilemap

```gml
gmnav_util_grid_from_tilemap(tilemap, tile_w, tile_h, mode, neighbours, is_blocked);
```

| Argument | Type | Description |
|---|---|---|
| tilemap | Id | A tilemap element id |
| tile_w | Real | Tile width in pixels |
| tile_h | Real | Optional, defaults to tile_w. Tile height |
| mode | Enum | Optional, default ORTHO |
| neighbours | Enum | Optional, default EIGHT |
| is_blocked | Function | Optional. Given a tile index, returns whether it blocks |

**Returns:** Grid struct

The whole top-down level setup in one call: size the grid to the tilemap,
build a matching layout, import the collision, block the border. This is the
pattern from the Getting Started guide with the boilerplate removed.

**Example:**

```gml
grid = gmnav_util_grid_from_tilemap(layer_tilemap_get_id("Collision"), 32);
```

Tile height defaults to tile width, mode defaults to ORTHO, neighbours
defaults to EIGHT, and `is_blocked` defaults to "any non-zero tile blocks".
Every argument past `tile_w` is optional, so the common case is one call.

### Node query and picking

A cell is not a position you can stand at. These functions bridge that gap
and refuse to return somewhere an agent cannot actually be.

### gmnav_util_node_at

```gml
gmnav_util_node_at(grid, x, y, layer);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| x | Real | World x |
| y | Real | World y |
| layer | Integer | Optional, default 0. Which surface to ask about |

**Returns:** Node id, or `GMNAV_NO_NODE` if the position is off the map or blocked

`gmnav_grid_world_to_node` returns a node for any position inside the grid,
including blocked cells. This returns a node only if the cell there is
walkable. Same two-line check that appears in every click handler, wrapped.

**Example:**

```gml
var _n = gmnav_util_node_at(grid, mouse_x, mouse_y);

if (_n != GMNAV_NO_NODE) {
    // somewhere the player can actually send a unit
}
```

### gmnav_util_cursor_node

```gml
gmnav_util_cursor_node(grid, mode);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| mode | Integer | Optional, default 0. 0 asks topmost, 1 asks the ground |

**Returns:** Node id, or `GMNAV_NO_NODE`

The node under the cursor, if it is somewhere an agent could stand.
`mode = 0` walks down from the highest overlay layer, which is what a click
on a bridge usually means. `mode = 1` asks layer 0, so the click passes under
a bridge.

**Example:**

```gml
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_util_cursor_node(grid);

    if (_n != GMNAV_NO_NODE) {
        // send the player's unit there
    }
}
```

### gmnav_util_snap_open

```gml
gmnav_util_snap_open(grid, x, y, max_rings);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| x | Real | World x |
| y | Real | World y |
| max_rings | Integer | Optional, default 4. How far out to search |

**Returns:** Node id, or `GMNAV_NO_NODE`

The nearest open node to a world position, when the exact cell is blocked or
off the map. Walks outward in rings, no clearance required. Useful for spawn
points, for forgiving clicks, and for anything that has to produce a walkable
position from an arbitrary one.

**Example:**

```gml
// a cutscene spawn point that might be inside geometry
var _n = gmnav_util_snap_open(grid, cutscene_x, cutscene_y);

if (_n != GMNAV_NO_NODE) {
    var _p = gmnav_grid_node_to_world(grid, _n);
    instance_create_layer(_p[0], _p[1], "Units", obj_guard);
}
```

### gmnav_util_random_open

```gml
gmnav_util_random_open(grid, max_attempts);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| max_attempts | Integer | Optional, default 200. How many cells to sample |

**Returns:** Node id, or `GMNAV_NO_NODE`

A random walkable node. Samples cells uniformly, not walkable cells, so a
mostly blocked map wants a higher attempt budget.

**Example:**

```gml
// scatter a crowd over the open ground
for (var i = 0; i < 20; i++) {
    var _n = gmnav_util_random_open(grid);
    if (_n == GMNAV_NO_NODE) continue;

    var _p = gmnav_grid_node_to_world(grid, _n);
    instance_create_layer(_p[0], _p[1], "Units", obj_guard);
}
```

### gmnav_util_random_open_world

```gml
gmnav_util_random_open_world(grid, max_attempts);
```

Same as `gmnav_util_random_open`, returning the world position as an `[x, y]`
array instead of the node id. `undefined` if nothing was found.

**Example:**

```gml
var _p = gmnav_util_random_open_world(grid);

if (_p != undefined) {
    agent.x = _p[0];
    agent.y = _p[1];
}
```

### Inspection

For debug messages and overlays. These are the "what does the framework
think about this cell" helpers.

### gmnav_util_probe_node

```gml
gmnav_util_probe_node(grid, node);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| node | Integer | Node id, base or overlay |

**Returns:** Struct, or `undefined` if the node is invalid

Everything the framework knows about one node, as a struct: column, row,
layer, blocked state, base cost, clearance, elevation, overlay offset, world
position.

**Example:**

```gml
var _pr = gmnav_util_probe_node(grid, _n);

show_debug_message("cell " + string(_pr.col) + "," + string(_pr.row)
                 + " layer " + string(_pr.layer)
                 + " cost " + string(_pr.cost)
                 + " clearance " + string(_pr.clearance));
```

### gmnav_util_describe_node

```gml
gmnav_util_describe_node(grid, node);
```

**Returns:** String

A one-line human readable summary: `(col,row) layer N cost X.XX` with
`blocked` inserted when applicable. Handles `GMNAV_NO_NODE` and invalid ids
without erroring.

**Example:**

```gml
show_debug_message("clicked " + gmnav_util_describe_node(grid, _n));
// prints:  clicked (5,3) layer 0 cost 1.00
```

### Agent control

Sending an agent somewhere, or a group of agents, with the position resolved
and the surface chosen.

### gmnav_util_send_agent

```gml
gmnav_util_send_agent(agent, grid, x, y, mode, priority);
```

| Argument | Type | Description |
|---|---|---|
| agent | Struct | The agent |
| grid | Struct | The grid |
| x | Real | World x |
| y | Real | World y |
| mode | Integer | Optional, default 0. 0 topmost surface, 1 ground |
| priority | Enum | Optional, default NORMAL |

**Returns:** Boolean, `false` if the point is not somewhere an agent can stand

The whole click-to-move handler in one call. Resolves the click to a node,
checks it is walkable, and if so sends the agent there on the correct layer.

**Example:**

```gml
if (mouse_check_button_pressed(mb_left)) {
    gmnav_util_send_agent(agent, grid, mouse_x, mouse_y);
}
```

### gmnav_util_send_agent_node

```gml
gmnav_util_send_agent_node(agent, grid, node, priority);
```

Same as `gmnav_util_send_agent` but takes a node id the caller already has.
Useful after a lookup that returned a node rather than a position.

### gmnav_util_send_group

```gml
gmnav_util_send_group(agents, grid, x, y, spread, priority);
```

| Argument | Type | Description |
|---|---|---|
| agents | Array | The agents |
| grid | Struct | The grid |
| x | Real | World x of the centre of the group |
| y | Real | World y |
| spread | Real | Optional, default 0. Radius of the disc, in pixels |
| priority | Enum | Optional, default NORMAL |

**Returns:** Integer, how many agents accepted the order

Send every agent in an array to a point, spread across a disc so they do not
stack on one cell. Uses a golden-angle distribution, which gives even coverage
without the pattern looking regular.

**Example:**

```gml
// send 20 guards to a spot, spread over a disc 60 pixels wide
gmnav_util_send_group(guards, grid, target_x, target_y, 60);
```

### gmnav_util_reset_agent

```gml
gmnav_util_reset_agent(agent, grid, x, y, layer);
```

Stop an agent, move it to a position, and clear every trace of the old
journey. Cleaner than calling `gmnav_agent_stop` and then setting `x`, `y`
and the latches by hand.

**Example:**

```gml
// respawn a unit at a checkpoint
gmnav_util_reset_agent(agent, grid, spawn_x, spawn_y);
```

### Agent state

Reading the state of an agent, or a group of agents, for HUDs and debug
overlays. These are live reads — nothing is cached.

### gmnav_util_agent_state

```gml
gmnav_util_agent_state(agent);
```

**Returns:** String, one of `"arrived"`, `"failed"`, `"walking"`, `"waiting"`, `"idle"`

A single word describing what the agent is doing right now. Order of checks
matters: arrived and failed win over walking, which wins over waiting.

**Example:**

```gml
draw_text(x, y - 20, gmnav_util_agent_state(agent));
```

### gmnav_util_agent_summary

```gml
gmnav_util_agent_summary(agents);
```

**Returns:** Struct with fields `total`, `walking`, `waiting`, `idle`, `arrived`, `failed`

Tally a group of agents. Useful for a HUD counter that reads
`"12/20 moving, 3 arrived"` without looping through agents in the draw event.

### gmnav_util_scheduler_snapshot

```gml
gmnav_util_scheduler_snapshot(sched);
```

**Returns:** Struct with fields `domain`, `budget`, `concurrent`, `pending`, `active`, `pops_used`, `pooled`

Everything a HUD wants to know about a scheduler, in one call. Reads the same
fields the built-in debug panel uses.

### Synchronous path queries

These run a search to completion inside the call. Fine for tools, level
validation, spawn checks, and anything outside gameplay. Wrong for anything
per frame, which is what the scheduler is for.

### gmnav_util_shortest_path

```gml
gmnav_util_shortest_path(grid, from, to, profile, need_clear, max_climb, max_drop, max_steps);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| from | Integer | Start node |
| to | Integer | Goal node |
| profile | Struct | Optional. A cost profile |
| need_clear | Integer | Optional, default 0 |
| max_climb, max_drop | Real | Optional. Elevation limits |
| max_steps | Integer | Optional, default 1000000. Safety cap |

**Returns:** Path struct, or `undefined`

The whole pipeline in one call: search to completion, reconstruct, smooth.
Handy for level tools and previews. Not for gameplay.

### gmnav_util_is_reachable

```gml
gmnav_util_is_reachable(grid, from, to, profile, need_clear, max_climb, max_drop, max_steps);
```

**Returns:** Boolean

Whether any route exists between two nodes. Same arguments as
`gmnav_util_shortest_path`, same synchronous behaviour. Use it for spawn
validation and objective checks, not per frame.

**Example:**

```gml
// refuse to spawn a unit that cannot reach the objective
if (gmnav_util_is_reachable(grid, spawn_node, objective_node)) {
    spawn_enemy(spawn_x, spawn_y);
}
```

### gmnav_util_path_cost

```gml
gmnav_util_path_cost(grid, nodes, profile);
```

| Argument | Type | Description |
|---|---|---|
| grid | Struct | The grid |
| nodes | Array | Node ids |
| profile | Struct | Optional. A cost profile |

**Returns:** Real

The cost the search would charge for a route, given as nodes. No search runs
— it adds up the resolved costs of each step. Useful for comparing two routes
you already have, or for deciding whether a detour is worth taking.

### gmnav_util_path_is_valid

```gml
gmnav_util_path_is_valid(grid, nodes, need_clear);
```

**Returns:** Boolean

Whether every node on a route still exists and remains walkable. Call this
after grid edits to decide whether a held path is worth keeping.

**Example:**

```gml
// the warehouse just changed shape, is our route still good?
if (!gmnav_util_path_is_valid(grid, my_path_nodes)) {
    request_new_path();
}
```

### Cost fields

### gmnav_util_costfield_single

```gml
gmnav_util_costfield_single(grid, name);
```

**Returns:** Struct with fields `layer` and `profile`

A layer plus a profile that reads it with weight 1. The common case by far,
and two calls that always go together.

**Example:**

```gml
var _danger = gmnav_util_costfield_single(grid, "danger");

gmnav_costlayer_stamp_radial(_danger.layer, x, y, 200, 8, 2);
gmnav_costprofile_bake(_danger.profile);
```

### gmnav_util_move_threat

```gml
gmnav_util_move_threat(layer, profiles, old_rect, new_rect);
```

| Argument | Type | Description |
|---|---|---|
| layer | Struct | The layer |
| profiles | Array | Every profile that reads it |
| old_rect | Array | `[c1, r1, c2, r2]`, the footprint being cleared |
| new_rect | Array | `[c1, r1, c2, r2]`, the footprint being written |

After a threat moves, clear the footprint it left and rebake both rectangles
for every profile that reads the layer. Both rects, always, which is the
pattern the docs warn about elsewhere. This function exists so nobody has to
remember the rule twice.

**Example:**

```gml
// a turret that has just moved
var _old = old_footprint;
var _new = gmnav_costlayer_stamp_radial(danger, x, y, 200, 8, 2);

gmnav_util_move_threat(danger, [soldier, scout], _old, _new);
old_footprint = _new;
```

### Overlay authoring

### gmnav_util_overlay_room

```gml
gmnav_util_overlay_room(ov, c1, r1, c2, r2, layer);
```

**Returns:** Integer, the count of cells added

Fill a rectangle with overlay cells. Returns how many were actually created,
which may be less than the rectangle if some cells already existed.

### gmnav_util_overlay_bridge

```gml
gmnav_util_overlay_bridge(grid, ov, c1, r1, c2, r2, layer);
```

**Returns:** Array `[first_node, last_node]`

A straight run of overlay cells from one point to the other, with links at
each end to the ground below. Handles horizontal, vertical and diagonal runs.
The two links are the only edges you need, because cells on one layer are
neighbours by the ordinary neighbour table.

**Example:**

```gml
// a five cell bridge crossing a road at column 5
gmnav_util_overlay_bridge(grid, ov, 5, 4, 5, 8, 1);
gmnav_overlay_finish(ov);
```

### Target selection

### gmnav_util_nearest_in_array

```gml
gmnav_util_nearest_in_array(x, y, items);
```

**Returns:** The array entry, or `undefined`

The array entry closest to a point by straight line distance. Uses `_items[i].x`
and `_items[i].y`, so it works on agents, structs, or anything with those two
fields.

### gmnav_util_agents_within_radius

```gml
gmnav_util_agents_within_radius(x, y, agents, radius);
```

**Returns:** Array

Every entry closer than the radius. The array to pass is usually the same one
you gathered for avoidance.

### gmnav_util_agents_sorted_by_distance

```gml
gmnav_util_agents_sorted_by_distance(x, y, agents);
```

**Returns:** Array, a copy sorted nearest first

A copy of the array sorted by straight line distance. Handy for threat
priority and for picking the closest target with an early break.

### gmnav_util_reachable_nearest

```gml
gmnav_util_reachable_nearest(grid, from_node, candidates, profile, max_steps);
```

**Returns:** Node id, or `GMNAV_NO_NODE`

The candidate the search can actually reach, and among those, the one with
the lowest path cost. Unlike `nearest_in_array`, this respects walls — a
target twenty pixels away on the other side of a river does not win.

Costs one search per candidate, so keep the list short.

**Example:**

```gml
var _targets = [spawn_a_node, spawn_b_node, spawn_c_node];
var _best = gmnav_util_reachable_nearest(grid, my_node, _targets);

if (_best != GMNAV_NO_NODE) {
    gmnav_agent_goto(agent, gmnav_grid_node_to_world(grid, _best));
}
```

### World-space queries

### gmnav_util_cost_at_world

```gml
gmnav_util_cost_at_world(layer, x, y);
```

**Returns:** Real, 0 if the position is off the map

The layer value under a world position. Reads the value at the cell containing
the point.

### gmnav_util_clearance_at_world

```gml
gmnav_util_clearance_at_world(grid, x, y, layer);
```

**Returns:** Integer, 0 if there is nothing there

The clearance at a world position.

### gmnav_util_danger_around

```gml
gmnav_util_danger_around(layer, x, y, radius);
```

**Returns:** Real

The highest layer value in a disc around a point. "How bad is it here"
without committing to a specific cell.

### Path following

The path object gives you a list of waypoints and a total length. These give
you "where will I be in N pixels along it", which most agents eventually want.

### gmnav_util_path_waypoint_index

```gml
gmnav_util_path_waypoint_index(path, distance);
```

**Returns:** Integer

The waypoint index the path has reached at a given distance along it. The
inverse of `gmnav_path_sample`.

### gmnav_util_path_direction_at

```gml
gmnav_util_path_direction_at(path, distance);
```

**Returns:** Real, degrees

The heading of the path at a distance along it. Aim a turret, orient a sprite,
angle a trail.

### gmnav_util_path_lookahead

```gml
gmnav_util_path_lookahead(path, distance, ahead);
```

**Returns:** Array `[x, y]`

A point N pixels further along the path than a given distance. Clamped at
the ends. The "follow the road ahead" position for anticipation.

### gmnav_util_path_length_between

```gml
gmnav_util_path_length_between(path, from, to);
```

**Returns:** Real

The distance along the path between two distance values. For "how much is
left" style readouts.

### Grid validation

Level design questions: is the map connected, can anything reach the
objective, where are the dead zones. Run these in a tool, on level load, or
from a debug key. Not per frame.

### gmnav_util_reachable_set

```gml
gmnav_util_reachable_set(grid, from_node, need_clear);
```

**Returns:** Array of node ids

Every node reachable from a starting point. Flood fill, no cost involved, no
search budget. Follows authored overlay links, so a deck joined by a stair
reads as part of the floor it connects to.

### gmnav_util_is_connected

```gml
gmnav_util_is_connected(grid, need_clear);
```

**Returns:** Boolean

True when every walkable cell can be reached from every other. False means
the map has islands, which is usually a level design bug rather than a
feature.

### gmnav_util_unreachable_from

```gml
gmnav_util_unreachable_from(grid, from_node, need_clear);
```

**Returns:** Array of node ids

Every walkable node that cannot be reached from a point. The complement of
`reachable_set`, which is what you actually want to draw when a level has
islands.

### Flow field to path

### gmnav_util_flowfield_to_path

```gml
gmnav_util_flowfield_to_path(grid, field, from_node, max_hops);
```

**Returns:** Path struct, or `undefined` if the chain loops or does not reach a goal

Walk the field's `next` chain from a start, return a path object. No search
runs — the field already knows the route. Useful for previews, tooling, and
for handing a field route to code that expects a path object.

### Line of sight

### gmnav_util_has_line_of_sight

```gml
gmnav_util_has_line_of_sight(grid, x1, y1, x2, y2, radius);
```

**Returns:** Boolean

Whether a straight line from one world point to another is unobstructed for
a body of a given radius. Radius 0 is the point test the framework already
does. Useful for stealth, vision cones and sniper AI.

### Repath staggering

When a group of agents share a repath trigger, they all ask on the same frame
and the queue fills. Giving each a slightly different gap and offset spreads
them across the frame.

### gmnav_util_stagger_repath_gaps

```gml
gmnav_util_stagger_repath_gaps(agents, base_gap, jitter);
```

Give each agent a `repath_gap` spread around a base value. Call once at setup.
Cheap way to stop a crowd synchronising.

### gmnav_util_stagger_repath_offsets

```gml
gmnav_util_stagger_repath_offsets(agents, frame_span);
```

Give each agent a different `repath_at` offset, so their first repath lands on
different frames. Call once at setup, not per frame.

### Motion tracker

An agent that has not moved for a while is stuck. Detection needs history, and
history needs state the framework does not carry. These two functions are a
tiny companion struct rather than a field on the agent.

### gmnav_util_motion_tracker_create

```gml
gmnav_util_motion_tracker_create(frames, min_dist);
```

**Returns:** Struct

A tracker that watches for N frames and reports stuck if the agent moved less
than a distance in that time.

### gmnav_util_motion_tracker_update

```gml
gmnav_util_motion_tracker_update(tracker, x, y);
```

**Returns:** Boolean, whether the agent has been stationary for the window

Push a position, get back whether the agent is stuck. Resets automatically on
movement.

**Example:**

```gml
// per agent, per frame
if (gmnav_util_motion_tracker_update(agent_tracker, agent.x, agent.y)) {
    // five seconds without moving, give up on this goal
    gmnav_agent_stop(agent);
}
```

### Spawning

### gmnav_util_spawn_points_around

```gml
gmnav_util_spawn_points_around(grid, x, y, count, radius, max_attempts);
```

**Returns:** Array of `[x, y]`

Positions evenly spaced on a circle around a point, each snapped to the
nearest open cell. May return fewer than `count` if some snap failed.

### gmnav_util_spawn_points_in_rect

```gml
gmnav_util_spawn_points_in_rect(grid, c1, r1, c2, r2, count, max_attempts);
```

**Returns:** Array of `[x, y]`

`count` random open positions inside a cell rectangle, in world space.
Duplicate cells are allowed, so pass a count smaller than the rectangle if
you want them distinct.

### Formations

### gmnav_util_formation_grid_offsets

```gml
gmnav_util_formation_grid_offsets(count, cols, spacing);
```

**Returns:** Array of `[dx, dy]`

Offsets for a rectangular block formation, centred on 0. One per slot, in
row-major order.

### gmnav_util_formation_ring_offsets

```gml
gmnav_util_formation_ring_offsets(count, radius, phase);
```

**Returns:** Array of `[dx, dy]`

Offsets on a circle, centred on 0, in order around the ring. `phase` rotates
the whole ring in degrees.

### gmnav_util_send_group_formation

```gml
gmnav_util_send_group_formation(agents, grid, cx, cy, offsets, priority);
```

**Returns:** Integer, how many agents accepted

Send a group to a formation centred on a world point. Pairs with the two
offset builders above.

**Example:**

```gml
var _offsets = gmnav_util_formation_grid_offsets(9, 3, 40);
gmnav_util_send_group_formation(squad, grid, target_x, target_y, _offsets);
```

---

## Enum Reference

### gmnav_layout

Which projection a grid uses. Set on the layout and never changed afterwards.

| Member | Description |
|---|---|
| `ORTHO` | Square or rectangular tiles, the usual top down case |
| `ISO_DIAMOND` | Classic 2:1 isometric, rows and columns run diagonally on screen |
| `ISO_STAGGERED` | Offset rows, which changes which cells are neighbours |
| `HEX_POINTY` | Hexagons with a point at the top |
| `HEX_FLAT` | Hexagons with a flat edge at the top |

```gml
layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 64, 32);
```

The search never reads this directly. It asks the layout which cells are
neighbours and what a step costs, so changing projection changes a line of setup
and nothing else in your game.

**Careful:** on `ISO_STAGGERED` the neighbours of a cell depend on whether its
row is odd or even. A wall drawn as a straight run of columns on screen is not a
straight run of cells, which surprises people building staggered maps by hand.

---

### gmnav_neighbours

Which steps exist from a cell.

| Member | Description |
|---|---|
| `FOUR` | Cardinals only. Heuristic becomes Manhattan |
| `EIGHT` | Cardinals and diagonals. Heuristic becomes octile |
| `SIX` | Hex adjacency. Heuristic becomes true hex distance |

```gml
layout = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32, gmnav_neighbours.FOUR);
```

`FOUR` suits grid locked tactics games and characters with four directional
sprites. `EIGHT` is the default for square grids. `SIX` should always be used
with hex layouts.

The heuristic changes to match automatically, which matters: octile on a four
direction grid would overestimate the true cost and quietly break optimality.

**Careful:** this constrains the **search**. Path smoothing is a separate pass
and has to be told separately, with the `headings` argument to
`gmnav_path_smooth`, or a cardinal route will be collapsed into a diagonal the
unit cannot walk.

---

### gmnav_costmode

How a step's cost is measured. Only meaningful on `ORTHO` and `ISO_DIAMOND`, and
only when tiles are not square.

| Member | Description |
|---|---|
| `LOGICAL` | Counts moves. Cardinal 1, diagonal 1.4142, regardless of tile shape |
| `VISUAL` | Counts pixels. Cost reflects distance actually covered on screen |

```gml
layout = gmnav_layout_create(gmnav_layout.ORTHO, 64, 32,
                             gmnav_neighbours.EIGHT, gmnav_costmode.VISUAL);
```

`LOGICAL` is what a turn based game wants: two moves cost two moves whichever
way they go. `VISUAL` is what a real time game wants: a unit crossing 64 pixels
takes twice as long as one crossing 32, so the path should know that.

Staggered and hex always measure geometrically, because their offset coordinates
are not a metric space and logical counting there would be meaningless rather
than merely different.

---

### gmnav_heuristic

How a search estimates remaining cost.

| Member | Description |
|---|---|
| `AUTO` | Picks the right one from the layout. Almost always correct |
| `ZERO` | No estimate, turning A\* into Dijkstra |

```gml
search = gmnav_search_create(grid, gmnav_heuristic.ZERO);
```

`ZERO` explores evenly in every direction and does far more work for the same
answer, which sounds useless and is valuable for exactly one thing: verifying a
suspicious path. Dijkstra is optimal by construction, so if `AUTO` and `ZERO`
disagree on total cost, the problem is the heuristic rather than your map.

---

### gmnav_state

What a search, ticket or field is doing.

| Member | Description |
|---|---|
| `IDLE` | Not started |
| `WORKING` | In progress, come back next frame |
| `FOUND` | Succeeded, a result is waiting |
| `FAILED` | No route exists, and will not unless the map changes |

```gml
if (ticket.state == gmnav_state.FOUND) {
    path = gmnav_scheduler_get_path(ticket);
}
```

Handle three cases, not two. Code that only checks for `FOUND` holds a failed
ticket forever and the unit stands still for no visible reason.

---

### gmnav_priority

Which band a request queues in.

| Member | Description |
|---|---|
| `LOW` | Background work: wandering, idle repositioning |
| `NORMAL` | The default. Ordinary movement orders |
| `HIGH` | Genuinely urgent and genuinely rare |
| `IMMEDIATE` | Bypasses the budget, runs to completion in the call |

```gml
ticket = gmnav_scheduler_request(sched, _a, _b, gmnav_priority.HIGH);
```

Within a band the oldest request goes first, which stops a queue reshuffling
around its own oldest member.

**Careful:** priority orders a queue, it does not create capacity. If everything
in your game is `HIGH` you have exactly the queue you would have had with no
priorities at all, plus false confidence.

**`IMMEDIATE` does not bypass the workspace pool.** If every workspace is busy
there is nowhere to run and the request falls back into the queue like any
other, so check the ticket state rather than assuming a path arrived.

---

### gmnav_domain

Which kind of target a scheduler is driving. Read from what you pass to
`gmnav_scheduler_create`; you never set it.

| Member | Description |
|---|---|
| `GRID` | A navigation grid |
| `PLATFORM` | A platformer graph |

---

### gmnav_link

How one node is reached from another.

| Member | Description |
|---|---|
| `WALK` | Along a surface, no change in height |
| `FALL` | Off an edge, gravity does the rest |
| `JUMP` | A launch with a stored velocity |
| `STAIR` | An authored overlay link between two surfaces |

```gml
switch (links[i]) {
    case gmnav_link.JUMP: press_jump(); break;
    case gmnav_link.FALL: run_off_edge(); break;
}
```

`WALK`, `FALL` and `JUMP` come from the platformer bake. `STAIR` is the default
type for `gmnav_overlay_link` and marks a change of surface on a grid.

**Note:** the type is stored and reported but nothing in the framework reads it
back to change behaviour. It is there so your code can tell a stair from a
ladder when it inspects a route.

---

### gmnav_bake

Which phase a sliced platformer bake is in.

| Member | Description |
|---|---|
| `IDLE` | Not started |
| `SURFACES` | Scanning for standing positions. Fast |
| `LINKS` | Simulating arcs from each of them. The expensive part |
| `DONE` | Finished |

```gml
if (gmnav_platgraph_bake_step(pg, 256) == gmnav_bake.DONE) start_level();
```

Enough for a two stage loading display.

---

### gmnav_curve

How `gmnav_path_curve` reshapes a path.

| Member | Description |
|---|---|
| `NONE` | The default. Changes nothing |
| `CORNER` | Rounds each turn to a radius, straight legs untouched |
| `SPLINE` | A curve through every waypoint, nothing stays straight |

```gml
agent.curve_mode = gmnav_curve.CORNER;
```

`CORNER` is the safer default. A spline passes through its waypoints but is not
bounded by them, so it overshoots at sharp turns.

---

### gmnav_pmode

The platform agent's internal state. Reported, not set.

| Member | Description |
|---|---|
| `GROUND` | Walking along a surface |
| `LINK` | Performing a fall or jump arc |
| `SETTLE` | Landing and re-acquiring its node |

`gmnav_platagent_airborne` is the readable version of this and is what you
should branch on.

---

## Macro Reference

### GMNAV_NO_NODE

The value returned when a node does not exist. It is -1.

```gml
var _n = gmnav_grid_node(grid, _c, _r);

if (_n == GMNAV_NO_NODE) return;   // out of bounds
```

Every function taking a node handles this safely, but your own arithmetic will
not, so check it after any lookup that can fail.

---

### GMNAV_INF

Infinity, used for unreachable distances in flow fields.

```gml
if (field.dist[_n] == GMNAV_INF) {
    // nothing can get there from any seeded goal
}
```

Prefer `gmnav_flowfield_is_reachable` in normal code; this is for reading the
arrays directly.

---

### GMNAV_FLAG_BLOCKED

The bit marking a cell impassable. It is 1.

```gml
if ((grid.flags[_n] & GMNAV_FLAG_BLOCKED) != 0) {
    // solid
}
```

`gmnav_grid_is_blocked` is the readable form and handles overlay nodes too.

---

### GMNAV_FLAG_ONEWAY

The bit marking a platform that can be jumped up through but not fallen down
through. It is 2.

```gml
gmnav_grid_set_flag(grid, _c, _r, GMNAV_FLAG_ONEWAY, true);
```

Read by the platformer bake when simulating arcs.

**Careful:** this is partial. Standing on and jumping up through a one way
platform work. Dropping down through one is not implemented, so a one way deck
stacked over a solid ledge routes the long way round.

---

### Debug colours

`GMNAV_DBG_BLOCKED`, `GMNAV_DBG_PATH`, `GMNAV_DBG_GOAL`, `GMNAV_DBG_AGENT`,
`GMNAV_DBG_OPEN`, `GMNAV_DBG_CLOSED` and `GMNAV_DBG_DECK`.

```gml
gmnav_debug_draw_path(grid, path, cfg, GMNAV_DBG_GOAL);
```

Pass any of them where a view takes a colour, or pass your own.

---

## Config Reference

### gmnav_init

**Syntax:**

```gml
gmnav_init(overrides);
```

| Argument | Type | Description |
|---|---|---|
| overrides | Struct | Optional. Settings to change from their defaults |

**Returns:** N/A

**Example:**

```gml
// once, at game start, before creating anything
gmnav_init();

// or with changes
gmnav_init({
    DEFAULT_BUDGET : 3000,
    EDIT_RING      : 64
});
```

The above code initialises GMNav's settings.

**Call this before anything else.** Every function that reads a config value
fails without it, so a project that forgets crashes on its first search rather
than degrading gracefully.

Unknown keys are ignored with a debug message rather than silently accepted, so
a typo in a setting name tells you.

### The settings

| Setting | Default | What it does |
|---|---|---|
| `PLAT_MAX_SIM` | 300 | Hard cap on simulated frames per arc. Stops a bake hanging on a runaway trajectory |
| `PLAT_MAX_LINKS` | 24 | Most outgoing links kept per platform node. Bounds graph size on dense levels |
| `PLAT_FALL_WALK_CELLS` | 4 | How far a fall may walk to reach a ledge edge before dropping |
| `DEFAULT_BUDGET` | 2000 | Node expansions per frame when none is given |
| `HEAP_INIT` | 256 | Initial open set capacity. Grows as needed |
| `MAX_STEPS` | 1000000 | Hard abort guard per search. A safety net, not a tuning knob |
| `CLEARANCE_MAX` | 16 | Largest clearance value stored per cell |
| `EDIT_RING` | 32 | Recent grid edits kept for scoped repathing |

`EDIT_RING` is read when a **grid is created**, so changing it affects grids made
afterwards rather than existing ones. A larger ring holds more history and costs
a slightly longer scan; a smaller one overflows sooner and falls back to
conservative repathing more often.

---

## Struct Reference

Fields you are expected to read or write. Internal scratch used during a build
is omitted.

### Grid

| Field | Type | Description |
|---|---|---|
| `width`, `height` | Integer | Dimensions in cells |
| `count` | Integer | `width * height`. Overlay node ids begin here |
| `layout` | Struct | Layout descriptor |
| `flags` | Array | One packed integer per cell |
| `cost` | Array | Base terrain cost per cell |
| `clear` | Array | Clearance values, `undefined` until built |
| `height_z` | Array | Elevation per cell, `undefined` until first set |
| `layer_lift` | Real | Pixels between layers, absent until set |
| `overlay` | Struct | Attached overlay, absent until one is created |
| `version` | Integer | Bumped on every genuine mutation |
| `edit_cap` | Integer | Recent edit rectangles kept. Set at creation, do not write |

### Layout

| Field | Type | Description |
|---|---|---|
| `mode` | Enum | A `gmnav_layout` member |
| `tile_w`, `tile_h` | Real | Tile bounding box |
| `neighbours` | Enum | A `gmnav_neighbours` member |
| `cost_mode` | Enum | A `gmnav_costmode` member |
| `origin_x`, `origin_y` | Real | World origin of cell (0,0) |

### Overlay

| Field | Type | Description |
|---|---|---|
| `grid` | Struct | Grid it is attached to |
| `base` | Integer | Id offset. Overlay cell 0 is this node id |
| `count` | Integer | Cells held |
| `max_layer` | Integer | Highest layer index in use |
| `cost` | Array | Base cost per cell, independent of the ground below |
| `clear` | Array | Clearance per cell, computed by `finish` |
| `offset` | Array | Fraction of a layer each cell sits below its own |
| `ready` | Boolean | Whether authoring happened since the last `finish` |

### Search

| Field | Type | Description |
|---|---|---|
| `state` | Enum | A `gmnav_state` member |
| `profile` | Struct | Cost profile, or `undefined` |
| `need_clear` | Integer | Minimum clearance required |
| `max_climb`, `max_drop` | Real | Elevation limits |
| `stale` | Boolean | Grid changed after this search began |
| `expansions` | Integer | Cells settled |
| `slot_g_final` | Real | Total cost of the found path |

### Ticket

| Field | Type | Description |
|---|---|---|
| `state` | Enum | A `gmnav_state` member |
| `priority` | Enum | A `gmnav_priority` member |
| `path` | Array | Node ids, empty unless found |
| `links` | Array | `gmnav_link` values, platformer domain only |
| `stale` | Boolean | Grid changed while this request was in flight |

### Path

| Field | Type | Description |
|---|---|---|
| `grid` | Struct | Grid the nodes belong to |
| `nodes` | Array | Node ids. Cleared by `simplify`, kept by `curve` |
| `px`, `py` | Array | World coordinates per waypoint |
| `count` | Integer | Waypoint count |
| `length` | Real | Total world length |
| `version` | Integer | Grid version when built, used for scoped repathing |

### Cost layer

| Field | Type | Description |
|---|---|---|
| `grid` | Struct | Grid it covers |
| `values` | Array | One value per node, base and overlay |
| `version` | Integer | Bumped on change, watched by profiles |

### Cost profile

| Field | Type | Description |
|---|---|---|
| `layers` | Array | Layers in this profile |
| `weights` | Array | Weight per layer, same order |
| `resolved` | Array | Flattened cost per node, what the search reads |
| `baked` | Boolean | Whether a bake has happened at all |

### Agent

| Field | Type | Default | Description |
|---|---|---|---|
| `x`, `y` | Real | - | Position. Yours to write |
| `vx`, `vy` | Real | 0 | Proposed velocity, written every update |
| `radius` | Real | 8 | Avoidance, arrival, and smoothing body check |
| `speed` | Real | 2 | Maximum speed |
| `accel` | Real | 0.35 | How sharply desired velocity is approached |
| `arrive_dist` | Real | 24 | Start easing off inside this range |
| `reach_dist` | Real | 4 | Close enough, journey complete |
| `arrived` | Boolean | false | Latched until the next `goto` or `stop` |
| `failed` | Boolean | false | Last goal could not be routed to |
| `layer` | Integer | 0 | Surface the agent is on |
| `goal_layer` | Integer | 0 | Surface the goal is on |
| `profile` | Struct | undefined | Passed on every request and to smoothing |
| `need_clear` | Integer | 0 | Passed on every request |
| `max_climb`, `max_drop` | Real | undefined | Passed on every request and to smoothing |
| `headings` | Integer | 0 | Headings smoothing may use |
| `curve_mode` | Enum | `NONE` | Curve applied after smoothing |
| `curve_radius` | Real | 16 | Corner radius when curving |
| `curve_steps` | Integer | 4 | Samples per arc |
| `repath_gap` | Integer | 20 | Frames between repath attempts |
| `avoid_str` | Real | 1.0 | Separation strength, 0 disables |
| `avoid_range` | Real | 3.0 | Separation reach, in multiples of radius |

### Movement

| Field | Type | Description |
|---|---|---|
| `gravity` | Real | Added to vertical velocity each frame |
| `jump_vel` | Real | Jump velocity at full strength |
| `run_speed` | Real | Horizontal speed on the ground |
| `air_speed` | Real | Horizontal speed in the air |
| `max_fall` | Real | Terminal fall speed |
| `width`, `height` | Real | Character box |
| `jump_levels` | Integer | Jump strengths sampled |
| `jump_bias` | Real | Multiplier on jump link costs |

### Platformer graph

| Field | Type | Description |
|---|---|---|
| `grid` | Struct | Underlying navigation grid |
| `move` | Struct | Movement model |
| `count` | Integer | Standing positions found |
| `edge_start` | Array | CSR row offsets, length `count + 1` |
| `edge_to` | Array | Destination node per edge |
| `edge_cost` | Array | Traversal cost in frames |
| `edge_type` | Array | `gmnav_link` value per edge |
| `edge_vx`, `edge_vy` | Array | Launch velocity per edge |
| `node_x`, `node_y` | Array | World position per node |

### Platform agent

| Field | Type | Description |
|---|---|---|
| `x`, `y` | Real | Position. **Written by the framework**, read by you |
| `vx`, `vy` | Real | Current velocity during an arc |
| `node` | Integer | Node the agent is on or heading to |
| `arrived` | Boolean | Latched until the next `goto` or `stop` |
| `desync` | Integer | Frames where replay and world disagreed. Should stay 0 |

### Flow field

| Field | Type | Description |
|---|---|---|
| `grid` | Struct | Grid it covers |
| `profile` | Struct | Profile it was built under |
| `dist` | Array | Cost to nearest goal per node |
| `dirx`, `diry` | Array | Normalised world direction per node |
| `next` | Array | Node each cell steps to. Read this when a step may change layer |
| `goals` | Array | Seeded goal node ids |
| `max_dist` | Real | Distance cap |
| `state` | Enum | A `gmnav_state` member |

### Scheduler

| Field | Type | Description |
|---|---|---|
| `domain` | Enum | Detected from the target |
| `budget` | Integer | Node expansions per frame, shared |
| `concurrent` | Integer | Maximum simultaneous searches |
| `last_pops` | Integer | Pops used on the most recent update that ran searches |
| `last_active` | Integer | Searches running on the most recent update that ran searches |

---

## Known Behaviours

Things that are deliberate, surprising, or both.

**A free cell is not a free position.** `gmnav_grid_is_blocked` asks about a
cell. An agent with a radius needs a position its whole body fits in, and a
point two pixels from a wall sits in a perfectly open cell. That is what
clearance is for.

**Agents that never register arrival.** `reach_dist` defaults to 4 pixels. If an
agent cannot physically reach within 4 pixels of its goal, because its body is
stopped by a wall first, it never latches `arrived` and keeps pushing. Raise
`reach_dist` past the agent radius, or validate goals with
`gmnav_clearance_nearest`.

**Avoidance is separation, not reciprocal avoidance.** It stops crowds stacking
into one pixel, which is what most games need. It will not resolve two agents
walking into each other in a one tile corridor: both push symmetrically, both
stall, neither yields. Plan for that at the design level.

**Avoidance does not know about walls.** It repels agents from other agents
only. When a crowd compresses against geometry it pushes bodies into walls, and
your movement code absorbs that.

**Editing the grid does not rebuild anything.** Flow fields, clearance and
platformer graphs go out of date and say so. Rebuilding is your call, because
only you know whether it is worth the frame.

**A suspended search does not re-validate.** Settled cells are never revisited,
so a wall landing on ground a search has already crossed off goes unnoticed. The
contract is termination plus the stale flag, not path validity.

**Smoothing needs telling about everything.** Elevation limits, body radius,
headings and cost profile each close a way a shortcut could be wrong. Without
them a shortcut will climb a cliff, clip a corner, take an illegal heading, or
walk back through ground the search paid to avoid.

**Smoothing and curving are refused on staggered and hex.** On those layouts a
straight line in cell coordinates says nothing reliable about whether a
character could walk it. `gmnav_path_simplify` works everywhere.

**A deck narrower than a body will not smooth.** The corridor test asks whether
the whole body fits along the line, and a one cell wide bridge cannot contain a
wider body, so every shortcut across it is refused and every deck cell survives
as a waypoint. That is correct rather than wasteful.

**Overlay offsets are drawn height, not climb cost.** They are read by world
positions and the debug renderer, and are not consulted by `max_climb` or
`max_drop`. For a slope only some units can take, use `gmnav_grid_set_height`.

**The surface between two cells belongs to your renderer.** A path across a ramp
is a straight interpolation between two cell centres, so it looks right only if
your ramp is drawn interpolated too.

**Cost cannot attract.** A negative profile weight is legal and resolved cost
still clamps at 1, which is the same guarantee as the cost floor. Cost fields
push; to pull a unit toward something, seed it as a goal in a flow field.

**Stamp peaks want to be modest.** Within about an order of magnitude of the
base cost of 1. A peak far above that puts every reasonable weight past the
point where a unit's decision flips, so tuning appears to do nothing.

**Stamps and region clearing cover one surface at a time.**
`gmnav_costlayer_stamp_radial`, `stamp_path`, `clear_region` and
`gmnav_costprofile_bake_region` all take a trailing `ov_layer` argument. The
default of 0 writes base cells, matching prior behaviour. Pass 1 or greater to
write cells on that overlay layer instead. A stamp at a position over a bridge
does not automatically reach both the road and the deck; call it once per
surface, and rebake the profile once per surface too. A stamp on a deck that has
not been rebaked with the same `ov_layer` is invisible to the search.

**Region baking is per profile.** A moving threat read by three unit types needs
all three profiles rebaked, over both the old and the new rectangle.

**`gmnav_costprofile_add` appends.** Calling it twice with the same layer counts
that layer twice and the weights sum. Use `gmnav_costprofile_set_weight` to
change an existing weight.

**`gmnav_scheduler_is_ready` means found, not finished.** A failed request is
finished but not ready. Check `ticket.state` if you need to tell them apart.

**`IMMEDIATE` bypasses the budget, not the workspace pool.** If every workspace
is busy the request falls back into the queue and resolves later like any other.

**`GMNAV_FLAG_ONEWAY` is partial.** Standing on and jumping up through a one way
platform work. Dropping down through one is not implemented, so a one way deck
stacked over a solid ledge routes the long way round.

**Clearance is `ORTHO` and `ISO_DIAMOND` only.** On staggered and hex a
Chebyshev radius in cell indices does not correspond to a disc in world space,
so `gmnav_clearance_build` returns `false` and clearance requirements are ignored
rather than failing every request.

**Forgetting to release a search leaks a workspace.** The grid lends out a small
fixed number, so slots disappear one by one until nothing can start. If searches
stop working after a long session, look for a path through your code that
acquires without releasing.
