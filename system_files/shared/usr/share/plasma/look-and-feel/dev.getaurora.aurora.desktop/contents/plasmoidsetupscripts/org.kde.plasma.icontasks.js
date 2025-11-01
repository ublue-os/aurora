var panel = panels()[0];
var widget = panel.widgets("org.kde.plasma.icontasks")[0];

if (widget) {
    widget.currentConfigGroup = ["Configuration", "General"];

    // Set default applications in panel
    var launchers = [
        "preferred://browser",
        "applications:org.gnome.Ptyxis.desktop",
        "applications:io.github.kolunmi.Bazaar.desktop",
        "preferred://filemanager"
    ];

    widget.writeConfig("launchers", launchers);

    widget.reloadConfig();
}
