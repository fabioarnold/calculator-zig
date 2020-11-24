const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL2/SDL_opengl.h");
    @cInclude("nanovg.h");
    @cDefine("NANOVG_GL2", "1");
    @cInclude("nanovg_gl.h");
});

pub const Color = c.NVGcolor;

pub const TextAlign = enum(i32) {
    // Horizontal align
    left = 1 << 0,
    center = 1 << 1,
    right = 1 << 2,
    // Vertical align
    top = 1 << 3,
    middle = 1 << 4,
    bottom = 1 << 5,
    baseline = 1 << 6, // Default, align text vertically to baseline.
    _,
};

var ctx: ?*c.NVGcontext = undefined;

pub fn init() void {
    ctx = c.nvgCreateGL2(0);
}

pub fn quit() void {
    c.nvgDeleteGL2(ctx);
}

// Begin drawing a new frame
// Calls to nanovg drawing API should be wrapped in nvgBeginFrame() & nvgEndFrame()
// nvgBeginFrame() defines the size of the window to render to in relation currently
// set viewport (i.e. glViewport on GL backends). Device pixel ration allows to
// control the rendering on Hi-DPI devices.
// For example, GLFW returns two dimension for an opened window: window size and
// frame buffer size. In that case you would set windowWidth/Height to the window size
// devicePixelRatio to: frameBufferWidth / windowWidth.
pub fn beginFrame(window_width: f32, window_height: f32, device_pixel_ratio: f32) void {
    c.nvgBeginFrame(ctx, window_width, window_height, device_pixel_ratio);
}

// Cancels drawing the current frame.
pub fn cancelFrame() void {
    c.nvgCancelFrame(ctx);
}

// Ends drawing flushing remaining render state.
pub fn endFrame() void {
    c.nvgEndFrame(ctx);
}

//
// Color utils
//
// Colors in NanoVG are stored as unsigned ints in ABGR format.

// Returns a color value from red, green, blue values. Alpha will be set to 255 (1.0f).
pub fn RGB(r: u8, g: u8, b: u8) Color {
    return c.nvgRGB(r, g, b);
}

// // Returns a color value from red, green, blue values. Alpha will be set to 1.0f.
// NVGcolor nvgRGBf(float r, float g, float b);

// // Returns a color value from red, green, blue and alpha values.
// NVGcolor nvgRGBA(unsigned char r, unsigned char g, unsigned char b, unsigned char a);

// // Returns a color value from red, green, blue and alpha values.
// NVGcolor nvgRGBAf(float r, float g, float b, float a);

// // Linearly interpolates from color c0 to c1, and returns resulting color value.
// NVGcolor nvgLerpRGBA(NVGcolor c0, NVGcolor c1, float u);

// // Sets transparency of a color value.
// NVGcolor nvgTransRGBA(NVGcolor c0, unsigned char a);

// // Sets transparency of a color value.
// NVGcolor nvgTransRGBAf(NVGcolor c0, float a);

// // Returns color value specified by hue, saturation and lightness.
// // HSL values are all in range [0..1], alpha will be set to 255.
// NVGcolor nvgHSL(float h, float s, float l);

// // Returns color value specified by hue, saturation and lightness and alpha.
// // HSL values are all in range [0..1], alpha in range [0..255]
// NVGcolor nvgHSLA(float h, float s, float l, unsigned char a);

//
// Render styles
//
// Fill and stroke render style can be either a solid color or a paint which is a gradient or a pattern.
// Solid color is simply defined as a color value, different kinds of paints can be created
// using nvgLinearGradient(), nvgBoxGradient(), nvgRadialGradient() and nvgImagePattern().
//
// Current render style can be saved and restored using nvgSave() and nvgRestore().

// // Sets whether to draw antialias for nvgStroke() and nvgFill(). It's enabled by default.
// void nvgShapeAntiAlias(NVGcontext* ctx, int enabled);

// // Sets current stroke style to a solid color.
pub fn strokeColor(color: Color) void {
    c.nvgStrokeColor(ctx, color);
}

// // Sets current stroke style to a paint, which can be a one of the gradients or a pattern.
// void nvgStrokePaint(NVGcontext* ctx, NVGpaint paint);

// // Sets current fill style to a solid color.
pub fn fillColor(color: Color) void {
    c.nvgFillColor(ctx, color);
}

// // Sets current fill style to a paint, which can be a one of the gradients or a pattern.
// void nvgFillPaint(NVGcontext* ctx, NVGpaint paint);

// // Sets the miter limit of the stroke style.
// // Miter limit controls when a sharp corner is beveled.
// void nvgMiterLimit(NVGcontext* ctx, float limit);

// // Sets the stroke width of the stroke style.
pub fn strokeWidth(size: f32) void {
    c.nvgStrokeWidth(ctx, size);
}

