/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { systemShare } from '@kit.ShareKit';
import { fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

interface UtdActionOptions {
  is: boolean;
}

interface UtdItem {
  utd: utd.UniformDataType,
  action: (context: Context, options?: UtdActionOptions) => Promise<systemShare.SharedRecord>,
  isUri?: boolean,
};

export default class CreateRecord {

  static readonly utdMap: UtdItem[] = [
    {
      utd: utd.UniformDataType.TEXT,
      action: this.createRecordForTEXT,
    },
    {
      utd: utd.UniformDataType.HYPERLINK,
      action: this.createRecordForHYPERLINK,
    },
    {
      utd: utd.UniformDataType.IMAGE,
      action: this.createRecordForIMAGE,
    },
    {
      utd: utd.UniformDataType.VIDEO,
      action: this.createRecordForVIDEO,
    }
  ];

  public static async filterRecordByUtd(context: Context, filterUtd: string): Promise<systemShare.SharedRecord | null> {
    const filterRecord = CreateRecord.utdMap.filter((item) => item.utd === filterUtd);
    if (filterRecord.length > 0) {
      const recordData = await filterRecord[0].action(context);
      return recordData;
    }
    return null;
  }

  private static async createRecordForTEXT(): Promise<systemShare.SharedRecord> {
    return {
      utd: utd.UniformDataType.TEXT,
      content: 'This is a text.',
      title: 'Text Title',
      description: 'Text Description',
      label: 'Text Title',
    }
  }

  private static async createRecordForHYPERLINK(): Promise<systemShare.SharedRecord> {
    return {
      utd: utd.UniformDataType.HYPERLINK,
      content: 'https://www.vmall.com/index.html?cid=128688',
      title: 'Huawei Vmall',
      description: 'Pura 70 Ultra',
      label: 'Huawei Vmall'
    }
  }

  private static async createRecordForIMAGE(context: Context): Promise<systemShare.SharedRecord> {
    let filePath = context.filesDir + '/exampleImage.jpg';
    return {
      utd: utd.UniformDataType.IMAGE,
      uri: fileUri.getUriFromPath(filePath),
      title: 'Picture Title',
      description: 'Picture Description',
      label: 'Picture Title'
    }
  }

  private static async createRecordForVIDEO(context: Context): Promise<systemShare.SharedRecord> {
    let filePath = context.filesDir + '/exampleVideo.mp4';
    let thumbnailPath = context.filesDir + '/exampleImage.jpg';
    const imageSource: image.ImageSource = image.createImageSource(thumbnailPath);
    const imagePacker: image.ImagePacker = image.createImagePacker();
    const buffer: ArrayBuffer = await imagePacker.packToData(imageSource, {
      format: 'image/jpeg',
      quality: 30,
    });
    return {
      utd: utd.UniformDataType.VIDEO,
      uri: fileUri.getUriFromPath(filePath),
      title: 'Video title',
      description: 'Video Description',
      thumbnail: new Uint8Array(buffer),
    }
  }
}
