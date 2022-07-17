import ballerina/io;

const int GRID_SIZE_Y = 5;
const int GRID_SIZE_X = 5;

type Coord record {|
    readonly int x;
    readonly int y;
|};

type CoordSet table<Coord> key (x, y);

const string LIVE_CELL_REPRESENTATION = "■";
const string DEAD_CELL_REPRESENTATION = "·";

public function main() {
    int generation = 1;

    // current generation (1) with seed
    CoordSet aliveCells = table [
        {x:2, y:1},
        {x:2, y:2},
        {x:2, y:3}
    ];

    while true {
        print(aliveCells, generation);

        final CoordSet nextAliveCells = table[];

        foreach int y in 0..<GRID_SIZE_Y {
            foreach int x in 0..<GRID_SIZE_X {
                final boolean currentCellState = aliveCells[x, y] is Coord;
                final Coord[] neighbours = neighboursOf({x, y});
                final int numberOfLiveNeighbours = 
                    neighbours.reduce(function (int accu, Coord c) returns int {
                        return aliveCells[c.x, c.y] is Coord ? accu + 1 : accu;
                    }, 0);
                 if willBeAlive(currentCellState, numberOfLiveNeighbours) {
                    nextAliveCells.add({x, y});
                 }
            }
        }

        aliveCells = nextAliveCells.clone();
        generation += 1;

        final string input = io:readln("Enter q to quit: ");
        if input == "q" {
            break;
        }
    }
}

# Calculate all valid neighbour cell coordinates of `cell`.
# 
# + c - The coordinates of a cell which neighbours are looked for
# + return - An array of all valid neighbour cell coordinates
isolated function neighboursOf(Coord c) returns Coord[] {
    return 
        from int x in [c.x-1, c.x, c.x+1]
            let int max_index_x = GRID_SIZE_X - 1
            where x >= 0 && x <= max_index_x
        from int y in [c.y-1, c.y, c.y+1]
            let int max_index_y = GRID_SIZE_Y - 1
            where y >= 0 && y <= max_index_y
        where !(x == c.x && y == c.y)
        select {x, y}
    ;
}

# Calculate the next cell state based on the number of live neighbours.
# 
# + cellState - The current state
# + liveNeighbours - The number of live neighbours
# + return - The next state
isolated function willBeAlive(boolean cellState, int liveNeighbours) returns boolean {
    match cellState {
        true => {
            match liveNeighbours {
                2|3 => { return true; }
                _   => { return false; }
            }
        }
        _ => {
            match liveNeighbours {
                3 => { return true; }
                _ => { return false; }
            }
        }
    }
}

# Visualize the grid by printing it to the screen.
# 
# + aliveCells - The cells that are alive
# + generation - The generation number used in the header
isolated function print(CoordSet aliveCells, int generation) {
    io:println("===");
    io:println(string`generation: ${generation}`);
    foreach int y in 0..<GRID_SIZE_Y {
        foreach int x in 0..<GRID_SIZE_X {
            io:print(aliveCells[x, y] is Coord ? LIVE_CELL_REPRESENTATION : DEAD_CELL_REPRESENTATION);
        }
        io:println();
    }
}