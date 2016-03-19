import QtQuick 2.1
import org.kde.plasma.core 2.0 as PlasmaCore

Item {
    id: cpt

    function getColoredIcon(color) {
        return 'data:image/svg+xml;utf8,<svg ' +
               'xmlns="http://www.w3.org/2000/svg" width="32" height="32" ' +
               'viewBox="0 0 32 32"><path ' +
               'd="m9.5 4.4 6.8 11.8-6.6 11.5 6.2 0L22.5 16.1 15.7 4.4Z" ' +
               'style="fill:' + String(color).replace('#', '%23') +
               ';"/></svg>';
    }

    Image {
        id: icon
        fillMode: Image.PreserveAspectFit
        smooth: false
        anchors.fill: parent
        sourceSize.height: this.height
        sourceSize.width: this.width
        source: getColoredIcon(myPalette.text)

        Rectangle {
            id: bubble
            width: parent.height * 0.5
            height: width
            color: myPalette.highlight
            visible: badgeText !== '0'
            radius: width * 0.5
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            Text {
                id: badge
                color: myPalette.highlightedText
                text: badgeText
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: parent.height * 0.6
                font.bold: true
            }
        }
    }
}
