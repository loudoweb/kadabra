package sys;
import openfl.display.BitmapData;
#if windows
import haxe.extension.Clipboard;
import haxe.extension.EClipboard;
#end

class KadabraClipboard
{
    static var lastFetchedFormats:Array<String>;

    public static function count():Int
    {
        return Clipboard.count_formats();
    }

    public static function fetch():Void
    {
        var str = Clipboard.list_available_format();
        if(str != "")
        {
            lastFetchedFormats = str.split(",");
        }else{
            lastFetchedFormats = [];
        }
        trace(lastFetchedFormats);
    }

    public static function has(format:EClipboard, fetchNow = false):Bool {
        var _r = false;
        #if windows
        try{
            if(fetchNow || lastFetchedFormats == null)
                fetch();
            _r = lastFetchedFormats.indexOf(format) != -1;  

        }catch(e)
        {
            trace(e);
        }
        #end
        return _r;
    }

    public static function getString(format:EClipboard):String
    {
        #if windows
        var str = Clipboard.get_data(format);
        if(str != "")
        {
            switch(format)
            {
                case TYPE_HTML:
                    var begin = str.indexOf("<!--StartFragment-->");
                    var end = str.indexOf("<!--EndFragment-->");
                    return str.substring(begin + 20, end);
                case TYPE_SVG:
                    var end = str.indexOf("</svg>");
                    return str.substring(0, end + 6);
                default:
                    return str;
            }
        }
        #end
        return "";
    }

    public static function getText():String
    {
        #if windows
        return Clipboard.get_text();
        #end
        return "";
    }

    public static function getImage():BitmapData
    {
        var bd:BitmapData = null;
        #if windows
        var bytes = Clipboard.get_image();

        if(bytes != null && bytes.length > 0)
        {
            try{
                bd = BitmapData.fromBytes(bytes);
            }catch(e)
            {
                throw 'fail to import BitmapData: ' + e;
            }
        }
        #end
        return bd;
    }
}