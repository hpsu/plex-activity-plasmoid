import QtQuick 2.1
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.2

import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras


Item {
    PlasmaExtras.Heading {
        width: parent.width
        level: 3
        opacity: 0.6
        text: 'Nothing is playing.'
        visible: badgeText === '0'
    }

    PlasmaExtras.ScrollArea {
        anchors.fill: parent
        ListView {
            model: sessionModel
            delegate: PlasmaComponents.ListItem {
                Column{
                    spacing: 0
                    anchors.left: parent.left
                    anchors.right: parent.right
                    Image {
                        id: imgs
                        source: 'http://' + logic.getHost() + model.thumb
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
                            text: logic.formatEpisodeTitle(model)
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
}
