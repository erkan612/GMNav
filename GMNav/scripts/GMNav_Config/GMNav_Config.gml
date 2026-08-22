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
*   						             Version 1.0.0										 *
*   																                         *
*   						             by erkan612					                     *
*   					***********************************************                      *
*********************************************************************************************/


#macro GMNAV_VERSION "1.0.0"

enum gmnav_layout {
    ORTHO,          // square / rectangular top-down
    ISO_DIAMOND,    // 2:1 diamond isometric - clean linear transform
    ISO_STAGGERED,  // offset isometric - neighbours depend on row parity
    HEX_POINTY,     // pointy-top hexagons
    HEX_FLAT        // flat-top hexagons
}

enum gmnav_neighbours {
    FOUR,   // cardinal only
    EIGHT,  // cardinal + diagonal
    SIX     // hex
}

enum gmnav_costmode {
    LOGICAL,
    VISUAL
}

enum gmnav_heuristic {
    AUTO,        // pick the strongest admissible heuristic for the layout
    ZERO,        // no heuristic - degrades A* to Dijkstra. Optimal by
                 // construction, so it is the reference for optimality tests
    MANHATTAN,
    OCTILE,
    CHEBYSHEV,
    EUCLIDEAN,   // world-space distance / shortest step - universal fallback
    HEX
}

enum gmnav_state {
    IDLE,
    WORKING,
    FOUND,
    FAILED
}

enum gmnav_priority {
    LOW,
    NORMAL,
    HIGH,
    IMMEDIATE
}

enum gmnav_link {
    WALK,   // along a contiguous ledge
    FALL,   // stepped off an edge, no jump input
    JUMP    // ballistic arc from a jump input
}

enum gmnav_domain {
    GRID,       // gmnav_grid_create      - cell graph, A*
    PLATFORM    // gmnav_platgraph_create - CSR link graph, side-view A*
}

#macro GMNAV_CLEARANCE_MAX 16

enum gmnav_bake {
    IDLE,
    SURFACES,
    LINKS,
    DONE
}

#macro GMNAV_PLAT_MAX_SIM 300   // hard cap on simulated frames per arc
#macro GMNAV_PLAT_MAX_LINKS 24  // max outgoing links kept per node

#macro GMNAV_FLAG_BLOCKED   0x0001
#macro GMNAV_FLAG_ONEWAY    0x0002   // [[EXPERIMENTAL]]
#macro GMNAV_FLAG_LINK      0x0004   // [[RESERVED]] - endpoint of an off-graph link (jump, ladder, door)
#macro GMNAV_FLAG_WATER     0x0008   // [[RESERVED]]
#macro GMNAV_FLAG_DANGER    0x0010   // [[RESERVED]]
#macro GMNAV_FLAG_USER0     0x1000
#macro GMNAV_FLAG_USER1     0x2000
#macro GMNAV_FLAG_USER2     0x4000
#macro GMNAV_FLAG_USER3     0x8000

#macro GMNAV_DEFAULT_BUDGET 2000     // node expansions per frame, all searches combined
#macro GMNAV_HEAP_INIT      256      // initial open-set capacity
#macro GMNAV_MAX_STEPS      1000000  // hard abort guard per search

#macro GMNAV_NO_NODE   -1
#macro GMNAV_SQRT2     1.4142135623730951
#macro GMNAV_INF       infinity

#macro GMNAV_PLAT_FALL_WALK_CELLS 4  // how far a fall may walk to reach an edge