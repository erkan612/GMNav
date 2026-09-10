# Getting Started with GMNav

GMNav is a pathfinding and navigation framework for GameMaker. It covers
top-down grids in four projections, terrain with height, surfaces that stack
over each other, side-view platformer navigation with baked jump arcs, layered
terrain costs, flow fields, agent clearance, and local avoidance, all under a
shared per-frame budget so a large crowd never stalls your game loop.

This guide gets you from an empty project to a moving agent, then shows each
subsystem in the order you are likely to need it. For the full API see
[API Reference](RawDocumentation.md). For worked examples with diagrams see the
tutorial series.

---

## Install

Import the `.yymps`. You will get script assets under a folder called `GMNav`,
the functions they contain are all prefixed `gmnav_`. Nothing else is added to
your project and nothing runs on its own.

Everything is plain GML structs and arrays. There are no objects to place, no
persistent controller, and no global state beyond one settings struct.

---

## Initialise once

Call this before creating anything, once, at game start.

```gml
gmnav_init();
```

Every setting has a default, so calling it with no arguments is the normal case.
Pass a struct to change any of them:

```gml
gmnav_init({ DEFAULT_BUDGET : 3000 });
```

Unknown keys are ignored with a debug message rather than silently accepted. See
the Config Reference in the API docs for the full list.

---

## Five minutes to a moving agent

Three things: a grid describing where you can walk, a scheduler that runs
searches inside a budget, and an agent that follows the result.

Create Event:

```gml
tile = 32;

layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);

// mark the walls
gmnav_grid_fill_blocked(grid, 10, 4, 10, 14, true);
gmnav_grid_set_blocked(grid, 6, 6, true);

sched = gmnav_scheduler_create(grid, 2000);
agent = gmnav_agent_create(sched, x, y, 8, 2.5);
```

Step Event:

```gml
if (mouse_check_button_pressed(mb_left)) {
    gmnav_agent_goto(agent, mouse_x, mouse_y);
}

gmnav_scheduler_update(sched);   // once per frame, before the agents
gmnav_agent_update(agent);       // steers, writes agent.vx and agent.vy

// GMNav never moves anything. You apply the velocity and you own collision.
x += agent.vx;
y += agent.vy;
agent.x = x;
agent.y = y;
```

Draw Event, while you are getting your bearings:

```gml
gmnav_debug_draw_grid(grid);
gmnav_debug_draw_agent(agent);
gmnav_debug_draw_stats(sched);
```

That is a complete working setup. Everything below is refinement.

### The one thing to internalise

GMNav computes and steers. It does not move, and it does not collide.
`gmnav_agent_update` writes a desired `vx` and `vy` onto the agent and stops
there. Applying that velocity, testing it against your walls, and resolving
overlaps is your code. This is deliberate, because every project already has
its own movement and collision, and a navigation library that fights it is
worse than useless.

There is exactly one exception, `gmnav_platagent`, and the reason is explained
where it appears below.

---

## Grids

A grid is cells plus flags plus costs. Build it however suits you.

```gml
gmnav_grid_set_blocked(grid, col, row, true);
gmnav_grid_fill_blocked(grid, c1, r1, c2, r2, true);

gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Collision"));
gmnav_grid_import_dsgrid(grid, my_ds_grid);
gmnav_grid_import_callback(grid, function(_col, _row) {
    return place_meeting(_col * 32 + 16, _row * 32 + 16, obj_wall);
});
```

Converting between the world and the grid:

```gml
var _node = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);
var _p    = gmnav_grid_node_to_world(grid, _node);   // [x, y]

var _col  = gmnav_grid_col(grid, _node);
var _row  = gmnav_grid_row(grid, _node);
```

A node is an integer. For base cells it is `row * width + col`.
`GMNAV_NO_NODE` is -1 and means out of bounds. Check for it. Every function
that takes a node handles it safely, but your own code will not.

Editing a grid bumps its version, which marks dependent searches, flow fields,
clearance data and platformer graphs as out of date. You are told, but nothing
is rebuilt behind your back.

---

## The scheduler and why searches are resumable

A single A* across a large grid can take longer than a frame. GMNav splits
every search into steps and runs as many as the budget allows, so a hundred
agents asking at once costs you a fixed amount of time rather than a spike.

```gml
sched = gmnav_scheduler_create(grid, 2000, 4);
```

The second argument is node expansions per frame across all searches combined.
The third is how many searches may be in flight at once. `2000` is a sensible
starting point on a mid-sized grid. Lower it until you see paths taking
visibly long to arrive, then go back up one step.

If you are not using agents, drive the scheduler directly:

