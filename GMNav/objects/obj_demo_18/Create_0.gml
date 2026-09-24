/********************************************************************************
                            Troop Demo - Design Notes
---------------------------------------------------------------------------------
Question: "can troops move to a point in formation with configurable avoidance?"

Answer: yes and this demo shows it.

Local avoidance alone is enough for the job. For extra quality, a cost field
can be layered on top so paths route around the crowd instead of through it.
But there is a cost. Both together, on a large group, drops the frame rate
noticeably. The framework performs as promised, the scheduler keeps the peak
frame cost bounded. But a bounded cost is not a free one, and 62 simultaneous
searches with per-agent path smoothing is real work no matter how the cost is
sliced.

On this demo; 62 agents all moving att once, fps drops by 40%. Each of those
agents is running a real A*, its own route, its own smoothing, its own arrival
logic. That is a good number for pure GML. But its not how a real RTS does it.
RTS games issue one path for the whole group and let steering spread the units
along it; one search, many followers, hundreds of units, no drop.

When local avoidancec is enough; small groups, or groups that only need to
arrive rather than negotiate. When to add a costfield on top; when the crowd
geniuenly needs to route around itself, vehicle traffic is the best example,
where every unit's path is different and worth pricing. Cost field on top of 
avoidance is overkill for most troop movement, which is why it is optional here.

The framework has one more option at this scale; flowfields. One build, every
unit reads a direction for free. What flow fields do not do is assign each unit
its slot at the destination, because the field knows distance-to-goal, 
not "which of these 62 places is mine". That part is the caller's job,
measure each unit's distance to the end point, and once it is close, steer
it into its place. The framework asks only for a start point and an end
point; spreading is the game's call.

Why both; the cost field affects the search, avoidance affects the moment.
The cost field spreads paths around the crowd at planning time, making each
agent respect eachothers path. Avoidance handles the last few pixels of sixty
bodies converging on one doorway. Cost field only, units still stack at arrival.
Avoidance only, they all take the same route and fight at every chokepoint.
Both together produce a thinking model, depending on the given weight, they
will ignore their paths (the cells agents are touching, and the cells agents
will be touching depending on their speed needs to be marked properly) and
only pusheachother in a rush situation or a point making them look like a real
thinking and acting AIs. Demo 16 is a great example of that, this demo is more
like a showcase of how can it be done.
********************************************************************************/

if (!variable_global_exists("gmnav")) gmnav_init();

grid   = troop_make_grid();
layout = grid.layout;

sched = gmnav_scheduler_create(grid, 800, 3);

// cost layer, one profile, single weight. 
// the layer prices where units are, so paths route around the crowd rather than through it
crowd_layer = gmnav_costlayer_create(grid, "crowd");
crowd_prof  = gmnav_costprofile_create(grid, "troop");
gmnav_costprofile_add(crowd_prof, crowd_layer, 1.5);
gmnav_costprofile_bake(crowd_prof);

// units
units = [];

// spawn area, left middle of the map
_spawn_cells = [[4, 9], [5, 9], [6, 9], [4, 10], [5, 10], [6, 10],
                    [4, 11], [5, 11], [6, 11]];
spawn_cursor = 0;

function next_spawn_pos() {
    var _c = _spawn_cells[spawn_cursor];
    spawn_cursor = (spawn_cursor + 1) mod array_length(_spawn_cells);

    var _n = gmnav_grid_node(grid, _c[0], _c[1]);
    return gmnav_grid_node_to_world(grid, _n);
}

// initial squad
repeat (6) {
    var _p = next_spawn_pos();
    array_push(units, troop_make_unit(sched, TROOP_TYPE_SCOUT, _p[0], _p[1]));
}
repeat (6) {
    var _p = next_spawn_pos();
    array_push(units, troop_make_unit(sched, TROOP_TYPE_HEAVY, _p[0] + irandom_range(-6, 6),
                                                    _p[1] + irandom_range(-6, 6)));
}

// ui state
formation          = TROOP_FORM_GRID;
avoid_mode_idx     = 2;      // 0 BASIC, 1 CONTEXT, 2 FOLLOW

show_paths         = false;
show_cost          = false;

// input state
marquee_active     = false;
marquee_x1         = 0;
marquee_y1         = 0;
marquee_x2         = 0;
marquee_y2         = 0;
mouse_down_x       = 0;
mouse_down_y       = 0;

hover_unit         = undefined;

// order feedback
formation_flash    = [];     // array of { x, y, ttl }
// order issuing, spread over frames so 12 requests do not all land at once
pending_orders = [];         // array of { unit, x, y }
orders_per_frame = 2;

// cost layer rebuild cadence
cost_frame_counter = 0;
cost_interval      = 45;
cost_rect = [0, 0, -1, -1];

// round robin repath cursor
repath_cursor      = 0;

// settings panel
settings_open = false;

settings_rows = [
    { key : "avoid_str",        def : 1.0,  min : 0,    max : 2,   step : 0.05, label : "avoid_str" },
    { key : "avoid_range",      def : 2.5,  min : 1,    max : 5,   step : 0.1,  label : "avoid_range" },
    { key : "follow_gap",       def : 2.2,  min : 0.5,  max : 5,   step : 0.1,  label : "follow_gap" },
    { key : "follow_min",       def : 1.0,  min : 0.1,  max : 2,   step : 0.05, label : "follow_min" },
    { key : "follow_sep",       def : 0.02, min : 0,    max : 1,   step : 0.02, label : "follow_sep" },
    { key : "follow_floor",     def : 0.02, min : 0,    max : 1,   step : 0.02, label : "follow_floor" },
    { key : "follow_cone",      def : 0.35, min : 0.1,  max : 1.5, step : 0.05, label : "follow_cone" },
    { key : "basic_clear_div",  def : 3.0,  min : 1,    max : 8,   step : 0.5,  label : "basic_clear_div" },
    { key : "cs_probes",        def : 16,   min : 4,    max : 32,  step : 4,    label : "cs_probes" },
    { key : "cs_wall_weight",   def : 2.0,  min : 0,    max : 6,   step : 0.25, label : "cs_wall_weight" },
    { key : "cs_wall_range",    def : 2.5,  min : 0.5,  max : 6,   step : 0.25, label : "cs_wall_range" },
    { key : "cs_danger_weight", def : 1.5,  min : 0,    max : 4,   step : 0.25, label : "cs_danger_weight" }
];

// panel geometry, used by Step for hit testing and Draw GUI for rendering
settings_px = 900;
settings_py = 20;
settings_pw = 360;
settings_row_h = 26;
settings_header_h = 44;