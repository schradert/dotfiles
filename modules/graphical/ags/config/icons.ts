import { Gtk } from "astal/gtk3"


export const icons = {
    fallback: {
        applications: "application-x-executable",
    },
    applications: {

    },
}

export function lookupIcon(name?: string, size: number = 16) {
    if (!name) return null
    return Gtk.IconTheme.get_default().lookup_icon(name, size, Gtk.IconLookupFlags.USE_BUILTIN)
}
