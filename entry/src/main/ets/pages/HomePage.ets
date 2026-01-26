import { promptAction } from '@kit.ArkUI';
import window from '@ohos.window';
import { common } from '@kit.AbilityKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
// 导入日志模块和错误码模块
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { systemShare, harmonyShare } from '@kit.ShareKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import Logger from '../utils/Logger';
//粘贴组件
import { pasteboard } from '@kit.BasicServicesKit';
//分享相关
import { fileUri } from '@kit.CoreFileKit';
import request from '@ohos.request';
import { navigationManager } from '../common/NavigationManager';
import { image } from '@kit.ImageKit';
import { effectKit } from '@kit.ArkGraphics2D';
import { CommonConstants } from '../constants/CommonConstants';
import { resourceManager } from '@kit.LocalizationKit';

//本地
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import MediaFileUri from '../media/MediaFileUri';
import KnockShareGuideCard, { CardRes } from '../model/KnockShareGuideCard';
import { GlobalInfoModel, BreakpointTypeEnum } from '../common/GlobalInfoModel';
import { DeviceSegmentButton } from '../components/DeviceSegmentButton';

//点光源效果
/*import { hdsEffect } from '@kit.UIDesignKit';*/

let logger = Logger.getLogger('[KnockShare]');
let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

/*
@Extend(Button) function globalButtonStyle() {
  .width('60%')
  .height(80)
  //.background (0x99CCFF)  // 白色背景
  .borderRadius(15)           // 圆角半径
  .margin({ top: 10 })         // 顶部间距
}*/

@Entry
@Component
  // 使用@Entry装饰器标记为入口组件，@Component表示自定义组件
export struct HomePage {
  @State initialOrientation: window.Orientation = window.Orientation.PORTRAIT; // 记录初始方向
  @State curRate: PlaybackSpeed = PlaybackSpeed.Speed_Forward_1_00_X
  @State isShortcutKeyEnabled: boolean = false
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State isPlaying: boolean = true;
  @State picture: PixelMap | undefined = undefined;
  @State localPixelMap: PixelMap | undefined = undefined; // 本地图片的PixelMap
  //@State networkPreviewUri: string = ''; // 默认网络预览图
  @StorageLink('sharepng') sharepng: string = 'https://www.hnyqwq.cn/hvideo/share.png'
  //@State networkPreviewUri: Resource = $r('app.media.homepageback');
  @State savefileUri: string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  @StorageLink('pengtitle') pengtitle: string = ' '
  //分享
  @State localShareImageUri: string = ''; // 本地分享图片的URI
  @State isLocalImageSelected: boolean = false; // 是否已选择本地图片
  //碰一碰
  @State whiteStatus: boolean = false;
  //点光源效果
  /*@State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  @State lightSourceType: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;*/

  // 添加一个状态来存储图片的宽高比
  @State imageAspectRatio: number = 1; // 默认为1:1
  @State isImageLoaded: boolean = false; // 图片是否已加载
  @State imageKey: string = ''; // 图片key用于强制刷新

  // 调试数据状态
  @State debugImagePath: string = '';
  @State debugImageExtension: string = '';
  @State debugSharepng: string = '';
  @State debugFilesDir: string = '';
  @State debugFilesList: string = '';
  @State debugFileExists: boolean = false;
  @State debugFileStat: string = '';
  @State debugFileError: string = '';

  // 顶部胶囊按钮
  @State selectedShareMode: number = 0; // 0: 碰一碰, 1: 隔空传输
  @State currentDescription: Resource = $r('app.string.pengyipeng_description'); // 当前显示的描述

  // 主颜色获取相关
  @State mainColor: string = '#F5E5D8'; // 获取的主颜色，用于文字背景，默认为#F5E5D8

  // 顶部背景渐变相关
  @State topBgColor: string = '#FFFFFF'; // 顶部背景颜色
  @State topSafeHeight: number = 0; // 顶部安全区域高度

  // 断点相关
  @StorageProp('currentWidthBreakpoint') currentBreakpoint: string = 'md';

  // 监听断点变化，动态调整默认分享模式
  @Watch('onBreakpointChange')
  @StorageProp('currentWidthBreakpoint') currentBreakpointWatcher: string = 'md';

  // 断点变化回调
  onBreakpointChange() {
    // 如果是平板设备且当前是碰一碰模式，自动切换到隔空投送模式
    if ((this.currentBreakpointWatcher === 'lg' || this.currentBreakpointWatcher === 'xl') &&
        this.selectedShareMode === 0) {
      this.selectedShareMode = 1;
      this.currentDescription = $r('app.string.gekong_description');
      console.log('检测到大屏设备，自动切换到隔空投送模式');
    }
  }

  //隔空投送
  private immersiveListening() {
    harmonyShare.on('gesturesShare', this.immersiveCallback);
  }

  private immersiveDisablingListening() {
    harmonyShare.off('gesturesShare', this.immersiveCallback);
  }
  //本地
  mediaFileUri: MediaFileUri = new MediaFileUri();
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  // 添加缺失的 imageExtension 状态属性
  @State imageExtension: string = '.png'; // 默认为.png格式

  //背景图片本地
  private async selectImage() {
    let uri = await this.openPhoto();
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      return;
    }

    console.log('=== selectImage 开始 ===');
    console.log('选择的图片 URI: ' + uri);

    // 根据选中的图片URI更新扩展名
    if (uri.endsWith('.png')) {
      this.imageExtension = '.png';
    } else if (uri.endsWith('.jpg') || uri.endsWith('.jpeg')) {
      this.imageExtension = '.jpg';
    } else if (uri.endsWith('.webp')) {
      this.imageExtension = '.webp';
    } else {
      // 默认使用.png格式
      this.imageExtension = '.png';
    }

    console.log('更新后的 imageExtension: ' + this.imageExtension);

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    console.log('selectImage 中的 context.filesDir: ' + context.filesDir);
    console.log('全局 filesDir: ' + filesDir);
    console.log('两者是否相同: ' + (context.filesDir === filesDir));

    // 根据当前图片扩展名设置目标路径
    let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;
    console.log('目标完整路径 targetPath: ' + targetPath);

    // 使用文件描述符方式复制文件（适配图库URI）
    try {
      // 打开源文件（图库URI）
      let sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      // 创建目标文件
      let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

      // 读取并写入文件
      let bufferSize = 1024 * 1024; // 1MB 缓冲区
      let buffer = new ArrayBuffer(bufferSize);
      let readLen: number = 0;

      while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
        fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
      }

      // 关闭文件
      fileIo.closeSync(sourceFile);
      fileIo.closeSync(targetFile);

      hilog.info(0x0000, 'localsharepng' , 'Copy completed: ' + targetPath);

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 验证文件是否真的存在
      const stat = fileIo.statSync(targetPath);
      hilog.info(0x0000, 'localsharepng' , 'File verified, size: ' + stat.size);

      // 直接加载为 PixelMap
      const imageSource = image.createImageSource(targetPath);
      this.localPixelMap = await imageSource.createPixelMap();
      hilog.info(0x0000, 'localsharepng' , 'PixelMap created: ' + (this.localPixelMap ? 'success' : 'failed'));

