// input
if (keyboard_check_pressed(ord("D"))) allow_drop = !allow_drop;
if (keyboard_check_pressed(ord("P"))) show_path  = !show_path;
if (keyboard_check_pressed(ord("G"))) show_graph = !show_graph;

if (keyboard_check_pressed(ord("R"))) {
    gmnav_platagent_stop(hero);

    var _sp_n = demo17_spawn_node(grid, pg);

    if (_sp_n != GMNAV_NO_NODE) {
        hero.node = _sp_n;
        hero.x    = pg.node_x[_sp_n];
        hero.y    = pg.node_y[_sp_n];
    }
    failed = false;
}

if (mouse_check_button_pressed(mb_left)) {
	var _goal = demo17_node_near(pg, grid, mouse_x, mouse_y);

	if (_goal == GMNAV_NO_NODE) {
	    failed = true;
	} else {
	    var _gp = gmnav_platgraph_node_world(pg, _goal);
	    failed = !gmnav_platagent_goto(hero, _gp[0], _gp[1], gmnav_priority.NORMAL, allow_drop);
	}
}

// tick
gmnav_scheduler_update(sched);
gmnav_platagent_update(hero);