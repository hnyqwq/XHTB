import { textToSpeech } from '@kit.CoreSpeechKit';//语音
import { BusinessError } from '@kit.BasicServicesKit';
import { navigationManager } from '../common/NavigationManager';
import { BackButton } from '../common/BackButton';
import { GlobalInfoModel } from '../common/GlobalInfoModel';

let ttsEngine: textToSpeech.TextToSpeechEngine;

@Entry
@Component
export struct TextToSpeechPage {
  @StorageLink('networkVideoSrc') networkVideoSrc: string = '';
  @StorageProp('GlobalInfoModel') globalInfoModel: GlobalInfoModel = AppStorage.get('GlobalInfoModel')!;
  @State originalText: string = ''; //语音
  @State createCount: number = 0;
  @State result: boolean = false;
  @State voiceInfo: string = '';
  @State text: string = '';
  @State textContent: string = '';
  @State utteranceId: string = '123456'
  @State illegalText: string = '';
  @StorageLink('isPlaying') isPlaying: boolean = false;

  aboutToAppear() {
    // 保存当前页面信息到 AppStorage,供接续功能使用
    AppStorage.setOrCreate('currentPageUrl', 'XHTB/TextToSpeechPage');
    AppStorage.delete('currentRouteParams');
  }

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
        BackButton()
      }
      .width('100%')
      .height(56)
      .padding({ top: (this.globalInfoModel?.statusBarHeight ?? 0) })
      
      Column({ space: 20 }) {
        Text($r('app.string.sub_title2_value1'))
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20 })
        
        TextArea({ placeholder: $r('app.string.speak'), text: this.networkVideoSrc })
          .margin({
            left: $r('sys.float.padding_level16'),
            right: $r('sys.float.padding_level16'),
          })
          .onChange((networkVideoSrc: string) => {
            this.networkVideoSrc = networkVideoSrc;
            AppStorage.set('networkVideoSrc', networkVideoSrc);
          })

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
      }
      .width('100%')
      .layoutWeight(1)
    }
    .height('100%')
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
  }

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