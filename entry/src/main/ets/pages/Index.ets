import { PcbDefectDetection } from "./PcbDefectDetection"
import { Settings } from "./Settings"
import { Test } from "../Test/Test"
import { DetectHistory } from "./DetectHistory"
@Entry
@Component
struct Index {
  private tabsController: TabsController = new TabsController();
  @State currentIndex: number = 0;

  @Builder
  tabBarBuilder(title: string, targetIndex: number, selectedIcon: Resource, unselectIcon: Resource) {
    Column() {
      Image(this.currentIndex === targetIndex ? selectedIcon : unselectIcon)
        .width(24)
        .height(24)
      Text(title)
        .fontFamily('HarmonyHeiTi-Medium')
        .fontSize(10)
        .fontColor(this.currentIndex === targetIndex ? '#0A59F7' : 'rgba(0,0,0,0.60)')
        .textAlign(TextAlign.Center)
        .lineHeight(14)
        .fontWeight(500)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.currentIndex = targetIndex;
      this.tabsController.changeIndex(targetIndex);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.tabsController }) {
      TabContent() {
        PcbDefectDetection()
      }
      .tabBar(this.tabBarBuilder('检测', 0, $r("app.media.circuit_board_icon_selected"),
        $r("app.media.circuit_board_icon_unselected")))

      TabContent() {
        DetectHistory()
      }
      .tabBar(this.tabBarBuilder('检测历史', 1, $r("app.media.clock_history_selected"),
        $r("app.media.clock_history")))

      TabContent() {
        Settings()
      }
      .tabBar(this.tabBarBuilder('设置', 2, $r("app.media.settings_icon_selected"),
        $r("app.media.settings_icon_unselected")))


    }
    .backgroundColor('#F1F3F5')
    // .padding({ top: 36, bottom: 28 })
  }
}