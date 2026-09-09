if (keyboard_check_pressed(vk_space)) show_arrows = !show_arrows;
if (keyboard_check_pressed(ord("G"))) show_grid   = !show_grid;
if (keyboard_check_pressed(ord("P"))) paused      = !paused;

if (keyboard_check_pressed(ord("A"))) repeat (20) demo9_spawn(grid, units);

if (keyboard_check_pressed(ord("D"))) {
    repeat (20) {
        if (array_length(units) == 0) break;
        array_pop(units);
    }
}

// move the goal, and the whole crowd redirects off one rebuild
if (mouse_check_button_pressed(mb_left)) {
    var _n = gmnav_grid_world_to_node_top(grid, mouse_x, mouse_y);

    if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
        goal_c = gmnav_grid_col(grid, _n);
        goal_r = gmnav_grid_row(grid, _n);
        gmnav_flowfield_build(field, _n);
    }
}

if (paused) exit;

var _n = array_length(units);
for (var i = 0; i < _n; i++) demo9_unit_step(grid, field, units[i]);