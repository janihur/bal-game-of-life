import ballerina/io;
import ballerina/random;

type GridSize record {|
    readonly int x;
    readonly int y;
|};

type Coord record {|
    readonly int x;
    readonly int y;
|};

type CoordSet table<Coord> key (x, y);

type Generations CoordSet[];

const string LIVE_CELL_REPRESENTATION = "■";
const string DEAD_CELL_REPRESENTATION = "·";

public type CmdLineArgs record {
    boolean random = false;
    string? saveprefix = ();
    string? load = ();
    int? size = ();
};

public function main(*CmdLineArgs args) {
    final var [gridSize, seed] = seed(args);
    
    int index = 0; // index of the current generation ...
    final Generations history = [seed]; // ... in the generation history (array)
    
    print(gridSize, history[index], index + 1, args.saveprefix);
    
    while true {
        final CoordSet currAliveCells = history[index];
        final CoordSet nextAliveCells = table[];

        foreach int y in 0..<gridSize.y {
            foreach int x in 0..<gridSize.x {
                final boolean currentCellState = currAliveCells[x, y] is Coord;
                final Coord[] neighbours = neighboursOf({x, y}, gridSize);
                final int numberOfLiveNeighbours = 
                    neighbours.reduce(function (int accu, Coord c) returns int {
                        return currAliveCells[c.x, c.y] is Coord ? accu + 1 : accu;
                    }, 0);
                 if willBeAlive(currentCellState, numberOfLiveNeighbours) {
                    nextAliveCells.add({x, y});
                 }
            }
        }
        index += 1;
        print(gridSize, nextAliveCells, index + 1, args.saveprefix);

        if nextAliveCells.length() == 0 {
            io:println("All cells died in ", index, " generations :(");
            break;
        }

        if nextAliveCells == currAliveCells {
            io:println("The cells stabilized in ", index, " generations");
            break;
        }

        do {
            boolean quit = false;
            // a trick to use range expression decrementally i.e. [3,2,1,0]
            foreach int i in -(history.length()-1) ... -1 {
                if nextAliveCells == history[-i] {
                    final int currentAppearance = index + 1;
                    final int previousAppearance = (-i)+1;
                    final int generationCycleSize = currentAppearance - previousAppearance;
                    io:println("The generation already appeared at ", previousAppearance);
                    io:println("The same generations appear in every ", generationCycleSize, " generations");
                    quit = true;
                    break;
                }
            }
            if quit {
                break;
            }
        }

        final string input = io:readln("Enter q to quit: ");
        if input == "q" {
            break;
        }

        history.push(nextAliveCells.cloneReadOnly());
    }
}

# Calculate the alive cells for first generation based on the `args`.
# 
# + args - How the seed is generated
# + return - A tuple of grid size and the cells alive
isolated function seed(CmdLineArgs args) returns [GridSize, CoordSet] {
    GridSize gridSize = 
        let int size = args.size ?: 9 
        in {x: size, y: size }
    ;
    CoordSet aliveCells = table [];

    if args.load is string {
        string[] lines = checkpanic io:fileReadLines(<string>args.load);
        int x = 0;
        int y = 0;
        foreach string line in lines {
            x = 0;
            foreach string cell in line {
                if cell != DEAD_CELL_REPRESENTATION {
                    aliveCells.add({x, y});
                }
                x += 1;
            }
            y += 1;
        }
        gridSize = {x, y};
    } else if args.random {
        // TODO: bug: https://github.com/ballerina-platform/ballerina-lang/issues/36686
        // TODO: on conflict clause 
        CoordSet|error tmp = checkpanic table key(x, y)
            from int x in 0..<gridSize.x
            from int y in 0..<gridSize.y
            let int 'limit = checkpanic random:createIntInRange(0, 100)
            where 'limit < 30
            select {x, y}
        ;
        return [gridSize, checkpanic tmp];
    } else {
        gridSize = {x:9, y:9};
        aliveCells = table [
            {x:4, y:2},
            {x:4, y:3},
            {x:4, y:4},
            {x:4, y:5},
            {x:4, y:6}
        ];
    }

    return [gridSize, aliveCells];
}

# Calculate all valid neighbour cell coordinates of `cell`.
# 
# + c - The coordinates of a cell which neighbours are looked for
# + gridSize - The grid size
# + return - An array of all valid neighbour cell coordinates
isolated function neighboursOf(Coord c, GridSize gridSize) returns Coord[] {
    return 
        from int x in [c.x-1, c.x, c.x+1]
            let int max_index_x = gridSize.x - 1
            where x >= 0 && x <= max_index_x
        from int y in [c.y-1, c.y, c.y+1]
            let int max_index_y = gridSize.y - 1
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
# + gridSize - The grid size
# + aliveCells - The cells that are alive
# + generation - The generation number used in the header
# + fileprefix - If non-nil the generation is also saved to a file with `fileprefix`
isolated function print(GridSize gridSize, CoordSet aliveCells, int generation, string? fileprefix = ()) {
    final string? path = generateFilePath(generation, fileprefix);

    final int nbrOfAllCells = gridSize.x * gridSize.y;
    final int nbrOfAliveCells = aliveCells.length();
    final float ratio = (<float>nbrOfAliveCells / <float>nbrOfAllCells) * 100;

    io:println("===");
    io:println(string`generation: ${generation}`);
    io:println(string`alive cells: ${nbrOfAliveCells}/${nbrOfAllCells} (${float:toFixedString(ratio, 1)}%)`);
    foreach int y in 0..<gridSize.y {
        string line = "";
        foreach int x in 0..<gridSize.x {
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