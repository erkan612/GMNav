<img width="1200" height="360" alt="banner" src="https://github.com/user-attachments/assets/dfcd0ccb-810e-4410-ab05-83eb4fecbfb9" />

<img width="1200" height="180" alt="layouts" src="https://github.com/user-attachments/assets/e77fa1e2-14bd-4d42-9095-b5d76c0a1ace" />

<img width="1200" height="50" alt="badges_4badge_alt" src="https://github.com/user-attachments/assets/3b1647ac-1acc-4ac0-b8e1-90e21550bc6c" />

<img width="1200" height="247" alt="overview" src="https://github.com/user-attachments/assets/7a4a4896-f874-4daa-92c9-ab63048a2cd1" />

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

### Elevation and Layers

- **Height per cell** - Climb and drop limits per unit, so a cliff is one-way without a flag
- **Stacked walkable surfaces** - A bridge over a road, a walkway behind a cliff, a tower you can circle
- **Sparse overlays** - A handful of cells above the grid, not a second grid to maintain
- **Ramps** - Fractional offsets that climb a surface in even steps
- **Caller-named picking** - A point over a bridge has two answers, and you say which you meant

### Cost Fields

- **Layered cost maps** - Stack danger, terrain, and faction layers independently
- **Per-agent weights** - Two agent types read one layer and disagree about it
- **Baked resolution** - Twelve layers cost the search exactly as much as none
- **Radial and path stamps** - Falloff brushes around a point or along a route
- **Region rebaking** - Move a threat every frame without touching the rest of the map

### Clearance

- **Chebyshev distance transform** - Two linear sweeps, no per-node box scans
- **Size-aware routing** - One nav graph serves agents of every radius
- **Start relaxation** - Agents in tight spots can still path out

### Flow Fields

- **One pass, many agents** - Thousands read a direction at near-zero cost
- **Multiple goals** - Nearest exit, nearest cover, in a single build
- **Distance capping** - Bound the build on large maps
- **Sliced building** - Spread the work across frames
- **True travel cost** - Ask any unit what a destination really costs it, in one lookup

### Path Shaping

- **Supercover string pulling** - Removes the staircase without clipping corners
- **Movement constraints** - Hold a path to four or eight headings for grid-locked characters
- **Corner rounding and splines** - For anything that cannot turn instantly
- **Validated throughout** - A shortcut that would clip geometry, climb a cliff, or walk back into priced ground is refused

### Platformer Navigation

- **Simulated reachability** - Jump arcs integrated against your collision data
- **Your movement model** - Gravity, jump velocity, run speed, terminal fall
- **Three link types** - Walk, fall, and jump, each with traversal cost in frames
- **One-way awareness** - Drops that cannot be climbed back up
- **Optional arc replay** - Let the framework fly the jumps, or read the links and fly them yourself

### Agents

- **Velocity proposal** - Writes vx and vy, never moves your instances
- **Scoped replanning** - Repaths only when a change lands on the route still to walk
- **Local avoidance** - Separation steering with speed clamping
- **Nothing hidden** - Every behaviour is a public call, so your own agent class loses nothing

### Debug Renderer

- **Layout-accurate cells** - Draws diamonds and hexagons, not squares
- **Layer-aware** - Raised cells draw where they sit, with a line to the ground beneath
- **Flow field arrows** - Direction and distance ramp per cell
- **Clearance and cost ramps** - See exactly what an agent type pays
- **Reachability** - Colour by connected component, for any agent size
- **Search frontier** - Watch open and closed sets expand across frames
- **Platformer link graph** - Colour-coded arcs, filterable and focusable

---

## Why GMNav?

| Traditional | GMNav |
| --- | --- |
| A\* blocks the frame | Resumable search,<br>one shared budget |
| Cost scales with<br>agent count | Fixed frame cost,<br>queue drains slower |
| Square grids only | Orthogonal, hex and<br>both isometrics |
| Flat ground assumed | Height per cell and<br>stacked surfaces |
| One cost per cell | Layered cost fields,<br>weighted per agent |
| One agent size | Clearance-aware<br>routing, any radius |
| Top-down assumed | Side-view nav with<br>simulated jumps |
| Rebuild per goal | Flow fields serve<br>every agent at once |
| Any edit repaths<br>everyone | Only agents the<br>change concerns |
| Guess why the path<br>looks odd | Debug renderer for<br>every subsystem |