// // Sets how the end of the line (cap) is drawn,
// // Can be one of: NVG_BUTT (default), NVG_ROUND, NVG_SQUARE.
// void nvgLineCap(NVGcontext* ctx, int cap);

// // Sets how sharp path corners are drawn.
// // Can be one of NVG_MITER (default), NVG_ROUND, NVG_BEVEL.
// void nvgLineJoin(NVGcontext* ctx, int join);

// // Sets the transparency applied to all rendered shapes.
// // Already transparent paths will get proportionally more transparent as well.
// void nvgGlobalAlpha(NVGcontext* ctx, float alpha);

//
// Transforms
//
// The paths, gradients, patterns and scissor region are transformed by an transformation
// matrix at the time when they are passed to the API.
// The current transformation matrix is a affine matrix:
//   [sx kx tx]
//   [ky sy ty]
//   [ 0  0  1]
// Where: sx,sy define scaling, kx,ky skewing, and tx,ty translation.
// The last row is assumed to be 0,0,1 and is not stored.
//
// Apart from nvgResetTransform(), each transformation function first creates
// specific transformation matrix and pre-multiplies the current transformation by it.
//
// Current coordinate system (transformation) can be saved and restored using nvgSave() and nvgRestore().

// Resets current transform to a identity matrix.
pub fn resetTransform() void {
    c.nvgResetTransform(ctx);
}

// Premultiplies current coordinate system by specified matrix.
// The parameters are interpreted as matrix as follows:
//   [a c e]
//   [b d f]
//   [0 0 1]
// void nvgTransform(NVGcontext* ctx, float a, float b, float c, float d, float e, float f);

// Translates current coordinate system.
// void nvgTranslate(NVGcontext* ctx, float x, float y);

// Rotates current coordinate system. Angle is specified in radians.
// void nvgRotate(NVGcontext* ctx, float angle);

// Skews the current coordinate system along X axis. Angle is specified in radians.
// void nvgSkewX(NVGcontext* ctx, float angle);

// Skews the current coordinate system along Y axis. Angle is specified in radians.
// void nvgSkewY(NVGcontext* ctx, float angle);

// Scales the current coordinate system.
pub fn scale(x: f32, y: f32) void {
    c.nvgScale(ctx, x, y);
}

// Stores the top part (a-f) of the current transformation matrix in to the specified buffer.
//   [a c e]
//   [b d f]
//   [0 0 1]
// There should be space for 6 floats in the return buffer for the values a-f.
// void nvgCurrentTransform(NVGcontext* ctx, float* xform);


// The following functions can be used to make calculations on 2x3 transformation matrices.
// A 2x3 matrix is represented as float[6].

// Sets the transform to identity matrix.
// void nvgTransformIdentity(float* dst);

// Sets the transform to translation matrix matrix.
// void nvgTransformTranslate(float* dst, float tx, float ty);

// Sets the transform to scale matrix.
// void nvgTransformScale(float* dst, float sx, float sy);

// Sets the transform to rotate matrix. Angle is specified in radians.
// void nvgTransformRotate(float* dst, float a);

// Sets the transform to skew-x matrix. Angle is specified in radians.
// void nvgTransformSkewX(float* dst, float a);

// Sets the transform to skew-y matrix. Angle is specified in radians.
// void nvgTransformSkewY(float* dst, float a);

// Sets the transform to the result of multiplication of two transforms, of A = A*B.
// void nvgTransformMultiply(float* dst, const float* src);

// Sets the transform to the result of multiplication of two transforms, of A = B*A.
// void nvgTransformPremultiply(float* dst, const float* src);

// Sets the destination to inverse of specified transform.
// Returns 1 if the inverse could be calculated, else 0.
// int nvgTransformInverse(float* dst, const float* src);

// Transform a point by given transform.
// void nvgTransformPoint(float* dstx, float* dsty, const float* xform, float srcx, float srcy);

// Converts degrees to radians and vice versa.
// float nvgDegToRad(float deg);
// float nvgRadToDeg(float rad);

//
// Paths
//
// Drawing a new shape starts with nvgBeginPath(), it clears all the currently defined paths.
// Then you define one or more paths and sub-paths which describe the shape. The are functions
// to draw common shapes like rectangles and circles, and lower level step-by-step functions,
// which allow to define a path curve by curve.
//
// NanoVG uses even-odd fill rule to draw the shapes. Solid shapes should have counter clockwise
// winding and holes should have counter clockwise order. To specify winding of a path you can
// call nvgPathWinding(). This is useful especially for the common shapes, which are drawn CCW.
//
// Finally you can fill the path using current fill style by calling nvgFill(), and stroke it
// with current stroke style by calling nvgStroke().
//
// The curve segments and sub-paths are transformed by the current transform.

// Clears the current path and sub-paths.
pub fn beginPath() void {
    c.nvgBeginPath(ctx);
}

