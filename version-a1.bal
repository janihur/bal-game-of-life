import ballerina/io;

const int GRID_SIZE_X = 5;
const int GRID_SIZE_Y = 5;

const int MAXX = GRID_SIZE_X - 1;
const int MAXY = GRID_SIZE_Y - 1;

type Grid boolean[GRID_SIZE_Y][GRID_SIZE_X];

const boolean LIVE = true;
const boolean DEAD = false;

// seed
Grid grid = [
    [DEAD, DEAD, DEAD, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, LIVE, DEAD, DEAD],
    [DEAD, DEAD, DEAD, DEAD, DEAD]
];

final Grid emptyGrid = [
    [DEAD, DEAD, DEAD, DEAD, DEAD],
    [DEAD, DEAD, DEAD, DEAD, DEAD],
    [DEAD, DEAD, DEAD, DEAD, DEAD],
    [DEAD, DEAD, DEAD, DEAD, DEAD],
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

        int x = 0;
        int y = 0;
        Grid nextGrid = emptyGrid.clone();

        foreach var line in grid {
            x = 0;
            foreach var _ in line {
                final boolean currentCellState = grid[y][x];
                final int numberOfLiveNeighbours = liveNeighboursOf({x, y});
                nextGrid[y][x] = nextCellState(currentCellState, numberOfLiveNeighbours);
                x += 1;
            }
            y += 1;
        }

        grid = nextGrid.clone();
        generation += 1;

        final string input = io:readln("Enter q to quit: ");
        if input == "q" {
            break;
        }
    }
}

function allNeighboursOf(Coord cell) returns Coord[] {
    Coord[] neighbours = [];

     // top grid row ----------------------------------------------------------
    if cell.y == 0 {
        if cell.x == 0 { 
            // #1 left-hand-side grid column (left top corner)
            neighbours.push(
                           {y:0, x:1},
                {y:1, x:0},{y:1, x:1}
            );
        } else if cell.x == MAXX { 
            // #2 right-hand-side grid column (right top corner)
            neighbours.push(
                {y:0, x:MAXX-1},
                {y:1, x:MAXX-1},{y:1, x:MAXX}
            );
        } else { 
            // #3 all middle grid columns
            neighbours.push(
                {y:0,        x:cell.x-1},                       {y:0,        x:cell.x+1},
                {y:cell.y+1, x:cell.x-1},{y:cell.y+1, x:cell.x},{y:cell.y+1, x:cell.x+1}
            );
        }
    } 
    // bottom grid row --------------------------------------------------------
    else if cell.y == MAXY {
        if cell.x == 0 { 
            // #4 left-hand-side grid column (left bottom corner)
            neighbours.push(
                {y:MAXY-1, x:0},{y:MAXY-1, x:1},
                                {y:MAXY,   x:1}
            );
        } else if cell.x == MAXX { 
            // #5 right-hand-side grid column (right bottom corner)
            neighbours.push(
                {y:MAXY-1, x:MAXX-1},{y:MAXY-1, x:MAXX},
                {y:MAXY,   x:MAXX-1}
            );
        } else { 
            // #6 all middle grid columns
            neighbours.push(
                {y:MAXY-1, x:cell.x-1},{y:MAXY-1, x:cell.x},{y:MAXY-1, x:cell.x+1},
                {y:MAXY,   x:cell.x-1},                     {y:MAXY,   x:cell.x+1}
            );
        }
    } 
    // all middle grid rows ---------------------------------------------------
    else {
        if cell.x == 0 { 
            // #7 left-hand-side grid column
            neighbours.push(
                {y:cell.y-1, x:0},{y:cell.y-1, x:1},
                                  {y:cell.y,   x:1},
                {y:cell.y+1, x:0},{y:cell.y+1, x:1}
            );
        } else if cell.x == MAXX { 
            // #8 right-hand-side grid column
            neighbours.push(
                {y:cell.y-1, x:MAXX-1},{y:cell.y-1, x:MAXX},
                {y:cell.y,   x:MAXX-1},
                {y:cell.y+1, x:MAXX-1},{y:cell.y+1, x:MAXX}
            );
        } else { 
            // #9 all middle grid columns
            neighbours.push(
                {y:cell.y-1, x:cell.x-1},{y:cell.y-1, x:cell.x},{y:cell.y-1, x:cell.x+1},
                {y:cell.y,   x:cell.x-1},                       {y:cell.y,   x:cell.x+1},
                {y:cell.y+1, x:cell.x-1},{y:cell.y+1, x:cell.x},{y:cell.y+1, x:cell.x+1}
            );
        }
    }

    return neighbours;
}

function liveNeighboursOf(Coord cell) returns int {
    Coord[] neighbours = allNeighboursOf(cell);
    return neighbours.reduce(function(int total, Coord c) returns int {
        return grid[c.y][c.x] ? total + 1 : total;
    }, 0);
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