      // 现在文件已经复制完成，更新 sharepng
      this.sharepng = 'file://' + targetPath;
      hilog.info(0x0000, 'localsharepng' , 'sharepng updated to: ' + this.sharepng);
      hilog.info(0x0000, 'localsharepng' , '当前 imageExtension: ' + this.imageExtension);
    } catch (error) {
      hilog.error(0x0000, 'localsharepng' , 'Copy failed: ' + JSON.stringify(error));
      return;
    }

    // 强制刷新图片显示
    this.imageKey = Date.now().toString();
    // 重新获取图片宽高比以更新显示
    await this.getImageAspectRatio();

    // 如果是横屏+隔空模式，获取主颜色
    if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
      await this.extractMainColor();
    }

    console.log('=== selectImage 结束 ===');
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }


  //华为系统分享
  private async share() {
    let uiContext: UIContext = this.getUIContext();
    if (!this.networkVideoSrc) {
      promptAction.showToast({ message: this.context.resourceManager.getStringSync($r('app.string.nopeng').id) });
      return;
    }
    let contextFaker: Context = uiContext.getHostContext() as Context;
    // 根据当前图片扩展名设置缩略图路径
    let thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      // 当前只支持'image/jpeg','image/webp'和'image/png'类型图片.
      format: 'image/jpeg',
      // JPEG编码中设定输出图片质量的参数,取值范围为0-100.
      // 建议适当压缩,图片过大无法拉起分享.
      quality: 30
    });

    //let context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    //let shareTitle = context.resourceManager.getStringSync($r('app.string.shareinfo').id);

    console.log('Creating share data');
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc, // 使用输入框中的视频链接
      //title: shareTitle,
      title: this.pengtitle,
      description: this.networkVideoSrc,
      thumbnail: new Uint8Array(buffer),
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  //碰一碰分享
  private readonly cardSwiperResources: CardRes[] = [
    {
      text: '对方手机需 HarmonyOS 5 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
      framesCount: 128,
      startDelay: 50,
      stopDelay: 500,
    },
    {
      text: '对方电脑需 HarmonyOS 6 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_pc_',
      framesCount: 104,
      startDelay: 50,
      stopDelay: 50,
    },
    {
      text: '对方手机需 HarmonyOS 6 及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_pc_pull_',
      framesCount: 150,
      startDelay: 500,
      stopDelay: 1000,
    },
  ];
  private debounceTimer: number = 0
  private urlDebounceTimer: number = 0
  // 修改 handleImageUpdate 方法
  private handleImageUpdate() {
    clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.updateImageExtension(); // 确保在下载前更新扩展名
      this.DownloadToSandbox();
    }, 1000); // 1秒防抖
  }

  // 修改 DownloadToSandbox 方法
  private async DownloadToSandbox() {
    if (!this.isValidUrl(this.sharepng)) {
      console.log('Invalid URL, skipping download');
      return;
    }

    if (this.sharepng !== '') {
      try {
        console.log('=== DownloadToSandbox 开始下载 ===');
        console.log('sharepng: ' + this.sharepng);
        // 根据URL确定图片扩展名（再次确认）
        this.updateImageExtension();

        // 先删除旧文件（如果存在）
        try {
          await fs.unlink(filesDir + '/pengyipeng' + this.imageExtension);
        } catch (e) {
          // 文件不存在是正常情况，忽略错误
        }

        // 下载新文件，使用回调确保下载完成
        const downloadTask = await request.downloadFile(context, {
          url: this.sharepng,
          filePath: filesDir + '/pengyipeng' + this.imageExtension
        });

        // 等待下载完成
        await new Promise<void>((resolve) => {
          downloadTask.on('complete', () => {
            console.log('Image downloaded successfully as ' + this.imageExtension);
            
            // 下载完成后，等待文件系统同步
            setTimeout(async () => {
              console.log('下载完成，开始获取宽高比');
              await this.getImageAspectRatio();
              console.log('getImageAspectRatio 执行完成，宽高比: ' + this.imageAspectRatio);
              console.log('=== DownloadToSandbox 下载完成 ===');
              resolve();
            }, 500);
          });
          
          downloadTask.on('fail', (err: number) => {
            console.error('Download failed with error code: ' + err);
            resolve(); // 即使失败也resolve，避免卡住
          });
        });
      } catch (error) {
        console.error('Download failed:', error);
      }
    }
  }

  // 添加缺失的 updateImageExtension 方法
  private updateImageExtension() {
    if (this.sharepng.endsWith('.png')) {
      this.imageExtension = '.png';
    } else if (this.sharepng.endsWith('.jpg') || this.sharepng.endsWith('.jpeg')) {
      this.imageExtension = '.jpg';
    } else if (this.sharepng.endsWith('.webp')) {
      this.imageExtension = '.webp';
    } else {
      // 默认使用.png格式
      this.imageExtension = '.png';
    }
  }

  isValidUrl(url: string): boolean {
    if (!url || typeof url !== 'string') {
      return false;
    }
    const trimmedUrl = url.trim();
    if (trimmedUrl.length < 3 || trimmedUrl.length > 2048) {
      return false;
    }

    // 不能包含空格
    if (trimmedUrl.includes(' ')) {
      return false;
    }

    // 检查是否为 file:// 协议（本地文件），不算作网络 URL
    if (trimmedUrl.startsWith('file://')) {
      return false;
    }

    // 检查是否为 http:// 或 https:// 开头的 URL
    if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      const domainStart = trimmedUrl.indexOf('://') + 3;
      if (domainStart >= trimmedUrl.length) return false;

      const domainPart = trimmedUrl.substring(domainStart);
      if (domainPart.length === 0) return false;

      // 域名至少包含一个点
      if (!domainPart.includes('.')) {
        return false;
      }

      return true;
    }

    // 检查是否为 URL scheme 格式（如 bilibili://, weixin://, tel:, mailto:, etc.）
    const colonIndex = trimmedUrl.indexOf(':');
    if (colonIndex === -1 || colonIndex === 0) {
      return false;
    }

    const scheme = trimmedUrl.substring(0, colonIndex);
    const rest = trimmedUrl.substring(colonIndex + 1);

    // scheme 部分必须只包含字母、数字、点、加号和减号
    for (let i = 0; i < scheme.length; i++) {
      const char = scheme[i];
      const lowerChar = char.toLowerCase();
      if (!((lowerChar >= 'a' && lowerChar <= 'z') || (char >= '0' && char <= '9') || char === '.' || char === '+' || char === '-')) {
        return false;
      }
    }

    // scheme 后面必须有内容（可以是 // 或其他内容）
    return rest.length > 0;
  }

  // 从文本中提取链接
  extractUrlFromText(text: string): string | null {
    if (!text || text.trim() === '') {
      return null;
    }

    const trimmedText = text.trim();
    let startIndex = -1;

    // 查找 http:// 或 https:// 的起始位置
    for (let i = 0; i < trimmedText.length - 6; i++) {
      if (trimmedText.substr(i, 7) === 'http://' ||
          (i < trimmedText.length - 7 && trimmedText.substr(i, 8) === 'https://')) {
        startIndex = i;
        break;
      }
    }

    if (startIndex === -1) {
      return null;
    }

    // 提取URL直到遇到空白字符或常见结束符
    let endIndex = startIndex;
    const endChars = [' ', '\n', '\t', '"', "'", '<', '>', '，', '。', '！', '？', '【', '】'];
    while (endIndex < trimmedText.length) {
      const char = trimmedText[endIndex];
      if (endChars.includes(char)) {
        break;
      }
      endIndex++;
    }

    const extractedUrl = trimmedText.substring(startIndex, endIndex);

    // 验证提取的URL是否有效
    if (this.isValidUrl(extractedUrl)) {
      return extractedUrl;
    }

    return null;
  }

  onPageHide(): void { //隔空传送
    let uiContext: UIContext = this.getUIContext();
    let context: Context = uiContext.getHostContext() as Context;
    context.eventHub.emit('onBackGround');
  }

  aboutToAppear(): void {
    console.log('=== aboutToAppear 开始 ===');
    this.DownloadToSandbox();
    this.whiteListening()
    this.immersiveListening();
    let context = getContext(this);

    // 初始化 AppStorage 中的默认值（如果不存在）
    if (!AppStorage.get('sharepng')) {
      AppStorage.setOrCreate('sharepng', 'https://www.hnyqwq.cn/hvideo/share.png');
    }
    if (!AppStorage.get('pengtitle')) {
      const defaultTitle = this.context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id);
      AppStorage.setOrCreate('pengtitle', defaultTitle);
    }

    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'pages/HomePage');
    AppStorage.delete('currentRouteParams');

    // 获取顶部安全区域高度
    window.getLastWindow(this.getUIContext().getHostContext() as common.UIAbilityContext).then((windowInstance) => {
      this.topSafeHeight = this.getUIContext().px2vp(windowInstance.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height);
      this.extractTopBgColor(); // 获取初始背景颜色
    });

    // 碰一碰标题
    this.pengtitle = this.context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id);

    // 根据设备能力设置默认分享模式
    // 判断是否为大屏设备（平板），平板不支持碰一碰分享
    // 直接从 AppStorage 读取断点值，确保获取最新的设备形态
    const actualBreakpoint = AppStorage.get<string>('currentWidthBreakpoint') || this.currentBreakpointWatcher;
    const isLargeScreen = actualBreakpoint === 'lg' || actualBreakpoint === 'xl';
    console.log('当前断点: ' + actualBreakpoint + ', 是否大屏: ' + isLargeScreen);

    if (canIUse('SystemCapability.Collaboration.HarmonyShare') && !isLargeScreen) {
      // 支持碰一碰分享的能力且非平板，默认为碰一碰分享预览
      this.selectedShareMode = 0;
      this.currentDescription = $r('app.string.pengyipeng_description');
      console.log('设备支持碰一碰分享且非平板，默认选择碰一碰模式');
    } else {
      // 不支持碰一碰分享或是平板，默认为隔空投送分享预览
      this.selectedShareMode = 1;
      this.currentDescription = $r('app.string.gekong_description');
      console.log('设备不支持碰一碰分享或为平板设备，默认选择隔空投送模式');
    }

    // 恢复接续的数据（优先级最高）- @StorageLink 会自动订阅 AppStorage 变化
    const restoredSharepng = AppStorage.get<string>('sharepng');
    if (restoredSharepng && restoredSharepng !== 'https://www.hnyqwq.cn/hvideo/share.png') {
      console.log('接续恢复 sharepng:', restoredSharepng);
    }
    const restoredPengtitle = AppStorage.get<string>('pengtitle');
    if (restoredPengtitle && restoredPengtitle !== this.pengtitle) {
      console.log('接续恢复 pengtitle:', restoredPengtitle);
    }

    // 建议调整顺序确保实时参数优先
    const params = navigationManager.getParams() as Record<string, string>;
    if (params?.['videoUrl']) {
      this.networkVideoSrc = params['videoUrl'];
    }
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      AppStorage.delete('sharedVideoUrl');
    }
    // 触发视频加载
    this.context.eventHub.on('urlUpdate', (url: string) => {
      this.networkVideoSrc = url
      //this.controller.start()
    })

    context.eventHub.on('onBackGround', this.onBackGround);

    console.log('=== aboutToAppear 结束 ===');
  }

  aboutToDisappear(): void {
    logger.info('aboutToDisappear invoked.');
    this.whiteDisablingListening()
    //this.immersiveDisablingListening();
    let context = getContext(this);
    context.eventHub.off('onFocus');
    context.eventHub.off('onBackGround');
  }

  private onBackGround = () => {
    this.whiteDisablingListening()
    this.immersiveDisablingListening();
  }
  // 在类成员变量区域定义箭头函数绑定回调
  private whiteCallback = async (sharableTarget: harmonyShare.SharableTarget): Promise<void> => {
    // 处理分享数据
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      //this.controller.start();
      AppStorage.delete('sharedVideoUrl');
    }
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    // 根据当前图片扩展名设置文件路径（使用当前 context 的 filesDir）
    let filePath = context.filesDir + "/pengyipeng" + this.imageExtension;
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc,
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: this.pengtitle,
      description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
    });
    sharableTarget.share(shareData);
