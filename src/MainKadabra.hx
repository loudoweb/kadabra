import panels.PropertiesPanel;
import panels.HierarchyPanel;
import utils.KadabraUtils;
import utils.UIFactory;
import panels.ToolPanel;
import feathers.events.FeathersEvent;
import feathers.events.ScrollEvent;
import feathers.controls.HScrollBar;
import feathers.utils.Scroller;
import feathers.controls.ScrollContainer;
import feathers.data.ArrayHierarchicalCollection;
import feathers.controls.TreeView;
import crashdumper.CrashDumper;
import crashdumper.SessionData;
import openfl.display.Scene;
import feathers.layout.AnchorLayoutData;
import feathers.controls.TextInput;
import feathers.layout.AnchorLayout;
import openfl.display.Sprite;
import feathers.controls.HDividedBox;
import openfl.events.MouseEvent;
import feathers.controls.Button;
import openfl.events.Event;
import feathers.layout.VerticalLayout;
import feathers.layout.HorizontalLayoutData;
import feathers.controls.Panel;
import openfl.text.TextFormat;
import feathers.skins.RectangleSkin;
import feathers.controls.LayoutGroup;
import feathers.layout.HorizontalLayout;
import feathers.controls.Application;
import feathers.controls.Label;
import openfl.Assets;

class MainKadabra extends Application
{
	var panel:LayoutGroup;
	var box:HDividedBox;
	var canvasContainer:CanvasContainer;

	public function new()
	{
		super();

		// init fonts
		KadabraUtils.initFonts("assets/fonts/Roboto-Regular.ttf");

		// crash logs system

		var unique_id:String = SessionData.generateID("kadabra_");
		var crashDumper = new CrashDumper(unique_id);

		// application

		var semiDarkSkin = new RectangleSkin();
		semiDarkSkin.fill = SolidColor(0x333333);

		var greySkin = new RectangleSkin();
		semiDarkSkin.fill = SolidColor(0x404040);

		var vLayout = new VerticalLayout();
		vLayout.horizontalAlign = JUSTIFY;
		vLayout.verticalAlign = JUSTIFY;

		panel = new LayoutGroup();
		panel.layout = vLayout;
		panel.width = stage.stageWidth;
		panel.height = stage.stageHeight;
		panel.addChild(UIFactory.createHeader(stage.application.meta.get("name"), "icon", 24));
		panel.addChild(createMainBoxes(semiDarkSkin));

		addChild(panel);

		stage.addEventListener(Event.RESIZE, onResize);

		stage.addEventListener(Event.ENTER_FRAME, onUpdate);
	}

	function createMainBoxes(skin:RectangleSkin):HDividedBox
	{
		box = new HDividedBox();
		box.height = stage.stageHeight - KadabraUtils.HEADER_THICKNESS;
		box.backgroundSkin = skin;

		var rect = new RectangleSkin();
		rect.fill = KadabraUtils.SCENE_FILL;
		rect.height = 2500;
		rect.width = 5000;
		rect.mouseEnabled = false;

		var tool = new ToolPanel();

		var hierarchy = new HierarchyPanel();

		canvasContainer = new CanvasContainer();

		var properties = new PropertiesPanel();

		box.addChild(tool);
		box.addChild(hierarchy);
		box.addChild(canvasContainer);
		box.addChild(properties);

		return box;
	}

	function onResize(e:Event):Void
	{
		panel.width = stage.stageWidth;
		panel.height = stage.stageHeight;
		box.height = stage.stageHeight - KadabraUtils.HEADER_THICKNESS;
	}

	function onUpdate(e:Event):Void
	{
		// stage.window.x, stage.window.y; //pour bouger window avec borderless false
	}
}
