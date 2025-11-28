import { media } from '@kit.MediaKit';
import { BusinessError } from '@kit.BasicServicesKit';
import router from '@ohos.router';

// 定义站点信息接口
interface StationInfo {
  name: string;
  englishName: string;
  lineNumber: string;
  stationNumber: string;
  lineColor: string;
  description: string;
}

// 定义线路信息接口
interface LineInfo {
  lineNumber: string;
  stationNumber: string;
  color: string;
}

// 从Metro.ets复制线路数据和相关方法
const MetroStationData: Array<Array<string>> = [
  // 1号线站点
  ['韦家碾', '升仙湖', '火车北站', '人民北路', '文殊院', '骡马市', '天府广场', '锦江宾馆', '华西坝', '省体育馆', '倪家桥',
    '火车南站', '高新', '金融城', '孵化园', '锦城广场', '世纪城', '天府三街', '天府五街', '华府大道', '四河', '华阳',
    '海昌路', '广福', '红石公园', '麓湖', '武汉路', '天府公园', '西博城', '广州路', '兴隆湖', '科学城'],
  // 2号线站点
  ['龙泉驿', '龙平路', '书房', '界牌', '连山坡', '大面铺', '成都行政学院', '洪河', '惠王陵', '成渝立交',
    '成都东客站', '塔子山公园', '东大路', '牛市口', '牛王庙', '东门大桥', '春熙路', '天府广场', '人民公园', '通惠门',
    '中医大省医院', '白果林', '蜀汉路东', '一品天下', '羊犀立交', '茶店子客运站', '迎宾大道', '金科北路', '金周路', '百草路',
    '天河路', '犀浦'],
  // 3号线站点
  ['成都医学院', '石油大学', '钟楼', '马超西路', '团结新区', '锦水河', '三河场', '金华寺东路', '植物园', '军区总医院',
    '熊猫大道', '动物园', '昭觉寺南路', '驷马桥', '李家沱', '前锋路', '红星桥', '市二医院', '春熙路', '新南门',
    '磨子桥', '省体育馆', '衣冠庙', '高升桥', '红牌楼', '太平园', '川藏立交', '武侯立交', '武青南路', '双凤桥',
    '龙桥路', '航都大街', '迎春桥', '东升', '双流广场', '三里坝', '双流西站'],
  // 4号线站点
  ['西河', '明蜀王陵', '成都大学', '十陵', '来龙', '槐树店', '万年场', '双桥路', '玉双路', '市二医院', '太升南路',
    '骡马市', '宽窄巷子', '中医大省医院', '草堂北路', '西南财大', '文化宫', '清江西路', '成都西站', '中坝', '蔡桥', '非遗博览园',
    '马厂坝', '凤凰大街', '涌泉', '光华公园', '南熏大道', '凤溪河', '杨柳河', '万盛'],
  // 5号线站点
  ['华桂路', '柏水场', '廖家湾', '北部商贸城', '幸福桥', '九道堰', '杜家碾', '大丰', '石犀公园', '皇花园',
    '陆家桥', '泉水路', '洞子口', '福宁路', '五块石', '赛云台', '北站西二路', '西北桥', '花牌坊', '抚琴',
    '中医大省医院', '青羊宫', '省骨科医院', '高升桥', '科园', '九兴大道', '神仙树', '石羊立交', '市一医院',
    '交子大道', '锦城大道', '锦城湖', '大源', '民乐', '骑龙', '警官学院', '二江寺', '南湖立交', '怡心湖',
    '龙马路', '回龙'],
  // 6号线站点
  ['望丛祠', '和平街', '郫筒', '蜀新大道', '檬梓', '尚锦路', '红高路', '天宇路', '犀浦',
    '兴业北街', '梓橦宫', '侯家桥', '兴盛', '青杠', '西华大道', '金府', '星河', '西南交大', '沙湾',
    '西北桥', '人民北路', '梁家巷', '前锋路', '建设北路', '新鸿路', '玉双路', '牛王庙', '顺江路', '三官堂',
    '东光', '琉璃场', '琉三路', '金石路', '金融城东', '中和', '张家寺', '陆肖', '观东', '新通大道', '新川路', '龙灯山',
    '蒲草塘', '万安', '麓山大道', '沈阳路', '青岛路', '昌公堰', '杭州路', '天府商务区', '西博城', '秦皇寺', '松林', '芦角',
    '钓鱼嘴', '回龙', '兰家沟'],
  // 7号线站点（环线）
  ['火车北站', '驷马桥', '府青路', '八里庄', '二仙桥', '理工大学', '崔家店', '双店路', '槐树店', '迎辉路',
    '成都东客站', '大观', '狮子山', '四川师大', '三瓦窑', '火车南站', '神仙树', '高朋大道', '太平园', '武侯大道', '龙爪堰',
    '东坡路', '文化宫', '金沙博物馆', '一品天下', '茶店子', '花照壁', '西南交大', '九里堤', '北站西二路'],
  // 8号线站点
  ['桂龙路', '桂林', '同乐', '龙潭寺', '龙潭立交', '圣灯公园', '十里店', '理工大学', '东郊记忆', '杉板桥', '万年路',
    '双桥路', '东大路', '净居寺', '东光', '东湖公园', '川大望江校区', '倪家桥', '芳草街', '永丰', '九兴大道', '高朋大道',
    '殷家林', '庆安', '石羊', '三元', '顺风', '珠江路', '川大江安校区', '文星', '莲花', '龙港'],
  // 9号线站点
  ['金融城东', '心岛', '孵化园', '锦城大道', '三元', '太平寺', '华兴', '簇桥', '武青南路', '机投桥', '培风',
    '成都西站', '黄田坝'],
  // 10号线站点
  ['骡马市（暂未开通）', '人民公园（暂未开通）', '文翁石室（暂未开通）', '武侯祠', '高升桥', '红牌楼', '太平园',
    '簇锦', '华兴', '金花', '双流机场1航站楼', '双流机场2航站楼（出闸换乘）', '双流西站',
    '应天寺', '黄水', '花源', '新津站', '花桥', '五津', '儒林路', '刘家碾', '新平'],
  // 13号线站点
  ['龙安', '龙华寺', '三圣花乡', '幸福梅林', '娇子立交', '四川师大', '净居寺', '三官堂', '九眼桥', '新南门', '华西坝', '文翁石室',
    '小南街', '青羊宫', '杜甫草堂', '光华村', '东坡路', '万寿桥', '培风', '万家湾', '瓦窑滩'],
  // 17号线站点
  ['高洪', '威灵', '航天路', '人民塘', '机车厂', '二仙桥', '踏水桥', '建设北路', '红星桥', '城隍庙', '西大街', '人民公园',
    '小南街', '省骨科医院', '浣花里', '清水河大桥', '龙爪堰', '阳公桥', '机投桥', '白佛桥', '九江北'],
  // 18号线站点
  ['火车北站（暂未开通）', '骡马市（暂未开通）', '省体育馆（暂未开通）', '倪家桥（暂未开通）', '火车南站', '孵化园', '锦城广场东',
    '世纪城', '海昌路', '西博城', '兴隆', '天府站（仅换乘）', '三岔', '福田', '天府机场3号4号航站楼（暂未开通）',
    '天府机场1号2号航站楼', '天府机场北', '官堰（暂未开通）'],
  // 19号线站点
  ['金星', '黄石', '市五医院', '凤溪河', '温泉大道', '明光', '九江北', '龙桥路', '双流机场2航站楼东（出闸换乘）',
    '龙港', '温家山', '牧华路', '怡心湖', '正兴湾', '红莲', '天府商务区', '蓝家店', '天府站（仅换乘）', '三岔', '福田',
    '天府机场3号4号航站楼（暂未开通）', '天府机场1号2号航站楼', '天府机场北'],
  // 27号线站点
  ['石佛', '慈义', '兴城大道', '旃檀寺', '石门坎', '三圣寺', '范家巷', '鲤鱼湾', '赖家店', '白仁店（暂未开通）',
    '韦家碾', '双水碾', '王贾桥', '洞子口', '沙河源', '新桥', '金府', '花照壁北', '金牛公园', '羊犀立交', '黄忠',
    '金沙滨河公园', '蜀鑫路'],
  // 30号线站点
  ['双流机场2航站楼东（出闸换乘）', '寺圣', '星月', '光明', '谢家渡', '珠江路', '大同', '石羊东', '新园大道',
    '市一医院', '益州大道', '金融城北', '府城桥', '金石路', '棬子树', '锦逸', '娇子立交', '海桐街', '航天立交', '惠王陵',
    '玉石', '分水', '玉虹路', '龙泉驿火车站南（出闸换乘）'],
  // S3（资阳）线站点
  ['福田', '资阳临空', '幸福大道', '苌弘广场', '宝台', '资阳北站'],
  // 蓉2号线站点
  ['郫县西站', '菠萝滩（暂未开通）', '梨园路', '和兴街（暂未开通）', '望丛祠', '望丛中路（暂未开通）', '何公路', '晨光', '花石',
    '大禹东路', '红展东路', '红旗大道', '德富大道', '安泰五路（暂未开通）', '安泰二路（暂未开通）', '康强四路（暂未开通）', '蜀新大道（暂未开通）', '天源路',
    '天映路', '安埠', '天欣路', '合作路', '合信路', '天润路（暂未开通）', '电子科大', '新达路（暂未开通）', '锦城学院', '新业路',
    '土龙路', '两河路（暂未开通）', '清淳（暂未开通）', '联工', '成都西站'],
];

