/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import { ColumnInfo } from './RdbUtils';

/**
 * Form Db info entity class.
 */
export class FormDbInfo {
  /**
   * Form name
   */
  formName: string = '';
  /**
   * Form table name
   */
  tableName: string = ""
  /**
   * Form storage variables name and type
   */
  variableList = new Map<string, string>();
  /**
   * the form data of inserting into db: Array indicates inserting multiple pieces of data into the database,
   * each Map indicates a piece of data, key is the column name, value is the data to be inserted.
   */
  insertData = new Array<Map<string, string>>();

  /**
   * Form database info
   * @param formName form name
   * @param tableName form database name
   * @param variableList local variable list of form
   * @param [insertData] initial data of form database
   */
  constructor(formName: string, tableName: string, variableList: Map<string, string>,
              insertData?: Array<Map<string, string>>) {
    this.formName = formName;
    this.tableName = tableName;
    this.variableList = variableList;
    if (insertData !== undefined) {
      this.insertData = insertData;
    }
  }

  /**
   * get Form table column info
   * @returns {Array<ColumnInfo>} columnList
   */
  getColumnInfo(): Array<ColumnInfo> {
    let columnList: Array<ColumnInfo> = []
    columnList.push(new ColumnInfo('id', 'integer', -1, true, true, false))
    this.variableList.forEach((varType, varName) => {
      columnList.push(new ColumnInfo(varName, 'text', -1, false, false, false))
    })
    return columnList
  }
}
