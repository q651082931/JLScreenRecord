//
//  Shader.vsh
//
//

/////////////////////////////////////////////////////////////////
// VERTEX ATTRIBUTES
/////////////////////////////////////////////////////////////////
attribute vec4 aPosition;
attribute vec2 aTextureCoord0;
attribute vec2 aTextureCoord1;

/////////////////////////////////////////////////////////////////
// Varyings
/////////////////////////////////////////////////////////////////
//varying lowp vec4 vColor;
varying lowp vec2 vTextureCoord0;
varying lowp vec2 vTextureCoord1;

/////////////////////////////////////////////////////////////////
// UNIFORMS
/////////////////////////////////////////////////////////////////
uniform mat4 uModelViewProjectionMatrix;

void main()
{
    // Pass the two sets of texture coordinates to the fragment
    // shader unmodified.
    vTextureCoord0 = aTextureCoord0.st;
    vTextureCoord1 = aTextureCoord1.st;
    
    // Transform the incoming vertex position by the combined
    // model-view-projection matrix to produce a fragment
    // position in the Color Render Buffer
    gl_Position = uModelViewProjectionMatrix * aPosition;
}
