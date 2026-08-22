# Getting Started with GMNav

GMNav is a pathfinding and navigation framework for GameMaker. It covers
top-down grids in four projections, side-view platformer navigation with
baked jump arcs, layered terrain costs, flow fields, agent clearance, and
local avoidance, all under a shared per-frame budget so a large crowd never
stalls your game loop.

This guide gets you from an empty project to a moving agent, then shows each
subsystem in the order you are likely to need it. For the full API see
`RawDocumentation.md`. For worked examples with diagrams see the tutorial
series.

---

## Install

Import the `.yymps`. You will get script assets under a folder called `GMNav`, the functions they
contain are all prefixed `gmnav_`. Nothing else is added to your project and nothing runs on its own.

Everything is plain GML structs and arrays. There are no objects to place, no
persistent controller, and no global state.

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

A node is an integer, `row * width + col`. `GMNAV_NO_NODE` is -1 and means
out of bounds. Check for it. Every function that takes a node handles it
safely, but your own code will not.

Editing a grid bumps its version, which marks dependent searches, flow fields,
clearance data and platformer graphs as stale. You are told, but nothing is
rebuilt behind your back.

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

if (gmnav_scheduler_is_ready(ticket)) {
    if (ticket.state == gmnav_state.FOUND) {
        path = gmnav_scheduler_get_path(ticket);   // array of nodes
    } else {
        // gmnav_state.FAILED, no route exists
    }
    ticket = undefined;
}
```

Priorities are `LOW`, `NORMAL`, `HIGH` and `IMMEDIATE`. `IMMEDIATE` bypasses
the budget and completes in the frame it is requested, so use it for the
player and almost nothing else.

### The stale contract

A search suspended mid-flight can outlive the grid it was searching. If you
block a cell while a search is running, the result may route through it.
GMNav marks such a result stale rather than silently returning a bad path:

```gml
if (gmnav_agent_has_path(agent) && gmnav_search_is_stale(srch)) {
    gmnav_agent_goto(agent, agent.goal_x, agent.goal_y);
}
```

For agents this is handled for you. If you drive searches directly, check it.

---

## Agents

An agent wraps a path with steering, arrival, and optional local avoidance.

```gml
agent = gmnav_agent_create(sched, x, y, 8, 2.5);   // radius, speed
```

Fields worth knowing, all writable at any time:

```gml
agent.speed       = 3;      // units per frame
agent.accel       = 0.35;   // 0 to 1, how sharply it turns
agent.arrive_dist = 24;     // starts slowing inside this range
agent.reach_dist  = 4;      // counts as arrived inside this range
agent.avoid_str   = 1.0;    // 0 disables local avoidance
agent.avoid_range = 3.0;    // multiples of radius
```

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

A field takes multiple goals, so a set of exits or capture points is one array.
`gmnav_flowfield_build` does the whole thing at once. For a big grid, use
`gmnav_flowfield_begin` and `gmnav_flowfield_step` to spread it over frames.

```gml
gmnav_flowfield_is_reachable(field, x, y);   // false means no route
gmnav_flowfield_cost_at(field, x, y);        // distance to the nearest goal
if (gmnav_flowfield_is_stale(field)) gmnav_flowfield_build(field, [goal_node]);
```

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

Clearance is capped at `GMNAV_CLEARANCE_MAX`, which is 16 cells.

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

## Platformer navigation

Side-view navigation is a different graph. Instead of cells, GMNav scans for
standing surfaces and bakes links between them by simulating your actual
movement model, so a jump link exists only if the character can really make
that jump.

```gml
layout = gmnav_layout_create(gmnav_layout.ORTHO, 32, 32);
grid   = gmnav_grid_create(40, 20, layout);
// ... mark the level ...

//                              gravity, jump_vel, run, max_fall, w,  h,  air, levels
move = gmnav_movement_create(   0.5,     12,       3,   12,       20, 44, 4,   7);

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
gmnav_debug_draw_flowfield(field, cfg);
gmnav_debug_draw_path(grid, path, cfg);
gmnav_debug_draw_search(srch, cfg);
gmnav_debug_draw_platgraph(pg, cfg);
gmnav_debug_draw_agent(agent, cfg);
gmnav_debug_draw_stats(sched, 8, 8);
```

`gmnav_debug_draw_stats` is the one to leave on longest. It shows pending
searches and budget use, which is how you tell whether your budget is right.

---

## Things that will catch you out

**A free cell is not a free position.** `gmnav_grid_is_blocked` asks about a
cell. An agent with a radius needs a position its whole body fits in, and a
point two pixels from a wall sits in a perfectly open cell. If you send agents
to spread-out destinations near geometry, test the body, not the point. This
is what clearance is for.

**Agents that never register arrival.** `reach_dist` defaults to 4 pixels. If
an agent cannot physically reach within 4 pixels of its goal, because its body
is stopped by a wall first, it never latches `arrived` and keeps pushing.
Raise `reach_dist` past your agent radius, or validate goals against the body.

**Avoidance does not know about walls.** Local avoidance repels agents from
other agents only. When a crowd compresses against geometry it will push
bodies into walls, and your movement code absorbs that. Agents may idle
against a wall until the crowd disperses. Set `avoid_str` to 0 to disable.

**Editing the grid does not rebuild anything.** Flow fields, clearance and
platformer graphs go stale and tell you so. Rebuilding is your call, because
only you know whether it is worth the frame.

**`GMNAV_FLAG_ONEWAY` is experimental.** Standing on and jumping up through a
one-way platform work. Dropping down through one is not implemented, so a
one-way deck stacked over a solid ledge routes the long way round.

---

## Where next

`RawDocumentation.md` is the complete API reference, every function with its
arguments, return shape and edge cases.

The tutorial series works through ten chapters with real datasets and diagrams,
from a first grid up to platformer navigation and flow fields.

`obj_demo_1` through `obj_demo_3` are runnable and commented: a single agent,
a crowd on one shared budget, and a platformer character following baked jump
arcs.