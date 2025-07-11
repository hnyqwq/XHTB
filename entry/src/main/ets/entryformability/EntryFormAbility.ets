import { FormHttpUpdate } from '../formcommon/HttpIndex';
import FormPreference from '../formcommon/utils/FormPreference';
import { FormDbUpdate } from '../formcommon/DbIndex';
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to persist formId and formName.
     */
    FormPreference.persistForm(want, this.context)


    // Called to return a FormBindingData object.
    let formData = '';
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(formId: string) {
    // Called when the form provider is notified that a temporary form is successfully
    // converted to a normal form.
  }

  onUpdateForm(formId: string) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to update(scheduledUpdateTime or updateDuration) form by http.
     */
    // FormHttpUpdate.updateForm(formId, this.context);


    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to update(scheduledUpdateTime or updateDuration) form by database.
     */
    FormDbUpdate.updateForm(formId, this.context);


    // Called to notify the form provider to update a specified form.
  }

  onChangeFormVisibility(newStatus: Record<string, number>) {
    // Called when the form provider receives form events from the system.
  }

  onFormEvent(formId: string, message: string) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to http update form through message event.
     */
    // FormHttpUpdate.formEvent(formId, message, this.context);


    /**
     * This is the automatically generated code for the logic of card interactions.
     * Used to database update form through message event.
     */
    FormDbUpdate.formEvent(formId, message, this.context);


    // Called when a specified message event defined by the form provider is triggered.
  }

  onRemoveForm(formId: string) {
    /**
     * This is the automatically generated code for the logic of card interactions.
     * Remove formId and formName from persistence.
     */
    FormPreference.removePersistentForm(formId, this.context);


    // Called to notify the form provider that a specified form has been destroyed.
  }

  onAcquireFormState(want: Want) {
    // Called to return a {@link FormState} object.
    return formInfo.FormState.READY;
  }
};