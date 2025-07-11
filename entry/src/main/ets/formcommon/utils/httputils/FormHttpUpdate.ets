/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import FormPreference from '../FormPreference';
import dataPreferences from '@ohos.data.preferences';
import http from '@ohos.net.http';
import { FormHttpInfo } from './FormHttpInfo';
import { formBindingData, formProvider } from '@kit.FormKit';
import { configUpdateCondition, getDataFromHttp } from '../../formsetting/formhttpsetting/UserSettings';
import { formHttpInfoArray } from '../../formsetting/formhttpsetting/formhttpinfo/Index';

/**
 * update form using Http
 */
export class FormHttpUpdate {
  /**
   * scheduledUpdateTime or updateDuration update form using http
   * @param formId
   * @param context
   */
  static updateForm(formId: string, context: Context) {
    let promise: Promise<dataPreferences.Preferences> = FormPreference.getPersistentForm(context);
    promise.then(async (storeDB: dataPreferences.Preferences) => {
      console.info("Succeeded to get preferences.");
      let valueType = await storeDB.get(formId, 'undefined');
      let formName = valueType.toString()
      formHttpInfoArray.forEach((formHttpInfo) => {
        FormHttpUpdate.updateFormOfOne(formName, formId, formHttpInfo)
      });
    })
  }

  /**
   * event update form using http
   * @param formId
   * @param message
   * @param context
   */
  static formEvent(formId: string, message: string, context: Context) {
    let promise: Promise<dataPreferences.Preferences> = FormPreference.getPersistentForm(context);
    promise.then(async (storeDB: dataPreferences.Preferences) => {
      console.info("Succeeded to get preferences.");
      let valueType = await storeDB.get(formId, 'undefined');
      let formName = valueType.toString();
      if (!configUpdateCondition(message, formName)) {
        return;
      }
      formHttpInfoArray.forEach((formHttpInfo) => {
        FormHttpUpdate.updateFormOfOne(formName, formId, formHttpInfo)
      });
    })
  }

  /**
   * update a form by formId
   * @param formName
   * @param formId
   * @param formHttpInfo
   */
  static updateFormOfOne(formName: string, formId: string, formHttpInfo: FormHttpInfo) {
    if (formName === formHttpInfo.formName) {
      const url = formHttpInfo.url
      const request = http.createHttp();
      let promise = request.request(url, formHttpInfo.httpOptions);
      promise.then((data) => {
        let obj = getDataFromHttp(data, formHttpInfo)
        let formData = formBindingData.createFormBindingData(obj);
        formProvider.updateForm(formId, formData)
      });
    }
  }
}
