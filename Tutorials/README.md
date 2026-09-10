# GMNav Tutorials

Welcome. This is a nineteen-chapter series that teaches GMNav from the ground up, starting with what pathfinding actually is and why walking straight at a target doesn't work, and ending with a navigation system you can see, tune, and diagnose.

It comes in two halves. **Basic**, Chapters 1 to 10, builds the whole thing from nothing and proves each piece as it goes. **Advanced**, Chapters 11 to 19, assumes you have that and covers the parts of the framework that are easy to get subtly wrong.

## Who this is for

If you've never built or used a navigation system before, you're in the right place. Each chapter in the Basic half explains the underlying *concept* before showing the code, what a graph is, what a heuristic does, why a search that blocks the frame is a problem worth an entire framework, not just a list of function signatures. If you already know some of this from working in another engine, feel free to skip ahead; every chapter is self-contained enough to jump into directly, though later chapters do build on ideas introduced earlier.

The chapters get progressively harder. Chapter 1 assumes nothing, not even that you know what A\* stands for. Chapter 10 assumes you've followed along and picked up the ideas from everything before it; ballistic simulation, directed graphs, and reachability baking are genuinely demanding material, and we take our time with them.

The Advanced half changes register. By then you have watched the framework do what it claims, so those chapters spend less time demonstrating and more time on the details that decide whether a feature works well or merely works.

## What is GMNav?

GMNav is a pure GML pathfinding and navigation framework for GameMaker, no external DLLs, no extensions. It brings the kind of navigation capability you'd expect from a real, production engine (resumable search under a frame budget, layered cost maps, agent clearance, flow fields, elevation, stacked walkable layers, and side-view platformer navigation) into a form any GameMaker project can use directly.

It's designed for games where things need to move intelligently, dungeon crawlers, strategy games, tower defense, stealth games, platformers, anywhere an enemy needs to *get somewhere* rather than drift toward the player and get stuck on a wall.

## How to use these tutorials

Every chapter comes with the chapter itself as a `ChapterN.md` file, with explanations, complete code examples, and a handful of `.svg` diagrams referenced directly in the text, illustrating the ideas that are easier to see than to describe.

The Basic chapters come with one thing more: a **`ChapterN_Dataset.gml` file**, the full level layout used throughout that chapter, ready to paste into a script and use immediately. Every path, cost, and node count quoted in those chapters was checked against that exact map, so you can run the examples and get the same numbers the text quotes.

The Advanced chapters have no datasets, deliberately. By that point you have your own map and your own project, and what those chapters teach is how a mechanism behaves rather than what a particular level does. Bring your own terrain.

There's a second kind of visual in this series that the code produces for you. GMNav ships a debug renderer, and you'll meet it in Chapter 1, before you've written anything complicated. From that point on, every chapter can be *seen* as well as read, you draw the grid, the path, the cost map, or the jump arcs on screen and look at what the framework is actually thinking. Learning a navigation system without visualising it is unnecessarily hard, so we don't, and Chapter 19 comes back to that renderer in full.

