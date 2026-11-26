import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The bar button for Personal Agents Drawer. The drawer itself is Hyprland +
// Chromium (see README); this only toggles it through the launcher.
BarWidget {
  id: root
  moduleName: "io.github.caiomsantos95.personal-agents-drawer"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "◆"
    slotSize: Style.bar.statusSlot
    tooltipText: strings.t("tooltip")
    onPressed: function(b) {
      if (root.bar) root.bar.run("agents-drawer toggle")
    }
  }
}
