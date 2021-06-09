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

	public var selectedAssets:List<KadabraAsset>;

	var transformTool:TransformTool;

	var draggedPoint:KadabraPoint;
	var pointsNumber = 0;

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
		selectedAssets = new List<KadabraAsset>();

		transformTool = new TransformTool();

		onChildAdded = new Event<Sprite->Void>();
		onChildRemoved = new Event<Sprite->Void>();
		onAssetSelected = new Event<Sprite->Void>();
		onAssetUpdated = new Event<Void->Void>();

		name = "SCENE";
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

		addChild(background);

		addChild(imageContainer);

		addEventListener(OpenflEvent.ADDED_TO_STAGE, onAddedtoStage);
	}

	function onAddedtoStage(e:OpenflEvent)
	{
		stage.window.onDropFile.add(dragNDrop);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, event_startDragging);
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
				image.name = splitPath[splitPath.length - 1];

				unselectAsset();

				var imagePoint = new Point(stage.mouseX, stage.mouseY);
				imagePoint = globalToLocal(imagePoint);

				image.x = imagePoint.x;
				image.y = imagePoint.y;

				onChildAdded.dispatch(image);
				selectAsset(image);
			});
		}
	}

	function event_startDragging(e:MouseEvent):Void
	{
		trace("start", cast(e.target, DisplayObject).name, e.currentTarget);

		// drag
		if (Std.is(e.target, KadabraAsset))
		{
			var kasset:KadabraAsset = cast e.target;

			stage.addEventListener(MouseEvent.MOUSE_UP, event_stopDragging);
			stage.addEventListener(MouseEvent.RELEASE_OUTSIDE, event_releaseOutside);

			switch (kasset.type)
			{
				case IMAGE:
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
							asset.unselect();
						}
						selectedAssets.clear();
						selectedAssets.add(cast(e.target, KadabraImage));
						cast(selectedAssets.last(), KadabraImage).select();
					}
					// }
					for (image in selectedAssets)
					{
						offsets.push(e.stageX / scaleX - image.x);
						offsets.push(e.stageY / scaleY - image.y);
					}

					onAssetSelected.dispatch(selectedAssets.first());
					stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);

				case POINT:
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
							asset.unselect();
						}
						selectedAssets.clear();
						selectedAssets.add(cast(e.target, KadabraPoint));
						cast(selectedAssets.last(), KadabraPoint).select();
					}

					onAssetSelected.dispatch(selectedAssets.first());
					stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);
				default:
					trace('not implemented');
			}
		} else
		{
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

	function dragAsset(e:MouseEvent):Void
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

	function onKeyDown(key:KKey):Void
	{
		switch (key.charCode)
		{
			case(KeyCode.DELETE):
				if (!selectedAssets.isEmpty())
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

	function event_selectAsset(e:MouseEvent):Void
	{
		trace("select 'click'", cast(e.target, DisplayObject).name, e.currentTarget);
		selectAsset(e.target);
	}

	function selectAsset(display:DisplayObject, dispatch:Bool = true):Void
	{
		/*if (!dragging && !scaling)
			{
				if (Std.is(display, KadabraImage))
				{
					var kImage:KadabraImage = cast display;
					// if (e.shiftKey)
					// {
					//	if (!(cast(display, KadabraImage)).isSelected)
					//	{
					//		selectedAssets.add(cast(display, KadabraImage));
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
					selectedAssets.add(kImage);
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
					selectedAssets.add(kPoint);
					kPoint.select();

					onAssetSelected.dispatch(selectedAssets.first());
				}
				else if (!Std.is(display, Gizmo))
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
			{ */

		if (ToolPanel.selectedButton == "icon-point")
		{
			addDraggedPoint();
			dragging = false;
		}

		// }
	}

	function unselectAsset():Void
	{
		for (asset in selectedAssets)
		{
			asset.unselect();
		}
		transformTool.unactive();
		selectedAssets.clear();
	}

	function onHierarchySelected(name):Void
	{
		trace("coucou");
		for (i in 0...imageContainer.numChildren)
		{
			if (imageContainer.getChildAt(i).name == name)
			{
				selectAsset(imageContainer.getChildAt(i), false);
				break;
			}
		}
	}

	function updateGizmos()
	{
		// puts gizmos on the corners and in the middle of the sides of the selection
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
			var kadabraImage:KadabraImage = cast selectedAssets.first();
			transformTool.active(kadabraImage, kadabraImage);

			transformTool.updateGizmos(kadabraImage.image.y, kadabraImage.image.y + kadabraImage.image.height,
				kadabraImage.image.x, kadabraImage.image.x + kadabraImage.image.width, kadabraImage.pivotX,
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
		if (newSelectedButton == "icon-point")
		{
			addDraggedPoint();
		}
		else if (ToolPanel.selectedButton == "icon-point")
		{
			onChildRemoved.dispatch(draggedPoint);
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

		onAssetSelected.dispatch(draggedPoint);

		stage.addEventListener(MouseEvent.MOUSE_MOVE, dragAsset);

		imageContainer.addChild(draggedPoint);

		onChildAdded.dispatch(draggedPoint);
	}

	function onInputChange(input:TextInput)
	{
		if (!selectedAssets.isEmpty())
		{
			switch (input.name)
			{
				case "nameInput":
					selectedAssets.first().name = input.text;
				case "xTransform":
					selectedAssets.first().x = Std.parseFloat(input.text);
				case "yTransform":
					selectedAssets.first().y = Std.parseFloat(input.text);
				case "rTransform":
					selectedAssets.first().rotation = Std.parseFloat(input.text);
				case "aTransform":
					var currentAsset = Std.is(selectedAssets.first(),
						KadabraImage) ? selectedAssets.first().getChildAt(0) : selectedAssets.first();
					currentAsset.alpha = Std.parseFloat(input.text);
				case "xPivot":
					if (Std.is(selectedAssets.first(), KadabraImage))
					{
						var kImage:KadabraImage = cast selectedAssets.first();
						kImage.pivotX = Std.parseFloat(input.text);
					}
				case "yPivot":
					if (Std.is(selectedAssets.first(), KadabraImage))
					{
						var kImage:KadabraImage = cast selectedAssets.first();
						kImage.pivotY = Std.parseFloat(input.text);
					}
			}
		}
	}
}
