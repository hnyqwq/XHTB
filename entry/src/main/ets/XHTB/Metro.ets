import { initSideData } from './Metro/TabViewModel';
import { ClassifyModel } from './Metro/TabItem';

import router from '@ohos.router';

// 定义线路信息接口
interface LineInfo {
  lineNumber: string;
  stationNumber: string;
  color: string;
}

// 使用Map来存储站点翻译，避免索引签名问题
const StationTranslations = new Map<string, string>([
  ['韦家碾', 'Weijianian'],
  ['升仙湖', 'Shengxianhu'],
  ['火车北站', 'North Railway Station'],
  ['人民北路', 'Renmin North Road'],
  ['文殊院', 'Wenshu Monastery'],
  ['天府广场', 'Tianfu Square'],
  ['锦江宾馆', 'Jinjiang Hotel'],
  ['华西坝', 'Huaxiba'],
  ['省体育馆', 'Provincial Stadium'],
  ['倪家桥', 'Nijiaqiao'],
  ['火车南站', 'South Railway Station'],
  ['高新', 'Gaoxin'],
  ['金融城', 'Financial City'],
  ['孵化园', 'Incubator Park'],
  ['锦城广场', 'Jincheng Square'],
  ['世纪城', 'Century City'],
  ['天府三街', 'Tianfu 3rd Street'],
  ['天府五街', 'Tianfu 5th Street'],
  ['华府大道', 'Huafu Avenue'],
  ['四河', 'Sihe'],
  ['华阳', 'Huayang'],
  ['海昌路', 'Haichang Road'],
  ['广福', 'Guangfu'],
  ['红石公园', 'Hongshi Park'],
  ['麓湖', 'Lu Lake'],
  ['武汉路', 'Wuhan Road'],
  ['天府公园', 'Tianfu Park'],
  ['西博城', 'Western Expo City'],
  ['广州路', 'Guangzhou Road'],
  ['兴隆湖', 'Xinglong Lake'],
  ['科学城', 'Science City'],
  ['龙泉驿', 'Longquanyi'],
  ['龙平路', 'Longping Road'],
  ['书房', 'Shufang'],
  ['界牌', 'Jiepai'],
  ['连山坡', 'Lianshanpo'],
  ['大面铺', 'Damianpu'],
  ['成都行政学院', 'Chengdu Administrative College'],
  ['洪河', 'Honghe'],
  ['惠王陵', 'Huiwangling'],
  ['成渝立交', 'Chengyu Overpass'],
  ['成都东客站', 'Chengdu East Bus Station'],
  ['塔子山公园', 'Tazishan Park'],
  ['东大路', 'East Avenue'],
  ['牛市口', 'Niushikou'],
  ['牛王庙', 'Niuwangmiao'],
  ['东门大桥', 'East Gate Bridge'],
  ['春熙路', 'Chunxi Road'],
  ['人民公园', 'People\'s Park'],
  ['通惠门', 'Tonghuimen'],
  ['中医大省医院', 'TCM University Provincial Hospital'],
  ['白果林', 'Baiguolin'],
  ['蜀汉路东', 'Shuhan Road East'],
  ['一品天下', 'Yipin Tianxia'],
  ['羊犀立交', 'Yangxi Overpass'],
  ['茶店子客运站', 'Chadianzi Bus Station'],
  ['迎宾大道', 'Yingbin Avenue'],
  ['金科北路', 'Jinke North Road'],
  ['金周路', 'Jinzhou Road'],
  ['百草路', 'Baicao Road'],
  ['天河路', 'Tianhe Road'],
  ['犀浦', 'Xipu'],
  ['成都医学院', 'Chengdu Medical College'],
  ['石油大学', 'Petroleum University'],
  ['钟楼', 'Bell Tower'],
  ['马超西路', 'Machao West Road'],
  ['团结新区', 'Tuanjie New District'],
  ['锦水河', 'Jinshui River'],
  ['三河场', 'Sanhechang'],
  ['金华寺东路', 'Jinhua Temple East Road'],
  ['植物园', 'Botanical Garden'],
  ['军区总医院', 'Military Region General Hospital'],
  ['熊猫大道', 'Panda Avenue'],
  ['动物园', 'Zoo'],
  ['昭觉寺南路', 'Zhaojuesi South Road'],
  ['驷马桥', 'Simai Bridge'],
  ['李家沱', 'Lijiata'],
  ['前锋路', 'Qianfeng Road'],
  ['红星桥', 'Hongxing Bridge'],
  ['市二医院', 'Second Municipal Hospital'],
  ['新南门', 'New South Gate'],
  ['磨子桥', 'Mozi Bridge'],
  ['衣冠庙', 'Yiguan Temple'],
  ['高升桥', 'Gaosheng Bridge'],
  ['红牌楼', 'Hongpailou'],
  ['太平园', 'Taiping Garden'],
  ['川藏立交', 'Chuanzang Overpass'],
  ['武侯立交', 'Wuhou Overpass'],
  ['武青南路', 'Wuqing South Road'],
  ['双凤桥', 'Shuangfeng Bridge'],
  ['龙桥路', 'Longqiao Road'],
  ['航都大街', 'Hangdu Avenue'],
  ['迎春桥', 'Yingchun Bridge'],
  ['东升', 'Dongsheng'],
  ['双流广场', 'Shuangliu Square'],
  ['三里坝', 'Sanliba'],
  ['双流西站', 'Shuangliu West Station'],
  ['西河', 'Xihe'],
  ['明蜀王陵', 'Ming Shu King Mausoleum'],
  ['成都大学', 'Chengdu University'],
  ['十陵', 'Shiling'],
  ['来龙', 'Lailong'],
  ['槐树店', 'Huaishudian'],
  ['万年场', 'Wannianchang'],
  ['双桥路', 'Shuangqiao Road'],
  ['玉双路', 'Yushuang Road'],
  ['太升南路', 'Taisheng South Road'],
  ['骡马市', 'Luomashi'],
  ['宽窄巷子', 'Kuanzhai Alley'],
  ['草堂北路', 'Caotang North Road'],
  ['西南财大', 'Southwestern University of Finance and Economics'],
  ['文化宫', 'Cultural Palace'],
  ['清江西路', 'Qingjiang West Road'],
  ['成都西站', 'Chengdu West Station'],
  ['中坝', 'Zhongba'],
  ['蔡桥', 'Caiqiao'],
  ['非遗博览园', 'Intangible Cultural Heritage Park'],
  ['马厂坝', 'Machangba'],
  ['凤凰大街', 'Fenghuang Avenue'],
  ['涌泉', 'Yongquan'],
  ['光华公园', 'Guanghua Park'],
  ['南熏大道', 'Nanxun Avenue'],
  ['凤溪河', 'Fengxi River'],
  ['杨柳河', 'Yangliu River'],
  ['万盛', 'Wansheng'],
  ['华桂路', 'Huagui Road'],
  ['柏水场', 'Baishuichang'],
  ['廖家湾', 'Liaojiawan'],
  ['北部商贸城', 'Northern Commercial City'],
  ['幸福桥', 'Xingfu Bridge'],
  ['九道堰', 'Jiudaoyan'],
  ['杜家碾', 'Dujianian'],
  ['大丰', 'Dafeng'],
  ['石犀公园', 'Shixi Park'],
  ['皇花园', 'Huanghuayuan'],
  ['陆家桥', 'Lujiabridge'],
  ['泉水路', 'Quanshui Road'],
  ['洞子口', 'Dongzikou'],
  ['福宁路', 'Funing Road'],
  ['五块石', 'Wukuai Stone'],
  ['赛云台', 'Saiyuntai'],
  ['北站西二路', 'North Station West 2nd Road'],
  ['西北桥', 'Northwest Bridge'],
  ['花牌坊', 'Huapai Fang'],
  ['抚琴', 'Fuqin'],
  ['青羊宫', 'Qingyang Palace'],
  ['省骨科医院', 'Provincial Orthopedic Hospital'],
  ['科园', 'Keyuan'],
  ['九兴大道', 'Jiuxing Avenue'],
  ['神仙树', 'Shenxianshu'],
  ['石羊立交', 'Shiyang Overpass'],
  ['市一医院', 'First Municipal Hospital'],
  ['交子大道', 'Jiaozi Avenue'],
  ['锦城大道', 'Jincheng Avenue'],
  ['锦城湖', 'Jincheng Lake'],
  ['大源', 'Dayuan'],
  ['民乐', 'Minle'],
  ['骑龙', 'Qilong'],
  ['警官学院', 'Police Officer College'],
  ['二江寺', 'Erjiang Temple'],
  ['南湖立交', 'Nanhu Overpass'],
  ['怡心湖', 'Yixin Lake'],
  ['龙马路', 'Longma Road'],
  ['回龙', 'Huilong'],
  ['望丛祠', 'Wangcong Temple'],
  ['和平街', 'Heping Street'],
  ['郫筒', 'Pitong'],
  ['蜀新大道', 'Shuxin Avenue'],
  ['檬梓', 'Mengzi'],
  ['尚锦路', 'Shangjin Road'],
  ['红高路', 'Honggao Road'],
  ['天宇路', 'Tianyu Road'],
  ['兴业北街', 'Xingye North Street'],
  ['梓橦宫', 'Zitong Palace'],
  ['侯家桥', 'Houjia Bridge'],
  ['兴盛', 'Xingsheng'],
  ['青杠', 'Qinggang'],
  ['西华大道', 'Xihua Avenue'],
  ['金府', 'Jinfu'],
  ['星河', 'Xinghe'],
  ['西南交大', 'Southwest Jiaotong University'],
  ['沙湾', 'Shawan'],
  ['梁家巷', 'Liangjia Lane'],
  ['建设北路', 'Construction North Road'],
  ['新鸿路', 'Xinhong Road'],
  ['玉双路', 'Yushuang Road'],
  ['顺江路', 'Shunjing Road'],
  ['三官堂', 'Sanguantang'],
  ['东光', 'Dongguang'],
  ['琉璃场', 'Liuli Field'],
  ['琉三路', 'Liu 3rd Road'],
  ['金石路', 'Jinshi Road'],
  ['金融城东', 'Financial City East'],
  ['中和', 'Zhonghe'],
  ['张家寺', 'Zhangjiasi'],
  ['陆肖', 'Luxiao'],
  ['观东', 'Guandong'],
  ['新通大道', 'Xintong Avenue'],
  ['新川路', 'Xinchuan Road'],
  ['龙灯山', 'Longdeng Mountain'],
  ['蒲草塘', 'Pucutang'],
  ['万安', 'Wan\'an'],
  ['麓山大道', 'Lushan Avenue'],
  ['沈阳路', 'Shenyang Road'],
  ['青岛路', 'Qingdao Road'],
  ['昌公堰', 'Changgongyan'],
  ['杭州路', 'Hangzhou Road'],
  ['天府商务区', 'Tianfu Business District'],
  ['秦皇寺', 'Qinhuang Temple'],
  ['松林', 'Songlin'],
  ['芦角', 'Lujaio'],
  ['钓鱼嘴', 'Diaoyuzui'],
  ['府青路', 'Fuqing Road'],
  ['八里庄', 'Baliazhuang'],
  ['二仙桥', 'Erxiang Bridge'],
  ['理工大学', 'University of Technology'],
  ['崔家店', 'Cuijiadian'],
  ['双店路', 'Shuangdian Road'],
  ['槐树店', 'Huaishudian'],
  ['迎辉路', 'Yinghui Road'],
  ['大观', 'Daguan'],
  ['狮子山', 'Shizishan'],
  ['四川师大', 'Sichuan Normal University'],
  ['三瓦窑', 'Sanwayao'],
  ['高朋大道', 'Gaopeng Avenue'],
  ['武侯大道', 'Wuhou Avenue'],
  ['龙爪堰', 'Longzhuayan'],
  ['东坡路', 'Dongpo Road'],
  ['金沙博物馆', 'Jinsha Museum'],
  ['茶店子', 'Chadianzi'],
  ['花照壁', 'Huazhaobi'],
  ['九里堤', 'Jiuliti'],
  ['桂龙路', 'Guilong Road'],
  ['桂林', 'Guilin'],
  ['同乐', 'Tongle'],
  ['龙潭寺', 'Longtansi'],
  ['龙潭立交', 'Longtan Overpass'],
  ['圣灯公园', 'Shengdeng Park'],
  ['十里店', 'Shilidian'],
  ['东郊记忆', 'East Suburb Memory'],
  ['杉板桥', 'Shanban Bridge'],
  ['万年路', 'Wannian Road'],
  ['净居寺', 'Jingju Temple'],
  ['东湖公园', 'Donghu Park'],
  ['川大望江校区', 'SCU Wangjiang Campus'],
  ['芳草街', 'Fangcao Street'],
  ['永丰', 'Yongfeng'],
  ['殷家林', 'Yinjialin'],
  ['庆安', 'Qing\'an'],
  ['石羊', 'Shiyang'],
  ['三元', 'Sanyuan'],
  ['顺风', 'Shunfeng'],
  ['珠江路', 'Zhujiang Road'],
  ['川大江安校区', 'SCU Jiang\'an Campus'],
  ['文星', 'Wenxing'],
  ['莲花', 'Lianhua'],
  ['龙港', 'Longgang'],
  ['心岛', 'Xindao'],
  ['太平寺', 'Taiping Temple'],
  ['华兴', 'Huaxing'],
  ['簇锦', 'Cujin'],
  ['机投桥', 'Jitou Bridge'],
  ['培风', 'Peifeng'],
  ['黄田坝', 'Huangtianba'],
  ['武侯祠', 'Wuhou Shrine'],
  ['金花', 'Jinhua'],
  ['双流机场1航站楼', 'Shuangliu Airport Terminal 1'],
  ['双流机场2航站楼（出闸换乘）', 'Shuangliu Airport Terminal 2 (Transfer)'],
  ['应天寺', 'Yingtiansi'],
  ['黄水', 'Huangshui'],
  ['花源', 'Huayuan'],
  ['新津站', 'Xinjin Station'],
  ['花桥', 'Huaqiao'],
  ['五津', 'Wujin'],
  ['儒林路', 'Rulin Road'],
  ['刘家碾', 'Liujianian'],
  ['新平', 'Xinping'],
  ['龙安', 'Long\'an'],
  ['龙华寺', 'Longhuasi'],
  ['三圣花乡', 'Sansheng Huaxiang'],
  ['幸福梅林', 'Xingfu Meilin'],
  ['娇子立交', 'Jiaozi Overpass'],
  ['九眼桥', 'Jiuyan Bridge'],
  ['文翁石室', 'Wenweng Shishi'],
  ['小南街', 'Xiao Nan Street'],
  ['杜甫草堂', 'Du Fu Thatched Cottage'],
  ['光华村', 'Guanghua Village'],
  ['万寿桥', 'Wanshou Bridge'],
  ['万家湾', 'Wanjiawan'],
  ['瓦窑滩', 'Wayao Beach'],
  ['高洪', 'Gaohong'],
  ['威灵', 'Weiling'],
  ['航天路', 'Aerospace Road'],
  ['人民塘', 'Renmintang'],
  ['机车厂', 'Locomotive Factory'],
  ['踏水桥', 'Tashui Bridge'],
  ['城隍庙', 'City God Temple'],
  ['西大街', 'West Street'],
  ['浣花里', 'Huanhua Li'],
  ['清水河大桥', 'Qingshui River Bridge'],
  ['阳公桥', 'Yanggong Bridge'],
  ['白佛桥', 'Baifo Bridge'],
  ['九江北', 'Jiujiang North'],
  ['锦城广场东', 'Jincheng Square East'],
  ['兴隆', 'Xinglong'],
  ['天府站（仅换乘）', 'Tianfu Station (Transfer Only)'],
  ['三岔', 'Sancha'],
  ['福田', 'Futian'],
  ['天府机场3号4号航站楼（暂未开通）', 'Tianfu Airport Terminals 3&4 (Not Yet Open)'],
  ['天府机场1号2号航站楼', 'Tianfu Airport Terminals 1&2'],
  ['天府机场北', 'Tianfu Airport North'],
  ['官堰（暂未开通）', 'Guanyan (Not Yet Open)'],
  ['金星', 'Jinxing'],
  ['黄石', 'Huangshi'],
  ['市五医院', 'Fifth Municipal Hospital'],
  ['温泉大道', 'Wenquan Avenue'],
  ['明光', 'Mingguang'],
  ['双流机场2航站楼东（出闸换乘）', 'Shuangliu Airport T2 East (Transfer)'],
  ['温家山', 'Wenjiasan'],
  ['牧华路', 'Muhua Road'],
  ['正心湾', 'Zhengxin Bay'],
  ['红莲', 'Honglian'],
  ['蓝家店', 'Lanjaidian'],
  ['石佛', 'Shifo'],
  ['慈义', 'Ciyi'],
  ['兴城大道', 'Xingcheng Avenue'],
  ['旃檀寺', 'Zhantansi'],
  ['石门坎', 'Shimenkan'],
  ['三圣寺', 'Sanshengsi'],
  ['范家巷', 'Fanjia Lane'],
  ['鲤鱼湾', 'Li Yu Wan'],
  ['赖家店', 'Laijiadian'],
  ['双水碾', 'Shuangshuinian'],
  ['王贾桥', 'Wangjia Bridge'],
  ['沙河源', 'Shaheyuan'],
  ['新桥', 'Xinqiao'],
  ['花照壁北', 'Huazhaobi North'],
  ['金牛公园', 'Jinniu Park'],
  ['黄忠', 'Huangzhong'],
  ['金沙滨河公园', 'Jinsha Riverside Park'],
  ['蜀鑫路', 'Shuxin Road'],
  ['寺圣', 'Sisheng'],
  ['星月', 'Xingyue'],
  ['光明', 'Guangming'],
  ['谢家渡', 'Xiejia Ferry'],
  ['大同', 'Datong'],
  ['石羊东', 'Shiyang East'],
  ['新园大道', 'Xinyuan Avenue'],
  ['益州大道', 'Yizhou Avenue'],
  ['金融城北', 'Financial City North'],
  ['府城桥', 'Fucheng Bridge'],
  ['棬子树', 'Quanzishu'],
  ['锦逸', 'Jinyi'],
  ['海桐街', 'Haitong Street'],
  ['航天立交', 'Aerospace Overpass'],
  ['惠王陵', 'Huiwangling'],
  ['玉石', 'Yushi'],
  ['分水', 'Fenshui'],
  ['玉虹路', 'Yuhong Road'],
  ['龙泉驿火车站南', 'Longquanyi Railway Station South']
]);

