
PlugAPI = require("./plugapi");


AUTH = process.env.AUTH
ROOM = "mashupfm";
bot = new PlugAPI(AUTH);

songLengthLimit = 8
songLengthLimitSeconds = songLengthLimit * 60
enforceSongLength = true
songLengthRelaxing = false
songLengthLimitSkipTimeout = null
songLengthLimitWarnTimeout = null
autoSkipTimeout = null
currentDJName = null
currentDJ = null
enableAutoSkip = true
botadmins = ['5164d7883b79036fc28a56a9']
roomStaff = []
bot.on('connected', () ->
    bot.joinRoom(ROOM, (data) ->
        #console.log data
        roomStaff = data.room.staff
        if data.room.djs.length > 0
            currentDJ = data.room.djs[0].user
            console.log currentDJ
        console.log 'now up ' + currentDJ.username
    );
)

bot.connect(ROOM);
bot.on('chat', (data) ->
    lowercase = data.message.toLowerCase()
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
    #console.log(data)
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
)

bot.on('djAdvance', (data) ->
    if data.djs.length > 0
        currentDJ = data.djs[0].user
    else
        currentDJ = null
    clearTimeout(songLengthLimitSkipTimeout)
    clearTimeout songLengthLimitWarnTimeout
    clearTimeout autoSkipTimeout
    #console.log(data)
    #sconsole.log data.djs[0]
    songLengthRelaxing = false
    if typeof data.media is 'undefined' or data.media is null
        return
    if data.media.duration > songLengthLimitSeconds and enforceSongLength
        skipAt = data.media.duration - songLengthLimitSeconds
        min =  Math.floor(skipAt % 60)
        if min < 10
            min = '0' + min
        skipAtStr = Math.floor(skipAt / 60) + ":" + min
        bot.chat "@" + currentDJ.username + "Your song is longer than the limit of " + songLengthLimit + " minutes. Please skip when there is " + skipAtStr + ' remaining.'
        songLengthLimitWarnTimeout = setTimeout(warnUserSongLengthSkip, (songLengthLimitSeconds - 15) * 1000)
        songLengthLimitSkipTimeout = setTimeout(userSkip, songLengthLimitSeconds * 1000)

    if enableAutoSkip
        autoSkipTimeout = setTimeout userSkip, (data.media.duration + 3)* 1000
)
warnUserSongLengthSkip = () ->
    console.log 'warn'
    if currentDJ is null
        return
    bot.chat "@"+ currentDJ.username + " you have 15 seconds to skip before being escorted"
###
skipUserSongLengthSkip = () ->
    if currentDJ is null
        return
    console.log 'kick ' + currentDJ.username
    bot.moderateRemoveDJ(currentDJ.id)
###
userSkip = () ->
    console.log 'skipping someone'    
    bot.skipSong((data) ->
        console.log 'skip callback'
        console.log data
        return;
    )
    #bot.moderateForceSkip()
isBotAdmin = (userid) ->
    return botadmins.indexOf(userid) isnt -1
isRoomStaff = (userid) ->
    return typeof roomStaff[userid] isnt 'undefined'