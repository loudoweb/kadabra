import openfl.display.DisplayObject;
import panels.HierarchyPanel;
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
import assets.*;

using utils.KadabraUtils;

/**
 * Handle Canvas: drop file, selection, scale,...
 * TODO: use enum to know what is selected (IMAGE, TEXTFIELD, SHAPE, POINT...)
 */
class KadabraScene extends Sprite
{
	public var background:RectangleSkin;

	var imageContainer:Sprite;

	public var offsets:Array<Float>;

	public var selectedAssets:Array<KadabraAsset>;

	var transformTool:TransformTool;

	public var dragging = false;

	public var scrollX:Float;
	public var scrollY:Float;
	public var scrollSpeedX = 0.;
	public var scrollSpeedY = 0.;

	inline static var scrollSpeedXDivisor = 10;
	inline static var scrollSpeedYDivisor = 5;

	public static var onChildAdded:Event<Sprite->Void>;
	public static var onChildRemoved:Event<Sprite->Void>;
	public static var onAssetSelected:Event<Sprite->Void>;
	public static var onAssetUpdated:Event<Void->Void>;
	public static var onAssetNameChanged:Event<String->String->Void>;

	public function new()
	{
		super();

		initialize();
		construct();
	}

	function initialize():Void
	{
		imageContainer = new Sprite();

		offsets = [];
		selectedAssets = [];

		transformTool = new TransformTool();

		onChildAdded = new Event<Sprite->Void>();
		onChildRemoved = new Event<Sprite->Void>();
		onAssetSelected = new Event<Sprite->Void>();
		onAssetUpdated = new Event<Void->Void>();
		onAssetNameChanged = new Event<String->String->Void>();

		name = "KSCENE";
	}

	function construct():Void
	{
		/////Scene dimensions/////
		///////////////////////////
		background = new RectangleSkin();
		background.width = 1920;
		background.height = 1080;
		background.fill = KadabraUtils.SCENE_FILL;
		background.mouseEnabled = false;
		background.name = "KSCENE-BACKGROUND";

		addChild(background);

		addChild(imageContainer);

		addEventListener(OpenflEvent.ADDED_TO_STAGE, onAddedtoStage);
	}

	function onAddedtoStage(e:OpenflEvent)
	{
		stage.window.onDropFile.add(dragNDrop);
		this.parent.addEventListener(MouseEvent.MOUSE_DOWN, event_startDragging, true);
		InputPoll.onKeyDown.add(onKeyDown);

		ToolPanel.onButtonChange.add(onButtonChange);
		PropertiesPanel.inputChange.add(onInputChange);
		HierarchyPanel.onAssetSelected.add(onHierarchySelected);
	}

	function dragNDrop(path:String)
	{
		if (path.toLowerCase().indexOf(".png") != -1 || path.toLowerCase().indexOf(".jpg") != -1)
		{
			// Add an image object when an image file is dropped in the window
			BitmapData.loadFromFile(path).onComplete(function(bitmapdata)
			{
				var image = new KadabraImage(bitmapdata);
				imageContainer.addChild(image);
				var splitPath = path.split("\\");
				var _name = splitPath[splitPath.length - 1];
				_name = _name.substring(0, _name.length - 4);
				image.name = _name;

				HierarchyPanel.onAssetSelected.remove(onHierarchySelected);
				unselectAsset();
				onChildAdded.dispatch(image);
				selectAsset(image);
				HierarchyPanel.onAssetSelected.add(onHierarchySelected);

				// we don't have correct mouseX mouseY here, so we need to wait
				stage.addEventListener(openfl.events.Event.ENTER_FRAME, placeOnNextFrame);
			});
		}
	}

	function placeOnNextFrame(e:openfl.events.Event):Void
	{
		trace("place on next frame", imageContainer.mouseX, imageContainer.mouseY);
		stage.removeEventListener(openfl.events.Event.ENTER_FRAME, placeOnNextFrame);
		var imagePoint = new Point(imageContainer.mouseX, imageContainer.mouseY);

		for (image in selectedAssets)
		{
			image.x = imagePoint.x;
			image.y = imagePoint.y;
		}
	}

