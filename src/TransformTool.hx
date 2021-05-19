import openfl.display.Sprite;

class TransformTool extends Sprite
{
	public var gizmosHeight:Float;
	public var gizmosWidth:Float;

	var gizmoUL:Gizmo;
	var gizmoU:Gizmo;
	var gizmoUR:Gizmo;
	var gizmoL:Gizmo;
	var gizmoR:Gizmo;
	var gizmoDL:Gizmo;
	var gizmoD:Gizmo;
	var gizmoDR:Gizmo;

	public function new()
	{
		super();

		gizmoDL = new Gizmo(1, -1);
		gizmoD = new Gizmo(1, 0);
		gizmoDR = new Gizmo(1, 1);
		gizmoUL = new Gizmo(-1, -1);
		gizmoU = new Gizmo(-1, 0);
		gizmoUR = new Gizmo(-1, 1);
		gizmoL = new Gizmo(0, -1);
		gizmoR = new Gizmo(0, 1);

		addChild(gizmoUL);
		addChild(gizmoU);
		addChild(gizmoUR);
		addChild(gizmoL);
		addChild(gizmoR);
		addChild(gizmoDL);
		addChild(gizmoD);
		addChild(gizmoDR);
	}

	public function updateGizmos()
	{
		gizmoU.x = gizmosWidth / 2;

		gizmoUR.x = gizmosWidth;

		gizmoL.y = gizmosHeight / 2;

		gizmoR.x = gizmosWidth;
		gizmoR.y = gizmosHeight / 2;

		gizmoDL.y = gizmosHeight;

		gizmoD.x = gizmosWidth / 2;
		gizmoD.y = gizmosHeight;

		gizmoDR.x = gizmosWidth;
		gizmoDR.y = gizmosHeight;
	}
}
