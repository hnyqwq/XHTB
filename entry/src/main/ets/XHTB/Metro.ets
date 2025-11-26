import { initSideData } from './Metro/TabViewModel';
import { ClassifyModel } from './Metro/TabItem';

import router from '@ohos.router';

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
            .width(60)
            .height(60)
            .objectFit(ImageFit.Contain)
            .fillColor(this.color)  // 更改SVG颜色
            .margin( { left : 2 } )

          // 数字编号
          Row() {
            Text(`${this.lineNumber.padStart(2, '0')}`)
              .fontSize(12)
              .fontColor(this.color)
              .textAlign(TextAlign.Center)
              .margin( { left : 1 , right : 12 } )
            Text(`${this.stationNumber.padStart(2, '0')}`)
              .fontSize(12)
              .fontColor(this.color)
              .textAlign(TextAlign.Center)
          }
        }
        .width(60)
        .height(60)
      }
    }
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
    ['犀浦', '天河路', '百草路', '金周路', '金科北路', '迎宾大道', '茶店子客运站', '羊犀立交', '一品天下', '蜀汉路东',
     '白果林', '中医大省医院', '通惠门', '人民公园', '天府广场', '春熙路', '东门大桥', '牛王庙', '牛市口', '东大路',
     '塔子山公园', '成都东客站', '成渝立交', '惠王陵', '洪河', '成都行政学院', '大面铺', '连山坡', '界牌', '书房',
     '龙平路', '龙泉驿'],
    // 3号线站点
    ['成都医学院', '石油大学', '钟楼', '马超西路', '团结新区', '锦水河', '三河场', '金华寺东路', '植物园', '军区总医院',
     '熊猫大道', '动物园', '昭觉寺南路', '驷马桥', '李家沱', '前锋路', '红星桥', '市二医院', '春熙路', '新南门',
     '磨子桥', '省体育馆', '衣冠庙', '高升桥', '红牌楼', '太平园', '川藏立交, '武侯立交', '武青南路', '双凤桥',
     '龙桥路', '航都大街', '迎春桥', '东升', '双流广场', '三里坝', '双流西站'],
    // 4号线站点
    ['万盛', '杨柳河', '凤溪河', '南熏大道', '光华公园', '非遗博览园', '蔡桥', '中坝', '马厂坝', '中医大省医院', '宽窄巷子',
     '西月城街', '太升南路', '市二医院', '玉双路', '双桥路', '万年场', '槐树店', '保和', '来龙', '十陵', '东林',
     '祥和', '西河'],
    // 5号线站点
    ['华桂路', '柏水场', '廖家湾', '北部商贸城', '幸福桥', '九道堰', '杜家碾', '大丰', '石犀公园', '皇花园',
     '陆家桥', '泉水路', '洞子口', '福宁路', '五块石', '赛云台', '北站西二路', '西北桥', '花牌坊', '抚琴',
     '中医大省医院', '青羊宫', '省骨科医院', '高升桥', '科园', '九兴大道', '神仙树', '石羊立交', '市一医院',
     '交子大道', '锦城大道', '锦城湖', '大源', '民乐', '骑龙', '警官学院', '二江寺', '南湖立交', '怡心湖',
     '龙马路', '回龙'],
    // 6号线站点
    ['望丛祠', '檬梓', '尚锦路', '安靖', '轻工职业技术学院', '纺织高等专科学校', '郫都校区', '西区大道', '犀浦',
     '地铁车辆段', '府通路', '蜀汉路', '沙湾', '梁家巷', '建设北路', '前锋路', '高笋塘', '八里庄', '列五中学',
     '动物园', '龙湖三千集', '万象城', '理工大学', '上东阳光', '沙河', '琉三路', '琉新路', '麓山大道', '陆肖',
     '生物城', '秦皇寺', '牧华路', '双华路', '公兴', '花源', '花桥', '新兴', '瓦窑滩', '明光', '白佛桥', '九江北',
     '兰家沟'],
    // 7号线站点（环线）
    ['火车北站', '驷马桥', '八里小区', '东区医院', '二仙桥', '成都理工', '成华大道', '崔家店', '万年场', '建材南路',
     '成都东客站', '沙河铺', '狮子山', '川师', '琉璃场', '科华南路', '火车南站', '太平园', '龙爪堰', '东坡路',
     '机头桥', '机投桥', '武青南路', '簇桥', '华兴', '太平寺', '应龙', '金花', '双流机场1航站楼', '双流机场2航站楼',
     '双流西', '应天寺', '黄水', '花源', '新津', '花桥', '五津', '儒林路', '刘家碾', '新平'],
    // 8号线站点
    ['龙港', '龙潭寺', '同乐', '白莲池', '地铁学院', '荆竹坝', '十里店', '杉板桥', '跳蹬河', '万年场', '双桥路',
     '东大路', '东光', '倪家桥', '桐梓林', '火车南站', '永丰', '九兴大道', '高朋大道', '顺江', '三瓦窑', '石羊场',
     '金融城东', '心岛', '孵化园', '锦城大道', '三元', '太平寺', '华兴', '簇桥', '武青南路', '机投桥', '培风',
     '成都西站', '黄田坝'],
    // 9号线站点
    ['黄田坝', '培风', '机投桥', '武青南路', '簇桥', '华兴', '太平寺', '三元', '锦城大道', '心岛', '金融城东'],
    // 10号线站点
    ['武侯祠', '红牌楼', '浆洗街', '太平园', '簇锦', '华兴', '金花', '双流机场1航站楼', '双流机场2航站楼', '双流西',
     '应天寺', '黄水', '花源', '新津', '花桥', '五津', '儒林路', '刘家碾', '新平'],
    // 13号线站点
    ['龙安', '龙华寺', '三圣花乡', 幸福梅林', '娇子立交', '四川师大', '净居寺', '三官堂', 九眼桥', '新南门', '华西坝', '文翁石室',
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
     '天府机场3号4号航站楼（暂未开通）', '天府机场1号2号航站楼', '天府机场北']
     // 27号线站点
    ['石佛', '慈义', '兴城大道', '旃檀寺', '石门坎', '三圣寺', '范家巷', '鲤鱼湾', '赖家店',
     '韦家碾', '双水碾', '王贾桥', '洞子口', '沙河源', '新桥', '金府', '花照壁北', '金牛公园', '羊犀立交', '黄忠',
     '金沙滨河公园', '蜀鑫路']
    // 30号线站点
    ['双流机场2航站楼东（出闸换乘）', '寺圣', '星月', '光明', '谢家渡', '珠江路', '大同', '石羊东', '新园大道',
     '市一医院', '益州大道', '金融城北', '府城桥', '金石路', '棬子树', '锦逸', '娇子立交', '海桐街', '航天立交', '惠王陵',
     '玉石', '分水', '玉虹路', '龙泉驿火车站南']
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
        .height('110%')
        .width('27.8%')
        .backgroundColor('#F1F3F5')
        .scrollBar(BarState.Off)
        .margin({ top: 94 })

        List() {
          // 添加安全检查，确保stationData[currentClassify]存在
          ForEach(
            (this.stationData && this.stationData[this.currentClassify]) ? 
            this.stationData[this.currentClassify] : 
            [], 
            (stationName: string, index: number) => {
            ListItem() {
              Column() {
                Row() {
                  Text(stationName)
                    .fontSize(18)
                    .fontColor('#182431')
                    .margin({ left: 20 })
                  Blank()
                  // 添加地铁图标
                  MetroIcon({
                    lineNumber: this.getClassifyName(this.currentClassify),
                    stationNumber: (index + 1).toString(),
                    color: this.currentClassify === 0 ? '#380096' :
                           this.currentClassify === 1 ? '#FA633B' :
                           this.currentClassify === 2 ? '#D6026B' :
                           this.currentClassify === 3 ? '#00AF60' :
                           this.currentClassify === 4 ? '#8E3981' :
                           this.currentClassify === 5 ? '#8A7530' :
                           this.currentClassify === 6 ? '#72D1DD' :
                           this.currentClassify === 7 ? '#9AC316' :
                           this.currentClassify === 8 ? '#E9AD00' :
                           this.currentClassify === 9 ? '#0750A3' :
                           this.currentClassify === 10 ? '#B2A222' :
                           this.currentClassify === 11 ? '#8CCA9E' :
                           this.currentClassify === 12 ? '#0B6267' :
                           this.currentClassify === 13 ? '#9C9ECE' :
                           this.currentClassify === 14 ? '#8FC31F' :
                           this.currentClassify === 15 ? '#E3718E' :
                           '#838382'
                  })
                  .margin({ right: 20 })
                }
                .height(60)
                .alignItems(VerticalAlign.Center)
                .backgroundColor('#FFFFFF')
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
        .scrollBar(BarState.Off)
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