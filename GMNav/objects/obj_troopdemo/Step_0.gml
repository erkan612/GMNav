// keyboard
if (keyboard_check_pressed(vk_tab)) settings_open = !settings_open;

if (keyboard_check_pressed(ord("F"))) formation = (formation + 1) mod TROOP_FORM_COUNT;

if (keyboard_check_pressed(ord("B"))) {
    avoid_mode_idx = (avoid_mode_idx + 1) mod 3;

    for (var i = 0; i < array_length(units); i++) {
        units[i].ag.avoid_mode = avoid_mode_idx;
    }
}

if (keyboard_check_pressed(ord("K"))) show_cost  = !show_cost;
if (keyboard_check_pressed(ord("P"))) show_paths = !show_paths;

if (keyboard_check_pressed(ord("N"))) {
    repeat (5) {
        var _p = next_spawn_pos();
        array_push(units, troop_make_unit(sched, TROOP_TYPE_SCOUT, _p[0], _p[1]));
    }
}

if (keyboard_check_pressed(ord("M"))) {
    repeat (5) {
        var _p = next_spawn_pos();
        array_push(units, troop_make_unit(sched, TROOP_TYPE_HEAVY, _p[0], _p[1]));
    }
}

if (keyboard_check_pressed(ord("A"))) {
    for (var i = 0; i < array_length(units); i++) units[i].selected = true;
}

if (keyboard_check_pressed(ord("S"))) {
    for (var i = 0; i < array_length(units); i++) {
        if (units[i].selected) gmnav_agent_stop(units[i].ag);
    }
}

if (keyboard_check_pressed(ord("R"))) {
    units = [];
    formation_flash = [];

    spawn_cursor = 0;

    repeat (6) {
        var _p = next_spawn_pos();
        array_push(units, troop_make_unit(sched, TROOP_TYPE_SCOUT, _p[0], _p[1]));
    }
    repeat (6) {
        var _p = next_spawn_pos();
        array_push(units, troop_make_unit(sched, TROOP_TYPE_HEAVY, _p[0], _p[1]));
    }

	gmnav_costlayer_clear(crowd_layer);
	gmnav_costprofile_bake(crowd_prof);
	cost_rect = [0, 0, -1, -1];
}

// mouse
var _clicked_panel = false;

if (settings_open && mouse_check_button_pressed(mb_left)) {
    var _panel_h = settings_header_h + array_length(settings_rows) * settings_row_h + 8;

    if (point_in_rectangle(mouse_x, mouse_y,
                           settings_px, settings_py,
                           settings_px + settings_pw, settings_py + _panel_h)) {

        _clicked_panel = true;

        var _sel_count = 0;
        for (var i = 0; i < array_length(units); i++) if (units[i].selected) _sel_count++;

        var _only_sel = (_sel_count > 0);

        // reset button, top right of the header
        if (point_in_rectangle(mouse_x, mouse_y,
                               settings_px + settings_pw - 70, settings_py + 8,
                               settings_px + settings_pw - 12, settings_py + 34)) {
            troop_settings_reset(units, settings_rows, _only_sel);
        } else {
            // which row
            for (var i = 0; i < array_length(settings_rows); i++) {
                var _ry = settings_py + settings_header_h + i * settings_row_h;

                var _minus_x = settings_px + 210;
                var _plus_x  = settings_px + settings_pw - 34;

                if (point_in_rectangle(mouse_x, mouse_y,
                                       _minus_x, _ry + 2,
                                       _minus_x + 22, _ry + 22)) {
                    troop_settings_apply(units, settings_rows, i, -1, _only_sel);
                    break;
                }

                if (point_in_rectangle(mouse_x, mouse_y,
                                       _plus_x, _ry + 2,
                                       _plus_x + 22, _ry + 22)) {
                    troop_settings_apply(units, settings_rows, i, +1, _only_sel);
                    break;
                }
            }
        }
    }
}

if (!_clicked_panel && mouse_check_button_pressed(mb_left)) {
    marquee_active = true;
    mouse_down_x   = mouse_x;
    mouse_down_y   = mouse_y;
    marquee_x1     = mouse_x;
    marquee_y1     = mouse_y;
    marquee_x2     = mouse_x;
    marquee_y2     = mouse_y;
}

