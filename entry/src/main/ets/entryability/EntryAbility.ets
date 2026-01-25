import { createDbInsertData } from '../formcommon/DbIndex';
import { actionCreate, actionNewWant, actionWindowStageCreate } from '../formcommon/formsetting/FormAction';
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
//接续
import { ContentInfo } from '../model/ContentInfo';
import { distributedDataObject } from '@kit.ArkData';
import Logger from '../utils/Loggerr';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { BreakpointSystem } from '../common/utils/BreakpointType';
import { WindowUtil } from '../common/utils/WindowUtils';

interface CustomDataObject extends distributedDataObject.DataObject {
  networkVideoSrc?: string;
}

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  private windowUtil?: WindowUtil = WindowUtil.getInstance();
  private onWindowSizeChange: (windowSize: window.Size, context: UIContext) => void = (_, context) => {
    this.windowUtil!.updateWidthBp(context);
  }
  private selectPage: string = '';
  private currentWindowStage: window.WindowStage | null = null;
  private distributedObject: distributedDataObject.DataObject | undefined = undefined;
  private windowClass?: window.Window = undefined;
  storage: LocalStorage = new LocalStorage();
  private want: Want | undefined = undefined;
  private launchParam: AbilityConstant.LaunchParam | undefined = undefined;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.want = want;
    this.launchParam = launchParam;
    actionCreate(want);
    createDbInsertData(this.context);
    //接续
    this.restoreDistributedObject(want, launchParam);
    this.storage.setOrCreate('networkVideoSrc', 'default_url');
    // 初始化 networkVideoSrc
    this.storage.setOrCreate('networkVideoSrc', 'default_url');
    // 在页面加载时显式检查
    if (!this.storage.get('networkVideoSrc')) {
      hilog.error(DOMAIN_NUMBER, TAG, 'Invalid video URL detected');
    }
    // 处理分享链接（AppLinking/碰一碰）
    const receivedLink = want.parameters?.['link'] || want.uri;
    if (receivedLink) {
      AppStorage.setOrCreate<string>('sharedVideoUrl', receivedLink.toString());
    }

    // 原有扫码逻辑保留
    let uri = want?.uri;
    if (uri) {
      // 保存视频URL到AppStorage,供HomePage使用
      AppStorage.setOrCreate<string>('sharedVideoUrl', uri.toString());
    }

    // 保留原有逻辑
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN_NUMBER, TAG, `Ability onCreate: ${JSON.stringify(want?.parameters)}`);
    if (want?.parameters?.params) {
      // want.parameters.params 对应 postCardAction() 中 params 内容
      let params: Record<string, Object> = JSON.parse(want.parameters.params as string);
      this.selectPage = params.targetPage as string;
      hilog.info(DOMAIN_NUMBER, TAG, `onCreate selectPage: ${this.selectPage}`);
    }
    this.context.eventHub.emit('urlUpdate', receivedLink)

    //快捷方式的快速打开页面跳转
    if (want.parameters?.ShortCutPage) {
      // 保存快捷方式参数到AppStorage
      AppStorage.setOrCreate<string>('ShortCutPage', want.parameters.ShortCutPage as string);
    }
  }

  // 热启动场景通过onNewWant回调获取码值信息
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    actionNewWant(want, this);
    createDbInsertData(this.context);
    const receivedLink = want.parameters?.['link'] || want.uri;
    if (receivedLink) {
      AppStorage.setOrCreate<string>('sharedVideoUrl', receivedLink.toString());
      // 触发页面刷新逻辑
      this.currentWindowStage?.loadContent('pages/HomePage')
    }
    // 保留原有逻辑
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    //接续
    this.restoreDistributedObject(want, launchParam);
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  // 更新导航条高度，针对平板横竖屏切换
  private updateNaviIndicatorHeight(windowClass: window.Window): void {
    try {
      const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel') || new GlobalInfoModel();
      // 增加额外间距，确保底部避让更充分
      globalInfoModel.naviIndicatorHeight = px2vp(avoidArea.bottomRect.height) + 16;
      AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
      hilog.info(0x0000, 'testTag', 'NaviIndicator height updated: %{public}d', globalInfoModel.naviIndicatorHeight);
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to update naviIndicatorHeight. Cause: %{public}s', JSON.stringify(error) ?? '');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 初始化 GlobalInfoModel
    const globalInfoModel = new GlobalInfoModel();
    AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
    actionWindowStageCreate(windowStage);
    // Main window is created, set main page for this ability
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Succeeded in loading the content.');
      try {
        let uiContext: UIContext | undefined = windowStage.getMainWindowSync().getUIContext();
        AppStorage.setOrCreate('uiContext', uiContext);
      } catch (error) {
        hilog.error(0x0000, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(error) ?? '');
      }
      //接续
      if (!this.storage.get('networkVideoSrc')) {
        Logger.warn(TAG, 'networkVideoSrc is empty!');
      }
    });
    let windowClass: window.Window | undefined = undefined;
    windowStage.getMainWindow((err: BusinessError, data: window.Window) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to get the main window. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }

      try {
        // 获取状态栏高度和其他窗口信息
        const avoidArea = data.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
        const windowProperties = data.getWindowProperties();
        const globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel') || new GlobalInfoModel();

        globalInfoModel.statusBarHeight = px2vp(avoidArea.topRect.height);
        // 增加额外间距，确保底部避让更充分
        globalInfoModel.naviIndicatorHeight = px2vp(avoidArea.bottomRect.height) + 16;
        globalInfoModel.decorHeight = windowProperties.windowRect.height;
        globalInfoModel.deviceHeight = px2vp(windowProperties.windowRect.height);
        globalInfoModel.deviceWidth = px2vp(windowProperties.windowRect.width);

        AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
        hilog.info(0x0000, 'testTag', 'StatusBar height: %{public}d', globalInfoModel.statusBarHeight);

        // 初始化断点系统
        BreakpointSystem.getInstance().updateWidthBp(data);

        this.windowUtil!.updateWidthBp(windowStage.getMainWindowSync().getUIContext());
        data.on('windowSizeChange', (windowSize: window.Size) => {
          this.onWindowSizeChange(windowSize, windowStage.getMainWindowSync().getUIContext());
          // 在窗口大小变化时更新导航条高度，针对平板横竖屏切换
          this.updateNaviIndicatorHeight(data);
        });
        windowClass = data;
        if (deviceInfo.deviceType === '2in1') {
          data.setWindowDecorVisible(false);
          data.setWindowDecorHeight(0);
        } else {
          windowClass.setWindowLayoutFullScreen(true).catch((error: BusinessError) => {
            hilog.error(0x0000, 'testTag', 'Failed to set window layout full screen. Cause: %{public}s', JSON.stringify(error) ?? '');
          });
        }
      } catch (error) {
        hilog.error(0x0000, 'testTag', 'Failed to  get main window. Cause: %{public}s', JSON.stringify(error) ?? '');
      }
    });
  }

  //接续
  private async restoreDistributedObject(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.distributedObject = distributedDataObject.create(this.context, {});
      // 从分布式对象中恢复网络地址
      const restoredUrl: string | undefined = (this.distributedObject as CustomDataObject)?.networkVideoSrc;
      if (restoredUrl) {
        this.storage.set('networkVideoSrc', restoredUrl);
      } else {
        hilog.warn(DOMAIN_NUMBER, TAG, 'No distributed data found');
      }
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 'Restore failed: %{public}s', JSON.stringify(err));
    }
  }

  async onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult> {
    const networkVideoSrc: string | null | undefined = this.storage.get('networkVideoSrc');
    if (networkVideoSrc !== null && networkVideoSrc !== undefined) {
      wantParam.networkVideoSrc = networkVideoSrc;
    }
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    this.currentWindowStage = null;
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }
}