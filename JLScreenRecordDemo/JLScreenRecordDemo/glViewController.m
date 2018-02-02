//
//  ViewController.m
//  deleteLater——openGLES
//
//  Created by 黄博闻 on 16/8/15.
//  Copyright © 2016年 黄博闻. All rights reserved.
//

/**
 viewDidLoad
 */
//1（create）
//2（complie）
//3（attach）
//4（bindAttribLocation）
//5（glLinkProgram）
//6（getUiniformLocation），
//7（genBuffer，bindBuffer，bufferData）
//8（加载纹理）
/**
 glkView：drawInRect：
 */
//9（glEnableVertexAttribArray，glVertexAttribPointer）//传数据给shader
//10（prepareToDraw，glDrawArrays）
//11（glUseProgram）
//12（glUniformMatrix4fv，glUniformMatrix3fv，glUniform1i，glUniform1f...）
//13（glDrawArrays）
/**
 update
 */
//projectionMatrix
//ModelViewMatrix
//处理一些变换

#import "glViewController.h"

@interface GLKEffectPropertyTexture (AGLKAdditions)

- (void)aglkSetParameter:(GLenum)parameterID
                   value:(GLint)value;

@end


@implementation GLKEffectPropertyTexture (AGLKAdditions)

- (void)aglkSetParameter:(GLenum)parameterID
                   value:(GLint)value;
{
    glBindTexture(self.target, self.name);
    
    glTexParameteri(
                    self.target,
                    parameterID,
                    value);
}

@end

/////////////////////////////////////////////////////////////////
// This data type is used to store information for each vertex
typedef struct {
    GLKVector3  positionCoords;
    //GLKVector3  normalCoords;
    GLKVector2  textureCoords;
}
SceneVertex;

