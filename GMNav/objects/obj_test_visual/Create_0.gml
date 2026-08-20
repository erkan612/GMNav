cfg = gmnav_debug_config();
cfg.cull = false;
cfg.alpha = 0.4;

a_grid = gmnav_grid_create(12, 12,
    gmnav_layout_create(gmnav_layout.ISO_DIAMOND, 32, 16,
                        gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL, 210, 40));
gmnav_grid_fill_blocked(a_grid, 6, 1, 6, 9, true);

a_search = gmnav_search_create(a_grid);
gmnav_search_begin(a_search, gmnav_grid_node(a_grid, 1, 1), gmnav_grid_node(a_grid, 10, 10));
gmnav_search_step(a_search, 100000);

b_grid = gmnav_grid_create(10, 8,
    gmnav_layout_create(gmnav_layout.HEX_POINTY, 32, 36,
                        gmnav_neighbours.SIX, gmnav_costmode.LOGICAL, 460, 50));
gmnav_grid_fill_blocked(b_grid, 5, 1, 5, 6, true);

b_search = gmnav_search_create(b_grid);
gmnav_search_begin(b_search, gmnav_grid_node(b_grid, 1, 1), gmnav_grid_node(b_grid, 9, 6));
gmnav_search_step(b_search, 100000);

c_grid = gmnav_grid_create(12, 9,
    gmnav_layout_create(gmnav_layout.ORTHO, 24, 24,
                        gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL, 880, 40));
gmnav_grid_fill_blocked(c_grid, 5, 0, 5, 5, true);
gmnav_grid_fill_blocked(c_grid, 8, 4, 8, 8, true);

c_field = gmnav_flowfield_create(c_grid);
gmnav_flowfield_build(c_field, gmnav_grid_node(c_grid, 11, 8));

d_grid = gmnav_grid_create(14, 9,
    gmnav_layout_create(gmnav_layout.ORTHO, 24, 24,
                        gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL, 30, 320));
gmnav_grid_fill_blocked(d_grid, 7, 0, 7, 3, true);
gmnav_grid_fill_blocked(d_grid, 7, 6, 7, 8, true);
gmnav_clearance_build(d_grid);

d_layer = gmnav_costlayer_create(d_grid, "danger");
gmnav_costlayer_stamp_radial(d_layer, 30 + 10 * 24, 320 + 6 * 24, 90, 14, 2);
d_prof = gmnav_costprofile_create(d_grid, "demo");
gmnav_costprofile_add(d_prof, d_layer, 1);
gmnav_costprofile_bake(d_prof);

d_search = gmnav_search_create(d_grid);
gmnav_search_begin(d_search, gmnav_grid_node(d_grid, 0, 4),
                             gmnav_grid_node(d_grid, 13, 4), false, d_prof);
gmnav_search_step(d_search, 100000);

e_grid = gmnav_grid_create(26, 15,
    gmnav_layout_create(gmnav_layout.ORTHO, 15, 15,
                        gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL, 430, 320));
gmnav_grid_fill_blocked(e_grid, 0, 13, 7, 13, true);    // low floor
gmnav_grid_fill_blocked(e_grid, 10, 13, 17, 13, true);  // across a 2-gap
gmnav_grid_fill_blocked(e_grid, 3, 8,  9, 8,  true);    // mid shelf
gmnav_grid_fill_blocked(e_grid, 14, 4, 22, 4, true);    // high shelf
gmnav_grid_fill_blocked(e_grid, 20, 10, 25, 10, true);  // right platform

e_graph = gmnav_platgraph_create(e_grid,
    gmnav_movement_create(0.5, 5, 2.5, 8, 10, 20, undefined, 3));
gmnav_platgraph_bake(e_graph);

f_grid = gmnav_grid_create(14, 10,
    gmnav_layout_create(gmnav_layout.ORTHO, 24, 24,
                        gmnav_neighbours.EIGHT, gmnav_costmode.LOGICAL, 890, 320));
gmnav_grid_fill_blocked(f_grid, 6, 0, 6, 6, true);

f_search = gmnav_search_create(f_grid);
gmnav_search_begin(f_search, gmnav_grid_node(f_grid, 1, 5), gmnav_grid_node(f_grid, 12, 5));
gmnav_search_step(f_search, 12);