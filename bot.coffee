
PlugAPI = require("./plugapi");


AUTH = process.env.AUTH
ROOM = "mashupfm";
bot = new PlugAPI(AUTH, "4w@fWs$");

songLengthLimit = 8
songLengthLimitSeconds = songLengthLimit * 60
enforceSongLength = true
songLengthRelaxing = false
songLengthLimitSkipTimeout = null
songLengthLimitWarnTimeout = null
autoSkipTimeout = null
currentDJName = null
currentDJ = null
enableAutoSkip = false
botadmins = ['5164d7883b79036fc28a56a9']
roomStaff = []
cycleLimits = [5,10]
cycleLimits = [1,2]
enforceAFKAtHowManyDJs = 5
afkLimit = 60 * 60 * 1000
mehLimit = 5
bootTime = Date.now()
lastUserChats = {}
bot.on('connected', () ->
    bot.joinRoom(ROOM, (data) ->
        #console.log data
        roomStaff = data.room.staff
        if data.room.djs.length > 0
            currentDJ = data.room.djs[0].user
            #console.log currentDJ
            console.log 'now up ' + currentDJ.username
    );
)

bot.connect(ROOM);
bot.on('chat', (data) ->
    #console.log data
    lowercase = data.message.toLowerCase()
    lastUserChats[data.fromID] = Date.now()
    fromBotAdmin = isBotAdmin(data.fromID)
    fromStaff = isRoomStaff(data.fromID)
    if (lowercase.indexOf('bot') isnt -1 or lowercase.indexOf('alfred') isnt -1) and lowercase.indexOf('dance') isnt -1
        bot.vote('up',() ->
            console.log 'wooted'
        )
    limitCmd = lowercase.match('(bot|alfred) limit ([0-9]+|off)')
    if limitCmd isnt null
        console.log limitCmd
        param = limitCmd[2]
        if param is 'off'
            enforceSongLength = false
        else
            enforceSongLength = true
            songLengthLimit = param 
            songLengthLimitSeconds = songLengthLimit * 60
            bot.chat 'The time limit is now ' + param + ' minutes.'
    if lowercase.match('(bot|alfred) relax') and fromStaff
        songLengthRelaxing = true
        clearTimeout songLengthLimitSkipTimeout
        clearTimeout songLengthLimitWarnTimeout
        bot.chat 'I\'m calmer than you are.'
    if lowercase.match('(bot|alfred) skip') and fromStaff
        userSkip()
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
)
curVotes = {}
bot.on('djAdvance', (data) ->
    curVotes = {}
    if data.djs.length > 0
        currentDJ = data.djs[0].user
    else
        currentDJ = null
    clearTimeout(songLengthLimitSkipTimeout)
    clearTimeout songLengthLimitWarnTimeout
    clearTimeout autoSkipTimeout
    if data.djs.length > enforceAFKAtHowManyDJs
        enforceAFK(data.djs)
    songLengthRelaxing = false
    if typeof data.media is 'undefined' or data.media is null
        return
    if data.media.duration > songLengthLimitSeconds and enforceSongLength
        skipAt = data.media.duration - songLengthLimitSeconds
        hours = Math.floor(skipAt / (60 * 60))
        if hours is 0
            hours = ''
        else
            hours += ':'
        mins = Math.floor((skipAt % (60 * 60))/ 60)
        if mins < 10 and hours isnt ''
            mins = '0' + mins
        seconds =  Math.floor(skipAt % 60)
        if seconds < 10
            seconds = '0' + seconds
        skipAtStr = hours + mins + ":" + seconds
        bot.chat "@" + currentDJ.username + " Your song is longer than the limit of " + songLengthLimit + " minutes. Please skip when there is " + skipAtStr + ' remaining.'
        songLengthLimitWarnTimeout = setTimeout(warnUserSongLengthSkip, (songLengthLimitSeconds - 15) * 1000)
        songLengthLimitSkipTimeout = setTimeout(userSkip, songLengthLimitSeconds * 1000)

    if enableAutoSkip
        autoSkipTimeout = setTimeout userSkip, (data.media.duration + 3)* 1000
    #djsInLine = data.djs.length
    #if djsInLine >= cycleLimits[1]
    #    
    #else if djsInLine <= cycleLimits[0]
        
)
enforceAFK = (djs) ->
    if djs.length < 2
        return
    time = Date.now()
    minActionTime = time - afkLimit
    checkIfCurDJStillAFK(djs[0].user,minActionTime)
    checkIfOnDeckAFK(djs[1].user,minActionTime)
checkIfCurDJStillAFK = (dj, timeLimit) ->
    if typeof lastUserChats[dj.id] is 'undefined'
        lastUserChats[dj.id] = Date.now()
        return
    lastChat = lastUserChats[dj.id]
    if lastChat is -1
        bot.chat "@"+dj.username + " please stay active to dj"
        bot.moderateRemoveDJ(currentDJ.id,"Too long")
checkIfOnDeckAFK = (dj, timeLimit) ->
    if typeof lastUserChats[dj.id] is 'undefined'
        return
    lastChat = lastUserChats[dj.id]
    if lastChat < timeLimit
        bot.chat "@" + dj.username + " are you still there? You are on deck! Please chat to ensure you are active!"
        lastUserChats[dj.id] = -1
bot.on('voteUpdate', (data) ->
    curVotes[data.id] = data.vote
    numMehs = 0
    for userid,vote of curVotes
        if vote is -1
            numMehs++
    if numMehs >= mehLimit
        skipForShittySong()
)
skipForShittySong = () ->
    bot.chat "@" + currentDJ.username + " your song has been skipped for receiving " + mehLimit + " mehs."
    userSkip()

bot.on('userJoin', (data) ->
    lastUserChats[data.id] = Date.now()
)

reconnect = () ->
    bot.connect('mashupfm');

bot.on('close', reconnect);
bot.on('error', reconnect);






warnUserSongLengthSkip = () ->
    console.log 'warn'
    if currentDJ is null
        return
    bot.chat "@"+ currentDJ.username + " you have 15 seconds to skip before being escorted"

userSkip = () ->
    if currentDJ is null
        return
    console.log 'skipping someone'    
    bot.skipSong(currentDJ.id)
    
isBotAdmin = (userid) ->
    return botadmins.indexOf(userid) isnt -1
isRoomStaff = (userid) ->
    return typeof roomStaff[userid] isnt 'undefined'