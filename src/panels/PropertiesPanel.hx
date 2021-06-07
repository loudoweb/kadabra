package panels;

import utils.KadabraUtils;
import feathers.layout.FormLayout;
import feathers.controls.TextInput;
import feathers.controls.FormItem;
import feathers.controls.Form;
import feathers.layout.VerticalLayout;
import openfl.events.Event;
import openfl.display.Sprite;
import feathers.layout.HorizontalLayoutData;
import utils.UIFactory;
import feathers.controls.LayoutGroup;

class PropertiesPanel extends LayoutGroup
{
	var selectedAsset:Sprite;

	var form:Form;
	var nameItem:FormItem;
	var nameInput:TextInput;
	var typeItem:FormItem;
	var typeInput:TextInput;
	var xItem:FormItem;
	var xInput:TextInput;
	var yItem:FormItem;
	var yInput:TextInput;
	var rotationItem:FormItem;
	var rotationInput:TextInput;

	public static var inputChange:lime.app.Event<TextInput->Void>;

	public function new():Void
	{
		super();

		width = 300;
		minWidth = 300;
		maxWidth = 600;
		layoutData = new HorizontalLayoutData(100.0);

		inputChange = new lime.app.Event<TextInput->Void>();

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = LEFT;
		_layout.gap = 18;
		layout = _layout;

		form = new Form();

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

		xItem = new FormItem();
		xItem.textPosition = LEFT;
		xItem.text = "X : ";
		xItem.textFormat = KadabraUtils.FONT_NORMAL;
		xInput = new TextInput();
		xInput.name = "xInput";
		xInput.restrict = "0-9\\.";
		xItem.content = xInput;

		yItem = new FormItem();
		yItem.textPosition = LEFT;
		yItem.text = "Y : ";
		yItem.textFormat = KadabraUtils.FONT_NORMAL;
		yInput = new TextInput();
		yInput.name = "yInput";
		yInput.restrict = "0-9\\.";
		yItem.content = yInput;

		rotationItem = new FormItem();
		rotationItem.textPosition = LEFT;
		rotationItem.text = "Rotation : ";
		rotationItem.textFormat = KadabraUtils.FONT_NORMAL;
		rotationInput = new TextInput();
		rotationInput.name = "rotationInput";
		rotationInput.restrict = "0-9\\.";
		rotationItem.content = rotationInput;

		addChild(UIFactory.createHeader("Properties"));
		addChild(form);

		form.addChild(nameItem);
		form.addChild(typeItem);
		form.addChild(xItem);
		form.addChild(yItem);
		form.addChild(rotationItem);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
	}

	function onAddedToStage(e:Event)
	{
		KadabraScene.onSelectAsset.add(showSelectedAsset);
		KadabraScene.onAssetUpdated.add(updateData);
		nameInput.addEventListener(Event.CHANGE, dispatchInputChange);
		xInput.addEventListener(Event.CHANGE, dispatchInputChange);
		yInput.addEventListener(Event.CHANGE, dispatchInputChange);
		rotationInput.addEventListener(Event.CHANGE, dispatchInputChange);
	}

	function showSelectedAsset(asset:Sprite)
	{
		selectedAsset = asset;

		nameInput.text = asset.name;
		if (Std.is(asset, KadabraImage))
		{
			typeInput.text = "image";
		}
		else if (Std.is(asset, KadabraPoint))
		{
			typeInput.text = "point";
		}
		xInput.text = "" + asset.x;
		yInput.text = "" + asset.y;
		rotationInput.text = "" + asset.rotation;
	}

	function updateData()
	{
		xInput.text = "" + selectedAsset.x;
		yInput.text = "" + selectedAsset.y;
		rotationInput.text = "" + selectedAsset.rotation;
	}

	function dispatchInputChange(e:Event)
	{
		var currentInput = cast(e.target, TextInput);

		if (currentInput.name == "xInput" || currentInput.name == "yInput" || currentInput.name == "rotationInput")
		{
			if (currentInput.text == "")
			{
				// avoid re-dispatching the event change
				currentInput.removeEventListener(Event.CHANGE, dispatchInputChange);
				// if a number input is empty, its default value is "0"
				currentInput.text = "0";
				currentInput.addEventListener(Event.CHANGE, dispatchInputChange);
			}
		}
		else
		{
			if (currentInput.text == "")
			{ // if the name input is empty, its default value is the type name
				currentInput.text += typeInput.text; // TODO increment number
			}
		}

		inputChange.dispatch(currentInput);
	}
}
