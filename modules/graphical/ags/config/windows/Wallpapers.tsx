import { App, Astal, Gdk } from "astal/gtk3"
import { exec } from "astal/process"
import Hyprland from "gi://AstalHyprland"

import { wallpapers } from "../store"


function WallpaperButton({ monitor, file }: {monitor: Hyprland.Monitor; file: string;}) {
    function onClicked() {
        App.get_window(`wallpapers-${monitor.get_id()}`)?.hide()
        exec(`theme ${file}`)
        App.reset_css()
        // TODO how can we make this dynamic to XDG_CONFIG_HOME. does it have to be deliberately set and passed from "wallpaper" script?
        App.apply_css(`${exec('echo "$XDG_CONFIG_HOME"')}/ags/style.scss`)
    }
    return <button onClicked={onClicked}>
        <icon size={100} icon={file} />
    </button>
}

export default function Wallpapers({ monitor, gdkMonitor }: { monitor: Hyprland.Monitor; gdkMonitor: Gdk.Monitor; }) {
    const { RIGHT, TOP, BOTTOM } = Astal.WindowAnchor
    return <window
        name={`wallpapers-${monitor.get_id()}`}
        application={App}
        className="wallpapers"
        gdkmonitor={gdkMonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={RIGHT | TOP | BOTTOM}
        visible={false}
        layer={Astal.Layer.OVERLAY}>
        <scrollable vscroll="always" hscroll="never">
            <box className="wallpaper">
                {wallpapers(files => files.map(file => <WallpaperButton monitor={monitor} file={file} />))}
            </box>
        </scrollable>
    </window>
}
