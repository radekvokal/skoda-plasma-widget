import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import QtLocation
import QtPositioning

PlasmoidItem {
    id: root

    width: 620
    height: 380
    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    property string vin: Plasmoid.configuration.vin
    property string apiKey: Plasmoid.configuration.apiKey
    property int updateIntervalMinutes: Plasmoid.configuration.updateIntervalMinutes

    property string vehicleName: ""
    property string licensePlate: ""
    property int mileage: 0
    property int fuelPercent: 0
    property int remainingRange: 0
    property int adBlueRange: 0
    property string carType: ""
    property string doorsStatus: ""
    property string windowsStatus: ""
    property string lockedStatus: ""
    property string trunkStatus: ""
    property string bonnetStatus: ""
    property string lightsStatus: ""
    property double lat: 0
    property double lon: 0
    property string address: ""
    property string lastUpdate: ""
    property bool loading: true
    property bool hasError: false
    property string errorText: ""

    Timer {
        id: refreshTimer
        interval: updateIntervalMinutes * 60 * 1000
        running: true
        repeat: true
        onTriggered: fetchVehicleData()
    }

    Component.onCompleted: fetchVehicleData()

    onVinChanged: fetchVehicleData()
    onApiKeyChanged: fetchVehicleData()

    function applyVehicleData(jsonString) {
        var data = JSON.parse(jsonString)
        var v = data.vehicle
        vehicleName = (v.name || "Unknown")
        licensePlate = v.licensePlate || ""
        mileage = v.odometer ? v.odometer.mileageInKm : 0
        if (v.fuelStatus) {
            carType = v.fuelStatus.carType || ""
            adBlueRange = v.fuelStatus.adBlueRange || 0
            if (v.fuelStatus.primaryEngineRange) {
                fuelPercent = v.fuelStatus.primaryEngineRange.currentFuelLevelInPercent || 0
                remainingRange = v.fuelStatus.primaryEngineRange.remainingRangeInKm || 0
            }
        }
        if (v.status) {
            var s = v.status.overall
            doorsStatus = s.doors || ""
            windowsStatus = s.windows || ""
            lockedStatus = s.locked || ""
            lightsStatus = s.lights || ""
            if (v.status.detail) {
                trunkStatus = v.status.detail.trunk || ""
                bonnetStatus = v.status.detail.bonnet || ""
            }
            lastUpdate = v.status.carCapturedTimestamp || ""
        }
        if (v.parkingPosition) {
            lat = v.parkingPosition.gpsCoordinates ? v.parkingPosition.gpsCoordinates.latitude : 0
            lon = v.parkingPosition.gpsCoordinates ? v.parkingPosition.gpsCoordinates.longitude : 0
            address = v.parkingPosition.formattedAddress || ""
        }
        hasError = false
    }

    function loadFromCache() {
        var cached = Plasmoid.configuration.cachedResponse
        if (cached) {
            try {
                applyVehicleData(cached)
                return true
            } catch (e) {}
        }
        return false
    }

    function fetchVehicleData() {
        if (!vin || !apiKey) {
            hasError = true
            errorText = "VIN or API Key not configured"
            loading = false
            return
        }

        if (loading && !vehicleName) {
            loadFromCache()
        }

        var xhr = new XMLHttpRequest()
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        applyVehicleData(xhr.responseText)
                        Plasmoid.configuration.cachedResponse = xhr.responseText
                    } catch (e) {
                        if (!loadFromCache()) {
                            hasError = true
                            errorText = "Failed to parse response"
                        }
                    }
                } else if (xhr.status === 429) {
                    if (!vehicleName) {
                        if (!loadFromCache()) {
                            hasError = true
                            errorText = "Rate limited — will retry at next interval"
                        }
                    }
                } else {
                    if (!vehicleName) {
                        if (!loadFromCache()) {
                            hasError = true
                            errorText = "API error: " + xhr.status
                        }
                    }
                }
                loading = false
            }
        }
        xhr.open("GET", "https://public.api.connect.skoda-auto.cz/api/v1/vehicles/" + vin)
        xhr.setRequestHeader("X-API-Key", apiKey)
        xhr.send()
    }

    function formatTimestamp(ts) {
        if (!ts) return ""
        var d = new Date(ts)
        return Qt.formatDateTime(d, "dd.MM.yyyy hh:mm")
    }

    function fuelColor(pct) {
        if (pct <= 15) return Kirigami.Theme.negativeTextColor
        if (pct <= 30) return Kirigami.Theme.neutralTextColor
        return Kirigami.Theme.positiveTextColor
    }

    fullRepresentation: Item {
        Layout.preferredWidth: 620
        Layout.preferredHeight: 380
        Layout.minimumWidth: 500
        Layout.minimumHeight: 320

        KSvg.FrameSvgItem {
            anchors.fill: parent
            imagePath: "widgets/background"
            opacity: Plasmoid.configuration.backgroundOpacity / 100
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.mediumSpacing
            spacing: Kirigami.Units.smallSpacing

            // Loading / error state
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: loading || hasError
                visible: active
                sourceComponent: Item {
                    anchors.fill: parent
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Kirigami.Units.mediumSpacing
                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            running: loading
                            visible: loading
                        }
                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: loading ? "Loading vehicle data..." : errorText
                            color: hasError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.textColor
                        }
                    }
                }
            }

            // Main content
            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                active: !loading && !hasError
                visible: active
                sourceComponent: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.mediumSpacing
                        Kirigami.Icon {
                            source: "car"
                            Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                        }
                        Label {
                            text: "Škoda " + vehicleName
                            font.bold: true
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.4
                        }
                        Label {
                            text: licensePlate
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.1
                            opacity: 0.7
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: formatTimestamp(lastUpdate)
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.85
                            opacity: 0.5
                        }
                        ToolButton {
                            icon.name: "view-refresh"
                            onClicked: fetchVehicleData()
                            ToolTip.text: "Refresh"
                            ToolTip.visible: hovered
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true }

                    // Body: info + map
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Kirigami.Units.mediumSpacing

                        // Left: vehicle info
                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 260
                            spacing: Kirigami.Units.smallSpacing

                            // Fuel
                            GridLayout {
                                columns: 2
                                columnSpacing: Kirigami.Units.mediumSpacing
                                rowSpacing: Kirigami.Units.smallSpacing

                                Label { text: "Mileage"; opacity: 0.6 }
                                Label { text: Number(mileage).toLocaleString() + " km"; font.bold: true }

                                Label { text: "Fuel Level"; opacity: 0.6 }
                                RowLayout {
                                    spacing: Kirigami.Units.smallSpacing
                                    Rectangle {
                                        width: 80
                                        height: 14
                                        radius: 3
                                        color: Kirigami.Theme.backgroundColor
                                        border.color: Kirigami.Theme.textColor
                                        border.width: 1
                                        opacity: 0.3
                                        Rectangle {
                                            width: parent.width * fuelPercent / 100
                                            height: parent.height
                                            radius: 3
                                            color: fuelColor(fuelPercent)
                                        }
                                    }
                                    Label {
                                        text: fuelPercent + "%"
                                        font.bold: true
                                        color: fuelColor(fuelPercent)
                                    }
                                }

                                Label { text: "Range"; opacity: 0.6 }
                                Label { text: remainingRange + " km"; font.bold: true }

                                Label { text: "AdBlue Range"; opacity: 0.6 }
                                Label { text: Number(adBlueRange).toLocaleString() + " km"; font.bold: true }

                                Label { text: "Engine"; opacity: 0.6 }
                                Label { text: carType; font.bold: true }
                            }

                            Kirigami.Separator { Layout.fillWidth: true }

                            // Doors & security
                            Label {
                                text: "Security"
                                font.bold: true
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.05
                            }

                            GridLayout {
                                columns: 2
                                columnSpacing: Kirigami.Units.mediumSpacing
                                rowSpacing: Kirigami.Units.smallSpacing

                                Label { text: "Locked"; opacity: 0.6 }
                                RowLayout {
                                    spacing: 4
                                    Kirigami.Icon {
                                        source: lockedStatus === "YES" ? "object-locked" : "object-unlocked"
                                        Layout.preferredWidth: Kirigami.Units.iconSizes.small
                                        Layout.preferredHeight: Kirigami.Units.iconSizes.small
                                        color: lockedStatus === "YES" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                    }
                                    Label {
                                        text: lockedStatus === "YES" ? "Locked" : "Unlocked"
                                        color: lockedStatus === "YES" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                    }
                                }

                                Label { text: "Doors"; opacity: 0.6 }
                                Label {
                                    text: doorsStatus
                                    color: doorsStatus === "CLOSED" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                }

                                Label { text: "Windows"; opacity: 0.6 }
                                Label {
                                    text: windowsStatus
                                    color: windowsStatus === "CLOSED" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                }

                                Label { text: "Trunk"; opacity: 0.6 }
                                Label {
                                    text: trunkStatus
                                    color: trunkStatus === "CLOSED" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                }

                                Label { text: "Bonnet"; opacity: 0.6 }
                                Label {
                                    text: bonnetStatus
                                    color: bonnetStatus === "CLOSED" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.negativeTextColor
                                }

                                Label { text: "Lights"; opacity: 0.6 }
                                Label { text: lightsStatus }
                            }

                            Item { Layout.fillHeight: true }
                        }

                        Kirigami.Separator {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                        }

                        // Right: map
                        ColumnLayout {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            spacing: Kirigami.Units.smallSpacing

                            Label {
                                text: address
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                                opacity: 0.7
                            }

                            Map {
                                id: vehicleMap
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                plugin: Plugin {
                                    name: "osm"
                                    PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: "true" }
                                    PluginParameter { name: "osm.mapping.custom.host"; value: "https://tile.openstreetmap.org/" }
                                }

                                center: QtPositioning.coordinate(lat, lon)
                                zoomLevel: 15
                                activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

                                MapQuickItem {
                                    coordinate: QtPositioning.coordinate(lat, lon)
                                    anchorPoint.x: markerIcon.width / 2
                                    anchorPoint.y: markerIcon.height

                                    sourceItem: Kirigami.Icon {
                                        id: markerIcon
                                        source: "car"
                                        width: Kirigami.Units.iconSizes.large
                                        height: Kirigami.Units.iconSizes.large
                                        color: Kirigami.Theme.highlightColor
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onWheel: function(wheel) {
                                        if (wheel.angleDelta.y > 0)
                                            vehicleMap.zoomLevel = Math.min(vehicleMap.zoomLevel + 1, 19)
                                        else
                                            vehicleMap.zoomLevel = Math.max(vehicleMap.zoomLevel - 1, 2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    compactRepresentation: RowLayout {
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Icon {
            source: "car"
            Layout.preferredWidth: Kirigami.Units.iconSizes.small
            Layout.preferredHeight: Kirigami.Units.iconSizes.small
        }

        Label {
            text: loading ? "..." : (fuelPercent + "% · " + remainingRange + " km")
            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 0.9
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }
}
