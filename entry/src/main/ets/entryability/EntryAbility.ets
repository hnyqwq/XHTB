import { createDbInsertData } from '../formcommon/DbIndex';
import { actionCreate, actionNewWant, actionWindowStageCreate } from '../formcommon/formsetting/FormAction';
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { url } from '@kit.ArkTS';
import { promptAction } from '@kit.ArkUI';
//接续
import { ContentInfo } from '../model/ContentInfo';
import { commonType, distributedDataObject } from '@kit.ArkData';
import Logger from '../utils/Loggerr';

interface CustomDataObject extends distributedDataObject.DataObject {
  networkVideoSrc?: string;
}

const TAG: string = 'EntryAbility';
const DOMAIN_NUMBER: number = 0xFF00;

export default class EntryAbility extends UIAbility {
  private selectPage: string = '';
  private currentWindowStage: window.WindowStage | null = null;
  private distributedObject: distributedDataObject.DataObject | undefined = undefined;
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
    setTimeout(() => {
      if (uri) {
        router.pushUrl({
          url: 'pages', // 直接跳转到视频页面
          params: {
            videoUrl: uri,
            source: 'scan'
          }
        });
      }
    })

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

  onWindowStageCreate(windowStage: window.WindowStage): void {
    actionWindowStageCreate(windowStage);
    // Main window is created, set main page for this ability
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        return;
      }
      let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      // 1. 设置窗口全屏
      /*let isLayoutFullScreen = true;
      windowClass.setWindowLayoutFullScreen(isLayoutFullScreen).then(() => {
        console.info('Succeeded in setting the window layout to full-screen mode.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the window layout to full-screen mode. Code is ${err.code}, message is ${err.message}`);
      });
      // 进行后续步骤2-3中的操作
      //2
      windowClass.setSpecificSystemBarEnabled('status', false).then(() => {
        console.info('Succeeded in setting the status bar to be invisible.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the status bar to be invisible. Code is ${err.code}, message is ${err.message}`);
      });
      //3
      windowClass.setSpecificSystemBarEnabled('navigationIndicator', false).then(() => {
        console.info('Succeeded in setting the navigation indicator to be invisible.');
      }).catch((err: BusinessError) => {
        console.error(`Failed to set the navigation indicator to be invisible. Code is ${err.code}, message is ${err.message}`);
      });*/
      //接续
      if (!this.storage.get('networkVideoSrc')) {
        Logger.warn(TAG, 'networkVideoSrc is empty!');
      }
    });
  }

  //接续
  // EntryAbility.ets
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