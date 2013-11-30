
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
currentDJName = null
currentDJ = null
bot.connect(ROOM);

bot.on('connected', () ->
    bot.joinRoom(ROOM, (data) ->
        currentDJ = data.room.djs[0].user
        currentDJName = currentDJ.username
        console.log 'now up ' + currentDJName
    );
)
bot.on('chat', (data) ->
    lowercase = data.message.toLowerCase()
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
    if lowercase.match('(bot|alfred) relax')
        songLengthRelaxing = true
        clearTimeout songLengthLimitSkipTimeout
        clearTimeout songLengthLimitWarnTimeout
        bot.chat 'I\'m chiller than you are dude.'
    if lowercase.match('(bot|alfred) skip')
        skipUserSongLengthSkip()
    #console.log(data)
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
)

bot.on('djAdvance', (data) ->
    currentDJ = data.djs[0].user
    currentDJName = data.djs[0].user.username
    clearTimeout(songLengthLimitSkipTimeout)
    clearTimeout songLengthLimitWarnTimeout

    #console.log(data)
    #sconsole.log data.djs[0]
    songLengthRelaxing = false
    if data.media.duration > songLengthLimitSeconds and enforceSongLength
        skipAt = data.media.duration - songLengthLimitSeconds
        min =  Math.floor(skipAt % 60)
        if min < 10
            min = '0' + min
        skipAtStr = Math.floor(skipAt / 60) + ":" + min
        bot.chat "@" + currentDJName + "Your song is longer than the limit of " + songLengthLimit + " minutes. Please skip when there is " + skipAtStr + ' remaining.'
        songLengthLimitWarnTimeout = setTimeout(warnUserSongLengthSkip, (songLengthLimitSeconds - 15) * 1000)
        songLengthLimitSkipTimeout = setTimeout(skipUserSongLengthSkip, songLengthLimitSeconds * 1000)
)
warnUserSongLengthSkip = () ->
    console.log 'warn'
    bot.chat "@"+ currentDJName + " you have 15 seconds to skip before being escorted"
skipUserSongLengthSkip = () ->
    console.log 'kick ' + currentDJName
    bot.moderateRemoveDJ(currentDJ.id)