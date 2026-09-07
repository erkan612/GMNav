enum gmnav_layout {
    ORTHO,								// square / rectangular top-down
    ISO_DIAMOND,						// 2:1 diamond isometric - clean linear transform
    ISO_STAGGERED,						// offset isometric - neighbours depend on row parity
    HEX_POINTY,							// pointy-top hexagons
    HEX_FLAT							// flat-top hexagons
}										
										
enum gmnav_neighbours {					
    FOUR,								// cardinal only
    EIGHT,								// cardinal + diagonal
    SIX									// hex
}										
										
enum gmnav_costmode {					
    LOGICAL,							
    VISUAL								
}										
										
enum gmnav_heuristic {					
    AUTO,								// pick the strongest admissible heuristic for the layout
    ZERO,								// no heuristic - degrades A* to Dijkstra. Optimal by
										// construction, so it is the reference for optimality tests
    MANHATTAN,							
    OCTILE,								
    CHEBYSHEV,							
    EUCLIDEAN,							// world-space distance / shortest step - universal fallback
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
										
enum gmnav_pmode {						
    GROUND,								// standing on a node, about to take the next link
    LINK,								// mid link, integrating the stored launch
    SETTLE								// landed, walking to the node's exact x
}										
										
enum gmnav_link {						
    WALK,								// along a contiguous ledge
    FALL,								// stepped off an edge, no jump input
    JUMP,								// ballistic arc from a jump input
    STAIR								// authored crossing between two layers
}										
										
enum gmnav_domain {						
    GRID,								// gmnav_grid_create      - cell graph, A*
    PLATFORM							// gmnav_platgraph_create - CSR link graph, side-view A*
}

enum gmnav_bake {
    IDLE,
    SURFACES,
    LINKS,
    DONE
}

#macro GMNAV_FLAG_BLOCKED   0x0001
#macro GMNAV_FLAG_ONEWAY    0x0002		// [[EXPERIMENTAL]]
#macro GMNAV_FLAG_LINK      0x0004		// [[RESERVED]] - endpoint of an off-graph link (jump, ladder, door)
#macro GMNAV_FLAG_WATER     0x0008		// [[RESERVED]]
#macro GMNAV_FLAG_DANGER    0x0010		// [[RESERVED]]
#macro GMNAV_FLAG_USER0     0x1000		
#macro GMNAV_FLAG_USER1     0x2000		
#macro GMNAV_FLAG_USER2     0x4000		
#macro GMNAV_FLAG_USER3     0x8000		

#macro GMNAV_NO_NODE   -1
#macro GMNAV_SQRT2     1.4142135623730951
#macro GMNAV_INF       infinity