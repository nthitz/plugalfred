
PlugAPI = require("./plugapi");


AUTH = process.env.AUTH
ROOM = "mashupfm";
bot = new PlugAPI(AUTH);

bot.connect(ROOM);

bot.on('connected', function() {
    bot.joinRoom(ROOM, function(data) {
        // data object has information on the room - list of users, song currently playing, etc.
        console.log("Joined " + ROOM + ": ", data);
    });
})
/*
bot.on("roomChanged", function() {
  console.log('joined');
  console.log(bot.getAudience())

    
});
*/
bot.on('chat', function(data) {
    console.log(data)
    if (data.type == 'emote')
        console.log(data.from+data.message)
    else
        console.log(data.from+"> "+data.message)
})