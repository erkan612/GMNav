# Chapter 12: Two Things In One Place

Chapter 11 ended on a limit rather than a feature. Height per cell describes
ground that rises and falls, and it cannot describe ground that is in two
places at once.

A bridge over a road is the plain example. The cell under the bridge has two
answers: there is a road at ground level and a deck above it, and both are
walkable, and a unit on one of them is not on the other. No single height
satisfies that. Neither does a finer grid, because the problem is not
resolution. The cell genuinely holds two surfaces.

This chapter is about the mechanism for that, and about two rules that keep it
from turning into a second map you have to maintain by hand.

## An overlay sits beside the grid

An overlay is a sparse set of extra walkable cells stacked over a grid. Sparse
matters: you are not allocating a second grid, you are listing the handful of
cells that exist above the first one.

```gml
var _ov = gmnav_overlay_create(grid);

var _a = gmnav_overlay_add(_ov, 5, 4, 1);
var _b = gmnav_overlay_add(_ov, 5, 5, 1);
var _c = gmnav_overlay_add(_ov, 5, 6, 1);

gmnav_overlay_link(_ov, gmnav_grid_node(grid, 5, 3), _a, gmnav_link.STAIR, true);
gmnav_overlay_link(_ov, _c, gmnav_grid_node(grid, 5, 7), gmnav_link.STAIR, true);

gmnav_overlay_finish(_ov);
```

Three cells at column 5, on layer 1, joined to the ground at each end. That is
a bridge.

The nodes those calls return are ordinary node ids. They are larger than
`grid.count`, which is how the framework tells them apart, but everywhere you
would pass a node you can pass one of these. The search takes them, paths
contain them, agents walk to them, clearance measures them, cost profiles price
them, and every debug view draws them.

`gmnav_overlay_finish` bakes the edges. Until you call it the overlay has
cells but no connectivity, so call it once when you have finished authoring.

## The first rule

Look at what the example did **not** do: it did not link each deck cell to the
next one.

![A link only where the layer changes](chapter12_two_rules.svg)

Cells on the same layer are neighbours by the ordinary neighbour table, exactly
as base cells are. A six cell walkway on one layer needs no links between its
own cells, because they already touch. What needs saying is the change of
surface, and that happens twice: getting on, and getting off.

**A link is only needed where the layer actually changes.**

This is the rule people break first, usually by writing a loop that links every
deck cell to its neighbour. It works, in the sense that the paths come out
right, and it produces an overlay with dozens of redundant edges that all have
to be walked at every expansion. The framework does not stop you. It just costs
you for nothing.

## The second rule

The other habit worth forming concerns what a layer means.

**One layer per standable surface, not per unit of height.**

A cliff three lifts tall is one layer, drawn tall. It is not three layers
stacked, because you cannot stand on the middle of a cliff face. The number in
`gmnav_overlay_add` is answering "which surface is this", not "how high is
this".

Height within a layer is a separate control. The layer lift sets how far apart
layers are drawn, and per-cell offsets shift individual cells between them,
which is how ramps work and is the next chapter.

Get this backwards and you end up with a layer per tile of elevation, hundreds
of them, most holding nothing, and links everywhere trying to reconnect a
surface that should have been one layer all along.

## Picking

Here is the part that has no tidy answer, and the framework is honest about it
rather than guessing.

![One point, two answers](chapter12_picking.svg)

When the player clicks, or an enemy asks what is at a position, a point over a
bridge genuinely has more than one answer. Which one is correct depends on the
camera, the game's rules, and what the player was looking at, and GMNav owns
none of those.

So it asks you:

```gml
var _road = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 0);
var _deck = gmnav_grid_world_to_node(grid, mouse_x, mouse_y, 1);
var _top  = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);
```

The first two name a layer and return a node on it, or nothing if that layer
has no cell there. The third walks down from the highest layer and returns the
first surface it finds, which is what most games want most of the time and is
what "click on the thing you can see" usually means.

Agents carry a layer too, and `gmnav_agent_goto` takes one, so sending a unit
to the deck and sending it to the road below are different instructions with
the same coordinates.

## What the overlay inherits

An overlay cell is a real cell, not a marker. That is worth stating plainly
because it saves asking about each subsystem in turn.

Deck cells can be blocked and unblocked, which is how a collapsing span works.
They carry their own base cost, so a rickety walkway can be expensive without
touching the ground beneath it. Clearance measures them, and a deck narrower
than a unit's body reports exactly that. Cost layers and profiles reach them.
Flow fields cover them. Every debug view draws them at the height they sit at.

