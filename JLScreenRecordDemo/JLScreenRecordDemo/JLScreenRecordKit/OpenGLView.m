

#import "OpenGLView.h"
#import <GLKit/GLKit.h>
/*
 1.导入<GLKit/GLKit.h>,才会有openGL
 */

/*
 01-自定义图层类型
 02-初始化CAEAGLLayer图层属性
 03-创建EAGLContext
 04-创建渲染缓冲区
 05-创建帧缓冲区
 06-创建着色器
 07-创建着色器程序
 08-创建纹理对象
 09-YUV转RGB绘制纹理
 10-渲染缓冲区到屏幕
 11-清理内存
 */
// #:把参数包装成C语言字符串

enum {
    ATTRIB_POSITION,
    ATTRIB_TEXCOORD
};

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

// 顶点着色器代码
NSString *const kVertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 inputTextureCoordinate;
 
 varying vec2 textureCoordinate;
 
 void main()
 {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate;
 }
 );

// 片段着色器代码
NSString *const kYUVFullRangeConversionForLAFragmentShaderString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 
 precision mediump float;
 
// uniform sampler2D luminanceTexture;
// uniform sampler2D chrominanceTexture;
// uniform mediump mat3 colorConversionMatrix;
 
 uniform sampler2D luminanceTexture;

 void main()
 {
    /* mediump vec3 yuv;
     lowp vec3 rgb;
     
     yuv.x = texture2D(luminanceTexture, textureCoordinate).r;
     yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra - vec2(0.5, 0.5);
     rgb = colorConversionMatrix * yuv;
     
     gl_FragColor = vec4(rgb, 1);*/
     
     
     vec4 color = texture2D(luminanceTexture, textureCoordinate);

     gl_FragColor = vec4(color.z, color.y, color.x, color.w);
     
//     gl_FragColor = vec4(color.x, color.y, color.z, color.w);

     
 }
 );

static const GLfloat kColorConversion601FullRange[] = {
    1.0,    1.0,    1.0,
    0.0,    -0.343, 1.765,
    1.4,    -0.711, 0.0,
};


@interface OpenGLView ()

@property (nonatomic, strong) EAGLContext *context;
@property (nonatomic, assign) GLuint renderbuffers;
@property (nonatomic, assign) GLuint framebuffers;
@property (nonatomic, assign) GLuint vertexShader;
@property (nonatomic, assign) GLuint fragmentShader;
// 着色器程序
@property (nonatomic, assign) GLuint program;

// YUA转换RGB格式
@property (nonatomic, assign)  GLfloat *preferredConversion;

// 属性
@property (nonatomic, assign) int luminanceTextureAtt;

@property (nonatomic, assign) int chrominanceTextureAtt;

@property (nonatomic, assign) int colorConversionMatrixAtt;



@property (nonatomic, assign) CVOpenGLESTextureCacheRef textureCacheRef;

@property (nonatomic, assign) GLsizei bufferWidth;
@property (nonatomic, assign) GLsizei bufferHeight;

// Y引用
@property (nonatomic, assign) CVOpenGLESTextureRef luminanceTextureRef;

// UV引用
@property (nonatomic, assign) CVOpenGLESTextureRef chrominanceTextureRef;

// Y
@property (nonatomic, assign) GLuint luminanceTexture;

// UV
@property (nonatomic, assign) GLuint chrominanceTexture;


@end

@implementation OpenGLView

 - (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
    
}

#pragma mark - 初始化方法
- (void)setup
{
    [self setupLayer];
    
    [self setupEAGLContext];
    
    [self setupRenderBuffer];
    
    [self setupFrameBuffer];
    
    [self setupShader];
    
    [self setupProgram];
    
    // 创建纹理缓存对象
    CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &_textureCacheRef);
    if (err) {
        NSLog(@"CVOpenGLESTextureCacheCreate %d",err);
    }
    
    _preferredConversion = kColorConversion601FullRange;
}

// 01-自定义图层类型CAEAGLLayer
// 修改View的图层
// 让当前View支持OpenGL渲染
+ (Class)layerClass
{
    // CAEAGLLayer:进行OpenGL渲染
    return [CAEAGLLayer class];
}

// 02-初始化CAEAGLLayer图层属性
- (void)setupLayer
{
    CAEAGLLayer *layer = self.layer;
    // kEAGLDrawablePropertyRetainedBacking:是否保存之前渲染画面
    // kEAGLDrawablePropertyColorFormat:绘制界面格式
    layer.drawableProperties = @{
                                 kEAGLDrawablePropertyRetainedBacking:@NO,
                                 kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                                 };
}

// 03-创建EAGLContext
- (void)setupEAGLContext
{
    // 创建openGL上下文
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _context = context;
    
    // 设置为当前上下文
    [EAGLContext setCurrentContext:context];
    
}

