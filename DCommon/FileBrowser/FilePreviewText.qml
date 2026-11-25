pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: viewer

    property var pane: null
    property int request: 0
    property string previewText: ""
    property bool binary: false
    property bool truncated: false
    property real fileSize: 0
    property string loadedPath: ""

    readonly property var entry: pane?.settledEntries[0] ?? null
    readonly property var lines: previewText === "" ? [] : previewText.replace(/\r\n/g, "\n").replace(/\n$/, "").split("\n")
    readonly property bool showsContent: previewText !== ""
    readonly property var rows: []
    readonly property string note: {
        if (binary)
            return I18n.tr("Binary file", "preview column note for files without readable text");
        if (truncated)
            return I18n.tr("First %1 of %2", "preview column note when only the start of the file is shown").arg(FileFormat.size(FileBrowserMetrics.previewBytes)).arg(FileFormat.size(fileSize));
        return "";
    }

    function scrollPage(direction) {
        scroll.contentY = Math.max(scroll.originY, Math.min(scroll.originY + scroll.contentHeight - scroll.height, scroll.contentY + direction * scroll.height));
    }

    function stop() {
        request++;
        scroll.stopMomentum();
        previewText = "";
        binary = false;
        truncated = false;
        loadedPath = "";
    }

    function load() {
        const current = ++request;
        if (!entry || typeof pane.backend?.preview !== "function") {
            stop();
            return;
        }
        const target = entry.path;
        pane.backend.preview(target, FileBrowserMetrics.previewBytes, result => {
            if (!viewer || current !== viewer.request)
                return;
            if (result.error) {
                viewer.stop();
                return;
            }
            viewer.binary = result.binary === true;
            viewer.truncated = result.truncated === true;
            viewer.fileSize = result.size ?? 0;
            viewer.previewText = result.text ?? "";
            if (viewer.loadedPath !== target) {
                scroll.stopMomentum();
                scroll.contentY = 0;
            }
            viewer.loadedPath = target;
        });
    }

    Connections {
        target: viewer.pane

        function onRevisionChanged() {
            viewer.load();
        }

        function onCurrentChanged() {
            if (!viewer.pane.current)
                viewer.stop();
        }
    }

    Component.onCompleted: load()

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(parent.height, scroll.contentHeight)
        visible: viewer.showsContent

        DFlickable {
            id: scroll

            anchors.fill: parent
            clip: true
            contentWidth: width
            contentHeight: editor.contentHeight
            interactive: contentHeight > height

            TextEdit {
                id: editor

                width: scroll.width
                height: Math.max(scroll.height, contentHeight)
                text: viewer.previewText
                readOnly: true
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                font.family: Style.fontFor("mono")
                font.pixelSize: Style.fontSizeSmall
                color: Style.surfaceText
                selectionColor: Style.primary
                selectedTextColor: Style.onPrimary
                renderType: Text.NativeRendering

                Keys.onEscapePressed: event => {
                    if (selectedText !== "") {
                        deselect();
                        return;
                    }
                    focus = false;
                    event.accepted = false;
                }

                MouseArea {
                    id: pointerArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.IBeamCursor
                    acceptedButtons: Qt.RightButton
                    onClicked: mouse => {
                        if (!editor.activeFocus)
                            editor.forceActiveFocus();
                        const point = pointerArea.mapToItem(viewer, mouse.x, mouse.y);
                        contextMenu.openAt(point.x, point.y);
                    }
                }
            }
        }
    }

    FileMenu {
        id: contextMenu

        FileMenuItem {
            text: I18n.tr("Copy", "context menu action copying selected preview text")
            iconName: "content_copy"
            shortcutText: "Ctrl+C"
            enabled: editor.selectedText !== ""
            onClicked: {
                contextMenu.close();
                editor.copy();
            }
        }

        FileMenuItem {
            text: I18n.tr("Select all", "context menu action selecting all preview text")
            iconName: "select_all"
            shortcutText: "Ctrl+A"
            enabled: editor.text !== ""
            onClicked: {
                contextMenu.close();
                editor.forceActiveFocus();
                editor.selectAll();
            }
        }
    }
}
