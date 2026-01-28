import common from '@ohos.app.ability.common';
import { promptAction } from '@kit.ArkUI';
import { VideoTrimmerOption } from '../XHTB/videotrimmer/VideoTrimmerOption';
import { VideoTrimListener } from '../XHTB/videotrimmer/VideoTrimListener';
import { VideoLoadFramesListener } from '../XHTB/videotrimmer/VideoLoadFramesListener';
import router from '@ohos.router';
import { VideoTrimmerView } from '../XHTB/videotrimmer/VideoTrimmerView';
import { logger } from '../utils/VideoLogger';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';

const TAG = 'VideoTrimmerPage';

@Entry
@Component
struct VideoTrimmerPage {
  @State videoTrimmerOption: VideoTrimmerOption = new VideoTrimmerOption();
  @State showDownloadDialog: boolean = false;
  @State trimmedFilePath: string = '';
  @State downloadUrl: string = '';
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  async aboutToAppear() {
    // 获取传入的视频路径
    const videoPath = AppStorage.get<string>('videoPath');
    if (videoPath) {
      this.videoTrimmerOption.srcFilePath = videoPath;
      this.videoTrimmerOption.context = this.context;
      this.videoTrimmerOption.listener = this.initListener();
      this.videoTrimmerOption.loadFrameListener = this.initLoadFrameListener();
      // 移除视频时长限制
      this.videoTrimmerOption.video_max_time = 0;
      this.videoTrimmerOption.video_min_time = 0;
      // 设置一个很大的值来移除帧数限制（避免除以0）
      this.videoTrimmerOption.max_count_range = 9999;
    }
  }

  // 初始化剪辑回调
  initListener(): VideoTrimListener {
    const that = this;
    return {
      onStartTrim: () => {
        logger.info(TAG, 'onStartTrim');
      },
      onFinishTrim: (outputFile: string) => {
        logger.info(TAG, 'onFinishTrim: ' + outputFile);
        // 剪辑完成，自动下载到媒体库
        that.trimmedFilePath = outputFile;
        that.downloadVideo();
      },
      onCancel: () => {
        logger.info(TAG, 'onCancel');
        router.back();
      }
    };
  }

  // 初始化帧加载回调
  initLoadFrameListener(): VideoLoadFramesListener {
    return {
      onStartLoad: () => {
        logger.info(TAG, 'onStartLoad');
      },
      onFinishLoad: () => {
        logger.info(TAG, 'onFinishLoad');
      }
    };
  }

  build() {
    Stack() {
      Column() {
        VideoTrimmerView({
          videoTrimmerOption: this.videoTrimmerOption
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      // 下载对话框
      if (this.showDownloadDialog) {
        this.DownloadDialog()
      }
    }
  }

  @Builder
  DownloadDialog() {
    Column() {
      Column() {
        if (this.downloadUrl) {
          Text('视频已保存')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 24 })
          Text('视频已成功保存到相册')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 32 })

          Button('确定')
            .width(120)
            .height(40)
            .backgroundColor('#007DFF')
            .onClick(() => {
              this.showDownloadDialog = false;
              router.back();
            })
        } else {
          Text('保存视频')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 24 })

          Text('正在保存到相册...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 32 })

          Button('取消')
            .width(120)
            .height(40)
            .backgroundColor('#F5F5F5')
            .fontColor('#666666')
            .onClick(() => {
              this.showDownloadDialog = false;
              router.back();
            })
        }
      }
      .width(280)
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 20, color: '#1F000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.5)')
    .justifyContent(FlexAlign.Center)
  }

  // 下载视频
  async downloadVideo() {
    try {
      logger.info(TAG, '开始保存视频: ' + this.trimmedFilePath);
      // 显示保存对话框
      this.showDownloadDialog = true;

      // 指定待保存到媒体库的位于应用沙箱的视频uri
      // 直接使用文件路径，不添加file://前缀
      let srcFileUris: Array<string> = [this.trimmedFilePath];
      logger.info(TAG, '源文件URI: ' + srcFileUris[0]);

      // 指定待保存视频的创建选项，包括文件后缀和视频类型
      let photoCreationConfigs: Array<photoAccessHelper.PhotoCreationConfig> = [
        {
          fileNameExtension: 'mp4',
          photoType: photoAccessHelper.PhotoType.VIDEO,
          subtype: photoAccessHelper.PhotoSubtype.DEFAULT
        }
      ];

      // 获取PhotoAccessHelper实例
      let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context);
      logger.info(TAG, '获取PhotoAccessHelper成功');

      // 基于弹窗授权的方式获取媒体库的目标uri，添加超时处理
      logger.info(TAG, '准备调用showAssetsCreationDialog');
      let desFileUris: Array<string> = await Promise.race([
        phAccessHelper.showAssetsCreationDialog(srcFileUris, photoCreationConfigs),
        new Promise<Array<string>>((_, reject) =>
          setTimeout(() => reject(new Error('Dialog timeout')), 30000)
        ) as Promise<Array<string>>
      ]);
      logger.info(TAG, 'showAssetsCreationDialog 返回目标URI: ' + desFileUris[0]);

      // 将来源于应用沙箱的视频内容写入媒体库的目标uri
      logger.info(TAG, '准备打开源文件: ' + srcFileUris[0]);
      let srcFile = await fileIo.open(srcFileUris[0], fileIo.OpenMode.READ_ONLY);
      logger.info(TAG, '打开源文件成功, fd: ' + srcFile.fd);

      logger.info(TAG, '准备打开目标文件: ' + desFileUris[0]);
      let desFile = await fileIo.open(desFileUris[0], fileIo.OpenMode.WRITE_ONLY);
      logger.info(TAG, '打开目标文件成功, fd: ' + desFile.fd);

      logger.info(TAG, '开始复制文件');
      await fileIo.copyFile(srcFile.fd, desFile.fd);
      logger.info(TAG, '文件复制完成');

      fileIo.closeSync(srcFile);
      fileIo.closeSync(desFile);

      // 保存下载后的URL（媒体库中的URI）
      this.downloadUrl = desFileUris[0];

      logger.info(TAG, '保存完成，URL: ' + this.downloadUrl);

      // 自动更新分享链接为剪辑后的视频
      AppStorage.setOrCreate('shareVideoPath', this.downloadUrl);
      logger.info(TAG, '已更新分享视频路径: ' + this.downloadUrl);

      promptAction.showToast({ message: '视频保存成功！' });
    } catch (error) {
      logger.error(TAG, '保存失败: ' + JSON.stringify(error));
      if (error instanceof Error) {
        logger.error(TAG, '错误详情: message=' + error.message);
      } else {
        logger.error(TAG, '错误详情: ' + JSON.stringify(error));
      }
      promptAction.showToast({ message: '视频保存失败！' });
      this.showDownloadDialog = false;
    }
  }
}
