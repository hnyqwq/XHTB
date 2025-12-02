import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, generateBarcode } from '@kit.ScanKit';

import { textToSpeech } from '@kit.CoreSpeechKit';//语音

import router from '@ohos.router';

//点光源效果
/*import { hdsEffect } from '@kit.UIDesignKit';*/

let ttsEngine: textToSpeech.TextToSpeechEngine;

@Entry
@Component
export struct ReadQR {
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @State pixelMap: image.PixelMap | undefined = undefined
  @State originalText: string = ''; //语音
  @State createCount: number = 0;
  @State result: boolean = false;
  @State voiceInfo: string = '';
  @State text: string = '';
  @State textContent: string = '';
  @State utteranceId: string = '123456'
  @State illegalText: string = '';
  @StorageLink('isPlaying') isPlaying: boolean = false;

  //点光源效果
  /*@State lightSourceType: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;
  @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();*/

  aboutToDisappear() {
    try {
      const isBusy = ttsEngine?.isBusy();
      if (isBusy) {
        ttsEngine?.stop();
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error(`The ttsEngine invoke error, the code is ${error.code}, the message is ${error.message}`);
    }
  }

  build() {
    Column({ space: 0 }) {
      Row() {
        Text('󰃚') // 自定义返回图标
          .fontSize(35)
          .margin({ left: 20 }) // 左侧留白
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      
      Column({ space: 0 }) {
        TextArea({ placeholder: $r('app.string.speak'), text: this.networkVideoSrc })
          .margin({
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })
          /*.visualEffect(new hdsEffect.HdsEffectBuilder()
            .shaderEffect({
              effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
              animation: {
                duration: 4000,
                iterations: -1,
                autoPlay: true,
                onFinish: () => {
                  console.info('Succeeded in finishing');
                }
              },
              controller: this.controller,
              params: {
                firstEdgeFlowLight: {
                  startPos: 0,
                  endPos: 1.0,
                  color: '#0A59F7',
                },
                secondEdgeFlowLight: {
                  startPos: 0.5,
                  endPos: 1.5,
                  color: '#ffed6f21',
                }
              }
            })
            .buildEffect())*/

        Row({ space: 40 }) {
          Button('', { type: ButtonType.Circle, stateEffect: true })
            .margin({ top: 10 })
            .backgroundColor(Color.Transparent)
            .backgroundImage(this.isPlaying ? $r('app.media.pause') : $r('app.media.play_circle_fill'))
            .backgroundImagePosition(Alignment.Center)
            .onClick(() => {
              try {
                this.createByCallback();
              } catch (err) {
                const error: BusinessError = err as BusinessError;
                console.error(`CreateEngine error, the code is ${error.code}, the message is ${error.message}`);
              }
            })
            .width('40vp')

          Button('', { type: ButtonType.Circle, stateEffect: true })
            .margin({ top: 10 })
            .backgroundColor(Color.Transparent)
            .backgroundImage($r('app.media.stop_circle'))
            .backgroundImagePosition(Alignment.Center)
            .onClick(() => {
              try {
                ttsEngine?.stop();
                ttsEngine?.shutdown();
              } catch (err) {
                const error: BusinessError = err as BusinessError;
                console.error(`The ttsEngine invoke error, the code is ${error.code}, the message is ${error.message}`);
              }
              AppStorage.setOrCreate('isPlaying', false);
            })
            .width('40vp')
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)

        //二维码生成
        TextArea({ placeholder: $r('app.string.qrcode'), text: this.networkVideoSrc })
          .margin({
            top: 50,
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })

          /*.visualEffect(new hdsEffect.HdsEffectBuilder()
            .shaderEffect({
              effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
              animation: {
                duration: 4000,
                iterations: -1,
                autoPlay: true,
                onFinish: () => {
                  console.info('Succeeded in finishing');
                }
              },
              controller: this.controller,
              params: {
                firstEdgeFlowLight: {
                  startPos: 0,
                  endPos: 1.0,
                  color: '#1AD0F1',
                },
                secondEdgeFlowLight: {
                  startPos: 0.5,
                  endPos: 1.5,
                  color: '#FFA4E5',
                }
              }
            })
            .buildEffect())*/
        Button($r('app.string.pick'))
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
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .layoutWeight(1)  // 动态分配剩余空间
  }

  createByCallback() {
    let extraParam: Record<string, string> = { 'style': 'interaction-broadcast', 'locate': 'CN', 'name': 'EngineName' };
    let initParamsInfo: textToSpeech.CreateEngineParams = {
      language: 'zh-CN',
      person: 0,
      online: 1,
      extraParams: extraParam
    };
    textToSpeech.createEngine(initParamsInfo,
      (err: BusinessError, textToSpeechEngine: textToSpeech.TextToSpeechEngine) => {
        if (!err) {
          ttsEngine = textToSpeechEngine;
          this.createCount++;
          this.speak();
        } else {
          console.log('Fail to createEngine.');
        }
      });
  };

  speak() {
    let speakListener: textToSpeech.SpeakListener = {
      onStart(requestId: string, response: textToSpeech.StartResponse) {
        console.log('onStart');
        AppStorage.setOrCreate('isPlaying', true);
      },
      onComplete(requestId: string, response: textToSpeech.CompleteResponse) {
        console.log('onComplete');
        AppStorage.setOrCreate('isPlaying', true);
      },
      onStop(requestId: string, response: textToSpeech.StopResponse) {
        console.log('onStop');
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      },
      onData(requestId: string, audio: ArrayBuffer, response: textToSpeech.SynthesisResponse) {
        console.log('onData');
      },
      onError(requestId: string, errorCode: number, errorMessage: string) {
        console.log('onError');
        AppStorage.setOrCreate('isPlaying', false);
        ttsEngine?.shutdown();
      }
    };
    ttsEngine?.setListener(speakListener);
    let extraParam: Record<string, string | number> = {
      'queueMode': 0,
      'speed': 1,
      'volume': 2,
      'pitch': 1,
      'languageContext': 'zh-CN',
      'audioType': 'pcm',
      'soundChannel': 3,
      'playType': 1
    }
    let speakParams: textToSpeech.SpeakParams = {
      requestId: '123456-a',
      extraParams: extraParam
    };
    ttsEngine?.speak(this.networkVideoSrc, speakParams);//originalText
  };
}