grid   = demo17_make_grid();
layout = grid.layout;

move = demo17_movement();

pg = gmnav_platgraph_create(grid, move);
gmnav_platgraph_bake(pg);

sched = gmnav_scheduler_create(pg, 1500, 2);

var _sp_n = demo17_spawn_node(grid, pg);

hero = gmnav_platagent_create(sched, pg.node_x[_sp_n], pg.node_y[_sp_n]);

allow_drop = true;
show_path  = true;
show_graph = false;
failed     = false;

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.3;