Every Basic chapter uses its own map, chosen to fit what that chapter is teaching, a small dungeon room for Chapter 1's basics, a muddy river crossing for Chapter 2's terrain costs, a crowded fortress siege for Chapter 8's flow fields. Nothing is shared or reused arbitrarily; if two chapters use similar maps, it's because one is a direct, deliberate extension of the other (Chapter 7's corridors widen Chapter 6's battlefield; Chapter 9 breaks holes in the exact map Chapter 4's patrol route crosses, specifically so you can watch a known-good path fail and repair itself).

---

# Basic

The framework from nothing, with every claim demonstrated on a map you can run.

### [Chapter 1: What Is Pathfinding, Anyway?](Chapters/Chapter1/Chapter1.md)
The gentlest possible starting point. What problem does pathfinding actually solve, and why can't an enemy just walk toward the player? Learn what a graph is, how a grid becomes one, and what a search algorithm is really doing when it explores, then build your first navigation grid, find your first path, and draw it on screen so you can see it.

### [Chapter 2: How A\* Decides, Cost and Heuristics](Chapters/Chapter2/Chapter2.md)
The path you got in Chapter 1 wasn't arbitrary, and understanding why is the difference between using a pathfinder and controlling one. Covers cost so far and estimated cost remaining, what makes a heuristic admissible and what silently breaks when it isn't, terrain that costs more to cross, and the exact reason diagonal movement needs its own price. Includes a from-scratch look at what "optimal path" actually guarantees.

### [Chapter 3: The Frame Problem, Budgets and the Scheduler](Chapters/Chapter3/Chapter3.md)
The chapter that explains why GMNav exists at all. A search that finishes before returning will drop your frame the moment you have enough agents, so GMNav's searches stop halfway and resume later. Learn what a resumable search is, how one shared budget keeps two hundred agents as cheap as ten, how request priorities avoid starving anyone, and why `IMMEDIATE` is not the guarantee its name suggests.

### [Chapter 4: From Nodes to Movement, Paths and Agents](Chapters/Chapter4/Chapter4.md)
A list of cell IDs is not a character walking. Covers turning raw nodes into world-space waypoints, string pulling to remove the staircase shape, why line-of-sight testing has to visit every cell a line touches and what breaks when it doesn't, and the agent layer, which proposes a velocity and deliberately refuses to move your instances for you.

### [Chapter 5: Beyond Square Grids, Isometric and Hex](Chapters/Chapter5/Chapter5.md)
The search never touches pixels, and once that clicks, isometric and hexagonal maps stop being a separate problem and become configuration. Covers all five layouts, the coordinate transforms behind them, why a heuristic measured in screen distance quietly breaks A\*, and a genuine surprise in staggered isometric adjacency that will bite anyone who draws a wall the obvious way.

### [Chapter 6: Making AI Look Smart, Layered Cost Fields](Chapters/Chapter6/Chapter6.md)
The cheapest way to turn a pathfinder into something that reads as intelligent. Learn what an influence map is, how to stack danger, terrain, and territory as independent layers, how two agent types can read the same danger map and disagree about how much they care, and why all of it gets flattened into a single array before the search ever runs.

### [Chapter 7: Size Matters, Clearance and Agent Radius](Chapters/Chapter7/Chapter7.md)
A boss the size of four tiles should not try to squeeze through a doorway. Covers what clearance means precisely, how two linear sweeps compute it for an entire map faster than checking a single agent by hand, how one navigation grid serves every agent size at once, and the deliberate rule-bend that lets an agent already stuck in a tight spot path its way out.

### [Chapter 8: One Pass, Many Agents, Flow Fields](Chapters/Chapter8/Chapter8.md)
When a thousand units chase the same target, running a thousand searches is the wrong shape of solution. Covers building a distance field outward from the goal instead of a path inward from each agent, turning that field into a direction per cell, seeding multiple goals so everyone flows to their own nearest exit, and an honest account of when a flow field is the wrong tool.

### [Chapter 9: A World That Changes, Dynamic Obstacles and Replanning](Chapters/Chapter9/Chapter9.md)
Doors close, walls break, bridges burn. Covers how GMNav detects that the world moved underneath an in-flight search, why a suspended search can return a path through a wall that appeared while it slept, what the stale flag guarantees and what it deliberately does not, and how the agent layer repairs itself without your code doing anything.

### [Chapter 10: Navigating a Platformer, Simulated Jump Arcs](Chapters/Chapter10/Chapter10.md)
The most demanding chapter of the first half. Side-view connectivity is not grid adjacency, so GMNav establishes it by simulating your character's actual jump arcs against your actual collision data. Covers describing a movement model, why it must match your player controller exactly, how walk, fall, and jump links are generated and priced in frames, why the resulting graph is one-way in places, and where GMNav stops and your character controller takes over.

---

# Advanced

Ground that isn't flat, surfaces that overlap, and the details that decide whether a feature works well or merely works.

### [Chapter 11: Ground That Isn't Flat](Chapters/Chapter11/Chapter11.md)
Every map so far has been a plane. Give cells a height and two neighbours are no longer necessarily reachable from each other. Covers elevation per cell, why a climb limit and a drop limit make a cliff one-way without anyone writing a rule, why a ramp is not a feature but a run of cells, and the reason smoothing quietly undoes all of it unless you tell it not to.

### [Chapter 12: Two Things In One Place](Chapters/Chapter12/Chapter12.md)
A bridge over a road needs two answers in one cell, and no height per cell can give you that. Covers layered overlays, the two rules that keep them from becoming a second map you maintain by hand, why picking a point over a bridge is a question the framework refuses to guess at, and what a deck cell inherits from being a real cell.

### [Chapter 13: Ramps](Chapters/Chapter13/Chapter13.md)
A deck that jumps to full height in one step reads as a wall with a door in it. Covers per-cell offsets and the difference between a layer and a fraction of one, how to author a slope without computing the fractions yourself, why the foot of a ramp always sits slightly above the ground, and the rendering problem that is genuinely your renderer's rather than the framework's.

### [Chapter 14: What A Unit Is Allowed To Walk](Chapters/Chapter14/Chapter14.md)
A character with four directional sprites cannot walk a diagonal, however clear the line happens to be. Covers movement constraints, why the search and the path shaping are two separate answers to that question and have to agree, and the rewrite that turns a legal staircase into legal straight legs by proposing a corner the search never visited.

### [Chapter 15: Turning Corners](Chapters/Chapter15/Chapter15.md)
Nothing with momentum turns instantly. Covers the two curve modes and why one of them is the safer default, what each tuning number actually does, why every generated segment has to be checked against the same geometry the search used, and three cases where curving a path is exactly the wrong thing to ask for.

### [Chapter 16: Danger Along A Route](Chapters/Chapter16/Chapter16.md)
Chapter 6's turret sat still. Most hazards do not. Covers painting cost along a polyline rather than around a point, keeping a moving threat affordable with region rebaking, why peak values want to be modest, and the honest answer to whether cost can attract as well as repel, along with what to do instead.

### [Chapter 17: A World That Keeps Changing](Chapters/Chapter17/Chapter17.md)
Chapter 9 asked whether an agent notices a change. This one asks whether it should care. Covers why a global version counter makes every agent react to every edit, why that failure looks exactly like an undersized budget, how the grid remembers where it changed so most agents never have to ask, and why running out of history repaths rather than staying quiet.

### [Chapter 18: Following A Jump Graph](Chapters/Chapter18/Chapter18.md)
Chapter 10 told you a jump was needed and left the jumping to you. Sometimes that is more work than a bat deserves. Covers the platform agent, the one place in the framework that moves something itself, why arc replay has to own the stepping order, what the desync counter is telling you, and what you give up by handing over the frames.

### [Chapter 19: Seeing What The Navigation Thinks](Chapters/Chapter19/Chapter19.md)
Almost everything in this series is invisible until something goes wrong. Covers every debug view and the one question each of them answers, how to read a flow field and an agent at a glance, the view that explains a `FAILED` search on a map that looks perfectly walkable, and why turning them all on at once tells you nothing.

---

## Where to go from here

If you're new to GMNav, start at Chapter 1 and work through in order, the series is built to be read that way, with each chapter assuming you have the concepts from everything before it. If you're comfortable with the basics already, Chapter 11 is a reasonable entry point, though Chapters 12 and 13 assume 11 and Chapter 17 assumes 9.

If you're looking for something specific, the [Full Documentation](https://github.com/erkan612/GMNav/blob/main/Documentation.md) has every function documented directly, without the surrounding narrative.

Good luck, and happy building.
