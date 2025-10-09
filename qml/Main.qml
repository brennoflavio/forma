/*
 * Copyright (C) 2025  Brenno Flávio de Almeida
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * forma is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.7
import Lomiri.Components 1.3
import Lomiri.Components.Popups 1.3
//import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.4
import Lomiri.Content 1.3
import "ut_components"

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'forma.brennoflavio'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property string errorMessage: ""

    PageStack {
        id: pageStack
        anchors.fill: parent

        Component.onCompleted: {
            push(mainPage)
        }
    }

    Connections {
        target: ContentHub
        onImportRequested: {
            if (transfer && transfer.items && transfer.items.length > 0) {
                var importedImages = [];
                for (var i = 0; i < transfer.items.length; i++) {
                    var fileUrl = transfer.items[i].url.toString();
                    var filePath = fileUrl.replace("file://", "");
                    importedImages.push(filePath);
                }

                if (importedImages.length > 0) {
                    if (pageStack.currentPage && pageStack.currentPage.selectedImages !== undefined) {
                        pageStack.currentPage.selectedImages = importedImages;
                    }
                }

                transfer.state = ContentTransfer.Charged;
            }
        }

        onShareRequested: {
            if (transfer && transfer.items && transfer.items.length > 0) {
                var importedImages = [];
                for (var i = 0; i < transfer.items.length; i++) {
                    var fileUrl = transfer.items[i].url.toString();
                    var filePath = fileUrl.replace("file://", "");
                    importedImages.push(filePath);
                }

                if (importedImages.length > 0) {
                    if (pageStack.currentPage && pageStack.currentPage.selectedImages !== undefined) {
                        pageStack.currentPage.selectedImages = importedImages;
                    }
                }

                transfer.state = ContentTransfer.Charged;
            }
        }
    }

    Component {
        id: mainPage

        Page {
            id: mainPageItem
            anchors.fill: parent

            header: AppHeader {
                id: header
                pageTitle: i18n.tr('Forma')
                isRootPage: true
                appIconName: "stock_image"
                showSettingsButton: false
            }

            property string selectedFormat: "png"
            property var selectedImages: []
            property int quality: 95
            property bool optimize: false

            LoadToast {
                id: loadingToast
                message: i18n.tr("Converting Images")
            }

            Column {
                anchors.centerIn: parent
                spacing: units.gu(4)
                width: parent.width - units.gu(4)

                OptionSelector {
                    id: formatSelector
                    text: i18n.tr("Output format")
                    anchors.left: parent.left
                    anchors.right: parent.right
                    model: [
                            "PNG",
                            "JPG",
                            "AVIF",
                            "HEIC",
                            "HEIF",
                            "WEBP"
                    ]
                    selectedIndex: 0
                    containerHeight: itemHeight * 3
                    onSelectedIndexChanged: {
                        mainPageItem.selectedFormat = model[selectedIndex].toLowerCase()
                    }
                }

                NumberOption {
                    id: qualityOption
                    title: i18n.tr("Quality")
                    subtitle: i18n.tr("Conversion quality (0-100)")
                    value: mainPageItem.quality
                    minimumValue: 0
                    maximumValue: 100
                    onValueUpdated: {
                        mainPageItem.quality = newValue
                    }
                }

                ToggleOption {
                    id: optimizeOption
                    title: i18n.tr("Optimize")
                    subtitle: i18n.tr("Optimize file size")
                    checked: mainPageItem.optimize
                    onCheckedChanged: {
                        mainPageItem.optimize = checked
                    }
                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr("Select images to convert")
                    iconName: "image-x-generic-symbolic"
                    backgroundColor: "#2196F3"
                    onClicked: {
                        pageStack.push(imagePickerPage, {"mainPage": mainPageItem});
                    }
                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mainPageItem.selectedImages.length > 1
                        ? i18n.tr("Convert %1 images").arg(mainPageItem.selectedImages.length)
                        : mainPageItem.selectedImages.length === 1
                            ? i18n.tr("Convert 1 image")
                            : i18n.tr("Convert Images")
                    iconName: "media-playback-start"
                    backgroundColor: "#1976D2"
                    enabled: mainPageItem.selectedImages.length > 0
                    onClicked: {
                        loadingToast.showing = true;

                        python.call('main.convert_images', [mainPageItem.selectedImages, mainPageItem.selectedFormat, mainPageItem.quality, mainPageItem.optimize], function(response) {
                            loadingToast.showing = false;

                            if (response.success && response.image_paths && response.image_paths.length > 0) {
                                pageStack.push(multiSharePage, {
                                    "imagePaths": response.image_paths
                                });
                            } else {
                                root.errorMessage = response.message || i18n.tr("Failed to convert images. Please try again.");
                                PopupUtils.open(errorDialogComponent);
                            }
                        });
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.errorMessage
                    fontSize: "small"
                    color: theme.palette.normal.negative
                    visible: root.errorMessage !== ""
                    wrapMode: Text.WordWrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    ContentStore {
        id: contentStore
        scope: ContentScope.App
    }

    Component {
        id: imagePickerPage

        Page {
            id: imagePickerInstance
            property var activeTransfer
            property var selectedFiles: []
            property var mainPage

            header: PageHeader {
                id: imagePickerHeader
                title: i18n.tr("Select Images to Convert")
                leadingActionBar.actions: [
                    Action {
                        iconName: "back"
                        onTriggered: {
                            if (imagePickerInstance.activeTransfer) {
                                imagePickerInstance.activeTransfer.state = ContentTransfer.Aborted;
                            }
                            pageStack.pop();
                        }
                    }
                ]
            }

            ContentPeerPicker {
                id: imagePicker
                anchors {
                    top: imagePickerHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                contentType: ContentType.Pictures
                handler: ContentHandler.Source

                onPeerSelected: {
                    imagePickerInstance.activeTransfer = peer.request(contentStore);
                    imagePickerInstance.activeTransfer.selectionType = ContentTransfer.Multiple;
                    imagePickerInstance.activeTransfer.stateChanged.connect(function () {
                        if (imagePickerInstance.activeTransfer.state === ContentTransfer.Charged) {
                            if (imagePickerInstance.activeTransfer.items.length > 0) {
                                imagePickerInstance.selectedFiles = [];
                                var selectedImages = [];
                                for (var i = 0; i < imagePickerInstance.activeTransfer.items.length; i++) {
                                    var fileUrl = imagePickerInstance.activeTransfer.items[i].url.toString();
                                    var filePath = fileUrl.replace("file://", "");
                                    imagePickerInstance.selectedFiles.push(filePath);
                                    selectedImages.push(filePath);
                                }
                                if (imagePickerInstance.mainPage) {
                                    imagePickerInstance.mainPage.selectedImages = selectedImages;
                                }
                                pageStack.pop();
                            }
                        }
                    });
                }

                onCancelPressed: {
                    if (imagePickerInstance.activeTransfer) {
                        imagePickerInstance.activeTransfer.state = ContentTransfer.Aborted;
                    }
                    pageStack.pop();
                }
            }
        }
    }

    Component {
        id: errorDialogComponent

        Dialog {
            id: errorDialog
            title: i18n.tr("Conversion Error")
            text: root.errorMessage

            Button {
                text: i18n.tr("OK")
                onClicked: {
                    PopupUtils.close(errorDialog);
                    root.errorMessage = "";
                }
            }
        }
    }

    Component {
        id: multiSharePage

        Page {
            id: sharePageInstance
            property var imagePaths: []
            property var activeTransfer

            header: PageHeader {
                id: shareHeader
                title: i18n.tr("Share Converted Images")
                leadingActionBar.actions: [
                    Action {
                        iconName: "back"
                        onTriggered: {
                            if (sharePageInstance.activeTransfer) {
                                sharePageInstance.activeTransfer.state = ContentTransfer.Aborted;
                            }
                            pageStack.pop();
                        }
                    }
                ]
            }

            ContentPeerPicker {
                id: peerPicker
                anchors {
                    top: shareHeader.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                contentType: ContentType.Pictures
                handler: ContentHandler.Share

                onPeerSelected: {
                    sharePageInstance.activeTransfer = peer.request();
                    if (sharePageInstance.activeTransfer) {
                        var items = [];
                        for (var i = 0; i < sharePageInstance.imagePaths.length; i++) {
                            var item = contentItemComponent.createObject(null, {
                                "url": "file://" + sharePageInstance.imagePaths[i]
                            });
                            items.push(item);
                        }
                        sharePageInstance.activeTransfer.items = items;
                        sharePageInstance.activeTransfer.state = ContentTransfer.Charged;
                        pageStack.pop();
                    }
                }

                onCancelPressed: {
                    if (sharePageInstance.activeTransfer) {
                        sharePageInstance.activeTransfer.state = ContentTransfer.Aborted;
                    }
                    pageStack.pop();
                }
            }

            Component {
                id: contentItemComponent
                ContentItem {
                    property alias url: contentItemInstance.url
                    id: contentItemInstance
                }
            }
        }
    }

    Python {
        id: python

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'));

            importModule('main', function() {});
        }

        onError: {
            console.log('python error: ' + traceback);
        }
    }
}
