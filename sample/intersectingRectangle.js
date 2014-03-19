/*
* jsfiddle project to take two rectangles with the coordinates of their top left and lower right corners and find
* the intersecting rectangle's coordinates
*/


// framework - paste <p class="x-console"></p> into html window for output to work                                     
console.log = function (msg) {
    $('p.x-console').append(msg + '<br/>');
}

// see if the two lines overlap at all
function findOverlaps(lines) {
    
    var overlap = { upperLeft: { value: -1 }, lowerRight: { value: -1 } };
    
    // line1 starts to the left of or below line2
    if (lines.line1.upperLeft <= lines.line2.upperLeft) {
        
        // if the end of line1 doesn't even reach line2
        if (lines.line1.lowerRight <= lines.line2.upperLeft) {
            // lines don't intersect
            // could make this more concise but this way makes my brain happy
            console.log('these lines aren\'t intersecting');
        } else {
            // we have some kind of intersection
            overlap.upperLeft.value = lines.line2.upperLeft;
            
            // whichever point is smaller is the end of our intersection
            if (lines.line1.lowerRight <= lines.line2.lowerRight)
                overlap.lowerRight.value = lines.line1.lowerRight;
            else
                overlap.lowerRight.value = lines.line2.lowerRight;
        }
    }
    // line1 starts to the right of or above line2
    else if (lines.line1.upperLeft >= lines.line2.upperLeft) {
        
        // ff the end of line2 doesn't even reach line1
        if (lines.line1.upperLeft >= lines.line2.lowerRight) {
            // lines don't intersect
            console.log('these lines aren\'t intersecting');
        } else {
            // we have some kind of intersection
            overlap.upperLeft.value = lines.line1.upperLeft;
            
            // whichever point is smaller is the end of our intersection
            if (lines.line1.lowerRight <= lines.line2.lowerRight)
                overlap.lowerRight.value = lines.line1.lowerRight;
            else
                overlap.lowerRight.value = lines.line2.lowerRight;
        }
    }
    
    return overlap;
}


// get the intersecting rectangle of 2 given rectangles
function getIntersection(rect1, rect2) {
    var intersection = { upperLeft: { x:-1, y:-1 }, lowerRight: { x:-1, y:-1 } };
    
    // break rectangles into lines, and look for overlaps, starting with x axis
    var inputLines = {
        line1: {
            upperLeft: rect1.upperLeft.x,
            lowerRight: rect1.lowerRight.x
        },
        line2: {
            upperLeft: rect2.upperLeft.x,
            lowerRight: rect2.lowerRight.x
        }
    }
    
   // see what overlaps the lines have
    var output = findOverlaps(inputLines);

    // save overlapping line x values
    intersection.upperLeft.x = output.upperLeft.value;
    intersection.lowerRight.x = output.lowerRight.value;

    // setup input for y axis
    inputLines.line1.upperLeft = rect1.upperLeft.y;
    inputLines.line1.lowerRight = rect1.lowerRight.y;
    inputLines.line2.upperLeft = rect2.upperLeft.y;
    inputLines.line2.lowerRight = rect2.lowerRight.y;
    
    // look for overlaps in y axis
    output = findOverlaps(inputLines);
    
    // Save y values
    intersection.upperLeft.y = output.upperLeft.value;
    intersection.lowerRight.y = output.lowerRight.value;
    
    
    return intersection;
}




// rectangle inputs
var rect1 = { upperLeft: { x:0, y:0 }, lowerRight: { x:2, y:2 } };
var rect2 = { upperLeft: { x:2, y:2 }, lowerRight: { x:4, y:4 } };

// intersection function, values will be -1 if no intersection is found
var rect3 = getIntersection(rect1, rect2);

console.log('Upper Left: ' + rect3.upperLeft.x + ", " + rect3.upperLeft.y);
console.log('Lower Right: ' + rect3.lowerRight.x + ", " + rect3.lowerRight.y);