```gml
// once
ticket = gmnav_scheduler_request(sched, start_node, goal_node,
                                 gmnav_priority.NORMAL);

// every frame
gmnav_scheduler_update(sched);

if (ticket.state == gmnav_state.FOUND) {
    path = gmnav_scheduler_get_path(ticket);   // array of nodes
    ticket = undefined;
} else if (ticket.state == gmnav_state.FAILED) {
    // no route exists
    ticket = undefined;
}
```

Priorities are `LOW`, `NORMAL`, `HIGH` and `IMMEDIATE`. `IMMEDIATE` bypasses
the budget and completes in the frame it is requested, so use it for the
player and almost nothing else. It does not bypass the workspace pool, so if
every workspace is busy it falls back into the queue like any other request.
Check the state rather than assuming a path arrived.

### The stale contract

A search suspended mid-flight can outlive the grid it was searching. If you
block a cell while a search is running, the result may route through it.
GMNav marks such a result stale rather than silently returning a bad path.

```gml
if (ticket.state == gmnav_state.FOUND && !ticket.stale) {
    // safe to follow
}
```

For agents this is handled for you, and more carefully than a bare stale flag:
an agent repaths only when a change lands on the part of its route it has still
to walk, rather than every time anything anywhere on the map moves.

---

## Agents

An agent wraps a path with steering, arrival and optional local avoidance.

```gml
agent = gmnav_agent_create(sched, x, y, 8, 2.5);   // radius, speed
```

Fields worth knowing, all writable at any time:

```gml
agent.speed        = 3;      // units per frame
agent.accel        = 0.35;   // 0 to 1, how sharply it turns
agent.arrive_dist  = 24;     // starts slowing inside this range
agent.reach_dist   = 4;      // counts as arrived inside this range
agent.avoid_str    = 1.0;    // 0 disables local avoidance
agent.avoid_range  = 3.0;    // multiples of radius

agent.profile      = my_profile;   // cost profile, if any
agent.need_clear   = 2;            // clearance, if the unit is wide
agent.headings     = 0;            // 0, 4 or 8. See Movement constraints
agent.curve_mode   = gmnav_curve.NONE;
```

Two latches tell you how a journey ended:

```gml
if (gmnav_agent_arrived(agent)) { /* got there */ }
if (gmnav_agent_failed(agent))  { /* no route existed */ }
```

Both stay true until the next `goto` or `stop`, which is what makes patrol
routes a single `if`. Without the second one, a failed request and a completed
journey look identical, since both end with no goal and no ticket.

Local avoidance needs a neighbour list, which you supply. GMNav does not keep
a spatial index for you, because your game almost certainly already has one:

```gml
var _near = [];
with (obj_unit) {
    if (id != other.id && point_distance(x, y, other.x, other.y) < 64) {
        array_push(_near, agent);
    }
}
gmnav_agent_update(agent, _near);
```

A neighbour only needs `x`, `y` and `radius`, so anything with those three
fields works.

Everything an agent does is a public call. It stores preferences and forwards
them; it invents nothing. If you write your own agent class, you lose nothing.

---

## Terrain costs

A cost layer marks parts of the grid as expensive rather than impassable. A
profile blends several layers, and a search uses the profile.

```gml
mud    = gmnav_costlayer_create(grid, "mud");
danger = gmnav_costlayer_create(grid, "danger");

gmnav_costlayer_set(mud, 12, 8, 3.0);                    // one cell
gmnav_costlayer_stamp_radial(danger, tx, ty, 96, 8, 2);  // a falloff blob

profile = gmnav_costprofile_create(grid, "infantry");
gmnav_costprofile_add(profile, mud,    1.0);
gmnav_costprofile_add(profile, danger, 2.5);

gmnav_costprofile_bake_if_dirty(profile);   // once per frame is fine
```

Point an agent at it:

```gml
agent.profile = profile;
```

Different agent types can hold different profiles over one shared grid, which
is how you get a scout that ignores mud and a tank that refuses to enter it.

For anything linear, a road, a patrol route, a spreading fire, stamp along a
polyline rather than approximating it with a chain of blobs:

```gml
var _rect = gmnav_costlayer_stamp_path(danger, [[x1, y1], [x2, y2]], 56, 8, 1);
```

Two things that save time later. Keep stamp peaks within about an order of
magnitude of the base cost of 1, or every profile weight you try will sit past
the point where a unit's decision flips and tuning will appear to do nothing.
And when a threat moves, clear and rebake **both** the old rectangle and the
new one, once per profile that reads the layer, or the old danger stays burned
in permanently.

---

## Flow fields

