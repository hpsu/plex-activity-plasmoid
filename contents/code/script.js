var sessions = {};

function getTest() {
    console.log(JSON.stringify(sessions));
    return sessions;
}

function zeroPad(num) {
    var str = String(num);
    if(str.length < 2) {
        str = '0' + str;
    }
    return str;
}

function formatEpisodeTitle(model) {
    var title = '';
    switch(model.type) {
        case 'track':
            title = [model.grandparentTitle,
                     model.parentTitle,
                     zeroPad(model.index) + '. ' +
                        model.title].join('\n');
            break;
        case 'episode':
            if(model.parentIndex) {
                title += 'S' + zeroPad(model.parentIndex);
            }
            if(model.index) {
                title += 'E' + zeroPad(model.index);
            }
            if(model.parentIndex &&
               model.parentIndex === '0') {
                title = 'Special ' + model.index;
            }
            title = model.grandparentTitle + ' - ' + title;
            title += '\n' + model.title;
            break;
        default:
            title = model.title;
            if(model.year) {
                title += ' (' + model.year + ')';
            }
    }
    return title;
}

/**
 * Collect model data from child properties
 */
function parseChildProperties(model) {
    model.userThumb = '';
    model.userName = 'anonymous';

    for(var i in model._children) {
        var childObject = model._children[i];
        switch(childObject._elementType) {
            case 'User':
                model.userName = childObject.title;
                if(childObject.thumb) {
                    model.userThumb = childObject.thumb;
                }
                break;
            case 'TranscodeSession':
                model.transcodeProgress = childObject.progress / 100;
                break;
            case 'Player':
                if(childObject.state == 'paused') {
                    model.playStateIcon = 'media-playback-pause';
                } else if(childObject.state == 'buffering') {
                    model.playStateIcon = 'buffering';
                } else if(childObject.state == 'playing') {
                    model.playStateIcon = 'media-playback-start';
                } else {
                    console.log('play status',
                                childObject.state);
                }
                break;
        }
    }
}

/**
 * Remap listKeys. Items may have been moved around
 */
function remapListIndicies() {
    for(var i = 0; i < sessionModel.count; i++) {
        var cont = sessionModel.get(i);
        if(sessions[cont.sessionKey]) {
            sessions[cont.sessionKey].listKey = i;
        }
    }
}

function processSessions(reply) {
    badgeText = String(reply._children.length);

    if (reply._children.length > 0) {
        plasmoid.status = PlasmaCore.Types.ActiveStatus;
    } else {
        plasmoid.status = PlasmaCore.Types.PassiveStatus;
    }
    var gc = [];
    remapListIndicies();

    for(var i in reply._children) {
        var cont = reply._children[i],
            dest = {};

        if(sessions[cont.sessionKey]) {
            cont.listKey = sessions[cont.sessionKey].listKey;
            dest = sessionModel.get(cont.listKey);
        }

        parseChildProperties(cont);
        if(!cont.viewOffset) {
            cont.viewOffset = '0';
        }
        var fields = ['thumb', 'viewOffset', 'duration',
                      'type', 'grandparentTitle',
                      'parentTitle', 'index', 'title',
                      'parentIndex', 'year', 'userName',
                      'userThumb', 'transcodeProgress',
                      'playStateIcon', 'sessionKey'];
        for(var j in fields) {
            dest[fields[j]] = cont[fields[j]];
        }
        if(!sessions[cont.sessionKey]) {
            cont.listKey = sessionModel.count;
            sessionModel.append(dest);
        }
        gc.push(cont.sessionKey);
        sessions[cont.sessionKey] = cont;
    }

    for(var k in sessions) {
        if(gc.indexOf(k) === -1) {
            sessionModel.remove(sessions[k].listKey);
            delete sessions[k];
        }
    }
}

function requestSessions() {
    var xhr = new XMLHttpRequest();
    xhr.timeout = 1000;

    xhr.onreadystatechange = function(){
        if (xhr.readyState == XMLHttpRequest.DONE) {
            processSessions(JSON.parse(xhr.responseText));
        }
    };

    xhr.open('POST', 'http://' + getHost() + '/status/sessions');
    xhr.setRequestHeader('Accept', 'application/json');

    try {
        xhr.send();
    }
    catch (e){
        console.log('XHR send error');
    }
}

 function onWsMessage(message) {
    var data = JSON.parse(message);
    switch(data.type) {
        case 'playing':
        case 'transcodeSession.update':
        case 'transcodeSession.start':
        case 'transcodeSession.end':
            requestSessions();
            break;
        case 'backgroundProcessingQueue':
        case 'progress':
        case 'timeline':
            break;
        default:
    }
}

function onWsStatusChange(socket) {
    switch(socket.status) {
        case WebSocket.Error:
            console.log('WS Error: ' + socket.errorString);
            break;
        case WebSocket.Open:
            requestSessions();
            break;
        case WebSocket.Closed:
            socket.active = false;
            wsReconnectTimer.start();
            break;
    }
}

function getHost() {
    return plasmoid.configuration.serverHost + ':' +
           plasmoid.configuration.serverPort;
}
