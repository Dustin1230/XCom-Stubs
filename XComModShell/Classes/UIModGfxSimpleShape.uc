/** This class provides a set of functions to use built-in Drawing API of Flash. 
 *  It also contains a few helper functions to draw ready-to-use rectangles, circles and rectangles with rounded corners.
 *  The helper functions let you define bordering and filling colors of the shapes.
 */
class UIModGfxSimpleShape extends GfxObject;

/** Moves drawing pen to (x, y) within current MC scope*/
function AS_MoveTo(float x, float y)
{
	ActionScriptVoid("moveTo");
}
/** Draws line from current drawing pen's position to (x, y) point within current MC scope*/
function AS_LineTo(float x, float y)
{
	ActionScriptVoid("lineTo");
}
/** Sets the stroke thickness, color, and transparency for all lines and curves subsequently drawn in MC via the lineTo( ) and curveTo( ) methods.*/
/** @param iThickness The integer line point size, ranging from 0 to 255, where 0 is hairline.
 *  @param iColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB, 
 *  where RR, GG, and BB are two-digit hex numbers representing Red, Green, and Blue. Defaults to black 0x000000.
 *  @param iAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 */  
function AS_LineStyle(int iThickness, optional int iColor=0x000000, optional int iAlpha=100)
{
	ActionScriptVoid("lineStyle");
}
/**Draws a quadratic Bezier curve from the current drawing pen position to the point (anchorX, anchorY) using an off-curve control point of (controlX, controlY). 
 * The tangents to the curve at the start and end points both pass through the control point.
 * @param controlX The horizontal coordinate of the off-curve control point of the quadratic Bezier curve, as a floating-point number. Measured relative to MC's registration point. 
 * @param controlY The vertical coordinate of the off-curve control point of the quadratic Bezier curve, as a floating-point number. Measured relative to MC's registration point.
 * @param anchorX The horizontal coordinate of the end position of the curve to be drawn, as a floating-point number. Measured relative to mc's registration point. 
 * @param anchorY The vertical coordinate of the end position of the curve to be drawn, as a floating-point number. Measured relative to mc's registration point. 
 */
function AS_CurveTo(float controlX, float controlY, float anchorX, float anchorY)
{
	ActionScriptVoid("curveTo");
}
/** Starts drawing a new shape within MC, filled with a solid color of RGB and a transparency of iAlpha. 
 *  The shape appears above any existing programmatically drawn content in MC but beneath all other content in MC.
 *  Must be preceeded by AS_MoveTo( ) command and followed by a sequence of AS_LineTo( ) calls which should draw a closed shape. 
 *  Finish the process by calling AS_EndFill( ).
 * @param iColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB, 
 *  where RR, GG, and BB are two-digit hex numbers representing Red, Green, and Blue (e.g. 0xFF0000 is pure red). 
 *  If RGB is omitted or undefined, no fill is drawn. 
 *  @param iAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 */
function AS_BeginFill(optional int iColor, optional int iAlpha=100)
{
	ActionScriptVoid("beginFill");
}
/** Terminates the filling of a shape that was begun with an earlier call to beginFill( ) or beginGradientFill( ), causing the shape to be drawn on-screen. 
 *  If the current drawing pen position is not the same as when beginFill( ) or beginGradientFill( ) was called, Flash closes the shape with a straight line and applies the fill. 
 *  However, creating open shapes can have unpredictable results and is not recommended. 
 */
function AS_EndFill()
{
	ActionScriptVoid("endFill");
}
/** Erases all lines (strokes) and shapes (fills) created with the MovieClip Drawing API methods in mc.
 *  Clears current line style and returns the drawing pen's position to (0, 0).
 */ 
function AS_Clear()
{
	ActionScriptVoid("clear");
}

