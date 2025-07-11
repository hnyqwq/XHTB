/*
 * Copyright (c) 2024 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { dataSharePredicates, unifiedDataChannel, uniformTypeDescriptor } from '@kit.ArkData';
import { fileIo as fs } from '@kit.CoreFileKit';
import { promptAction, SymbolGlyphModifier } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import {
  CollaborationServiceFilter,
  CollaborationServiceStateDialog,
  createCollaborationServiceMenuItems
} from '@hms.collaboration.service';
import { CommonConstants } from '../constants/CommonConstants';
import { ImageInfo } from '../model/ContentInfo';
import { fileSelect } from '../utils/FileUtil';
import { BreakpointType } from '../utils/BreakpointSystem';

/*
 * Image area.
 */
@Component
export struct AddPic {
  @StorageLink('continueImageUriArray') imageUriArray: Array<ImageInfo> = [];
  @StorageLink('continueAttachments') attachments: Object = [];
  @StorageLink('continueBreakpoint') currentBreakpoint: string = 'sm';
  @State pasteShow: boolean = false;
  @State toastShow: boolean = false;
  // Get the UIAbilityContext information of device A.
  private context = this.getUIContext().getHostContext() as common.UIAbilityContext;

  /*
   * Select picture method.
   */
  selectImage(): void {
    fileSelect().then((uri: Array<ResourceStr>) => {
      if ((this.imageUriArray.length + uri.length) > CommonConstants.MAX_ADD_PIC) {
        uri.length = CommonConstants.MAX_ADD_PIC - this.imageUriArray.length;
        promptAction.showToast({ message: $r('app.string.add_picture_prompt') });
      }
      uri.forEach((item: ResourceStr) => {
        this.getThumbnail(item as string);
      });
    })
  }