@Component
struct MetroIcon {
  @Prop lineNumber: string;
  @Prop stationNumber: string;
  @Prop color: string = '#182431';

  build() {
    Row() {
      // 使用自定义的地铁图标组件，包含SVG图标和数字
      Row() {
        // 使用Stack布局将数字放置在SVG图标上
        Stack({ alignContent: Alignment.Center }) {
          // SVG图标
          Image($r('app.media.cdmetro'))
            .width(50)
            .height(50)
            .objectFit(ImageFit.Contain)
            .fillColor(this.color)  // 更改SVG颜色
            .margin( { left : 2 } )

          // 数字编号
          Row() {
            Text(`${this.lineNumber.padStart(2, '0')}`)
              .fontSize(10)
              .fontColor(this.color)
              .textAlign(TextAlign.Center)
              .margin( { left : 1 , right : 10 } )
            Text(`${this.stationNumber.padStart(2, '0')}`)
              .fontSize(10)
              .fontColor(this.color)
              .textAlign(TextAlign.Center)
          }
        }
        .width(50)
        .height(50)
      }
    }
  }
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
struct ClassifyItem {
  @Prop isSelected: boolean = false;
  @Prop classifyName: string | Resource;
  @Prop index: number;
  @Prop currentClassify: number;

  build() {
    Text(this.classifyName)
      .fontSize(14)
      .fontColor(this.isSelected ? '#182431' : '#99182431')
      .fontFamily(this.isSelected ? 'HarmonyHeiTi-Medium' : 'HarmonyHeiTi')
      .fontWeight(this.isSelected ? FontWeight.Medium : FontWeight.Normal)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.isSelected ? '#FFFFFF' : '')
      .width('100%')
      .height(52)
  }
}

