grid   = demo16_make_grid();
layout = grid.layout;

sched = gmnav_scheduler_create(grid, 3000, 8);

// crowd cost layer, three reader profiles
crowd_layer = gmnav_costlayer_create(grid, "crowd");

prof_patient = gmnav_costprofile_create(grid, "patient");
gmnav_costprofile_add(prof_patient, crowd_layer, 4.0);

prof_normal = gmnav_costprofile_create(grid, "normal");
gmnav_costprofile_add(prof_normal, crowd_layer, 1.5);

prof_rush = gmnav_costprofile_create(grid, "rush");
gmnav_costprofile_add(prof_rush, crowd_layer, 0.25);

gmnav_costprofile_bake(prof_patient);
gmnav_costprofile_bake(prof_normal);
gmnav_costprofile_bake(prof_rush);

// agents
agents       = [];
danger_cells = [];
stamp_rect   = [0, 0, -1, -1];

urgency_base = 0.5;

avoid_mode_idx = 2; // 0 BASIC, 1 CONTEXT, 2 FOLLOW
avoid_on       = true;

for (var i = 0; i < DEMO16_N; i++) {
    var _sc = demo16_spawn_cell(i);
    var _sp = demo16_world_of_cell(grid, _sc);

    var _a = gmnav_agent_create(sched, _sp[0], _sp[1], 8, 1.6);

    _a.avoid_range   = 2.5;
    _a.follow_gap    = 2.2;
    _a.follow_min    = 1.0;
    _a.follow_sep    = 0.02;
    _a.follow_floor  = 0.02;
    _a.follow_cone   = 0.35;

    _a.urgency = clamp(urgency_base + random_range(-0.35, 0.35), 0, 1);
    _a.profile = demo16_urgency_profile(id, _a);

    array_push(agents, _a);
}

demo16_apply_avoid(id);

for (var i = 0; i < DEMO16_N; i++) demo16_send(id, i);

// timing
frames         = 0;
arrivals_total = 0;

cfg = gmnav_debug_config();
cfg.cull  = false;
cfg.alpha = 0.35;

show_paths = false;
show_layer = true;
show_grid  = false;