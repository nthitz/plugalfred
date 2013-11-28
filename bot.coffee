
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
    console.log(data)
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
)