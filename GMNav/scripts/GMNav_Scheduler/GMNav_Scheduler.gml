function gmnav_scheduler_create(_target, _budget = GMNAV_DEFAULT_BUDGET, _concurrent = 4) {
    var _dom = _target[$ "domain"] ?? gmnav_domain.GRID;

    return {
        domain     : _dom,
        target     : _target,

        grid       : (_dom == gmnav_domain.PLATFORM) ? _target.grid : _target,

        budget     : _budget,
        concurrent : min(_concurrent, _target.slot_max),

        queue      : [],   // waiting tickets, priority order
        active     : [],   // tickets currently holding a scratch slot
        pool       : [],   // recycled search objects, all of one domain

        seq        : 0,    // FIFO tie-break within a priority band
        last_pops  : 0,    // diagnostics for the debugger
        last_active: 0
    };
}

function gmnav_scheduler_request(_sched, _start_node, _goal_node,
                                 _priority = gmnav_priority.NORMAL,
                                 _corner_cut = false,
                                 _profile = undefined,
                                 _need_clear = 0) {
    var _ticket = {
        state      : gmnav_state.IDLE,
        priority   : _priority,
        seq        : _sched.seq++,
        start      : _start_node,
        goal       : _goal_node,

        corner_cut : _corner_cut,
        profile    : _profile,
        need_clear : _need_clear,

        search     : undefined,
        path       : [],
        links      : [],   // platformer domain only
        stale      : false,
        cancelled  : false
    };

    if (_priority == gmnav_priority.IMMEDIATE) {
        __gmnav_sched_run_immediate(_sched, _ticket);
        return _ticket;
    }

    array_push(_sched.queue, _ticket);
    return _ticket;
}

function gmnav_scheduler_update(_sched) {
    __gmnav_sched_promote(_sched);

    var _n = array_length(_sched.active);
    _sched.last_active = _n;
    _sched.last_pops   = 0;
    if (_n == 0) return;

    var _share = max(1, _sched.budget div _n);
    var _spare = _sched.budget - (_share * _n);

    for (var i = array_length(_sched.active) - 1; i >= 0; i--) {
        var _t = _sched.active[i];

        if (_t.cancelled) {
            __gmnav_sched_kill(_sched, _t.search);
            __gmnav_sched_recycle(_sched, _t);
            array_delete(_sched.active, i, 1);
            continue;
        }

        var _give   = _share + _spare;
        _spare      = 0;
        var _before = _t.search.pops;

        var _st = __gmnav_sched_advance(_sched, _t.search, _give);

        var _used = _t.search.pops - _before;
        _sched.last_pops += _used;
        if (_used < _give) _spare += (_give - _used);

        _t.state = _st;

        if (_st != gmnav_state.WORKING) {
            if (_st == gmnav_state.FOUND) __gmnav_sched_collect(_sched, _t);
            __gmnav_sched_recycle(_sched, _t);
            array_delete(_sched.active, i, 1);
        }
    }

    __gmnav_sched_promote(_sched);
}

function gmnav_scheduler_cancel(_sched, _ticket) {
    _ticket.cancelled = true;

    if (_ticket.search == undefined) {
        var _i = __gmnav_sched_queue_index(_sched, _ticket);
        if (_i >= 0) array_delete(_sched.queue, _i, 1);
        _ticket.state = gmnav_state.FAILED;
    }
}

function gmnav_scheduler_is_ready(_ticket) {
    return (_ticket.state == gmnav_state.FOUND);
}

function gmnav_scheduler_get_path(_ticket) {
    return _ticket.path;
}

function gmnav_scheduler_get_links(_ticket) {
    return _ticket.links;
}

function gmnav_scheduler_pending(_sched) {
    return array_length(_sched.queue);
}

function __gmnav_sched_make(_sched) {
    if (array_length(_sched.pool) > 0) return array_pop(_sched.pool);

    return (_sched.domain == gmnav_domain.PLATFORM)
         ? gmnav_graphsearch_create(_sched.target)
         : gmnav_search_create(_sched.target);
}

function __gmnav_sched_begin(_sched, _srch, _t) {
    if (_sched.domain == gmnav_domain.PLATFORM) {
        return gmnav_graphsearch_begin(_srch, _t.start, _t.goal);
    }
    return gmnav_search_begin(_srch, _t.start, _t.goal,
                              _t.corner_cut, _t.profile, _t.need_clear);
}

