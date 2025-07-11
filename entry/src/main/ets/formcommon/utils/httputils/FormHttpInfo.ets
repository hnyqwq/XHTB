/**
 * This file is not modifiable. This file will be reset when a new card is generated.
 */
import { http } from '@kit.NetworkKit';

/**
 * Form Db info entity class.
 */
export class FormHttpInfo {
  /**
   * Form name
   */
  formName: string = '';
  /**
   * Form storage variables name and type
   */
  variableList = new Map<string, string>();
  /**
   * this url is used to get the data for form update
   */
  url: string = '';
  /**
   * optional parameters in the HTTP request
   */
  httpOptions: http.HttpRequestOptions = {
    method: http.RequestMethod.GET,
    connectTimeout: 1000,
    readTimeout: 1000,
    header: {
      'Content-Type': 'application/json'
    }
  }

  /**
   * Form http info
   * @param formName form name
   * @param variableList form variable list
   * @param url url
   * @param [httpOption] options of http request
   */
  constructor(formName: string, variableList: Map<string, string>, url: string, httpOptions?: http.HttpRequestOptions) {
    this.formName = formName;
    this.variableList = variableList;
    this.url = url;
    if (httpOptions !== undefined) {
      this.httpOptions = httpOptions;
    }
  }
}