  async getThumbnail(uri: string) {
    let phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context);
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo('uri', uri);
    let fetchOption: photoAccessHelper.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };
    let fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
      await phAccessHelper.getAssets(fetchOption);
    let asset: photoAccessHelper.PhotoAsset = await fetchResult.getFirstObject();
    asset.getThumbnail((err, pixelMap) => {
      if (err === undefined) {
        hilog.info(0x0000, '[AddPic]', 'getThumbnail successful ');
        let imageName = asset.displayName.substring(0, (asset.displayName).indexOf('.'));
        this.PixelMapToBuffer(pixelMap, imageName);
        this.imageUriArray.push({ imagePixelMap: pixelMap, imageName: imageName });
      } else {
        hilog.error(0x0000, '[AddPic]', `getThumbnail fail.`);
      }
    });
  }

  PixelMapToBuffer(pixelMap: image.PixelMap, displayName: string): void {
    const imagePackerApi: image.ImagePacker = image.createImagePacker();
    let packOpts: image.PackingOption = { format: 'image/jpeg', quality: 100 };
    imagePackerApi.packToData(pixelMap, packOpts).then((data: ArrayBuffer) => {
      this.writeDistributedFile(data, displayName);
    })
  }

  writeDistributedFile(buf: ArrayBuffer, displayName: string): void {
    // The asset is written to the distributed file directory.
    // Obtain the distributed file directory path.
    let distributedDir: string = this.context.distributedFilesDir;
    let fileName: string = '/' + displayName;
    let filePath: string = distributedDir + fileName;
    try {
      // Create a file in a distributed directory.
      let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      hilog.info(0x0000, '[AddPic]', 'Create file success.');
      // Write content to a file (if the asset is a picture, the picture can be converted to a buffer to write)
      fs.writeSync(file.fd, buf);
      // closed file.
      fs.closeSync(file.fd);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      hilog.info(0x0000, '[AddPic]',
        `Failed to openSync / writeSync / closeSync. Code: ${err.code}, message: ${err.message}`);
    }
  }

  getDataFromUdmfRetry(event: DragEvent, callback: (data: DragEvent) => void) {
    try {
      let data: UnifiedData = event.getData();
      if (!data) {
        return false;
      }
      let records: unifiedDataChannel.UnifiedRecord[] = data.getRecords();
      if (!records || records.length <= 0) {
        return false;
      }
      callback(event);
      return true;
    } catch (e) {
      hilog.info(0x0000, '[AddPic]', 'getData failed, code = ' + (e as BusinessError).code);
      return false;
    }
  }

  getDataFromUdmf(event: DragEvent, callback: (data: DragEvent) => void) {
    if (this.getDataFromUdmfRetry(event, callback)) {
      return;
    }
    setTimeout(() => {
      this.getDataFromUdmfRetry(event, callback);
    }, 1500);
  }

  doInsertPicture(stateCode: number, bufferType: string, buffer: ArrayBuffer): void {
    if (stateCode != 0) {
      return;
    }
    if (bufferType === 'general.image') {
      let imageSource = image.createImageSource(buffer);
      imageSource.createPixelMap().then((pixelMap) => {
        if (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC) {
          let uuid = util.generateRandomUUID();
          this.PixelMapToBuffer(pixelMap, uuid);
          this.imageUriArray.push({ imagePixelMap: pixelMap, imageName: uuid });
        }
      })
      imageSource.release();
    }
  }

  // Uri to pixelMap.
  uri2pixelMap(uri: string): void {
    let imageUri = uri;
    let file = fs.openSync(imageUri, fs.OpenMode.READ_ONLY);
    let imageSource = image.createImageSource(file.fd);
    fs.closeSync(file);
    const imagePackApi = image.createImagePacker();
    let packOpts: image.PackingOption = { format: 'image/png', quality: 100 };
    imagePackApi.packToData(imageSource, packOpts).then(async readBuffer => {
      let imageSource: image.ImageSource = image.createImageSource(readBuffer as ArrayBuffer);
      let option: image.InitializationOptions = {
        size: {
          width: 100,
          height: 100
        },
      };
      imageSource.createPixelMap(option).then((pixelMap: PixelMap) => {
        if (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC) {
          let uuid = util.generateRandomUUID();
          this.PixelMapToBuffer(pixelMap, uuid);
          this.imageUriArray.push({ imagePixelMap: pixelMap, imageName: uuid });
        } else {
          promptAction.showToast({ message: $r('app.string.add_picture_prompt') });
        }
      });
      imageSource.release();
    })
    imageSource.release();
  }

  // Copy picture.
  async setPasteDataTest(pixelMap: image.PixelMap): Promise<void> {
    let pasteData: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_PIXELMAP, pixelMap);
    let systemPasteBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    await systemPasteBoard.setData(pasteData).catch((err: BusinessError) => {
      hilog.error(0x0000, '[AddPic]', `Failed to set pastedata. Code: ${err.code}`);
    });
  }

  // Paste picture.
  async getPasteDataTest(): Promise<void> {
    let systemPasteBoard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteBoard.getData((err: BusinessError, data: pasteboard.PasteData) => {
      if (err) {
        hilog.error(0x0000, '[AddPic]', `Failed to get pastedata. Code: ${err.code}`);
        return;
      }
      // Process pasteData, obtain type, number, etc
      // Retrieve the number of records in the clipboard.
      let recordCount: number = data.getRecordCount();
      // Retrieve the type of data from the clipboard.
      let types: string = data.getPrimaryMimeType();
      hilog.info(0x0000, '[AddPic]', `recordCount: ${recordCount}, types: ${types}`);
      // Retrieve the content of data from the clipboard.
      if (types === 'pixelMap') {
        let primaryPixelMap: image.PixelMap = data.getPrimaryPixelMap();
        if (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC) {
          let uuid = util.generateRandomUUID();
          this.PixelMapToBuffer(primaryPixelMap, uuid);
          this.imageUriArray.push({ imagePixelMap: primaryPixelMap, imageName: uuid });
        } else {
          this.toastShow = true;
        }
      } else if (types === 'text/uri') {
        this.uri2pixelMap(data.getPrimaryUri());
      }
    });
  }

  build() {
    Column() {
      CollaborationServiceStateDialog({
        onState: (stateCode: number, bufferType: string, buffer: ArrayBuffer): void => this.doInsertPicture(stateCode,
          bufferType, buffer)
      })
      this.addPic();
    }
    .allowDrop([uniformTypeDescriptor.UniformDataType.IMAGE,
      uniformTypeDescriptor.UniformDataType.OPENHARMONY_PIXEL_MAP])
    .onDrop((dragEvent?: DragEvent) => {
      // The logic behind the image falling in, achieving image writing.
      this.getDataFromUdmf((dragEvent as DragEvent), async (event: DragEvent) => {
        let records: unifiedDataChannel.UnifiedRecord[] = event.getData().getRecords();
        for (let i = 0; i < records.length; i++) {
          // PixelMap converted from image to pixelMap in the image system.
          if (records[i].getType() === uniformTypeDescriptor.UniformDataType.OPENHARMONY_PIXEL_MAP) {
            let pixelMapRecord = records[i] as unifiedDataChannel.SystemDefinedPixelMap;
            const mWidth: number = (pixelMapRecord.details?.width ?? -1) as number;
            const mHeight: number = (pixelMapRecord.details?.height ?? -1) as number;
            const mPixelFormat: image.PixelMapFormat =
              (pixelMapRecord.details?.['pixel-format'] ?? image.PixelMapFormat.UNKNOWN) as image.PixelMapFormat;
            const mItemPixelMapData: Uint8Array = pixelMapRecord.rawData;
            const opts: image.InitializationOptions = {
              srcPixelFormat: mPixelFormat,
              pixelFormat: mPixelFormat,
              size: {
                width: mWidth,
                height: mHeight
              }
            };
            const buffer: ArrayBuffer = mItemPixelMapData.buffer.slice(mItemPixelMapData.byteOffset,
              mItemPixelMapData.byteOffset + mItemPixelMapData.byteLength);
            const pixelMap = await image.createPixelMap(buffer, opts);
            if (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC) {
              let uuid = util.generateRandomUUID();
              this.PixelMapToBuffer(pixelMap, uuid);
              this.imageUriArray.push({ imagePixelMap: pixelMap, imageName: uuid });
            } else {
              this.getUIContext().getPromptAction().showToast({ message: $r('app.string.add_picture_prompt') });
            }
          } else {
            // Convert the image from imageUri to PixelMap.
            this.uri2pixelMap((records[i] as unifiedDataChannel.Image).imageUri);
          }
        }
        event.useCustomDropAnimation = false;
        // If the result is explicitly set to successful, pass this value to the onDragEnd of the dragging party.
        event.setResult(DragResult.DRAG_SUCCESSFUL);
      })
    })
  }

  /*
   *  Adding an image.
   */
  @Builder
  addPic() {
    Row() {
      List({ space: CommonConstants.LIST_COMM_SPACE }) {
        ForEach(this.imageUriArray, (item: ImageInfo) => {
          ListItem() {
            Image(item.imagePixelMap)
              .width($r('app.integer.add_image_area_size'))
              .height($r('app.integer.add_image_area_size'))
              .borderRadius($r('app.integer.border_radius3'))
              .visibility(item ? Visibility.Visible : Visibility.None)
              .draggable(true)
              .onDragEnd((event) => {
                // The logic after dragging and dropping is completed.
                // The result value obtained from onDragEnd is set by the recipient onDrop.
                if (event.getResult() === DragResult.DRAG_FAILED) {
                  this.getUIContext().getPromptAction().showToast({ duration: 100, message: 'Drag failed' });
                }
              })
          }
        }, (item: ImageInfo, index: number) => JSON.stringify(item) + index)
        this.addDefaultPic()
      }
      .listDirection(Axis.Horizontal)
      .scrollBar(BarState.Off)
    }
    .height($r('app.integer.add_image_area_size'))
    .width(CommonConstants.FULL_PERCENT)
    .alignItems(VerticalAlign.Center)
    .padding({
      left: new BreakpointType({
        sm: $r('sys.float.padding_level8'),
        md: $r('sys.float.padding_level12'),
        lg: $r('sys.float.padding_level16')
      }).getValue(this.currentBreakpoint),
      right: new BreakpointType({
        sm: $r('sys.float.padding_level8'),
        md: $r('sys.float.padding_level12'),
        lg: $r('sys.float.padding_level16')
      }).getValue(this.currentBreakpoint)
    })
    .onClick(() => {
      this.pasteShow = false;
      this.pasteShow = true;
    })
  }

  // Remote menu.
  @Builder
  MyTestMenu() {
    Menu() {
      MenuItem({
        symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.picture_2')),
        content: $r('app.string.local_device')
      })
        .onClick(() => {
          if (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC) {
            this.selectImage();
          } else {
            promptAction.showToast({ message: $r('app.string.add_picture_prompt') });
          }
        })
      createCollaborationServiceMenuItems([CollaborationServiceFilter.ALL], 9)
    }
  }

  /*
   * Add default image.
   */

  @Builder
  addDefaultPic() {
    Row() {
      Column() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize($r('app.integer.add_icon_size'))
          .fontColor([$r('sys.color.font_primary')])
        Text(this.imageUriArray.length === 0 ? $r('app.string.add_high_img') :
          (this.imageUriArray.length < CommonConstants.MAX_ADD_PIC ? $r('app.string.continue_add') :
          $r('app.string.image_add')))
          .fontSize($r('app.integer.text_size_body3'))
          .fontColor($r('app.color.add_image_background'))
          .margin({ top: $r('app.integer.comm_padding_margin_mini') })
      }
      .justifyContent(FlexAlign.Center)
      .width(CommonConstants.FULL_PERCENT)
    }
    .borderStyle(BorderStyle.Dashed)
    .borderWidth($r('app.integer.default_border_width'))
    .borderColor($r('app.color.add_image_border_color'))
    .borderRadius($r('app.integer.border_radius3'))
    .width($r('app.integer.add_image_area_size'))
    .height($r('app.integer.add_image_area_size'))
    .margin({
      right: $r('app.integer.add_default_pic_right'),
      bottom: $r('app.integer.add_default_pic_bottom')
    })
    .bindMenu(this.MyTestMenu())
  }
}