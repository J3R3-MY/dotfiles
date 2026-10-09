pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../common"

// Notification daemon. Only one process can own org.freedesktop.Notifications,
// so the launcher script starts this *instead of* dunst; if the shell isn't
// running, dunst is started as before.
Singleton {
    id: root

    // Toasts currently on screen (subset of history)
    property var popups: []
    readonly property var history: server.trackedNotifications.values
    readonly property int count: history.length

    function dismiss(n) { n.dismiss(); }
    function clearAll() { for (const n of history.slice()) n.dismiss(); }
    function hidePopup(n) { root.popups = root.popups.filter(p => p !== n); }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.hidePopup(n));
            if (!Fluid.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups).slice(0, 5);
        }
    }
}
