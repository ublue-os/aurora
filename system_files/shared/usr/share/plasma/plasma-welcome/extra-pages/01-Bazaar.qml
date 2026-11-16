/*
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 *
 *  Aurora replacement for plasma-welcome's Discover page, since Aurora ships
 *  Bazaar instead of Discover. See https://github.com/ublue-os/aurora/issues/1169
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasma.welcome as Welcome

Welcome.Page {
    id: root

    readonly property string bazaarId: "io.github.kolunmi.Bazaar"

    // Bazaar is a Flatpak that gets preinstalled in the background on first boot,
    // so it may not be there yet when this page is shown.
    property bool bazaarInstalled: false

    // Plasma <= 6.7 requires `heading`, newer versions require `title` (with
    // `heading` kept as a deprecated alias), so set both.
    heading: i18ndc("plasma-welcome-aurora", "@title:window", "Find Great Apps")
    title: i18ndc("plasma-welcome-aurora", "@title:window", "Find Great Apps")
    description: xi18ndc("plasma-welcome-aurora", "@info:usagetip",
        "Aurora uses <application>Bazaar</application> as its app store. It installs apps from Flathub as Flatpaks, which are kept separate from the system and are updated automatically together with the rest of Aurora.<nl/><nl/>For command-line tools, use <command>brew</command> in a terminal instead.")

    topContent: [
        Kirigami.UrlButton {
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18ndc("plasma-welcome-aurora", "@action:button", "Learn more about installing software on Aurora")
            url: "https://docs.getaurora.dev"
        }
    ]

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width, Kirigami.Units.gridUnit * 30)
        spacing: Kirigami.Units.largeSpacing

        Kirigami.Icon {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.iconSizes.enormous * 2
            implicitHeight: implicitWidth
            source: root.bazaarId
            fallback: "system-software-install"
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            enabled: root.bazaarInstalled
            icon.name: "system-software-install"
            text: i18ndc("plasma-welcome-aurora", "@action:button", "Open Bazaar")
            onClicked: Welcome.Utils.launchApp(root.bazaarId)
        }

        Kirigami.InlineMessage {
            Layout.fillWidth: true
            visible: !root.bazaarInstalled
            type: Kirigami.MessageType.Information
            text: i18ndc("plasma-welcome-aurora", "@info",
                "Bazaar is still being installed in the background. This page will update once it is ready.")
        }
    }

    function checkBazaar() {
        Welcome.Utils.runCommand("flatpak info " + root.bazaarId, (returnStatus, outputText) => {
            root.bazaarInstalled = (returnStatus === 0);
        });
    }

    // Re-check periodically while Bazaar is still being installed.
    Timer {
        interval: 10000
        repeat: true
        running: !root.bazaarInstalled
        onTriggered: root.checkBazaar()
    }

    Component.onCompleted: checkBazaar()
}
