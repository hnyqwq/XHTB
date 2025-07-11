/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import { Want } from '@kit.AbilityKit';
import { formInfo } from '@kit.FormKit';
import dataPreferences from '@ohos.data.preferences';

export default class FormPreference {
  static PREFERENCE_NAME: string = 'formPreference';

  /**
   * Used for persisting formId and FormName in the EntryFormAbility.onAddForm
   * @param want
   * @param context
   */
  static persistForm(want: Want, context: Context) {
    if (want.parameters) {
      let formId: string = want.parameters[formInfo.FormParam.IDENTITY_KEY].toString();
      let formName: string = want.parameters[formInfo.FormParam.NAME_KEY].toString();
      let isTempCard: boolean = Boolean(want.parameters[formInfo.FormParam.TEMPORARY_KEY]);
      if (isTempCard === false) {
        console.info('Not temp card, init db for:' + formId);
        let promise: Promise<dataPreferences.Preferences> =
          dataPreferences.getPreferences(context, FormPreference.PREFERENCE_NAME);
        promise.then(async (storeDB: dataPreferences.Preferences) => {
          console.info("Succeeded to get preferences.");
          await storeDB.put(formId, formName)
          await storeDB.flush()
        })
      }
    }
  }

  /**
   * Used for get formId and formName from persistence in the EntryFormAbility.onUpdateForm
   * and EntryFormAbility.onFormEvent
   * @param formId
   * @param context
   */
  static getPersistentForm(context: Context): Promise<dataPreferences.Preferences> {
    return dataPreferences.getPreferences(context, FormPreference.PREFERENCE_NAME);
  }

  /**
   * Used for removing formId and formName from persistence in the EntryFormAbility.onRemoveForm
   * @param formId
   * @param context
   */
  static removePersistentForm(formId: string, context: Context) {
    let promise: Promise<dataPreferences.Preferences> =
      dataPreferences.getPreferences(context, FormPreference.PREFERENCE_NAME);
    promise.then(async (storeDB) => {
      await storeDB.delete(formId)
    })
  }
}
