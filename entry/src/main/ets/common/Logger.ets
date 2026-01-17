import { hilog } from '@kit.PerformanceAnalysisKit';

class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '%{public}s, %{public}s';

  public constructor(prefix: string) {
    this.prefix = prefix;
    this.domain = 0xFF00;
  }

  public debug(...args: Object[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  public info(...args: Object[]): void {
    hilog.info(this.domain, this.prefix, this.format, args);
  }

  public warn(...args: Object[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  public error(...args: Object[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
  }
}

export default new Logger('[metrolog]');