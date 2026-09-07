/*********************************************************************************************
*                                        MIT License                                         *
*--------------------------------------------------------------------------------------------*
* Copyright (c) 2026 erkan612                                                                *
*                                                                                            *
* Permission is hereby granted, free of charge, to any person obtaining a copy of this       *
* software and associated documentation files (the "Software"), to deal in the Software      *
* without restriction, including without limitation the rights to use, copy, modify, merge,  *
* publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons *
* to whom the Software is furnished to do so, subject to the following conditions:           *
*                                                                                            *
* The above copyright notice and this permission notice shall be included in all copies or   *
* substantial portions of the Software.                                                      *
*                                                                                            *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,        *
* INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR   *
* PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE  *
* FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR       *
* OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER     *
* DEALINGS IN THE SOFTWARE.                                                                  *
**********************************************************************************************
*--------------------------------------------------------------------------------------------*
*   					***********************************************                      *
*   					 ██████╗ ███╗   ███╗███╗   ██╗ █████╗ ██╗   ██╗		                 *
*   					██╔════╝ ████╗ ████║████╗  ██║██╔══██╗██║   ██║		                 *
*   					██║  ███╗██╔████╔██║██╔██╗ ██║███████║██║   ██║		                 *
*   					██║   ██║██║╚██╔╝██║██║╚██╗██║██╔══██║╚██╗ ██╔╝		                 *
*   					╚██████╔╝██║ ╚═╝ ██║██║ ╚████║██║  ██║ ╚████╔╝ 		                 *
*   					 ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝  ╚═══╝  		                 *
*   							Pathfinding Engine for GameMaker	                         *
*   						             Version 1.1.41										 *
*   																                         *
*   						              by erkan612					                     *
*   					***********************************************                      *
*********************************************************************************************/


function gmnav_init(_overrides = undefined) {
    var _c = {
        // platformer
        PLAT_MAX_SIM         : 300,      // hard cap on simulated frames per arc
        PLAT_MAX_LINKS       : 24,       // max outgoing links kept per node
        PLAT_FALL_WALK_CELLS : 4,        // how far a fall may walk to reach a ledge edge

        // budget
        DEFAULT_BUDGET       : 2000,     // node expansions per frame, all searches combined
        HEAP_INIT            : 256,      // initial open-set capacity
        MAX_STEPS            : 1000000,  // hard abort guard per search
        CLEARANCE_MAX        : 16        // largest clearance value stored per cell
    };

    if (_overrides != undefined) {
        var _keys = variable_struct_get_names(_overrides);

        for (var _i = 0; _i < array_length(_keys); _i++) {
            var _k = _keys[_i];

            if (!variable_struct_exists(_c, _k)) {
                show_debug_message("GMNav: gmnav_init got an unknown setting, " + _k);
                continue;
            }
            _c[$ _k] = _overrides[$ _k];
        }
    }

    global.gmnav = { config : _c };
}

function __gmnav_ensure_init() {
    if (!variable_global_exists("gmnav")) gmnav_init();
}