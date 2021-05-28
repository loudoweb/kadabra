import lime.ui.KeyCode;
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

	var defaultX:Float;
	var defaultY:Float;

	var radianRotation:Float;
	var cosinus:Float;
	var sinus:Float;

	public var selectedAssets:List<KadabraImage>;

	public var dragging = false;
	public var scaling = false;

	var transformTool:TransformTool;

	var upOrigin:Float;
	var downOrigin:Float;
	var leftOrigin:Float;
	var rightOrigin:Float;

	var currentGizmo:Gizmo;

	var scaleDone = false;
	var forceCalcul = false;

	var defaultAngle:Float;

	var pivotEnabled = true;

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

		InputPoll.onKeyDown.add(togglePivot);
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

			radianRotation = selectedAssets.first().rotation * Math.PI / 180;
			cosinus = Math.cos(radianRotation);
			sinus = Math.sin(radianRotation);

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

			// if (!event.shiftKey)
			// { // if Shift is pressed while clicking an image, it is added to the selection
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

				radianRotation = selectedAssets.first().rotation * Math.PI / 180;
				cosinus = Math.cos(radianRotation);
				sinus = Math.sin(radianRotation);
			}
			// }

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
			var xValue = currentGizmo.x;
			var yValue = currentGizmo.y;

			if (currentGizmo.horizontal == 0 && currentGizmo.vertical == 0)
			{ // gizmo offsets depend on pivot coordinates only during rotation
				xValue -= transformTool.pivot.x;
				yValue -= transformTool.pivot.y;
			}

			gizmoOffsetX = event.stageX / scaleX - ((xValue) * cosinus - (yValue) * sinus);
			gizmoOffsetY = event.stageY / scaleY - ((xValue) * sinus + (yValue) * cosinus);

			defaultAngle = Math.atan((currentGizmo.x
				- transformTool.pivot.x) / (currentGizmo.y - transformTool.pivot.y));
			defaultX = selectedAssets.first().x + (transformTool.pivot.x * cosinus - transformTool.pivot.y * sinus);
			defaultY = selectedAssets.first().y + (transformTool.pivot.x * sinus + transformTool.pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, scale);
		}
		else if (Std.is(event.target, Pivot))
		{
			// gizmoOffsets are here used for the pivot
			gizmoOffsetX = event.stageX / scaleX - (transformTool.pivot.x * cosinus - transformTool.pivot.y * sinus);
			gizmoOffsetY = event.stageY / scaleY - (transformTool.pivot.x * sinus + transformTool.pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragPivot);
		}
	}

	private function stopDragging(event:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragImage);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, scale);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragPivot);
		offsets = [];

		if (!selectedAssets.isEmpty())
		{
			for (image in selectedAssets)
			{
				image.defaultHeight = image.height;
				image.defaultWidth = image.width;
				image.defaultX = image.x;
				image.defaultY = image.y;
			}

			updateGizmos();
		}
	}

	private function dragImage(event:MouseEvent):Void
	{
		if (!dragging)
		{
			dragging = true;

			selectedAssets.first().removeChild(transformTool);
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
		if (!scaling)
		{
			scaling = true;
		}

		var coef = currentGizmo.vertical * currentGizmo.horizontal;
		if (coef != 0)
		{ // if coef != 0, currentGizmo is a corner
			if (!event.altKey)
			{ // preserving proportions
				var aPoint = new Point(0, 0);
				var bPoint = new Point(0, 0);

				if (coef < 0)
				{
					aPoint = new Point(transformTool.gizmosHeight * sinus, transformTool.gizmosHeight * cosinus);
					bPoint = new Point(transformTool.gizmosWidth * cosinus, transformTool.gizmosWidth * sinus);
				}
				else if (coef > 0)
				{
					aPoint = new Point(transformTool.x, transformTool.y);
					bPoint = new Point(transformTool.gizmosWidth * cosinus - transformTool.gizmosHeight * sinus,
						transformTool.gizmosHeight * cosinus + transformTool.gizmosWidth * sinus);
				}

				if (currentGizmo.vertical < 0)
				{ // is an Up gizmo
					if (!upSide(event.stageX / scaleX - gizmoOffsetX, event.stageY / scaleY - gizmoOffsetY, aPoint,
						bPoint))
					{
						var oldUpOrigin = upOrigin;
						upOrigin = (event.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (event.stageX / scaleX - gizmoOffsetX) * sinus;
						gizmoOffsetY += upOrigin;

						if (upOrigin >= downOrigin)
						{ // minimum scale
							gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
							upOrigin = downOrigin - 0.1;
						}

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (upOrigin - oldUpOrigin) / ratio;
							gizmoOffsetX += leftOrigin;
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
							leftOrigin = (event.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (event.stageY / scaleY - gizmoOffsetY) * sinus;
							gizmoOffsetX += leftOrigin;

							if (leftOrigin >= rightOrigin)
							{ // minimum scale
								gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
								leftOrigin = rightOrigin - 0.1;
							}

							upOrigin += (leftOrigin - oldLeftOrigin) * ratio;
							gizmoOffsetY += upOrigin;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = (event.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (event.stageY / scaleY - gizmoOffsetY) * sinus;

							if (rightOrigin <= leftOrigin)
							{ // minimum scale
								rightOrigin = leftOrigin + 0.1;
							}

							upOrigin += (oldRightOrigin - rightOrigin) * ratio;
							gizmoOffsetY += upOrigin;
						}
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					if (upSide(event.stageX / scaleX - gizmoOffsetX, event.stageY / scaleY - gizmoOffsetY, aPoint,
						bPoint))
					{
						var oldDownOrigin = downOrigin;
						downOrigin = (event.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (event.stageX / scaleX - gizmoOffsetX) * sinus;

						if (downOrigin <= upOrigin)
						{ // minimum scale
							downOrigin = upOrigin + 0.1;
						}

						if (currentGizmo.horizontal < 0)
						{ // is a Left gizmo
							leftOrigin += (oldDownOrigin - downOrigin) / ratio;
							gizmoOffsetX += leftOrigin;
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
							leftOrigin = (event.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (event.stageY / scaleY - gizmoOffsetY) * sinus;
							gizmoOffsetX += leftOrigin;

							if (leftOrigin >= rightOrigin)
							{ // minimum scale
								gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
								leftOrigin = rightOrigin - 0.1;
							}

							downOrigin -= (leftOrigin - oldLeftOrigin) * ratio;
						}
						else if (currentGizmo.horizontal > 0)
						{ // is a Right gizmo
							var oldRightOrigin = rightOrigin;
							rightOrigin = (event.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (event.stageY / scaleY - gizmoOffsetY) * sinus;

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
					upOrigin = (event.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (event.stageX / scaleX - gizmoOffsetX) * sinus;
					gizmoOffsetY += upOrigin;

					if (upOrigin >= downOrigin)
					{
						gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
						upOrigin = downOrigin - 0.1;
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					downOrigin = (event.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (event.stageX / scaleX - gizmoOffsetX) * sinus;

					if (downOrigin <= upOrigin)
					{
						downOrigin = upOrigin + 0.1;
					}
				}

				if (currentGizmo.horizontal < 0)
				{ // is a Left gizmo
					leftOrigin = (event.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (event.stageY / scaleY - gizmoOffsetY) * sinus;
					gizmoOffsetX += leftOrigin;

					if (leftOrigin >= rightOrigin)
					{
						gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
						leftOrigin = rightOrigin - 0.1;
					}
				}
				else if (currentGizmo.horizontal > 0)
				{ // is a Right gizmo
					rightOrigin = (event.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (event.stageY / scaleY - gizmoOffsetY) * sinus;

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
				upOrigin = (event.stageY / scaleY
					- gizmoOffsetY) * cosinus
					- (event.stageX / scaleX - gizmoOffsetX) * sinus;
				gizmoOffsetY += upOrigin;

				if (upOrigin >= downOrigin)
				{
					gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
					upOrigin = downOrigin - 0.1;
				}
			}
			else if (currentGizmo.vertical > 0)
			{ // is a Down gizmo
				downOrigin = (event.stageY / scaleY
					- gizmoOffsetY) * cosinus
					- (event.stageX / scaleX - gizmoOffsetX) * sinus;

				if (downOrigin <= upOrigin)
				{
					downOrigin = upOrigin + 0.1;
				}
			}
			else if (currentGizmo.horizontal < 0)
			{ // is a Left gizmo
				leftOrigin = (event.stageX / scaleX
					- gizmoOffsetX) * cosinus
					+ (event.stageY / scaleY - gizmoOffsetY) * sinus;
				gizmoOffsetX += leftOrigin;

				if (leftOrigin >= rightOrigin)
				{
					gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
					leftOrigin = rightOrigin - 0.1;
				}
			}
			else if (currentGizmo.horizontal > 0)
			{ // is a Right gizmo
				rightOrigin = (event.stageX / scaleX
					- gizmoOffsetX) * cosinus
					+ (event.stageY / scaleY - gizmoOffsetY) * sinus;

				if (rightOrigin <= leftOrigin)
				{
					rightOrigin = leftOrigin + 0.1;
				}
			}
			else
			{
				rotate(event);
			}
		}

		var oldGizmosHeight = transformTool.gizmosHeight;
		var oldGizmosWidth = transformTool.gizmosWidth;
		transformTool.gizmosHeight = downOrigin - upOrigin;
		transformTool.gizmosWidth = rightOrigin - leftOrigin;

		for (asset in selectedAssets)
		{ // image dimensions are adjusted and asset coordinates are changed to always keep upOrigin = LeftOrigin = 0
			asset.image.height *= transformTool.gizmosHeight / oldGizmosHeight;
			asset.y += upOrigin * cosinus + leftOrigin * sinus;
			downOrigin -= upOrigin;
			asset.image.width *= transformTool.gizmosWidth / oldGizmosWidth;
			asset.x += leftOrigin * cosinus - upOrigin * sinus;
			rightOrigin -= leftOrigin;
			upOrigin = 0;
			leftOrigin = 0;
		}

		transformTool.updateGizmos();

		transformTool.x = leftOrigin;
		transformTool.y = upOrigin;

		event.updateAfterEvent();
	}

	private function rotate(event:MouseEvent):Void
	{
		var newAngle = Math.atan((event.stageX / scaleX - gizmoOffsetX) / (event.stageY / scaleY - gizmoOffsetY));
		newAngle -= defaultAngle;
		newAngle *= 180 / Math.PI;

		if (event.stageY / scaleY - gizmoOffsetY >= 0)
		{ // adjusts the angle if the mouse is under the pivot
			newAngle += 180;
		}

		for (asset in selectedAssets)
		{
			asset.rotation = -newAngle;

			radianRotation = selectedAssets.first().rotation * Math.PI / 180;
			cosinus = Math.cos(radianRotation);
			sinus = Math.sin(radianRotation);

			asset.x = defaultX - transformTool.pivot.x * cosinus + transformTool.pivot.y * sinus;
			asset.y = defaultY - transformTool.pivot.x * sinus - transformTool.pivot.y * cosinus;
		}
	}

	private function dragPivot(event:MouseEvent):Void
	{
		if (!dragging)
		{
			dragging = true;
		}

		transformTool.pivot.x = (event.stageX / scaleX
			- gizmoOffsetX) * cosinus
			+ (event.stageY / scaleY - gizmoOffsetY) * sinus;
		transformTool.pivot.y = (event.stageY / scaleY
			- gizmoOffsetY) * cosinus
			- (event.stageX / scaleX - gizmoOffsetX) * sinus;

		// minimum & maximum positions
		if (transformTool.pivot.x < 0)
		{
			transformTool.pivot.x = 0;
		}
		else if (transformTool.pivot.x > transformTool.gizmosWidth)
		{
			transformTool.pivot.x = transformTool.gizmosWidth;
		}

		if (transformTool.pivot.y < 0)
		{
			transformTool.pivot.y = 0;
		}
		else if (transformTool.pivot.y > transformTool.gizmosHeight)
		{
			transformTool.pivot.y = transformTool.gizmosHeight;
		}

		transformTool.pivot.X = transformTool.pivot.x / transformTool.gizmosWidth;
		transformTool.pivot.Y = transformTool.pivot.y / transformTool.gizmosHeight;

		event.updateAfterEvent();
	}

	private function togglePivot(key:KKey):Void
	{
		if (key.charCode == KeyCode.P)
		{
			if (pivotEnabled)
			{
				transformTool.removeChild(transformTool.pivot);
				pivotEnabled = false;
			}
			else
			{
				transformTool.addChild(transformTool.pivot);
				pivotEnabled = true;
			}
		}
	}

	private function selectImage(event:MouseEvent):Void
	{
		if (!dragging && !scaling)
		{
			if (Std.is(event.target, KadabraImage))
			{
				// if (event.shiftKey)
				// {
				//	if (!(cast(event.target, KadabraImage)).isSelected)
				//	{
				//		selectedAssets.add(cast(event.target, KadabraImage));
				//		selectedAssets.last().select();
				//	}
				// }
				// else
				// {
				for (image in selectedAssets)
				{
					image.unselect();
				}
				selectedAssets.clear();
				selectedAssets.add(cast(event.target, KadabraImage));
				selectedAssets.last().select();

				radianRotation = selectedAssets.first().rotation * Math.PI / 180;
				cosinus = Math.cos(radianRotation);
				sinus = Math.sin(radianRotation);
				// }
			}
			else if (!Std.is(event.target, Gizmo))
			{
				if (!selectedAssets.isEmpty())
				{
					for (image in selectedAssets)
					{
						image.unselect();
					}
					selectedAssets.clear();

					updateGizmos();
				}
			}
		}
		else
		{
			dragging = false;
			scaling = false;
		}
	}

	private function updateGizmos()
	{ // puts gizmos on the corners and in the middle of the sides of the selection
		if (selectedAssets.isEmpty())
		{
			transformTool.parent.removeChild(transformTool);
		}
		else
		{
			selectedAssets.first().addChild(transformTool);

			upOrigin = stage.height;
			downOrigin = -800;
			leftOrigin = stage.width;
			rightOrigin = -800;

			for (image in selectedAssets)
			{ // determines bounds of the selection
				// if (image.y < upOrigin)
				// {
				//	upOrigin = image.y;
				// }
				// if (image.y + image.height > downOrigin)
				// {
				//	downOrigin = image.y + image.height;
				// }
				// if (image.x < leftOrigin)
				// {
				//	leftOrigin = image.x;
				// }
				// if (image.x + image.width > rightOrigin)
				// {
				//	rightOrigin = image.x + image.width;
				// }
				upOrigin = image.image.y;
				downOrigin = image.image.y + image.image.height;
				leftOrigin = image.image.x;
				rightOrigin = image.image.x + image.image.width;
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