/*
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

      // 1. 使用 rawfile 方案获取资源
      const rawfileName = 'share.png'; // rawfile 目录下的文件名
      const fdResult = await context.resourceManager.getRawFd(rawfileName);

      // 2. 直接使用文件描述符构建 URI
      const fdPath = `fd://${fdResult.fd}`;

      // 3. 构建分享数据
      let shareData: systemShare.SharedData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.networkVideoSrc,
        thumbnailUri: fdPath,
        title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
        description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
      });

      // 4. 执行分享
      sharableTarget.share(shareData);

    } catch (error) {
      console.error("分享缩略图处理失败:", error);
      // 后备方案：不使用缩略图
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let shareData = new systemShare.SharedData({
        utd: utd.UniformDataType.HYPERLINK,
        content: this.networkVideoSrc,
        title: context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id),
        description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
      });
      sharableTarget.share(shareData);
    }*/
  }

  // 修改事件监听与解绑逻辑
  private whiteListening() {
    if (this.isNoListening()) {
      harmonyShare.on('knockShare', (sharableTarget: harmonyShare.SharableTarget) => {
        // 在回调中检查 networkVideoSrc 是否为有效链接
        if (!this.isValidUrl(this.networkVideoSrc)) {
          sharableTarget.clarifyNonShare({ message: this.context.resourceManager.getStringSync($r('app.string.nopengsystem').id) });
        } else {
          this.whiteCallback(sharableTarget);
        }
      });
      this.whiteStatus = true;
    } else {
      promptAction.showToast({ message: this.context.resourceManager.getStringSync($r('app.string.nopeng').id) });
    }
  }

  private whiteDisablingListening() {
    harmonyShare.off('knockShare', this.whiteCallback);
    this.whiteStatus = false;
  }

  private immersiveCallback = (sharableTarget: harmonyShare.SharableTarget): void => {
    // 直接处理分享数据（假设数据已通过其他方式传递）
    const sharedUrl = AppStorage.get<string>('sharedVideoUrl');
    if (sharedUrl && this.isValidUrl(sharedUrl)) {
      this.networkVideoSrc = sharedUrl;
      //this.controller.start();
      AppStorage.delete('sharedVideoUrl');
    }
    // 更新显示的图片为当前缓存的图片
    // 直接获取最新的 context，而不是使用全局变量
    const currentContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const imagePath = currentContext.filesDir + "/pengyipeng" + this.imageExtension;

    // 更新调试数据到状态变量
    this.debugImagePath = imagePath;
    this.debugImageExtension = this.imageExtension;
    this.debugSharepng = this.sharepng;
    this.debugFilesDir = currentContext.filesDir;
    this.debugFileExists = false;
    this.debugFileStat = '';
    this.debugFileError = '';

    console.log('=== 隔空投送调试 ===');
    console.log('正在检查的图片路径: ' + imagePath);
    console.log('当前的 imageExtension: ' + this.imageExtension);
    console.log('当前的 sharepng: ' + this.sharepng);
    console.log('当前 context.filesDir: ' + currentContext.filesDir);

    // 列出 filesDir 中的所有文件
    try {
      const files = fileIo.listFileSync(currentContext.filesDir);
      this.debugFilesList = JSON.stringify(files);
      console.log('filesDir 中的文件列表: ' + JSON.stringify(files));
    } catch (e) {
      this.debugFilesList = '列出文件失败: ' + JSON.stringify(e);
      console.log('列出文件失败: ' + JSON.stringify(e));
    }

    console.log('====================');
    // 检查文件是否存在,存在才更新
    try {
      const stat = fileIo.statSync(imagePath);
      this.debugFileStat = `size: ${stat.size}, isFile: ${stat.isFile()}, isDirectory: ${stat.isDirectory()}`;
      console.log('文件存在，状态: ' + JSON.stringify(stat));
      if (stat.isFile()) {
        this.debugFileExists = true;
        this.sharepng = 'file://' + imagePath;
        console.log('图片文件已找到并更新: ' + imagePath);
        // 如果是横屏+隔空模式，获取主颜色
        if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
          this.extractMainColor();
        }
      }
    } catch (error) {
      // 文件不存在,不更新图片
      this.debugFileError = JSON.stringify(error);
      console.log('=== 文件未找到 ===');
      console.log('路径: ' + imagePath);
      console.log('错误信息: ' + JSON.stringify(error));
      console.log('==================');
    }
    // 根据当前图片扩展名设置文件路径（使用相同的 currentContext）
    let filePath = currentContext.filesDir + "/pengyipeng" + this.imageExtension;
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.networkVideoSrc,
      thumbnailUri: fileUri.getUriFromPath(filePath),
      title: this.pengtitle,
      description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
    });
    sharableTarget.share(shareData);
  }

  // 添加一个方法来获取图片的宽高比
  private async getImageAspectRatio(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let imageSource: image.ImageSource;

      console.log('=== getImageAspectRatio 开始 ===');
      console.log('当前 sharepng: ' + this.sharepng);
      console.log('当前 imageExtension: ' + this.imageExtension);

      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // 如果是网络图片，使用本地缓存文件
        let imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        console.log('使用网络图片缓存路径: ' + imagePath);
        imageSource = image.createImageSource(imagePath);
      } else if (this.sharepng.startsWith('file://')) {
        // 如果是本地文件
        let filePath = this.sharepng.substring(7); // 移除 'file://' 前缀
        console.log('使用本地文件路径: ' + filePath);
        imageSource = image.createImageSource(filePath);
      } else {
        // 如果是资源文件
        console.log('使用资源文件: ' + this.sharepng);
        imageSource = image.createImageSource(this.sharepng);
      }

      const info = await imageSource.getImageInfo();
      console.log('获取到的图片信息: ' + JSON.stringify(info));

      if (info && info.size && info.size.width > 0 && info.size.height > 0) {
        this.imageAspectRatio = info.size.width / info.size.height;
        this.isImageLoaded = true;
        console.log('宽高比: ' + this.imageAspectRatio);
        console.log('图片宽度: ' + info.size.width);
        console.log('图片高度: ' + info.size.height);

        // 如果是横屏图片，自动获取主颜色
        if (this.imageAspectRatio >= 1) {
          console.log('检测到横屏图片，开始获取主颜色');
          await this.extractMainColor();
          console.log('主颜色获取完成: ' + this.mainColor);
        } else {
          console.log('不是横屏图片，不获取主颜色');
        }
      } else {
        console.log('图片信息无效');
      }
      console.log('=== getImageAspectRatio 结束 ===');
    } catch (error) {
      console.error('Failed to get image info: ' + JSON.stringify(error));
      // 如果获取失败，默认按原始方式处理
      this.isImageLoaded = true;
    }
  }

  // 使用 ColorPicker 获取图片主颜色
  private async extractMainColor(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let pixelMap: PixelMap;

      if (this.localPixelMap) {
        // 使用本地选择的 PixelMap
        pixelMap = this.localPixelMap;
      } else {
        // 从文件加载 PixelMap
        let imagePath: string;
        if (this.sharepng.startsWith('file://')) {
          imagePath = this.sharepng.substring(7); // 移除 'file://' 前缀
        } else {
          imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        }

        const imageSource = image.createImageSource(imagePath);
        pixelMap = await imageSource.createPixelMap();
      }

      // 使用 ColorPicker 获取主颜色
      effectKit.createColorPicker(pixelMap, (err: BusinessError, colorPicker: effectKit.ColorPicker) => {
        if (err) {
          console.error('创建 ColorPicker 失败: ' + err.message);
          this.mainColor = '#FFFFFF';
          return;
        }

        try {
          const mainColor = colorPicker.getMainColorSync();
          // 将颜色转换为 ARGB 格式的十六进制字符串
          const alpha: string = (mainColor.alpha ?? 255).toString(16).padStart(2, '0');
          const red: string = (mainColor.red ?? 255).toString(16).padStart(2, '0');
          const green: string = (mainColor.green ?? 255).toString(16).padStart(2, '0');
          const blue: string = (mainColor.blue ?? 255).toString(16).padStart(2, '0');
          this.mainColor = `#${alpha}${red}${green}${blue}`;
          console.log('获取到主颜色: ' + this.mainColor);

          // 同时更新顶部背景颜色
          this.updateTopBgColor();
        } catch (error) {
          console.error('获取主颜色失败: ' + JSON.stringify(error));
          this.mainColor = '#FFFFFF';
        }
      });
    } catch (error) {
      console.error('获取主颜色失败: ' + JSON.stringify(error));
      // 失败时使用默认白色
      this.mainColor = '#FFFFFF';
    }
  }

  // 获取顶部背景颜色
  private async extractTopBgColor(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let pixelMap: PixelMap;

      if (this.localPixelMap) {
        pixelMap = this.localPixelMap;
      } else {
        let imagePath: string;
        if (this.sharepng.startsWith('file://')) {
          imagePath = this.sharepng.substring(7);
        } else {
          imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        }
        const imageSource = image.createImageSource(imagePath);
        pixelMap = await imageSource.createPixelMap();
      }

      effectKit.createColorPicker(pixelMap, (err: BusinessError, colorPicker: effectKit.ColorPicker) => {
        if (err) {
          console.error('创建 ColorPicker 失败: ' + err.message);
          this.topBgColor = '#FFFFFF';
          return;
        }

        try {
          const mainColor = colorPicker.getMainColorSync();
          const alpha: string = (mainColor.alpha ?? 255).toString(CommonConstants.HEXADECIMAL);
          const red: string = (mainColor.red ?? 255).toString(CommonConstants.HEXADECIMAL);
          const green: string = (mainColor.green ?? 255).toString(CommonConstants.HEXADECIMAL);
          const blue: string = (mainColor.blue ?? 255).toString(CommonConstants.HEXADECIMAL);
          this.topBgColor = `#${alpha}${red}${green}${blue}`;
          console.log('获取到顶部背景颜色: ' + this.topBgColor);
        } catch (error) {
          console.error('获取顶部背景颜色失败: ' + JSON.stringify(error));
          this.topBgColor = '#FFFFFF';
        }
      });
    } catch (error) {
      console.error('获取顶部背景颜色失败: ' + JSON.stringify(error));
      this.topBgColor = '#FFFFFF';
    }
  }

  // 更新顶部背景颜色（带动画）
  private updateTopBgColor() {
    this.getUIContext().animateTo({
      duration: CommonConstants.SWIPER_DURATION1,
      curve: Curve.Linear,
      iterations: CommonConstants.ANIMATION_ITERATIONS
    }, () => {
      this.topBgColor = this.mainColor;
    });
  }

  build() {
    Column() {
      // 根据断点选择不同的布局
      if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
        // lg/xl 断点：使用左右两栏布局
        Row() {
          // 左侧：预览区域（胶囊按钮 + Stack 图片预览）
          Column() {
            Scroll() {
              Column() {
                // 布局选择胶囊按钮
                DeviceSegmentButton({
                  initialIndex: this.selectedShareMode,
                  onIndexChange: (index: number) => {
                    this.handleShareModeChange(index);
                  }
                })
                  .margin({ top: 10, bottom: 20 })

                Stack() {
                  // 横屏图片 + 碰一碰模式：使用卡片样式
                  if (this.imageAspectRatio >= 1 && this.selectedShareMode === 0) {
                    // 横屏图片 + 碰一碰模式：使用主颜色背景填充整个卡片
                    Column() {
                      // 图片
                      if (this.localPixelMap) {
                        Image(this.localPixelMap)
                          .width('100%')
                          .aspectRatio(1.5)
                          .margin({ bottom: 0 })
                          .objectFit(ImageFit.Cover)
                          .borderRadius(20)
                          .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                          .onComplete(() => {
                            this.getImageAspectRatio();
                            this.extractMainColor(); // 获取主颜色
                          })

                      } else {
                        Image(this.sharepng)
                          .width('100%')
                          .aspectRatio(1.5)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(20)
                          .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                          .onComplete(() => {
                            this.getImageAspectRatio();
                            this.extractMainColor(); // 获取主颜色
                          })
                      }

                      // 标题
                      Text(this.pengtitle)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 12 ,bottom: 8 })
                        .blur(0) // 文字不模糊

                      // 描述
                      Text(this.currentDescription)
                        .fontSize(16)
                        .fontColor(0xA3A3A3)
                        //.fontWeight(FontWeight.Medium)
                        .margin({ bottom: 5 })
                        .blur(0) // 文字不模糊

                      Image($r('app.media.CIcon'))
                        .width(20)
                        .height(20)
                        .margin({ bottom: 12 })
                        .blur(0) // 图标不模糊
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: 350 })
                    .height('auto')
                    .backgroundColor(this.mainColor) // 使用主颜色填充整个卡片
                    .borderRadius(20)
                    .border({ width: 2, color: 0xCCCCCC })
                    .alignItems(HorizontalAlign.Center)
                    .justifyContent(FlexAlign.Start)
                  } else if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) { // 横屏+隔空
                    Column() {
                      // 图片
                      if (this.localPixelMap) {
                        Image(this.localPixelMap)
                          .width('100%')
                          .aspectRatio(1.4)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(10)
                      } else {
                        Image(this.sharepng)
                          .width('100%')
                          .aspectRatio(1.4)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(10)
                          .onComplete(() => {
                            this.getImageAspectRatio();
                          })
                      }

                      // 标题
                      Text(this.pengtitle)
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 12 , bottom: 8 })
                        .blur(0) // 文字不模糊

                      // 描述
                      Text(this.currentDescription)
                        .fontSize(16)
                        .fontColor(0xA3A3A3)
                        //.fontWeight(FontWeight.Medium)
                        .margin({ bottom: 5 })
                        .blur(0) // 文字不模糊

                      Image($r('app.media.CIcon'))
                        .width(20)
                        .height(20)
                        .blur(0) // 图标不模糊
                        .margin({ bottom: 8 })
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: 350 })
                    .height('auto')
                    .padding(8)
                    .backgroundColor(0xFFFFFF)
                    .borderRadius(20)
                    .border({ width: 2, color: 0xCCCCCC })
                    .alignItems(HorizontalAlign.Center)
                    .justifyContent(FlexAlign.Start)
                  } else {
                    // 其他模式：保持原有 Stack 样式
                    // 图片区域
                    if (this.localPixelMap) {
                      // 使用 PixelMap 显示本地选择的图片
                      Column() {
                        Image(this.localPixelMap)
                          .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                          .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                          .objectFit(ImageFit.Contain)
                          .blur(0)
                          .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                          .borderRadius(20)
                      }
                      .border({ width: 1, color: 0xCCCCCC })
                      .borderRadius(20)
                      .alignSelf(ItemAlign.Start)
                      .justifyContent(FlexAlign.Center)
                      .margin({ top: 0 })
                    } else {
                      // 使用 URL 显示图片
                      Column() {
                        Image(this.sharepng)
                          .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                          .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                          .objectFit(ImageFit.Contain)
                          .blur(0)
                          .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                          .borderRadius(20)
                          .onComplete(() => {
                            this.getImageAspectRatio();
                          })
                      }
                      .border({ width: 1, color: 0xCCCCCC })
                      .borderRadius(20)
                      .alignSelf(ItemAlign.Start)
                      .justifyContent(FlexAlign.Center)
                      .margin({ top: 0 })
                    }
                    // 文字区域
                    Column() {
                      Text(this.pengtitle)
                        .fontWeight(600)
                        .fontSize('20fp')
                        .fontWeight(FontWeight.Bold)
                      Text(this.currentDescription)
                        .fontWeight(400)
                        .fontSize('13vp')
                        .margin({ top: 5, bottom: 5 })
                        .fontWeight(FontWeight.Medium)
                        .opacity(0.5)
                        .fontColor($r('app.color.version_color_182431'))
                      Image($r('app.media.CIcon'))
                        .width(20)
                        .height(20)
                        .margin({ top: 5, bottom: 10 })
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Center)
                    .align(Alignment.Bottom)
                    .constraintSize({ maxWidth: '100%' })
                  }
                }
                .width('100%')
                .height('auto')
                .alignContent(Alignment.Bottom)
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .padding({ left: 16, right: 16 })
            }
            .width('100%')
            .layoutWeight(1)
          }
          .width('45%')
          .height('100%')
          .padding({ right: 10 })

          // 右侧：其他所有内容（卡片容器 + 碰一碰引导）
          Scroll() {
            Column() {
              // 卡片容器：包含从图片组件往下到碰一碰引导提示组件以上的所有内容
              Column() {
                // 调试数据显示区域
                Column() {
                  Text('背景图片调试信息')
                    .fontSize(14)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(0xFF0000)
                    .margin({ bottom: 8 })
                  Text('图片路径: ' + this.debugImagePath)
                    .fontSize(10)
                    .fontColor(0x666666)
                    .margin({ bottom: 4 })
                  Text('扩展名: ' + this.debugImageExtension)
                    .fontSize(10)
                    .fontColor(0x666666)
                    .margin({ bottom: 4 })
                  Text('sharepng: ' + this.debugSharepng)
                    .fontSize(10)
                    .fontColor(0x666666)
                    .margin({ bottom: 4 })
                  Text('filesDir: ' + this.debugFilesDir)
                    .fontSize(10)
                    .fontColor(0x666666)
                    .margin({ bottom: 4 })
                  Text('文件列表: ' + this.debugFilesList)
                    .fontSize(10)
                    .fontColor(0x666666)
                    .margin({ bottom: 4 })
                  Text('文件存在: ' + (this.debugFileExists ? '是' : '否'))
                    .fontSize(10)
                    .fontColor(this.debugFileExists ? 0x00FF00 : 0xFF0000)
                    .margin({ bottom: 4 })
                  if (this.debugFileStat) {
                    Text('文件状态: ' + this.debugFileStat)
                      .fontSize(10)
                      .fontColor(0x666666)
                      .margin({ bottom: 4 })
                  }
                  if (this.debugFileError) {
                    Text('错误信息: ' + this.debugFileError)
                      .fontSize(10)
                      .fontColor(0xFF0000)
                      .margin({ bottom: 4 })
                  }
                }
                .width('100%')
                .backgroundColor(0xFFFFF0)
                .borderRadius(8)
                .padding(8)
                .margin({ bottom: 16 })
                .border({ width: 1, color: 0xFFCCCC })

                Row()
                {
                  Text($r('app.string.sharepngon'))
                    .textAlign(TextAlign.Center)
                    .width('55%')
                    .margin({ right: 10 })
                  Button($r('app.string.choose'))
                    .height(50)
                    .width('40%')
                    .backgroundColor(0xb87cff)//紫色
                    .onClick(() => {
                      this.selectImage();
                    })
                }
                .width('100%')

                TextArea({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
                //.type(InputType.URL)
                //.backgroundColor('#FF9CCE')
                  .width('100%')
                  //.height(50)
                  .margin({ top: 10, bottom: 10 })
                  .onChange((sharepng: string) => {
                    this.sharepng = sharepng;
                    // @StorageLink 会自动同步到 AppStorage,无需手动保存
                    if (this.isValidUrl(sharepng)) {
                      this.handleImageUpdate(); // 触发图片更新逻辑
                    }
                  })

                Text($r('app.string.texton'))
                  .textAlign(TextAlign.Center)
                  .margin({ top: 5, bottom: 10 })
                Row() {
                  TextArea({ placeholder: $r('app.string.testinput') , text: this.networkVideoSrc })
                  //.type(InputType.URL)
                  //.backgroundColor('#FF9CCE')
                    .width('60%')
                    .margin({ right: 5 })
                    .onChange((networkVideoSrc: string) => {
                      // 清除之前的防抖定时器
                      clearTimeout(this.urlDebounceTimer);

                      // 设置新的防抖定时器，300ms后执行
                      this.urlDebounceTimer = setTimeout(() => {
                        // 尝试从输入文本中提取链接
                        const extractedUrl = this.extractUrlFromText(networkVideoSrc);
                        if (extractedUrl) {
                          this.networkVideoSrc = extractedUrl;
                          AppStorage.set('networkVideoSrc', extractedUrl);
                        } else {
                          this.networkVideoSrc = networkVideoSrc;
                          AppStorage.set('networkVideoSrc', networkVideoSrc);
                        }
                      }, 300);
                    })

                  Button($r('app.string.scancode'))
                  //.globalButtonStyle()
                  //.type(ButtonType.Capsule)
                  //.backgroundColor(0x66CCFF)//蓝色
                  //.backgroundColor('#0044fc')
                    .height(35)
                    .margin({ right: 2 })
                    .backgroundColor(0xFF66CC)
                    .onClick(async () => {
                      try {
                        // 定义扫码参数options
                        let options: scanBarcode.ScanOptions = {
                          scanTypes: [scanCore.ScanType.ALL],
                          enableMultiMode: true,
                          enableAlbum: true
                        };
                        // 调用扫码功能
                        scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                          // 正确获取扫描结果的字符串值
                          const originalValue: string = result.originalValue; // 假设ScanResult有originalValue属性
                          this.networkVideoSrc = originalValue;
                          promptAction.showToast({ duration: 10000, message: '扫码成功: ' + originalValue });
                        }).catch((error: BusinessError) => {
                          hilog.error(0x0001, '[Scan]',
                            `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                          promptAction.showToast({ message: '手动取消或扫码失败（PC/2in1设备暂不支持扫描二维码，请使用其它类型的设备）' });
                        });
                      } catch (error) {
                        //promptAction.showToast({ message: '扫码失败: 读取二维码信息错误； ' + error.message });
                        promptAction.showToast({ message: '扫码失败: 启动扫码服务失败' });
                        hilog.error(0x0001, '[Scan]',
                          `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
                      }
                    })
                  PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                    .backgroundColor(0xFF66CC)
                    .height(35)
                    .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                      if (PasteButtonOnClickResult.SUCCESS === result) {
                        pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                          if (err) {
                            console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                            return;
                          }
                          this.networkVideoSrc = pasteData.getPrimaryText();
                        });
                      }
                    })
                }
                .width('100%')
                .justifyContent(FlexAlign.Center)
                .margin({ top: 5, bottom: 10 })

                Text($r('app.string.pengtitleset'))
                  .textAlign(TextAlign.Center)
                  .margin({ top: 5, bottom: 10 })
                TextArea({ placeholder: $r('app.string.pengyipeng_title'), text: this.pengtitle })
                //.backgroundColor('#FF9CCE')
                  .width('55%')
                  .onChange((pengtitle: string) => {
                    this.pengtitle = pengtitle;
                   // @StorageLink 会自动同步到 AppStorage,无需手动保存
                  })
                  .margin({ top: 5, bottom: 10 })

                Column() {
                  Row()
                  {
                    /*Text($r('app.string.nowplaying'))
                      .width('55%')
                      .textAlign(TextAlign.Center)
                      .margin({ right: 10 })*/
                    Button($r('app.string.share'))
                    //.type(ButtonType.Capsule)
                      .width('40%')
                      .height(50)
                      .backgroundColor(0x66CCFF)//蓝色
                      .onClick(() => {
                        logger.info('分享按钮被点击');
                        try {
                          this.share();
                        } catch (error) {
                          logger.error(`分享按钮点击异常: ${error.message}`);
                          promptAction.showToast({ message: '分享功能异常: ' + error.message });
                        }
                      })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .padding({ bottom: 10 })



                  Text(this.networkVideoSrc)
                    .padding({ top: 10 , bottom : 10 , left : 10 , right : 10 })
                    .copyOption(CopyOptions.LocalDevice)
                    .textAlign(TextAlign.Center)//.margin({ right: 10 })
                    .width('100%')
                }
                .width('100%')  // 控制内容区域宽度
                .alignItems(HorizontalAlign.Center) // 内容水平居中
                .margin({ top: 10 })
                //.height('100%')
              }
              .width('100%')
              .backgroundColor('#F5F5F5')
              .borderRadius(16)
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .margin({ bottom: 20 })

              //碰一碰提示
              if (this.currentBreakpoint !== 'lg' && this.currentBreakpoint !== 'xl') {
                Text($r('app.string.nowplayingon'))
                  .padding({ top: 20 , left: 24, right: 24 })
                  .maxLines(2)
                  .fontSize(11)
                  .maxFontScale(1.75)
                  .width('100%')
                  .constraintSize({ minHeight: 16 })
                  .fontColor($r('sys.color.font_secondary'))
                  .fontFamily('HarmonyHeiTi')
                  .textAlign(TextAlign.Center)
                KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
                  .padding({ top: 2 })
              } else {
                // 大屏设备提示
                Column() {
                  Text('平板和PC/2in1设备不支持碰一碰传送，\n已为您自动选择隔空传送预览。')
                    .fontSize(11)
                    .maxFontScale(1.75)
                    .width('100%')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontFamily('HarmonyHeiTi')
                    .textAlign(TextAlign.Center)
                    .lineHeight(18)
                    .padding({ top: 20, bottom: 20 })
                }
                .width('100%')
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .padding({ left: 10, right: 16 })
          }
          .width('55%')
          .height('100%')
        }
        .width('100%')
        .height('100%')
      } else {
        // 其他断点：保持原有的垂直布局
        Scroll()
        {
          Column() {
            // 布局选择胶囊按钮
            DeviceSegmentButton({
              initialIndex: this.selectedShareMode,
              onIndexChange: (index: number) => {
                this.handleShareModeChange(index);
              }
            })
              .margin({ top: 10, bottom: 5 })
          Stack() {
            // 横屏图片 + 碰一碰模式：使用卡片样式
            if (this.imageAspectRatio >= 1 && this.selectedShareMode === 0) {
              // 横屏图片 + 碰一碰模式：使用主颜色背景填充整个卡片
              Column() {
                // 图片
                if (this.localPixelMap) {
                  Image(this.localPixelMap)
                    .width('100%')
                    .aspectRatio(1.5)
                    .margin({ bottom: 0 })
                    .objectFit(ImageFit.Cover)
                    .borderRadius(20)
                    .linearGradientBlur(60,
                      { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                    .onComplete(() => {
                      this.getImageAspectRatio();
                      this.extractMainColor(); // 获取主颜色
                    })

                } else {
                  Image(this.sharepng)
                    .width('100%')
                    .aspectRatio(1.5)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(20)
                    .linearGradientBlur(60,
                      { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                    .onComplete(() => {
                      this.getImageAspectRatio();
                      this.extractMainColor(); // 获取主颜色
                    })
                }

                // 标题
                Text(this.pengtitle)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 12 ,bottom: 8 })
                  .blur(0) // 文字不模糊

                // 描述
                Text(this.currentDescription)
                  .fontSize(16)
                  .fontColor(0xA3A3A3)
                  //.fontWeight(FontWeight.Medium)
                  .margin({ bottom: 5 })
                  .blur(0) // 文字不模糊

                Image($r('app.media.CIcon'))
                  .width(20)
                  .height(20)
                  .margin({ bottom: 12 })
                  .blur(0) // 图标不模糊
              }
              .width('100%')
              .constraintSize({ maxWidth: 350 })
              .height('auto')
              .backgroundColor(this.mainColor) // 使用主颜色填充整个卡片
              .borderRadius(20)
              .border({ width: 2, color: 0xCCCCCC })
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Start)
            } else if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) { // 横屏+隔空
              Column() {
                // 图片
                if (this.localPixelMap) {
                  Image(this.localPixelMap)
                    .width('100%')
                    .aspectRatio(1.4)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(10)
                } else {
                  Image(this.sharepng)
                    .width('100%')
                    .aspectRatio(1.4)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(10)
                    .onComplete(() => {
                      this.getImageAspectRatio();
                    })
                }

                // 标题
                Text(this.pengtitle)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .margin({ top: 12 , bottom: 8 })
                  .blur(0) // 文字不模糊

                // 描述
                Text(this.currentDescription)
                  .fontSize(16)
                  .fontColor(0xA3A3A3)
                  //.fontWeight(FontWeight.Medium)
                  .margin({ bottom: 5 })
                  .blur(0) // 文字不模糊

                Image($r('app.media.CIcon'))
                  .width(20)
                  .height(20)
                  .blur(0) // 图标不模糊
                  .margin({ bottom: 8 })
              }
              .width('100%')
              .constraintSize({ maxWidth: 350 })
              .height('auto')
              .padding(8)
              .backgroundColor(0xFFFFFF)
              .borderRadius(20)
              .border({ width: 2, color: 0xCCCCCC })
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Start)
            } else {
              // 其他模式：保持原有 Stack 样式
              // 图片区域
              if (this.localPixelMap) {
                // 使用 PixelMap 显示本地选择的图片
                Column() {
                  Image(this.localPixelMap)
                    .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                    .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                    .objectFit(ImageFit.Contain)
                    .blur(0)
                    .linearGradientBlur(60,
                      { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                    .borderRadius(20)
                }
                .border({ width: 1, color: 0xCCCCCC })
                .borderRadius(20)
                .alignSelf(ItemAlign.Start)
                .justifyContent(FlexAlign.Center)
                .margin({ top: 0 })
              } else {
                // 使用 URL 显示图片
                Column() {
                  Image(this.sharepng)
                    .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                    .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                    .objectFit(ImageFit.Contain)
                    .blur(0)
                    .linearGradientBlur(60,
                      { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                    .borderRadius(20)
                    .onComplete(() => {
                      this.getImageAspectRatio();
                    })
                }
                .border({ width: 1, color: 0xCCCCCC })
                .borderRadius(20)
                .alignSelf(ItemAlign.Start)
                .justifyContent(FlexAlign.Center)
                .margin({ top: 0 })
              }
              // 文字区域
              Column() {
                Text(this.pengtitle)
                  .fontWeight(600)
                  .fontSize('20fp')
                  .fontWeight(FontWeight.Bold)
                Text(this.currentDescription)
                  .fontWeight(400)
                  .fontSize('13vp')
                  .margin({ top: 5, bottom: 5 })
                  .fontWeight(FontWeight.Medium)
                  .opacity(0.5)
                  .fontColor($r('app.color.version_color_182431'))
                Image($r('app.media.CIcon'))
                  .width(20)
                  .height(20)
                  .margin({ top: 5, bottom: 10 })
              }
              .width('100%')
              .alignItems(HorizontalAlign.Center)
              .align(Alignment.Bottom)
              .constraintSize({ maxWidth: '100%' })
            }
          }
          .width('100%')
          .height('auto')
          .alignContent(Alignment.Bottom)
          .margin({ bottom: 20 })

          // 卡片容器：包含从图片组件往下到碰一碰引导提示组件以上的所有内容
          Column() {
            // 调试数据显示区域
            Column() {
              Text('背景图片调试信息')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(0xFF0000)
                .margin({ bottom: 8 })
              Text('图片路径: ' + this.debugImagePath)
                .fontSize(10)
                .fontColor(0x666666)
                .margin({ bottom: 4 })
              Text('扩展名: ' + this.debugImageExtension)
                .fontSize(10)
                .fontColor(0x666666)
                .margin({ bottom: 4 })
              Text('sharepng: ' + this.debugSharepng)
                .fontSize(10)
                .fontColor(0x666666)
                .margin({ bottom: 4 })
              Text('filesDir: ' + this.debugFilesDir)
                .fontSize(10)
                .fontColor(0x666666)
                .margin({ bottom: 4 })
              Text('文件列表: ' + this.debugFilesList)
                .fontSize(10)
                .fontColor(0x666666)
                .margin({ bottom: 4 })
              Text('文件存在: ' + (this.debugFileExists ? '是' : '否'))
                .fontSize(10)
                .fontColor(this.debugFileExists ? 0x00FF00 : 0xFF0000)
                .margin({ bottom: 4 })
              if (this.debugFileStat) {
                Text('文件状态: ' + this.debugFileStat)
                  .fontSize(10)
                  .fontColor(0x666666)
                  .margin({ bottom: 4 })
              }
              if (this.debugFileError) {
                Text('错误信息: ' + this.debugFileError)
                  .fontSize(10)
                  .fontColor(0xFF0000)
                  .margin({ bottom: 4 })
              }
            }
            .width('100%')
            .backgroundColor(0xFFFFF0)
            .borderRadius(8)
            .padding(8)
            .margin({ bottom: 16 })
            .border({ width: 1, color: 0xFFCCCC })

            Row()
            {
              Text($r('app.string.sharepngon'))
                .textAlign(TextAlign.Center)
                .width('55%')
                .margin({ right: 10 })
              Button($r('app.string.choose'))
                .height(50)
                .width('40%')
                .backgroundColor(0xb87cff)//紫色
                .onClick(() => {
                  this.selectImage();
                })
            }
            .width('100%')

            TextArea({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
            //.type(InputType.URL)
            //.backgroundColor('#FF9CCE')
              .width('100%')
              //.height(50)
              .margin({ top: 10, bottom: 10 })
              .onChange((sharepng: string) => {
                this.sharepng = sharepng;
                if (this.isValidUrl(sharepng)) {
                  this.handleImageUpdate(); // 触发图片更新逻辑
                }
              })

            Text($r('app.string.texton'))
              .textAlign(TextAlign.Center)
              .margin({ top: 5, bottom: 10 })
            Row() {
              TextArea({ placeholder: $r('app.string.testinput') , text: this.networkVideoSrc })
              //.type(InputType.URL)
              //.backgroundColor('#FF9CCE')
                .width('60%')
                .margin({ right: 5 })
                .onChange((networkVideoSrc: string) => {
                  // 清除之前的防抖定时器
                  clearTimeout(this.urlDebounceTimer);

                  // 设置新的防抖定时器，300ms后执行
                  this.urlDebounceTimer = setTimeout(() => {
                    // 尝试从输入文本中提取链接
                    const extractedUrl = this.extractUrlFromText(networkVideoSrc);
                    if (extractedUrl) {
                      this.networkVideoSrc = extractedUrl;
                      AppStorage.set('networkVideoSrc', extractedUrl);
                    } else {
                      this.networkVideoSrc = networkVideoSrc;
                      AppStorage.set('networkVideoSrc', networkVideoSrc);
                    }
                  }, 300);
                })

              Button($r('app.string.scancode'))
              //.globalButtonStyle()
              //.type(ButtonType.Capsule)
              //.backgroundColor(0x66CCFF)//蓝色
              //.backgroundColor('#0044fc')
                .height(35)
                .margin({ right: 2 })
                .backgroundColor(0xFF66CC)
                .onClick(async () => {
                  try {
                    // 定义扫码参数options
                    let options: scanBarcode.ScanOptions = {
                      scanTypes: [scanCore.ScanType.ALL],
                      enableMultiMode: true,
                      enableAlbum: true
                    };
                    // 调用扫码功能
                    scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
                      // 正确获取扫描结果的字符串值
                      const originalValue: string = result.originalValue; // 假设ScanResult有originalValue属性
                      this.networkVideoSrc = originalValue;
                      promptAction.showToast({ duration: 10000, message: '扫码成功: ' + originalValue });
                    }).catch((error: BusinessError) => {
                      hilog.error(0x0001, '[Scan]',
                        `Failed to get ScanResult by promise with options. Code: ${error.code}, message: ${error.message}`);
                      promptAction.showToast({ message: '手动取消或扫码失败（PC/2in1设备暂不支持扫描二维码，请使用其它类型的设备）' });
                    });
                  } catch (error) {
                    //promptAction.showToast({ message: '扫码失败: 读取二维码信息错误； ' + error.message });
                    promptAction.showToast({ message: '扫码失败: 启动扫码服务失败' });
                    hilog.error(0x0001, '[Scan]',
                      `Failed to start the scanning service. Code:${error.code}, message: ${error.message}`);
                  }
                })
              PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                .backgroundColor(0xFF66CC)
                .height(35)
                .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                  if (PasteButtonOnClickResult.SUCCESS === result) {
                    pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                      if (err) {
                        console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                        return;
                      }
                      this.networkVideoSrc = pasteData.getPrimaryText();
                    });
                  }
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .margin({ top: 5, bottom: 10 })

            Row()
            {
              Text($r('app.string.pengtitleset'))
                .width('40%')
                .textAlign(TextAlign.Center)
                .margin({ right: 10 })
              TextArea({ placeholder: $r('app.string.pengyipeng_title'), text: this.pengtitle })
              //.backgroundColor('#FF9CCE')
                .width('55%')
                .onChange((pengtitle: string) => {
                  this.pengtitle = pengtitle;
                  AppStorage.set('pengtitle', pengtitle);
                })
            }
            .margin({ top: 10 })
            .width('100%')  // 控制内容区域宽度
            Column() {
              Row()
              {
                Button($r('app.string.share'))
                //.type(ButtonType.Capsule)
                  .width('40%')
                  .height(50)
                  .backgroundColor(0x66CCFF)//蓝色
                  .onClick(() => {
                    logger.info('分享按钮被点击');
                    try {
                      this.share();
                    } catch (error) {
                      logger.error(`分享按钮点击异常: ${error.message}`);
                      promptAction.showToast({ message: '分享功能异常: ' + error.message });
                    }
                  })
              }
              .width('100%')
              .justifyContent(FlexAlign.Center)
              .padding({ bottom: 10 })


              Text(this.networkVideoSrc)
                .padding({ top: 10 , bottom : 10 , left : 10 , right : 10 })
                .copyOption(CopyOptions.LocalDevice)
                .textAlign(TextAlign.Center)//.margin({ right: 10 })
                .width('100%')
            }
            .width('100%')  // 控制内容区域宽度
            .alignItems(HorizontalAlign.Center) // 内容水平居中
            .margin({ top: 10 })
            //.height('100%')
          }
          .width('100%')
          .backgroundColor('#F5F5F5')
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .margin({ bottom: 20 })

          //碰一碰提示
          if (this.currentBreakpoint !== 'lg' && this.currentBreakpoint !== 'xl') {
            Text($r('app.string.nowplayingon'))
              .padding({ top: 20 , left: 24, right: 24 })
              .maxLines(2)
              .fontSize(11)
              .maxFontScale(1.75)
              .width('100%')
              .constraintSize({ minHeight: 16 })
              .fontColor($r('sys.color.font_secondary'))
              .fontFamily('HarmonyHeiTi')
              .textAlign(TextAlign.Center)
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
              .padding({ top: 2 })
          } else {
            // 大屏设备提示
            Column() {
              Text('平板和PC/2in1设备不支持碰一碰传送，\n已为您自动选择隔空传送预览。')
                .fontSize(11)
                .maxFontScale(1.75)
                .width('100%')
                .fontColor($r('sys.color.font_secondary'))
                .fontFamily('HarmonyHeiTi')
                .textAlign(TextAlign.Center)
                .lineHeight(18)
                .padding({ top: 20, bottom: 20 })
            }
            .width('100%')
          }
          }
          .width('90%')  // 控制内容区域宽度
          .alignItems(HorizontalAlign.Center) // 内容水平居中
          .margin({ top: 10 })
          //.height('100%')
        }
        .width('90%')
      }
    }
    .width(CommonConstants.FULL_PARENT)
    .height(CommonConstants.FULL_PARENT)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.topBgColor, CommonConstants.START_GRADIENT_RANGE], [Color.White, CommonConstants.END_GRADIENT_RANGE]]
    })
    .padding({ top: this.topSafeHeight })
  }

  private isNoListening() {
    return !this.whiteStatus;
  }

  // 处理胶囊按钮选择变化
  private handleShareModeChange(index: number) {
    this.selectedShareMode = index;
    // 根据选中的模式更新描述
    if (index === 1) {
      // 隔空传送模式
      this.currentDescription = $r('app.string.gekong_description');
    } else {
      // 碰一碰模式
      this.currentDescription = $r('app.string.pengyipeng_description');
    }
  }
}