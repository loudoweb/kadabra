package io;

import haxe.ds.IntMap;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.display.Stage;
import lime.app.Event;

class InputPoll
{
	public static var isMouseDown(default, null):Bool;
	public static var isMouseJustPressed(default, null):Bool;
	public static var isMouseJustReleased(default, null):Bool;

	public static var isMouseRightDown(default, null):Bool;
	public static var isMouseRightJustPressed(default, null):Bool;
	public static var isMouseRightJustReleased(default, null):Bool;

	public static var isMouseMiddleDown(default, null):Bool;
	public static var isMouseMiddleJustPressed(default, null):Bool;
	public static var isMouseMiddleJustReleased(default, null):Bool;

	public static var onMouseDown:Event<MouseEvent->Void>;
	public static var onMouseUp:Event<MouseEvent->Void>;

	public static var onKeyDown:Event<KKey->Void>;
	public static var onKeyUp:Event<KKey->Void>;

	public static var wheel(default, null):Float;

	static var _stage:Stage;
	static var _isWheeling:Bool;
	static var _keys:IntMap<KKey>;

	public static function init(stage:Stage):Void
	{
		_stage = stage;

		_isWheeling = false;
		wheel = 0;
		_keys = new IntMap<KKey>();
		isMouseDown = false;
		isMouseJustPressed = false;
		isMouseJustReleased = false;
		isMouseRightDown = false;
		isMouseRightJustPressed = false;
		isMouseRightJustReleased = false;
		isMouseMiddleDown = false;
		isMouseMiddleJustPressed = false;
		isMouseMiddleJustReleased = false;

		onMouseDown = new Event<MouseEvent->Void>();
		onMouseUp = new Event<MouseEvent->Void>();

		onKeyDown = new Event<KKey->Void>();
		onKeyUp = new Event<KKey->Void>();

		_stage.addEventListener(MouseEvent.MOUSE_DOWN, _onMouseDown);
		_stage.addEventListener(MouseEvent.MOUSE_UP, _onMouseUp);

		_stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, _onMouseDown);
		_stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, _onMouseUp);

		_stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, _onMouseDown);
		_stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, _onMouseUp);

		_stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, _onMouseLeave);
		_stage.addEventListener(MouseEvent.MOUSE_WHEEL, _onMouseWheel);

		_stage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown);
		_stage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp);
	}

	/**
	 * Must be the last component to be updated
	 */
	public static function update():Void
	{
		// update left mouse
		if (isMouseJustPressed)
			isMouseJustPressed = false;
		if (isMouseJustReleased)
			isMouseJustReleased = false;
		// update right mouse
		if (isMouseRightJustPressed)
			isMouseRightJustPressed = false;
		if (isMouseRightJustReleased)
			isMouseRightJustReleased = false;
		// update right mouse
		if (isMouseMiddleJustPressed)
			isMouseMiddleJustPressed = false;
		if (isMouseMiddleJustReleased)
			isMouseMiddleJustReleased = false;

		if (_isWheeling)
		{
			_isWheeling = false;
			wheel = 0;
		}

		for (kkey in _keys)
		{
			kkey.update();
		}
	}

	public static function getKey(keyCode:Int):KKey
	{
		var key = _keys.get(keyCode);
		if (key != null)
		{
			return key;
		}
		return null;
	}

	public static function isKeyDown(keyCode:Int):Bool
	{
		var key = _keys.get(keyCode);
		if (key != null)
		{
			return key.isDown;
		}
		return false;
	}

	public static function areKeysDown(keyCodes:Array<Int>):Bool
	{
		for (keyCode in keyCodes)
		{
			var key = _keys.get(keyCode);
			if (key == null || !key.isDown)
			{
				return false;
			}
		}

		return true;
	}

	static function _onKeyDown(e:KeyboardEvent):Void
	{
		var key = null;
		if (_keys.exists(e.keyCode))
		{
			_keys.get(e.keyCode)
				.down();
		} else
		{
			_keys.set(e.keyCode, new KKey(e.keyCode, e.charCode));
		}
	}

	static function _onKeyUp(e:KeyboardEvent):Void
	{
		if (_keys.exists(e.keyCode))
		{
			_keys.get(e.keyCode)
				.up();
		} else
		{
			_keys.set(e.keyCode, new KKey(e.keyCode, e.charCode));
		}
	}

	static function _onMouseDown(e:MouseEvent):Void
	{
		switch (e.type)
		{
			case MouseEvent.RIGHT_MOUSE_DOWN:
				isMouseRightDown = true;
				isMouseRightJustPressed = true;
			case MouseEvent.MIDDLE_MOUSE_DOWN:
				isMouseMiddleDown = true;
				isMouseMiddleJustPressed = true;
			default:
				isMouseDown = true;
				isMouseJustPressed = true;
				onMouseDown.dispatch(e);
		}
	}

	static function _onMouseUp(e:MouseEvent):Void
	{
		switch (e.type)
		{
			case MouseEvent.RIGHT_MOUSE_UP:
				isMouseRightDown = false;
				isMouseRightJustReleased = true;
			case MouseEvent.MIDDLE_MOUSE_UP:
				isMouseMiddleDown = false;
				isMouseMiddleJustReleased = true;
			default:
				isMouseDown = false;
				isMouseJustReleased = true;
				onMouseUp.dispatch(e);
		}
	}

	static function _onMouseLeave(e:MouseEvent):Void
	{
		if (isMouseDown)
		{
			isMouseDown = false;
			isMouseJustReleased = true;
		}
		if (isMouseRightDown)
		{
			isMouseRightDown = false;
			isMouseRightJustReleased = true;
		}
		if (isMouseMiddleDown)
		{
			isMouseMiddleDown = false;
			isMouseMiddleJustReleased = true;
		}
	}

	static function _onMouseWheel(e:MouseEvent):Void
	{
		_isWheeling = true;
		wheel = e.delta;
	}
}

class KKey
{
	public var keyCode:Int;
	public var charCode:Int;

	public var isDown:Bool;
	public var isJustPressed:Bool;
	public var isJustReleased:Bool;

	public function new(keyCode:Int, charCode:Int, firstPressed:Bool = true)
	{
		this.keyCode = keyCode;
		this.charCode = charCode;
		if (firstPressed)
		{
			isDown = true;
			isJustPressed = true;
		}
		isJustReleased = false;
	}

	inline public function down():Void
	{
		isDown = true;
		isJustPressed = true;
		InputPoll.onKeyDown.dispatch(this);
	}

	inline public function up():Void
	{
		isDown = false;
		isJustReleased = true;
		InputPoll.onKeyUp.dispatch(this);
	}

	inline public function update():Void
	{
		if (isJustPressed)
		{
			isJustPressed = false;
		}
		if (isJustReleased)
		{
			isJustReleased = false;
		}
	}

	inline public function reset():Void
	{
		isDown = false;
		isJustPressed = false;
		isJustReleased = false;
	}
}
