import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../common"

// One notification: app icon/image, summary, body, actions.
Rectangle {
    id: card

    property var notification
    signal close()

    readonly property bool critical: notification && notification.urgency === NotificationUrgency.Critical
    // Plain JS array copy of the actions list (a QList, which lacks find/filter)
    readonly property var actionList: {
        const out = [];
        const a = notification ? notification.actions : null;
        if (a) for (let i = 0; i < a.length; i++) out.push(a[i]);
        return out;
    }
    readonly property var extraActions: actionList.filter(a => a.identifier !== "default")
    readonly property string iconSource: {
        if (!notification) return "";
        // local images only: a remote one would be fetched (see body below)
        if (/^(\/|file:\/\/|image:\/\/)/.test(notification.image)) return notification.image;
        if (notification.appIcon) return notification.appIcon.startsWith("/") ? "file://" + notification.appIcon
                                                                               : Quickshell.iconPath(notification.appIcon, true);
        return "";
    }

    implicitHeight: content.implicitHeight + 24
    radius: 16
    color: hoverArea.containsMouse ? Theme.surfaceHi : Theme.surface
    border.width: critical ? 2 : 0
    border.color: Theme.urgent
    Behavior on color { ColorAnimation { duration: Anim.fast } }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        // Click = default action if the app offers one
        onClicked: {
            const def = card.actionList.find(a => a.identifier === "default");
            if (def) { def.invoke(); card.close(); }
        }
    }

    Row {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        ClippingRectangle {
            visible: card.iconSource.length > 0
            width: 40; height: 40; radius: 10
            color: "transparent"
            Image { anchors.fill: parent; source: card.iconSource; fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize.width: 80 }
        }

        Column {
            width: content.width - (card.iconSource.length > 0 ? 52 : 0) - 24
            spacing: 3

            Text {
                width: parent.width; elide: Text.ElideRight
                text: card.notification ? card.notification.appName : ""
                textFormat: Text.PlainText      // AutoText would render HTML (and fetch <img>)
                color: Theme.fgDim; font.family: Theme.font; font.pixelSize: Theme.fontSize - 4
            }
            Text {
                width: parent.width; elide: Text.ElideRight
                text: card.notification ? card.notification.summary : ""
                textFormat: Text.PlainText
                color: Theme.fg; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1; font.weight: Font.DemiBold
            }
            Text {
                width: parent.width
                visible: text.length > 0
                // images are dropped: an <img src="https://…"> would be fetched and could
                // tell the sender that (and from where) you read the notification
                text: card.notification ? card.notification.body.replace(/<img[^>]*>/gi, "") : ""
                textFormat: Text.StyledText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                color: Theme.fg; opacity: 0.85
                font.family: Theme.font; font.pixelSize: Theme.fontSize - 3
            }

            Row {
                spacing: 6
                topPadding: 4
                visible: card.extraActions.length > 0
                Repeater {
                    model: card.extraActions
                    Chip {
                        required property var modelData
                        text: modelData.text
                        onClicked: { modelData.invoke(); card.close(); }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        width: 22; height: 22; radius: 11
        opacity: hoverArea.containsMouse || xArea.containsMouse ? 1 : 0
        color: xArea.containsMouse ? Theme.urgent : Theme.surfaceHi
        Behavior on opacity { NumberAnimation { duration: Anim.fast } }
        Glyph { anchors.centerIn: parent; text: Icons.close; size: 11 }
        MouseArea { id: xArea; anchors.fill: parent; hoverEnabled: true; onClicked: card.close() }
    }
}
