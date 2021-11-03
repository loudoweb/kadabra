package panels;

import feathers.layout.VerticalLayoutData;
import feathers.layout.HorizontalLayoutData;
import feathers.layout.VerticalLayout;
import feathers.controls.LayoutGroup;
import openfl.display.Sprite;
import utils.UIFactory;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.TreeView;
import openfl.events.Event;

class HierarchyPanel extends LayoutGroup
{
	public static var onAssetSelected:lime.app.Event<String->Void> = new lime.app.Event<String->Void>();

	var tree:TreeView;
	var dispatch:Bool;

	public function new():Void
	{
		super();

		width = 180;
		minWidth = 180;
		maxWidth = 800;

		dispatch = true;

		var _layout = new VerticalLayout();
		_layout.horizontalAlign = LEFT;
		_layout.gap = 18;
		layout = _layout;
		layoutData = new VerticalLayoutData(100.0, 100.0);

		tree = new TreeView(new ArrayHierarchicalCollection());
		tree.layoutData = new VerticalLayoutData(100.0, 100.0);

		addChild(UIFactory.createHeader("Hierarchy"));
		addChild(tree);

		addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);

		tree.addEventListener(Event.CHANGE, treeView_changeHandler);
	}

	function onAddedToStage(e:Event)
	{
		KadabraScene.onChildAdded.add(addAsset);
		KadabraScene.onChildRemoved.add(removeAsset);
		KadabraScene.onAssetSelected.add(selectAsset);
		KadabraScene.onAssetNameChanged.add(onNameChanged);
	}

	public function addAsset(asset:Sprite):Void
	{
		var name = handleAssetName(asset.name);
		asset.name = name;
		tree.dataProvider.addAt(name, [0]);
	}

	public function removeAsset(asset:Sprite):Void
	{
		tree.dataProvider.remove(asset.name);
	}

	public function selectAsset(asset:Sprite):Void
	{
		tree.removeEventListener(Event.CHANGE, treeView_changeHandler);
		if (asset != null)
			tree.selectedItem = asset.name;
		else
			tree.selectedItem = null;
		tree.addEventListener(Event.CHANGE, treeView_changeHandler);
	}

	public function onNameChanged(oldName:String, newName:String):Void
	{
		if (tree.dataProvider.contains(oldName))
		{
			var index = tree.dataProvider.locationOf(oldName);
			tree.dataProvider.set(index, newName);
		}
	}

	public function handleAssetName(name:String):String
	{
		var _finalName = name;
		var i = 2;
		while (tree.dataProvider.contains(_finalName))
		{
			_finalName = name + Std.string(i);
			i++;
		}
		return _finalName;
	}

	function treeView_changeHandler(event:Event):Void
	{
		if (tree.selectedItem != null)
		{
			trace(tree.selectedItem);
			onAssetSelected.dispatch(tree.selectedItem);
		}
	}
}
