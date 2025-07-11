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
import { hilog } from '@kit.PerformanceAnalysisKit';

/*
 * Select a picture from the gallery.
 * @returns uri The uri for the selected file.
 */
export async function fileSelect(): Promise<Array<string>> {
  let imgUri: string[] = [];
  let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
  photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
  photoSelectOptions.maxSelectNumber = 5;
  let photoPicker = new photoAccessHelper.PhotoViewPicker();
  try {
    let photoSelectResult = await photoPicker.select(photoSelectOptions);
    if (photoSelectResult && photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
      imgUri = photoSelectResult.photoUris;
      return imgUri;
    } else {
      return [];
    }
  } catch (error) {
    hilog.error(0x0000, '[FileUtil]', `PhotoViewPicker failed.`);
    return [];
  }
}