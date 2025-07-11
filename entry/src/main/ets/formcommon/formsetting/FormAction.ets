import { window } from '@kit.ArkUI';
import { UIAbility, Want } from '@kit.AbilityKit';

let  selectPage: string = "";
let  currentWindowStage: window.WindowStage | null = null;

/**
 * Retrieve the 'targetPage' parameter passed in the router event
 * @param want
 */
export function actionCreate(want: Want) {
  if (want.parameters?.params !== undefined) {
    let params: Record<string, string> = JSON.parse(want.parameters?.params.toString());
    console.info("onCreate router targetPage:" + params.targetPage);
    selectPage = params.targetPage;
  }
}

/**
 * If the UIAbility is already running in the background,
 * the onNewWant lifecycle callback will be triggered upon receiving a Router event
 * @param want
 * @param entryAbility
 */
export function actionNewWant(want: Want, entryAbility: UIAbility) {
  if (want.parameters?.params !== undefined) {
    let params: Record<string, string> = JSON.parse(want.parameters?.params.toString());
    console.info("onNewWant router targetPage:" + params.targetPage);
    selectPage = params.targetPage;
  }
  if (currentWindowStage != null) {
    entryAbility.onWindowStageCreate(currentWindowStage);
  }
}

/**
 * Launch different pages according to the specified targetPage parameter
 * @param windowStage
 */
export function actionWindowStageCreate(windowStage: window.WindowStage) {
  let targetPage: string;
  switch (selectPage) {
    case 'page1':
      targetPage = 'pages/Page1';
      break;
    case 'page2':
      targetPage = 'pages/Page2';
      break;
    case 'page3':
      targetPage = 'pages/Page3';
      break;
    default:
      targetPage = 'pages/Index';
  }
  if (currentWindowStage === null) {
    currentWindowStage = windowStage;
  }
  windowStage.loadContent(targetPage);
}
