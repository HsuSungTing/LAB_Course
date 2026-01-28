module point_in_box (
    input  [31:0] Ax, Ay,  // Coordinates of point A
    input  [31:0] Bx, By,  // Coordinates of point B
    input  [31:0] Px, Py,  // Coordinates of point P
    output        inside   // Output: whether P is inside the rectangle defined by A and B
);

    wire x_between, y_between;

    // Check if P.x is in [min(Ax,Bx), max(Ax,Bx)]
    assign x_between = (Px >= (Ax < Bx ? Ax : Bx)) &&
                       (Px <= (Ax > Bx ? Ax : Bx));

    // Check if P.y is in [min(Ay,By), max(Ay,By)]
    assign y_between = (Py >= (Ay < By ? Ay : By)) &&
                       (Py <= (Ay > By ? Ay : By));

    // If both X and Y conditions are satisfied, inside = 1
    assign inside = x_between & y_between;

endmodule