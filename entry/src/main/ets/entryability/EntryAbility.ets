import { createDbInsertData } from '../formcommon/DbIndex';
import { actionCreate, actionNewWant, actionWindowStageCreate } from '../formcommon/formsetting/FormAction';
import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';
import { url } from '@kit.ArkTS';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to card action.
     */
    actionCreate(want)


    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to create a database and insert update card data.
     */
    createDbInsertData(this.context)


    hilog.info(0x0001, '[Scan Access]', 'Ability onCreate');

    // 处理扫码结果
    let uri = want?.uri;
    if (uri) {
      try {
        // 解析URL
        let urlObject = url.URL.parseURL(uri);
        if (!urlObject) {
          throw new Error('Invalid URL format');
        }

        // 传递扫码结果
        router.pushUrl({
          url: 'pages/Index',
          params: {
            videoUrl: uri,
            source: 'scan'
          }
        });

        hilog.info(0x0001, '[Scan Access]', `Processed scan result: ${uri}`);
      } catch (error) {
        hilog.error(0x0001, '[Scan Access]',
          `Failed to process scan result: ${error.message}`);
      }
    }

    // 保留原有逻辑
    actionCreate(want);
    createDbInsertData(this.context);
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  }
// 热启动场景通过onNewWant回调获取码值信息
  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to card action.
     */
    actionNewWant(want, this);


    hilog.info(0x0001, '[Scan Access]', 'Ability onNewWant');

    // 处理扫码结果
    let uri = want?.uri;
    if (uri) {
      try {
        // 解析URL
        let urlObject = url.URL.parseURL(uri);
        if (!urlObject) {
          throw new Error('Invalid URL format');
        }

        // 传递扫码结果
        router.pushUrl({
          url: 'pages/Index',
          params: {
            videoUrl: uri,
            source: 'scan'
          }
        });

        hilog.info(0x0001, '[Scan Access]', `Processed scan result: ${uri}`);
      } catch (error) {
        hilog.error(0x0001, '[Scan Access]',
          `Failed to process scan result: ${error.message}`);
      }
    }

    // 保留原有逻辑
    actionNewWant(want, this);
    createDbInsertData(this.context);
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
  }
  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to card action.
     */
    actionWindowStageCreate(windowStage);
    // Main window is created, set main page for this ability
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        return;
      }

      let windowClass: window.Window = windowStage.getMainWindowSync(); // 获取应用主窗口
      // 1. 设置窗口全屏
      let isLayoutFullScreen = true;
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
      });


    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
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