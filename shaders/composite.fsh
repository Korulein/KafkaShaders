#version 330 compatibility

// =====================================================================
// composite.fsh
// AUTHOR: Claude-written (Claude, 29 Oct 2026) - pending Korulein's
//         review and explanation in the research log before merge.
// SPEC:   Written retroactively by Korulein after the 29 Oct demo.
// WHAT:   Depth-based block outlines + Korulein's original greyscale.
// REF:    LearnOpenGL "Depth testing" (linearising depth).
// =====================================================================

// ---- Options (Iris shows these in the shader options menu) ----------
#define OUTLINES                // Draw block outlines
#define OUTLINE_THICKNESS 1.0   // Line thickness in pixels [0.5 1.0 1.5 2.0 3.0]
#define OUTLINE_THRESHOLD 0.05  // Edge sensitivity: smaller = more lines [0.02 0.05 0.10 0.20]
#define OUTLINE_STRENGTH 1.0    // How dark the lines are [0.25 0.5 0.75 1.0]
#define GREYSCALE               // Korulein's original greyscale effect

uniform sampler2D colortex0;   // the image drawn so far
uniform sampler2D depthtex0;   // depth of everything, translucents included
uniform mat4 gbufferProjectionInverse;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

// Raw depth (0..1, non-linear) -> distance from the camera in blocks.
// Undoes the projection with its inverse matrix instead of the
// near/far formula, so it doesn't depend on which "far" value is right.
float linearDepth(vec2 uv) {
	float depth = texture(depthtex0, uv).r;
	vec4 ndc  = vec4(uv, depth, 1.0) * 2.0 - 1.0; // 0..1 -> -1..1
	vec4 view = gbufferProjectionInverse * ndc;
	return -view.z / view.w;  // view space looks down -z, so flip sign
}

void main() {
	color = texture(colortex0, texcoord);

#ifdef GREYSCALE
	float grey = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	color.rgb = vec3(grey);
#endif

#ifdef OUTLINES
	vec2 px = OUTLINE_THICKNESS / vec2(viewWidth, viewHeight);
	float centre = linearDepth(texcoord);

	// Neighbours up, down, left, right.
	float n0 = linearDepth(texcoord + vec2( px.x, 0.0));
	float n1 = linearDepth(texcoord + vec2(-px.x, 0.0));
	float n2 = linearDepth(texcoord + vec2(0.0,  px.y));
	float n3 = linearDepth(texcoord + vec2(0.0, -px.y));

	// Only count neighbours FURTHER away than this pixel, so the line
	// sits on the closer object's edge and the sky never gets lines.
	float jump = max(max(n0, n1), max(n2, n3)) - centre;

	// Relative jump: 1 block behind at 2 m is a big edge, 1 block
	// behind at 200 m is not. A fixed threshold can't handle both.
	float edge = step(OUTLINE_THRESHOLD, jump / centre);

	color.rgb = mix(color.rgb, vec3(0.0), edge * OUTLINE_STRENGTH);
#endif
}
