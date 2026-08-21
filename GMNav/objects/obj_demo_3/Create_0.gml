tile = 32;

layout = gmnav_layout_create(gmnav_layout.ORTHO, tile, tile);
grid   = gmnav_grid_create(room_width div tile, room_height div tile, layout);
demo3_build_level(grid);

move = demo3_movement();
pg   = gmnav_platgraph_create(grid, move);
gmnav_platgraph_bake(pg);

budget = 1500;
sched  = gmnav_scheduler_create(pg, budget, 2);

// drop the character on the first surface node on the ground row
surf_row = grid.height - 5;
start    = gmnav_platgraph_node_at(pg, 3 * tile, surf_row * tile + 1);
if (start == GMNAV_NO_NODE) start = 0;
hero = demo3_character_create(pg, sched, start);

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

show_debug_message("demo3: edge_vx " + string(variable_struct_exists(pg, "edge_vx"))
                 + "  nodes " + string(pg.count)
                 + "  links " + string(array_length(pg.edge_to)));