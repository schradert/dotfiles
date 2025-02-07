import { App, Gdk } from "astal/gtk3"
import { exec } from "astal/process"
import Hyprland from "gi://AstalHyprland"

import Bar from "./windows/Bar"
import Wallpapers from "./windows/Wallpapers"


const windows = {
  bars: new Map<Hyprland.Monitor, Gtk.Widget>(),
  wallpapers: new Map<Hyprland.Monitor, Gtk.Widget>(),
}

function getGdkMonitor(monitor: Hyprland.Monitor) {
  // TODO do I need get_x and get_y
  return Gdk.Display.get_default()?.get_monitor_at_point(monitor.x, monitor.y)
}

App.start({
  // TODO can I avoid running this if I just pass it?
  css: exec("rsass ./style.scss"),
  main() {
    Hyprland.get_default().get_monitors().forEach(monitor => {
      const gdkMonitor = getGdkMonitor(monitor)
      windows.bars.set(monitor, Bar({ monitor, gdkMonitor }))
      windows.wallpapers.set(monitor, Wallpapers({ monitor, gdkMonitor }))
    })
    // NOTE https://gitlab.gnome.org/GNOME/gtk/-/blob/gtk-3-24/gdk/gdkdisplay.c
    // TODO figure out how to go the reverse direction
    // App.connect("monitor-added", (_, gdkMonitor) => {
    //   const gdkMonitor = getGdkMonitor(monitor)
    //   windows.bars.set(monitor, Bar({ monitor, gdkMonitor }))
    //   windows.wallpapers.set(monitor, Wallpapers({ monitor, gdkMonitor }))
    // })
    // App.connect("monitor-removed", (_, gdkMonitor) => {
    //   windows.bars.get(monitor)?.destroy()
    //   windows.wallpapers.get(monitor)?.destroy()
    //   windows.bars.delete(monitor)
    //   windows.wallpapers.delete(monitor)
    // })
  },
  requestHandler(req, res) {
    App.eval(js).then(res).catch(res)
  },
})