When many agents share one destination, do not give them each a search. Build
one field and have them all read it.

```gml
field = gmnav_flowfield_create(grid, profile);
gmnav_flowfield_build(field, [goal_node]);
```

Then per agent, per frame:

```gml
var _d = gmnav_flowfield_sample(field, x, y);   // [dx, dy], normalised
x += _d[0] * spd;
y += _d[1] * spd;
```

A field takes multiple goals, so a set of exits or capture points is one array
and every agent flows to its own nearest one.
`gmnav_flowfield_build` does the whole thing at once. For a big grid, use
`gmnav_flowfield_begin` and `gmnav_flowfield_step` to spread it over frames.

```gml
gmnav_flowfield_is_reachable(field, x, y);   // false means no route
gmnav_flowfield_cost_at(field, x, y);        // true travel cost to the nearest goal
if (gmnav_flowfield_is_stale(field)) gmnav_flowfield_build(field, [goal_node]);
```

`cost_at` is more useful than it looks. It is a real travel cost with walls,
terrain and danger accounted for, available for every unit on the map at one
array lookup, which makes it a far better input to a decision than straight
line distance.

---

## Clearance, for agents wider than one cell

A path through a one-cell gap is useless to a body three cells wide. Build a
clearance map once and searches will respect it.

```gml
gmnav_clearance_build(grid);

agent.need_clear = gmnav_clearance_for_radius(grid, agent.radius);
```

`gmnav_clearance_for_radius` converts a world radius into the cell count the
search needs. After editing the grid:

```gml
gmnav_clearance_build_if_stale(grid);
```

Clearance is capped at the `CLEARANCE_MAX` config setting, which is 16 cells by
default, and is available on `ORTHO` and `ISO_DIAMOND` only.

---

## Other projections

The layout owns all cell-to-world maths, so isometric and hex work exactly
like the orthogonal case. Change one line:

```gml
layout = gmnav_layout_create(gmnav_layout.ISO_DIAMOND,   64, 32);
layout = gmnav_layout_create(gmnav_layout.ISO_STAGGERED, 64, 32);
layout = gmnav_layout_create(gmnav_layout.HEX_POINTY,    48, 42,
                             gmnav_neighbours.SIX);
layout = gmnav_layout_create(gmnav_layout.HEX_FLAT,      42, 48,
                             gmnav_neighbours.SIX);
```

Hex layouts want `gmnav_neighbours.SIX`. Orthogonal defaults to `EIGHT`, and
`FOUR` gives you cardinal-only movement.

Everything else in this guide is unchanged. Costs, clearance, flow fields and
agents do not know or care which projection they are on.

---

## Ground with height

Give cells an elevation and tell a unit what it can manage.

```gml
gmnav_grid_set_height(grid, 12, 8, 3);
gmnav_grid_fill_height(grid, 10, 4, 20, 12, 3);

agent.max_climb = 1;
agent.max_drop  = 3;
```

The value is in whatever unit suits you. A grid with no heights set behaves
exactly as a flat one, and a unit with no limits set ignores heights entirely.

A one-way cliff falls out of this without a flag anywhere: a climb limit below
a drop limit is what almost everything that walks looks like. A ramp is simply
a run of cells whose heights step up by an amount the unit can take.

The limits are honoured by the search, by flow fields, by the scheduler and by
the agent. If you drive paths yourself, pass them to `gmnav_path_smooth` and
`gmnav_path_simplify` too, or a shortcut will cut straight up a cliff the
search walked around. A cliff is not blocked, and a ramp seen from above is a
straight line.

---

## Surfaces that stack

Height per cell cannot describe a bridge over a road, because that cell has two
answers. An overlay is a sparse set of extra walkable cells above the grid.

```gml
var _ov = gmnav_overlay_create(grid);

var _a = gmnav_overlay_add(_ov, 5, 4, 1);
var _b = gmnav_overlay_add(_ov, 5, 5, 1);
var _c = gmnav_overlay_add(_ov, 5, 6, 1);

gmnav_overlay_link(_ov, gmnav_grid_node(grid, 5, 3), _a, gmnav_link.STAIR, true);
gmnav_overlay_link(_ov, _c, gmnav_grid_node(grid, 5, 7), gmnav_link.STAIR, true);

gmnav_overlay_finish(_ov);
gmnav_grid_set_layer_lift(grid, 24);
```

Two rules keep this from becoming a second map you maintain by hand.

**A link is only needed where the layer changes.** Cells on one layer are
already neighbours, so a walkway needs a link at each end and nothing between.

**One layer per standable surface, not per unit of height.** A cliff three
lifts tall is one layer drawn tall.

