tile = 32;

layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);
demo3_build_level(grid);

move = demo3_movement();
pg   = gmnav_platgraph_create(grid, move);
gmnav_platgraph_bake(pg);

budget = 1500;
sched  = gmnav_scheduler_create(pg, budget, 2);

surf_row = grid.height - 5;
hero     = gmnav_platagent_create(sched, 3 * tile, surf_row * tile + 1);

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.3;

show_grid  = true;
show_graph = false;
show_path  = true;
show_arc   = true;

link_mask = 7;    // 1 WALK, 2 FALL, 4 JUMP
stepping  = false;
step_now  = false;

bake_ms = 0;