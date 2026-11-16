/*
 *  SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 *
 *  Aurora page asking users to support the project. KDE donations are already
 *  covered by plasma-welcome's own Enjoy page, so this one is Aurora-specific.
 *  See https://github.com/ublue-os/aurora/issues/1169
 */

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

import org.kde.kirigami as Kirigami

import org.kde.plasma.welcome as Welcome

Welcome.Page {
    id: root

    // Lists the maintainers and contributors with their GitHub Sponsors links
    readonly property string donateUrl: "https://getaurora.dev/en/contributors/"

    // Plasma <= 6.7 requires `heading`, newer versions require `title` (with
    // `heading` kept as a deprecated alias), so set both.
    heading: i18ndc("plasma-welcome-aurora", "@title:window", "Support Aurora")
    title: i18ndc("plasma-welcome-aurora", "@title:window", "Support Aurora")
    description: xi18ndc("plasma-welcome-aurora", "@info:usagetip",
        "Aurora is made by volunteers in the Universal Blue community, not by a big company. Many of our contributors accept sponsorships. If you enjoy using Aurora, your support helps keep its development active and sustainable.<nl/><nl/>You can also help by reporting bugs, improving the documentation or helping other users.")

    topContent: [
        Kirigami.UrlButton {
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18ndc("plasma-welcome-aurora", "@action:button", "Contribute on GitHub")
            url: "https://github.com/ublue-os/aurora"
        },
        Kirigami.UrlButton {
            text: i18ndc("plasma-welcome-aurora", "@action:button", "Join the community on Discord")
            url: "https://discord.getaurora.dev"
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
            // Red heart in Breeze
            source: "donate"
            fallback: "distributor-logo"
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            icon.name: "help-donate"
            text: i18ndc("plasma-welcome-aurora", "@action:button", "Support Aurora's contributors")
            onClicked: Qt.openUrlExternally(root.donateUrl)
        }
    }
}
