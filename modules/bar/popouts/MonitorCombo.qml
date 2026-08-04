import QtQuick
import QtQuick.Controls

ComboBox {
    id: combo
    width: 220
    height: 28

    property string placeholder: ""
    property var display: function (modelData) {
        return modelData.name;
    }
    signal popupOpened()
    signal popupClosed()

    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 13

    contentItem: Text {
        text: combo.currentIndex >= 0 && combo.model && combo.currentIndex < combo.model.length ? combo.display(combo.model[combo.currentIndex]) : combo.placeholder
        color: "#eeeeee"
        font: combo.font
        verticalAlignment: Text.AlignVCenter
        leftPadding: 8
        elide: Text.ElideRight
    }

    background: Rectangle {
        color: "#1e1f20"
        radius: 7
        border.color: "#3a3a3a"
        border.width: 1
    }

    popup: Popup {
        y: combo.height + 4
        width: combo.width
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        padding: 4

        onOpened: combo.popupOpened()
        onClosed: combo.popupClosed()

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: combo.popup.visible ? combo.delegateModel : null

            ScrollIndicator.vertical: ScrollIndicator {}
        }

        background: Rectangle {
            color: "#1e1f20"
            radius: 7
            border.color: "#3a3a3a"
            border.width: 1
        }
    }

    delegate: ItemDelegate {
        id: del
        required property var modelData
        required property int index

        width: combo.width
        contentItem: Text {
            text: combo.display(del.modelData)
            color: "#eeeeee"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            leftPadding: 8
        }
        highlighted: combo.highlightedIndex === del.index
        background: Rectangle {
            color: del.highlighted ? "#2a2a2a" : "transparent"
        }
    }
}