	function event_startDragging(e:MouseEvent):Void
	{
		trace("start", cast(e.target, DisplayObject).name, e.currentTarget);

		var _target:DisplayObject = cast e.target;
		trace(_target.name, e.localX, e.localY, scrollX, scrollY);

		if (ToolPanel.selectedButton == "icon-point" && this.hitTestPoint(e.localX, e.localY))
		{
			_target = addDraggedPoint();
		}

		// drag
		if (Std.isOfType(_target, KadabraAsset))
		{
			var kasset:KadabraAsset = cast _target;

			stage.addEventListener(MouseEvent.MOUSE_UP, event_stopDragging);
			stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, event_releaseOutside);

			switch (kasset.type)
			{
				default:
					if (selectedAssets.length == 0)
					{
						selectAsset(kasset);
						stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
					}
					else if (selectedAssets.indexOf(kasset) == -1)
					{ // if the clicked image is different from the selected object, it is selected
						unselectAsset();
						selectAsset(kasset);
						stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
					} else
					{
						// already selected, allow drag
						stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
					}
					// if (!e.shiftKey)
					// { // if Shift is pressed while clicking an image, it is added to the selection
					// }
					// clear offsets

					var i = 0;
					for (image in selectedAssets)
					{
						offsets[i] = imageContainer.mouseX - image.x;
						offsets[i + 1] = imageContainer.mouseY - image.y;
						i += 2;
					}
					trace(offsets.length, selectedAssets.length);
			}
		} else if (Std.isOfType(_target, Gizmo) || Std.isOfType(_target, Pivot))
		{
			trace('transform');
		} else
		{
			// unselect if click elsewhere on scene (keep selection if click on other part of ui)
			unselectAsset();
		}
	}

	function event_stopDragging(e:MouseEvent):Void
	{
		trace("stop", cast(e.target, DisplayObject).name, e.currentTarget);
		stage.removeEventListener(MouseEvent.MOUSE_UP, event_stopDragging);
		stage.removeEventListener(MouseEvent.RELEASE_OUTSIDE, event_releaseOutside);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		offsets = [];

		if (selectedAssets.length > 0)
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

	function dragAsset(e:MouseEvent):Void
	{
		trace("drag asset");
		if (selectedAssets.length == 0)
		{ // avoid error when the draggedPoint is deleted in HierarchyPanel onButtonChange
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
		}
		else
		{
			if (InputPoll.isMouseDown)
			{
				if (!dragging)
				{
					dragging = true;

					selectedAssets[0].removeChild(transformTool);
				}

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
			trace(offsets.length, selectedAssets.length);
			for (asset in selectedAssets)
			{
				asset.x = imageContainer.mouseX - offsets[i];
				asset.y = imageContainer.mouseY - offsets[i + 1];

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

				i += 2;
			}

			onAssetUpdated.dispatch();
			e.updateAfterEvent();
		}
	}

	function onKeyDown(key:KKey):Void
	{
		switch (key.charCode)
		{
			case(KeyCode.DELETE):
				if (selectedAssets.length > 0)
				{
					for (asset in selectedAssets)
					{
						if (asset.parent != null)
						{
							onChildRemoved.dispatch(asset);
							asset.parent.removeChild(asset);
						}
					}
				}
		}
	}

	function selectAsset(display:DisplayObject):Void
	{
		/*if (ToolPanel.selectedButton == "icon-point")
			{
				trace('hello');
				addDraggedPoint();
				dragging = false;
			} else
			{ */
		var kasset:KadabraAsset = null;
		if (Std.is(display, KadabraImage))
		{
			kasset = cast display;
		} else if (Std.is(display, KadabraPoint))
		{
			kasset = cast display;
		}

		selectedAssets.push(kasset);
		trace("select asset", offsets.length, selectedAssets.length);
		onAssetSelected.dispatch(kasset);
		kasset.select();
		updateGizmos();
		// }

		/*if (!dragging && !scaling)
			{
				if (Std.is(display, KadabraImage))
				{
					var kImage:KadabraImage = cast display;
					// if (e.shiftKey)
					// {
					//	if (!(cast(display, KadabraImage)).isSelected)
					//	{
					//		selectedAssets.push(cast(display, KadabraImage));
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
					selectedAssets.push(kImage);
					kImage.select();

					if (dispatch)
						onAssetSelected.dispatch(kImage);

					radianRotation = kImage.rotation.toRadians();
					cosinus = Math.cos(radianRotation);
					sinus = Math.sin(radianRotation);
					// }
				}
				else if (Std.is(display, KadabraPoint))
				{
					var kPoint:KadabraPoint = cast display;
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
					selectedAssets.push(kPoint);
					kPoint.select();

					onAssetSelected.dispatch(selectedAssets[0]);
				}
				else if (!Std.is(display, Gizmo))
				{
					if (selectedAssets.length > 0)
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
			{ */

		// }
	}

	function unselectAsset():Void
	{
		for (asset in selectedAssets)
		{
			asset.unselect();
		}
		transformTool.unactive();
		selectedAssets.splice(0, selectedAssets.length);
		onAssetSelected.dispatch(null);
	}

	function onHierarchySelected(name):Void
	{
		trace("coucou");
		unselectAsset();
		for (i in 0...imageContainer.numChildren)
		{
			if (imageContainer.getChildAt(i).name == name)
			{
				selectAsset(imageContainer.getChildAt(i));
				break;
			}
		}
	}

	function updateGizmos()
	{
		// puts gizmos on the corners and in the middle of the sides of the selection
		if (selectedAssets.length == 0)
		{
			if (transformTool.parent != null)
			{
				transformTool.parent.removeChild(transformTool);
			}
		}
		else if (Std.is(selectedAssets[0], KadabraImage))
		{
			// TODO multi select
			var kadabraImage:KadabraImage = cast selectedAssets[0];
			transformTool.active(kadabraImage, kadabraImage);
			trace(kadabraImage.image.getBounds(kadabraImage));
			trace(kadabraImage.image.x + kadabraImage.width * kadabraImage.image.scaleX);
			transformTool.updateGizmos(kadabraImage.image.getBounds(kadabraImage), kadabraImage.pivotX,
				kadabraImage.pivotY);
		}
	}

	function event_releaseOutside(e:MouseEvent)
	{
		trace("release outside");
		dragging = false;
	}

	function onButtonChange(newSelectedButton:String)
	{
		/*if (newSelectedButton == "icon-point")
			{
				addDraggedPoint();
			}
			else if (ToolPanel.selectedButton == "icon-point")
			{
				// onChildRemoved.dispatch(draggedPoint);
				//	removeChild(draggedPoint);
				// selectedAssets.clear();
		}*/
	}

	function addDraggedPoint():KadabraPoint
	{
		var draggedPoint = new KadabraPoint();
		draggedPoint.name = "point";

		imageContainer.addChild(draggedPoint);

		onChildAdded.dispatch(draggedPoint);

		selectAsset(draggedPoint);

		return draggedPoint;
	}

	function onInputChange(input:TextInput)
	{
		trace('input change');
		var i = 0;
		for (currentAsset in selectedAssets)
		{
			switch (input.name)
			{
				case "nameInput":
					var _name = currentAsset.name;
					currentAsset.name = input.text;
					onAssetNameChanged.dispatch(_name, i == 0 ? input.text : input.text + i);
				case "xTransform":
					currentAsset.x = Std.parseFloat(input.text);
				case "yTransform":
					currentAsset.y = Std.parseFloat(input.text);
				case "sxTransform":
					if (Std.is(currentAsset, KadabraImage))
					{
						var kImage:KadabraImage = cast currentAsset;
						kImage.image.scaleX = Std.parseFloat(input.text);
						updateGizmos();
					}
				case "syTransform":
					if (Std.is(currentAsset, KadabraImage))
					{
						var kImage:KadabraImage = cast currentAsset;
						kImage.image.scaleY = Std.parseFloat(input.text);
						updateGizmos();
					}
				case "rTransform":
					currentAsset.rotation = Std.parseFloat(input.text);
				case "aTransform":
					var currentAsset = Std.is(currentAsset, KadabraImage) ? currentAsset.getChildAt(0) : currentAsset;
					currentAsset.alpha = Std.parseFloat(input.text);
				case "xPivot":
					if (Std.is(currentAsset, KadabraImage))
					{
						var kImage:KadabraImage = cast currentAsset;
						kImage.pivotX = Std.parseFloat(input.text);
						updateGizmos();
					}
				case "yPivot":
					if (Std.is(currentAsset, KadabraImage))
					{
						var kImage:KadabraImage = cast currentAsset;
						kImage.pivotY = Std.parseFloat(input.text);
						updateGizmos();
					}
			}
			i++;
		}
	}
}