// 线路颜色数据
const LineColors = [
  '#380096', '#FA633B', '#D6026B', '#00AF60', '#8E3981',
  '#8A7530', '#72D1DD', '#9AC316', '#E9AD00', '#0750A3',
  '#B2A222', '#8CCA9E', '#0B6267', '#9C9ECE', '#8FC31F', '#E3718E', '#838382'
];

// 获取线路名称的方法
function getClassifyName(index: number): string {
  const lineNames = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "13", "17", "18", "19", "27", "30", "S3", "92"];
  return lineNames[index] || (index + 1).toString();
}

// 获取线路颜色的方法
function getLineColor(lineIndex: number): string {
  return LineColors[lineIndex] || '#7CBA27';
}

// 判断是否为换乘站
function isTransferStation(stationName: string): boolean {
  let count = 0;
  for (let i = 0; i < MetroStationData.length; i++) {
    const cleanStationName = stationName.replace('（暂未开通）', '');
    for (let j = 0; j < MetroStationData[i].length; j++) {
      if (MetroStationData[i][j].includes(cleanStationName)) {
        count++;
        break;
      }
    }
  }
  return count > 1;
}

// 获取换乘站涉及的线路信息
function getTransferStationLines(stationName: string): LineInfo[] {
  let lines: LineInfo[] = [];
  const cleanStationName = stationName.replace('（暂未开通）', '');
  
  for (let i = 0; i < MetroStationData.length; i++) {
    const stationIndex = MetroStationData[i].findIndex(name => name.includes(cleanStationName));
    if (stationIndex !== -1) {
      lines.push({
        lineNumber: getClassifyName(i),
        stationNumber: (stationIndex + 1).toString(),
        color: getLineColor(i)
      });
    }
  }
  return lines;
}