/** Draws a rectangle of width and height as supplied with parameters.
 *  @param W Width in pixels.
 *  @param H Height in pixels.
 *  @param bFill Defaults to TRUE. Fills the rectangle with iFillColor (black by default).
 *  @param iFillColor The integer color of the filling supplied in RGB hexadecimal triplet notation 0xRRGGBB, 
 *  where RR, GG, and BB are two-digit hex numbers representing Red, Green, and Blue (e.g. 0xFF0000 is pure red). Defaults to black 0x000000
 *  @param iAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 *  @param bWithBorder Defaults to FALSE. If set to TRUE the rectangle will be stroked (have a bordering line around).
 *  @param iBorderColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB. Defaults to white 0xFFFFFF
 *  @param iBorderThickness Thickness of the bordering line in point size, ranging from 0 to 255, where 0 is hairline. Defaults to 1.
 *  @param iBorderAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 */
function DrawRectangle(float W, float H, optional bool bFill=TRUE, optional int iFillColor=0x000000, optional int iAlpha=100, optional bool bWithBorder, optional int iBorderColor=0xFFFFFF, optional int iBorderThickness=1, optional int iBorderAlpha=100)
{
	AS_MoveTo(0.0, 0.0);
	if(bFill)
	{
		AS_BeginFill(iFillColor, iAlpha);
	}
	if(bWithBorder)
	{
		AS_LineStyle(iBorderThickness, iBorderColor, iBorderAlpha);
	}
	AS_LineTo(W, 0.0);
	AS_LineTo(W, H);
	AS_LineTo(0.0, H);
	AS_LineTo(0.0, 0.0);
	if(bFill)
	{
		AS_EndFill();
	}
}
/** Draws a rectangle of width and height as supplied with parameters.
 *  @param W Width in pixels.
 *  @param H Height in pixels.
 *  @param RPct Float number in range 0.0-1.0 (default value 0.20) where 0.0 means no rounding while 1.0 results in tube-like effect: (__)
 *  @param bFill Defaults to TRUE. Fills the rectangle with iFillColor (black by default).
 *  @param iFillColor The integer color of the filling supplied in RGB hexadecimal triplet notation 0xRRGGBB, 
 *  where RR, GG, and BB are two-digit hex numbers representing Red, Green, and Blue (e.g. 0xFF0000 is pure red). Defaults to black 0x000000
 *  @param iAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 *  @param bWithBorder Defaults to FALSE. If set to TRUE the rectangle will be stroked (have a bordering line around).
 *  @param iBorderColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB. Defaults to white 0xFFFFFF
 *  @param iBorderThickness Thickness of the bordering line in point size, ranging from 0 to 255, where 0 is hairline. Defaults to 1.
 *  @param iBorderAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the shape 
 *  as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied. 
 */
function DrawRoundedRectangle(float W, float H, optional float RPct=0.20, optional bool bFill, optional int iFillColor=0x000000, optional int iAlpha=100, optional bool bWithBorder, optional int iBorderColor=0xFFFFFF, optional int iBorderThickness=1, optional int iBorderAlpha=100)
{
	local float R;

	R = Rpct * FMin(W, H) / 2;

	AS_MoveTo(R, 0.0);
	if(bFill)
	{
		AS_BeginFill(iFillColor, iAlpha);
	}
	if(bWithBorder)
	{
		AS_LineStyle(iBorderThickness, iBorderColor, iBorderAlpha);
	}
	AS_LineTo(W-R, 0.0);
	AS_CurveTo(W, 0.0, W, R);
	AS_LineTo(W, H-R);
	AS_CurveTo(W, H, W-R, H);
	AS_LineTo(R, H);
	AS_CurveTo(0.0, H, 0.0, H-R);
	AS_LineTo(0.0, R);
	AS_CurveTo(0.0, 0.0, R, 0.0);
	if(bFill)
	{
		AS_EndFill();
	}
}
/**Draws a circle of given radius and optional (x, y) center point. By default the center is set to MC's registration (0,0) point.
 * @param fRadius Radius of the circle, in pixels.
 * @param iThickness The integer line point size, ranging from 0 to 255, where 0 is hairline.
 * @param iColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB, where RR, GG, and BB are two-digit hex numbers representing Red, Green, and Blue. Defaults to black 0x000000.
 * @param iAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the circle (not the filling!) 
 * as a percentage: 0 is completely transparent, whereas 100 is completely opaque. Defaults to 100 if not supplied.  
 * @param bFill Defaults to FALSE. Set to TRUE to fill the circle with optionally defined color (black by default).
 * @param iFillColor The integer color of the line supplied in RGB hexadecimal triplet notation 0xRRGGBB. Defaults to white 0xFFFFFF
 * @param iFillAlpha An integer between 0 and 100 specifying the opacity (or, conversely, the transparency) of the filling of the circle 
 * @param fCenterX Horizontal coordinate of the center point - in relation to MC's registration point.
 * @param fCenterY Vertical coordinate of the center point - in relation to MC's registration point.
 */
