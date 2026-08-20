# GMNav

**Pathfinding and navigation framework for GameMaker**

> Pure GML. No extensions. No DLLs.

---

## Overview

GMNav is a complete navigation solution for GameMaker, covering top-down, isometric, hex and side-view platformer games.

Every search is resumable. Instead of blocking the frame, searches run under a global budget shared across all agents, so pathfinding costs the same milliseconds whether you have ten agents or five hundred.

---

## Features at a Glance

### Core Search

- **Resumable A\*** - Stops mid-search, resumes next frame, never blocks
- **Global frame budget** - One shared pool of node expansions, not per agent
- **Request priorities** - Low, normal, high, and immediate with FIFO fairness
- **Deterministic** - Identical input always returns the identical path

### Layouts

- **Orthogonal** - Standard square and rectangular grids
- **Isometric diamond** - Classic 2:1 projection
- **Isometric staggered** - Offset rows with parity-aware adjacency
- **Hexagonal** - Pointy-top and flat-top, with cube coordinate rounding
- **Anisotropic cost** - Logical or visual step cost for non-square tiles

### Cost Fields

- **Layered cost maps** - Stack danger, terrain, and faction layers independently
- **Per-agent weights** - Two agent types read one layer and disagree about it
- **Baked resolution** - Twelve layers cost the search exactly as much as none
- **Radial stamps** - Falloff brushes with region-local rebaking for moving sources

### Clearance

- **Chebyshev distance transform** - Two linear sweeps, no per-node box scans
- **Size-aware routing** - One nav graph serves agents of every radius
- **Start relaxation** - Agents in tight spots can still path out

### Flow Fields

- **One pass, many agents** - Thousands read a direction at near-zero cost
- **Multiple goals** - Nearest exit, nearest cover, in a single build
- **Distance capping** - Bound the build on large maps
- **Sliced building** - Spread the work across frames

### Platformer Navigation

- **Simulated reachability** - Jump arcs integrated against your collision data
- **Your movement model** - Gravity, jump velocity, run speed, terminal fall
- **Three link types** - Walk, fall, and jump, each with traversal cost in frames
- **One-way awareness** - Drops that cannot be climbed back up

### Agents

- **Velocity proposal** - Writes vx and vy, never moves your instances
- **Path smoothing** - Supercover string pulling, no corner clipping
- **Local avoidance** - Separation steering with speed clamping
- **Automatic replanning** - Detects world changes and re-requests

### Debug Renderer

- **Layout-accurate cells** - Draws diamonds and hexagons, not squares
- **Flow field arrows** - Direction and distance ramp per cell
- **Clearance and cost ramps** - See exactly what an agent type pays
- **Search frontier** - Watch open and closed sets expand across frames
- **Platformer link graph** - Colour-coded arcs, filterable and focusable

---

## Quick Example

```gml
// Create
grid  = gmnav_grid_create(60, 40, gmnav_layout_create(gmnav_layout.ORTHO, 32, 32));
gmnav_grid_import_tilemap(grid, layer_tilemap_get_id("Tiles_Collision"));

sched = gmnav_scheduler_create(grid, 2000, 4);
agent = gmnav_agent_create(sched, x, y, 12, 3);
```

```gml
// Step
gmnav_scheduler_update(sched);
gmnav_agent_update(agent);

x += agent.vx;
y += agent.vy;
```

```gml
// Anywhere
gmnav_agent_goto(agent, target_x, target_y);
```

### Cost Fields

```gml
danger = gmnav_costlayer_create(grid, "danger");
gmnav_costlayer_stamp_radial(danger, player_x, player_y, 200, 12, 2);

grunt = gmnav_costprofile_create(grid, "grunt");
gmnav_costprofile_add(grunt, danger, 1);
gmnav_costprofile_bake(grunt);

gmnav_scheduler_request(sched, from, to, gmnav_priority.NORMAL, false, grunt);
```

### Platformer

