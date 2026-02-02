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
import { picker } from '@kit.CoreFileKit';
import MediaFileUri from '../media/MediaFileUri';
import KnockShareGuideCard, { CardRes } from '../model/KnockShareGuideCard';
import { GlobalInfoModel, BreakpointTypeEnum } from '../common/GlobalInfoModel';
import { DeviceSegmentButton } from '../components/DeviceSegmentButton';

// 跨设备协作相关
import {
  createCollaborationServiceMenuItems,
  CollaborationServiceStateDialog,
  CollaborationServiceFilter
} from '@kit.ServiceCollaborationKit';

let logger = Logger.getLogger('[KnockShare]');
let context = getContext(this) as common.UIAbilityContext;
let filesDir = context.filesDir;

// 新年卡片接口定义
interface NewYearCard {
  title: string;
  imageUrl: string;
  jumpUrl: string;
}

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
  @StorageLink('sharepng') sharepng: string = 'https://www.hnyqwq.cn/hvideo/share.png' // 背景图片(预览卡片显示)
  @State backgroundImagePath: string = 'https://www.hnyqwq.cn/hvideo/share.png' // 背景图片路径(独立)
  @State backgroundPixelMap: PixelMap | undefined = undefined; // 背景图片的PixelMap(独立)
  @State backgroundImageKey: string = ''; // 背景图片key(独立)
  @State useCustomBackground: boolean = false; // 标记是否用户手动设置了自定义背景图片
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

  // 分享类型选择
  @State shareTypeIndex: number = 0; // 0: 链接, 1: 文本, 2: 图片, 3: 视频, 4: 文件

  // 各类型分享内容
  @State shareLinkContent: string = ''; // 链接内容
  @State shareTextContent: string = ''; // 文本内容
  @State shareImagePath: string = ''; // 图片路径（单个）
  @State shareImagePaths: string[] = []; // 图片路径数组（多个）
  @StorageLink('shareVideoPath') shareVideoPath: string = ''; // 视频路径（单个）- 使用StorageLink以响应AppStorage更新
  @State shareVideoPaths: string[] = []; // 视频路径数组（多个）
  @State shareFilePath: string = ''; // 文件路径（单个）
  @State shareFilePaths: string[] = []; // 文件路径数组（多个）
  @State downloadUrl: string = ''; // 下载链接
  @State downloadProgress: string = '0'; // 下载进度

  // 主颜色获取相关
  @State mainColor: string = '#F5E5D8'; // 获取的主颜色，用于文字背景，默认为#F5E5D8

  // 顶部背景渐变相关
  @State topBgColor: string = '#FFFFFF'; // 顶部背景颜色
  @State topSafeHeight: number = 0; // 顶部安全区域高度

  // 新年卡片相关
  @State showNewYearCard: boolean = true; // 是否显示新年卡片
  @State newYearCards: NewYearCard[] = [
    {
      title: '2026春节快乐',
      imageUrl: 'https://img.alicdn.com/imgextra/i2/O1CN01Z6Hv8X1Z8ZkXJgV7a_!!6000000004684-2-tps-800-600.png',
      jumpUrl: 'https://www.baidu.com/s?wd=2026春节快乐'
    },
    {
      title: '春节放假安排',
      imageUrl: 'https://img.alicdn.com/imgextra/i3/O1CN01Z6Hv8Y1Z8ZkXJgV7b_!!6000000004684-2-tps-800-600.png',
      jumpUrl: 'https://www.gov.cn/zhengce/content/202511/content_7047090.htm'
    },
    {
      title: '新年祝福',
      imageUrl: 'https://img.alicdn.com/imgextra/i4/O1CN01Z6Hv8W1Z8ZkXJgV7c_!!6000000004684-2-tps-800-600.png',
      jumpUrl: 'https://www.baidu.com/s?wd=2026新年祝福语'
    },
    {
      title: '看春晚',
      imageUrl: 'https://img.alicdn.com/imgextra/i1/O1CN01Z6Hv8V1Z8ZkXJgV7d_!!6000000004684-2-tps-800-600.png',
      jumpUrl: 'https://www.baidu.com/s?wd=2026新年快乐图片'
    }
  ];
  @State currentNewYearCardIndex: number = 0; // 当前显示的新年卡片索引

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

      // 加载为 PixelMap,只更新背景图片,不更新分享图片
      const imageSource = image.createImageSource(targetPath);
      this.backgroundPixelMap = await imageSource.createPixelMap();
      hilog.info(0x0000, 'localsharepng' , 'PixelMap created for background image');

      // 更新 sharepng（第一个卡片的分享图片背景）
      this.sharepng = 'file://' + targetPath;
      hilog.info(0x0000, 'localsharepng' , 'sharepng updated to: ' + this.sharepng);

      // 只更新背景图片路径,不影响分享图片
      this.backgroundImagePath = 'file://' + targetPath;
      hilog.info(0x0000, 'localsharepng' , 'Background image path updated');
    } catch (error) {
      hilog.error(0x0000, 'localsharepng' , 'Copy failed: ' + JSON.stringify(error));
      return;
    }

    // 强制刷新背景图片显示
    this.backgroundImageKey = Date.now().toString();

    // 重新获取图片宽高比
    await this.getImageAspectRatio();

    // 如果是横屏+隔空模式，获取主颜色
    if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
      await this.extractMainColor();
    }

    console.log('=== selectImage 结束 ===');
  }

  // 选择分享图片(不影响背景图片)
  private async selectShareImage() {
    let uri = await this.openPhoto();
    if (uri === undefined) {
      hilog.error(0x0000, 'OCRDemo', "Failed to get uri.");
      return;
    }

    console.log('=== selectShareImage 开始 ===');
    console.log('选择的图片 URI: ' + uri);

    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    // 根据选中的图片URI确定扩展名，但使用独立的变量
    let shareImageExtension = '.png';
    if (uri.endsWith('.png')) {
      shareImageExtension = '.png';
    } else if (uri.endsWith('.jpg') || uri.endsWith('.jpeg')) {
      shareImageExtension = '.jpg';
    } else if (uri.endsWith('.webp')) {
      shareImageExtension = '.webp';
    } else {
      // 默认使用.png格式
      shareImageExtension = '.png';
    }

    console.log('分享图片扩展名: ' + shareImageExtension);

    // 根据当前图片扩展名设置目标路径(分享图片使用不同的文件名)
    let targetPath = context.filesDir + '/shareimg' + shareImageExtension;
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

      hilog.info(0x0000, 'localsharepng', 'Copy completed: ' + targetPath);

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 验证文件是否真的存在
      const stat = fileIo.statSync(targetPath);
      hilog.info(0x0000, 'localsharepng', 'File verified, size: ' + stat.size);

      // 只更新单张分享图片路径,不影响多图数组(shareImagePaths已在openPhoto中设置)
      this.shareImagePath = targetPath;
      hilog.info(0x0000, 'localsharepng', 'Share image path updated');
      hilog.info(0x0000, 'localsharepng', 'Total images: ' + this.shareImagePaths.length);
    } catch (error) {
      hilog.error(0x0000, 'localsharepng', 'Copy failed: ' + JSON.stringify(error));
      return;
    }

    // 强制刷新分享图片显示
    this.imageKey = Date.now().toString();

    console.log('=== selectShareImage 结束 ===');
  }

  // 将指定图片设置为背景图片
  private async setImageAsBackground(imagePath: string): Promise<void> {
    console.log('=== setImageAsBackground 开始 ===');
    console.log('要设置为背景的图片 URI: ' + imagePath);

    try {
      // 根据图片URI获取扩展名
      let extension = '.png';
      if (imagePath.endsWith('.png')) {
        extension = '.png';
      } else if (imagePath.endsWith('.jpg') || imagePath.endsWith('.jpeg')) {
        extension = '.jpg';
      } else if (imagePath.endsWith('.webp')) {
        extension = '.webp';
      }

      this.imageExtension = extension;

      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;

      // 复制文件到应用目录
      let sourceFile = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
      let targetFile = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);

      let bufferSize = 1024 * 1024;
      let buffer = new ArrayBuffer(bufferSize);
      let readLen: number = 0;

      while ((readLen = fileIo.readSync(sourceFile.fd, buffer)) > 0) {
        fileIo.writeSync(targetFile.fd, buffer, { length: readLen });
      }

      fileIo.closeSync(sourceFile);
      fileIo.closeSync(targetFile);

      hilog.info(0x0000, 'HomePage', 'Copy completed: ' + targetPath);

      // 等待文件系统同步
      await new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 100);
      });

      // 加载为PixelMap
      const imageSource = image.createImageSource(targetPath);
      this.backgroundPixelMap = await imageSource.createPixelMap();

      // 更新背景图片(独立状态,不影响分享图片)
      this.backgroundImagePath = 'file://' + targetPath;
      hilog.info(0x0000, 'HomePage', 'Background image updated to: ' + this.backgroundImagePath);

      // 标记用户已手动设置自定义背景
      this.useCustomBackground = true;

      // 强制刷新背景图片显示
      this.backgroundImageKey = Date.now().toString();

      // 重新获取图片宽高比(使用背景图片)
      await this.getImageAspectRatio();

      // 如果是横屏+隔空模式，获取主颜色
      if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
        await this.extractMainColor();
      }

      promptAction.showToast({ message: '已设置为背景图片' });

      console.log('=== setImageAsBackground 结束 ===');
    } catch (error) {
      hilog.error(0x0000, 'HomePage', 'setImageAsBackground failed: ' + JSON.stringify(error));
      promptAction.showToast({ message: '设置背景图片失败' });
    }
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 500 // 最多选择500个图片
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        this.shareImagePaths = res.photoUris; // 保存所有选择的图片
        if (res.photoUris.length > 1) {
          promptAction.showToast({ message: `已选择${res.photoUris.length}张图片` });
        }
        resolve(res.photoUris[0]);
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'OCRDemo', `Failed to get photo image uri. code：${err.code}，message：${err.message}`);
        reject('');
      })
    })
  }

  // 处理跨设备协作传来的图片
  doInsertPicture(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    if (stateCode != 0) {
      return;
    }
    if (bufferType == "general.image") {
      let imageSource = image.createImageSource(buffer);
      imageSource.createPixelMap().then((pixelMap) => {
        this.localPixelMap = pixelMap;

        // 获取扩展名
        this.imageExtension = '.png'; // 跨设备传输默认使用 png
        let targetPath = context.filesDir + '/pengyipeng' + this.imageExtension;

        // 保存图片到本地
        let packer = image.createImagePacker();
        packer.packing(pixelMap, { format: 'image/png', quality: 100 }).then((data) => {
          let file = fileIo.openSync(targetPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
          fileIo.writeSync(file.fd, data);
          fileIo.closeSync(file);

          // 更新 sharepng
          this.sharepng = 'file://' + targetPath;

          // 刷新图片
          this.imageKey = Date.now().toString();

          // 重新获取图片宽高比
          this.getImageAspectRatio().then(() => {
            // 如果是横屏+隔空模式，获取主颜色
            if (this.imageAspectRatio >= 1 && this.selectedShareMode === 1) {
              this.extractMainColor();
            }
          });
        });
      }).catch((error: BusinessError) => {
        hilog.error(0x0000, 'HomePage', `Failed to process image from other device: ${JSON.stringify(error)}`);
      });
    }
  }




  //华为系统分享
  private async share() {
    let uiContext: UIContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;

    // 根据分享类型执行不同的分享逻辑
    switch (this.shareTypeIndex) {
      case 0: // 链接分享
        if (!this.shareLinkContent) {
          promptAction.showToast({ message: '请输入要分享的链接' });
          return;
        }
        await this.shareLink(contextFaker);
        break;
      case 1: // 文本分享
        if (!this.shareTextContent) {
          promptAction.showToast({ message: '请输入要分享的文本' });
          return;
        }
        await this.shareText(contextFaker);
        break;
      case 2: // 图片分享
        if (!this.shareImagePath && !this.sharepng) {
          promptAction.showToast({ message: '请选择要分享的图片' });
          return;
        }
        // 如果选择了多个图片，使用多文件分享
        if (this.shareImagePaths.length > 1) {
          await this.shareMultipleImages(contextFaker);
        } else {
          await this.shareImage(contextFaker);
        }
        break;
      case 3: // 视频分享
        if (!this.shareVideoPath) {
          promptAction.showToast({ message: '请选择要分享的视频' });
          return;
        }
        // 如果选择了多个视频，使用多文件分享
        if (this.shareVideoPaths.length > 1) {
          await this.shareMultipleVideos(contextFaker);
        } else {
          await this.shareVideo(contextFaker);
        }
        break;
      case 4: // 文件分享
        if (!this.shareFilePath) {
          promptAction.showToast({ message: '请选择要分享的文件' });
          return;
        }
        // 如果选择了多个文件，使用多文件分享
        if (this.shareFilePaths.length > 1) {
          await this.shareMultipleFiles(contextFaker);
        } else {
          await this.shareFile(contextFaker);
        }
        break;
    }
  }

  // 分享链接
  private async shareLink(contextFaker: Context) {
    // 始终使用 sharepng 作为缩略图背景(第一个卡片的背景图片)
    let thumbnailPath: string;
    if (this.sharepng) {
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // sharepng 是网络图片,使用本地缓存文件
        thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
      } else if (this.sharepng.startsWith('file://')) {
        // sharepng 是本地文件
        thumbnailPath = this.sharepng.substring(7); // 移除 file:// 前缀
      } else {
        // sharepng 是其他路径
        thumbnailPath = this.sharepng;
      }
    } else {
      // sharepng 为空,使用默认pengyipeng文件
      thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
    }

    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: 30
    });

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: this.shareLinkContent,
      title: this.pengtitle,
      description: this.shareLinkContent,
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

  // 分享文本
  private async shareText(contextFaker: Context) {
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.TEXT,
      content: this.shareTextContent,
      title: '分享文本',
      description: this.shareTextContent,
      thumbnail: new Uint8Array()
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

  // 分享图片
  private async shareImage(contextFaker: Context) {
    let imagePath = this.shareImagePath || this.sharepng;

    // 根据文件扩展名获取UTD类型
    let extension = imagePath.substring(imagePath.lastIndexOf('.'));
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.IMAGE);

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: fileUri.getUriFromPath(imagePath),
      title: '分享图片',
      description: '分享图片',
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.BATCH
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  // 分享视频
  private async shareVideo(contextFaker: Context) {
    // 始终使用 sharepng 作为缩略图背景(第一个卡片的背景图片)
    let thumbnailPath: string;
    if (this.sharepng) {
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // sharepng 是网络图片,使用本地缓存文件
        thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
      } else if (this.sharepng.startsWith('file://')) {
        // sharepng 是本地文件
        thumbnailPath = this.sharepng.substring(7); // 移除 file:// 前缀
      } else {
        // sharepng 是其他路径
        thumbnailPath = this.sharepng;
      }
    } else {
      // sharepng 为空,使用默认pengyipeng文件
      thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
    }

    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer | undefined = undefined;

    try {
      buffer = await imagePacker.packToData(imageSource, {
        format: 'image/jpeg',
        quality: 30,
      });
    } catch (error) {
      console.error(`packToData error. Code: ${error?.code}, message: ${error?.message}`);
    }

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.VIDEO,
      uri: fileUri.getUriFromPath(this.shareVideoPath),
      title: '分享视频',
      description: '分享视频',
      thumbnail: buffer ? new Uint8Array(buffer) : undefined,
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.BATCH
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  // 分享文件
  private async shareFile(contextFaker: Context) {
    // 根据文件扩展名获取UTD类型
    let extension = this.shareFilePath.substring(this.shareFilePath.lastIndexOf('.'));
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.FILE);

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: fileUri.getUriFromPath(this.shareFilePath),
      content: this.shareFilePath,
      title: '分享文件',
      description: '分享文件',
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.BATCH
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  // 分享多个文件
  private async shareMultipleFiles(contextFaker: Context) {
    if (this.shareFilePaths.length === 0) {
      promptAction.showToast({ message: '请先选择要分享的文件' });
      return;
    }

    // 为每个文件创建SharedData
    let shareDataList: systemShare.SharedData[] = [];
    for (let i = 0; i < this.shareFilePaths.length; i++) {
      let filePath = this.shareFilePaths[i];
      let extension = filePath.substring(filePath.lastIndexOf('.'));
      let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.FILE);

      let shareData = new systemShare.SharedData({
        utd: utdTypeId,
        uri: fileUri.getUriFromPath(filePath),
        content: filePath,
        title: `分享文件${i + 1}`,
        description: `分享文件${i + 1}`,
      });
      shareDataList.push(shareData);
    }

    // 创建ShareController并显示
    let controller: systemShare.ShareController = new systemShare.ShareController(shareDataList[0]);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  // 分享多个图片
  private async shareMultipleImages(contextFaker: Context) {
    if (this.shareImagePaths.length === 0) {
      promptAction.showToast({ message: '请先选择要分享的图片' });
      return;
    }

    // 构造ShareData，配置第一条数据
    let imagePath = this.shareImagePaths[0];
    let extension = imagePath.substring(imagePath.lastIndexOf('.'));
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.IMAGE);

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: imagePath,
      title: '分享图片',
      description: `分享${this.shareImagePaths.length}张图片`,
    });

    // 为剩余的每张图片添加记录
    for (let i = 1; i < this.shareImagePaths.length; i++) {
      shareData.addRecord({
        utd: utdTypeId,
        uri: this.shareImagePaths[i],
        title: `分享图片${i + 1}`,
        description: `分享图片${i + 1}`,
      });
    }

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.BATCH
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      console.error(`ShareController show error. code: ${error.code}, message: ${error.message}`);
    });
  }

  // 分享多个视频
  private async shareMultipleVideos(contextFaker: Context) {
    if (this.shareVideoPaths.length === 0) {
      promptAction.showToast({ message: '请先选择要分享的视频' });
      return;
    }

    // 始终使用 sharepng 作为缩略图背景(第一个卡片的背景图片)
    let thumbnailPath: string;
    if (this.sharepng) {
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // sharepng 是网络图片,使用本地缓存文件
        thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
      } else if (this.sharepng.startsWith('file://')) {
        // sharepng 是本地文件
        thumbnailPath = this.sharepng.substring(7); // 移除 file:// 前缀
      } else {
        // sharepng 是其他路径
        thumbnailPath = this.sharepng;
      }
    } else {
      // sharepng 为空,使用默认pengyipeng文件
      thumbnailPath = contextFaker.filesDir + '/pengyipeng' + this.imageExtension;
    }

    let imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    let imagePacker: image.ImagePacker = image.createImagePacker();
    let buffer: ArrayBuffer | undefined = undefined;

    try {
      buffer = await imagePacker.packToData(imageSource, {
        format: 'image/jpeg',
        quality: 30,
      });
    } catch (error) {
      console.error(`packToData error. Code: ${error?.code}, message: ${error?.message}`);
    }

    // 构造ShareData，配置第一条数据
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.VIDEO,
      uri: fileUri.getUriFromPath(this.shareVideoPaths[0]),
      title: '分享视频',
      description: `分享${this.shareVideoPaths.length}个视频`,
      thumbnail: buffer ? new Uint8Array(buffer) : undefined,
    });

    // 为剩余的每个视频添加记录
    for (let i = 1; i < this.shareVideoPaths.length; i++) {
      shareData.addRecord({
        utd: utd.UniformDataType.VIDEO,
        uri: fileUri.getUriFromPath(this.shareVideoPaths[i]),
        title: `分享视频${i + 1}`,
        description: `分享视频${i + 1}`,
      });
    }

    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.BATCH
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
      urlPrefix: 'https://www.hnyqwq.cn/hvideo/knock_share_guide/knock_share_guide_phone_',
      framesCount: 128,
      startDelay: 50,
      stopDelay: 500,
    },
    {
      text: '对方电脑需 HarmonyOS 6 及以上版本。',
      urlPrefix: 'https://www.hnyqwq.cn/hvideo/knock_share_guide/knock_share_guide_pc_',
      framesCount: 104,
      startDelay: 50,
      stopDelay: 50,
    },
    {
      text: '对方手机需 HarmonyOS 6 及以上版本。',
      urlPrefix: 'https://www.hnyqwq.cn/hvideo/knock_share_guide/knock_share_guide_pc_pull_',
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

              // 只有当用户没有手动设置自定义背景时，才更新 backgroundPixelMap 和 backgroundImagePath
              if (!this.useCustomBackground) {
                let localPath = filesDir + '/pengyipeng' + this.imageExtension;
                try {
                  const imageSource = image.createImageSource(localPath);
                  this.backgroundPixelMap = await imageSource.createPixelMap();
                  this.backgroundImagePath = 'file://' + localPath;
                  console.log('backgroundPixelMap 和 backgroundImagePath 已更新（跟随 sharepng）');
                } catch (error) {
                  console.error('加载 backgroundPixelMap 失败:', JSON.stringify(error));
                }
              } else {
                console.log('用户已设置自定义背景，保持不变');
              }

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

    // 同步 networkVideoSrc 到 shareLinkContent
    this.shareLinkContent = this.networkVideoSrc;

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
      // 支持碰一碰分享的能力且非平板，但手机端默认为隔空投送分享预览
      this.selectedShareMode = 1;
      this.currentDescription = $r('app.string.gekong_description');
      console.log('设备支持碰一碰分享且非平板，手机端默认选择隔空投送模式');
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
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;

    // 始终使用 sharepng 作为缩略图背景(第一个卡片的背景图片)
    let thumbnailPath: string;
    if (this.sharepng) {
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // sharepng 是网络图片,使用本地缓存文件
        thumbnailPath = context.filesDir + "/pengyipeng" + this.imageExtension;
      } else if (this.sharepng.startsWith('file://')) {
        // sharepng 是本地文件
        thumbnailPath = this.sharepng.substring(7); // 移除 file:// 前缀
      } else {
        // sharepng 是其他路径
        thumbnailPath = this.sharepng;
      }
    } else {
      // sharepng 为空,使用默认pengyipeng文件
      thumbnailPath = context.filesDir + "/pengyipeng" + this.imageExtension;
    }

    let shareData: systemShare.SharedData;

    // 根据分享类型索引构建不同的分享数据
    switch (this.shareTypeIndex) {
      case 0: // 链接分享
        shareData = new systemShare.SharedData({
          utd: utd.UniformDataType.HYPERLINK,
          content: this.shareLinkContent || this.networkVideoSrc,
          thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
          title: this.pengtitle,
          description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
        });
        break;
      case 1: // 文本分享
        shareData = new systemShare.SharedData({
          utd: utd.UniformDataType.TEXT,
          content: this.shareTextContent,
          thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
          title: this.pengtitle,
          description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
        });
        break;
      case 2: // 图片分享
        if (this.shareImagePaths.length > 0) {
          let imagePath = this.shareImagePaths[0];
          let extension = imagePath.substring(imagePath.lastIndexOf('.'));
          let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.IMAGE);
          
          shareData = new systemShare.SharedData({
            utd: utdTypeId,
            uri: imagePath,
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
          });
          
          // 为剩余的每张图片添加记录
          for (let i = 1; i < this.shareImagePaths.length; i++) {
            shareData.addRecord({
              utd: utdTypeId,
              uri: this.shareImagePaths[i],
              title: `分享图片${i + 1}`,
              description: `分享图片${i + 1}`,
            });
          }
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的图片' });
          return;
        }
        break;
      case 3: // 视频分享
        if (this.shareVideoPaths.length > 0) {
          shareData = new systemShare.SharedData({
            utd: utd.UniformDataType.VIDEO,
            uri: fileUri.getUriFromPath(this.shareVideoPaths[0]),
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
          });
          
          // 为剩余的每个视频添加记录
          for (let i = 1; i < this.shareVideoPaths.length; i++) {
            shareData.addRecord({
              utd: utd.UniformDataType.VIDEO,
              uri: fileUri.getUriFromPath(this.shareVideoPaths[i]),
              title: `分享视频${i + 1}`,
              description: `分享视频${i + 1}`,
            });
          }
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的视频' });
          return;
        }
        break;
      case 4: // 文件分享
        if (this.shareFilePaths.length > 0) {
          let extension = this.shareFilePaths[0].substring(this.shareFilePaths[0].lastIndexOf('.'));
          let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.FILE);
          shareData = new systemShare.SharedData({
            utd: utdTypeId,
            uri: fileUri.getUriFromPath(this.shareFilePaths[0]),
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.pengyipeng_description').id)
          });
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的文件' });
          return;
        }
        break;
      default:
        sharableTarget.clarifyNonShare({ message: '不支持的分享类型' });
        return;
    }
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
        // 根据分享类型验证是否可分享
        switch (this.shareTypeIndex) {
          case 0: // 链接分享
            if (!this.shareLinkContent && !this.networkVideoSrc) {
              sharableTarget.clarifyNonShare({ message: '请输入要分享的链接' });
              return;
            }
            break;
          case 1: // 文本分享
            if (!this.shareTextContent) {
              sharableTarget.clarifyNonShare({ message: '请输入要分享的文本' });
              return;
            }
            break;
          case 2: // 图片分享
            if (this.shareImagePaths.length === 0) {
              sharableTarget.clarifyNonShare({ message: '请先选择要分享的图片' });
              return;
            }
            break;
          case 3: // 视频分享
            if (this.shareVideoPaths.length === 0) {
              sharableTarget.clarifyNonShare({ message: '请先选择要分享的视频' });
              return;
            }
            break;
          case 4: // 文件分享
            if (this.shareFilePaths.length === 0) {
              sharableTarget.clarifyNonShare({ message: '请先选择要分享的文件' });
              return;
            }
            break;
        }
        this.whiteCallback(sharableTarget);
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
        // 注释掉:不要在隔空投送时修改 sharepng,保持用户设置的背景图片
        // this.sharepng = 'file://' + imagePath;
        console.log('图片文件已找到: ' + imagePath);
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

    // 始终使用 sharepng 作为缩略图背景(第一个卡片的背景图片)
    let thumbnailPath: string;
    if (this.sharepng) {
      if (this.sharepng.startsWith('http://') || this.sharepng.startsWith('https://')) {
        // sharepng 是网络图片,使用本地缓存文件
        thumbnailPath = currentContext.filesDir + "/pengyipeng" + this.imageExtension;
      } else if (this.sharepng.startsWith('file://')) {
        // sharepng 是本地文件
        thumbnailPath = this.sharepng.substring(7); // 移除 file:// 前缀
      } else {
        // sharepng 是其他路径
        thumbnailPath = this.sharepng;
      }
    } else {
      // sharepng 为空,使用默认pengyipeng文件
      thumbnailPath = currentContext.filesDir + "/pengyipeng" + this.imageExtension;
    }

    let shareData: systemShare.SharedData;

    // 根据分享类型索引构建不同的分享数据
    switch (this.shareTypeIndex) {
      case 0: // 链接分享
        shareData = new systemShare.SharedData({
          utd: utd.UniformDataType.HYPERLINK,
          content: this.shareLinkContent || this.networkVideoSrc,
          thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
          title: this.pengtitle,
          description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
        });
        break;
      case 1: // 文本分享
        shareData = new systemShare.SharedData({
          utd: utd.UniformDataType.TEXT,
          content: this.shareTextContent,
          thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
          title: this.pengtitle,
          description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
        });
        break;
      case 2: // 图片分享
        if (this.shareImagePaths.length > 0) {
          let imagePath = this.shareImagePaths[0];
          let extension = imagePath.substring(imagePath.lastIndexOf('.'));
          let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.IMAGE);
          
          shareData = new systemShare.SharedData({
            utd: utdTypeId,
            uri: imagePath,
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
          });
          
          // 为剩余的每张图片添加记录
          for (let i = 1; i < this.shareImagePaths.length; i++) {
            shareData.addRecord({
              utd: utdTypeId,
              uri: this.shareImagePaths[i],
              title: `分享图片${i + 1}`,
              description: `分享图片${i + 1}`,
            });
          }
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的图片' });
          return;
        }
        break;
      case 3: // 视频分享
        if (this.shareVideoPaths.length > 0) {
          shareData = new systemShare.SharedData({
            utd: utd.UniformDataType.VIDEO,
            uri: fileUri.getUriFromPath(this.shareVideoPaths[0]),
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
          });
          
          // 为剩余的每个视频添加记录
          for (let i = 1; i < this.shareVideoPaths.length; i++) {
            shareData.addRecord({
              utd: utd.UniformDataType.VIDEO,
              uri: fileUri.getUriFromPath(this.shareVideoPaths[i]),
              title: `分享视频${i + 1}`,
              description: `分享视频${i + 1}`,
            });
          }
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的视频' });
          return;
        }
        break;
      case 4: // 文件分享
        if (this.shareFilePaths.length > 0) {
          let extension = this.shareFilePaths[0].substring(this.shareFilePaths[0].lastIndexOf('.'));
          let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.FILE);
          shareData = new systemShare.SharedData({
            utd: utdTypeId,
            uri: fileUri.getUriFromPath(this.shareFilePaths[0]),
            thumbnailUri: fileUri.getUriFromPath(thumbnailPath),
            title: this.pengtitle,
            description: context.resourceManager.getStringSync($r('app.string.gekong_description').id)
          });
        } else {
          sharableTarget.clarifyNonShare({ message: '请先选择要分享的文件' });
          return;
        }
        break;
      default:
        sharableTarget.clarifyNonShare({ message: '不支持的分享类型' });
        return;
    }
    sharableTarget.share(shareData);
  }

  // 根据分享类型获取标题输入框的提示文字
  private getTitlePlaceholder(): string {
    switch (this.shareTypeIndex) {
      case 0:
        return '请输入链接分享的标题';
      case 1:
        return '请输入文本分享的标题';
      case 2:
        return '请输入图片分享的标题';
      case 3:
        return '请输入视频分享的标题';
      case 4:
        return '请输入文件分享的标题';
      default:
        return '请输入分享标题';
    }
  }

  // 根据分享类型获取对应的标题字符串
  private getShareTypeTitle(typeIndex: number): string {
    switch (typeIndex) {
      case 0:
        return '分享当前的链接';
      case 1:
        return '分享当前的文本';
      case 2:
        return '分享当前的图片';
      case 3:
        return '分享当前的视频';
      case 4:
        return '分享当前的文件';
      default:
        return '分享当前的链接';
    }
  }

  // 根据分享类型更新标题
  private updateTitleForShareType(typeIndex: number): void {
    this.pengtitle = this.getShareTypeTitle(typeIndex);
    // 同步到 AppStorage
    AppStorage.set('pengtitle', this.pengtitle);
  }




  // 添加一个方法来获取图片的宽高比
  private async getImageAspectRatio(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let imageSource: image.ImageSource;
      // 优先使用背景图片路径
      let imagePath = this.backgroundImagePath !== '' ? this.backgroundImagePath : this.sharepng;

      console.log('=== getImageAspectRatio 开始 ===');
      console.log('当前背景图片路径: ' + this.backgroundImagePath);
      console.log('当前分享图片路径: ' + this.sharepng);
      console.log('使用的图片路径: ' + imagePath);
      console.log('当前 imageExtension: ' + this.imageExtension);

      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        // 如果是网络图片，使用本地缓存文件
        let localPath = context.filesDir + '/pengyipeng' + this.imageExtension;
        console.log('使用网络图片缓存路径: ' + localPath);
        imageSource = image.createImageSource(localPath);
      } else if (imagePath.startsWith('file://')) {
        // 如果是本地文件
        let filePath = imagePath.substring(7); // 移除 'file://' 前缀
        console.log('使用本地文件路径: ' + filePath);
        imageSource = image.createImageSource(filePath);
      } else {
        // 如果是资源文件
        console.log('使用资源文件: ' + imagePath);
        imageSource = image.createImageSource(imagePath);
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

      if (this.backgroundPixelMap) {
        // 使用背景图片的 PixelMap
        pixelMap = this.backgroundPixelMap;
      } else {
        // 从文件加载 PixelMap
        let imagePath: string;
        if (this.backgroundImagePath.startsWith('file://')) {
          imagePath = this.backgroundImagePath.substring(7); // 移除 'file://' 前缀
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

      if (this.backgroundPixelMap) {
        pixelMap = this.backgroundPixelMap;
      } else {
        let imagePath: string;
        if (this.backgroundImagePath.startsWith('file://')) {
          imagePath = this.backgroundImagePath.substring(7);
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
                      if (this.backgroundPixelMap) {
                        Image(this.backgroundPixelMap)
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
                        Image(this.backgroundImagePath)
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
                      if (this.backgroundPixelMap) {
                        Image(this.backgroundPixelMap)
                          .width('100%')
                          .aspectRatio(1.4)
                          .objectFit(ImageFit.Cover)
                          .borderRadius(10)
                      } else {
                        Image(this.backgroundImagePath)
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
                    if (this.backgroundPixelMap) {
                      // 使用 PixelMap 显示本地选择的图片
                      Column() {
                        Image(this.backgroundPixelMap)
                          .width(this.imageAspectRatio < 1 ? '100%' : '80%')
                          .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                          .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
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
                        Image(this.backgroundImagePath)
                          .width(this.imageAspectRatio < 1 ? '100%' : '80%')
                          .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                          .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
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
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .margin({ top: 12 ,bottom: 8 })
                        .blur(0) // 文字不模糊

                      Text(this.currentDescription)
                        .fontSize(16)
                        .fontColor(0xA3A3A3)
                        .margin({ bottom: 5 })
                        .blur(0) // 文字不模糊

                      Image($r('app.media.CIcon'))
                        .width(20)
                        .height(20)
                        .margin({ bottom: 8 })
                        .blur(0) // 图标不模糊
                    }
                    .width('100%')
                    .padding(8)
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
                /*Column() {
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
                .border({ width: 1, color: 0xFFCCCC })*/

                // 区域1：分享图片
                Column() {
                  Row() {
                    Text($r('app.string.sharepngon'))
                      .textAlign(TextAlign.Center)
                      .width('55%')
                      .margin({ right: 10 })
                    // 跨设备协作状态对话框（用于接收其他设备的图片）
                    CollaborationServiceStateDialog({
                      onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
                        bufferType, buffer)
                    })
                    if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
                      // 平板/PC设备：使用跨设备协作按钮
                      Button($r('app.string.choosepad'))
                        .height(50)
                        .width('40%')
                        .backgroundColor(0xb87cff)//紫色
                        .bindMenu(this.CrossDeviceMenu)
                    } else {
                      // 手机设备：使用普通按钮
                      Button($r('app.string.choose'))
                        .height(50)
                        .width('40%')
                        .backgroundColor(0xb87cff)//紫色
                        .onClick(() => {
                          this.selectImage();
                        })
                    }
                  }
                  .width('100%')

                  Row() {
                    TextArea({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
                      .layoutWeight(1)
                      .onChange((sharepng: string) => {
                        this.sharepng = sharepng;
                        // @StorageLink 会自动同步到 AppStorage,无需手动保存
                        if (this.isValidUrl(sharepng)) {
                          this.handleImageUpdate(); // 触发图片更新逻辑
                        }
                      })
                    Row() {
                      PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                        .backgroundColor(0xb87cff)
                        .height(40)
                        .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                          if (PasteButtonOnClickResult.SUCCESS === result) {
                            pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                              if (err) {
                                console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              this.sharepng = pasteData.getPrimaryText();
                            });
                          }
                        })
                    }
                    .margin({ left: 10 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 10, bottom: 10 })
                }
                .width('100%')
                .backgroundColor($r('app.color.comp_background_list_card'))
                .borderRadius(8)
                .padding(12)
                .margin({ bottom: 10 })
                .border({ width: 1, color: $r('sys.color.comp_divider') })

                // 区域2：分享内容
                Column() {
                  // 分享类型选择胶囊按钮
                  Row() {
                    Button('链接')
                      .fontSize(14)
                      .height(36)
                      .backgroundColor(this.shareTypeIndex === 0 ? 0x66CCFF : 0xE0E0E0)
                      .fontColor(this.shareTypeIndex === 0 ? 0xFFFFFF : 0x000000)
                      .borderRadius(8)
                      .margin({ right: 5 })
                      .onClick(() => {
                        this.shareTypeIndex = 0;
                      })
                    Button('文本')
                      .fontSize(14)
                      .height(36)
                      .backgroundColor(this.shareTypeIndex === 1 ? 0x66CCFF : 0xE0E0E0)
                      .fontColor(this.shareTypeIndex === 1 ? 0xFFFFFF : 0x000000)
                      .borderRadius(8)
                      .margin({ right: 5 })
                      .onClick(() => {
                        this.shareTypeIndex = 1;
                      })
                    Button('图片')
                      .fontSize(14)
                      .height(36)
                      .backgroundColor(this.shareTypeIndex === 2 ? 0x66CCFF : 0xE0E0E0)
                      .fontColor(this.shareTypeIndex === 2 ? 0xFFFFFF : 0x000000)
                      .borderRadius(8)
                      .margin({ right: 5 })
                      .onClick(() => {
                        this.shareTypeIndex = 2;
                      })
                    Button('视频')
                      .fontSize(14)
                      .height(36)
                      .backgroundColor(this.shareTypeIndex === 3 ? 0x66CCFF : 0xE0E0E0)
                      .fontColor(this.shareTypeIndex === 3 ? 0xFFFFFF : 0x000000)
                      .borderRadius(8)
                      .margin({ right: 5 })
                      .onClick(() => {
                        this.shareTypeIndex = 3;
                      })
                    // Button('文件') // 暂时隐藏文件分享
                    //   .fontSize(14)
                    //   .height(36)
                    //   .backgroundColor(this.shareTypeIndex === 4 ? 0x66CCFF : 0xE0E0E0)
                    //   .fontColor(this.shareTypeIndex === 4 ? 0xFFFFFF : 0x000000)
                    //   .borderRadius(8)
                    //   .onClick(() => {
                    //     this.shareTypeIndex = 4;
                    //   })
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.SpaceEvenly)
                  .margin({ bottom: 10 })

                  // 根据选择的类型显示不同的内容
                  if (this.shareTypeIndex === 0) {
                    // 链接分享
                    Column() {
                      Row() {
                        Text($r('app.string.texton'))
                          .textAlign(TextAlign.Center)
                          .width('55%')
                          .margin({ right: 10 })

                        Button($r('app.string.scancodelinkpad'))
                          .height(50)
                          .width('40%')
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
                                this.shareLinkContent = originalValue;
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
                      }
                      .width('100%')
                      .height(50)
                      .margin({ bottom: 10 })

                      Row() {
                        TextArea({ placeholder: $r('app.string.testinput'), text: this.shareLinkContent })
                          .layoutWeight(1)
                          .onChange((value: string) => {
                            this.shareLinkContent = value;
                            // 清除之前的防抖定时器
                            clearTimeout(this.urlDebounceTimer);
                            // 设置新的防抖定时器，300ms后执行
                            this.urlDebounceTimer = setTimeout(() => {
                              const extractedUrl = this.extractUrlFromText(value);
                              if (extractedUrl) {
                                this.shareLinkContent = extractedUrl;
                                this.networkVideoSrc = extractedUrl;
                              } else {
                                this.shareLinkContent = value;
                                this.networkVideoSrc = value;
                              }
                            }, 300);
                          })
                        Row() {
                          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                            .backgroundColor(0xFF66CC)
                            .height(40)
                            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                              if (PasteButtonOnClickResult.SUCCESS === result) {
                                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                                  if (err) {
                                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                    return;
                                  }
                                  this.shareLinkContent = pasteData.getPrimaryText();
                                  this.networkVideoSrc = this.shareLinkContent;
                                });
                              }
                            })
                        }
                        .margin({ left: 10 })
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                    }
                  } else if (this.shareTypeIndex === 1) {
                    // 文本分享
                    Column() {
                      Row() {
                        TextArea({ placeholder: '请输入要分享的文本', text: this.shareTextContent })
                          .layoutWeight(1)
                          .onChange((value: string) => {
                            this.shareTextContent = value;
                          })
                        Row() {
                          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                            .backgroundColor(0xFF66CC)
                            .height(40)
                            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                              if (PasteButtonOnClickResult.SUCCESS === result) {
                                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                                  if (err) {
                                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                    return;
                                  }
                                  this.shareTextContent = pasteData.getPrimaryText();
                                });
                              }
                            })
                        }
                        .margin({ left: 10 })
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                    }
                  } else if (this.shareTypeIndex === 2) {
                    // 图片分享
                    Column() {
                      Row() {
                        Text('分享图片')
                          .textAlign(TextAlign.Center)
                          .width('55%')
                          .margin({ right: 10 })
                        if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
                          // 平板设备：使用跨设备菜单
                          Button($r('app.string.choosepad'))
                            .height(50)
                            .width('40%')
                            .backgroundColor(0xFF66CC)
                            .bindMenu(this.CrossDeviceShareImageMenu)
                        } else {
                          // 手机设备：使用普通按钮
                          Button($r('app.string.choose'))
                            .height(50)
                            .width('40%')
                            .backgroundColor(0xFF66CC)
                            .onClick(() => {
                              this.selectShareImage();
                            })
                        }
                      }
                      .width('100%')
                      // 显示选中的所有图片路径
                      ForEach(this.shareImagePaths, (item: string, index: number) => {
                        Row() {
                          TextArea({ placeholder: `图片路径${index + 1}`, text: item })
                            .enabled(false)
                            .layoutWeight(1)
                          Button('同时作为背景图片')
                            .height(50)
                            .backgroundColor(0xFF66CC)
                            .fontSize(12)
                            .onClick(() => {
                              this.setImageAsBackground(item);
                            })
                        }
                        .width('100%')
                        .margin({ top: 5 })
                      })
                      if (this.shareImagePaths.length > 1) {
                        Text(`已选择${this.shareImagePaths.length}张图片`)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ top: 5 })
                      }
                    }
                  } else if (this.shareTypeIndex === 3) {
                    // 视频分享
                    Column() {
                      Row() {
                        Text('分享视频')
                          .textAlign(TextAlign.Center)
                          .width('55%')
                          .margin({ right: 10 })
                        Button('选择视频')
                          .height(50)
                          .width('40%')
                          .backgroundColor(0xFF66CC)
                          .onClick(async () => {
                            await this.selectVideo();
                          })
                        // 暂时屏蔽裁剪视频功能
                        // if (this.shareVideoPath) {
                        //   Button('裁剪视频')
                        //     .height(50)
                        //     .width('25%')
                        //     .backgroundColor(0xFF66CC)
                        //     .margin({ left: 5 })
                        //     .onClick(() => {
                        //       this.openVideoTrimmer();
                        //     })
                        // }
                      }
                      .width('100%')
                      // 显示选中的所有视频路径
                      ForEach(this.shareVideoPaths, (item: string, index: number) => {
                        TextArea({ placeholder: `视频路径${index + 1}`, text: item })
                          .enabled(false)
                          .margin({ top: 5 })
                      })
                      if (this.shareVideoPaths.length > 1) {
                        Text(`已选择${this.shareVideoPaths.length}个视频`)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ top: 5 })
                      }
                    }
                  } else if (this.shareTypeIndex === 4) {
                    // 文件分享
                    Column() {
                      Row() {
                        Text('分享文件')
                          .textAlign(TextAlign.Center)
                          .width('55%')
                          .margin({ right: 10 })
                        Button('选择文件')
                          .height(50)
                          .width('40%')
                          .backgroundColor(0xFF66CC)
                          .onClick(async () => {
                            await this.selectFile();
                          })
                      }
                      .width('100%')
                      // 显示选中的所有文件路径
                      ForEach(this.shareFilePaths, (item: string, index: number) => {
                        TextArea({ placeholder: `文件路径${index + 1}`, text: item })
                          .enabled(false)
                          .margin({ top: 5 })
                      })
                      if (this.shareFilePaths.length > 1) {
                        Text(`已选择${this.shareFilePaths.length}个文件`)
                          .fontSize(12)
                          .fontColor('#999999')
                          .margin({ top: 5 })
                      }
                      Row() {
                        Text('下载网络文件')
                          .width('55%')
                          .margin({ right: 10 })
                          .textAlign(TextAlign.Center)
                        Button('下载并分享')
                          .height(50)
                          .width('40%')
                          .backgroundColor(0xFF66CC)
                          .onClick(() => {
                            this.downloadAndShare();
                          })
                      }
                      .width('100%')
                      .margin({ top: 10, bottom: 10 })
                      Row() {
                        TextArea({ placeholder: '输入网络文件下载链接', text: this.downloadUrl })
                          .layoutWeight(1)
                          .onChange((value: string) => {
                            this.downloadUrl = value;
                          })
                        Row() {
                          PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                            .backgroundColor(0xFF66CC)
                            .height(40)
                            .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                              if (PasteButtonOnClickResult.SUCCESS === result) {
                                pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                                  if (err) {
                                    console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                    return;
                                  }
                                  this.downloadUrl = pasteData.getPrimaryText();
                                });
                              }
                            })
                        }
                        .margin({ left: 10 })
                      }
                      .width('100%')
                      .alignItems(VerticalAlign.Center)
                      if (this.downloadProgress !== '0' && this.downloadProgress !== '100') {
                        Text(`下载进度: ${this.downloadProgress}%`)
                          .fontSize(14)
                          .fontColor(0x66CCFF)
                          .margin({ top: 5, bottom: 5 })
                      }
                    }
                  }
                }
                .width('100%')
                .backgroundColor($r('app.color.comp_background_list_card'))
                .borderRadius(8)
                .padding(12)
                .margin({ bottom: 10 })
                .border({ width: 1, color: $r('app.color.card_border_color') })

                // 区域3：分享标题
                Column() {
                  Row() {
                    Text($r('app.string.pengtitleset'))
                      .textAlign(TextAlign.Center)
                      .width('100%')
                  }
                  .width('100%')
                  .height(50)

                  Row() {
                    TextArea({ placeholder: $r('app.string.pengyipeng_title'), text: this.pengtitle })
                      .layoutWeight(1)
                      .onChange((pengtitle: string) => {
                        this.pengtitle = pengtitle;
                        // @StorageLink 会自动同步到 AppStorage,无需手动保存
                      })
                    Row() {
                      PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                        .backgroundColor(0x66CCFF)
                        .height(40)
                        .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                          if (PasteButtonOnClickResult.SUCCESS === result) {
                            pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                              if (err) {
                                console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              this.pengtitle = pasteData.getPrimaryText();
                            });
                          }
                        })
                    }
                    .margin({ left: 10 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 5, bottom: 10 })
                }
                .width('100%')
                .backgroundColor($r('app.color.comp_background_list_card'))
                .borderRadius(8)
                .padding(12)
                .margin({ bottom: 10 })
                .border({ width: 1, color: $r('app.color.card_border_color') })

                // 系统分享按钮区域
                Button($r('app.string.share'))
                  .width('100%')
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
              .backgroundColor($r('app.color.card_container_background'))
              .borderRadius(16)
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .margin({ bottom: 20 })

              //碰一碰提示
              if (this.currentBreakpoint !== 'lg' && this.currentBreakpoint !== 'xl') {
                Text($r('app.string.nowplayingon'))
                  .padding({ top: 10 , left: 24, right: 24 })
                  .maxLines(2)
                  .fontSize(11)
                  .maxFontScale(1.75)
                  .width('100%')
                  .constraintSize({ minHeight: 16 })
                  .fontColor($r('app.color.font_secondary'))
                  .fontFamily('HarmonyHeiTi')
                  .textAlign(TextAlign.Center)
                KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
                  .padding({ top: 2 })
              } else {
                // 大屏设备提示
                Column() {
                  Text($r('app.string.large_device_hint'))
                    .fontSize(11)
                    .maxFontScale(1.75)
                    .width('100%')
                    .fontColor($r('app.color.font_secondary'))
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
                if (this.backgroundPixelMap) {
                  Image(this.backgroundPixelMap)
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
                  Image(this.backgroundImagePath)
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
                  .fontColor($r('app.color.pengtitle'))

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
                if (this.backgroundPixelMap) {
                  Image(this.backgroundPixelMap)
                    .width('100%')
                    .aspectRatio(1.4)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(10)
                } else {
                  Image(this.backgroundImagePath)
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
                  .fontColor($r('app.color.pengtitle'))

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
              if (this.backgroundPixelMap) {
                // 使用 PixelMap 显示本地选择的图片
                Column() {
                  Image(this.backgroundPixelMap)
                    .width(this.imageAspectRatio < 1 ? '100%' : '80%')
                    .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                    .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
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
                  Image(this.backgroundImagePath)
                    .width(this.imageAspectRatio < 1 ? '100%' : '80%')
                    .height(this.imageAspectRatio < 1 ? 'auto' : (this.selectedShareMode === 1 && this.imageAspectRatio >= 1 ? '80%' : '80%'))
                    .constraintSize({ maxWidth: this.imageAspectRatio < 1 ? 250 : '100%' })
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
                  .fontColor($r('app.color.pengtitle'))
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

          // 新年快捷按钮区域
          if (this.showNewYearCard) {
            Column() {
              Row() {
                Text('🎉 新年快捷')
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(0xCC0000)
                  .layoutWeight(1)

                // 关闭按钮
                Text('✕')
                  .fontSize(18)
                  .fontColor(0x999999)
                  .onClick(() => {
                    this.showNewYearCard = false;
                  })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .justifyContent(FlexAlign.SpaceBetween)

              // 新年按钮列表 - 两行,每行两个
              Column({ space: 8 }) {
                // 第一行
                Row({ space: 8 }) {
                  Button(this.newYearCards[0].title)
                    .fontSize(14)
                    .height(40)
                    .layoutWeight(1)
                    .backgroundColor(0xFF6666)
                    .fontColor(0xFFFFFF)
                    .borderRadius(8)
                    .shadow({ radius: 4, color: 0x1A000000, offsetX: 0, offsetY: 2 })
                    .onClick(() => {
                      this.handleNewYearCardClick(this.newYearCards[0]);
                    })
                  Button(this.newYearCards[1].title)
                    .fontSize(14)
                    .height(40)
                    .layoutWeight(1)
                    .backgroundColor(0xFF6666)
                    .fontColor(0xFFFFFF)
                    .borderRadius(8)
                    .shadow({ radius: 4, color: 0x1A000000, offsetX: 0, offsetY: 2 })
                    .onClick(() => {
                      this.handleNewYearCardClick(this.newYearCards[1]);
                    })
                }
                .width('100%')

                // 第二行
                Row({ space: 8 }) {
                  Button(this.newYearCards[2].title)
                    .fontSize(14)
                    .height(40)
                    .layoutWeight(1)
                    .backgroundColor(0xFF6666)
                    .fontColor(0xFFFFFF)
                    .borderRadius(8)
                    .shadow({ radius: 4, color: 0x1A000000, offsetX: 0, offsetY: 2 })
                    .onClick(() => {
                      this.handleNewYearCardClick(this.newYearCards[2]);
                    })
                  Button(this.newYearCards[3].title)
                    .fontSize(14)
                    .height(40)
                    .layoutWeight(1)
                    .backgroundColor(0xFF6666)
                    .fontColor(0xFFFFFF)
                    .borderRadius(8)
                    .shadow({ radius: 4, color: 0x1A000000, offsetX: 0, offsetY: 2 })
                    .onClick(() => {
                      this.handleNewYearCardClick(this.newYearCards[3]);
                    })
                }
                .width('100%')
              }
              .width('100%')
              .padding({ left: 12, right: 12, bottom: 8 })
            }
            .width('100%')
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [[0xFFFEF5E5, 0.0], [0xFFFFE0E0, 1.0]]
            })
            .borderRadius(12)
            .margin({ bottom: 16 })
          }

          // 卡片容器：包含从图片组件往下到碰一碰引导提示组件以上的所有内容
          Column() {
            // 调试数据显示区域
            /*Column() {
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
            .border({ width: 1, color: 0xFFCCCC })*/

            // 区域1：分享图片
            Column() {
              Row() {
                Text($r('app.string.sharepngon'))
                  .textAlign(TextAlign.Center)
                  .width('55%')
                  .margin({ right: 10 })
                // 跨设备协作状态对话框（用于接收其他设备的图片）
                CollaborationServiceStateDialog({
                  onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
                    bufferType, buffer)
                })
                if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
                  // 平板/PC设备：使用跨设备协作按钮
                  Button($r('app.string.choose'))
                    .height(50)
                    .width('40%')
                    .backgroundColor(0xb87cff)//紫色
                    .bindMenu(this.CrossDeviceMenu)
                } else {
                  // 手机设备：使用普通按钮
                  Button($r('app.string.choose'))
                    .height(50)
                    .width('40%')
                    .backgroundColor(0xb87cff)//紫色
                    .onClick(() => {
                      this.selectImage();
                    })
                }
              }
              .width('100%')
              .height(50)

              Row() {
                TextArea({ placeholder: $r('app.string.sharepng'), text: this.sharepng })
                  .layoutWeight(1)
                  .onChange((sharepng: string) => {
                    this.sharepng = sharepng;
                    if (this.isValidUrl(sharepng)) {
                      this.handleImageUpdate(); // 触发图片更新逻辑
                    }
                  })
                Row() {
                  PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                    .backgroundColor(0xb87cff)
                    .height(40)
                    .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                      if (PasteButtonOnClickResult.SUCCESS === result) {
                        pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                          if (err) {
                            console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                            return;
                          }
                          this.sharepng = pasteData.getPrimaryText();
                        });
                      }
                    })
                }
                .margin({ left: 10 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 10, bottom: 10 })
            }
            .width('100%')
            .backgroundColor($r('app.color.comp_background_list_card'))
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 10 })
            .border({ width: 1, color: $r('sys.color.comp_divider') })

            // 区域2：分享内容
            Column() {
              // 分享类型选择胶囊按钮
              Row() {
                Button('链接')
                  .fontSize(13)
                  .height(32)
                  .layoutWeight(1)
                  .backgroundColor(this.shareTypeIndex === 0 ? 0x66CCFF : 0xE0E0E0)
                  .fontColor(this.shareTypeIndex === 0 ? 0xFFFFFF : 0x000000)
                  .borderRadius(6)
                  .margin({ right: 4 })
                  .padding({ left: 4, right: 4 })
                  .onClick(() => {
                    this.shareTypeIndex = 0;
                    this.updateTitleForShareType(0);
                  })
                Button('文本')
                  .fontSize(13)
                  .height(32)
                  .layoutWeight(1)
                  .backgroundColor(this.shareTypeIndex === 1 ? 0x66CCFF : 0xE0E0E0)
                  .fontColor(this.shareTypeIndex === 1 ? 0xFFFFFF : 0x000000)
                  .borderRadius(6)
                  .margin({ right: 4 })
                  .padding({ left: 4, right: 4 })
                  .onClick(() => {
                    this.shareTypeIndex = 1;
                    this.updateTitleForShareType(1);
                  })
                Button('图片')
                  .fontSize(13)
                  .height(32)
                  .layoutWeight(1)
                  .backgroundColor(this.shareTypeIndex === 2 ? 0x66CCFF : 0xE0E0E0)
                  .fontColor(this.shareTypeIndex === 2 ? 0xFFFFFF : 0x000000)
                  .borderRadius(6)
                  .margin({ right: 4 })
                  .padding({ left: 4, right: 4 })
                  .onClick(() => {
                    this.shareTypeIndex = 2;
                    this.updateTitleForShareType(2);
                  })
                Button('视频')
                  .fontSize(13)
                  .height(32)
                  .layoutWeight(1)
                  .backgroundColor(this.shareTypeIndex === 3 ? 0x66CCFF : 0xE0E0E0)
                  .fontColor(this.shareTypeIndex === 3 ? 0xFFFFFF : 0x000000)
                  .borderRadius(6)
                  .margin({ right: 4 })
                  .padding({ left: 4, right: 4 })
                  .onClick(() => {
                    this.shareTypeIndex = 3;
                    this.updateTitleForShareType(3);
                  })
                // Button('文件') // 暂时隐藏文件分享
                //   .fontSize(13)
                //   .height(32)
                //   .layoutWeight(1)
                //   .backgroundColor(this.shareTypeIndex === 4 ? 0x66CCFF : 0xE0E0E0)
                //   .fontColor(this.shareTypeIndex === 4 ? 0xFFFFFF : 0x000000)
                //   .borderRadius(6)
                //   .padding({ left: 4, right: 4 })
                //   .onClick(() => {
                //     this.shareTypeIndex = 4;
                //     this.updateTitleForShareType(4);
                //   })
              }
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)
              .margin({ bottom: 10 })

              // 根据选择的类型显示不同的内容
              if (this.shareTypeIndex === 0) {
                // 链接分享
                Column() {
                  Row() {
                    Text($r('app.string.texton'))
                      .textAlign(TextAlign.Center)
                      .width('55%')
                      .margin({ right: 10 })

                    Button($r('app.string.scancodelink'))
                      .height(50)
                      .width('40%')
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
                            this.shareLinkContent = originalValue;
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
                  }
                  .width('100%')
                  .height(50)
                  .margin({ bottom: 10 })

                  Row() {
                    TextArea({ placeholder: $r('app.string.testinput'), text: this.shareLinkContent })
                      .layoutWeight(1)
                      .onChange((value: string) => {
                        this.shareLinkContent = value;
                        // 清除之前的防抖定时器
                        clearTimeout(this.urlDebounceTimer);
                        // 设置新的防抖定时器，300ms后执行
                        this.urlDebounceTimer = setTimeout(() => {
                          const extractedUrl = this.extractUrlFromText(value);
                          if (extractedUrl) {
                            this.shareLinkContent = extractedUrl;
                            this.networkVideoSrc = extractedUrl;
                            AppStorage.set('networkVideoSrc', extractedUrl);
                          } else {
                            this.shareLinkContent = value;
                            this.networkVideoSrc = value;
                            AppStorage.set('networkVideoSrc', value);
                          }
                        }, 300);
                      })
                    Row() {
                      PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                        .backgroundColor(0xFF66CC)
                        .height(40)
                        .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                          if (PasteButtonOnClickResult.SUCCESS === result) {
                            pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                              if (err) {
                                console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              this.shareLinkContent = pasteData.getPrimaryText();
                              this.networkVideoSrc = this.shareLinkContent;
                            });
                          }
                        })
                    }
                    .margin({ left: 10 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 10, bottom: 10 })
                }
              } else if (this.shareTypeIndex === 1) {
                // 文本分享
                Column() {
                  Row() {
                    TextArea({ placeholder: '请输入要分享的文本', text: this.shareTextContent })
                      .layoutWeight(1)
                      .onChange((value: string) => {
                        this.shareTextContent = value;
                      })
                    Row() {
                      PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                        .backgroundColor(0xFF66CC)
                        .height(40)
                        .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                          if (PasteButtonOnClickResult.SUCCESS === result) {
                            pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                              if (err) {
                                console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              this.shareTextContent = pasteData.getPrimaryText();
                            });
                          }
                        })
                    }
                    .margin({ left: 10 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  .margin({ top: 10, bottom: 10 })
                }
              } else if (this.shareTypeIndex === 2) {
                // 图片分享
                Column() {
                  Row() {
                    Text('分享图片')
                      .textAlign(TextAlign.Center)
                      .width('55%')
                      .margin({ right: 10 })
                    if (this.currentBreakpoint === 'lg' || this.currentBreakpoint === 'xl') {
                      // 平板设备：使用跨设备菜单
                      Button($r('app.string.choosepad'))
                        .height(50)
                        .width('40%')
                        .backgroundColor(0xFF66CC)
                        .bindMenu(this.CrossDeviceShareImageMenu)
                    } else {
                      // 手机设备：使用普通按钮
                      Button($r('app.string.choose'))
                        .height(50)
                        .width('40%')
                        .backgroundColor(0xFF66CC)
                        .onClick(() => {
                          this.selectShareImage();
                        })
                    }
                  }
                  .width('100%')
                  // 显示选中的所有图片路径
                  ForEach(this.shareImagePaths, (item: string, index: number) => {
                    Row() {
                      TextArea({ placeholder: `图片路径${index + 1}`, text: item })
                        .enabled(false)
                        .layoutWeight(1)
                      Button('同时作为背景图片')
                        .height(50)
                        .backgroundColor(0xFF66CC)
                        .fontSize(12)
                        .onClick(() => {
                          this.setImageAsBackground(item);
                        })
                    }
                    .width('100%')
                    .margin({ top: 5 })
                  })
                  if (this.shareImagePaths.length > 1) {
                    Text(`已选择${this.shareImagePaths.length}张图片`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 5 })
                  }
                }
              } else if (this.shareTypeIndex === 3) {
                // 视频分享
                Column() {
                  Row() {
                    Text('分享视频')
                      .textAlign(TextAlign.Center)
                      .width('55%')
                      .margin({ right: 10 })
                    Button('选择视频')
                      .height(50)
                      .width('40%')
                      .backgroundColor(0xFF66CC)
                      .onClick(async () => {
                        await this.selectVideo();
                      })
                  }
                  .width('100%')
                  // 显示选中的所有视频路径
                  ForEach(this.shareVideoPaths, (item: string, index: number) => {
                    Row() {
                      TextArea({ placeholder: `视频路径${index + 1}`, text: item })
                        .enabled(false)
                        .layoutWeight(1)
                      // 暂时屏蔽裁剪视频功能
                      // if (this.shareVideoPath) {
                      //   Button('裁剪视频')
                      //     .height(50)
                      //     .backgroundColor(0xFF66CC)
                      //     .fontSize(12)
                      //     .onClick(() => {
                      //       this.openVideoTrimmer();
                      //     })
                      // }
                    }
                    .width('100%')
                    .margin({ top: 5 })
                  })
                  if (this.shareVideoPaths.length > 1) {
                    Text(`已选择${this.shareVideoPaths.length}个视频`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 5 })
                  }
                }
              } else if (this.shareTypeIndex === 4) {
                // 文件分享
                Column() {
                  Row() {
                    Text('分享文件')
                      .textAlign(TextAlign.Center)
                      .width('55%')
                      .margin({ right: 10 })
                    Button('选择文件')
                      .height(50)
                      .width('40%')
                      .backgroundColor(0xFF66CC)
                      .onClick(async () => {
                        await this.selectFile();
                      })
                  }
                  .width('100%')
                  // 显示选中的所有文件路径
                  ForEach(this.shareFilePaths, (item: string, index: number) => {
                    TextArea({ placeholder: `文件路径${index + 1}`, text: item })
                      .enabled(false)
                      .margin({ top: 5 })
                  })
                  if (this.shareFilePaths.length > 1) {
                    Text(`已选择${this.shareFilePaths.length}个文件`)
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ top: 5 })
                  }
                  Row() {
                    Text('下载网络文件')
                      .width('55%')
                      .margin({ right: 10 })
                      .textAlign(TextAlign.Center)
                    Button('下载并分享')
                      .height(50)
                      .width('40%')
                      .backgroundColor(0xFF66CC)
                      .onClick(() => {
                        this.downloadAndShare();
                      })
                  }
                  .width('100%')
                  .margin({ top: 10, bottom: 10 })
                  Row() {
                    TextArea({ placeholder: '输入网络文件下载链接', text: this.downloadUrl })
                      .layoutWeight(1)
                      .onChange((value: string) => {
                        this.downloadUrl = value;
                      })
                    Row() {
                      PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                        .backgroundColor(0xFF66CC)
                        .height(40)
                        .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                          if (PasteButtonOnClickResult.SUCCESS === result) {
                            pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                              if (err) {
                                console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                                return;
                              }
                              this.downloadUrl = pasteData.getPrimaryText();
                            });
                          }
                        })
                    }
                    .margin({ left: 10 })
                  }
                  .width('100%')
                  .alignItems(VerticalAlign.Center)
                  if (this.downloadProgress !== '0' && this.downloadProgress !== '100') {
                    Text(`下载进度: ${this.downloadProgress}%`)
                      .fontSize(14)
                      .fontColor(0x66CCFF)
                      .margin({ top: 5, bottom: 5 })
                  }
                }
              }
            }
            .width('100%')
            .backgroundColor($r('app.color.comp_background_list_card'))
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 10 })
            .border({ width: 1, color: $r('app.color.card_border_color') })

            // 区域3：分享标题
            Column() {
              Row() {
                Text($r('app.string.pengtitleset'))
                  .textAlign(TextAlign.Center)
                  .width('100%')
              }
              .width('100%')
              .height(50)

              Row() {
                TextArea({ placeholder: this.getTitlePlaceholder(), text: this.pengtitle })
                  .layoutWeight(1)
                  .onChange((pengtitle: string) => {
                    this.pengtitle = pengtitle;
                    AppStorage.set('pengtitle', pengtitle);
                  })
                Row() {
                  PasteButton({ icon: PasteIconStyle.LINES, buttonType: ButtonType.ROUNDED_RECTANGLE })
                    .backgroundColor(0x66CCFF)
                    .height(40)
                    .onClick((_event: ClickEvent, result: PasteButtonOnClickResult) => {
                      if (PasteButtonOnClickResult.SUCCESS === result) {
                        pasteboard.getSystemPasteboard().getData((err: BusinessError, pasteData: pasteboard.PasteData) => {
                          if (err) {
                            console.error(`Failed to get paste data. Code is ${err.code}, message is ${err.message}`);
                            return;
                          }
                          this.pengtitle = pasteData.getPrimaryText();
                        });
                      }
                    })
                }
                .margin({ left: 10 })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
              .margin({ top: 5, bottom: 10 })
            }
            .width('100%')
            .backgroundColor($r('app.color.comp_background_list_card'))
            .borderRadius(8)
            .padding(12)
            .margin({ bottom: 10 })
            .border({ width: 1, color: $r('app.color.card_border_color') })
          }

          // 系统分享按钮
          Button($r('app.string.share'))
            .width('90%')
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
            .margin({ bottom: 20 })

          //碰一碰提示
          if (this.currentBreakpoint !== 'lg' && this.currentBreakpoint !== 'xl') {
            Column() {
              Text($r('app.string.nowplayingon'))
                .padding({ top: 10 , left: 24, right: 24 })
                .maxLines(2)
                .fontSize(11)
                .maxFontScale(1.75)
                .width('100%')
                .constraintSize({ minHeight: 16 })
                .fontColor($r('app.color.font_secondary'))
                .fontFamily('HarmonyHeiTi')
                .textAlign(TextAlign.Center)
              KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResources  })
                .padding({ top: 2 })
            }
            .width('100%')
          } else {
            // 大屏设备提示
            Column() {
              Text($r('app.string.large_device_hint'))
                .fontSize(11)
                .maxFontScale(1.75)
                .width('100%')
                .fontColor($r('app.color.font_secondary'))
                .fontFamily('HarmonyHeiTi')
                .textAlign(TextAlign.Center)
                .lineHeight(18)
                .padding({ top: 20, bottom: 20 })
            }
            .width('90%')
          }
        }
        .width('90%')
        .alignItems(HorizontalAlign.Center) // 内容水平居中
        .margin({ top: 10 })
      }
      }
    }
    .width(CommonConstants.FULL_PARENT)
    .height(CommonConstants.FULL_PARENT)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[this.topBgColor, CommonConstants.START_GRADIENT_RANGE], [$r('app.color.page_background_gradient_end'), CommonConstants.END_GRADIENT_RANGE]]
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

  // 处理新年卡片点击 - 快速设置分享内容
  private handleNewYearCardClick(card: NewYearCard) {
    // 更新分享标题
    this.pengtitle = card.title;
    AppStorage.set('pengtitle', card.title);

    // 更新分享链接内容
    this.shareLinkContent = card.jumpUrl;

    // 更新背景图片
    this.sharepng = card.imageUrl;
    this.backgroundImagePath = card.imageUrl;
    AppStorage.set('sharepng', card.imageUrl);

    // 触发图片更新
    this.handleImageUpdate();

    // 提示用户
    promptAction.showToast({ message: `已切换到: ${card.title}` });
  }

  // 新年卡片Builder - 已废弃,现在直接使用按钮
  @Builder
  NewYearCardItem(card: NewYearCard, index: number) {
    // 此Builder已废弃,新年卡片现在直接显示为按钮
  }

  // 跨设备协作菜单 Builder
  @Builder
  CrossDeviceMenu() {
    Menu() {
      MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.pickphotos'),
        builder: (): void => {
          this.selectImage();
        }
      })
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL], 1)
    }
  }

  // 跨设备协作菜单 Builder - 分享图片专用
  @Builder
  CrossDeviceShareImageMenu() {
    Menu() {
      MenuItem({
        startIcon: $r("app.media.CIcon"),
        content: $r('app.string.pickphotos'),
        builder: (): void => {
          this.selectShareImage();
        }
      })
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL], 1)
    }
  }

  // 选择视频
  private async selectVideo(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE,
        maxSelectNumber: 500 // 最多选择500个视频
      }).then((res: photoAccessHelper.PhotoSelectResult) => {
        this.shareVideoPaths = res.photoUris;
        this.shareVideoPath = res.photoUris[0]; // 第一个视频用于显示
        if (res.photoUris.length > 1) {
          promptAction.showToast({ message: `已选择${res.photoUris.length}个视频` });
        } else {
          promptAction.showToast({ message: '视频选择成功' });
        }
        resolve();
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'HomePage', `Failed to select video. code：${err.code}，message：${err.message}`);
        promptAction.showToast({ message: '选择视频失败' });
        reject(err);
      });
    });
  }

  // 选择文件（使用文件分享API）
  private async selectFile(): Promise<void> {
    try {
      hilog.info(0x0000, 'HomePage', 'Start selecting file');
      // 使用文件系统API选择文件
      const documentPicker = new picker.DocumentViewPicker();
      const options: picker.DocumentSelectOptions = {
        maxSelectNumber: 10,
        fileSuffixFilters: ['.*']
      };
      hilog.info(0x0000, 'HomePage', 'Calling documentPicker.select');
      const result = await documentPicker.select(options);
      hilog.info(0x0000, 'HomePage', `Document picker returned ${result.length} results`);
      if (result && result.length > 0) {
        this.shareFilePaths = result;
        this.shareFilePath = result[0]; // 第一个文件用于显示
        if (result.length > 1) {
          promptAction.showToast({ message: `已选择${result.length}个文件` });
        } else {
          hilog.info(0x0000, 'HomePage', `File selected: ${this.shareFilePath}`);
          promptAction.showToast({ message: '文件选择成功' });
        }
      } else {
        hilog.info(0x0000, 'HomePage', 'No file selected or user cancelled');
      }
    } catch (err) {
      let error = err as BusinessError;
      hilog.error(0x0000, 'HomePage', `Failed to select file. code：${error.code}，message：${error.message}`);
      promptAction.showToast({ message: '选择文件失败' });
    }
  }

  // 获取文件名
  private getFileName(url: string): string {
    let date = new Date();
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    let hour = date.getHours();
    let minute = date.getMinutes();
    let seconds = date.getSeconds();

    // 从URL中提取扩展名
    let extension = '';
    let lastSlashIndex = url.lastIndexOf('/');
    let lastDotIndex = url.lastIndexOf('.');
    if (lastDotIndex > lastSlashIndex) {
      extension = url.substring(lastDotIndex);
    }

    return `${year}${month}${day}${hour}${minute}${seconds}${extension}`;
  }

  // 分享下载的文件
  private shareDownloadedFile(contextFaker: Context, uri: string) {
    // 根据文件扩展名获取UTD类型
    let extension = this.shareFilePath.substring(this.shareFilePath.lastIndexOf('.'));
    let utdTypeId = utd.getUniformDataTypeByFilenameExtension(extension, utd.UniformDataType.FILE);

    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utdTypeId,
      uri: uri,
      content: this.shareFilePath,
      title: '分享文件',
      description: '分享文件',
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    controller.on('dismiss', () => {
      console.log('Download share panel closed');
    });
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DETAIL,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      console.info('ShareController show success.');
    }).catch((err: BusinessError) => {
      console.error(`ShareController show error. code: ${err.code}, message: ${err.message}`);
    });
  }

  // 下载文件
  private async downloadAndShare() {
    if (!this.downloadUrl) {
      promptAction.showToast({ message: '请输入下载链接' });
      return;
    }

    const uiContext = this.getUIContext();
    let contextFaker: Context = uiContext.getHostContext() as Context;

    // 创建下载目录
    let cacheDir = contextFaker.cacheDir;
    let dirPath = cacheDir + '/down_export';
    let fileName = this.getFileName(this.downloadUrl);
    let filePath = dirPath + '/' + fileName;

    // 创建目录
    fs.mkdir(dirPath).then(() => {
      console.info("mkdir succeed");
    }).catch((err: BusinessError) => {
      if (err.code !== 13900015) {
        console.error("mkdir failed with error message: " + err.message + ", error code: " + err.code);
      }
    });

    try {
      // 判断文件是否已存在
      let res = fs.accessSync(filePath);
      if (res) {
        promptAction.showToast({ message: '文件已存在' });
        console.info('file exists');
        this.shareFilePath = filePath;
        let uri = fileUri.getUriFromPath(filePath);
        this.shareDownloadedFile(contextFaker, uri);
      } else {
        // 下载文件
        request.downloadFile(contextFaker, {
          url: this.downloadUrl,
          filePath: filePath
        }).then((downloadTask: request.DownloadTask) => {
          let progressCallback = (receivedSize: number, totalSize: number) => {
            this.downloadProgress = ((receivedSize / totalSize) * 100).toFixed(2);
            promptAction.showToast({
              message: `下载进度: ${this.downloadProgress}%`,
            });
          };
          downloadTask.on('progress', progressCallback);

          downloadTask.on('complete', () => {
            promptAction.showToast({ message: `下载完成，存储目录：${filePath}` });
            this.shareFilePath = filePath;
            let uri = fileUri.getUriFromPath(filePath);
            this.shareDownloadedFile(contextFaker, uri);
          });

          downloadTask.on('fail', (err: number) => {
            if (err == 13900015) {
              console.info('目录已存在');
            } else {
              console.error('Download failed with error code: ' + err);
            }
          });
        }).catch((err: BusinessError) => {
          if (err.code == 13900015) {
            console.info('目录已存在');
          } else {
            console.error('downloadFile failed: ' + JSON.stringify(err));
          }
        });
      }
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      console.error(`Invoke downloadTask downloadFile failed, code is ${err.code}, message is ${err.message}`);
    }
  }
}