For a slope, hand a run of cells to the ramp helper and it spaces their offsets
evenly:

```gml
gmnav_overlay_ramp(_ov, [_c1, _c2, _c3, _c4]);
```

Picking has no single answer, so the caller names a layer:

```gml
var _road = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 0);
var _deck = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 1);
var _top  = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

gmnav_agent_goto(agent, mouse_x, mouse_y, gmnav_priority.NORMAL, 1);
```

Overlay cells are real cells. They can be blocked, priced, measured for
clearance and drawn, and their properties are their own. Dear ground beneath a
bridge does not make the bridge dear.

---

## Shaping the path

Smoothing removes the staircase a grid search produces. Everything it needs to
know has to be passed in, and each argument closes a different way a shortcut
could be wrong.

```gml
gmnav_path_smooth(path, agent.max_climb, agent.max_drop,
                  agent.radius, agent.headings, agent.profile);

gmnav_path_anchor_start(path, x, y);
gmnav_path_anchor_end(path, goal_x, goal_y);

gmnav_path_curve(path, gmnav_curve.CORNER, 40, 5, agent.radius);
```

Smooth, anchor, then curve, in that order. Agents do this for you.

### Movement constraints

A character with four directional sprites cannot walk a diagonal, however clear
the line happens to be.

```gml
layout       = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32, gmnav_neighbours.FOUR);
agent.headings = 4;
```

Both are needed and they must agree. The neighbour set decides what steps the
search may take; the heading count decides which lines may replace them. Setting
headings to 4 on an eight-direction grid does not give cardinal movement,
because the diagonals are already in the path and smoothing can only remove
waypoints.

With a constraint set, smoothing also rewrites a staircase into the fewest legal
straight legs rather than leaving every step in place.

### Curves

```gml
agent.curve_mode   = gmnav_curve.CORNER;
agent.curve_radius = 40;
```

`CORNER` rounds each turn and leaves straight legs alone. `SPLINE` curves the
whole path. Every generated segment is checked against the same geometry the
search used, so a corner whose arc would clip keeps its sharp corner.

Do not curve a path whose headings you constrained, since a curve contains
every heading.

---

## Platformer navigation

Side-view navigation is a different graph. Instead of cells, GMNav scans for
standing surfaces and bakes links between them by simulating your actual
movement model, so a jump link exists only if the character can really make
that jump.

```gml
layout = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32);
grid   = gmnav_grid_create(40, 20, layout);
// ... mark the level ...

//                            gravity, jump_vel, run, max_fall, w,  h,  air, levels
move = gmnav_movement_create( 0.5,     12,       3,   12,       20, 44, 4,   7);

pg = gmnav_platgraph_create(grid, move);
gmnav_platgraph_bake(pg);

sched = gmnav_scheduler_create(pg, 1500);
```

The scheduler takes a platformer graph exactly where it took a grid, and the
request and ticket flow is identical. Paths come back as platform node indices.

Reading a link so you can perform it:

```gml
var _lk = gmnav_platgraph_link_get(pg, from_node, to_node);
// { type, cost, vx, vy, x, y }
```

`type` is `gmnav_link.WALK`, `FALL` or `JUMP`. `vx` and `vy` are the launch
velocity that produced the link. Apply them and integrate under the same
gravity and the character lands on the node the graph promised.

**Integrate in the same order the baker did**, or the character will drift and
miss its landing. Gravity, then horizontal, then vertical, testing each
separately:

```gml
vy = min(vy + move.gravity, move.max_fall);

var _nx = x + vx;
if (gmnav_platgraph_solid(pg, _nx, y, 0)) vx = 0; else x = _nx;

var _ny = y + vy;
if (gmnav_platgraph_solid(pg, x, _ny, vy)) {
    // landed, or hit a ceiling if vy < 0
} else {
    y = _ny;
}
```

`gmnav_platgraph_solid` is the same collision test the bake used, which is why
using it keeps you in sync.

Two parameters that matter more than they look:

`air_speed` defaults to `run_speed`, which means the character has no air
momentum and drifts sideways in flight exactly as fast as it walks. That makes
long diagonal jumps impossible and can quietly turn a platform into a one-way
trap. Most platformers want it at or above `run_speed`.

`jump_levels` is how many jump strengths get sampled between half power and
full, and it controls arc quality, not just how many jumps are tried. The
default of 3 is cheap but coarse, and arcs will overshoot on gaps that fall
near a sampling boundary. 7 to 9 gives noticeably flatter, more natural arcs.
Bake time scales linearly with it.

### Letting the framework fly

For a character that does not need a bespoke controller, the platform agent
follows the graph itself, replaying each link's stored launch velocity.

