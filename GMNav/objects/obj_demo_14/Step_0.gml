if (keyboard_check_pressed(ord("1"))) view_mode = 0;
if (keyboard_check_pressed(ord("2"))) view_mode = 1;
if (keyboard_check_pressed(ord("3"))) view_mode = 2;
if (keyboard_check_pressed(ord("4"))) view_mode = 3;
if (keyboard_check_pressed(ord("5"))) view_mode = 4;
if (keyboard_check_pressed(ord("6"))) view_mode = 5;
if (keyboard_check_pressed(ord("7"))) { view_mode = 6; demo14_probe(id); }

if (keyboard_check_pressed(ord("C"))) cfg.cull = !cfg.cull;
if (keyboard_check_pressed(ord("R"))) demo14_probe(id);

if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        var _p = gmnav_grid_node_to_world(grid, _n);
        gmnav_agent_goto(agent, _p[0], _p[1], gmnav_priority.NORMAL,
                         gmnav_grid_node_layer(grid, _n));
    }
}

// the frontier is only visible while a search is in flight, so this one is stepped slowly on purpose
if (probe_on && probe.state == gmnav_state.WORKING) gmnav_search_step(probe, 12);

gmnav_scheduler_update(sched);
gmnav_agent_update(agent);
agent.x += agent.vx;
agent.y += agent.vy;