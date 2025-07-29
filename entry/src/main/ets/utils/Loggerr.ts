import hilog from '@ohos.hilog';

class Logger {
  private domain: number;
  private prefix: string;
  private format: string = '[%{public}s] %{public}s, %{public}s';//TAG method msg

  /**
   * constructor.
   *
   * @param Prefix Identifies the log tag.
   * @param domain Domain Indicates the service domain, which is a hexadecimal integer ranging from 0x0 to 0xFFFFF.
   */
  constructor(prefix: string = 'Xiang', domain: number = 0xFF00) {
    this.prefix = prefix;
    this.domain = domain;
  }

  debug(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  info(...args: string[]): void {
    hilog.info(this.domain, this.prefix, this.format, args);
  }

  warn(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  error(...args: string[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
  }

  d(...args: string[]): void {
    hilog.debug(this.domain, this.prefix, this.format, args);
  }

  i(...args: string[]): void {
    hilog.info(this.domain, this.prefix, this.format, args);
  }

  w(...args: string[]): void {
    hilog.warn(this.domain, this.prefix, this.format, args);
  }

  e(...args: string[]): void {
    hilog.error(this.domain, this.prefix, this.format, args);
  }
}

// 这里的prefix和domain字段，可以根据个人喜好来修改
export default new Logger('hny', 0xFF00)