import QtQuick 2.1
import QtWebSockets 1.0

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0

import "../code/script.js" as Logic

Item {
    id: mainItem

    property var logic: Logic
    property var badgeText: '0'

    ListModel {
        id: sessionModel
    }

    WebSocket {
        id: socket
        url: 'ws://' + Logic.getHost() + '/:/websockets/notifications/'
        onTextMessageReceived: Logic.onWsMessage(message)
        onStatusChanged: Logic.onWsStatusChange(socket)
        active: true
    }

    Timer {
        id: wsReconnectTimer
        interval: 5000
        onTriggered: {
            socket.active = true;
        }
    }

    SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }

    Plasmoid.compactRepresentation: CompactRepresentation {}
    Plasmoid.fullRepresentation: FullRepresentation {}

    Connections {
        target: theme
        onThemeChanged: {
            myPalette.colorGroup = SystemPalette.Active;
        }
    }

    Component.onCompleted: {
        socket.active = true;
        plasmoid.status = PlasmaCore.Types.PassiveStatus;
    }
}
