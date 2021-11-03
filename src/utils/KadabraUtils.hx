package utils;

import feathers.graphics.LineStyle;
import openfl.display.PixelSnapping;
import openfl.display.Bitmap;
import openfl.utils.Assets;
import feathers.text.TextFormat;
import feathers.graphics.FillStyle;
import openfl.geom.Point;

class KadabraUtils
{
	inline public static var KADABRA_COLOR = 0xEB7D42;
	inline public static var HEADER_THICKNESS = 30;
	inline public static var HEADER_FONT_SIZE = 20;
	inline public static var HEADER_FONT_COLOR = 0xFFFFFF;

	public static var HEADER_FILL = SolidColor(0x262626);
	public static var CANVAS_FILL = SolidColor(0x333333);
	public static var WINDOW_FILL = SolidColor(0x404040);
	public static var SCENE_FILL = SolidColor(0xCCCCCC);

	public static var HEADER_BORDER = LineStyle.SolidColor(2, KADABRA_COLOR);

	public static var ICON_FILL:FillStyle = None;
	public static var ICON_BORDER:LineStyle = None;
	public static var SELECTED_FILL = SolidColor(KADABRA_COLOR);

	public static var HOVER_FILL = SolidColor(KADABRA_COLOR);

	public static var FONT:String;
	public static var HEADER_FORMAT:TextFormat;

	public static var DEBUG_RED = SolidColor(0xFF0000);
	public static var DEBUG_BLUE = SolidColor(0x0000FF);

	public static var FONT_NORMAL = new feathers.text.TextFormat("Roboto", 20, HEADER_FONT_COLOR);

	public static function initFonts(regular:String):Void
	{
		FONT = Assets.getFont(regular).fontName;
		HEADER_FORMAT = new TextFormat(FONT, HEADER_FONT_SIZE, HEADER_FONT_COLOR);
	}

	inline public static function getIcon(name:String):Bitmap
	{
		return new Bitmap(Assets.getBitmapData("icons/" + name + ".png"), PixelSnapping.ALWAYS, true);
	}

	inline static public function toRadians(deg:Float):Float
	{
		return deg * Math.PI / 180;
	}

	inline static public function toDegree(rad:Float):Float
	{
		return rad * 180 / Math.PI;
	}

	inline static public function bound(value:Float, min:Float = 0, max:Float = 1):Float
	{
		value = (value < min) ? min : value;
		return (value > max) ? max : value;
	}

	inline static public function roundDecimal(value:Float, precision:Int):Float
	{
		var mult:Float = 1;
		for (i in 0...precision)
		{
			mult *= 10;
		}
		return Math.fround(value * mult) / mult;
	}

	inline static public function sign(value:Float):Int
	{
		if (value >= 0)
			return 1;
		return -1;
	}

	/**
	 * Get corrected position of sprite depending of rotation and pivot
	 * @param x 
	 * @param y 
	 * @param angle degrees
	 * @param width 
	 * @param height 
	 * @param pivotX [0,1]
	 * @param pivotY [0,1]
	 * @return Point position of 
	 */
	inline static public function getOrigin(x:Float, y:Float, angle:Float, width:Float, height:Float,
			pivotX:Float = 0, pivotY:Float = 0):Point
	{
		var rad = toRadians(angle);
		var s = Math.sin(rad);
		var c = Math.cos(rad);

		var _pivotX = pivotX * width;
		var _pivotY = pivotY * height;

		return new Point((0 - _pivotX) * c - (0 - _pivotY) * s + x, (0 - _pivotX) * s + (0 - _pivotY) * c + y);
	}
}
