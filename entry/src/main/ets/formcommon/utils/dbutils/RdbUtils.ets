/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import dataRdb from '@ohos.data.relationalStore';
import { formDbInfoArray } from '../../formsetting/formdbsetting/formdbinfo/Index';

let DB_NAME: string = 'form.db'

export const STORE_CONFIG: dataRdb.StoreConfig = {
  name: DB_NAME,
  securityLevel: dataRdb.SecurityLevel.S1
} as dataRdb.StoreConfig;

/**
 * db table column info.
 */
export class ColumnInfo {
  name: string;
  type: string;
  length?: number;
  nullable?: boolean;
  primary?: boolean;
  autoincrement?: boolean;

  constructor(name: string, type: string, length?: number, nullable?: boolean,
              primary?: boolean, autoincrement?: boolean) {
    this.name = name;
    this.type = type;
    this.primary = primary;
    this.length = length;
    this.nullable = nullable;
    this.autoincrement = autoincrement;
  }
}

export function createDbInsertData(context: Context) {
  formDbInfoArray.forEach(formDbInfo => {
    dataRdb.getRdbStore(context, STORE_CONFIG).then(async dbStore => {
      let sql = createTableSql(formDbInfo.tableName, formDbInfo.getColumnInfo());
      dbStore.executeSql(sql).then(() => {
        if (formDbInfo.insertData.length == 0) {
          return;
        }
        formDbInfo.insertData.forEach(item => {
          let valueBucket = {} as dataRdb.ValuesBucket;
          item.forEach((varValue, varName) => {
            valueBucket[varName] = varValue;
          });
          insert(dbStore, formDbInfo.tableName, valueBucket).then((isDone: number) => {
            if (isDone) {
            }
          })
        })
      })
    })
  })
}

function createTableSql(tableName: string, columns: Array<ColumnInfo>): string {
  let sql = `create table if not exists ${tableName}(`;
  for (let column of columns) {
    sql = sql.concat(`${column.name} ${column.type}`);
    sql = sql.concat(`${column.length && column.length > 0 ? `(${column.length})` : ''}`);
    sql = sql.concat(`${column.primary ? ' primary key' : ''}`);
    sql = sql.concat(`${column.autoincrement ? ' autoincrement' : ''}`);
    sql = sql.concat(`${column.nullable ? '' : ' not null'}`);
    sql = sql.concat(', ');
  }
  sql = `${sql.substring(0, sql.length - 2)})`;
  return sql;
}

function insert(dbStore: dataRdb.RdbStore, tableName: string,
                values: dataRdb.ValuesBucket | Array<dataRdb.ValuesBucket>): Promise<number> {
  return new Promise<number>((success, error) => {
    if (!values) {
      error(0);
      return;
    }
    if (values instanceof Array) {
      dbStore.beginTransaction();
      saveArray(dbStore, tableName, values).then(data => {
        success(data);
        dbStore.commit();
      }).catch((err: Error) => {
        console.error(`insert failed, err : ${err}`);
        error(err);
        dbStore.commit();
      })
    } else {
      dbStore.insert(tableName, values).then(data => {
        success(data);
        dbStore.commit();
      }).catch((err: Error) => {
        error(err);
        dbStore.commit();
      })
    }
  })
}

function saveArray(dbStore: dataRdb.RdbStore, tableName: string, values: Array<dataRdb.ValuesBucket>): Promise<number> {
  return new Promise<number>((success, error) => {
    if (!values || values.length === 0) {
      error(0);
      return;
    }
    let index = 0
    let callback = (data: number, err: Error) => {
      if (err) {
        error(err);
        return;
      }
      if (data) {
        if (index < values.length - 1) {
          saveData(dbStore, tableName, values, ++index, callback);
        } else {
          success(data);
        }
      }
    }
    saveData(dbStore, tableName, values, index, callback);
  })
}

function saveData(dbStore: dataRdb.RdbStore, tableName: string, values: Array<dataRdb.ValuesBucket>,
                  index: number, callback: Function): void {
  dbStore.insert(tableName, values[index]).then((data: number) => {
    callback(data);
  }).catch((err: Error) => {
    callback(err);
  })
}