@Entry
@Component
struct SideTab {
  @State currentClassify: number = 0;
  @State ClassifyArray: Array<ClassifyModel> = initSideData();
  // 站点录入
  @State stationData: Array<Array<string>> = [
    // 1号线站点
    ['韦家碾', '升仙湖', '火车北站', '人民北路', '文殊院', '天府广场', '锦江宾馆', '华西坝', '省体育馆', '倪家桥',
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
     '钓鱼嘴', '回龙'],
    // 7号线站点（环线）
    ['火车北站', '驷马桥', '府青路', '八里庄', '二仙桥', '理工大学', '崔家店', '双店路', '槐树店', '迎辉路',
     '成都东客站', '大观', '狮子山', '四川师大', '三瓦窑', '火车南站', '神仙树', '高朋大道', '太平园', '武侯大道', '龙爪堰',
     '东坡路', '文化宫', '金沙博物馆', '一品天下', '茶店子', '花照壁', '西南交大', '九里堤', '北站西二路'],
    // 8号线站点
    ['桂龙路', '桂林', '同乐', '龙潭寺', '龙潭立交', '圣灯公园', '十里店', '理工大学', '东郊记忆', '杉板桥', '万年路',
     '双桥路', '东大路', '净居寺', '东光', '东湖公园', '川大望江校区', '倪家桥', '芳草街', '永丰', '九兴大道', '高朋大道',
     '殷家林', '庆安', '石羊', '三元', '顺风', '珠江路', '川大江安校区', '文星', '莲花', '龙港'],
    // 9号线站点
    ['金融城东', '心岛', '孵化园', '锦城大道', '三元', '太平寺', '华兴', '簇锦', '武青南路', '机投桥', '培风',
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
     '龙港', '温家山', '牧华路', '怡心湖', '正心湾', '红莲', '天府商务区', '蓝家店', '天府站（仅换乘）', '三岔', '福田',
     '天府机场3号4号航站楼（暂未开通）', '天府机场1号2号航站楼', '天府机场北'],
     // 27号线站点
    ['石佛', '慈义', '兴城大道', '旃檀寺', '石门坎', '三圣寺', '范家巷', '鲤鱼湾', '赖家店',
     '韦家碾', '双水碾', '王贾桥', '洞子口', '沙河源', '新桥', '金府', '花照壁北', '金牛公园', '羊犀立交', '黄忠',
     '金沙滨河公园', '蜀鑫路'],
    // 30号线站点
    ['双流机场2航站楼东（出闸换乘）', '寺圣', '星月', '光明', '谢家渡', '珠江路', '大同', '石羊东', '新园大道',
     '市一医院', '益州大道', '金融城北', '府城桥', '金石路', '棬子树', '锦逸', '娇子立交', '海桐街', '航天立交', '惠王陵',
     '玉石', '分水', '玉虹路', '龙泉驿火车站南'],
  ];
  private classifyScroller: Scroller = new Scroller();
  private scroller: Scroller = new Scroller();

