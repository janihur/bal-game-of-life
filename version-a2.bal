import ballerina/io;

const int GRID_SIZE_Y = 5;
const int GRID_SIZE_X = 5;

const int MAX_INDEX_Y = GRID_SIZE_Y - 1;
const int MAX_INDEX_X = GRID_SIZE_X - 1;

type Grid boolean[GRID_SIZE_Y][GRID_SIZE_X];

const boolean LIVE = true;
const boolean DEAD = false;

// current generation with seed (for generation 1)
Grid grid = [
    [DEAD, DEAD, DEAD, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, DEAD, DEAD, DEAD]
];

type Coord record {|
    int x;
    int y;
|};

const LIVE_STR = "■";
const DEAD_STR = "·";

public function main() {
    int generation = 1;

    while true {
        print(generation);

        Grid nextGrid = [[DEAD]];

        foreach int y in 0..<GRID_SIZE_Y {
            foreach int x in 0..<GRID_SIZE_X {
                final boolean currentCellState = grid[y][x];
                final int numberOfLiveNeighbours = numberOfLiveNeighboursOf({x, y});
                nextGrid[y][x] = nextCellState(currentCellState, numberOfLiveNeighbours);
            }
        }

        grid = nextGrid.clone();
        generation += 1;

        final string input = io:readln("Enter q to quit: ");
        if input == "q" {
            break;
        }
    }
}

function numberOfLiveNeighboursOf(Coord cell) returns int {
    int countOfLiveNeighbours = 0;

    // count only alive cells
    final var x = function(Coord c) {
        if grid[c.y][c.x] == LIVE {
            countOfLiveNeighbours += 1;
        }
    };

    // for better readability
    final int cy = cell.y;
    final int cx = cell.x;
    final int MY = MAX_INDEX_Y;
    final int MX = MAX_INDEX_X;

    //
    // check all possible neighbours
    //

    // top grid row ----------------------------------------------------------
    if cy == 0 {
        if cx == 0 { 
            // #1 left-hand-side grid column (left top corner)
                           x({y:0, x:1});
            x({y:1, x:0}); x({y:1, x:1});
        } else if cx == MX { 
            // #2 right-hand-side grid column (right top corner)
            x({y:0, x:MX-1});
            x({y:1, x:MX-1}); x({y:1, x:MX});
        } else { 
            // #3 all middle grid columns
            x({y:0,    x:cx-1});                    x({y:0,    x:cx+1});
            x({y:cy+1, x:cx-1}); x({y:cy+1, x:cx}); x({y:cy+1, x:cx+1});
        }
    } 
    // bottom grid row --------------------------------------------------------
    else if cy == MY {
        if cx == 0 { 
            // #4 left-hand-side grid column (left bottom corner)
            x({y:MY-1, x:0}); x({y:MY-1, x:1});
                              x({y:MY+0, x:1});
        } else if cx == MX { 
            // #5 right-hand-side grid column (right bottom corner)
            x({y:MY-1, x:MX-1}); x({y:MY-1, x:MX});
            x({y:MY+0, x:MX-1});
        } else { 
            // #6 all middle grid columns
            x({y:MY-1, x:cx-1}); x({y:MY-1, x:cx}); x({y:MY-1, x:cx+1});
            x({y:MY+0, x:cx-1});                    x({y:MY+0, x:cx+1});
        }
    } 
    // all middle grid rows ---------------------------------------------------
    else {
        if cx == 0 { 
            // #7 left-hand-side grid column
            x({y:cy-1, x:0}); x({y:cy-1, x:1});
                              x({y:cy+0, x:1});
            x({y:cy+1, x:0}); x({y:cy+1, x:1});
        } else if cx == MX { 
            // #8 right-hand-side grid column
            x({y:cy-1, x:MX-1}); x({y:cy-1, x:MX});
            x({y:cy+0, x:MX-1});
            x({y:cy+1, x:MX-1}); x({y:cy+1, x:MX});
        } else { 
            // #9 all middle grid columns
            x({y:cy-1, x:cx-1}); x({y:cy-1, x:cx}); x({y:cy-1, x:cx+1});
            x({y:cy+0, x:cx-1});                    x({y:cy+0, x:cx+1});
            x({y:cy+1, x:cx-1}); x({y:cy+1, x:cx}); x({y:cy+1, x:cx+1});
        }
    }

    return countOfLiveNeighbours;
}

function nextCellState(boolean cellState, int liveNeighbours) returns boolean {
    match cellState {
        LIVE => {
            match liveNeighbours {
                2|3 => { return LIVE; }
                _   => { return DEAD; }
            }
        }
        DEAD => {
            match liveNeighbours {
                3 => { return LIVE; }
                _ => { return DEAD; }
            }
        }
    }
    return DEAD; // dead-code to keep compiler happy :(
}

function print(int generation) {
    io:println("===");
    io:println(string`generation: ${generation}`);
    foreach var line in grid {
        foreach var cell in line {
            io:print(cell ? LIVE_STR : DEAD_STR);
        }
        io:println();
    }
}