// 04-创建渲染缓冲区
- (void)setupRenderBuffer
{
    // openGL:c框架,都是以gl开头
    // Opengl通过一些索引,去获取值
    /*
        n : 总数
        renderbuffers:渲染缓存区索引
     */
   
    
    // 生成渲染缓存区索引
    glGenRenderbuffers(1, &_renderbuffers);
    
    // 绑定渲染缓存区:通过索引直接访问这块地址
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffers);
    
    // 渲染缓存区分配内存
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
}

// 05-创建帧缓冲区
- (void)setupFrameBuffer
{
    // 创建帧缓存区

    glGenFramebuffers(1, &_framebuffers);
    
    // 绑定帧缓存区
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffers);
    // 颜色,深度
    // 把渲染缓存区添加到帧缓存区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderbuffers);
    
}

// 创建着色器
- (void)setupShader
{
    // 顶点着色器 GL_VERTEX_SHADER
   _vertexShader = [self loadShader:GL_VERTEX_SHADER withSource:kVertexShaderString];
    
    // 片段着色期 GL_FRAGMENT_SHADER
    _fragmentShader = [self loadShader:GL_FRAGMENT_SHADER withSource:kYUVFullRangeConversionForLAFragmentShaderString];
    
}


// 加载着色器
- (GLuint)loadShader:(GLenum)type withSource:(NSString *)source
{
    GLuint shader = glCreateShader(type);
    
    if (shader == 0) {
        // 创建失败
        NSLog(@"着色器创建失败");
        return 0;
    }
    
    // 加载着色器代码
    const char * shadeSource = [source UTF8String];
    glShaderSource(shader, 1, &shadeSource, NULL);
    
    // 编译着色器代码
    glCompileShader(shader);
    
    // 编译完成
    // 获取编译状态
    GLint compiled ;
    
    // 检测源码是否正确
    glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);
    
    if (compiled == 0) {
        NSLog(@"编译失败");
        // 编译失败
        return 0;
    }

    return shader;
}

// 07-创建着色器程序
- (void)setupProgram
{
    // 创建着色器程序
    _program = glCreateProgram();
    
    // 添加着色器
    // 顶点着色器
    glAttachShader(_program, _vertexShader);
    
    // 片段着色器
    glAttachShader(_program, _fragmentShader);
    
    // 绑定着色器属性
    /*
     attribute vec4 position;
     attribute vec2 inputTextureCoordinate;
     */
    // 一定要在链接之前,绑定普通属性
    // GLuint:属性索引
    // GLchar:绑定属性名称
    glBindAttribLocation(_program, ATTRIB_POSITION, "position");
    glBindAttribLocation(_program, ATTRIB_TEXCOORD, "inputTextureCoordinate");
    
    // 链接程序
    glLinkProgram(_program);
    
    // 绑定着色器全局属性
    // 注意:一定要在链接之后,才能获取到全局
    _luminanceTextureAtt = glGetUniformLocation(_program, "luminanceTexture");
    _chrominanceTextureAtt = glGetUniformLocation(_program, "chrominanceTexture");
    _colorConversionMatrixAtt = glGetUniformLocation(_program, "colorConversionMatrix");
    
    // 启动程序
    glUseProgram(_program);
}

#pragma mark - 7、创建纹理对象，渲染采集图片到屏幕
- (void)setupTexture:(CMSampleBufferRef)sampleBuffer
{
    // 创建纹理缓存对象
    CVImageBufferRef imageBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    // CVPixelBufferRef == CVImageBufferRef
    // 获取图片宽度
    GLsizei bufferWidth = (GLsizei)CVPixelBufferGetWidth(imageBufferRef);
    _bufferWidth = bufferWidth;
    GLsizei bufferHeight = (GLsizei)CVPixelBufferGetHeight(imageBufferRef);
    _bufferHeight = bufferHeight;
    
    // 创建亮度纹理
    // 激活纹理单元0, 不激活，创建纹理会失败
    glActiveTexture(GL_TEXTURE0);
    
    // 创建纹理对象
    CVReturn err;
    // YUV Y:亮度 UV:色度
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, imageBufferRef, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_RGBA, GL_UNSIGNED_BYTE, 0, &_luminanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    // 获取纹理对象
    _luminanceTexture = CVOpenGLESTextureGetName(_luminanceTextureRef);

    
    
    /*err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE, bufferWidth, bufferHeight, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &_luminanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _luminanceTexture = CVOpenGLESTextureGetName(_luminanceTextureRef);
    */
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _luminanceTexture);
    
    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    // 激活单元1
  /*  glActiveTexture(GL_TEXTURE1);
    
    // 创建色度纹理
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, _textureCacheRef, imageBufferRef, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, bufferWidth / 2, bufferHeight / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &_chrominanceTextureRef);
    if (err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    // 获取纹理对象
    _chrominanceTexture = CVOpenGLESTextureGetName(_chrominanceTextureRef);
    
    // 绑定纹理
    glBindTexture(GL_TEXTURE_2D, _chrominanceTexture);
    
    // 设置纹理滤波
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);*/
}

