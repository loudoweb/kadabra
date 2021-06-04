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
		nameItem.textFormat = new feathers.text.TextFormat("Roboto", 20, KadabraUtils.HEADER_FONT_COLOR);
		nameInput = new TextInput();
		nameInput.name = "nameInput";
		nameItem.content = nameInput;

		typeItem = new FormItem();
		typeItem.textPosition = LEFT;
		typeItem.text = "type : ";
		typeItem.textFormat = new feathers.text.TextFormat("Roboto", 20, KadabraUtils.HEADER_FONT_COLOR);
		typeInput = new TextInput();
		typeItem.content = typeInput;
		typeInput.enabled = false;

		xItem = new FormItem();
		xItem.textPosition = LEFT;
		xItem.text = "X : ";
		xItem.textFormat = new feathers.text.TextFormat("Roboto", 20, KadabraUtils.HEADER_FONT_COLOR);
		xInput = new TextInput();
		xInput.name = "xInput";
		xItem.content = xInput;

		yItem = new FormItem();
		yItem.textPosition = LEFT;
		yItem.text = "Y : ";
		yItem.textFormat = new feathers.text.TextFormat("Roboto", 20, KadabraUtils.HEADER_FONT_COLOR);
		yInput = new TextInput();
		yInput.name = "yInput";
		yItem.content = yInput;

		rotationItem = new FormItem();
		rotationItem.textPosition = LEFT;
		rotationItem.text = "Rotation : ";
		rotationItem.textFormat = new feathers.text.TextFormat("Roboto", 20, KadabraUtils.HEADER_FONT_COLOR);
		rotationInput = new TextInput();
		rotationInput.name = "rotationInput";
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

	function onAddedToStage(event:Event)
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

	function dispatchInputChange(event:Event)
	{
		var currentInput = cast(event.target, TextInput);

		if (currentInput.name == "xInput" || currentInput.name == "yInput" || currentInput.name == "rotationInput")
		{
			if (currentInput.text == "")
			{ // if a number input is empty, its default value is "0"
				currentInput.text += 0;
			}
			// number inputs can only contain Float numbers
			currentInput.text = "" + Std.parseFloat(currentInput.text);
		}
		else
		{
			if (currentInput.text == "")
			{ // if the name input is empty, its default value is the type name
				currentInput.text += typeInput.text;
			}
		}

		inputChange.dispatch(currentInput);
	}
}
