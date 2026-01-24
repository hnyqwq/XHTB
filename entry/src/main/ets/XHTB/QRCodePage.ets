import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { navigationManager } from '../common/NavigationManager';
import { BackButton } from '../common/BackButton';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

@Entry
@Component
export struct QRCodePage {
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State pixelMap: image.PixelMap | undefined = undefined

  build() {
    Column({ space: 0 }) {
      Row() {
        BackButton()
      }
      .width('100%')
      .height(56)
      .padding({ top: (this.globalInfoModel?.statusBarHeight ?? 0) })
      
      Column({ space: 20 }) {
        Text('二维码生成')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
        
        TextArea({ placeholder: $r('app.string.qrcode'), text: this.networkVideoSrc })
          .margin({
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })

        Button($r('app.string.createqrcode'))
          .margin({ top: 10 })
          .onClick(() => {
            this.pixelMap = undefined;
            let content: string = this.networkVideoSrc;
            let options: generateBarcode.CreateOptions = {
              scanType: scanCore.ScanType.QR_CODE,
              height: 200,
              width: 200
            }
            try {
              generateBarcode.createBarcode(content, options).then((pixelMap: image.PixelMap) => {
                this.pixelMap = pixelMap;
                // 码图生成接口，成功返回PixelMap格式图片
                hilog.info(0x0001, '[Scan Sample]', `Succeeded in getting PixelMap by promise with options`);
              }).catch((error: BusinessError) => {
                hilog.error(0x0001, '[Scan Sample]',
                  `Failed to get PixelMap by promise with options. Code: ${error.code}, message: ${error.message}`);
              });
            } catch (error) {
              hilog.error(0x0001, '[Scan Sample]', `Failed to generateBarcode. Code: ${error.code}, message: ${error.message}`);
            }
          })
        
        // 获取生成码后显示
        if (this.pixelMap) {
          Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
            .margin({ top: 10 })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .height('100%')
  }
}