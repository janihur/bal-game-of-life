import ballerina/io;

const int GRID_SIZE_Y = 5;
const int GRID_SIZE_X = 5;

const int MAX_INDEX_Y = GRID_SIZE_Y - 1;
const int MAX_INDEX_X = GRID_SIZE_X - 1;

type Grid boolean[GRID_SIZE_Y][GRID_SIZE_X];

type Coord record {|
    int x;
    int y;
|};

const boolean LIVE = true;
const boolean DEAD = false;

const string LIVE_CELL_REPRESENTATION = "■";
const string DEAD_CELL_REPRESENTATION = "·";

public function main() {
    int generation = 1;

    // current generation (1) with seed
    Grid grid = [
        [DEAD, DEAD, DEAD, DEAD, DEAD],
        [DEAD, DEAD, LIVE, DEAD, DEAD],
        [DEAD, DEAD, LIVE, DEAD, DEAD],
        [DEAD, DEAD, LIVE, DEAD, DEAD],
        [DEAD, DEAD, DEAD, DEAD, DEAD]
    ];

    while true {
        print(grid, generation);

        final Grid nextGrid = [[DEAD]];

        foreach int y in 0..<GRID_SIZE_Y {
            foreach int x in 0..<GRID_SIZE_X {
                final boolean currentCellState = grid[y][x];
                final Coord[] neighbours = neighboursOf({x, y});
                final int numberOfLiveNeighbours = numberOfLiveCells(grid, neighbours);
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

# Calculate all valid neighbour cell coordinates of `cell`.
# 
# + cell - The cell which neighbours are looked for
# + return - An array of all valid neighbour cell coordinates
isolated function neighboursOf(Coord cell) returns Coord[] {
    final Coord[] candidateCoordinates = 
        let int cy = cell.y,
            int cx = cell.x 
    in [
        {y:cy-1, x:cx-1}, {y:cy-1, x:cx+0}, {y:cy-1, x:cx+1},
        {y:cy+0, x:cx-1},                   {y:cy+0, x:cx+1},
        {y:cy+1, x:cx-1}, {y:cy+1, x:cx+0}, {y:cy+1, x:cx+1}
    ];

    final Coord[] validCoordinates = candidateCoordinates.filter(isolated function(Coord c) returns boolean {
        if c.y < 0           { return false; }
        if c.y > MAX_INDEX_Y { return false; }
        if c.x < 0           { return false; }
        if c.x > MAX_INDEX_X { return false; }
        return true;
    });

    return validCoordinates;
}

// this won't work :( because:
// https://github.com/ballerina-platform/ballerina-spec/issues/602
// isolated function numberOfLiveCells(Grid grid, Coord[] cells) returns int {
//     return cells.reduce(isolated function (int accu, Coord c) returns int {
//         return grid[c.y][c.x] == LIVE ? accu + 1 : accu;
//     }, 0);
// }

# Calculate the number of live cells (`cells`) in the current generation (`grid`).
# 
# + grid - The generation Grid that is the basis of the check
# + cells - The cells that are checked
# + return - Number of live cells
isolated function numberOfLiveCells(Grid grid, Coord[] cells) returns int {
    int accu = 0;
    foreach Coord c in cells {
        if grid[c.y][c.x] == LIVE {
            accu += 1;
        }
    }
    return accu;
}

# Calculate the next cell state based on the number of live neighbours.
# 
# + cellState - The current state
# + liveNeighbours - The number of live neighbours
# + return - The next state
isolated function nextCellState(boolean cellState, int liveNeighbours) returns boolean {
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

# Visualize the grid by printing it to the screen.
# 
# + grid - The grid
# + generation - The generation number used in the header
isolated function print(Grid grid, int generation) {
    io:println("===");
    io:println(string`generation: ${generation}`);
    foreach var line in grid {
        foreach var cell in line {
            io:print(cell == LIVE ? LIVE_CELL_REPRESENTATION : DEAD_CELL_REPRESENTATION);
        }
        io:println();
    }
}