The one thing to hold in mind is that a deck's properties are its own. Dear
ground beneath a bridge does not make the bridge dear, and a blocked road does
not block the deck above it. That is the entire point of the mechanism, and it
is also the thing that surprises people the first time they stamp a radial cost
near a bridge and find the deck unaffected.

## Editing after the fact

Overlays are not frozen once built.

```gml
gmnav_overlay_set_blocked(_ov, _span, true);   // the bridge collapses
gmnav_overlay_set_cost(_ov, _span, 8);         // or merely becomes unpleasant
```

Blocking a span refuses that cell and leaves every other crossing on the map
working. You do not need to rebuild the overlay for a change of state, only for
a change of shape: adding or removing cells, or adding links.

Chapter 9's advice applies here unchanged, and is worth repeating in this
context. A span that is usually passable is better modelled as expensive than
as blocked, because an expensive deck can never strand anybody while a blocked
one can.

### Three ways a cell can be gone

Blocking is the reversible one. A blocked cell keeps its cost, its offset and
its clearance value, and unblocking it restores everything in place. That is
what you want for a door.

`gmnav_overlay_remove` is stronger. It marks the cell as **gone** entirely,
which is not the same thing:

```gml
// the cannon hits the bridge
gmnav_overlay_remove(_ov, _span);
gmnav_overlay_finish(_ov);
```

A removed cell reads as blocked to every subsystem that already respects
blocked state, is unreachable from `gmnav_overlay_node_at`, and is skipped at
the next `finish` so its edges are pruned. But it stays in the overlay's arrays
as a **tombstone**, marked with a bit. It is not deleted from memory, and
`gmnav_overlay_count` does not change.

The reason is that removing a cell mid-session and then re-adding it is the
common case for a bridge. Tombstoning means `gmnav_overlay_add` on the same
column, row and layer finds the existing slot, clears the bit, and returns the
**same node id** the caller was already using. Any id you were holding is still
valid, any array you built around that id is still correct. There is no
renumbering.

### When the tombstones add up

A long session of destroying and rebuilding leaves tombstones behind. They cost
a few bytes each and no per-frame work, so most games never need to do anything
about them. If a scripted event destroys a large fraction of an overlay, or if
a game has run for hours with constant destruction, `gmnav_overlay_compact`
reclaims the slots:

```gml
var _map = gmnav_overlay_compact(_ov);
```

Compaction drops every tombstoned cell and renumbers the survivors consecutively
starting at `base`. Authored links that touched a removed cell are dropped;
links between two live cells are renumbered. `max_layer` is recomputed. The
overlay is re-finished automatically at the end of the call, so the edges and
clearance are rebuilt against the new numbering.

This is destructive. Every node id you hold becomes invalid the moment it
returns, and any id that pointed at a removed cell is gone entirely. The
returned array is the old-to-new slot map, one entry per slot before the
compact, with `GMNAV_NO_NODE` for a cell that was removed. A caller that needs
to keep its references across a compact remaps them through that array.

`gmnav_overlay_count` tells you how many slots are still in use, including
tombstones. If you want a signal for when compaction is worth it, compare that
against the count of live cells.

## What you've learned

- **An overlay is a sparse set of cells above the grid**, and its nodes are
  ordinary node ids that every subsystem already understands.
- **A link is only needed where the layer changes.** Cells on one layer are
  already neighbours, so a walkway needs a link at each end and nothing in
  between.
- **One layer per standable surface**, not per unit of height. A tall cliff is
  one layer drawn tall.
- **Picking has no single answer**, so the caller names a layer.
  `gmnav_grid_world_to_node_top` is the usual convenience.
- **A deck cell is a real cell**: blockable, priceable, measurable, and
  independent of the ground beneath it.
- **State changes need no rebuild**, only shape changes do.
- **Removing a cell is not the same as blocking it.** `gmnav_overlay_remove`
  marks the cell gone, prunes its edges at the next `finish`, and makes it
  unreachable from any lookup. It stays in the arrays as a tombstone so
  `gmnav_overlay_add` can restore it later with the same node id, which is what
  a destroyed-and-rebuilt bridge needs.
- **`gmnav_overlay_compact` reclaims tombstones** and renumbers the rest.
  Destructive: any node id you hold becomes invalid. It returns an
  old-to-new-slot map so a caller can remap what it holds. Most games never
  need it.

## What's next

A bridge is flat. Terrain rarely is, and a deck that jumps from ground level to
its full height in one step reads as a wall with a door in it rather than
something you walk up.

In **Chapter 13** we cover ramps: per-cell offsets that let a surface climb in
even fractions of a layer, how to author them without computing the fractions
yourself, and the rendering problem they create, which is that a ramp drawn as
flat cells looks like a staircase no matter how smoothly the navigation treats
it.

See you there.
