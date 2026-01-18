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
import router from '@ohos.router';
import { image } from '@kit.ImageKit';

//本地
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import MediaFileUri from '../media/MediaFileUri';
import KnockShareGuideCard, { CardRes } from '../model/KnockShareGuideCard';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

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
  @State sharepng: string = 'https://www.hnyqwq.cn/hvideo/share.png'
  //@State networkPreviewUri: Resource = $r('app.media.homepageback');
  @State savefileUri: string = ' ';
  @State currentFitMode: ImageFit = ImageFit.Auto; // 当前填充模式
  @State isControls: boolean = false; // 控制栏显示状态
  @State handlePopup: boolean = false; // 气泡提示（Popup）
  @State enableShortcutKey: boolean = true; //设置组件支持快捷键响应。
  @State pengtitle: string = ' ';//碰一碰分享标题
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
        // 根据URL确定图片扩展名（再次确认）
        this.updateImageExtension();

        // 先删除旧文件（如果存在）
        try {
          await fs.unlink(filesDir + '/pengyipeng' + this.imageExtension);
        } catch (e) {
          // 文件不存在是正常情况，忽略错误
        }

        // 下载新文件
        await request.downloadFile(context, {
          url: this.sharepng,
          filePath: filesDir + '/pengyipeng' + this.imageExtension
        });

        console.log('Image downloaded successfully as ' + this.imageExtension);
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
    this.DownloadToSandbox();
    this.whiteListening()
    this.immersiveListening();
    let context = getContext(this);

    //碰一碰标题
    this.pengtitle = this.context.resourceManager.getStringSync($r('app.string.pengyipeng_title').id);

    // 建议调整顺序确保实时参数优先
    const params = router.getParams() as Record<string, string>;
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
    console.log('=== 隔空投送调试 ===');
    console.log('正在检查的图片路径: ' + imagePath);
    console.log('当前的 imageExtension: ' + this.imageExtension);
    console.log('当前的 sharepng: ' + this.sharepng);
    console.log('当前 context.filesDir: ' + currentContext.filesDir);

    // 列出 filesDir 中的所有文件
    try {
      const files = fileIo.listFileSync(currentContext.filesDir);
      console.log('filesDir 中的文件列表: ' + JSON.stringify(files));
    } catch (e) {
      console.log('列出文件失败: ' + JSON.stringify(e));
    }

    console.log('====================');
    // 检查文件是否存在,存在才更新
    try {
      const stat = fileIo.statSync(imagePath);
      console.log('文件存在，状态: ' + JSON.stringify(stat));
      if (stat.isFile()) {
        this.sharepng = 'file://' + imagePath;
        console.log('图片文件已找到并更新: ' + imagePath);
      }
    } catch (error) {
      // 文件不存在,不更新图片
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
      
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // 如果是网络图片，使用本地缓存文件
        let imagePath = context.filesDir + '/pengyipeng' + this.imageExtension;
        imageSource = image.createImageSource(imagePath);
      } else if (this.sharepng.startsWith('file://')) {
        // 如果是本地文件
        let filePath = this.sharepng.substring(7); // 移除 'file://' 前缀
        imageSource = image.createImageSource(filePath);
      } else {
        // 如果是资源文件
        imageSource = image.createImageSource(this.sharepng);
      }

      const info = await imageSource.getImageInfo();
      if (info && info.size && info.size.width > 0 && info.size.height > 0) {
        this.imageAspectRatio = info.size.width / info.size.height;
        this.isImageLoaded = true;
      }
    } catch (error) {
      console.error('Failed to get image info: ' + JSON.stringify(error));
      // 如果获取失败，默认按原始方式处理
      this.isImageLoaded = true;
    }
  }

  build() {
    Scroll()
    {
      Column() {

        Stack() {
          // 根据宽高比动态决定图片尺寸
          if (this.localPixelMap) {
            // 使用 PixelMap 显示本地选择的图片
            Column() {
              Image(this.localPixelMap)
                .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                .height(this.imageAspectRatio < 1 ? 'auto' : '80%')
                .objectFit(ImageFit.Contain)
                .blur(0)
                .linearGradientBlur(this.imageAspectRatio < 1 ? 60 : 60,
                  { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                .borderRadius(20)
            }
            .border({ width: 1, color: 0xCCCCCC })
            .borderRadius(20)
            .margin({ top: this.imageAspectRatio < 1 ? 0 : 0 })
          } else {
            // 使用 URL 显示图片
            Column() {
              Image(this.sharepng)
                .width(this.imageAspectRatio < 1 ? '60%' : '80%')
                .height(this.imageAspectRatio < 1 ? 'auto' : '80%')
                .objectFit(ImageFit.Contain)
                .blur(0)
                .linearGradientBlur(this.imageAspectRatio < 1 ? 60 : 60,
                  { fractionStops: [[0, 0], [0, 0.6], [1, 0.8], [1, 1]], direction: GradientDirection.Bottom })
                .borderRadius(20)
                .onComplete(() => {
                  this.getImageAspectRatio();
                })
            }
            .border({ width: 1, color: 0xCCCCCC })
            .borderRadius(20)
            .margin({ top: this.imageAspectRatio < 1 ? 0 : 0 })
          }
          Text(this.pengtitle)
            .fontWeight(600)
            .fontSize('20fp')
            .margin({ bottom: 70 })
            .fontWeight(FontWeight.Bold)
          Text($r('app.string.pengyipeng_description'))
            .fontWeight(400)
            .fontSize('13vp')
            .margin({ bottom: 50 })
            .fontWeight(FontWeight.Medium)
            .opacity(0.5)
            .fontColor($r('app.color.version_color_182431'))
          Image($r('app.media.CIcon'))
            .width(20)
            .height(20)
            .margin({ bottom: 20 })
        }
        .width('100%')
        .height(this.imageAspectRatio < 1 ? 'auto' : 300)
        .alignContent(Alignment.Bottom)
        .margin({ top: (AppStorage.get<GlobalInfoModel>('GlobalInfoModel')?.statusBarHeight ?? 0) })

        // 卡片容器：包含从图片组件往下到碰一碰引导提示组件以上的所有内容
        Column() {
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
            /*.visualEffect(new hdsEffect.HdsEffectBuilder()
              .shaderEffect({
                effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                animation: {
                  duration: 4000,
                  iterations: -1,
                  autoPlay: true,
                  onFinish: () => {
                    console.info('Succeeded in finishing');
                  }
                },
                controller: this.controller,
                params: {
                  firstEdgeFlowLight: {
                    startPos: 0,
                    endPos: 1.0,
                    color: '#FF66CC',
                  },
                  secondEdgeFlowLight: {
                    startPos: 0.5,
                    endPos: 1.5,
                    color: '#b87cff',
                  }
                }
              })
              .buildEffect())*/
          Text($r('app.string.texton'))
            .textAlign(TextAlign.Center)
            .margin({ top: 5, bottom: 10 })
          Row() {
            Button($r('app.string.scancode'))
            //.globalButtonStyle()
            //.type(ButtonType.Capsule)
            //.backgroundColor(0x66CCFF)//蓝色
            //.backgroundColor('#0044fc')
              .labelStyle({ overflow: TextOverflow.Ellipsis, maxLines: 3, minFontSize: 0 })
              .width('55%')
              .height(50)
              .margin({ right: 10 })
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
            PasteButton({ icon: PasteIconStyle.LINES, text: PasteDescription.PASTE, buttonType: ButtonType.ROUNDED_RECTANGLE })
              .backgroundColor(0xFF66CC)
              //.backgroundColor(0x66CCFF)//浅蓝色
              .width('40%')
              .height(50)
              //.padding({top: 12, bottom: 12, left: 24, right: 24})
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
          .margin({ top: 5, bottom: 10 })

          TextArea({ placeholder: $r('app.string.testinput') , text: this.networkVideoSrc })
          //.type(InputType.URL)
          //.backgroundColor('#FF9CCE')
            .width('100%')
            //.height(50)
            .margin({ right: 10 })
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
            /*.visualEffect(new hdsEffect.HdsEffectBuilder()
              .shaderEffect({
                effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                animation: {
                  duration: 4000,
                  iterations: -1,
                  autoPlay: true,
                  onFinish: () => {
                    console.info('Succeeded in finishing');
                  }
                },
                controller: this.controller,
                params: {
                  firstEdgeFlowLight: {
                    startPos: 0,
                    endPos: 1.0,
                    color: '#FF66CC',
                  },
                  secondEdgeFlowLight: {
                    startPos: 0.5,
                    endPos: 1.5,
                    color: '#FFA4E5',
                  }
                }
              })
              .buildEffect())*/
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
              /*.visualEffect(new hdsEffect.HdsEffectBuilder()
                .shaderEffect({
                  effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                  animation: {
                    duration: 4000,
                    iterations: -1,
                    autoPlay: true,
                    onFinish: () => {
                      console.info('Succeeded in finishing');
                    }
                  },
                  controller: this.controller,
                  params: {
                    firstEdgeFlowLight: {
                      startPos: 0,
                      endPos: 1.0,
                      color: '#1AD0F1',
                    },
                    secondEdgeFlowLight: {
                      startPos: 0.5,
                      endPos: 1.5,
                      color: '#FFA4E5',
                    }
                  }
                })
                .buildEffect())*/
          }
          .margin({ top: 10 })
          .width('100%')  // 控制内容区域宽度
          Column() {
            Row()
            {
              Text($r('app.string.nowplaying'))
                .width('55%')
                .textAlign(TextAlign.Center)
                .margin({ right: 10 })
              Button($r('app.string.share'))
              //.type(ButtonType.Capsule)
                .width('40%')
                .height(50)
                .backgroundColor(0x66CCFF)//蓝色
                /*.visualEffect(new hdsEffect.HdsEffectBuilder()
                  .pointLight({
                    sourceType:  hdsEffect.PointLightSourceType.NONE,
                    illuminatedType: hdsEffect.PointLightIlluminatedType.DEFAULT_FEATHERING_BORDER
                  })
                  .buildEffect())
                .onTouch((event: TouchEvent) => {
                  if (event.type === TouchType.Down) {
                    this.lightSourceType = hdsEffect.PointLightSourceType.BRIGHT;
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.lightSourceType = hdsEffect.PointLightSourceType.NONE;
                  }
                })*/
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
            .padding({ bottom: 10 })


            Text(this.networkVideoSrc)
              .padding({ top: 10 , bottom : 10 , left : 10 , right : 10 })
              .copyOption(CopyOptions.LocalDevice)
              .textAlign(TextAlign.Center)//.margin({ right: 10 })
              .width('100%')

            //碰一碰提示
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
          }
          .width('100%')  // 控制内容区域宽度
          .alignItems(HorizontalAlign.Center) // 内容水平居中
          .margin({ top: 10 })
          //.height('100%')
        }
        .width('90%')
        .backgroundColor('#F5F5F5')
        .borderRadius(16)
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })

        KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
          .padding({ top: 2 })

          /*Text(this.myFileName)
            .focusable(true)
            .focusOnTouch(true)
            .fontFamily('HarmonyHeiTi-Bold')
            .textAlign(TextAlign.Start)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('Size: ' + JSON.stringify(this.myFileSize) + 'B')
            .focusable(true)
            .focusOnTouch(true)
            .fontFamily('HarmonyHeiTi')
            .textAlign(TextAlign.Start)*/
        }
        .width('90%')  // 控制内容区域宽度
        .alignItems(HorizontalAlign.Center) // 内容水平居中
        .margin({ top: 10 })
        //.height('100%')
      }
    }

  private isNoListening() {
    return !this.whiteStatus;
  }
}

/*
interface DurationObject {
  duration: number;
}

interface TimeObject {
  time: number;
}

interface FullscreenObject {
  fullscreen: boolean;
}*/