// Starts new sub-path with specified point as first point.
pub fn moveTo(x: f32, y: f32) void {
    c.nvgMoveTo(ctx, x, y);
}

// Adds line segment from the last point in the path to the specified point.
pub fn lineTo(x: f32, y: f32) void {
    c.nvgLineTo(ctx, x, y);
}

// // Adds cubic bezier segment from last point in the path via two control points to the specified point.
// void nvgBezierTo(NVGcontext* ctx, float c1x, float c1y, float c2x, float c2y, float x, float y);

// // Adds quadratic bezier segment from last point in the path via a control point to the specified point.
// void nvgQuadTo(NVGcontext* ctx, float cx, float cy, float x, float y);

// // Adds an arc segment at the corner defined by the last path point, and two specified points.
// void nvgArcTo(NVGcontext* ctx, float x1, float y1, float x2, float y2, float radius);

// Closes current sub-path with a line segment.
pub fn closePath() void {
    c.nvgClosePath(ctx);
}

// // Sets the current sub-path winding, see NVGwinding and NVGsolidity.
// void nvgPathWinding(NVGcontext* ctx, int dir);

// // Creates new circle arc shaped sub-path. The arc center is at cx,cy, the arc radius is r,
// // and the arc is drawn from angle a0 to a1, and swept in direction dir (NVG_CCW, or NVG_CW).
// // Angles are specified in radians.
// void nvgArc(NVGcontext* ctx, float cx, float cy, float r, float a0, float a1, int dir);

// Creates new rectangle shaped sub-path.
pub fn rect(x: f32, y: f32, w: f32, h: f32) void {
    c.nvgRect(ctx, x, y, w, h);
}

// Creates new rounded rectangle shaped sub-path.
pub fn roundedRect(x: f32, y: f32, w: f32, h: f32, r: f32) void {
    c.nvgRoundedRect(ctx, x, y, w, h, r);
}

// // Creates new rounded rectangle shaped sub-path with varying radii for each corner.
// void nvgRoundedRectVarying(NVGcontext* ctx, float x, float y, float w, float h, float radTopLeft, float radTopRight, float radBottomRight, float radBottomLeft);

// // Creates new ellipse shaped sub-path.
// void nvgEllipse(NVGcontext* ctx, float cx, float cy, float rx, float ry);

// // Creates new circle shaped sub-path.
// void nvgCircle(NVGcontext* ctx, float cx, float cy, float r);

// Fills the current path with current fill style.
pub fn fill() void {
    c.nvgFill(ctx);
}

// Fills the current path with current stroke style.
pub fn stroke() void {
    c.nvgStroke(ctx);
}

//
// Text
//
// NanoVG allows you to load .ttf files and use the font to render text.
//
// The appearance of the text can be defined by setting the current text style
// and by specifying the fill color. Common text and font settings such as
// font size, letter spacing and text align are supported. Font blur allows you
// to create simple text effects such as drop shadows.
//
// At render time the font face can be set based on the font handles or name.
//
// Font measure functions return values in local space, the calculations are
// carried in the same resolution as the final rendering. This is done because
// the text glyph positions are snapped to the nearest pixels sharp rendering.
//
// The local space means that values are not rotated or scale as per the current
// transformation. For example if you set font size to 12, which would mean that
// line height is 16, then regardless of the current scaling and rotation, the
// returned line height is always 16. Some measures may vary because of the scaling
// since aforementioned pixel snapping.
//
// While this may sound a little odd, the setup allows you to always render the
// same way regardless of scaling. I.e. following works regardless of scaling:
//
//		const char* txt = "Text me up.";
//		nvgTextBounds(vg, x,y, txt, NULL, bounds);
//		nvgBeginPath(vg);
//		nvgRoundedRect(vg, bounds[0],bounds[1], bounds[2]-bounds[0], bounds[3]-bounds[1]);
//		nvgFill(vg);
//
// Note: currently only solid color fill is supported for text.

// Creates font by loading it from the disk from specified file name.
// Returns handle to the font.
pub fn createFont(name: [:0]const u8, filename: [:0]const u8) i32 {
    return c.nvgCreateFont(ctx, name, filename);
}

// Sets the font size of current text style.
pub fn fontSize(size: f32) void {
    c.nvgFontSize(ctx, size);
}

// Sets the text align of current text style, see NVGalign for options.
pub fn textAlign(text_align: TextAlign) void {
    c.nvgTextAlign(ctx, @enumToInt(text_align));
}

// Sets the font face based on specified name of current text style.
pub fn fontFace(font: [:0]const u8) void {
    c.nvgFontFace(ctx, font);
}

// Draws text string at specified location. If end is specified only the sub-string up to the end is drawn.
pub fn text(x: f32, y: f32, string: [:0]const u8) f32 {
    return c.nvgText(ctx, x, y, string, 0);
}
