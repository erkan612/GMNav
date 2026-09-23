// info panel, left
draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(8, 8, 400, 340, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 16,  "GMNav Demo 16 - crossing crowds");
draw_text(20, 40,  "H / L        raise / lower urgency");
draw_text(20, 58,  "B            cycle avoid mode");
draw_text(20, 76,  "K            avoidance on / off");
draw_text(20, 94,  "D / X        place / clear danger");
draw_text(20, 112, "R            reset everything");
draw_text(20, 130, "P / V / G    paths, layer, grid");

// avoid state
var _mode_names = ["BASIC", "CONTEXT", "FOLLOW"];
var _mode_cols  = [ #E0B84A, #5FC8F0, #60C075 ];

draw_set_color(_mode_cols[avoid_mode_idx]);
draw_text(20, 160, "avoid mode   " + _mode_names[avoid_mode_idx]);

draw_set_color(avoid_on ? #75C060 : #8A8A8A);
draw_text(20, 178, "avoidance    " + (avoid_on ? "on" : "off"));

// urgency meter
draw_set_color(c_white);
draw_text(20, 206, "urgency");

var _ux = 100;
var _uy = 210;
var _uw = 280;
var _uh = 12;

draw_set_color(#303030);
draw_rectangle(_ux, _uy, _ux + _uw, _uy + _uh, false);

draw_set_color(#5FC8F0);
draw_rectangle(_ux, _uy, _ux + _uw * 0.33, _uy + _uh, false);
draw_set_color(#E0B84A);
draw_rectangle(_ux + _uw * 0.33, _uy, _ux + _uw * 0.66, _uy + _uh, false);
draw_set_color(#E05A3C);
draw_rectangle(_ux + _uw * 0.66, _uy, _ux + _uw, _uy + _uh, false);

var _nx = _ux + _uw * urgency_base;
draw_set_color(c_white);
draw_line(_nx, _uy - 2, _nx, _uy + _uh + 2);

// counts
var _arrived = 0;
var _rushing = 0;
var _patient = 0;
var _n = array_length(agents);

for (var i = 0; i < _n; i++) {
    var _a = agents[i];
    if (gmnav_agent_arrived(_a)) _arrived++;
    if (_a.urgency > 0.66) _rushing++;
    if (_a.urgency < 0.33) _patient++;
}

draw_set_color(c_white);
draw_text(20, 240, "agents       " + string(_n));
draw_text(20, 258, "patient      " + string(_patient));
draw_text(20, 276, "rushing      " + string(_rushing));
draw_text(20, 294, "arrivals     " + string(arrivals_total));
draw_text(20, 312, "frames       " + string(frames));

// legend
draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(8, 350, 400, 440, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 358, "urgency:");
draw_set_color(#5FC8F0);
draw_text(20, 380, "patient    routes around the crowd");
draw_set_color(#E0B84A);
draw_text(20, 398, "normal     some awareness");
draw_set_color(#E05A3C);
draw_text(20, 416, "rushing    pushes straight through");

// hero panel, left column bottom
draw_set_alpha(0.85);
draw_set_color(c_black);
draw_rectangle(8, 452, 400, 690, false);
draw_set_alpha(1);

draw_set_color(c_white);
draw_text(20, 460, "hero (agent 0) - left side");

var _hero = agents[0];
var _hx   = 200;
var _hy   = 580;

// side colour ring
draw_set_color(#E8C46A);
draw_circle(_hx, _hy, _hero.radius + 2, true);

// urgency fill
if      (_hero.urgency < 0.33) draw_set_color(#5FC8F0);
else if (_hero.urgency > 0.66) draw_set_color(#E05A3C);
else                            draw_set_color(#E0B84A);
draw_circle(_hx, _hy, _hero.radius - 2, false);

// velocity arrow
if (_hero.vx != 0 || _hero.vy != 0) {
    var _vm = point_distance(0, 0, _hero.vx, _hero.vy);

    if (_vm > 0.01) {
        var _ex = _hx + _hero.vx / _vm * 60;
        var _ey = _hy + _hero.vy / _vm * 60;
        var _ea = point_direction(_hx, _hy, _ex, _ey);

        draw_set_color(c_white);
        draw_line(_hx, _hy, _ex, _ey);
        draw_line(_ex, _ey,
                  _ex + lengthdir_x(6, _ea + 150),
                  _ey + lengthdir_y(6, _ea + 150));
        draw_line(_ex, _ey,
                  _ex + lengthdir_x(6, _ea - 150),
                  _ey + lengthdir_y(6, _ea - 150));
    }
}

// hero stats
draw_set_color(c_white);
draw_text(20, 640, "urgency       " + string_format(_hero.urgency, 1, 2));
draw_text(20, 658, "follow_gap    " + string_format(_hero.follow_gap, 1, 2));
draw_text(20, 676, "follow_sep    " + string_format(_hero.follow_sep, 1, 2));

draw_set_alpha(1);