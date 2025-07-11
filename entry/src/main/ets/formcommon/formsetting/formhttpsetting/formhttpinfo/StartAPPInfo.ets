import { FormHttpInfo } from '../../../utils/httputils/FormHttpInfo';
/**
 * FormHttpInfo.url is used to get the data for form update. You need to configure the url, it is necessary to
 * replace with the actual url. And http option is optional.
 *
 * # Examples
 *
 * ```
 * const startAPPHttpInfo = new FormHttpInfo(
 *   'startAPP1',
 *   new Map([['title', 'string'], ['image', 'Resource'], ['ratingNum', 'number']]),
 *   'url_to_be_replaced',
 *   {
 *     connectTimeout: 1000,
 *     readTimeout: 1000
 *   }
 * );
 * ```
 */

export const startAPPHttpInfo = new FormHttpInfo(
  'startAPP',
  new Map([
['backgroundImg', 'Resource'],]),
  'url_to_be_replaced'
);