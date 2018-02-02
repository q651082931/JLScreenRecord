# JLScreenRecord
ios screenRecord
只需两行代码就能集成超简单自定义程度高的录屏框架

地址: https://github.com/q651082931/JLScreenRecord.git
因为公司的业务需求需要AR的录屏框架,要求同时录镜头,界面和渲染引擎的录屏框架,目前网上也没找合适的,所以自己封装了一个,项目中没有用系统的预览layer去显示镜头数据,因为截屏截不到,所以自己用OpenGL去渲染镜头数据.

实现原理:

1.视频流:JLScreenRecorder 这个类主要是每秒截图截30帧,通过AVFoundation写成视频流
2.音频录制:JLAudioRecord主要是音配录制
3.音视频合成:录制完成后会进行音视频和成和转码成mp4封装格式

优点 :因为开源而且全部自己实现没有用第三方的库,所以 拓展性强,自定义化程度高,可以对每帧图片进行处理也可以选择录屏范围,录制视频的参数可以随意设置
缺点 : cpu消耗有点大 50%左右

demo中有示例非常简单使用
1. 开始录制 [[JLScreenRecorder sharedInstance]startRecording];

2. 结束录制  [[JLScreenRecorder sharedInstance]stopRecordingWithCompletion:^(NSString *path) {



}];
其中项目中用到的立方体渲染是 https://github.com/holyHbw/OpenGLES_DEMO
参考资料 ASScreenRecorder https://github.com/alskipp/ASScreenRecorder
多谢作者贡献
如果有issue可以反馈给我多谢,如果对你有帮助帮点个星吧.
