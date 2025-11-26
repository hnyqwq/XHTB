import { initSideData } from './Metro/TabViewModel';
import { ClassifyModel } from './Metro/TabItem';

import router from '@ohos.router';

// 定义线路信息接口
interface LineInfo {
  lineNumber: string;
  stationNumber: string;
  color: string;
}

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
              .fontSize(6)
              .fontColor(info.color)
              .textAlign(TextAlign.Center)
              .margin({ left: 1, right: 4 })
            Text(`${info.stationNumber.padStart(2, '0')}`)
              .fontSize(6)
              .fontColor(info.color)
              .textAlign(TextAlign.Center)
          }
        }
        .width(30)
        .height(30)
      }, (info: LineInfo) => JSON.stringify(info))
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
                  Text(stationName)
                    .fontSize(16)
                    .fontColor('#182431')
                    .margin({ left: 20 })
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