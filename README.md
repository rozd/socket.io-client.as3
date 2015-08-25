socket.io-client.as3
====================

The socket.io-client implementation for ActionScript 3.0, most code was ported from https://github.com/nkzawa/socket.io-client.java


### Connect 

```as3
var opts:Options = new Options();
opts.forceNew = true;
opts.query = {authToken : ${CURRENT_USER_TOKEN}};

socket = IO.socket(backend.node, opts);
socket.on(Socket.EVENT_ERROR, onError); // handles server connection errors, such as token expiration
socket.on(Socket.EVENT_CONNECT, onConnect); // indicates that connection is established
socket.on(Socket.EVENT_DISCONNECT, onDisconnect); // indicates disconnect

socket.connect();
```

### Send Message

```as3
socket.send({"text" : "Hello!", "from" : ${CURRENT_USER_ID}}, 
  function(error:Object, data:Object = null):void
  {
    if (error == null)
    {
      // message sent, "data" is object that server sent as response
    }
    else
    {
      // some error occurs, "error" could contains mmore info about error
    }
  });
```

### Receive Message

```as3
socket.on(Socket.EVENT_MESSAGE, 
  function(json:String):void
  {
    // "json" contains message from other client
  });
```