function DrawCircle(float fRadius, optional float fCenterX, optional float fCenterY, optional int iThickness=1, optional int iColor, optional int iAlpha=100, optional bool bFill, optional int iFillColor, optional int iFillAlpha=100)
{
	local int i;
	local float ctrlDist, angleDelta, angleCurrent, rx, ry, ax, ay;

	// The angle of each of the eight segments is 45 degrees (360 divided by 8), which
	// equals pi/4 radians.
	angleDelta = Pi/4;
	
	// Find the distance from the circle's center to the control points for the curves.
	ctrlDist = fRadius/Cos(angleDelta/2);

	if(bFill)
	{
		AS_BeginFill(iFillColor, iFillAlpha);
	}
	// Move to the starting point, one radius to the right of the circle's center.
	AS_MoveTo(fCenterX + fRadius, fCenterY);
	
	//Apply line properties
	AS_LineStyle(iThickness, iColor, iAlpha);

	// Repeat eight times to create eight segments.
	for(i = 0; i < 8; i++) 
	{
	    // Increment the angle by angleDelta (pi/4).
		angleCurrent += angleDelta;

		// The control points are derived using sine and cosine.
		rx = fCenterX + Cos(angleCurrent - angleDelta/2)*ctrlDist;
		ry = fCenterY + Sin(angleCurrent - angleDelta/2)*ctrlDist;

		// The anchor points (end points of the curve) can be found similarly to the 
		// control points.
		ax = fCenterX + Cos(angleCurrent)*fRadius;
		ay = fCenterY + Sin(angleCurrent)*fRadius;

		// Draw the segment.
		AS_CurveTo(rx, ry, ax, ay);
	}
	if(bFill)
	{
		AS_EndFill();
	}
}
/** Draws a pentagram-star. Takes obligatory "arm length" parameter. 
	The top left corner-cone of the star is anchored at the registration point of MC (that is 0,0).*/
function DrawStar(float fArm, optional int iThickness=1, optional int iColor, optional int iFillColor=-1, optional int iAlpha=100)
{
	local float x;

	AS_LineStyle(iThickness, iColor, iAlpha);
	AS_MoveTo(0,0);
	if(iFillColor != -1)
	{
		AS_BeginFill(iFillColor);
	}
	//The maths below rely on certain relations of a pentagram - don't try to understand it, Google knowledge first :) 
	AS_LineTo(fArm, 0);
	AS_LineTo(fArm - fArm * Cos(Pi/5), fArm * Sin(Pi/5));
	AS_LineTo(fArm / 2, -fArm / 2 * Tan(Pi/5));
	AS_LineTo(fArm * Cos(Pi/5), fArm * Sin(Pi/5));
	AS_LineTo(0,0);
	if(iFillColor != -1)
	{
		AS_EndFill();
		//fill the inside (the maths could be simplified probably, but well...)
		x = fArm/2/Cos(Pi/5);
		AS_MoveTo(x, 0);
		AS_BeginFill(iFillColor);
		AS_LineTo(fArm - (fArm-x)*Cos(Pi/5), -fArm / 2 * Tan(Pi/5) + x * Cos(Pi/10));
		AS_LineTo(fArm / 2, fArm / 2 * Tan(Pi/5));
		AS_LineTo((fArm-x)*Cos(Pi/5), -fArm / 2 * Tan(Pi/5) + x * Cos(Pi/10));
		AS_LineTo(fArm-x, 0);
		AS_LineTo(x, 0);
		AS_EndFill();
	}
}
DefaultProperties
{
}