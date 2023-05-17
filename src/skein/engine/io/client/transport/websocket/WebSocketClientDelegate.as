/**
 * Created by max.rozdobudko@gmail.com on 11/12/17.
 */
package skein.engine.io.client.transport.websocket {
public interface WebSocketClientDelegate {

    function webSocketClientDidOpen(): void;
    function webSocketClientDidClose(): void;
    function webSocketClientDidError(): void;
    function webSocketClientDidMessage(message: String): void;
}
}
