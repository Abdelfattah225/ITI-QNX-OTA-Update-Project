import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls

ApplicationWindow {
    visible: true
    width: 780
    height: 720
    title: "OTA Hypervisor Manager"
    minimumWidth: 680
    minimumHeight: 620

    Material.theme: Material.Dark
    Material.accent: Material.Teal

    // UI State Properties
    property bool isTransferring: false
    property string localErrorMessage: ""

    // ─── Background ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b0f1e" }
            GradientStop { position: 0.5; color: "#0d1428" }
            GradientStop { position: 1.0; color: "#080c18" }
        }
    }

    // Soft radial ambient — top
    Rectangle {
        width: 500; height: 220
        x: (parent.width - width) / 2
        y: -80; radius: 250
        color: "#6c63ff"; opacity: 0.06
    }

    // Soft radial ambient — bottom
    Rectangle {
        width: 400; height: 180
        x: (parent.width - width) / 2
        y: parent.height - 80; radius: 200
        color: "#00c9b1"; opacity: 0.05
    }

    // ─── Top accent line ──────────────────────────────────────────────────────
    Rectangle {
        width: parent.width; height: 1
        color: "#1e2d4a"; z: 10
    }

    Rectangle {
        width: 180; height: 1
        anchors.horizontalCenter: parent.horizontalCenter
        z: 10
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "#6c63ff"     }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ─── Main layout ──────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: parent.width
            clip: true

            ColumnLayout {
                width: parent.parent.width
                spacing: 0

                // ── HEADER ────────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        // Orbital logo
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 56; height: 56

                            Rectangle {
                                anchors.fill: parent; radius: 28
                                color: "transparent"
                                border.color: "#6c63ff"
                                border.width: 1; opacity: 0.4
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 40; height: 40; radius: 20
                                color: "transparent"
                                border.color: "#6c63ff"
                                border.width: 1; opacity: 0.7
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10; height: 10; radius: 5
                                color: "#6c63ff"; opacity: 0.9
                            }

                            // Orbiting dot
                            Item {
                                anchors.centerIn: parent
                                width: 0; height: 0

                                Rectangle {
                                    width: 5; height: 5; radius: 3
                                    color: "#00c9b1"
                                    x: 24; y: -24
                                }

                                RotationAnimation on rotation {
                                    running: true
                                    loops: Animation.Infinite
                                    from: 0; to: 360
                                    duration: 5000
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "OTA Hypervisor Manager"
                            font.pixelSize: 24
                            font.weight: Font.Light
                            font.letterSpacing: 1.5
                            color: "#e8ecf8"
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 36; height: 1
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.5; color: "#6c63ff"     }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Abdelfattah Moawed"
                            font.pixelSize: 11
                            font.letterSpacing: 3
                            font.weight: Font.Light
                            color: "#6c63ff"
                            opacity: 0.9
                        }
                    }
                }

                // ── FORM CARD ─────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 40
                    Layout.rightMargin: 40
                    Layout.bottomMargin: 24
                    height: formColumn.implicitHeight + 48
                    radius: 14
                    color: "#0d1530"
                    border.color: "#1e2d50"
                    border.width: 1

                    // Card top glow
                    Rectangle {
                        width: parent.width - 2; height: 1
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.6
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.4; color: "#6c63ff"     }
                            GradientStop { position: 0.6; color: "#00c9b1"     }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    ColumnLayout {
                        id: formColumn
                        anchors {
                            left: parent.left; right: parent.right
                            top: parent.top;   topMargin: 28
                            leftMargin: 28;    rightMargin: 28
                        }
                        spacing: 18

                        // ── 01 Network ────────────────────────────────────────
                        FormSection { sectionTitle: "Network Target"; sectionIndex: "01" }

                        RowLayout {
                            spacing: 12; Layout.fillWidth: true

                            FormField {
                                id: ipField
                                hint: "Device IP Address"
                                icon: "IP"
                                Layout.fillWidth: true
                            }

                            FormField {
                                id: portField
                                hint: "Port"
                                value: "8080"
                                icon: "PT"
                                Layout.preferredWidth: 120
                            }
                        }

                        // ── 02 Image File ─────────────────────────────────────
                        FormSection { sectionTitle: "Image File"; sectionIndex: "02" }

                        RowLayout {
                            spacing: 12; Layout.fillWidth: true

                            FormField {
                                id: fileField
                                hint: "Root filesystem image path"
                                icon: "FS"
                                readOnly: true
                                Layout.fillWidth: true
                            }

                            // ── Browse button ─────────────────────────────────
                            Rectangle {
                                width: 110; height: 44; radius: 8
                                color: browseArea.pressed
                                       ? "#100a40"
                                       : browseArea.containsMouse
                                         ? "#1a1260"
                                         : "#140e50"
                                border.color: "#4a3fa0"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Browse"
                                    color: "#a89fef"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: browseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: fileDialog.open()
                                }

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }

                        // ── 03 Image Verification ─────────────────────────────
                        FormSection { sectionTitle: "Image Verification"; sectionIndex: "03" }

                        RowLayout {
                            spacing: 12; Layout.fillWidth: true

                            FormField {
                                id: uuidField
                                hint: "Image UUID"
                                icon: "ID"
                                Layout.fillWidth: true
                            }

                            // ── Generate button ───────────────────────────────
                            Rectangle {
                                width: 110; height: 44; radius: 8
                                color: genArea.pressed
                                       ? "#061a14"
                                       : genArea.containsMouse
                                         ? "#0a2820"
                                         : "#082018"
                                border.color: "#1e6050"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Generate"
                                    color: "#00c9b1"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: genArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: uuidField.value = generateUUID()
                                }

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }

                        // UUID validation badge
                        Item {
                            Layout.fillWidth: true
                            height: uuidField.value !== "" ? 20 : 0
                            clip: true
                            Behavior on height { NumberAnimation { duration: 200 } }

                            RowLayout {
                                spacing: 6
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: isValidUUID(uuidField.value)
                                           ? "#00c9b1" : "#f06292"
                                }

                                Text {
                                    text: isValidUUID(uuidField.value)
                                          ? "Valid UUID  ·  RFC 4122"
                                          : "Invalid  ·  xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                                    color: isValidUUID(uuidField.value)
                                           ? "#00c9b1" : "#f06292"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // Checksum row
                        RowLayout {
                            spacing: 12; Layout.fillWidth: true

                            FormField {
                                id: hashField
                                hint: "SHA-256 checksum"
                                icon: "CS"
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 110; height: 44; radius: 8
                                color: "#090d1e"
                                border.color: "#1e2d50"
                                border.width: 1

                                ComboBox {
                                    id: hashType
                                    anchors.fill: parent
                                    model: ["SHA-256", "SHA-512", "MD5"]
                                    background: Rectangle { color: "transparent" }
                                    contentItem: Text {
                                        leftPadding: 10
                                        text: hashType.displayText
                                        color: "#6a7a9a"
                                        font.pixelSize: 11
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    popup.background: Rectangle {
                                        color: "#0d1530"
                                        border.color: "#1e2d50"
                                        radius: 8
                                    }
                                }
                            }
                        }

                        // ── Divider ───────────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            height: 1; color: "#1a2540"
                            Layout.topMargin: 4
                        }

                        // ── Progress ──────────────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "Transfer Progress"
                                    font.pixelSize: 11
                                    font.weight: Font.Light
                                    color: "#6a7a9a"
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: Math.round(progressBar.value) + "%"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    color: "#6c63ff"
                                }
                            }

                            // Track
                            Rectangle {
                                Layout.fillWidth: true
                                height: 5; radius: 3
                                color: "#080c1a"
                                border.color: "#1a2540"
                                border.width: 1

                                Rectangle {
                                    width: parent.width * (progressBar.value / 100)
                                    height: parent.height; radius: 3
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#6c63ff" }
                                        GradientStop { position: 1.0; color: "#00c9b1" }
                                    }
                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 400
                                            easing.type: Easing.OutCubic
                                        }
                                    }
                                }
                            }

                            // Hidden backend bind target
                            ProgressBar {
                                id: progressBar
                                visible: false
                                from: 0; to: 100
                                value: backend.progress
                            }
                        }

                        // ── Status bar ────────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            height: 42; radius: 8
                            color: "#080c1a"
                            border.color: "#1a2540"
                            border.width: 1

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 14; rightMargin: 14
                                }
                                spacing: 10

                                Rectangle {
                                    id: pulseDot
                                    width: 6; height: 6; radius: 3
                                    color: "#2a3a5a"

                                    SequentialAnimation {
                                        id: dotBlink
                                        running: false
                                        loops: Animation.Infinite
                                        ColorAnimation {
                                            target: pulseDot
                                            property: "color"
                                            to: "#6c63ff"; duration: 600
                                        }
                                        ColorAnimation {
                                            target: pulseDot
                                            property: "color"
                                            to: "#2a3a5a"; duration: 600
                                        }
                                    }
                                }

                                Text {
                                    id: statusText
                                    // BINDING FIX: Safely switch between local errors and C++ status
                                    text: localErrorMessage !== "" ? localErrorMessage : backend.statusMessage
                                    color: "#5a6a8a"
                                    font.pixelSize: 12
                                    font.weight: Font.Light
                                    Layout.fillWidth: true
                                }

                                Text {
                                    id: etaLabel
                                    text: ""
                                    color: "#6c63ff"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        // ── Action buttons ────────────────────────────────────
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            Layout.topMargin: 4
                            Layout.bottomMargin: 8

                            // Reset ───────────────────────────────────────────
                            Rectangle {
                                width: 120; height: 46; radius: 8
                                color: resetMa.pressed
                                       ? "#1e0a14"
                                       : resetMa.containsMouse
                                         ? "#260d18"
                                         : "#1a0810"
                                border.color: "#5a1a30"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset"
                                    color: "#f06292"
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: resetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: resetAll()
                                }

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            // Deploy ──────────────────────────────────────────
                            Rectangle {
                                Layout.fillWidth: true
                                height: 46; radius: 8
                                opacity: isTransferring ? 0.5 : 1.0 // Fades out during transfer
                                color: deployMa.containsMouse ? "#1a1060" : "#120a50"
                                border.color: "#4a3fa0"
                                border.width: 1

                                // Gradient overlay
                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop {
                                            position: 0.0
                                            color: deployMa.containsMouse
                                                   ? "#4a42cc" : "#3d36b0"
                                        }
                                        GradientStop {
                                            position: 1.0
                                            color: deployMa.containsMouse
                                                   ? "#00c9b1" : "#00a896"
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Deploy Update"
                                    color: "white"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    font.letterSpacing: 0.8
                                    z: 1
                                }

                                MouseArea {
                                    id: deployMa
                                    anchors.fill: parent
                                    hoverEnabled: !isTransferring
                                    cursorShape: isTransferring ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !isTransferring // PREVENTS CLICKS WHILE TRANSFERRING
                                    onClicked: startDeploy()
                                }
                            }
                        }
                    }
                }

                // ── FOOTER — perfectly centered ───────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 28
                    spacing: 6

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: 50; height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: "#2a2060"     }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Abdelfattah Moawed"
                        font.pixelSize: 12
                        font.letterSpacing: 3
                        font.weight: Font.Light
                        color: "#3d3680"
                    }
                }
            }
        }
    }

    // ─── FileDialog ───────────────────────────────────────────────────────────
    FileDialog {
        id: fileDialog
        title: "Select root filesystem image"
        nameFilters: ["Disk Images (*.ext4 *.ext3* .img *.bin *.tar.gz)", "All Files (*)"]
        onAccepted: fileField.value = fileDialog.selectedFile
    }

    // ─── Timers & Connections ─────────────────────────────────────────────────
    Timer {
        id: colorResetTimer
        interval: 2200
        onTriggered: {
            statusText.color = "#5a6a8a"
            localErrorMessage = "" // Restores C++ binding view
        }
    }

    // Watch C++ backend to know when transfer completes
    Connections {
        target: backend
        function onStatusMessageChanged() {
            if (backend.statusMessage === "Deployment complete" || backend.statusMessage.includes("Error")) {
                isTransferring = false
                dotBlink.running = false
                if (backend.statusMessage === "Deployment complete") {
                    statusText.color = "#00c9b1" // Success color
                    pulseDot.color = "#00c9b1"
                } else {
                    statusText.color = "#f06292" // Error color
                    pulseDot.color = "#f06292"
                }
            }
        }
    }

    // ─── Logic ────────────────────────────────────────────────────────────────
    function startDeploy() {
        if (fileField.value === "" || ipField.value === "") {
            localErrorMessage  = "Please fill in all required fields"
            statusText.color = "#f06292"
            colorResetTimer.start()
            return
        }

        isTransferring = true
        localErrorMessage = "" // Clear local errors
        dotBlink.running  = true
        statusText.color  = "#5a6a8a"
        etaLabel.text     = ""

        backend.startTransfer(ipField.value, parseInt(portField.value),
                              fileField.value, uuidField.value, hashField.value)
    }

    function resetAll() {
        // If we are currently transferring, tell C++ to kill the connection!
        if (isTransferring) {
            backend.cancelTransfer()
            isTransferring = false
        }

        dotBlink.running  = false
        pulseDot.color    = "#2a3a5a"
        statusText.color  = "#5a6a8a"
        localErrorMessage = ""
        etaLabel.text     = ""
    }

    function generateUUID() {
        var h = "0123456789abcdef"
        var s = []
        for (var i = 0; i < 36; i++) {
            if ([8, 13, 18, 23].indexOf(i) > -1) s[i] = "-"
            else if (i === 14) s[i] = "4"
            else if (i === 19) s[i] = h[(Math.random() * 4 | 0) + 8]
            else s[i] = h[Math.random() * 16 | 0]
        }
        return s.join("")
    }

    function isValidUUID(str) {
        return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(str)
    }

    // ─── Inline components ────────────────────────────────────────────────────
    component FormSection: RowLayout {
        property string sectionTitle: ""
        property string sectionIndex: "01"
        Layout.fillWidth: true
        spacing: 10

        Text {
            text: sectionIndex
            font.pixelSize: 10
            font.letterSpacing: 1
            color: "#6c63ff"
            opacity: 0.5
        }

        Text {
            text: sectionTitle
            font.pixelSize: 11
            font.letterSpacing: 1
            font.weight: Font.Light
            color: "#8892b4"
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1; color: "#1a2540"
        }
    }

    component FormField: Rectangle {
        id: ff
        property string hint:     ""
        property string value:    ""
        property string icon:     ""
        property bool   readOnly: false

        height: 44; radius: 8
        color: fi.activeFocus ? "#0e1840" : "#090e20"
        border.color: fi.activeFocus ? "#6c63ff" : "#1e2d50"
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on color        { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
            spacing: 10

            Rectangle {
                width: 24; height: 24; radius: 5
                color: fi.activeFocus ? "#1a1560" : "#0d1230"
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: ff.icon
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    color: fi.activeFocus ? "#6c63ff" : "#2e3e60"
                }
            }

            TextInput {
                id: fi
                Layout.fillWidth: true
                text: ff.value
                color: "#d0d8f0"
                font.pixelSize: 13
                font.weight: Font.Light
                readOnly: ff.readOnly
                verticalAlignment: Text.AlignVCenter
                clip: true
                onTextChanged: ff.value = text

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ff.hint
                    color: "#28304a"
                    font.pixelSize: 13
                    font.weight: Font.Light
                    visible: parent.text === ""
                }
            }
        }
    }
}