// 处理帧缓存 => 显示
- (void)processWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    
    // 设置当前上下文,每个线程当前上下文都没有设置,需要自己设置一次
    [EAGLContext setCurrentContext:_context];
    
    // 清空之前纹理缓存,否则不会刷新最新纹理
     [self cleanUpTextures];
    
    // 创建纹理对象
    [self setupTexture:sampleBuffer];
    
    // YUA 转 RGB
    [self convertYUVToRGBOutput];

    // 设置窗口尺寸
    glViewport(0, 0, self.bounds.size.width, self.bounds.size.height);
    
    // 把上下文的东西渲染到屏幕上
    [_context presentRenderbuffer:GL_RENDERBUFFER];

}

// YUA 转 RGB，里面的顶点和片段都要转换
- (void)convertYUVToRGBOutput
{
    // 在创建纹理之前，有激活过纹理单元，就是那个数字.GL_TEXTURE0,GL_TEXTURE1
    // 指定着色器中亮度纹理对应哪一层纹理单元
    // 这样就会把亮度纹理，往着色器上贴
    glUniform1i(_luminanceTextureAtt, 0);
    
    // 指定着色器中色度纹理对应哪一层纹理单元
//    glUniform1i(_chrominanceTextureAtt, 1);
    
    // YUA转RGB矩阵
//    glUniformMatrix3fv(_colorConversionMatrixAtt, 1, GL_FALSE, _preferredConversion);
    
    // 计算顶点数据结构
    CGRect vertexSamplingRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(self.bounds.size.width, self.bounds.size.height), self.layer.bounds);
    
    CGSize normalizedSamplingSize = CGSizeMake(0.0, 0.0);
    CGSize cropScaleAmount = CGSizeMake(vertexSamplingRect.size.width/self.layer.bounds.size.width, vertexSamplingRect.size.height/self.layer.bounds.size.height);
    
    if (cropScaleAmount.width > cropScaleAmount.height) {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.height/cropScaleAmount.width;
    }
    else {
        normalizedSamplingSize.width = 1.0;
        normalizedSamplingSize.height = cropScaleAmount.width/cropScaleAmount.height;
    }
    
    // 确定顶点数据结构
    GLfloat quadVertexData [] = {
        -1 * normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        normalizedSamplingSize.width, -1 * normalizedSamplingSize.height,
        -1 * normalizedSamplingSize.width, normalizedSamplingSize.height,
        normalizedSamplingSize.width, normalizedSamplingSize.height,
    };
    
    // 确定纹理数据结构
//    GLfloat quadTextureData[] =  { // 正常坐标
//        0, 0,
//        1, 0,
//        0, 1,
//        1, 1
//    };
    
//    GLfloat quadTextureData[] =  { // 正常坐标
//        0, 1,
//        0, 0,
//        1, 1,
//        1, 0
//    };
    
    GLfloat quadTextureData[] =  { // 正常坐标
        1, 1,
        1, 0,
        0, 1,
        0, 0
    };


    
    // 激活ATTRIB_POSITION顶点数组
    glEnableVertexAttribArray(ATTRIB_POSITION);
    // 给ATTRIB_POSITION顶点数组赋值
    glVertexAttribPointer(ATTRIB_POSITION, 2, GL_FLOAT, 0, 0, quadVertexData);
    
    // 激活ATTRIB_TEXCOORD顶点数组
    glVertexAttribPointer(ATTRIB_TEXCOORD, 2, GL_FLOAT, 0, 0, quadTextureData);
    // 给ATTRIB_TEXCOORD顶点数组赋值
    glEnableVertexAttribArray(ATTRIB_TEXCOORD);
    
    // 渲染纹理数据数据
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


- (void)cleanUpTextures
{
    // 清空亮度引用
    if (_luminanceTextureRef) {
        CFRelease(_luminanceTextureRef);
        _luminanceTextureRef = NULL;
    }
    
    // 清空色度引用
    if (_chrominanceTextureRef) {
        CFRelease(_chrominanceTextureRef);
        _chrominanceTextureRef = NULL;
    }
    
    // 清空纹理缓存
    CVOpenGLESTextureCacheFlush(_textureCacheRef, 0);
}

#pragma mark - 6、销毁渲染和帧缓存
- (void)destoryRenderAndFrameBuffer
{
    glDeleteRenderbuffers(1, &_renderbuffers);
    _renderbuffers = 0;
    
    glDeleteBuffers(1, &_framebuffers);
    _framebuffers = 0;
}


- (void)dealloc
{
    // 清空缓存
    [self destoryRenderAndFrameBuffer];
    
    // 清空纹理
    [self cleanUpTextures];
}


@end