function __gmnav_sched_advance(_sched, _srch, _budget) {
    return (_sched.domain == gmnav_domain.PLATFORM)
         ? gmnav_graphsearch_step(_srch, _budget)
         : gmnav_search_step(_srch, _budget);
}

function __gmnav_sched_collect(_sched, _t) {
    var _s = _t.search;

    if (_sched.domain == gmnav_domain.PLATFORM) {
        _t.path  = gmnav_graphsearch_get_path(_s);
        _t.links = gmnav_graphsearch_get_links(_s);
        _t.stale = gmnav_graphsearch_is_stale(_s);
    } else {
        _t.path  = gmnav_search_get_path(_s);
        _t.stale = gmnav_search_is_stale(_s);
    }
}

function __gmnav_sched_release(_sched, _srch) {
    if (_sched.domain == gmnav_domain.PLATFORM) gmnav_graphsearch_release(_srch);
    else                                        gmnav_search_release(_srch);
}

function __gmnav_sched_kill(_sched, _srch) {
    if (_srch == undefined) return;
    if (_sched.domain == gmnav_domain.PLATFORM) gmnav_graphsearch_abort(_srch);
    else                                        gmnav_search_abort(_srch);
}

function __gmnav_sched_promote(_sched) {
    if (array_length(_sched.queue) == 0) return;

    __gmnav_sched_sort_queue(_sched);

    while (array_length(_sched.active) < _sched.concurrent
        && array_length(_sched.queue)  > 0) {

        var _t = _sched.queue[0];

        if (_t.cancelled) {
            array_delete(_sched.queue, 0, 1);
            continue;
        }

        var _srch = __gmnav_sched_make(_sched);

        if (__gmnav_sched_begin(_sched, _srch, _t)) {
            _t.search = _srch;
            _t.state  = gmnav_state.WORKING;
            array_delete(_sched.queue, 0, 1);
            array_push(_sched.active, _t);
            continue;
        }

        array_push(_sched.pool, _srch);

        if (_srch.state == gmnav_state.FAILED) {
            _t.state = gmnav_state.FAILED;
            array_delete(_sched.queue, 0, 1);
            continue;
        }
        break;
    }
}

function __gmnav_sched_sort_queue(_sched) {
    var _q = _sched.queue;
    var _n = array_length(_q);

    for (var i = 1; i < _n; i++) {
        var _t  = _q[i];
        var _tp = _t.priority;
        var _ts = _t.seq;
        var _j  = i - 1;

        while (_j >= 0) {
            var _o = _q[_j];
            if (_o.priority > _tp) break;
            if (_o.priority == _tp && _o.seq < _ts) break;
            _q[_j + 1] = _o;
            _j--;
        }
        _q[_j + 1] = _t;
    }
}

function __gmnav_sched_queue_index(_sched, _ticket) {
    var _q = _sched.queue;
    for (var i = 0; i < array_length(_q); i++) {
        if (_q[i] == _ticket) return i;
    }
    return -1;
}

function __gmnav_sched_recycle(_sched, _ticket) {
    if (_ticket.search != undefined) {
        __gmnav_sched_release(_sched, _ticket.search);
        array_push(_sched.pool, _ticket.search);
        _ticket.search = undefined;
    }
}

function __gmnav_sched_run_immediate(_sched, _ticket) {
    var _srch = __gmnav_sched_make(_sched);

    if (!__gmnav_sched_begin(_sched, _srch, _ticket)) {
        _ticket.state = (_srch.state == gmnav_state.FAILED)
                      ? gmnav_state.FAILED
                      : gmnav_state.IDLE;
        array_push(_sched.pool, _srch);

        if (_ticket.state == gmnav_state.IDLE) array_push(_sched.queue, _ticket);
        return;
    }

    _ticket.search = _srch;
    var _st = __gmnav_sched_advance(_sched, _srch, GMNAV_MAX_STEPS);

    if (_st == gmnav_state.FOUND) __gmnav_sched_collect(_sched, _ticket);

    _ticket.state = _st;
    __gmnav_sched_recycle(_sched, _ticket);
}