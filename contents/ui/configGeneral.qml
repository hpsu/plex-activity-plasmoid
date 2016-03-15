import QtQuick 2.0
import QtQuick.Controls 1.0 as QtControls
import QtQuick.Layouts 1.1 as QtLayouts

Item {
    width: childrenRect.width
    height: childrenRect.height

    property alias cfg_serverHost: serverHostField.text
    property alias cfg_serverPort: serverPortField.text

    QtLayouts.GridLayout {
        columns: 2
        QtControls.Label {
            text: i18n("Server host")
        }
        QtControls.TextField {
            id: serverHostField
            text: i18n("Show application and system notifications")
        }

        QtControls.Label {
            text: i18n("Server port")
        }
        QtControls.TextField {
            id: serverPortField
            text: i18n("Track file transfers and other jobs")
        }
    }
}