```gml
pa = gmnav_platagent_create(psched, x, y);

gmnav_platagent_goto(pa, target_x, target_y);
gmnav_platagent_update(pa);

x = pa.x;
y = pa.y;
```

This is the one place GMNav moves something, because arc replay is only correct
if the stepping order matches the bake exactly, so the replay has to own the
stepping. In exchange you give up ownership of the position, which makes it a
poor fit for anything that can be knocked back or grabbed.

`gmnav_platagent_airborne` tells you when to play a jump animation.
`pa.desync` counts frames where the replay and the world disagreed, and should
stay at zero. A non-zero value means your movement model does not match the
level, something else moved the character, or the collision data changed after
the bake.

---

## Debug drawing

Every subsystem has a view. Turn them on while building, off when shipping.

```gml
cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.3;

gmnav_debug_draw_grid(grid, cfg);
gmnav_debug_draw_costs(grid, profile, cfg);
gmnav_debug_draw_clearance(grid, cfg);
gmnav_debug_draw_reach(grid, cfg, 2);
gmnav_debug_draw_flowfield(field, cfg);
gmnav_debug_draw_path(grid, path, cfg);
gmnav_debug_draw_search(srch, cfg);
gmnav_debug_draw_platgraph(pg, cfg);
gmnav_debug_draw_agent(agent, cfg);
gmnav_debug_draw_stats(sched, 8, 8);
```

Each view answers one question, and picking the one that matches your symptom
beats turning them all on.

`gmnav_debug_draw_reach` is the one for a `FAILED` search on a map that looks
walkable. It colours each connected component, and with a clearance argument it
answers what a unit of that size can actually get to.

`gmnav_debug_draw_stats` is the one to leave on longest. It shows pending
searches and budget use, which is how you tell whether your budget is right.

---

## Things that will catch you out

**A free cell is not a free position.** `gmnav_grid_is_blocked` asks about a
cell. An agent with a radius needs a position its whole body fits in, and a
point two pixels from a wall sits in a perfectly open cell. This is what
clearance is for.

**Agents that never register arrival.** `reach_dist` defaults to 4 pixels. If
an agent cannot physically reach within 4 pixels of its goal, because its body
is stopped by a wall first, it never latches `arrived` and keeps pushing.
Raise `reach_dist` past your agent radius, or validate goals against the body.

**Avoidance does not know about walls.** Local avoidance repels agents from
other agents only. When a crowd compresses against geometry it will push
bodies into walls, and your movement code absorbs that. Agents may idle
against a wall until the crowd disperses. Set `avoid_str` to 0 to disable.

**Avoidance is separation, not reciprocal avoidance.** It will not resolve two
agents walking into each other in a one-tile corridor. Plan for that at the
design level.

**Editing the grid does not rebuild anything.** Flow fields, clearance and
platformer graphs go out of date and tell you so. Rebuilding is your call,
because only you know whether it is worth the frame.

**Smoothing needs telling everything.** Elevation limits, body radius, headings
and cost profile each close a way a shortcut could be wrong. Agents pass all
four for you; if you drive paths yourself, pass them.

**Smoothing and curving are refused on staggered and hex.** On those layouts a
straight line in cell coordinates says nothing reliable about whether a
character could walk it. `gmnav_path_simplify` works everywhere.

**A deck narrower than a body will not smooth.** The corridor test asks whether
the whole body fits along the line, so every shortcut across a one-cell bridge
is refused and every deck cell survives as a waypoint. That is correct.

**Cost cannot attract.** A negative profile weight is legal and resolved cost
still clamps at 1, so dangerous ground becomes ordinary rather than appealing.
To pull a unit toward something, seed it as a goal in a flow field.

**`GMNAV_FLAG_ONEWAY` is partial.** Standing on and jumping up through a
one-way platform work. Dropping down through one is not implemented, so a
one-way deck stacked over a solid ledge routes the long way round.

---

## Where next

[API Reference](RawDocumentation.md) is the complete API reference, every
function with its arguments, return shape and edge cases, plus a struct
reference and a longer list of known behaviours.

The tutorial series works through nineteen chapters with diagrams, from a first
grid up to a navigation system you can see and diagnose. The first ten build
the framework from nothing with runnable datasets; the rest cover the parts
that are easy to get subtly wrong.

`obj_demo_1` through `obj_demo_14` are runnable and commented, covering a single
agent, a crowd on one shared budget, a platformer character following baked jump
arcs, elevation, bridges and ramps in three projections, flow fields over
stacked surfaces, movement constraints, curves, moving cost, and a tour of the
debug renderer.