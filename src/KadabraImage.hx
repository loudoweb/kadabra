import motion.easing.Quad;
import motion.Actuate;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.PixelSnapping;
import openfl.display.Sprite;
import openfl.Assets;

class KadabraImage extends Sprite
{
	public var moving:Bool;
	public var removed:Bool;
	public var row:Int;
	public var type:Int;

	public var isSelected:Bool;

	public var image:Bitmap;

	public var defaultHeight:Float;
	public var defaultWidth:Float;
	public var defaultX:Float;
	public var defaultY:Float;

	public var pivotX:Float;
	public var pivotY:Float;

	public function new(bitmapdata:BitmapData)
	{
		super();

		isSelected = true;

		pivotX = 0;
		pivotY = 0;

		image = new Bitmap(bitmapdata, PixelSnapping.ALWAYS, true);
		addChild(image);

		defaultHeight = image.height;
		defaultWidth = image.width;
		defaultX = x;
		defaultY = y;
	}

	// public function FromPath (imagePath:String) {
	//
	//	var bitmapdata = Assets.getBitmapData (imagePath);
	//	return new KadabraImage(bitmapdata);
	//
	// }

	public function initialize():Void
	{
		mouseEnabled = true;

		scaleX = 1;
		scaleY = 1;
		alpha = 1;
	}

	public function select():Void
	{
		if (!isSelected)
		{
			isSelected = true;
		}
	}

	public function unselect():Void
	{
		if (isSelected)
		{
			isSelected = false;
		}
	}
}
