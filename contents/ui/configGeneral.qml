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
        }

        QtControls.Label {
            text: i18n("Server port")
        }
        QtControls.TextField {
            id: serverPortField
        }
    }
}
