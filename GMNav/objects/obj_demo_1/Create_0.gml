tile = 32;

// 1. describe the shape of the world
layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);

// 2. build a grid that covers the room
grid = gmnav_grid_create(room_width div tile, room_height div tile, layout);

// 3. tell GMNav where the walls are
demo1_build_walls(grid);

// 4. one scheduler owns the frame budget for every search in the game.
//    1500 node expansions per frame, at most 4 searches running at once.
sched = gmnav_scheduler_create(grid, 1500, 4);

// 5. start somewhere walkable
x = 2 * tile + tile * 0.5;
y = 2 * tile + tile * 0.5;

// 6. one agent. it proposes a velocity, it never moves us.
agent = gmnav_agent_create(sched, x, y, 10, 2.5);

// display
cfg = gmnav_debug_config();
cfg.cull = false;          // this room has no view enabled

show_grid = true;
blocked_click = 0;         // frames left on the "that is a wall" message