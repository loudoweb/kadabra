import openfl.geom.Transform;
import io.InputPoll;
import utils.KadabraUtils;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import lime.ui.MouseCursor;
import feathers.controls.ScrollContainer;
import openfl.geom.Point;
import feathers.skins.RectangleSkin;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.system.Capabilities;
import openfl.Assets;
import openfl.Lib;

/**
 * Handle Canvas: drop file, selection, scale,...
 * TODO: create TransformTool class including all gizmo (managing gizmo rotation & position will be easier )
 * TODO: factorize using rotation gizmo as pivot and rotation (https://github.com/loudoweb/SpriterHaxeEngine/blob/master/spriter/library/TilemapLibrary.hx#L88-L100)
 * TODO: use InputPoll for all events (modify InputPoll if needed) except for CLICK. add mouse move listener only if needed.
 * TODO: use enum to know what is selected (IMAGE, TEXTFIELD, SHAPE, POINT...)
 * TODO: add pivot (and use it only for rotation)
 * TODO: replace selectedImages with selectedAssets
 */
class KadabraScene extends Sprite
{
	public var background:RectangleSkin;

	var imageContainer:Sprite;

	public var offsets:Array<Float>;

	var gizmoOffsetX:Float;
	var gizmoOffsetY:Float;

	public var selectedAssets:List<KadabraImage>;

	public var dragging = false;

	var transformTool:TransformTool;

	var upOrigin:Float;
	var downOrigin:Float;
	var leftOrigin:Float;
	var rightOrigin:Float;

	var currentGizmo:Gizmo;

	var scaleDone = false;
	var forceCalcul = false;

	var ratio:Float;

	public var scrollX:Float;
	public var scrollY:Float;
	public var scrollSpeedX = 0.;
	public var scrollSpeedY = 0.;

	inline static var scrollSpeedXDivisor = 10;
	inline static var scrollSpeedYDivisor = 5;

	public function new()
	{
		super();

		initialize();
		construct();
	}

	private function construct():Void
	{
		/////Scene dimensions/////
		///////////////////////////
		background = new RectangleSkin();
		background.width = 1920;
		background.height = 1080;
		background.fill = KadabraUtils.SCENE_FILL;
		background.mouseEnabled = false;

		addChild(background);

		addChild(imageContainer);

		addEventListener(Event.ADDED_TO_STAGE, onAddedtoStage);
	}

	private function initialize():Void
	{
		imageContainer = new Sprite();

		offsets = [];
		selectedAssets = new List<KadabraImage>();

		transformTool = new TransformTool();
	}