/////////////////////////////////////////////////////////////////
// Define vertex data for a triangle to use in example
static const SceneVertex vertices[] =
{
    {{ 0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{ 0.5f,  0.5f, -0.5f},{1.0f, 0.0f}},
    {{ 0.5f, -0.5f,  0.5f},{0.0f, 1.0f}},
    {{ 0.5f, -0.5f,  0.5f},{0.0f, 1.0f}},
    {{ 0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{ 0.5f,  0.5f, -0.5f},{1.0f, 0.0f}},
    
    {{ 0.5f,  0.5f, -0.5f},{1.0f, 0.0f}},
    {{-0.5f,  0.5f, -0.5f},{0.0f, 0.0f}},
    {{ 0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{ 0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{-0.5f,  0.5f, -0.5f},{0.0f, 0.0f}},
    {{-0.5f,  0.5f,  0.5f},{0.0f, 1.0f}},
    
    {{-0.5f,  0.5f, -0.5f},{1.0f, 0.0f}},
    {{-0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{-0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{-0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{-0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{-0.5f, -0.5f,  0.5f},{0.0f, 1.0f}},
    
    {{-0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{ 0.5f, -0.5f, -0.5f},{1.0f, 0.0f}},
    {{-0.5f, -0.5f,  0.5f},{0.0f, 1.0f}},
    {{-0.5f, -0.5f,  0.5f},{0.0f, 1.0f}},
    {{ 0.5f, -0.5f, -0.5f},{1.0f, 0.0f}},
    {{ 0.5f, -0.5f,  0.5f},{1.0f, 1.0f}},
    
    {{ 0.5f,  0.5f,  0.5f},{1.0f, 1.0f}},
    {{-0.5f,  0.5f,  0.5f},{0.0f, 1.0f}},
    {{ 0.5f, -0.5f,  0.5f},{1.0f, 0.0f}},
    {{ 0.5f, -0.5f,  0.5f},{1.0f, 0.0f}},
    {{-0.5f,  0.5f,  0.5f},{0.0f, 1.0f}},
    {{-0.5f, -0.5f,  0.5f},{0.0f, 0.0f}},
    
    {{ 0.5f, -0.5f, -0.5f},{1.0f, 0.0f}},
    {{-0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{ 0.5f,  0.5f, -0.5f},{1.0f, 1.0f}},
    {{ 0.5f,  0.5f, -0.5f},{1.0f, 1.0f}},
    {{-0.5f, -0.5f, -0.5f},{0.0f, 0.0f}},
    {{-0.5f,  0.5f, -0.5f},{0.0f, 1.0f}},
};

enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_TEXTURE0_SAMPLER2D,
    UNIFORM_TEXTURE1_SAMPLER2D,
    NUM_UNIFORMS
};

GLuint uniforms[NUM_UNIFORMS];

@interface glViewController ()
{
    GLKView *glView;
    EAGLContext *context;
    GLKBaseEffect *baseEffect;
    GLfloat rotation;
    GLKMatrix4 modelViewProjectionMatrix;
    GLuint shaderProgram;
    AGLKVertexAttribArrayBuffer *vertexBuffer;
}
- (BOOL)loadShader;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation glViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

//init and setup glView/context/baseEffect/vertexBuffer
-(void)setup{
    context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES3];
    glView = (GLKView *)self.view;
    NSAssert([glView isKindOfClass:[GLKView class]],
             @"View controller's view is not a GLKView");
    glView.context = context;
    [EAGLContext setCurrentContext:context];
    glEnable(GL_DEPTH_TEST);
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    glView.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    
    [self loadShader];
    
    baseEffect = [[GLKBaseEffect alloc]init];
    
    vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]initWithAttribStride:sizeof(SceneVertex) numberOfVertices:sizeof(vertices)/sizeof(SceneVertex) bytes:vertices usage:GL_STATIC_DRAW];
    
    [self loadTextures];
}

//load the texture to baseEffect
-(void)loadTextures{
    //texture 1
    CGImageRef texture1 = [UIImage imageNamed:@"a"].CGImage;
    GLKTextureInfo *textInfo1 = [GLKTextureLoader textureWithCGImage:texture1 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                                                                       GLKTextureLoaderOriginBottomLeft, nil] error:NULL];
    baseEffect.texture2d0.target = textInfo1.target;
    baseEffect.texture2d0.name = textInfo1.name;
//    [baseEffect.texture2d0 aglkSetParameter:GL_TEXTURE_WRAP_S
//                                      value:GL_REPEAT];
//    [baseEffect.texture2d0 aglkSetParameter:GL_TEXTURE_WRAP_T
//                                      value:GL_REPEAT];
    //[baseEffect.texture2d0 aglkSetParameter:GL_TEXTURE_WRAP_S value:GL_REPEAT];
    glBindTexture(baseEffect.texture2d0.target, baseEffect.texture2d0.name);
    //texture 2
    CGImageRef texture2 = [UIImage imageNamed:@"b"].CGImage;
    GLKTextureInfo *textInfo2 = [GLKTextureLoader textureWithCGImage:texture2 options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],
                                                                                       GLKTextureLoaderOriginBottomLeft, nil] error:NULL];
    baseEffect.texture2d1.target = textInfo2.target;
    baseEffect.texture2d1.name = textInfo2.name;
    baseEffect.texture2d1.envMode = GLKTextureEnvModeDecal;
//    [baseEffect.texture2d1 aglkSetParameter:GL_TEXTURE_WRAP_S
//                                      value:GL_REPEAT];
//    [baseEffect.texture2d1 aglkSetParameter:GL_TEXTURE_WRAP_T
//                                      value:GL_REPEAT];
    //[baseEffect.texture2d1 aglkSetParameter:GL_TEXTURE_WRAP_S value:GL_REPEAT];
    glBindTexture(baseEffect.texture2d1.target, baseEffect.texture2d1.name);
}


-(BOOL)loadShader{
    GLuint vertShader,fragShader;
    NSString *vertShaderPathname,*fragShaderPathname;
    
    shaderProgram = glCreateProgram();
    
    vertShaderPathname = [[NSBundle mainBundle]pathForResource:@"vertex" ofType:@"vsh"];
    fragShaderPathname = [[NSBundle mainBundle]pathForResource:@"fragment" ofType:@"fsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"failed to compile vertex shader");
        return NO;
    }
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"failed to compile fragment shader");
        return NO;
    }
    
    glAttachShader(shaderProgram, vertShader);
    glAttachShader(shaderProgram, fragShader);
    
    glBindAttribLocation(shaderProgram, GLKVertexAttribPosition, "aPosition");
    glBindAttribLocation(shaderProgram, GLKVertexAttribTexCoord0, "aTextureCoord0");
    glBindAttribLocation(shaderProgram, GLKVertexAttribTexCoord1, "aTextureCoord1");
    
    if (![self linkProgram:shaderProgram]) {
        NSLog(@"Failed to link program: %d", shaderProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (shaderProgram) {
            glDeleteProgram(shaderProgram);
            shaderProgram = 0;
        }
        
        return NO;
    }
    
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(shaderProgram, "uModelViewProjectionMatrix");
    uniforms[UNIFORM_TEXTURE0_SAMPLER2D] = glGetUniformLocation(shaderProgram, "uSampler0");
    uniforms[UNIFORM_TEXTURE1_SAMPLER2D] = glGetUniformLocation(shaderProgram, "uSampler1");
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(shaderProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(shaderProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

- (void)update
{
    
    NSLog(@"update");
    float aspect = fabs(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    baseEffect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, rotation, 0.0f, 1.0f, 0.0f);
    
    // Compute the model view matrix for the object rendered with GLKit
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    baseEffect.transform.modelviewMatrix = modelViewMatrix;
    
    // Compute the model view matrix for the object rendered with ES2
    modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation, 1.0f, 1.0f, 1.0f);
    modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
    
    modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
    
    rotation += self.timeSinceLastUpdate * 0.5f;
}

-(void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    
    glClearColor(0.7, 0, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    
    [vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                      numberOfCoordinates:3
                             attribOffset:offsetof(SceneVertex, positionCoords)
                             shouldEnable:YES];
    
    [vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                      numberOfCoordinates:2
                             attribOffset:offsetof(SceneVertex, textureCoords)
                             shouldEnable:YES];
    
    [vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord1
                      numberOfCoordinates:2
                             attribOffset:offsetof(SceneVertex, textureCoords)
                             shouldEnable:YES];
    
    
    [baseEffect prepareToDraw];
    
    // Draw triangles using baseEffect
    [vertexBuffer drawArrayWithMode:GL_TRIANGLES
                   startVertexIndex:0
                   numberOfVertices:sizeof(vertices) / sizeof(SceneVertex)];
    
    glUseProgram(shaderProgram);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0,  modelViewProjectionMatrix.m);
    glUniform1i(uniforms[UNIFORM_TEXTURE0_SAMPLER2D], 0);
    glUniform1i(uniforms[UNIFORM_TEXTURE1_SAMPLER2D], 1);
    glDrawArrays(GL_TRIANGLES, 0, sizeof(vertices) / sizeof(SceneVertex));
}


#pragma functions of  loadeShader
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
