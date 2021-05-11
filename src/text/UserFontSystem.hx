package text;

import lime.system.System;
import openfl.utils.Assets;
import openfl.text.Font;
import sys.FileSystem;

/**
 * Allow to get all installed fonts and cache the used ones.
 * 
 */
class UserFontSystem
{
	static var FONT_SYSTEM_FOLDER(default, null):String = System.fontsDirectory;

	/**
	 * Store all fonts used by the user in his application
	 */
	static var usedFonts:Array<String> = [];

	/**
	 * Get all installed fonts in the user operating system
	 * @return Array<String> file name
	 */
	inline public static function getAllFonts():Array<String>
	{
		// return Font.enumerateFonts(true);  //waiting for openfl fix
		// TODO sort and return only ttf for max compatibilities

		return FileSystem.readDirectory(FONT_SYSTEM_FOLDER);
	}

	/**
	 * Allow to store installed fonts into application cache
	 * @param file file name
	 * @return String return the id of the font
	 */
	inline public static function getUserFont(file:String):String
	{
		var font = Font.fromFile(FONT_SYSTEM_FOLDER + file);
		Font.registerFont(font);
		Assets.cache.setFont(file, font);
		usedFonts.push(file);
		return font.fontName;
	}
}
