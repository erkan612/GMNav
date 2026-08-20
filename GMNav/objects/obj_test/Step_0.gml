if (sched_done) exit;

sched_frames++;
gmnav_scheduler_update(sched);

for (var i = 0; i < 3; i++) {
    var _s = tk[i].state;
    if (_s == gmnav_state.IDLE || _s == gmnav_state.WORKING) exit;
}

sched_done = true;

gmt_check("ticket 0 found", tk[0].state, gmnav_state.FOUND);
gmt_check("ticket 1 found", tk[1].state, gmnav_state.FOUND);
gmt_check("ticket 2 found", tk[2].state, gmnav_state.FOUND);
gmt_check_arr("ticket 0 path", gmnav_scheduler_get_path(tk[0]), [0,6,11,16,21,22,23,19,14,9,4]);
gmt_check("ticket 1 length", array_length(gmnav_scheduler_get_path(tk[1])), 8);
gmt_check("ticket 2 length", array_length(gmnav_scheduler_get_path(tk[2])), 8);
gmt_check("none stale", tk[0].stale || tk[1].stale || tk[2].stale, false);
gmt_note("frames to drain", sched_frames);

gmt_summary();