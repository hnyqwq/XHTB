import dataRdb from '@ohos.data.relationalStore';
import { FormDbInfo } from '../../utils/dbutils/FormDbInfo';

/**
 * Used to convert the obtained update data into the corresponding type in the widget card
 *
 * # Examples
 *
 * ```
 * If there is a variable in the widget card that needs to update, for example:
 * @LocalStorageProp('numArr') numArr: Array<number> = []
 * const formDbInfo = new FormDbInfo('widget1', 'widget1Table', new Map([['numArr', 'Array<number>']]));
 * You need to add this type in this method:
 *
 * switch (varType) {
 *   case "Array<number>":
 *     let valueArr: Array<number> = JSON.parse(valueStr);
 *     obj[varName] = valueArr;
 *     break;
 *   case "Resource":
 *     let valueRes: Resource = JSON.parse(valueStr);
 *     obj[varName] = valueRes;
 *     break;
 *   case "number":
 *     let valueNum: number = JSON.parse(valueStr);
 *     obj[varName] = valueNum;
 *     break;
 *   case "boolean":
 *     let valueBool: boolean = JSON.parse(valueStr);
 *     obj[varName] = valueBool;
 *     break;
 *   case "string":
 *     obj[varName] = valueStr;
 * }
 * ```
 *
 * @param varType variable type
 * @param varName variable name
 * @param valueStr variable value as string
 * @param obj object with variable value
 */
export function configTypeSwitch(varType: string, varName: string, valueStr: string, obj: Record<string, Object>) {
    switch (varType) {
      case "Resource":
        let valueRes: Resource = JSON.parse(valueStr);
        obj[varName] = valueRes;
        break;
      case "number":
        let valueNum: number = JSON.parse(valueStr);
        obj[varName] = valueNum;
        break;
      case "boolean":
        let valueBool: boolean = JSON.parse(valueStr);
        obj[varName] = valueBool;
        break;
      case "string":
        obj[varName] = valueStr;
    }
}

/**
 * Get new values of form LocalStorage variables from database.
 *
 * @param resSet database result set
 * @param formDbInfo form info
 * @returns object with new values of variables
 */
export function getDataFromDb(resSet: dataRdb.ResultSet, formDbInfo: FormDbInfo): Record<string, Object> {
  // You can change way to update data here.
  let cnt = resSet.rowCount;
  if (cnt === 0) {
    return {};
  } else {
    // random a piece of data in db table.
    let row = Math.floor(Math.random() * cnt);
    resSet.goToRow(row);
    let obj: Record<string, Object> = {};
    formDbInfo.variableList.forEach((varType, varName) => {
      const valueStr: string = resSet.getString(resSet.getColumnIndex(varName));
      configTypeSwitch(varType, varName, valueStr, obj)
    })
    resSet.close();
    return obj;
  }
}

/**
 * Customize updating different data by configuring different conditions
 * @param message message sent by form action
 * @param formName form name
 * @returns whether to update form data
 */
export function configUpdateCondition(message: string, formName: string): boolean {
  if (formName == 'widget_example' && message == '') {
    return false;
  }
  return true;
}
