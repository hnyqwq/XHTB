import { display, window } from '@kit.ArkUI';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { ProductSeriesEnum } from '../CommonEnums';
import { BreakpointTypeEnum, GlobalInfoModel } from '../GlobalInfoModel';
import Logger from '../Logger';

const TAG: string = '[BreakpointSystem]';

export interface BreakpointTypes<T> {
  xs?: T;
  sm: T;
  md: T;
  lg: T;
  xl?: T;
}

export class BreakpointType<T> {
  private xs: T;
  private sm: T;
  private md: T;
  private lg: T;
  private xl: T;

  public constructor(param: BreakpointTypes<T>) {
    this.xs = param.xs ?? param.sm;
    this.sm = param.sm;
    this.md = param.md;
    this.lg = param.lg;
    this.xl = param.xl ?? param.lg;
  }

  public getValue(currentBreakpoint: string): T {
    if (currentBreakpoint === BreakpointTypeEnum.XS) {
      return this.xs;
    }
    if (currentBreakpoint === BreakpointTypeEnum.SM) {
      return this.sm;
    }
    if (currentBreakpoint === BreakpointTypeEnum.MD) {
      return this.md;
    }
    if (currentBreakpoint === BreakpointTypeEnum.XL) {
      return this.xl;
    }
    return this.lg;
  }
}

export class BreakpointSystem {
  private static instance: BreakpointSystem;
  private currentBreakpoint: BreakpointTypeEnum = BreakpointTypeEnum.MD;

  private constructor() {
  }

  public static getInstance(): BreakpointSystem {
    if (!BreakpointSystem.instance) {
      BreakpointSystem.instance = new BreakpointSystem();
    }
    return BreakpointSystem.instance;
  }

  public updateCurrentBreakpoint(breakpoint: BreakpointTypeEnum): void {
    if (this.currentBreakpoint !== breakpoint) {
      this.currentBreakpoint = breakpoint;
      const globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel') || new GlobalInfoModel();
      globalInfoModel.currentBreakpoint = this.currentBreakpoint;
      AppStorage.setOrCreate('GlobalInfoModel', globalInfoModel);
      // 同步更新currentWidthBreakpoint，让Home.ets中的@StorageLink能接收到变化
      AppStorage.setOrCreate('currentWidthBreakpoint', this.currentBreakpoint);
    }
  }

  public onWindowSizeChange(window: window.Window): void {
    this.updateWidthBp(window);
  }

  public updateWidthBp(window: window.Window): void {
    try {
      const mainWindow: window.WindowProperties = window.getWindowProperties();
      const windowWidth: number = mainWindow.windowRect.width;
      const windowWidthVp = px2vp(windowWidth);
      const deviceType = deviceInfo.productSeries;
      if (deviceType === ProductSeriesEnum.HPR) {
        this.updateCurrentBreakpoint(BreakpointTypeEnum.XL);
        return;
      }
      let widthBp: BreakpointTypeEnum = BreakpointTypeEnum.MD;
      if (deviceInfo.deviceType === '2in1') {
        // 2in1设备直接使用xl布局（平板布局）
        widthBp = BreakpointTypeEnum.XL;
      } else if (windowWidthVp < 320) {
        widthBp = BreakpointTypeEnum.XS;
      } else if (windowWidthVp >= 320 && windowWidthVp < 600) {
        widthBp = BreakpointTypeEnum.SM;
      } else if (windowWidthVp >= 600 && windowWidthVp < 840) {
        widthBp = BreakpointTypeEnum.MD;
      } else if (windowWidthVp >= 840 && windowWidthVp < 1440) {
        widthBp = BreakpointTypeEnum.LG;
      } else {
        // PC和大屏设备直接使用xl布局（平板布局）
        widthBp = BreakpointTypeEnum.XL;
      }
      this.updateCurrentBreakpoint(widthBp);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      Logger.error(TAG, `Failed to getWindowProperties. Cause: ${err.code}, ${err.message}`);
    }
  }
}