	private function onAddedtoStage(event:Event)
	{
		stage.window.onDropFile.add(dragNDrop);
		InputPoll.onMouseDown.add(startDragging);
		InputPoll.onMouseUp.add(stopDragging);

		stage.addEventListener(MouseEvent.CLICK, selectImage, true);

		stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, onMouseUp);
	}

	private function dragNDrop(path:String)
	{
		// Add an image object when an image file is dropped in the window
		BitmapData.loadFromFile(path).onComplete(function(bitmapdata)
		{
			var image = new KadabraImage(bitmapdata);
			imageContainer.addChild(image);
			var splitPath = path.split("\\");
			image.name = splitPath[splitPath.length - 1];

			for (image in selectedAssets)
			{
				image.unselect();
			}
			selectedAssets.clear();
			selectedAssets.add(image);
			selectedAssets.last().select();

			var imagePoint = new Point(stage.mouseX, stage.mouseY);
			imagePoint = globalToLocal(imagePoint);

			image.x = imagePoint.x;
			image.y = imagePoint.y;

			offsets = [];
			offsets.push((x + parent.parent.x + image.width / 2 - scrollX) * scaleX);
			offsets.push((y + parent.parent.parent.y + image.height / 2 - scrollY) * scaleY);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragImage);
		});
	}

	private function startDragging(event:MouseEvent):Void
	{
		if (Std.is(event.target, KadabraImage))
		{
			if (selectedAssets.isEmpty())
			{
				selectedAssets.add(cast(event.target, KadabraImage));
				selectedAssets.last().select();
			}

			if (!event.shiftKey)
			{ // if Shift is pressed while clicking an image, it is added to the selection
				if ((selectedAssets.filter(function(image)
				{
					return (image == cast(event.target, KadabraImage));
				})).isEmpty())
				{
					for (image in selectedAssets)
					{
						image.unselect();
					}
					selectedAssets.clear();
					selectedAssets.add(cast(event.target, KadabraImage));
					selectedAssets.last().select();
				}
			}

			for (image in selectedAssets)
			{
				offsets.push(event.stageX / scaleX - image.x);
				offsets.push(event.stageY / scaleY - image.y);
			}

			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragImage);
		}
		else if (Std.is(event.target, Gizmo))
		{
			currentGizmo = cast(event.target, Gizmo);
			gizmoOffsetX = event.stageX / scaleX - (currentGizmo.x + transformTool.x);
			gizmoOffsetY = event.stageY / scaleY - (currentGizmo.y + transformTool.y);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, scale);
		}
	}

	private function stopDragging(event:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragImage);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, scale);
		offsets = [];

		for (image in selectedAssets)
		{
			image.defaultHeight = image.height;
			image.defaultWidth = image.width;
			image.defaultX = image.x;
			image.defaultY = image.y;
		}

		updateGizmos();
	}

	private function dragImage(event:MouseEvent):Void
	{
		if (!dragging)
		{
			dragging = true;

			removeChild(transformTool);
		}

		var containerPoint = new Point(scrollX, scrollY);
		containerPoint = parent.localToGlobal(containerPoint);

		if (event.stageX < containerPoint.x)
		{
			// stage.window.warpMouse(Std.int(containerPoint.x), Std.int(event.stageY));
			scrollSpeedX = (event.stageX - containerPoint.x) / scrollSpeedXDivisor;
		}
		else if (event.stageX > containerPoint.x + parent.parent.width)
		{
			// stage.window.warpMouse(Std.int(containerPoint.x + parent.parent.width), Std.int(event.stageY));
			scrollSpeedX = (event.stageX - (containerPoint.x + parent.parent.width)) / scrollSpeedXDivisor;
		}
		else
		{
			scrollSpeedX = 0;
		}

		if (event.stageY < containerPoint.y)
		{
			// stage.window.warpMouse(Std.int(event.stageX), Std.int(containerPoint.y));
			scrollSpeedY = (event.stageY - containerPoint.y) / scrollSpeedYDivisor;
		}
		else if (event.stageY > containerPoint.y + parent.parent.height)
		{
			// stage.window.warpMouse(Std.int(event.stageX), Std.int(containerPoint.y + parent.parent.height));
			scrollSpeedY = (event.stageY - (containerPoint.y + parent.parent.height)) / scrollSpeedYDivisor;
		}
		else
		{
			scrollSpeedY = 0;
		}

		var i = 0;
		for (image in selectedAssets)
		{
			image.x = event.stageX / scaleX - offsets[i * 2];
			image.y = event.stageY / scaleY - offsets[i * 2 + 1];

			if (image.x < -x)
			{
				image.x = -x;
			}
			else if (image.x + image.width > background.width + x)
			{
				image.x = background.width + x - image.width;
			}

			if (image.y < -y)
			{
				image.y = -y;
			}
			else if (image.y + image.height > background.height + y)
			{
				image.y = background.height + y - image.height;
			}

			++i;
		}

		event.updateAfterEvent();
	}

	function upSide(x:Float, y:Float, a:Point, b:Point)
	{
		return ((b.y - a.y) * (x - a.x) - (b.x - a.x) * (y - a.y)) >= 0;
	}

	private function scale(event:MouseEvent):Void
	{
		var coef = currentGizmo.vertical * currentGizmo.horizontal;
		if (coef != 0)
		{ // if coef != 0, currentGizmo is a corner
			if (!event.altKey)
			{ // preserving proportions
				var aPoint = new Point(0, 0);
				var bPoint = new Point(0, 0);
				if (coef < 0)
				{
					aPoint = new Point(transformTool.x, transformTool.y + transformTool.gizmosHeight);
					bPoint = new Point(transformTool.x + transformTool.gizmosWidth, transformTool.y);
				}
				else if (coef > 0)
				{
					aPoint = new Point(transformTool.x, transformTool.y);
					bPoint = new Point(transformTool.x + transformTool.gizmosWidth,
						transformTool.y + transformTool.gizmosHeight);
				}

				if (currentGizmo.vertical < 0)
				{ // is an Up gizmo
					if (!upSide(event.stageX / scaleX - gizmoOffsetX, event.stageY / scaleY - gizmoOffsetY, aPoint,
						bPoint))
					{
						var oldUpOrigin = upOrigin;
						upOrigin = event.stageY / scaleY - gizmoOffsetY;

						if (upOrigin >= downOrigin)
						{ // minimum scale
							upOrigin = downOrigin - 0.1;
						}

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (upOrigin - oldUpOrigin) / ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							rightOrigin -= (upOrigin - oldUpOrigin) / ratio;
						}
					}
					else
					{
						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							var oldLeftOrigin = leftOrigin;
							leftOrigin = event.stageX / scaleX - gizmoOffsetX;

							if (leftOrigin >= rightOrigin)
							{ // minimum scale
								leftOrigin = rightOrigin - 0.1;
							}

							upOrigin += (leftOrigin - oldLeftOrigin) * ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = event.stageX / scaleX - gizmoOffsetX;

							if (rightOrigin <= leftOrigin)
							{ // minimum scale
								rightOrigin = leftOrigin + 0.1;
							}

							upOrigin += (oldRightOrigin - rightOrigin) * ratio;
						}
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					if (upSide(event.stageX / scaleX - gizmoOffsetX, event.stageY / scaleY - gizmoOffsetY, aPoint,
						bPoint))
					{
						var oldDownOrigin = downOrigin;
						downOrigin = event.stageY / scaleY - gizmoOffsetY;

						if (downOrigin <= upOrigin)
						{ // minimum scale
							downOrigin = upOrigin + 0.1;
						}

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (oldDownOrigin - downOrigin) / ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							rightOrigin -= (oldDownOrigin - downOrigin) / ratio;
						}
					}
					else
					{
						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							var oldLeftOrigin = leftOrigin;
							leftOrigin = event.stageX / scaleX - gizmoOffsetX;

							if (leftOrigin >= rightOrigin)
							{ // minimum scale
								leftOrigin = rightOrigin - 0.1;
							}

							downOrigin -= (leftOrigin - oldLeftOrigin) * ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = event.stageX / scaleX - gizmoOffsetX;

							if (rightOrigin <= leftOrigin)
							{ // minimum scale
								rightOrigin = leftOrigin + 0.1;
							}

							downOrigin -= (oldRightOrigin - rightOrigin) * ratio;
						}
					}
				}
			}
			else
			{ // not preserving proportions
				if (currentGizmo.vertical < 0)
				{ // is an Up gizmo
					upOrigin = event.stageY / scaleY - gizmoOffsetY;

					if (upOrigin >= downOrigin)
					{
						upOrigin = downOrigin - 0.1;
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					downOrigin = event.stageY / scaleY - gizmoOffsetY;

					if (downOrigin <= upOrigin)
					{
						downOrigin = upOrigin + 0.1;
					}
				}

				if (currentGizmo.horizontal < 0)
				{ // is a Left gizmo
					leftOrigin = event.stageX / scaleX - gizmoOffsetX;

					if (leftOrigin >= rightOrigin)
					{
						leftOrigin = rightOrigin - 0.1;
					}
				}
				else if (currentGizmo.horizontal > 0)
				{ // is a Right gizmo
					rightOrigin = event.stageX / scaleX - gizmoOffsetX;

					if (rightOrigin <= leftOrigin)
					{
						rightOrigin = leftOrigin + 0.1;
					}
				}
			}
		}
		else
		{ // gizmo has only one direction
			if (currentGizmo.vertical < 0)
			{ // is an Up gizmo
				upOrigin = event.stageY / scaleY - gizmoOffsetY;

				if (upOrigin >= downOrigin)
				{
					upOrigin = downOrigin - 0.1;
				}
			}
			else if (currentGizmo.vertical > 0)
			{ // is a Down gizmo
				downOrigin = event.stageY / scaleY - gizmoOffsetY;

				if (downOrigin <= upOrigin)
				{
					downOrigin = upOrigin + 0.1;
				}
			}
			else if (currentGizmo.horizontal < 0)
			{ // is a Left gizmo
				leftOrigin = event.stageX / scaleX - gizmoOffsetX;

				if (leftOrigin >= rightOrigin)
				{
					leftOrigin = rightOrigin - 0.1;
				}
			}
			else if (currentGizmo.horizontal > 0)
			{ // is a Down gizmo
				rightOrigin = event.stageX / scaleX - gizmoOffsetX;

				if (rightOrigin <= leftOrigin)
				{
					rightOrigin = leftOrigin + 0.1;
				}
			}
		}

		var oldGizmosHeight = transformTool.gizmosHeight;
		var oldGizmosWidth = transformTool.gizmosWidth;
		transformTool.gizmosHeight = downOrigin - upOrigin;
		transformTool.gizmosWidth = rightOrigin - leftOrigin;

		transformTool.updateGizmos();

		transformTool.x = leftOrigin;
		transformTool.y = upOrigin;

		for (image in selectedAssets)
		{
			image.height *= transformTool.gizmosHeight / oldGizmosHeight;
			image.y = upOrigin;
			image.width *= transformTool.gizmosWidth / oldGizmosWidth;
			image.x = leftOrigin;
		}

		event.updateAfterEvent();
	}

	private function selectImage(event:MouseEvent):Void
	{
		if (!dragging)
		{
			if (Std.is(event.target, KadabraImage))
			{
				if (event.shiftKey)
				{
					if (!(cast(event.target, KadabraImage)).isSelected)
					{
						selectedAssets.add(cast(event.target, KadabraImage));
						selectedAssets.last().select();
					}
				}
				else
				{
					for (image in selectedAssets)
					{
						image.unselect();
					}
					selectedAssets.clear();
					selectedAssets.add(cast(event.target, KadabraImage));
					selectedAssets.last().select();
				}
			}
			else if (!Std.is(event.target, Gizmo))
			{
				for (image in selectedAssets)
				{
					image.unselect();
				}
				selectedAssets.clear();
			}
			updateGizmos();
		}
		else
		{
			dragging = false;
		}
	}

	private function updateGizmos()
	{ // puts gizmos on the corners and in the middle of the sides of the selection
		if (selectedAssets.isEmpty())
		{
			removeChild(transformTool);
		}
		else
		{
			addChild(transformTool);

			upOrigin = stage.height;
			downOrigin = -800;
			leftOrigin = stage.width;
			rightOrigin = -800;

			for (image in selectedAssets)
			{ // determines bounds of the selection
				if (image.y < upOrigin)
				{
					upOrigin = image.y;
				}
				if (image.y + image.height > downOrigin)
				{
					downOrigin = image.y + image.height;
				}
				if (image.x < leftOrigin)
				{
					leftOrigin = image.x;
				}
				if (image.x + image.width > rightOrigin)
				{
					rightOrigin = image.x + image.width;
				}
			}

			transformTool.gizmosHeight = downOrigin - upOrigin;
			transformTool.gizmosWidth = rightOrigin - leftOrigin;

			ratio = transformTool.gizmosHeight / transformTool.gizmosWidth;

			transformTool.updateGizmos();

			transformTool.x = leftOrigin;
			transformTool.y = upOrigin;
		}
	}

	function onMouseUp(e:MouseEvent)
	{
		dragging = false;
	}
}
