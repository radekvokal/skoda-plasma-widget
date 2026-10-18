import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configPage

    property alias cfg_vin: vinField.text
    property alias cfg_apiKey: apiKeyField.text
    property alias cfg_updateIntervalMinutes: intervalSpinBox.value
    property int cfg_backgroundOpacity

    TextField {
        id: vinField
        Kirigami.FormData.label: i18n("VIN:")
        placeholderText: "e.g. TMBLM9NS6L8043618"
    }

    TextField {
        id: apiKeyField
        Kirigami.FormData.label: i18n("API Key:")
        placeholderText: "e.g. msk_..."
        echoMode: TextInput.Password
    }

    SpinBox {
        id: intervalSpinBox
        Kirigami.FormData.label: i18n("Update interval (minutes):")
        from: 1
        to: 120
        stepSize: 1
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Background opacity:")
        spacing: Kirigami.Units.smallSpacing

        Slider {
            id: opacitySlider
            from: 0
            to: 100
            stepSize: 1
            value: cfg_backgroundOpacity
            onMoved: cfg_backgroundOpacity = Math.round(value)
            Layout.fillWidth: true
        }

        Label {
            text: Math.round(opacitySlider.value) + "%"
            Layout.preferredWidth: 40
        }
    }
}
