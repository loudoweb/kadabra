package panels;

import feathers.layout.ResponsiveGridLayoutData;
import feathers.skins.RectangleSkin;
import feathers.layout.VerticalLayoutData;
import feathers.layout.HorizontalLayout;
import feathers.controls.Label;
import utils.KadabraUtils;
import feathers.layout.FormLayout;
import feathers.controls.TextInput;
import feathers.controls.FormItem;
import feathers.controls.Form;
import feathers.layout.VerticalLayout;
import feathers.layout.ResponsiveGridLayout;
import openfl.events.Event;
import openfl.display.Sprite;
import feathers.layout.HorizontalLayoutData;
import utils.UIFactory;
import feathers.controls.LayoutGroup;
import assets.*;

class PropertiesPanel extends LayoutGroup
{
	var selectedAsset:Sprite;

	var form:Form;
	var nameItem:FormItem;
	var nameInput:TextInput;
	var typeItem:FormItem;
	var typeInput:TextInput;
	var transformItem:LayoutGroup;
	var xInput:TextInput;
	var yInput:TextInput;
	var sizeItem:LayoutGroup;
	var wInput:TextInput;
	var hInput:TextInput;
	var sxInput:TextInput;
	var syInput:TextInput;
	var rotationInput:TextInput;
	var alphaInput:TextInput;

	var pivots:LayoutGroup;
	var xPivot:LayoutGroup;
	var xPivotInput:TextInput;
	var yPivot:LayoutGroup;
	var yPivotInput:TextInput;

	var dispatch:Bool;

	public static var inputChange:lime.app.Event<TextInput->Void>;

