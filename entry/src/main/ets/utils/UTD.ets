/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2024-2024. All rights reserved.
 */

import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import Logger from '../utils/Logger';

let logger = Logger.getLogger('[UTD]');

export default class UTD {
  public static getUtdByFileSuffix(filenameExtension: string): string {
    try {
      let typeId = utd.getUniformDataTypeByFilenameExtension(filenameExtension);
      if (typeId) {
        return typeId;
      }
      return '';
    } catch(err) {
      logger.error(`getUtdByFileSuffix throws an exception. Code: ${err.code}, message: ${err.message}`);
      return '';
    }
  }
}