// 添加一个多线路图标组件，用于显示换乘站的信息
@Component
struct MultiLineMetroIcon {
  @Prop lineInfos: LineInfo[];

  build() {
    Row() {
      ForEach(this.lineInfos, (info: LineInfo, index: number) => {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.cdmetro'))
            .width(30)
            .height(30)
            .objectFit(ImageFit.Contain)
            .fillColor(info.color)
            .margin({ left: 2 })

          Row() {
            Text(`${info.lineNumber.padStart(2, '0')}`)
              .fontSize(7)
              .fontColor(info.color)
              .textAlign(TextAlign.Center)
              .margin({ left: 1, right: 5 })
            Text(`${info.stationNumber.padStart(2, '0')}`)
              .fontSize(7)
              .fontColor(info.color)
              .textAlign(TextAlign.Center)
          }
        }
        .width(30)
        .height(30)
      }, (info: LineInfo) => JSON.stringify(info))
    }
    .width('hug')
    .height(30)
    .alignItems(VerticalAlign.Center)
  }
}

@Component
struct FavoriteStationItem {
  @Prop stationName: string;
  @Prop stationEnglishName: string;
  @Prop lineNumber: string;
  @Prop stationNumber: string;
  @Prop lineColor: string;
  @Prop description: string;
  @State isPlaying: boolean = false; // 播放状态
  private avPlayer: media.AVPlayer | null = null;
  private audioUrl: string = '';
  tag: string = 'FavoriteStationItem';

