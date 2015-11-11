/*
  Copyright (C) 2015 Alexander Ladygin
  Contact: Alexander Ladygin <fake.ae@gmail.com>
  All rights reserved.

  This file is part of Harbour-vk-music.

  Harbour-vk-music is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Harbour-vk-music is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Harbour-vk-music.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import harbour.vk.music.downloadmanager 1.0
import harbour.vk.music.audioplayerhelper 1.0
import "../utils/misc.js" as Misc
import "../utils/database.js" as DB

DockedPanel {
    id: controlsPanel

    property var song: {
        aid: 0
        ; owner_id: 0
        ; artist: ""
        ; title: ""
        ; duration: 0
        ; date: ""
        ; url: ""
        ; lyrics_id: 0
        ; album_id: 0
        ; genre_id: 0
        ; cached: false
    }
    property bool userInteraction: false
    property string albumTitle
    property int albumId: -1// -1 - My music
                            // -2 - shuffle on
    property bool showLyrics: false

    property alias audioPlayer: audioPlayer
    property alias nextButton: nextButton
    property alias previousButton: previousButton
    property alias sliderHeight: songProgress.height

    property bool _partiallyHidden: true
    property bool _autoPlayAfterDownload: true

    signal showLyrics()

    height: column.height
//    width: parent.width
    width: {
        switch (screen.sizeCategory){
                case (Screen.Large): return Screen.width/2;
                case (Screen.ExtraLarge): return Screen.width/3;
                default: return Screen.width;
        }
    }
    anchors.horizontalCenter: parent.horizontalCenter

    opacity: Qt.inputMethod.visible ? 0.0 : 1.0
    Behavior on opacity { FadeAnimator {}}

    dock: Dock.Bottom

    Column{
        id: column

        width: parent.width
        spacing: _partiallyHidden ? 0 : Theme.paddingMedium

        Separator {
            anchors.leftMargin: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin
            visible: !_partiallyHidden
        }

        ScrollingLabel {
            id: titleLabel

            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin + (downloadIndicatorItem.visible ? downloadIndicatorItem.width : 0)
                topMargin: Theme.paddingSmall
            }

            text: {
                song.artist
                ? (song.artist
                    + (song.title
                        ? " - " + song.title
                        : ""))
                : (song.title
                    ? song.title
                    : "")
            }
            visible: !_partiallyHidden
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignLeft

            onTextChanged: {
                if (controlsPanel.open && !controlsPanel._partiallyHidden){
                    titleLabel.stopAnimation();
                    titleLabel.startAnimation();
                }
            }
        }

        Separator {
            anchors.leftMargin: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin
            visible: !_partiallyHidden
        }

        Row {
            id: buttons
            spacing: Theme.paddingMedium

            visible: !_partiallyHidden

            Item {
                id: spacer
                height: parent.height
                width: (column.width - playButton.width - pauseButton.width - previousButton.width - nextButton.width - 4*Theme.paddingMedium) / 2
                IconButton {
                    id: shuffleButton
                    anchors {
                        right: parent.right
                        rightMargin: -Theme.paddingMedium
                        top: parent.top
                        topMargin: -height/3
                    }

                    icon.source: "image://theme/icon-m-shuffle?" + (AudioPlayerHelper.shuffle ? Theme.highlightColor : Theme.primaryColor)
                    icon.width: Theme.iconSizeSmall
                    icon.height: Theme.iconSizeSmall

                    onClicked: {
                        userInteraction = true;
                        audioPlayer.stop();
                        AudioPlayerHelper.shuffle = !AudioPlayerHelper.shuffle;
                        AudioPlayerHelper.repeat = false;
                    }
                }
                IconButton {
                    id: repeatButton
                    anchors {
                        right: parent.right
                        rightMargin: -Theme.paddingMedium
                        bottom: parent.bottom
                        bottomMargin: -height/3
                    }
                    icon.source: "image://theme/icon-m-repeat?" + (AudioPlayerHelper.repeat ? Theme.highlightColor : Theme.primaryColor)
                    icon.width: Theme.iconSizeSmall
                    icon.height: Theme.iconSizeSmall

                    enabled: !AudioPlayerHelper.shuffle

                    onClicked: {
                        AudioPlayerHelper.repeat = !AudioPlayerHelper.repeat;
                    }
                }

            }

            IconButton {
                id: previousButton
                icon.source: "image://theme/icon-m-previous?" + (pressed === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    userInteraction = true;
                    AudioPlayerHelper.playPrevious();
                }
            }
            IconButton {
                id: playButton
                icon.source: "image://theme/icon-l-play?" + (audioPlayer.playbackState === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    console.log("playing audio");
                    play();
                }
            }
            IconButton {
                id: pauseButton
                icon.source: "image://theme/icon-l-pause?" + (audioPlayer.playbackState === Audio.PausedState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    console.log("paused audio");
                    pause();
                }
            }
            IconButton {
                id: nextButton
                icon.source: "image://theme/icon-m-next?" + (pressed === Audio.PlayingState ? Theme.highlightColor : Theme.primaryColor)
                onClicked: {
                    userInteraction = true;
                    AudioPlayerHelper.playNext();
                }
            }
        }

        Separator {
            anchors.leftMargin: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin
            visible: !_partiallyHidden
        }

        Slider {
            id: songProgress

            width: parent.width
            leftMargin: Theme.horizontalPageMargin
            rightMargin: Theme.horizontalPageMargin
            implicitHeight: valueText !== "" ? Theme.itemSizeLarge : label !== "" ? Theme.itemSizeMedium : Theme.itemSizeSmall

            minimumValue: 0
            maximumValue: song.duration ? song.duration : 0
            value: 0
            valueText: _partiallyHidden ?
                            ""
                            : Format.formatDuration(
                                   songProgress.value
                                   , songProgress.value >= 3600 ? Format.DurationLong : Format.DurationShort
                              )
                              + " - "
                              + Format.formatDuration(
                                    song.duration
                                    , song.duration >= 3600 ? Format.DurationLong : Format.DurationShort
                                )
            enabled: (audioPlayer.status === Audio.Loaded
                            || audioPlayer.status === Audio.Buffered)
                        && !_partiallyHidden
                        && !song.error
            visible: open// && (song.aid > 0)

            label: _partiallyHidden
                   ? (song.artist
                      ? (song.artist
                         + (song.title
                            ? " - " + song.title
                            : ""))
                      : (song.title
                         ? song.title
                         : ""))
                   : ""

            onReleased: {
                audioPlayer.seek(value * 1000);
                console.log("new position = " + audioPlayer.position);
            }
        }
    }

    IconButton {
        id: lyricsButton

        anchors {
            horizontalCenter: downloadIndicatorItem.horizontalCenter
            top: column.top
            topMargin: buttons.y + Math.abs(lyricsButton.height - buttons.height)/2
        }

        icon.source: "image://theme/icon-s-clipboard?" + (pressed || showLyrics ? Theme.highlightColor : Theme.primaryColor)
        visible: song.lyrics_id > 0
        onClicked: {
            showLyrics = !showLyrics
        }
    }

    Item{
        id: downloadIndicatorItem

        anchors {
            right: column.right
            top: column.top
            topMargin: Math.abs(downloadIndicator.height - buttons.height)/2
            rightMargin: Theme.paddingSmall
        }

        height: downloadIndicator.height
        width: downloadIndicator.width

        visible: !_partiallyHidden

        BusyIndicator {
            id: downloadIndicator

            property bool clearingCache: false

            size: BusyIndicatorSize.Medium
            running: applicationWindow.applicationActive
                        && (audioPlayer.status === Audio.Loading
                            || audioPlayer.status === Audio.Buffering
                            || downloadManager.downloading
                            || clearingCache
                            )


        }

        Text {
            id: progressText
            anchors.centerIn: downloadIndicator
            color: Theme.primaryColor
            visible: downloadIndicator.running
            font.pixelSize: Theme.fontSizeSmall
        }

        IconButton {
            id: cachedIcon

            anchors.centerIn: downloadIndicator

            icon.source: "image://theme/icon-s-device-upload"
            visible: false

            onClicked:{//clear cache
                downloadIndicator.clearingCache = true;
                Utils.deleteFile(cacheDir, Misc.getFileName(song));
                DB.removeLastAccessedEntry(Misc.getFileName(song));
                Utils.getFreeSpace(cacheDir);
                AudioPlayerHelper.signalFileUnCached(AudioPlayerHelper.currentIndex);
                controlsPanel.hideCacheIcon();
                downloadIndicator.clearingCache = false;
            }
        }

        Image {
            id: errorIcon

            anchors.centerIn: downloadIndicator

            height: Theme.iconSizeSmall
            width: Theme.iconSizeSmall
            source: "../images/exclamation.png"
            visible: false
        }
    }

    Label {
        id: bitRateLabel

        anchors.left: column.left
        anchors.leftMargin: Theme.paddingSmall
        anchors.bottom: column.bottom

        visible: !_partiallyHidden && enableBitRate

        font.pixelSize: Theme.fontSizeExtraSmall
    }

    Audio {
        id: audioPlayer

        onSourceChanged: {
            console.log("new song url: " + source);
        }

        onStatusChanged: {
            console.log("audio status: " + getAudioStatus(status));

            bitRateLabel.text = Math.floor(audioPlayer.metaData.audioBitRate/1000) + "kbps";
        }

        onPositionChanged: {
            if (applicationWindow.applicationActive && !songProgress.pressed) {
                songProgress.value = position / 1000
            }
        }

        onPlaying: {
            userInteraction = false;
            AudioPlayerHelper.status = AudioPlayerHelper.Playing;
            console.log("playing song: " + titleLabel.text);
        }

        onPaused: {
            userInteraction = false;
            AudioPlayerHelper.status = AudioPlayerHelper.Paused;
        }

        onStopped: {
            console.log("playback stopped with userInteraction = " + userInteraction);
            AudioPlayerHelper.status = AudioPlayerHelper.Paused;
            songProgress.value = 0;
            bitRateLabel.text = "";
            if (userInteraction){//stopped by user
                //do nothing
            } else {//end of the song, play next
                AudioPlayerHelper.playNext();
            }
            userInteraction = false;
        }

    }

    MouseArea {
        id: dockPanelMouseArea

        anchors.fill: parent

        enabled: _partiallyHidden

        onClicked: {
            console.log("dockPanelMouseArea:onClicked")
            showFull();
        }
    }




    DownloadManager {
        id: downloadManager

        property int retryCount: 0

        onDownloadStarted: {
            console.log("Download Started");
            AudioPlayerHelper.status = AudioPlayerHelper.Buffering;
        }

        onDownloadComplete: {
            console.log("Download Complete");
            retryCount = 0;
            AudioPlayerHelper.signalFileCached(AudioPlayerHelper.currentIndex);
            song.cached = true;
            cachedIcon.visible = true;

            if (AudioPlayerHelper.downloadPlayListMode){
                AudioPlayerHelper.playNext();
                return;
            }

            audioPlayer.source = filePath;
            AudioPlayerHelper.status = AudioPlayerHelper.Paused;
            if (_autoPlayAfterDownload){
                audioPlayer.play();
            }
            _autoPlayAfterDownload = true;//setting to default value
            DB.setLastAccessedDate(Misc.getFileName(song));
            Utils.getFreeSpace(cacheDir);
        }

        onDownloadUnsuccessful: {
            console.log("Download unsuccessful");
            errorIcon.visible = true;
            song.error = true;
            AudioPlayerHelper.signalFileError(AudioPlayerHelper.currentIndex);
        }

        onProgress: {
            progressText.text = nPercentage + "%"
        }

        onDownloadCanceled: {

        }
    }

    Connections {
        target: AudioPlayerHelper

        onPauseRequested: {
            pause();
        }

        onPlayRequested: {
            play();
        }

    }

    Timer {
        id: waitForDockerCloseAnimationAndOpenTimer

        triggeredOnStart: false
        interval: 0
        repeat: false
        running: false

        onTriggered: {
            _partiallyHidden = true;
            if (AudioPlayerHelper.currentIndex !== -1
                    || song.aid > 0){
                show();
            }
        }
    }

    Timer {
        id: waitForKeyboardCloseAnimationAndOpenTimer

        triggeredOnStart: false
        interval: 500
        repeat: false
        running: false

        onTriggered: {
            if (AudioPlayerHelper.currentIndex !== -1
                    || song.aid > 0){
                show();
            }
        }
    }

    onAlbumIdChanged: {
        console.log("onAlbumIdChanged: " + albumId + " - " + albumTitle);
    }

    function getAudioStatus(status){
        switch(status){
            case Audio.NoMedia: return "No media";
            case Audio.Loading: return "Loading";
            case Audio.Loaded: return "Loaded";
            case Audio.Buffering: return "Buffering";
            case Audio.Stalled: return "Stalled";
            case Audio.Buffered: return "Buffered";
            case Audio.EndOfMedia: return "EndOfMedia";
            case Audio.InvalidMedia: return "InvalidMedia";
            case Audio.UnknownStatus: return "UnknownStatus";
            default: return "Undefined";
        }

    }

    function loadSong(newSong, autoPlay){
        autoPlay = (typeof autoPlay !== 'undefined' ? autoPlay : true);

        song = newSong;
        cachedIcon.visible = song.cached;
        errorIcon.visible = false;
        AudioPlayerHelper.title = song.title;
        AudioPlayerHelper.artist = song.artist;
        var fileName = Misc.getFileName(song);//no extension
        var filePath = Utils.getFilePath(cacheDir, fileName);
        if (filePath) {
            if (!song.cached){
                AudioPlayerHelper.signalFileCached(AudioPlayerHelper.currentIndex);
            }

            if (AudioPlayerHelper.downloadPlayListMode){
                AudioPlayerHelper.playNext();
                return;
            }

            audioPlayer.source = filePath;
            if (autoPlay){
                audioPlayer.play();
            }
            DB.setLastAccessedDate(fileName);
        } else {//check free space before download
            if (freeSpaceKBytes < minimumFreeSpaceKBytes){
                console.log("out of free disk space");
                for (var i = 0; i < 1000 && freeSpaceKBytes < minimumFreeSpaceKBytes; i++){//delete files until there is space
                    var lastAccessedFileName = DB.getLastAccessedFileName();
                    if (lastAccessedFileName){
                        freeSpaceKBytes += Utils.deleteFile(cacheDir, lastAccessedFileName);//returns size of deleted file
                        DB.removeLastAccessedEntry(lastAccessedFileName);
                        AudioPlayerHelper.signalFileDeleted(lastAccessedFileName);
                        console.log("freeSpaceKBytes after delete = " + freeSpaceKBytes);
                    } else {
                        break;
                    }
                }
            }
            if (freeSpaceKBytes < minimumFreeSpaceKBytes){//still? play from web
                audioPlayer.source = song.url;
                if (autoPlay){
                    audioPlayer.play();
                }
                Utils.getFreeSpace(cacheDir);
            } else {//free space ok, download
                _autoPlayAfterDownload = autoPlay;
                downloadManager.download(song.url, fileName, cacheDir);
            }
        }
    }

    function partiallyHide(){
        console.log("partiallyHide");

        if (screen.sizeCategory > Screen.Medium){//do not hide
            showFull();
            return;
        }

        titleLabel.stopAnimation();

        if (!applicationWindow.applicationActive){
            return;
        }

        if (!_partiallyHidden
                || !open){
            controlsPanel.hide(true);
            waitForDockerCloseAnimationAndOpenTimer.start();
        }
    }

    function hidePanel(){
        console.log("hidePanel");
        titleLabel.stopAnimation();

        if (!applicationWindow.applicationActive){
            return;
        }

        hide();
        _partiallyHidden = true;
    }

    function showFull(){
        console.log("showFull");

        if (!applicationWindow.applicationActive){
            return;
        }

        _partiallyHidden = false;

        if (!controlsPanel.open){
            waitForKeyboardCloseAnimationAndOpenTimer.start();
        }

        titleLabel.stopAnimation();
        titleLabel.startAnimation();
    }

    function stop(){
        if (downloadManager.downloading){
            downloadManager.abort();
        }

        if (audioPlayer.playbackState === Audio.PlayingState){
            audioPlayer.stop();
        }
    }

    function play(){
        userInteraction = true;
        if (song.cached){
            audioPlayer.play();
        } else {
            console.log("wow! song not cached or null");

            //maybe we are at index -1? start playing
            if (AudioPlayerHelper.currentIndex === -1){
                AudioPlayerHelper.playNext();
            }
        }
    }

    function pause(){
        userInteraction = true;
        if (song.cached){
            audioPlayer.pause();
        } else {
            console.log("wow! song not cached, this should not happen!");
        }
    }

    function hideCacheIcon(){
        cachedIcon.visible = false;
    }
}
