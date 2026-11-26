import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The bar button for Personal Agents Drawer. The drawer itself is Hyprland +
// Chromium, set up by Service.qml (see README); this only toggles it through
// the launcher.
BarWidget {
  id: root
  moduleName: "io.github.caiomsantos95.personal-agents-drawer"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  readonly property string launcher: decodeURIComponent(String(Qt.resolvedUrl("bin/agents-drawer")).replace(/^file:\/\//, ""))

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "◆"
    slotSize: Style.bar.statusSlot
    tooltipText: strings.t("tooltip")
    onPressed: function(b) {
      if (root.bar) root.bar.run("'" + root.launcher.replace(/'/g, "'\\''") + "' toggle")
    }
  }
}