## Quick Comparison

| Feature | GMNav | mp\_grid | A\* |
| --- | :---: | :---: | :---: |
| Grid pathfinding | ✅ | ✅ | ✅ |
| Frame-safe search | ✅ | ❌ | ❌ |
| Shared frame<br>budget | ✅ | ❌ | ❌ |
| Isometric and hex | ✅ | ❌ | ❌ |
| Weighted terrain<br>cost | ✅ | ❌ | ⚠️ |
| Layered cost fields | ✅ | ❌ | ❌ |
| Elevation limits | ✅ | ❌ | ❌ |
| Stacked surfaces | ✅ | ❌ | ❌ |
| Agent clearance | ✅ | ❌ | ❌ |
| Flow fields | ✅ | ❌ | ❌ |
| Platformer<br>navigation | ✅ | ❌ | ❌ |
| Dynamic obstacles | ✅ | ⚠️ | ⚠️ |
| Determinism<br>guarantee | ✅ | ❌ | ❌ |
| Debug visualisation | ✅ | ❌ | ❌ |
| Pure GML | ✅ | ✅ | ✅ |

---

## Documentation

- **[Getting Started](GettingStarted.md)** - From an empty project to a moving agent, then each subsystem in the order you are likely to need it
- **[Documentations](GMNavDocs.md)** - Every function with its arguments, detailed description, example, return shape, edge cases, and known behaviours
- **[API Reference](RawDocumentation.md)** - Every function with its arguments, return shape, edge cases, and known behaviours
- **[Tutorials](https://github.com/erkan612/GMNav/tree/main/Tutorials)** - Nineteen chapters, from what pathfinding is to a navigation system you can see and diagnose

---

## References

**Shortest paths** Dijkstra, E. W. (1959) "[A Note on Two Problems in Connexion with Graphs](https://link.springer.com/article/10.1007/BF01386390)", Numerische Mathematik, 1, 269-271
Hart, P. E., Nilsson, N. J. and Raphael, B. (1968) "[A Formal Basis for the Heuristic Determination of Minimum Cost Paths](https://ieeexplore.ieee.org/document/4082128)", IEEE Transactions on Systems Science and Cybernetics, 4(2), 100-107

**Distance transforms and clearance** Rosenfeld, A. and Pfaltz, J. L. (1966) "[Sequential Operations in Digital Picture Processing](https://dl.acm.org/doi/10.1145/321356.321357)", Journal of the ACM, 13(4), 471-494
Borgefors, G. (1986) "[Distance Transformations in Digital Images](https://www.sciencedirect.com/science/article/abs/pii/0734189X86900472)", Computer Vision, Graphics, and Image Processing, 34(3), 344-371

**Grid traversal and line of sight** Amanatides, J. and Woo, A. (1987) "[A Fast Voxel Traversal Algorithm for Ray Tracing](https://www.cse.yorku.ca/~amana/research/grid.pdf)", Eurographics '87

**Curves and corner rounding** Catmull, E. and Rom, R. (1974) "A Class of Local Interpolating Splines", in Barnhill, R. E. and Riesenfeld, R. F. (eds.) Computer Aided Geometric Design, Academic Press, 317-326

**Steering and local avoidance** Reynolds, C. W. (1987) "[Flocks, Herds and Schools: A Distributed Behavioral Model](https://dl.acm.org/doi/10.1145/37402.37406)", SIGGRAPH '87, 25-34
Reynolds, C. W. (1999) "[Steering Behaviors For Autonomous Characters](https://www.red3d.com/cwr/steer/gdc99/)", Game Developers Conference

**Flow fields** Emerson, E. (2013) "Crowd Pathfinding and Steering Using Flow Field Tiles", in Rabin, S. (ed.) Game AI Pro, CRC Press

**Hex grids** Patel, A. "[Hexagonal Grids](https://www.redblobgames.com/grids/hexagons/)", Red Blob Games
