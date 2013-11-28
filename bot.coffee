
PlugAPI = require("./plugapi");


AUTH = process.env.AUTH
ROOM = "mashupfm";
bot = new PlugAPI(AUTH);

bot.connect(ROOM);

bot.on('connected', () ->
    bot.joinRoom(ROOM, (data) ->
        # data object has information on the room - list of users, song currently playing, etc.
        console.log("Joined " + ROOM + ": ", data);
    );
)
bot.on('chat', (data) ->
    lowercase = data.message.toLowerCase()
    if (lowercase.indexOf('bot') isnt -1 or lowercase.indexOf('alfred') isnt -1) and lowercase.indexOf('dance') isnt -1
        bot.vote('up',() ->
            console.log 'wooted'
        )
    console.log(data)
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
)