  classifyChangeAction(index: number): void {
    if (this.currentClassify !== index && index !== undefined) {
      this.currentClassify = index;
      this.classifyScroller.scrollToIndex(index);
    }
  }

  // 修改站点名称的方法
  modifyStationName(classifyIndex: number, stationIndex: number, newName: string): void {
    if (this.stationData[classifyIndex] && this.stationData[classifyIndex][stationIndex]) {
      this.stationData[classifyIndex][stationIndex] = newName;
    }
  }

  // 获取线路名称的方法
  getClassifyName(index: number): string {
    // 根据索引直接获取线路名
    switch(index) {
      case 0: return "1";
      case 1: return "2";
      case 2: return "3";
      case 3: return "4";
      case 4: return "5";
      case 5: return "6";
      case 6: return "7";
      case 7: return "8";
      case 8: return "9";
      case 9: return "10";
      case 10: return "13";
      case 11: return "17";
      case 12: return "18";
      case 13: return "19";
      case 14: return "27";
      case 15: return "30";
      default: return (index + 1).toString();
    }
  }

  // 获取线路颜色的方法
  getLineColors(lineIndex: number): string {
    const colors = [
      '#380096', '#FA633B', '#D6026B', '#00AF60', '#8E3981',
      '#8A7530', '#72D1DD', '#9AC316', '#E9AD00', '#0750A3',
      '#B2A222', '#8CCA9E', '#0B6267', '#9C9ECE', '#8FC31F', '#E3718E'
    ];
    return colors[lineIndex] || '#838382';
  }

