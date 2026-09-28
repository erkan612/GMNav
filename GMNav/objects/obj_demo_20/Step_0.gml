if (keyboard_check_pressed(vk_space)) show_grid = !show_grid;

// R rebuilds, undoing any edits the player made
if (keyboard_check_pressed(ord("R"))) demo20_rebuild(id);

// A restores every removed bridge cell without compacting
if (keyboard_check_pressed(ord("A"))) demo20_restore_all(id);

// C compacts, dropping tombstones and renumbering the rest
if (keyboard_check_pressed(ord("C"))) demo20_compact(id);

// left click sets a new goal
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE) {
        var _p = gmnav_grid_node_to_world(grid, _n);
        demo20_set_goal(id, _p[0], _p[1]);
    }
}

// right click on a bridge cell removes or re-adds it
if (mouse_check_button_pressed(mb_right)) {
    var _cr = gmnav_layout_world_to_cell(grid.layout, mouse_x, mouse_y);
    var _bn = gmnav_overlay_node_at(grid.overlay, _cr[0], _cr[1], 1, true);

    if (_bn != GMNAV_NO_NODE) demo20_toggle_remove(id, _bn);
}

gmnav_scheduler_update(sched);

gmnav_agent_update(agent);
agent.x += agent.vx;
agent.y += agent.vy;