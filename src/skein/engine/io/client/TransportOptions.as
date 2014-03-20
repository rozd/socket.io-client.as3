/**
 * Created with IntelliJ IDEA.
 * User: mobitile
 * Date: 2/27/14
 * Time: 9:24 PM
 * To change this template use File | Settings | File Templates.
 */
package skein.engine.io.client
{
public class TransportOptions
{
    public function TransportOptions()
    {
    }

    public var hostname:String;
    public var path:String;
    public var secure:Boolean;
    public var timestampParam:String;
    public var timestampRequests:Boolean;
    public var port:int;
    public var policyPort:int;
    public var query:Object;
}
}
