#version 330 compatibility

uniform sampler2D colortex0;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
	float grey = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	color.rgb = vec3(grey);
}