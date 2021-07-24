# Chatterino
A super simple ruby chat server. 

This is an anonymous, multichannel chat server built on ruby and em-websocket

## Running
``` bash
$ gem install em-websocket json
$ ruby chatterino.rb
```
And that's it, there's now a websocket server listening on ws://localhost:8081 ready to answer all your requests

## Commands
Now that you have your server running, you can start sending commands to it through websockets
The list of supported commands is:
* __new_chan__ __channel_name__ __username__ - Creates a new channel named *channel_name* and subscribes *username* to it
* __subscribe channel_name username__ - Subscribes *username* to *channel_name*
* __send_msg__ __channel_name__ __username__ __message__ - Sends *message* from *username* in *channel_name*
* __get_online channel_name__ - Sends back a JSON list of who's online in *channel_name*
* __get_chans__ - Sends back a JSON list of all the channels
