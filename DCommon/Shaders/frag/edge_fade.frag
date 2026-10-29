#version 450

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float heightPx;
    float topInset;
    float bottomInset;
    float fadeLength;
    float topStrength;
    float bottomStrength;
} ubuf;

layout(binding = 1) uniform sampler2D source;

void main() {
    float y = qt_TexCoord0.y * ubuf.heightPx;
    float len = max(ubuf.fadeLength, 1.0);
    float top = y < ubuf.topInset ? 1.0 : clamp((y - ubuf.topInset) / len, 0.0, 1.0);
    float bottomEdge = ubuf.heightPx - ubuf.bottomInset;
    float bottom = y > bottomEdge ? 1.0 : clamp((bottomEdge - y) / len, 0.0, 1.0);
    float alpha = mix(1.0, top, ubuf.topStrength) * mix(1.0, bottom, ubuf.bottomStrength);
    fragColor = texture(source, qt_TexCoord0) * (alpha * ubuf.qt_Opacity);
}