```gml
move   = gmnav_movement_create(0.5, 7, 3, 9, 16, 32);
pgraph = gmnav_platgraph_create(grid, move);
gmnav_platgraph_bake(pgraph);

// path[i] is a ledge, links[i] is how you reach it
var _path  = gmnav_scheduler_get_path(ticket);
var _links = gmnav_scheduler_get_links(ticket);
```

---

## Why GMNav?

| Traditional Approach         | GMNav                                        |
| ---------------------------- | -------------------------------------------- |
| A\* blocks the frame          | Resumable search under a shared budget       |
| Cost scales with agent count | Fixed frame cost, queue drains slower        |
| Square grids only            | Orthogonal, isometric, staggered, hex        |
| One cost per cell            | Layered cost fields, weighted per agent type |
| One agent size               | Clearance-aware routing for any radius       |
| Top-down assumed             | Side-view navigation with simulated jumps    |
| Rebuild per goal             | Flow fields serve unlimited agents at once   |
| Guess why the path looks odd | Full debug renderer for every subsystem      |

---

## Quick Comparison

| Feature               | GMNav | mp\_grid | Hand-rolled A\* |
| --------------------- | ----- | -------- | --------------- |
| Grid pathfinding      | ✅     | ✅        | ✅               |
| Frame-safe search     | ✅     | ❌        | ❌               |
| Shared frame budget   | ✅     | ❌        | ❌               |
| Isometric and hex     | ✅     | ❌        | ❌               |
| Weighted terrain cost | ✅     | ❌        | ⚠️               |
| Layered cost fields   | ✅     | ❌        | ❌               |
| Agent clearance       | ✅     | ❌        | ❌               |
| Flow fields           | ✅     | ❌        | ❌               |
| Platformer navigation | ✅     | ❌        | ❌               |
| Dynamic obstacles     | ✅     | ⚠️        | ⚠️               |
| Determinism guarantee | ✅     | ❌        | ❌               |
| Debug visualisation   | ✅     | ❌        | ❌               |
| Pure GML              | ✅     | ✅        | ✅               |

---

## Documentation

- **[API Reference](RawDocumentation.md)** - Complete API reference, tuning, and known behaviours
- **[Tutorials](https://github.com/erkan612/GMNav/tree/main/Tutorials)** - Complete API reference, tuning, and known behaviours

---

## References

**Shortest paths** Dijkstra, E. W. (1959) "[A Note on Two Problems in Connexion with Graphs](https://link.springer.com/article/10.1007/BF01386390)", Numerische Mathematik, 1, 269-271
Hart, P. E., Nilsson, N. J. and Raphael, B. (1968) "[A Formal Basis for the Heuristic Determination of Minimum Cost Paths](https://ieeexplore.ieee.org/document/4082128)", IEEE Transactions on Systems Science and Cybernetics, 4(2), 100-107

**Distance transforms and clearance** Rosenfeld, A. and Pfaltz, J. L. (1966) "[Sequential Operations in Digital Picture Processing](https://dl.acm.org/doi/10.1145/321356.321357)", Journal of the ACM, 13(4), 471-494
Borgefors, G. (1986) "[Distance Transformations in Digital Images](https://www.sciencedirect.com/science/article/abs/pii/0734189X86900472)", Computer Vision, Graphics, and Image Processing, 34(3), 344-371

**Grid traversal and line of sight** Amanatides, J. and Woo, A. (1987) "[A Fast Voxel Traversal Algorithm for Ray Tracing](https://www.cse.yorku.ca/~amana/research/grid.pdf)", Eurographics '87

**Steering and local avoidance** Reynolds, C. W. (1987) "[Flocks, Herds and Schools: A Distributed Behavioral Model](https://dl.acm.org/doi/10.1145/37402.37406)", SIGGRAPH '87, 25-34
Reynolds, C. W. (1999) "[Steering Behaviors For Autonomous Characters](https://www.red3d.com/cwr/steer/gdc99/)", Game Developers Conference

**Flow fields** Emerson, E. (2013) "Crowd Pathfinding and Steering Using Flow Field Tiles", in Rabin, S. (ed.) Game AI Pro, CRC Press

**Hex grids** Patel, A. "[Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/)", Red Blob Games
