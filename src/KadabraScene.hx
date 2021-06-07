import feathers.controls.TextInput;
import panels.PropertiesPanel;
import panels.ToolPanel;
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
import openfl.events.Event as OpenflEvent;
import openfl.events.MouseEvent;
import openfl.events.KeyboardEvent;
import openfl.system.Capabilities;
import openfl.Assets;
import openfl.Lib;
import lime.app.Event;

using utils.KadabraUtils;

/**
 * Handle Canvas: drop file, selection, scale,...
 * TODO: create TransformTool class including all gizmo (managing gizmo rotation & position will be easier )
 * TODO: factorize using rotation gizmo as pivot and rotation (https://github.com/loudoweb/SpriterHaxeEngine/blob/master/spriter/library/TilemapLibrary.hx#L88-L100)
 * TODO: use InputPoll for all es (modify InputPoll if needed) except for CLICK. add mouse move listener only if needed.
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

	public var selectedAssets:List<Sprite>;

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

	var draggedPoint:KadabraPoint;
	var pointsNumber = 0;

	public var scrollX:Float;
	public var scrollY:Float;
	public var scrollSpeedX = 0.;
	public var scrollSpeedY = 0.;

	inline static var scrollSpeedXDivisor = 10;
	inline static var scrollSpeedYDivisor = 5;

	public static var addedChild:Event<Sprite->Void>;
	public static var removedChild:Event<Sprite->Void>;
	public static var onSelectAsset:Event<Sprite->Void>;
	public static var onAssetUpdated:Event<Void->Void>;

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

		addEventListener(OpenflEvent.ADDED_TO_STAGE, onAddedtoStage);
	}

	private function initialize():Void
	{
		imageContainer = new Sprite();

		offsets = [];
		selectedAssets = new List<Sprite>();

		transformTool = new TransformTool();

		addedChild = new Event<Sprite->Void>();
		removedChild = new Event<Sprite->Void>();
		onSelectAsset = new Event<Sprite->Void>();
		onAssetUpdated = new Event<Void->Void>();
	}

	private function onAddedtoStage(e:OpenflEvent)
	{
		stage.window.onDropFile.add(dragNDrop);
		addEventListener(MouseEvent.MOUSE_DOWN, startDragging);
		stage.addEventListener(MouseEvent.MOUSE_UP, stopDragging);

		addEventListener(MouseEvent.CLICK, selectAsset, true);

		stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, onMouseUp);

		InputPoll.onKeyDown.add(onKeyDown);

		ToolPanel.onButtonChange.add(onButtonChange);

		PropertiesPanel.inputChange.add(onInputChange);
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

			addedChild.dispatch(image);

			for (asset in selectedAssets)
			{
				if (Std.is(asset, KadabraImage))
				{
					cast(asset, KadabraImage).unselect();
				}
				else if (Std.is(asset, KadabraPoint))
				{
					cast(asset, KadabraPoint).unselect();
				}
			}
			selectedAssets.clear();
			selectedAssets.add(image);
			cast(selectedAssets.last(), KadabraImage).select();

			onSelectAsset.dispatch(image);

			// default rotation
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
			dragging = true;

			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		});
	}

	private function startDragging(e:MouseEvent):Void
	{
		if (Std.is(e.target, KadabraImage))
		{
			if (selectedAssets.isEmpty())
			{
				selectedAssets.add(cast(e.target, KadabraImage));
				cast(selectedAssets.last(), KadabraImage).select();
			}

				// if (!e.shiftKey)
			// { // if Shift is pressed while clicking an image, it is added to the selection
			else if ((selectedAssets.filter(function(image)
			{ // if the clicked image is different from the selected object, it is selected
				return (image == cast(e.target, KadabraImage));
			})).isEmpty())
			{
				for (asset in selectedAssets)
				{
					if (Std.is(asset, KadabraImage))
					{
						cast(asset, KadabraImage).unselect();
					}
					else if (Std.is(asset, KadabraPoint))
					{
						cast(asset, KadabraPoint).unselect();
					}
				}
				selectedAssets.clear();
				selectedAssets.add(cast(e.target, KadabraImage));
				cast(selectedAssets.last(), KadabraImage).select();

				// default rotation
				radianRotation = selectedAssets.first().rotation * Math.PI / 180;
				cosinus = Math.cos(radianRotation);
				sinus = Math.sin(radianRotation);
			}
			// }
			for (image in selectedAssets)
			{
				offsets.push(e.stageX / scaleX - image.x);
				offsets.push(e.stageY / scaleY - image.y);
			}

			onSelectAsset.dispatch(selectedAssets.first());
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		}
		else if (Std.is(e.target, KadabraPoint))
		{
			if (selectedAssets.isEmpty())
			{
				selectedAssets.add(cast(e.target, KadabraPoint));
				cast(selectedAssets.last(), KadabraPoint).select();
			}
			else if ((selectedAssets.filter(function(image)
			{ // if the clicked point is different from the selected object, it is selected
				return (image == cast(e.target, KadabraPoint));
			})).isEmpty())
			{
				for (asset in selectedAssets)
				{
					if (Std.is(asset, KadabraImage))
					{
						cast(asset, KadabraImage).unselect();
					}
					else if (Std.is(asset, KadabraPoint))
					{
						cast(asset, KadabraPoint).unselect();
					}
				}
				selectedAssets.clear();
				selectedAssets.add(cast(e.target, KadabraPoint));
				cast(selectedAssets.last(), KadabraPoint).select();
			}

			onSelectAsset.dispatch(selectedAssets.first());
			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		}
		else if (Std.is(e.target, Gizmo))
		{
			currentGizmo = cast(e.target, Gizmo);
			var xValue = currentGizmo.x;
			var yValue = currentGizmo.y;

			if (currentGizmo.horizontal == 0 && currentGizmo.vertical == 0)
			{ // gizmo offsets depend on pivot coordinates only during rotation
				xValue -= transformTool.pivot.x;
				yValue -= transformTool.pivot.y;
			}

			gizmoOffsetX = e.stageX / scaleX - ((xValue) * cosinus - (yValue) * sinus);
			gizmoOffsetY = e.stageY / scaleY - ((xValue) * sinus + (yValue) * cosinus);

			defaultAngle = Math.atan((currentGizmo.x
				- transformTool.pivot.x) / (currentGizmo.y - transformTool.pivot.y));
			defaultX = selectedAssets.first().x + (transformTool.pivot.x * cosinus - transformTool.pivot.y * sinus);
			defaultY = selectedAssets.first().y + (transformTool.pivot.x * sinus + transformTool.pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, onTransform);
		}
		else if (Std.is(e.target, Pivot))
		{
			// gizmoOffsets are here used for the pivot
			gizmoOffsetX = e.stageX / scaleX - (transformTool.pivot.x * cosinus - transformTool.pivot.y * sinus);
			gizmoOffsetY = e.stageY / scaleY - (transformTool.pivot.x * sinus + transformTool.pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, dragPivot);
		}
	}

	private function stopDragging(e:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, onTransform);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragPivot);
		offsets = [];

		if (!selectedAssets.isEmpty())
		{
			for (asset in selectedAssets)
			{
				if (Std.is(asset, KadabraImage))
				{
					var kadabraAsset = cast(asset, KadabraImage);
					kadabraAsset.defaultHeight = kadabraAsset.height;
					kadabraAsset.defaultWidth = kadabraAsset.width;
					kadabraAsset.defaultX = kadabraAsset.x;
					kadabraAsset.defaultY = kadabraAsset.y;
				}
			}

			updateGizmos();
		}
	}

	private function dragAsset(e:MouseEvent):Void
	{
		if (selectedAssets.isEmpty())
		{ // pres error when the draggedPoint is deleted in onButtonChange
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		}
		else
		{
			if (!dragging)
			{
				dragging = true;

				offsets.push(-mouseX + e.stageX);
				offsets.push(-mouseY + e.stageY);

				selectedAssets.first().removeChild(transformTool);
			}

			if (InputPoll.isMouseDown)
			{
				var containerPoint = new Point(scrollX, scrollY);
				containerPoint = parent.localToGlobal(containerPoint);

				if (e.stageX < containerPoint.x)
				{
					// stage.window.warpMouse(Std.int(containerPoint.x), Std.int(e.stageY));
					scrollSpeedX = (e.stageX - containerPoint.x) / scrollSpeedXDivisor;
				}
				else if (e.stageX > containerPoint.x + parent.parent.width)
				{
					// stage.window.warpMouse(Std.int(containerPoint.x + parent.parent.width), Std.int(e.stageY));
					scrollSpeedX = (e.stageX - (containerPoint.x + parent.parent.width)) / scrollSpeedXDivisor;
				}
				else
				{
					scrollSpeedX = 0;
				}

				if (e.stageY < containerPoint.y)
				{
					// stage.window.warpMouse(Std.int(e.stageX), Std.int(containerPoint.y));
					scrollSpeedY = (e.stageY - containerPoint.y) / scrollSpeedYDivisor;
				}
				else if (e.stageY > containerPoint.y + parent.parent.height)
				{
					// stage.window.warpMouse(Std.int(e.stageX), Std.int(containerPoint.y + parent.parent.height));
					scrollSpeedY = (e.stageY - (containerPoint.y + parent.parent.height)) / scrollSpeedYDivisor;
				}
				else
				{
					scrollSpeedY = 0;
				}
			}
			var i = 0;
			for (asset in selectedAssets)
			{
				asset.x = e.stageX / scaleX - offsets[i * 2];
				asset.y = e.stageY / scaleY - offsets[i * 2 + 1];

				if (asset.x < -x)
				{
					asset.x = -x;
				}
				else if (asset.x + asset.width > background.width + x)
				{
					asset.x = background.width + x - asset.width;
				}

				if (asset.y < -y)
				{
					asset.y = -y;
				}
				else if (asset.y + asset.height > background.height + y)
				{
					asset.y = background.height + y - asset.height;
				}

				++i;
			}

			onAssetUpdated.dispatch();
			e.updateAfterEvent();
		}
	}

	function upSide(x:Float, y:Float, a:Point, b:Point)
	{
		return ((b.y - a.y) * (x - a.x) - (b.x - a.x) * (y - a.y)) >= 0;
	}

	function onTransform(e:MouseEvent):Void
	{
		if (currentGizmo.isRotate)
		{
			rotate(e);
		} else
		{
			scale(e);
		}

		var oldGizmosHeight = transformTool.gizmosHeight;
		var oldGizmosWidth = transformTool.gizmosWidth;
		transformTool.gizmosHeight = downOrigin - upOrigin;
		transformTool.gizmosWidth = rightOrigin - leftOrigin;

		for (asset in selectedAssets)
		{ // image dimensions are adjusted and asset coordinates are changed to always keep upOrigin = LeftOrigin = 0
			var kadabraAsset = cast(asset, KadabraImage);
			kadabraAsset.image.height *= transformTool.gizmosHeight / oldGizmosHeight;
			asset.y += upOrigin * cosinus + leftOrigin * sinus;
			downOrigin -= upOrigin;
			kadabraAsset.image.width *= transformTool.gizmosWidth / oldGizmosWidth;
			asset.x += leftOrigin * cosinus - upOrigin * sinus;
			rightOrigin -= leftOrigin;
			upOrigin = 0;
			leftOrigin = 0;
		}

		transformTool.updateGizmos();

		transformTool.x = leftOrigin;
		transformTool.y = upOrigin;

		onAssetUpdated.dispatch();
		e.updateAfterEvent();
	}

	function scale(e:MouseEvent):Void
	{
		if (!scaling)
		{
			scaling = true;
		}

		var coef = currentGizmo.vertical * currentGizmo.horizontal;
		if (coef != 0)
		{ // if coef != 0, currentGizmo is a corner
			if (!e.altKey)
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
					if (!upSide(e.stageX / scaleX - gizmoOffsetX, e.stageY / scaleY - gizmoOffsetY, aPoint, bPoint))
					{
						var oldUpOrigin = upOrigin;
						upOrigin = (e.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (e.stageX / scaleX - gizmoOffsetX) * sinus;
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
							leftOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
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
							rightOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

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
					if (upSide(e.stageX / scaleX - gizmoOffsetX, e.stageY / scaleY - gizmoOffsetY, aPoint, bPoint))
					{
						var oldDownOrigin = downOrigin;
						downOrigin = (e.stageY / scaleY
							- gizmoOffsetY) * cosinus
							- (e.stageX / scaleX - gizmoOffsetX) * sinus;

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
							leftOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
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
							rightOrigin = (e.stageX / scaleX
								- gizmoOffsetX) * cosinus
								+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

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
					upOrigin = (e.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (e.stageX / scaleX - gizmoOffsetX) * sinus;
					gizmoOffsetY += upOrigin;

					if (upOrigin >= downOrigin)
					{
						gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
						upOrigin = downOrigin - 0.1;
					}
				}
				else if (currentGizmo.vertical > 0)
				{ // is a Down gizmo
					downOrigin = (e.stageY / scaleY
						- gizmoOffsetY) * cosinus
						- (e.stageX / scaleX - gizmoOffsetX) * sinus;

					if (downOrigin <= upOrigin)
					{
						downOrigin = upOrigin + 0.1;
					}
				}

				if (currentGizmo.horizontal < 0)
				{ // is a Left gizmo
					leftOrigin = (e.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
					gizmoOffsetX += leftOrigin;

					if (leftOrigin >= rightOrigin)
					{
						gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
						leftOrigin = rightOrigin - 0.1;
					}
				}
				else if (currentGizmo.horizontal > 0)
				{ // is a Right gizmo
					rightOrigin = (e.stageX / scaleX
						- gizmoOffsetX) * cosinus
						+ (e.stageY / scaleY - gizmoOffsetY) * sinus;

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
				upOrigin = (e.stageY / scaleY - gizmoOffsetY) * cosinus - (e.stageX / scaleX - gizmoOffsetX) * sinus;
				gizmoOffsetY += upOrigin;

				if (upOrigin >= downOrigin)
				{
					gizmoOffsetY -= upOrigin - (downOrigin - 0.1);
					upOrigin = downOrigin - 0.1;
				}
			}
			else if (currentGizmo.vertical > 0)
			{ // is a Down gizmo
				downOrigin = (e.stageY / scaleY - gizmoOffsetY) * cosinus - (e.stageX / scaleX - gizmoOffsetX) * sinus;

				if (downOrigin <= upOrigin)
				{
					downOrigin = upOrigin + 0.1;
				}
			}
			else if (currentGizmo.horizontal < 0)
			{ // is a Left gizmo
				leftOrigin = (e.stageX / scaleX - gizmoOffsetX) * cosinus + (e.stageY / scaleY - gizmoOffsetY) * sinus;
				gizmoOffsetX += leftOrigin;

				if (leftOrigin >= rightOrigin)
				{
					gizmoOffsetX -= leftOrigin - (rightOrigin - 0.1);
					leftOrigin = rightOrigin - 0.1;
				}
			}
			else if (currentGizmo.horizontal > 0)
			{ // is a Right gizmo
				rightOrigin = (e.stageX / scaleX - gizmoOffsetX) * cosinus + (e.stageY / scaleY - gizmoOffsetY) * sinus;

				if (rightOrigin <= leftOrigin)
				{
					rightOrigin = leftOrigin + 0.1;
				}
			}
		}
	}

	function rotate(e:MouseEvent):Void
	{
		var newAngle = Math.atan((e.stageX / scaleX - gizmoOffsetX) / (e.stageY / scaleY - gizmoOffsetY));
		newAngle -= defaultAngle;
		newAngle = newAngle.toDegree();

		if (e.stageY / scaleY - gizmoOffsetY >= 0)
		{
			// adjusts the angle if the mouse is under the pivot
			newAngle += 180;
		}

		for (asset in selectedAssets)
		{
			asset.rotation = -newAngle;

			radianRotation = selectedAssets.first().rotation.toRadians();
			cosinus = Math.cos(radianRotation);
			sinus = Math.sin(radianRotation);

			asset.x = defaultX - transformTool.pivot.x * cosinus + transformTool.pivot.y * sinus;
			asset.y = defaultY - transformTool.pivot.x * sinus - transformTool.pivot.y * cosinus;
		}
	}

	private function dragPivot(e:MouseEvent):Void
	{
		if (!dragging)
		{
			dragging = true;
		}

		transformTool.pivot.x = (e.stageX / scaleX
			- gizmoOffsetX) * cosinus
			+ (e.stageY / scaleY - gizmoOffsetY) * sinus;
		transformTool.pivot.y = (e.stageY / scaleY
			- gizmoOffsetY) * cosinus
			- (e.stageX / scaleX - gizmoOffsetX) * sinus;

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

		// TODO group
		var kadabraImage:KadabraImage = cast selectedAssets.first();
		kadabraImage.pivotX = transformTool.pivot.x / transformTool.gizmosWidth;
		kadabraImage.pivotY = transformTool.pivot.y / transformTool.gizmosHeight;

		transformTool.pivot.X = kadabraImage.pivotX;
		transformTool.pivot.Y = kadabraImage.pivotY;

		e.updateAfterEvent();
	}

	private function onKeyDown(key:KKey):Void
	{
		switch (key.charCode)
		{
			case(KeyCode.P):
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

			case(KeyCode.DELETE):
				if (!selectedAssets.isEmpty())
				{
					removedChild.dispatch(selectedAssets.first());
					imageContainer.removeChild(selectedAssets.first());
				}
		}
	}

	private function selectAsset(e:MouseEvent):Void
	{
		if (!dragging && !scaling)
		{
			if (Std.is(e.target, KadabraImage))
			{
				// if (e.shiftKey)
				// {
				//	if (!(cast(e.target, KadabraImage)).isSelected)
				//	{
				//		selectedAssets.add(cast(e.target, KadabraImage));
				//		selectedAssets.last().select();
				//	}
				// }
				// else
				// {
				for (asset in selectedAssets)
				{
					if (Std.is(asset, KadabraImage))
					{
						cast(asset, KadabraImage).unselect();
					}
					else if (Std.is(asset, KadabraPoint))
					{
						cast(asset, KadabraPoint).unselect();
					}
				}
				selectedAssets.clear();
				selectedAssets.add(cast(e.target, KadabraImage));
				cast(selectedAssets.last(), KadabraImage).select();

				onSelectAsset.dispatch(selectedAssets.first());

				radianRotation = selectedAssets.first().rotation.toRadians();
				cosinus = Math.cos(radianRotation);
				sinus = Math.sin(radianRotation);
				// }
			}
			else if (Std.is(e.target, KadabraPoint))
			{
				for (asset in selectedAssets)
				{
					if (Std.is(asset, KadabraImage))
					{
						cast(asset, KadabraImage).unselect();
					}
					else if (Std.is(asset, KadabraPoint))
					{
						cast(asset, KadabraPoint).unselect();
					}
				}
				selectedAssets.clear();
				selectedAssets.add(cast(e.target, KadabraPoint));
				cast(selectedAssets.last(), KadabraPoint).select();

				onSelectAsset.dispatch(selectedAssets.first());
			}
			else if (!Std.is(e.target, Gizmo))
			{
				if (!selectedAssets.isEmpty())
				{
					for (asset in selectedAssets)
					{
						if (Std.is(asset, KadabraImage))
						{
							cast(asset, KadabraImage).unselect();
						}
						else if (Std.is(asset, KadabraPoint))
						{
							cast(asset, KadabraPoint).unselect();
						}
					}
					selectedAssets.clear();

					updateGizmos();
				}
			}
		}
		else
		{
			if (ToolPanel.selectedButton == "icon-point")
			{
				addDraggedPoint();
			}
			dragging = false;
			scaling = false;
		}
	}

	private function updateGizmos()
	{ // puts gizmos on the corners and in the middle of the sides of the selection
		if (selectedAssets.isEmpty())
		{
			if (transformTool.parent != null)
			{
				transformTool.parent.removeChild(transformTool);
			}
		}
		else if (Std.is(selectedAssets.first(), KadabraImage))
		{
			// TODO multi select
			var kadabraImage = cast selectedAssets.first();
			kadabraImage.addChild(transformTool);

			upOrigin = stage.height;
			downOrigin = -800;
			leftOrigin = stage.width;
			rightOrigin = -800;

			for (asset in selectedAssets)
			{ // determines bounds of the selection
				var kadabraAsset = cast(asset, KadabraImage);
				upOrigin = kadabraAsset.image.y;
				downOrigin = kadabraAsset.image.y + kadabraAsset.image.height;
				leftOrigin = kadabraAsset.image.x;
				rightOrigin = kadabraAsset.image.x + kadabraAsset.image.width;
			}

			transformTool.gizmosHeight = downOrigin - upOrigin;
			transformTool.gizmosWidth = rightOrigin - leftOrigin;

			ratio = transformTool.gizmosHeight / transformTool.gizmosWidth;

			transformTool.pivot.setPivot(kadabraImage.pivotX, kadabraImage.pivotY);

			transformTool.updateGizmos();

			transformTool.x = leftOrigin;
			transformTool.y = upOrigin;
		}
	}

	function onMouseUp(e:MouseEvent)
	{
		dragging = false;
	}

	function onButtonChange(newSelectedButton:String)
	{
		if (newSelectedButton == "icon-point")
		{
			addDraggedPoint();
		}
		else if (ToolPanel.selectedButton == "icon-point")
		{
			removedChild.dispatch(draggedPoint);
			removeChild(draggedPoint);
			selectedAssets.clear();
			--pointsNumber;
		}
	}

	function addDraggedPoint():Void
	{
		draggedPoint = new KadabraPoint();
		++pointsNumber;
		draggedPoint.name = "point" + pointsNumber;
		trace(draggedPoint.name);

		if (!selectedAssets.isEmpty())
		{
			for (asset in selectedAssets)
			{
				if (Std.is(asset, KadabraImage))
				{
					cast(asset, KadabraImage).unselect();
				}
				else if (Std.is(asset, KadabraPoint))
				{
					cast(asset, KadabraPoint).unselect();
				}
			}
			selectedAssets.clear();
			updateGizmos();
		}

		selectedAssets.add(draggedPoint);

		onSelectAsset.dispatch(draggedPoint);

		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);

		addChild(draggedPoint);

		addedChild.dispatch(draggedPoint);
	}

	function onInputChange(input:TextInput)
	{
		if (!selectedAssets.isEmpty())
		{
			switch (input.name)
			{
				case("nameInput"):
					selectedAssets.first().name = input.text;
				case("xInput"):
					selectedAssets.first().x = Std.parseFloat(input.text);
				case("yInput"):
					selectedAssets.first().y = Std.parseFloat(input.text);
				case("rotationInput"):
					selectedAssets.first().rotation = Std.parseFloat(input.text);
			}
		}
	}
}
