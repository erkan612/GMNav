if (mouse_check_button_pressed(mb_left)) {
    if (!gmnav_platagent_goto(hero, mouse_x, mouse_y)) hero.failed = true;
}

if (keyboard_check_pressed(ord("G"))) show_graph = !show_graph;

// cycle which link types the graph overlay shows
if (keyboard_check_pressed(ord("L"))) {
    link_mask = (link_mask == 7) ? 1 : ((link_mask == 1) ? 2 : ((link_mask == 2) ? 4 : 7));
}

if (keyboard_check_pressed(ord("P"))) show_path = !show_path;
if (keyboard_check_pressed(ord("J"))) show_arc  = !show_arc;
if (keyboard_check_pressed(vk_space)) show_grid = !show_grid;

// F freezes the agent so an arc can be walked frame by frame with N
if (keyboard_check_pressed(ord("F"))) stepping = !stepping;
step_now = keyboard_check_pressed(ord("N"));

if (keyboard_check_pressed(ord("B"))) {
    move.jump_bias = (move.jump_bias > 1.4) ? 1.333 : 1.5;

    var _t0 = get_timer();
    gmnav_platgraph_bake(pg);
    bake_ms = (get_timer() - _t0) / 1000;

    gmnav_platagent_stop(hero);
}

if (keyboard_check_pressed(ord("R"))) {
    var _t0 = get_timer();
    gmnav_platgraph_bake(pg);
    bake_ms = (get_timer() - _t0) / 1000;

    gmnav_platagent_stop(hero);
}

gmnav_scheduler_update(sched);

if (!stepping || step_now) gmnav_platagent_update(hero);