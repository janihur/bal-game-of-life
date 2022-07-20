# bal-game-of-life

Several iterations of [Conway's Game Of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) with [Ballerina](https://ballerina.io/) programming language.

All versions apply the following [rules](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life#Rules):

1. Any live cell with two or three live neighbours survives.
1. Any dead cell with three live neighbours becomes a live cell.
1. All other live cells die in the next generation. Similarly, all other dead cells stay dead.

The coordinate system is programmer-friendly with origo (`{x:0, y:0}`) in top-left corner and increasing into right and down:
```
―――――――――――――――――――――――
| 0,0 | 0,1 | 0,2 | ...
―――――――――――――――――――
| 1,0 | 1,1 | ...
―――――――――――――
| 2,0 | ...
―――――――
| ...
```

Error handling is kept simple with [panics](https://ballerina.io/learn/language-basics/#panics) in all error scenarios (`checkpanic` keyword).

Versions A (`version-a?.bal`) are bare implementations and versions B (`version-b?.bal`) have features creeped in.

These are my first implementations of this game ever.

Used Ballerina version:
```
$ bal version
Ballerina 2201.1.0 (Swan Lake Update 1)
Language specification 2022R2
Update Tool 1.3.9
```

## Version A1

1. The seed is hardcoded (initialization of the module global `grid` variable).
1. Uses two fixed size grids (two dimensional boolean arrays).
1. The `grid` is a global state.
1. First finds out all neighbour cells and then checks in a separate step which of those are alive.

All neighbour cell coordinates are hardcoded with the following algorithm:
1. Top row: left hand cell (#1)
1. Top row: right hand cell (#2)
1. Top row: all middle cells (#3)
1. Bottom row: left hand cell (#4)
1. Bottom row: right hand cell (#5)
1. Bottom row: all middle cells (#6)
1. All middle rows: left hand cell (#7)
1. All middle rows: right hand cell (#8)
1. All middle rows: all middle cells (#9)

```
―――――――――――――――――
| 1 | 3 | 3 | 2 |
―――――――――――――――――
| 7 | 9 | 9 | 8 |
―――――――――――――――――
| 7 | 9 | 9 | 8 |
―――――――――――――――――
| 4 | 6 | 6 | 5 |
―――――――――――――――――
```

Run:
```
bal run version-a1.bal
```

## Version A2

Changes compared to version A1:

* Removed `emptyGrid` initialization variable as `[[DEAD]]` is effectively the same. One could also use `[[]]` because the implicit default value for `boolean` is `false` but I prefer `[[DEAD]]` because it is more explict.
* Simplified main loop.
* Count the number of alive neighbours in one step.

Run:
```
bal run version-a2.bal
```

## Version A3

Changes compared to version A2:

* Instead of hard coding neighbour cell coordinates are (mostly) calculated.
* Global `grid` variable removed. After that there is no more global state thus all functions except `main()` (because `io:readln()` is not isolated) could be [`isolated`](https://ballerina.io/learn/distinctive-language-features/concurrency/#isolated-functions).
* Implementation of function `numberOfLiveCells()` couldn't use `reduce()` because there is a pending [specification issue](https://github.com/ballerina-platform/ballerina-spec/issues/602) with anonymous functions and isolation.
* Added function comments. Ballerina has a built-in [documentation framework](https://ballerina.io/learn/generate-code-documentation/). It doesn't work with a single file programs but the Ballerina Flavored Markup could still be used.

Run:
```
bal run version-a3.bal
```

## Version A4

Changes compared to version A3:

* Using a [set](https://en.wikipedia.org/wiki/Set_%28abstract_data_type%29) of alive cells instead of two dimensional array of all cells. However Ballerina doesn't have set data structure and [map](https://en.wikipedia.org/wiki/Associative_array) only supports string keys. Hence the set (`aliveCells` variable) has been implemented with Ballerina's very powerful [table](https://ballerina.io/learn/distinctive-language-features/data/#table-concept) data structure.
* Implemented `numberOfLiveCells()` as `reduce()` in `main()`. Now the function name no more documents the purpose of the function but the name of the result variable `numberOfLiveNeighbours` does. As a bonus this also works around the [specification issue](https://github.com/ballerina-platform/ballerina-spec/issues/602) with anonymous functions and isolation.
* Generates the neighbour cell coordinates with a [query expression](https://ballerina.io/learn/distinctive-language-features/data/#query-expressions) that is Ballerina's realization of a [list comprehension](https://en.wikipedia.org/wiki/List_comprehension).

Run:
```
bal run version-a4.bal
```

## Version B1

Changes compared to version A4:

* Default grid size increased to 9x9 and default seed changed.
* Added an option to start with a random seed. Every first generation cell has 30% chance to be alive.
* Added an option to load the first generation from a file. Note that the grid size have to be 9x9. You can load files created with `--saveprefix` option.
* Added an option to save generations to files.
* Added `player.sh` to show the generation files.

Run:
```
# start with hard-coded seed
bal run version-b1.bal
# start with a random seed
bal run version-b1.bal -- --random
# save all generations also to files with a prefix
bal run version-b1.bal -- --random --saveprefix=$(date +%Y%m%d-%H%M%S)-
# load the first generation from a file
bal run version-b1.bal -- --load=<FILENAME>
```
Show saved generation files:
```
./player.sh <FILES>
```

## TODO

Feature creep:

* variable grid size
* stop automatically when all cells are dead or are stable (i.e. compare last two generations)
* identify longer cycles too