  aboutToAppear() {
    // 初始化音频URL
    const audioUrls: Map<string, string> = new Map([
      ['龙平路', 'http://www.hnyqwq.cn/hvideo/audios/LongpingRoad.mp3'],
      ['界牌', 'http://www.hnyqwq.cn/hvideo/audios/Jiepai.mp3'],
      ['成都行政学院', 'http://www.hnyqwq.cn/hvideo/audios/ChengduAcademyofGovernance.mp3'],
      ['塔子山公园', 'http://www.hnyqwq.cn/hvideo/audios/TazishanPark.mp3'],
      ['白果林', 'http://www.hnyqwq.cn/hvideo/audios/Baiguolin.mp3'],
      ['一品天下', 'http://www.hnyqwq.cn/hvideo/audios/Yipingtianxia.mp3'],
      ['文明乘车', 'http://www.hnyqwq.cn/hvideo/audios/wmcc.mp3'],
      ['文明乘车日', 'http://www.hnyqwq.cn/hvideo/audios/11.mp3'],
      ['18号线语音播报', 'http://www.hnyqwq.cn/hvideo/audios/18.mp3'],
      ['19号线语音播报', 'http://www.hnyqwq.cn/hvideo/audios/19.mp3']
    ]);
    
    this.audioUrl = audioUrls.get(this.stationName) || '';
    this.isPlaying = false;
  }

  aboutToDisappear() {
    // 页面销毁时释放播放器资源
    if (this.avPlayer) {
      this.avPlayer.release().then(() => {
        this.avPlayer = null;
      }).catch((error: BusinessError) => {
        console.error(`${this.tag}: release player failed, error: ${JSON.stringify(error)}`);
      });
    }
  }

  // 初始化播放器
  private async initPlayer() {
    if (!this.audioUrl) {
      console.error(`${this.tag}: audio url is empty for station ${this.stationName}`);
      return;
    }

    try {
      // 使用 await 确保 AVPlayer 创建完成
      this.avPlayer = await media.createAVPlayer();
      this.avPlayer.url = this.audioUrl;
      
      // 监听播放完成事件
      this.avPlayer.on('stateChange', (state: string) => {
        if (state === 'completed') {
          this.isPlaying = false;
        }
      });
      
      // 监听错误事件
      this.avPlayer.on('error', (error: BusinessError) => {
        console.error(`${this.tag}: player error, error: ${JSON.stringify(error)}`);
        this.isPlaying = false;
      });
      
      // 立即准备播放器
      await this.avPlayer.prepare();
    } catch (error) {
      console.error(`${this.tag}: init player failed, error: ${JSON.stringify(error)}`);
    }
  }

