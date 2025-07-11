import { FormDbInfo } from '../../../utils/dbutils/FormDbInfo';

/**
 * At present, there is no data in the database, so updating form has no effect, You can imitate the following examples
 * to insert the data required for form updating into the database.
 *
 * # Examples
 *
 * ```
 * const formDBInfo = new FormDbInfo(
 *   'startAPP1',
 *   'startAPP1Table',
 *   new Map([['title', 'string'], ['image', 'Resource'], ['ratingNum', 'number']]),
 *   [
 *     new Map([['title', '数码家电直播'], ['image', JSON.stringify($r('app.media.image1'))], ['ratingNum', '4']]),
 *     new Map([['title', '食品服装直播'], ['image', JSON.stringify($r('app.media.image2'))], ['ratingNum', '4.5']])
 *   ]
 * );
 * ```
 */

export const startAPPDbInfo = new FormDbInfo(
  'startAPP',
  'startAPPTable',
  new Map([
['backgroundImg', 'Resource'],
  ])
);