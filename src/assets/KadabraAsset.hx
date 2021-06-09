package assets;

import openfl.display.Sprite;

class KadabraAsset extends Sprite
{
	public var isSelected:Bool;
	public var type(default, null):EKadabraAsset;

	public function new():Void
	{
		super();
		select();
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