  // 播放/暂停音频
  private async togglePlay() {
    if (!this.audioUrl) {
      console.error(`${this.tag}: no audio url for station ${this.stationName}`);
      return;
    }

    try {
      if (!this.avPlayer) {
        // 初始化播放器并等待其完成
        await this.initPlayer();
        
        // 确保播放器已创建且可以使用
        if (this.avPlayer) {
          // 设置初始 isPlaying 状态为 true，提供即时反馈
          this.isPlaying = true;
          
          // 播放器已准备好，直接播放
          const player = this.avPlayer as media.AVPlayer;
          await player.play();
        }
      } else {
        const player = this.avPlayer as media.AVPlayer;
        if (this.isPlaying) {
          await player.pause();
          this.isPlaying = false;
        } else {
          // 如果处于完成状态，需要重新准备
          this.isPlaying = true; // 提供即时反馈
          await player.prepare().catch((err: Error) => {
            console.error(`${this.tag}: prepare failed, error: ${JSON.stringify(err)}`);
            this.isPlaying = false;
            throw err;
          });
          await player.play().catch((err: Error) => {
            console.error(`${this.tag}: play failed, error: ${JSON.stringify(err)}`);
            this.isPlaying = false;
            throw err;
          });
        }
      }
    } catch (error) {
      if (error instanceof Error) {
        console.error(`${this.tag}: toggle play failed, error: ${JSON.stringify(error)}`);
      } else {
        console.error(`${this.tag}: toggle play failed, error: ${JSON.stringify(error)}`);
      }
      this.isPlaying = false;
    }
  }

  build() {
    Row() {
      // 地铁图标
      if (isTransferStation(this.stationName)) {
        // 如果是换乘站，显示所有涉及的线路图标
        MultiLineMetroIcon({
          lineInfos: getTransferStationLines(this.stationName)
        })
        .margin({ left: 10 })
      } else {
        // 如果不是换乘站，显示单个线路图标
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.cdmetro'))
            .width(40)
            .height(40)
            .objectFit(ImageFit.Contain)
            .fillColor(this.lineColor)
            .margin({ left: 2 })

          Row() {
            Text(`${this.lineNumber.padStart(2, '0')}`)
              .fontSize(8)
              .fontColor(this.lineColor)
              .textAlign(TextAlign.Center)
              .margin({ left: 1, right: 8 })
            Text(`${this.stationNumber.padStart(2, '0')}`)
              .fontSize(8)
              .fontColor(this.lineColor)
              .textAlign(TextAlign.Center)
          }
        }
        .width(40)
        .height(40)
        .margin({ left: 10 })
      }

      Column() {
        Text(this.stationName)
          .fontSize(16)
          .fontColor('#182431')
          .margin({ left: 10 })
        Text(this.stationEnglishName)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 10, top: 2 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Start)

      // 语音播放按钮
      Image(this.isPlaying ? $r("app.media.pause") : $r("app.media.play_circle_fill"))
        .width(30)
        .height(30)
        .margin({ right: 20 })
        .onClick(() => {
          this.togglePlay();
        })
    }
    .height(60)
    .alignItems(VerticalAlign.Center)
    .backgroundColor('#FFFFFF')
  }
}

