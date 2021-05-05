package io;
import openfl.display.PNGEncoderOptions;
import openfl.display.BitmapData;
#if cpp
import haxe.extension.*;
#else
import haxe.extension.EClipboard;
#end

class KadabraClipboard
{
    static var lastFetchedFormats:Array<String>;

    public static function count():Int
    {
        #if cpp
        return Clipboard.count_formats();
        #else
        return 0;
        #end
    }

    public static function fetch():Void
    {
        #if cpp
        var str = Clipboard.list_available_format();
        if(str != "" && str.toUpperCase() != "NULL")
        {
            lastFetchedFormats = str.split(",");
        }else{
            lastFetchedFormats = [];
        }
        trace(lastFetchedFormats);
        #end
    }

    public static function has(format:EClipboard, fetchNow = false):Bool {
        var _r = false;
        #if cpp
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
        #if cpp
        var str = Clipboard.get_data(format);
        return ClipboardUtils.getString(str, format);
        #else
        return "";
        #end
    }

    public static function getText():String
    {
        #if cpp
        return Clipboard.get_text();
        #else
        return "";
        #end
    }

    public static function getImage():BitmapData
    {
        var bd:BitmapData = null;
        #if cpp
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

    public static function clear():Void
    {
        #if cpp
        Clipboard.clear();
        #end
    }

    public static function setText(str:String):Void
    {
        #if cpp
        Clipboard.set_text(str);
        #end
    }

    public static function setHTMLText(str:String):Void
    {
        #if cpp
        Clipboard.set_data(EClipboard.HTML, ClipboardUtils.formatHTML(str));
        #end
    }

    public static function setSVGText(str:String):Void
    {
        #if cpp
        Clipboard.set_data(EClipboard.SVG, str);
        #end
    }

    public static function setImage(bitmap:BitmapData):Void
    {
        #if cpp
        var bytes = bitmap.encode(bitmap.rect, new PNGEncoderOptions(true) );
        Clipboard.set_image(bytes);
        #end
    }
}