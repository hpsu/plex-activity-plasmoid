import QtQuick 2.1
import QtWebSockets 1.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import org.kde.plasma.core 2.0 as PlasmaCore
import QtQuick.Controls.Styles.Plasma 2.0 as Styles
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0


Item {
    id: mainItem
    property string badgeText: '0'
    property var sessions: ({})

    ListModel {
        id: sessionModel
    }

    function getHost() {
        return Plasmoid.configuration.serverHost + ':' +
               Plasmoid.configuration.serverPort;
    }

    function zeroPad(num) {
        var str = String(num);
        if(str.length < 2) {
            str = '0' + str;
        }
        return str;
    }

    function formatEpisodeTitle(model) {
        var title = '';
        switch(model.type) {
            case 'track':
                title = [model.grandparentTitle,
                         model.parentTitle,
                         zeroPad(model.index) + '. ' +
                            model.title].join('\n');
                break;
            case 'episode':
                if(model.parentIndex) {
                    title += 'S' + zeroPad(model.parentIndex);
                }
                if(model.index) {
                    title += 'E' + zeroPad(model.index);
                }
                if(model.parentIndex &&
                   model.parentIndex === '0') {
                    title = 'Special ' + model.index;
                }
                title = model.grandparentTitle + ' - ' + title;
                title += '\n' + model.title;
                break;
            default:
                title = model.title;
                if(model.year) {
                    title += ' (' + model.year + ')';
                }
        }
        return title;
    }

    /**
     * Collect model data from child properties
     */
    function parseChildProperties(model) {
        model.userThumb = '';
        model.userName = 'anonymous';

        for(var i in model._children) {
            var childObject = model._children[i];
            switch(childObject._elementType) {
                case 'User':
                    model.userName = childObject.title;
                    if(childObject.thumb) {
                        model.userThumb = childObject.thumb;
                    }
                    break;
                case 'TranscodeSession':
                    model.transcodeProgress = childObject.progress / 100;
                    break;
                case 'Player':
                    if(childObject.state == 'paused') {
                        model.playStateIcon = 'media-playback-pause';
                    } else if(childObject.state == 'buffering') {
                        model.playStateIcon = 'buffering';
                    } else if(childObject.state == 'playing') {
                        model.playStateIcon = 'media-playback-start';
                    } else {
                        console.log('play status',
                                    childObject.state);
                    }
                    break;
            }
        }
    }

    /**
     * Remap listKeys. Items may have been moved around
     */
    function remapListIndicies() {
        for(var i = 0; i < sessionModel.count; i++) {
            var cont = sessionModel.get(i);
            if(sessions[cont.sessionKey]) {
                sessions[cont.sessionKey].listKey = i;
            }
        }
    }

    function processSessions(reply) {
        badgeText = String(reply._children.length);

        if (reply._children.length > 0) {
            plasmoid.status = PlasmaCore.Types.ActiveStatus;
        } else {
            plasmoid.status = PlasmaCore.Types.PassiveStatus;
        }
        var gc = [];
        remapListIndicies();

        for(var i in reply._children) {
            var cont = reply._children[i],
                dest = {};

            if(sessions[cont.sessionKey]) {
                cont.listKey = sessions[cont.sessionKey].listKey;
                dest = sessionModel.get(cont.listKey);
            }

            parseChildProperties(cont);
            if(!cont.viewOffset) {
                cont.viewOffset = '0';
            }
            var fields = ['thumb', 'viewOffset', 'duration',
                          'type', 'grandparentTitle',
                          'parentTitle', 'index', 'title',
                          'parentIndex', 'year', 'userName',
                          'userThumb', 'transcodeProgress',
                          'playStateIcon', 'sessionKey'];
            for(var j in fields) {
                dest[fields[j]] = cont[fields[j]];
            }
            if(!sessions[cont.sessionKey]) {
                cont.listKey = sessionModel.count;
                sessionModel.append(dest);
            }
            gc.push(cont.sessionKey);
            sessions[cont.sessionKey] = cont;
        }

        for(var j in sessions) {
            if(gc.indexOf(j) === -1) {
                sessionModel.remove(sessions[j].listKey);
                delete sessions[j];
            }
        }
    }


    function requestSessions() {
        var xhr = new XMLHttpRequest();
        xhr.timeout = 1000;

        xhr.onreadystatechange = function(){
            if (xhr.readyState == XMLHttpRequest.DONE) {
                processSessions(JSON.parse(xhr.responseText));
            }
        };

        xhr.open('POST', 'http://' + getHost() + '/status/sessions');
        xhr.setRequestHeader('Accept', 'application/json');

        try {
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
                            requestSessions();
                         } else if (socket.status == WebSocket.Closed) {
                            console.log('WS closed');
                         }
        active: false
    }
    SystemPalette { id: myPalette; colorGroup: SystemPalette.Active }

    Plasmoid.compactRepresentation: CompactRepresentation {}

    Plasmoid.fullRepresentation: PlasmaExtras.ScrollArea {
        ListView {
            model: sessionModel
            delegate: PlasmaComponents.ListItem {
                Column{
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    Image {
                        id: imgs
                        source: 'http://' + getHost() + model.thumb
                        asynchronous: true
                        width: parent.width
                        // Hard coded because aspect calculations hang
                        height: 225
                        fillMode: Image.PreserveAspectCrop
                    }
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        PlasmaCore.IconItem {
                            id: pticon
                            height: 10
                            width: 10
                            source: model.playStateIcon
                            visible: model.playStateIcon !== 'buffering'
                        }
                        BusyIndicator {
                            height: 10
                            width: 10
                            running: model.playStateIcon === 'buffering'
                            visible: model.playStateIcon === 'buffering'
                        }

                        Rectangle {
                            color: myPalette.dark
                            height: 10
                            Layout.fillWidth: true

                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                color: myPalette.mid
                                width: parent.width * model.transcodeProgress
                            }
                            Rectangle {
                                color: myPalette.highlight
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                width: parent.width * (model.viewOffset /
                                                       model.duration)
                            }
                        }
                    }
                    RowLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        Text {
                            text: formatEpisodeTitle(model)
                            color: myPalette.text
                            anchors.fill: parent
                            Layout.fillWidth: true
                        }
                        Text {
                            color: myPalette.text
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            text: model.userName
                        }
                        Image {
                            source: model.userThumb
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            visible: model.userThumb.length
                        }
                        PlasmaCore.IconItem {
                            source: 'user'
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            visible: !model.userThumb.length
                        }
                    }
                }
            }
        }
    }
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