  // 判断是否为换乘站
  isTransferStation(stationName: string): boolean {
    let count = 0;
    for (let i = 0; i < this.stationData.length; i++) {
      // 注意：有些站点名称带"（暂未开通）"后缀，需要特殊处理
      const cleanStationName = stationName.replace('（暂未开通）', '');
      for (let j = 0; j < this.stationData[i].length; j++) {
        if (this.stationData[i][j].includes(cleanStationName)) {
          count++;
          break;
        }
      }
    }
    return count > 1;
  }

  // 获取换乘站涉及的线路信息
  getTransferStationLines(stationName: string): LineInfo[] {
    let lines: LineInfo[] = [];
    const cleanStationName = stationName.replace('（暂未开通）', '');
    
    for (let i = 0; i < this.stationData.length; i++) {
      const stationIndex = this.stationData[i].findIndex(name => name.includes(cleanStationName));
      if (stationIndex !== -1) {
        lines.push({
          lineNumber: this.getClassifyName(i),
          stationNumber: (stationIndex + 1).toString(),
          color: this.getLineColors(i)
        });
      }
    }
    return lines;
  }

  build() {
    Stack() {
      Row() {
        List({ scroller: this.classifyScroller }) {
          ForEach(this.ClassifyArray, (item: ClassifyModel, index?: number) => {
            ListItem() {
              ClassifyItem({
                classifyName: item.classifyName,
                isSelected: this.currentClassify === (index !== undefined ? index : -1),
                index: index !== undefined ? index : -1,
                currentClassify: this.currentClassify
              })
              .onClick(() => {
                if (index !== undefined) {
                  this.classifyChangeAction(index);
                }
              })
            }
          }, (item: ClassifyModel, index: number) => JSON.stringify(item) + index.toString())
        }
        .height('100%')
        .width('27.8%')
        .backgroundColor('#F1F3F5')
        .scrollBar(BarState.Off)
        .margin({ top: 94 })

        List({ scroller: this.scroller }) {
          // 添加安全检查，确保stationData[currentClassify]存在
          ForEach(
            (this.stationData && this.stationData[this.currentClassify]) ? 
            this.stationData[this.currentClassify] : 
            [], 
            (stationName: string, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Column() {
                    Text(stationName)
                      .fontSize(16)
                      .fontColor('#182431')
                      .margin({ left: 20 })
                      .draggable(true)
                      .copyOption(CopyOptions.LocalDevice)
                    Text(StationTranslations.get(stationName) || '')
                      .fontSize(12)
                      .fontColor('#999999')
                      .margin({ left: 20, top: 2 })
                      .draggable(true)
                      .copyOption(CopyOptions.LocalDevice)
                  }
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.Center)
                  .alignItems(HorizontalAlign.Start)
                  
                  Blank()
                  // 检查是否是换乘站并显示对应的多个线路图标
                  if (this.isTransferStation(stationName)) {
                    MultiLineMetroIcon({
                      lineInfos: this.getTransferStationLines(stationName)
                    })
                    .margin({ right: 20 })
                  } else {
                    // 添加地铁图标
                    MetroIcon({
                      lineNumber: this.getClassifyName(this.currentClassify),
                      stationNumber: (index + 1).toString(),
                      color: this.getLineColors(this.currentClassify)
                    })
                    .margin({ right: 20 })
                  }
                }
                .height(60)
                .alignItems(VerticalAlign.Center)
                .backgroundColor('#FFFFFF')
                .width('100%')
                // 点击行可以修改内容（示例）
                .onClick(() => {
                  // 这里可以添加修改逻辑，例如弹出输入框
                  console.log(`点击了 ${stationName}，可以在这里添加修改逻辑`);
                })
                
                // 添加灰色分割线（除了最后一项）
                // 添加安全检查，确保数组存在
                if (this.stationData && 
                    this.stationData[this.currentClassify] && 
                    index < this.stationData[this.currentClassify].length - 1) {
                  Divider()
                    .color('#E5E5E5')
                    .strokeWidth(1)
                }
              }
            }
          }, (stationName: string, index: number) => stationName + index.toString())
        }
        .width('72.2%')
        .height('100%')
        .scrollBar(BarState.Off)
        .margin({ top: 94 })
        // [End Side_tab_list]
      }
      .backgroundColor('#FFFFFF')
      
      Text('󰃚') // 自定义返回图标
        .fontSize(35)
        .margin({ left: 20 }) // 左侧留白
        .onClick(() => {
          router.back();
        })
        .position({ x: 0, y: 0 })
    }
  }
}