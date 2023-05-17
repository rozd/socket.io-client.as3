/**
 * Created by max.rozdobudko@gmail.com on 5/16/23.
 */
package skein.engine.io.client.transport.websocket {
public interface WebSocketClientDataSource {

    function webSocketClientID(): int;
    function webSocketClientHostname(): String;
    function webSocketClientOrigin(): String;
    function webSocketClientCookie(): String;

}
}