@Entry
@Component
struct FavoriteStations {
  // 常用站点列表 - 从Metro.ets中获取数据构建
  @State favoriteStations: Array<StationInfo> = [
    {
      name: '龙平路',
      englishName: 'Longping Road',
      lineNumber: '2',
      stationNumber: '2',
      lineColor: getLineColor(1),
      description: '小乔提醒您：“恋爱和战斗，都要勇往直前，龙平路站到了。”'
    },
    { 
      name: '界牌',
      englishName: 'Jiepai',
      lineNumber: '2',
      stationNumber: '4',
      lineColor: getLineColor(1),
      description: '貂蝉提醒您：“星光化作翅膀，长久闪烁，界牌站到了。”'
    },
    { 
      name: '成都行政学院',
      englishName: 'Chengdu Academy of Governance',
      lineNumber: '2',
      stationNumber: '7',
      lineColor: getLineColor(1),
      description: '瑶提醒您：“这是谁的小鹿，真厉害，成都行政学院站到了。”'
    },
    { 
      name: '塔子山公园',
      englishName: 'Tazishan Park',
      lineNumber: '2',
      stationNumber: '12',
      lineColor: getLineColor(1),
      description: '李白提醒您：“大河之剑天上来，塔子山公园站到了。”'
    },
    { 
      name: '白果林',
      englishName: 'Baiguolin',
      lineNumber: '2',
      stationNumber: '22',
      lineColor: getLineColor(1),
      description: '曜提醒您：“星光荡开宇宙，本人闪耀其中，白果林站到了。”'
    },
    { 
      name: '一品天下',
      englishName: 'Yipingtianxia',
      lineNumber: '2',
      stationNumber: '24',
      lineColor: getLineColor(1),
      description: '李信提醒您：“吾持剑锋，以筑长城，一品天下站到了。”'
    },
    {
      name: '文明乘车',
      englishName: '',
      lineNumber: '',
      stationNumber: '',
      lineColor: getLineColor(0),
      description: '“文明乘车，关爱他人。和谐共处，共建平安。乘客您好，请爱护公共卫生及设备设施，成都地铁邀您一路文明出行。”'
    },
    {
      name: '文明乘车日',
      englishName: '',
      lineNumber: '',
      stationNumber: '',
      lineColor: getLineColor(0),
      description: '“每月11日是成都地铁文明乘车日，敬老爱幼，礼让和谐，传递温暖，共享平安，让我们一同文明出行。”'
    },
    {
      name: '18号线语音播报',
      englishName: '',
      lineNumber: '',
      stationNumber: '',
      lineColor: getLineColor(0),
      description: '列车到站前，车站广播会不间断播放线路线别、列车编组及终点站提示信息，其中18号线采用女声播报，19号线采用男声播报，乘客可通过男女声音区分18、19号线列车。'
    },
    {
      name: '19号线语音播报',
      englishName: '',
      lineNumber: '',
      stationNumber: '',
      lineColor: getLineColor(0),
      description: '列车到站前，车站广播会不间断播放线路线别、列车编组及终点站提示信息，其中18号线采用女声播报，19号线采用男声播报，乘客可通过男女声音区分18、19号线列车。'
    }
  ];

  build()
  {
    Column()
    {
      Column() {
        // 页面标题（不含返回按钮）
        Row() {
          Column(){
            Text('彩蛋站点')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Text('来源均为官方文章，仅供娱乐，侵权立删')
              .fontSize(12)
              .fontColor('#666666')
              .textAlign(TextAlign.Start)
              .margin({ top: 2 })
          }
        }
        .height(60)
        .alignItems(VerticalAlign.Center)

        // 站点列表项
        ForEach(this.favoriteStations, (station: StationInfo, index: number) => {
          Column() {
            // 添加描述文字
            Text(station.description)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 20, top: 5, right: 20 })
              .textAlign(TextAlign.Start)
              
            FavoriteStationItem({
              stationName: station.name,
              stationEnglishName: station.englishName,
              lineNumber: station.lineNumber,
              stationNumber: station.stationNumber,
              lineColor: station.lineColor,
              description: station.description
            })

            // 分割线
            Divider()
              .color('#E5E5E5')
              .strokeWidth(1)
          }
        })
      }
      .height('100%')
      
      // 固定在左上角的返回按钮
      Text('󰃚')
        .fontSize(35)
        .position({ x: 20, y: 10 })
        .onClick(() => {
          router.back();
        })
    }
  }
}