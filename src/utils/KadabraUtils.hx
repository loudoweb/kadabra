package utils;

import feathers.graphics.LineStyle;
import openfl.display.PixelSnapping;
import openfl.display.Bitmap;
import openfl.utils.Assets;
import feathers.text.TextFormat;
import feathers.graphics.FillStyle;

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

	public static function initFonts(regular:String):Void
	{
		FONT = Assets.getFont(regular).fontName;
		HEADER_FORMAT = new TextFormat(FONT, HEADER_FONT_SIZE, HEADER_FONT_COLOR);
	}

	inline public static function getIcon(name:String):Bitmap
	{
		return new Bitmap(Assets.getBitmapData("icons/" + name + ".png"), PixelSnapping.ALWAYS, true);
	}
}