if (marquee_active) {
    marquee_x2 = mouse_x;
    marquee_y2 = mouse_y;

    if (mouse_check_button_released(mb_left)) {
        marquee_active = false;

        var _dragged = point_distance(mouse_down_x, mouse_down_y, mouse_x, mouse_y) > 6;
        var _shift   = keyboard_check(vk_shift);

        if (!_shift) {
            for (var i = 0; i < array_length(units); i++) units[i].selected = false;
        }

        if (_dragged) {
            var _sel = troop_units_in_rect(units, mouse_down_x, mouse_down_y, mouse_x, mouse_y);
            for (var i = 0; i < array_length(_sel); i++) _sel[i].selected = true;
        } else {
            var _u = troop_unit_under_cursor(units, mouse_x, mouse_y);
            if (_u != undefined) _u.selected = true;
        }
    }
}

if (mouse_check_button_pressed(mb_right)) {
    var _sel = troop_selected_list(units);

    if (array_length(_sel) > 0) {
        var _n = gmnav_grid_world_to_node(grid, mouse_x, mouse_y);

        if (_n != GMNAV_NO_NODE && !gmnav_grid_is_blocked(grid, _n)) {
            var _maxr = 0;
            for (var i = 0; i < array_length(_sel); i++) {
                _maxr = max(_maxr, _sel[i].ag.radius);
            }
            var _spacing = _maxr * 2 + 22;

            // clear the old queue
            array_resize(pending_orders, 0);

            troop_plan_order(grid, _sel, mouse_x, mouse_y, formation,
                             _spacing, pending_orders);
        }
    }
}

// hover
hover_unit = undefined;
if (!marquee_active) hover_unit = troop_unit_under_cursor(units, mouse_x, mouse_y);

// update
gmnav_scheduler_update(sched);

// neighbour list, built once per frame
var _agents = [];
for (var i = 0; i < array_length(units); i++) array_push(_agents, units[i].ag);

for (var i = 0; i < array_length(units); i++) {
    var _u = units[i];

    gmnav_agent_update(_u.ag, _agents);
    troop_move(grid, _u);

    // facing, from the current velocity
    if (abs(_u.ag.vx) > 0.05 || abs(_u.ag.vy) > 0.05) {
        _u.facing = point_direction(0, 0, _u.ag.vx, _u.ag.vy);
    }
}

// cost layer, periodic
cost_frame_counter++;

if (cost_frame_counter mod cost_interval == 0) {
    cost_rect = troop_update_costfield(crowd_layer, crowd_prof, units, cost_rect);
}

// staggered repath
repath_cursor = (repath_cursor + 1) mod max(1, array_length(units));

if (array_length(units) > 0) {
    var _u = units[repath_cursor];

    if (gmnav_agent_has_path(_u.ag) && _u.ag.has_goal) {
        gmnav_agent_goto(_u.ag, _u.ag.goal_x, _u.ag.goal_y,
                         gmnav_priority.LOW, _u.ag.goal_layer);
    }
}

// formation flash
for (var i = array_length(formation_flash) - 1; i >= 0; i--) {
    formation_flash[i].ttl--;

    if (formation_flash[i].ttl <= 0) array_delete(formation_flash, i, 1);
}

// drain pending orders, orders_per_frame at a time
if (array_length(pending_orders) > 0) {
    var _batch = min(orders_per_frame, array_length(pending_orders));

    for (var i = 0; i < _batch; i++) {
        var _o = pending_orders[i];

        if (!gmnav_agent_goto(_o.u.ag, _o.x, _o.y, gmnav_priority.NORMAL)) {
            var _snap = troop_snap_for_body(grid, _o.x, _o.y,
                                            _o.u.ag.radius + 2, 6);

            if (_snap != undefined) {
                gmnav_agent_goto(_o.u.ag, _snap[0], _snap[1], gmnav_priority.NORMAL);
            }
            // if the snap also fails, the unit stays where it is. it will try again on the next order
        }
    }

    array_delete(pending_orders, 0, _batch);
}