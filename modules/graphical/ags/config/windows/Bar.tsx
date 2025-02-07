import { Variable, GLib, bind } from "astal"
import { App, Astal, Gdk, Gtk } from "astal/gtk3"
import { ButtonProps } from "astal/gtk3/widget"
import { exec } from "astal/process"
import Hyprland from "gi://AstalHyprland"
import Wp from "gi://AstalWp"
import Tray from "gi://AstalTray"

import { wallpapers } from "../store"
import { icons, lookupIcon } from "../icons"

function SysTray() {
    const tray = Tray.get_default()
    const filled = tray.get_items().length > 0
    const setup = (self) => self.hook(tray, "notify::items", () => {
        if (filled) {
            self.reveal_child = true
            self.visible = true
        } else {
            self.reveal_child = false;
            setTimeout(() => self.visible = false, 300)
        }
    })
    return <revealer
        visible={filled}
        revealChild={filled}
        transitionType={Gtk.RevealerTransitionType.SLIDE_LEFT}
        transitionDuration={300}
        setup={setup}>
        <BarButton className="tray">
            <box spacing={4} hexpand={false} valign={Gtk.Align.CENTER}>
                {bind(tray, "items").as(items => items
                    .filter(item => item.iconName)
                    .map(item => {
                        if (item.iconThemePath) App.add_icons(item.iconThemePath)
                        const menu = item.create_menu()
                        return <button
                            className="tray__item"
                            tooltipMarkup={bind(item, "tooltipMarkup")}
                            onDestroy={() => menu?.destroy()}
                            onClickRelease={(self, event) => event.button === 3 && menu?.popup_at_widget(self, Gdk.Gravity.NORTH, Gdk.Gravity.SOUTH, null)}>
                            <icon gIcon={bind(item, "gicon")} />
                        </button>
                    })
                )}
            </box>
        </BarButton>
    </revealer>
}

function Volume() {
    const speaker = Wp.get_default()?.audio.defaultSpeaker!
    return <box>
        <circularprogress className="circular" rounded startAt={0.75} value={bind(speaker, "volume")}>
            <icon size={12} icon={bind(speaker, "volumeIcon")} />
        </circularprogress>
    </box>
}

function Workspaces() {
    const hypr = Hyprland.get_default()
    // TODO use workspace icons
    // TODO shoiuld I filter out workspaces that have no active windows?
    return <BarButton>
        <box spacing={8}>
            {bind(hypr, "workspaces").as(wss => wss
                .sort((a, b) => a.id - b.id)
                .map(ws => <button
                    valign={Gtk.Align.CENTER}
                    className={bind(hypr, "focusedWorkspace").as(fw => ws === fw ? "focused" : "")}
                    onClicked={() => ws.focus()}>
                    {ws.id}
                </button>)
            )}
        </box>
    </BarButton>
}

// TODO how can I use the client icon instead? maybe the number at the very least
function FocusedClient() {
    const focused = bind(Hyprland.get_default(), "focusedClient")
    const icon = focused.as(focused => {
        if (!focused) return icons.fallback.applications
        const cls = focused.class
        return icons.applications[cls] ?? lookupIcon(cls)
            ? cls
            : icons.fallback.applications
    })
    const title = focused.as(focused => !focused ? "" : focused.title.toString())
    return <revealer
        transitionType={Gtk.RevealerTransitionType.CROSSFADE}
        transitionDuration={300}
        revealChild={focused.as(Boolean)}>
        <BarButton className="focused">
            <box spacing={8}>
                <icon icon={icon} />
                <label label={title} truncate maxWidthChars={24} />
            </box>
        </BarButton>
    </revealer>
}

// TODO toggle a calendar
function DateTime({format = "%H:%M | %a, %b %e"}) {
    const time = Variable("").poll(1000, () => GLib.DateTime.new_now_local().format(format)!)
    return <BarButton className="time">
        <label onDestroy={() => time.drop()} label={time()} />
    </BarButton>
}

function CpuMem() {
    const cpu = Variable(0, {poll: [5000, `echo "$[100-$(vmstat 1 2 | tail -1 | awk '{print $15}')]"`]})
    const mem = Variable(0, {poll: [5000, `printf "%.0f\n" $(free -m | grep Mem | awk '{print (1 - $7 / $2) * 100}')`]})
    return <box className="cpuMem" onDestroy={() => (cpu.drop(), mem.drop())}>
        <circularprogress className="circular" rounded startAt={0.75} value={mem(m => m / 100)}>
            <icon size={10} icon="cpu" />
        </circularprogress>
        <circularprogress className="circular" rounded startAt={0.75} value={mem(m => m / 100)}>
            <icon size={11} icon="memory" />
        </circularprogress>
    </box>
}

// TODO fix this being really slow
function OpenWallpaper({ monitor }: { monitor: Hyprland.Monitor; }) {
    function onClicked() {
        wallpapers.set(exec("theme --list").split("\n").filter(x => x !== ""))
        App.get_window(`wallpapers-${monitor.get_id()}`)?.show()
    }
    return <button onClicked={onClicked}><icon icon="starred" /></button>
}

type BarButtonProps = ButtonProps & { child?: JSX.Element; }
function BarButton({ className, child, ...props }: BarButtonProps) {
    return <button
           className={`bar__button ${className}`}
           valign={Gtk.Align.Center}
           {...props}>
        {child}
    </button>
}

function KeyboardLanguage() {
    const hyprland = Hyprland.get_default()
    const languages = {
      English: "en",
      Portuguese: "pt",
      "?": "?",
    }
    function setup(self) {
        self.hook(hyprland, "keyboard-layout", (_, keyboard, layout) => keyboard && (self.shown = languages[layout]))
    }
    return <BarButton className="bar__keyboard">
        <stack
            transitionType={Gtk.StackTransitionType.SLIDE_UP_DOWN}
            halign={Gtk.Align.Center}
            hexpand
            setup={setup}>
            {Object.values(languages).map(initial => <label name={initial} label={initial} />)}
        </stack>
    </BarButton>
}

// TODO designated hyprland workspaces for specific applications
// TODO bluetooth manager
// TODO tooltips for everything
// TODO MPRIS/MPD, click to open meta music player
// TODO basic day calendar
// TODO overview widget integrated with calendars (opens calendar tool)
// TODO teemperature
// TODO network speed, active download & upload rate
// TODO weather


export default function Bar({ monitor, gdkMonitor }: { monitor: Hyprland.Monitor; gdkMonitor: Gdk.Monitor; }) {
    const { BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor
    // TODO add media somehow... maybe expand a widget running a basic music player (would I need kitty?)
    return <window
        name={`bar-${monitor.get_id()}`}
        application={App}
        className="bar"
        namespace="bar"
        gdkmonitor={gdkMonitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={BOTTOM | LEFT | RIGHT}
        visible={false}
        vexpand>
        <box valign={Gtk.Align.CENTER}>
            <box halign={Gtk.Align.START} spacing={8}>
                <Workspaces />
                <FocusedClient />
            </box>
            <box spacing={8}>
                <DateTime />
            </box>
            <box halign={Gtk.Align.END} spacing={8}>
                <KeyboardLanguage />
                <Volume />
                <SysTray />
                <CpuMem />
            </box>
        </box>
    </window>
}
