import ballerina/io;
import ballerina/random;

const int GRID_SIZE_Y = 9;
const int GRID_SIZE_X = 9;

type Coord record {|
    readonly int x;
    readonly int y;
|};

type CoordSet table<Coord> key (x, y);

const string LIVE_CELL_REPRESENTATION = "■";
const string DEAD_CELL_REPRESENTATION = "·";

public type CmdLineArgs record {
    boolean random = false;
    string? saveprefix = ();
    string? load = ();
};

public function main(*CmdLineArgs args) {
    int generation = 1;
    CoordSet aliveCells = seed(args);

    while true {
        print(aliveCells, generation, args.saveprefix);

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

# Calculate the alive cells for first generation based on the `args`.
# 
# + args - How the seed is generated
# + return - The cells alive
isolated function seed(CmdLineArgs args) returns CoordSet {
    CoordSet aliveCells = table [];

    if args.load is string {
        string[] lines = checkpanic io:fileReadLines(<string>args.load);
        int y = 0;
        foreach string line in lines {
            int x = 0;
            foreach string cell in line {
                if cell != DEAD_CELL_REPRESENTATION {
                    aliveCells.add({x, y});
                }
                x += 1;
            }
            y += 1;
        }
    } else if args.random {
        // TODO: bug: https://github.com/ballerina-platform/ballerina-lang/issues/36686
        // TODO: on conflict clause 
        CoordSet|error tmp = checkpanic table key(x, y)
            from int x in 0..<GRID_SIZE_X
            from int y in 0..<GRID_SIZE_Y
            let int 'limit = checkpanic random:createIntInRange(0, 100)
            where 'limit < 30
            select {x, y}
        ;
        return checkpanic tmp;
    } else {
        aliveCells = table [
            {x:4, y:2},
            {x:4, y:3},
            {x:4, y:4},
            {x:4, y:5},
            {x:4, y:6}
        ];
    }

    return aliveCells;
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
# Optionally saves the generation also to file with name:
# 
# <FILEPREFIX><GENERATION>.gen
# 
# + aliveCells - The cells that are alive
# + generation - The generation number used in the header
# + fileprefix - If non-nil the generation is also saved to a file with `fileprefix`
isolated function print(CoordSet aliveCells, int generation, string? fileprefix = ()) {
    final string? path = generateFilePath(generation, fileprefix);

    io:println("===");
    io:println(string`generation: ${generation}`);
    foreach int y in 0..<GRID_SIZE_Y {
        string line = "";
        foreach int x in 0..<GRID_SIZE_X {
            line += aliveCells[x, y] is Coord ? LIVE_CELL_REPRESENTATION : DEAD_CELL_REPRESENTATION;
        }
        line += "\n";
        io:print(line);
        if path is string {
            checkpanic io:fileWriteString(path, line, io:APPEND);
        }
    }
}

# Calculate generation save file path.
# 
# Return value nil indicates the file should not be created.
# 
# + generation - The generation number used in the file path
# + fileprefix - If non-nil a path for the save file will be generated
# + return - A path where the file should be saved or nil if no save file
isolated function generateFilePath(int generation, string? fileprefix) returns string? {
    if fileprefix is string {
        string path = fileprefix;
        path += string:padZero(generation.toString(), 4);
        path += ".gen";
        return path;
    }
    return ();
}