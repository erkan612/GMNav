# GMNav Tutorials

Welcome. This is a ten-chapter series that teaches GMNav from the ground up, starting with what pathfinding actually is and why walking straight at a target doesn't work, and ending with a character that can look at a level, work out which ledges it can physically jump between, and route itself across them.

## Who this is for

If you've never built or used a navigation system before, you're in the right place. Each chapter explains the underlying *concept* before showing the code, what a graph is, what a heuristic does, why a search that blocks the frame is a problem worth an entire framework, not just a list of function signatures. If you already know some of this from working in another engine, feel free to skip ahead; every chapter is self-contained enough to jump into directly, though later chapters do build on ideas introduced earlier.

The chapters get progressively harder. Chapter 1 assumes nothing, not even that you know what A\* stands for. Chapter 10 assumes you've followed along and picked up the ideas from everything before it; ballistic simulation, directed graphs, and reachability baking are genuinely demanding material, and we take our time with them.

## What is GMNav?

GMNav is a pure GML pathfinding and navigation framework for GameMaker, no external DLLs, no extensions. It brings the kind of navigation capability you'd expect from a real, production engine (resumable search under a frame budget, layered cost maps, agent clearance, flow fields, and side-view platformer navigation) into a form any GameMaker project can use directly.

It's designed for games where things need to move intelligently, dungeon crawlers, strategy games, tower defense, stealth games, platformers, anywhere an enemy needs to *get somewhere* rather than drift toward the player and get stuck on a wall.

## How to use these tutorials

Each chapter comes with everything you need to follow along directly in GameMaker:

- **A `ChapterN.md` file**, the chapter itself, with explanations, diagrams, and complete code examples.
- **A `ChapterN_Dataset.gml` file**, the full level layout used throughout that chapter, ready to paste into a script and use immediately. Every path, cost, and node count quoted in the chapter text was checked against this exact map.
- **A handful of `.svg` diagrams** per chapter, referenced directly in the chapter text, illustrating the concepts that are easier to see than to describe in words alone.

There's a second kind of visual in this series that the code produces for you. GMNav ships a debug renderer, and you'll meet it in Chapter 1, before you've written anything complicated. From that point on, every chapter can be *seen* as well as read, you draw the grid, the path, the cost map, or the jump arcs on screen and look at what the framework is actually thinking. Learning a navigation system without visualising it is unnecessarily hard, so we don't.

Every chapter uses its own map, chosen to fit what that chapter is teaching, a small dungeon room for Chapter 1's basics, a muddy river crossing for Chapter 2's terrain costs, a crowded fortress siege for Chapter 8's flow fields. Nothing is shared or reused arbitrarily; if two chapters use similar maps, it's because one is a direct, deliberate extension of the other (Chapter 7's corridors widen Chapter 6's battlefield; Chapter 9 breaks holes in the exact map Chapter 4's patrol route crosses, specifically so you can watch a known-good path fail and repair itself).

## The chapters

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
The final chapter, and the most demanding one. Side-view connectivity is not grid adjacency, so GMNav establishes it by simulating your character's actual jump arcs against your actual collision data. Covers describing a movement model, why it must match your player controller exactly, how walk, fall, and jump links are generated and priced in frames, why the resulting graph is one-way in places, and where GMNav stops and your character controller takes over. Closes with a full tour of the debug renderer.

## Where to go from here

If you're new to GMNav, start at Chapter 1 and work through in order, the series is built to be read that way, with each chapter assuming you have the concepts from everything before it. If you're looking for something specific, the [Full Documentation](https://github.com/erkan612/GMNav/blob/main/Documentation.md) has every function documented directly, without the surrounding narrative.

Good luck, and happy building.
