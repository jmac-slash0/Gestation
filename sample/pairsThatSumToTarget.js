/*
* jsfiddle project; take in a target number and array of ints, then find the first pair of ints that add
* up to the target number, or find all unique ([1, 2] and [2, 1] are current considered unique) pairs of
* ints that add up to the target number.
*
* performance testing: http://jsperf.com/find-first-2-numbers-that-add-up-to-target/edit
*
* To do: find duplicate pairings for better performance comparisons (map pairings to object that counts 
* the number of times that pairing has been found)
*
* requires jquery for output
*/

// framework - paste <p class="x-console"></p> into html window for output to work
console.log = function (msg) {
    $('p.x-console').append(msg + '<br/>');
}


// Setup //
// Input
var target = 10;
var intArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; // Contains 8 unique pairs that add up to 10
var findAll = true; // find all pairs if true, otherwise stop on first pair found
var useRandom = true; // Use randomly populated array of ints if true, otherwise use initial handmade array

// Problem Area Settings
var searchArea = 100;
var min = 1;
var max = 101;

// Algorithm Variables
var found = false;
var lookedAt = [];
var foundArray = [];


// Generate problem area
if (useRandom) {
    for (var i = 0; i < searchArea; i++) {
        // Generate random number
        intArray[i] = Math.floor(Math.random() * (max - min + 1)) + min;
    }
}


// Algorithm //
for (var i = 0; i < intArray.length && !found; i++) {
    // Make sure current number is not impossible to add up to target
    if (!(intArray[i] >= target)) {
        // See if we've looked at this number before
        if (!lookedAt[intArray[i]][0]) {

            for (var j = 0; j < intArray.length && !found; j++) {

                // Make sure we don't add the same number to itself
                if (i != j) {
                    // Check if meets target
                    if (intArray[i] + intArray[j] == target) {
                        if (findAll) {
                            // Add found pairing to list of good numbers
                            foundArray[foundArray.length] = {[intArray[i], intArray[j]];
                        }
                        else {
                            found = true;
                            console.log('Found ' + intArray[i] + '\ + ' + intArray[j]
                                + ' = ' + target + ' at [' + i + ', ' + j + ']');
                        }
                    }
                }
            }

            // Flag this number as looked at
            lookedAt[intArray[i]] = { flag: true, count: 1 };
        }
        else {
            // Increment pair findings, if any
            if (lookedAt[intArray[i]][0]) {
                lookedAt[intArray[i]][1]++;
            }
        }
    }
}

// Summary of results if looking for all unique pairs
if (findAll) {
    console.log('Found ' + foundArray.length + ' unique pairs that add up to ' + target + '.');

    // Show all unique pairs or first 20
    for (var i = 0; i < foundArray.length && i < 20; i++) {
        console.log('[' + foundArray[i][0] + ', ' + foundArray[i][1] + '] ('
            + lookedAt[foundArray[i][0]][1] + ')');
    }
}
