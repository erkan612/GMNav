gmnav_debug_draw_grid(a_grid, cfg);
gmnav_debug_draw_path(a_grid, gmnav_search_get_path(a_search), cfg);

gmnav_debug_draw_grid(b_grid, cfg);
gmnav_debug_draw_path(b_grid, gmnav_search_get_path(b_search), cfg);

gmnav_debug_draw_flowfield(c_field, cfg, true);
gmnav_debug_draw_grid(c_grid, cfg);

gmnav_debug_draw_clearance(d_grid, cfg);
gmnav_debug_draw_costs(d_grid, d_prof, cfg);
gmnav_debug_draw_grid(d_grid, cfg);
gmnav_debug_draw_path(d_grid, gmnav_search_get_path(d_search), cfg);

gmnav_debug_draw_grid(e_grid, cfg);
gmnav_debug_draw_platgraph(e_graph, cfg, 7);

gmnav_debug_draw_grid(f_grid, cfg);
gmnav_debug_draw_search(f_search, cfg);

draw_set_color(c_white);
draw_text(210, 20,  "A  iso diamond");
draw_text(460, 20,  "B  hex pointy");
draw_text(880, 20,  "C  flow field");
draw_text(30,  300, "D  clearance + cost");
draw_text(430, 300, "E  platformer  white walk / blue fall / orange jump");
draw_text(890, 300, "F  search frontier  green open / grey closed");