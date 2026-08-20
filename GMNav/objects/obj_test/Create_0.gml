gmt_reset();
show_debug_message("########## GMNav suite ##########");

gmt_test_layout();
gmt_test_search();
gmt_test_flowfield();
gmt_test_clearance();
gmt_test_costfield();
gmt_test_nonortho();
gmt_test_dynamic();
gmt_test_sched_domains();
gmt_test_platformer();
gmt_test_agent();

gmt_head("D scheduler (running)");

sched_grid   = gmt_maze();
sched        = gmnav_scheduler_create(sched_grid, 5, 2);
sched_frames = 0;
sched_done   = false;

tk = [];
array_push(tk, gmnav_scheduler_request(sched, 0,  4));
array_push(tk, gmnav_scheduler_request(sched, 20, 4));
array_push(tk, gmnav_scheduler_request(sched, 24, 0));