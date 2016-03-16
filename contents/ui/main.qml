import QtQuick 2.0
import QtWebSockets 1.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

Item {
    id: mainItem
    property string badgeText: '0'

    ListModel {
        id: sessionModel
    }

    function getHost() {
        return Plasmoid.configuration.serverHost + ':' +
               Plasmoid.configuration.serverPort;
    }

    function requestSessions() {
        var xhr = new XMLHttpRequest();
        xhr.timeout = 1000;

        xhr.onreadystatechange = function(r){
            if (xhr.readyState == XMLHttpRequest.DONE) {
                var reply = JSON.parse(xhr.responseText);
                badgeText = String(reply._children.length);

                if (reply._children.length > 0) {
                    plasmoid.status = PlasmaCore.Types.ActiveStatus;
                } else {
                    plasmoid.status = PlasmaCore.Types.PassiveStatus;
                }
                sessionModel.clear();
                for(var i in reply._children) {
                    sessionModel.append(reply._children[i]);
                }
            }
        };

        xhr.open('POST', 'http://' + getHost() + '/status/sessions');
        xhr.setRequestHeader('Accept', 'application/json');

        try {
            console.log('XHR send');
            xhr.send();
        }
        catch (e){
            console.log('XHR send error');
        }
    }


    WebSocket {
        id: socket
        url: 'ws://' + getHost() + '/:/websockets/notifications/'
        onTextMessageReceived: {
            var data = JSON.parse(message);
            switch(data.type) {
                case 'playing':
                case 'transcodeSession.update':
                case 'transcodeSession.start':
                case 'transcodeSession.end':
                    requestSessions();
                    break;
                case 'backgroundProcessingQueue':
                case 'progress':
                case 'timeline':
                    break;
                default:
            }
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                            console.log('WS Error: ' + socket.errorString)
                         } else if (socket.status == WebSocket.Open) {
                            console.log('WS Connected');
                         } else if (socket.status == WebSocket.Closed) {
                            console.log('WS closed');
                         }
        active: false
    }

    Plasmoid.compactRepresentation: Image {
        id: envelopeImage
        fillMode: Image.PreserveAspectFit
        smooth: false
        anchors.fill: parent
        sourceSize.height: envelopeImage.height
        sourceSize.width: envelopeImage.width
        source: 'images/icon.svg'

        Rectangle {
            SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }
            width: envelopeImage.height * 0.5
            height: width
            color: myPalette.highlight
            visible: badgeText !== '0'
            radius: width * 0.5
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            Text {
                color: myPalette.highlightedText
                text: badgeText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: parent.height * 0.6
                font.bold: true
            }
        }
    }

    Plasmoid.fullRepresentation: PlasmaExtras.ScrollArea {
        anchors.fill: parent
        ListView {
            model: sessionModel
            delegate: PlasmaComponents.ListItem {
                Column{
                    spacing: 0
                    width: parent.width
                    Image {
                        source: 'http://' + getHost() + model.thumb
                        width: parent.width
                        height: Math.round(parent.width / 1.7777)
                        fillMode: Image.PreserveAspectCrop
                    }
                    ProgressBar {
                        value: model.viewOffset /
                               model.duration
                        anchors.left: parent.left
                        anchors.right: parent.right
                    }
                    Text {
                        color: '#fff'
                        anchors.left: parent.left
                        anchors.right: parent.right
                        text: model.title
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        socket.active = true;
        plasmoid.status = PlasmaCore.Types.PassiveStatus;
        requestSessions();
    }
}
