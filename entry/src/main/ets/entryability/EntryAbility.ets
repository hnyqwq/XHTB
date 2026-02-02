import { createDbInsertData } from '../formcommon/DbIndex';
import { actionCreate, actionNewWant, actionWindowStageCreate } from '../formcommon/formsetting/FormAction';
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { AppUtil } from '@pura/harmony-utils';
//接续
import { ContentInfo } from '../model/ContentInfo';
import { distributedDataObject } from '@kit.ArkData';
import Logger from '../utils/EntryAbillityLogger';
import { GlobalInfoModel } from '../common/GlobalInfoModel';
import { BreakpointSystem } from '../common/utils/BreakpointType';
import { WindowUtil } from '../common/utils/WindowUtils';

interface CustomDataObject extends distributedDataObject.DataObject {
  networkVideoSrc?: string;
  sharepng?: string;
  pengtitle?: string;
  currentTabIndex?: number; // 当前选中的 Tab 索引
  currentPageUrl?: string; // 当前页面 URL
  currentRouteParams?: string; // 当前路由参数（JSON 字符串）
  shareLinkContent?: string; // 分享链接/文本内容
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
  private isContinuation: boolean = false; // 标记是否为接续场景

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.want = want;
    this.launchParam = launchParam;
    AppUtil.init(this.context);
    actionCreate(want);
    createDbInsertData(this.context);
    //接续 - 先标记是接续场景
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      this.isContinuation = true;
    }
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
      globalInfoModel.naviIndicatorHeight = px2vp(avoidArea.bottomRect.height);
      AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
      hilog.info(0x0000, 'testTag', 'NaviIndicator height updated: %{public}d', globalInfoModel.naviIndicatorHeight);
    } catch (error) {
      hilog.error(0x0000, 'testTag', 'Failed to update naviIndicatorHeight. Cause: %{public}s', JSON.stringify(error) ?? '');
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.currentWindowStage = windowStage;
    // 初始化 GlobalInfoModel
    const globalInfoModel = new GlobalInfoModel();
    AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
    actionWindowStageCreate(windowStage);

    // 如果是接续场景,从 want 中获取初始 Tab 索引和页面 URL
    if (this.isContinuation && this.want) {
      const restoredTabIndex = this.want.parameters?.['currentTabIndex'] as number;
      const restoredPageUrl = this.want.parameters?.['currentPageUrl'] as string;
      const restoredRouteParams = this.want.parameters?.['currentRouteParams'] as string;

      if (restoredTabIndex !== undefined && restoredTabIndex !== null) {
        AppStorage.setOrCreate('initialTabIndex', restoredTabIndex);
        hilog.info(DOMAIN_NUMBER, TAG, 'onWindowStageCreate: Set initialTabIndex = %{public}d', restoredTabIndex);
      }

      if (restoredPageUrl !== undefined && restoredPageUrl !== null) {
        AppStorage.setOrCreate('continuationPageUrl', restoredPageUrl);
        if (restoredRouteParams !== undefined && restoredRouteParams !== null) {
          AppStorage.setOrCreate('continuationRouteParams', restoredRouteParams);
        }
        hilog.info(DOMAIN_NUMBER, TAG, 'onWindowStageCreate: Set continuationPageUrl = %{public}s', restoredPageUrl);
      }
    }

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
        globalInfoModel.naviIndicatorHeight = px2vp(avoidArea.bottomRect.height);
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

  onWindowStageRestore(windowStage: window.WindowStage): void {
    this.currentWindowStage = windowStage;
    hilog.info(0x0000, 'testTag', 'onWindowStageRestore called - continuation mode');

    // 接续场景,从 want 中获取初始 Tab 索引和页面 URL
    if (this.want) {
      const restoredTabIndex = this.want.parameters?.['currentTabIndex'] as number;
      const restoredPageUrl = this.want.parameters?.['currentPageUrl'] as string;
      const restoredRouteParams = this.want.parameters?.['currentRouteParams'] as string;

      if (restoredTabIndex !== undefined && restoredTabIndex !== null) {
        AppStorage.setOrCreate('initialTabIndex', restoredTabIndex);
        hilog.info(0x0000, 'testTag', 'onWindowStageRestore: Set initialTabIndex = %{public}d', restoredTabIndex);
      } else {
        AppStorage.setOrCreate('initialTabIndex', 0);
      }

      if (restoredPageUrl !== undefined && restoredPageUrl !== null) {
        AppStorage.setOrCreate('continuationPageUrl', restoredPageUrl);
        if (restoredRouteParams !== undefined && restoredRouteParams !== null) {
          AppStorage.setOrCreate('continuationRouteParams', restoredRouteParams);
        }
        hilog.info(0x0000, 'testTag', 'onWindowStageRestore: Set continuationPageUrl = %{public}s', restoredPageUrl);
      }
    } else {
      AppStorage.setOrCreate('initialTabIndex', 0);
    }

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'testTag', 'Failed to load Index for continuation. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(0x0000, 'testTag', 'Index loaded successfully for continuation.');
      try {
        let uiContext: UIContext | undefined = windowStage.getMainWindowSync().getUIContext();
        AppStorage.setOrCreate('uiContext', uiContext);
      } catch (error) {
        hilog.error(0x0000, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(error) ?? '');
      }
    });

    // 窗口初始化
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
        globalInfoModel.naviIndicatorHeight = px2vp(avoidArea.bottomRect.height);
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
        hilog.error(0x0000, 'testTag', 'Failed to get main window. Cause: %{public}s', JSON.stringify(error) ?? '');
      }
    });
  }

  //接续
  private async restoreDistributedObject(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      hilog.info(DOMAIN_NUMBER, TAG, 'Starting restoreDistributedObject');
      hilog.info(DOMAIN_NUMBER, TAG, 'Want parameters: %{public}s', JSON.stringify(want.parameters));

      // 接续数据在 want.parameters 中,不在分布式对象中
      const restoredUrl: string = want.parameters?.['networkVideoSrc'] as string;
      const restoredSharepng: string = want.parameters?.['sharepng'] as string;
      const restoredPengtitle: string = want.parameters?.['pengtitle'] as string;
      const restoredShareLinkContent: string = want.parameters?.['shareLinkContent'] as string;

      // 恢复网络视频地址
      if (restoredUrl && restoredUrl !== 'default_url') {
        this.storage.set('networkVideoSrc', restoredUrl);
        AppStorage.setOrCreate('networkVideoSrc', restoredUrl);
        hilog.info(DOMAIN_NUMBER, TAG, 'Restored networkVideoSrc: %{public}s', restoredUrl);
      }

      // 恢复背景图片地址
      if (restoredSharepng && restoredSharepng !== 'https://www.hnyqwq.cn/png/sharelink.png') {
        AppStorage.setOrCreate('sharepng', restoredSharepng);
        hilog.info(DOMAIN_NUMBER, TAG, 'Restored sharepng: %{public}s', restoredSharepng);
      }

      // 恢复分享标题
      if (restoredPengtitle && restoredPengtitle !== ' ') {
        this.storage.set('pengtitle', restoredPengtitle);
        AppStorage.setOrCreate('pengtitle', restoredPengtitle);
        hilog.info(DOMAIN_NUMBER, TAG, 'Restored pengtitle: %{public}s', restoredPengtitle);
      }

      // 恢复分享链接/文本内容
      if (restoredShareLinkContent && restoredShareLinkContent !== '') {
        this.storage.set('shareLinkContent', restoredShareLinkContent);
        AppStorage.setOrCreate('shareLinkContent', restoredShareLinkContent);
        hilog.info(DOMAIN_NUMBER, TAG, 'Restored shareLinkContent: %{public}s', restoredShareLinkContent);
      } else {
        hilog.info(DOMAIN_NUMBER, TAG, 'restoredShareLinkContent 为空或默认值: %{public}s', restoredShareLinkContent ?? 'undefined');
      }

      const hasData = (restoredUrl && restoredUrl !== 'default_url') ||
                      (restoredSharepng && restoredSharepng !== 'https://www.hnyqwq.cn/png/sharelink.png') ||
                      (restoredPengtitle && restoredPengtitle !== ' ') ||
                      (restoredShareLinkContent && restoredShareLinkContent !== '');

      if (!hasData) {
        hilog.warn(DOMAIN_NUMBER, TAG, 'No valid continuation data found (only default values)');
      } else {
        hilog.info(DOMAIN_NUMBER, TAG, 'Continuation data restored successfully');
      }
    } catch (err) {
      hilog.error(DOMAIN_NUMBER, TAG, 'Restore failed: %{public}s', JSON.stringify(err));
    }
  }

  async onContinue(wantParam: Record<string, Object>): Promise<AbilityConstant.OnContinueResult> {
    hilog.info(DOMAIN_NUMBER, TAG, '=== onContinue 开始 ===');

    // 从AppStorage获取三个文本框的内容
    const networkVideoSrc: string | null | undefined = AppStorage.get('networkVideoSrc');
    const sharepng: string | null | undefined = AppStorage.get('sharepng');
    const pengtitle: string | null | undefined = AppStorage.get('pengtitle');
    const shareLinkContent: string | null | undefined = AppStorage.get('shareLinkContent');

    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: networkVideoSrc = %{public}s', networkVideoSrc ?? 'undefined');
    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: sharepng = %{public}s', sharepng ?? 'undefined');
    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: pengtitle = %{public}s', pengtitle ?? 'undefined');
    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: shareLinkContent = %{public}s', shareLinkContent ?? 'undefined');
    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: wantParam = %{public}s', JSON.stringify(wantParam));

    // 获取当前选中的 Tab 索引
    const currentTabIndex: number | null | undefined = AppStorage.get('currentTabIndex');

    // 获取当前页面 URL 和路由参数
    const currentPageUrl: string | null | undefined = AppStorage.get('currentPageUrl');
    const currentRouteParams: string | null | undefined = AppStorage.get('currentRouteParams');

    // 将数据传递到wantParam
    if (networkVideoSrc !== null && networkVideoSrc !== undefined) {
      wantParam.networkVideoSrc = networkVideoSrc;
    }
    if (sharepng !== null && sharepng !== undefined) {
      wantParam.sharepng = sharepng;
    }
    if (pengtitle !== null && pengtitle !== undefined) {
      wantParam.pengtitle = pengtitle;
    }
    if (shareLinkContent !== null && shareLinkContent !== undefined) {
      wantParam.shareLinkContent = shareLinkContent;
      hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: 设置 wantParam.shareLinkContent = %{public}s', shareLinkContent);
    } else {
      hilog.warn(DOMAIN_NUMBER, TAG, 'onContinue: shareLinkContent 为空，未设置到 wantParam');
    }
    // 传递当前 Tab 索引
    if (currentTabIndex !== null && currentTabIndex !== undefined) {
      wantParam.currentTabIndex = currentTabIndex;
    }
    // 传递当前页面 URL
    if (currentPageUrl !== null && currentPageUrl !== undefined) {
      wantParam.currentPageUrl = currentPageUrl;
    }
    // 传递当前路由参数
    if (currentRouteParams !== null && currentRouteParams !== undefined) {
      wantParam.currentRouteParams = currentRouteParams;
    }

    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: currentTabIndex = %{public}d, currentPageUrl = %{public}s',
      currentTabIndex ?? -1, currentPageUrl ?? 'none');

    // 打印完整的 wantParam，确认数据是否被正确设置
    hilog.info(DOMAIN_NUMBER, TAG, 'onContinue: wantParam 最终内容 = %{public}s', JSON.stringify(wantParam));

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