	public function new():Void
	{
		super();

		width = 300;
		minWidth = 300;
		maxWidth = 600;
		layoutData = new VerticalLayoutData(100.0);

		dispatch = true;

		inputChange = new lime.app.Event<TextInput->Void>();

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = LEFT;
		_layout.gap = 18;
		layout = _layout;

		form = new Form();
		form.layoutData = new VerticalLayoutData(100.0);

		nameItem = new FormItem();
		nameItem.textPosition = LEFT;
		nameItem.text = "name : ";
		nameItem.textFormat = KadabraUtils.FONT_NORMAL;
		nameInput = new TextInput();
		nameInput.name = "nameInput";
		nameItem.content = nameInput;

		typeItem = new FormItem();
		typeItem.textPosition = LEFT;
		typeItem.text = "type : ";
		typeItem.textFormat = KadabraUtils.FONT_NORMAL;
		typeInput = new TextInput();
		typeItem.content = typeInput;
		typeInput.enabled = false;

		// transform

		transformItem = new LayoutGroup();
		transformItem.layout = new VerticalLayout();
		transformItem.layoutData = VerticalLayoutData.fillHorizontal();

		var tLabel = new Label("Transform");
		tLabel.textFormat = KadabraUtils.FONT_NORMAL;
		transformItem.addChild(tLabel);

		var transformInputs = new LayoutGroup();
		transformInputs.layout = new ResponsiveGridLayout(2);
		transformInputs.layoutData = VerticalLayoutData.fillHorizontal();
		transformItem.addChild(transformInputs);

		var itemLabel = UIFactory.createItemLabel('X', "xTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		xInput = itemLabel.input;
		transformInputs.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('Y', "yTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		yInput = itemLabel.input;
		transformInputs.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('R', "rTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		rotationInput = itemLabel.input;
		transformInputs.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('A', "aTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		alphaInput = itemLabel.input;
		transformInputs.addChild(itemLabel.group);

		// size
		sizeItem = new LayoutGroup();
		sizeItem.layout = new ResponsiveGridLayout(2);
		sizeItem.layoutData = VerticalLayoutData.fillHorizontal();

		itemLabel = UIFactory.createItemLabel('W', "wTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		wInput = itemLabel.input;
		sizeItem.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('H', "hTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		hInput = itemLabel.input;
		sizeItem.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('Sx', "sxTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		sxInput = itemLabel.input;
		sizeItem.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('Sy', "syTransform", 20, new ResponsiveGridLayoutData(1),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		syInput = itemLabel.input;
		sizeItem.addChild(itemLabel.group);

		// pivots

		pivots = new LayoutGroup();
		pivots.layout = new VerticalLayout();
		pivots.layoutData = VerticalLayoutData.fillHorizontal();

		var pivotsLabel = new Label("Origin");
		pivotsLabel.textFormat = KadabraUtils.FONT_NORMAL;
		pivots.addChild(pivotsLabel);

		var pivotsItems = new LayoutGroup();
		pivotsItems.layout = new HorizontalLayout();
		pivotsItems.layoutData = VerticalLayoutData.fill();
		pivots.addChild(pivotsItems);

		var itemLabel = UIFactory.createItemLabel('X', "xPivot", 20, new HorizontalLayoutData(50.0),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		xPivotInput = itemLabel.input;
		pivotsItems.addChild(itemLabel.group);

		itemLabel = UIFactory.createItemLabel('Y', "yPivot", 20, new HorizontalLayoutData(50.0),
			HorizontalLayoutData.fillHorizontal(60.0), true);
		yPivotInput = itemLabel.input;
		pivotsItems.addChild(itemLabel.group);

		addChild(UIFactory.createHeader("Properties"));
		addChild(form);

		form.addChild(nameItem);
		form.addChild(typeItem);
		form.addChild(transformItem);
		form.addChild(sizeItem);
		form.addChild(pivots);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(e:Event)
	{
		KadabraScene.onAssetSelected.add(showSelectedAsset);
		KadabraScene.onAssetUpdated.add(updateData);
		TransformTool.onTransform.add(updateData);

		addChangeListeners();
	}

	function addChangeListeners():Void
	{
		nameInput.addEventListener(Event.CHANGE, dispatchInputChange);
		xInput.addEventListener(Event.CHANGE, dispatchInputChange);
		yInput.addEventListener(Event.CHANGE, dispatchInputChange);
		wInput.addEventListener(Event.CHANGE, dispatchInputChange);
		hInput.addEventListener(Event.CHANGE, dispatchInputChange);
		sxInput.addEventListener(Event.CHANGE, dispatchInputChange);
		syInput.addEventListener(Event.CHANGE, dispatchInputChange);
		rotationInput.addEventListener(Event.CHANGE, dispatchInputChange);
		alphaInput.addEventListener(Event.CHANGE, dispatchInputChange);
		xPivotInput.addEventListener(Event.CHANGE, dispatchInputChange);
		yPivotInput.addEventListener(Event.CHANGE, dispatchInputChange);
	}

	function removeChangeListeners():Void
	{
		nameInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		xInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		yInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		wInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		hInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		sxInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		syInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		rotationInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		alphaInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		xPivotInput.removeEventListener(Event.CHANGE, dispatchInputChange);
		yPivotInput.removeEventListener(Event.CHANGE, dispatchInputChange);
	}

	function showSelectedAsset(asset:Sprite)
	{
		selectedAsset = asset;
		removeChangeListeners();
		if (asset != null)
		{
			nameItem.visible = true;
			typeItem.visible = true;
			transformItem.visible = true;

			nameInput.text = asset.name;
			if (Std.is(asset, KadabraImage))
			{
				var kImage:KadabraImage = cast asset;
				typeInput.text = "image";

				sizeItem.visible = true;
				sxInput.text = "" + kImage.image.scaleX;
				syInput.text = "" + kImage.image.scaleY;
				wInput.text = "" + kImage.image.width;
				hInput.text = "" + kImage.image.height;

				pivots.visible = true;

				xPivotInput.text = "" + kImage.pivotX;
				yPivotInput.text = "" + kImage.pivotY;
				alphaInput.text = "" + selectedAsset.getChildAt(0).alpha;
			}
			else if (Std.is(asset, KadabraPoint))
			{
				typeInput.text = "point";
				sizeItem.visible = false;
				pivots.visible = false;
			}
			xInput.text = "" + asset.x;
			yInput.text = "" + asset.y;

			rotationInput.text = "" + asset.rotation;
		} else
		{
			nameItem.visible = false;
			typeItem.visible = false;
			transformItem.visible = false;
			sizeItem.visible = false;
			pivots.visible = false;
		}

		addChangeListeners();
	}

	function updateData()
	{
		removeChangeListeners();
		xInput.text = "" + selectedAsset.x;
		yInput.text = "" + selectedAsset.y;
		rotationInput.text = "" + selectedAsset.rotation;
		if (Std.is(selectedAsset, KadabraImage))
		{
			var asset:KadabraImage = cast selectedAsset;
			alphaInput.text = "" + asset.image.alpha;
			xPivotInput.text = "" + asset.pivotX;
			yPivotInput.text = "" + asset.pivotY;
			sxInput.text = "" + asset.image.scaleX;
			syInput.text = "" + asset.image.scaleY;
			wInput.text = "" + asset.image.width;
			hInput.text = "" + asset.image.height;
		}
		addChangeListeners();
	}

	function dispatchInputChange(e:Event)
	{
		trace("input change");
		var currentInput = cast(e.target, TextInput);

		if (currentInput.name == "nameInput" || currentInput.name == "typeInput")
		{
			if (currentInput.text == "")
			{ // if the name input is empty, its default value is the type name
				currentInput.text += typeInput.text; // TODO increment number
			}
		} else
		{
			if (currentInput.name == "aTransform")
			{
				var f = Std.parseFloat(currentInput.text);
				var fm = KadabraUtils.bound(f, 0, 1);
				if (f != fm)
				{
					// avoid re-dispatching the event change
					currentInput.removeEventListener(Event.CHANGE, dispatchInputChange);
					currentInput.text = "" + fm;
					currentInput.addEventListener(Event.CHANGE, dispatchInputChange);
				}
			}
			if (currentInput.text == "")
			{
				// avoid re-dispatching the event change
				currentInput.removeEventListener(Event.CHANGE, dispatchInputChange);
				// if a number input is empty, its default value is "0"
				currentInput.text = "0";
				currentInput.addEventListener(Event.CHANGE, dispatchInputChange);
			}
		}

		inputChange.dispatch(currentInput);
	}
}
