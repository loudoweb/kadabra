import assets.KadabraImage;
import assets.KadabraAsset;
import openfl.geom.Point;
import openfl.events.MouseEvent;
import lime.ui.KeyCode;
import io.InputPoll;
import openfl.display.Sprite;

using utils.KadabraUtils;

// TODO add flag isDirty to only draw graphics when necessary
class TransformTool extends Sprite
{
	public static var onTransform:lime.app.Event<Sprite->Void> = new lime.app.Event<Sprite->Void>();

	public var isActive(default, null):Bool;

	public var asset(default, null):KadabraAsset;

	public var gizmosHeight:Float;
	public var gizmosWidth:Float;

	var upOrigin:Float;
	var downOrigin:Float;
	var leftOrigin:Float;
	var rightOrigin:Float;

	var currentGizmo:Gizmo;

	var defaultAngle:Float;

	var pivotEnabled = true;

	var ratio:Float;

	var gizmoOffsetX:Float;
	var gizmoOffsetY:Float;

	var defaultX:Float;
	var defaultY:Float;

	var radianRotation:Float;
	var cosinus:Float;
	var sinus:Float;

	public var scaling = false;

	var gizmoUL:Gizmo;
	var gizmoU:Gizmo;
	var gizmoUR:Gizmo;
	var gizmoL:Gizmo;
	var gizmoR:Gizmo;
	var gizmoDL:Gizmo;
	var gizmoD:Gizmo;
	var gizmoDR:Gizmo;

	var rotationGizmo:Gizmo;

	public var pivot:Pivot;

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

		rotationGizmo = new Gizmo(0, 0);

		pivot = new Pivot();

		addChild(gizmoUL);
		addChild(gizmoU);
		addChild(gizmoUR);
		addChild(gizmoL);
		addChild(gizmoR);
		addChild(gizmoDL);
		addChild(gizmoD);
		addChild(gizmoDR);

		addChild(rotationGizmo);

		addChild(pivot);
	}

	function onKeyDown(key:KKey):Void
	{
		switch (key.charCode)
		{
			case(KeyCode.P):
				if (pivotEnabled)
				{
					removeChild(pivot);
					pivotEnabled = false;
				}
				else
				{
					addChild(pivot);
					pivotEnabled = true;
				}
		}
	}

	function onMouseDown(e:MouseEvent):Void
	{
		if (Std.is(e.target, Gizmo))
		{
			currentGizmo = cast(e.target, Gizmo);
			var xValue = currentGizmo.x;
			var yValue = currentGizmo.y;

			if (currentGizmo.isRotate)
			{ // gizmo offsets depend on pivot coordinates only during rotation
				xValue -= pivot.x;
				yValue -= pivot.y;
			}

			gizmoOffsetX = e.stageX / scaleX - ((xValue) * cosinus - (yValue) * sinus);
			gizmoOffsetY = e.stageY / scaleY - ((xValue) * sinus + (yValue) * cosinus);

			defaultAngle = Math.atan((currentGizmo.x - pivot.x) / (currentGizmo.y - pivot.y));
			defaultX = asset.x + (pivot.x * cosinus - pivot.y * sinus);
			defaultY = asset.y + (pivot.x * sinus + pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, event_onTransform);
			stage.addEventListener(MouseEvent.MOUSE_UP, event_mouseUp);
		}
		else if (Std.is(e.target, Pivot))
		{
			// gizmoOffsets are here used for the pivot
			gizmoOffsetX = e.stageX / scaleX - (pivot.x * cosinus - pivot.y * sinus);
			gizmoOffsetY = e.stageY / scaleY - (pivot.x * sinus + pivot.y * cosinus);

			stage.addEventListener(MouseEvent.MOUSE_MOVE, event_dragPivot);
			stage.addEventListener(MouseEvent.MOUSE_UP, event_mouseUp);
		}
	}

	function event_mouseUp(e:MouseEvent):Void
	{
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, event_onTransform);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, event_dragPivot);
		stage.removeEventListener(MouseEvent.MOUSE_UP, event_mouseUp);
	}

	function upSide(x:Float, y:Float, a:Point, b:Point)
	{
		return ((b.y - a.y) * (x - a.x) - (b.x - a.x) * (y - a.y)) >= 0;
	}

	function event_onTransform(e:MouseEvent):Void
	{
		if (currentGizmo.isRotate)
		{
			rotate(e);
		} else
		{
			scale(e);
		}

		var oldGizmosHeight = gizmosHeight;
		var oldGizmosWidth = gizmosWidth;
		gizmosHeight = downOrigin - upOrigin;
		gizmosWidth = rightOrigin - leftOrigin;

		// TODO multi select + other asset type
		// image dimensions are adjusted and asset coordinates are changed to always keep upOrigin = LeftOrigin = 0
		var kimage:KadabraImage = cast asset;
		kimage.image.width *= gizmosWidth / oldGizmosWidth;
		kimage.image.height *= gizmosHeight / oldGizmosHeight;

		asset.x += leftOrigin * cosinus - upOrigin * sinus;
		asset.y += upOrigin * cosinus + leftOrigin * sinus;

		updateGizmos(0, downOrigin - upOrigin, 0, rightOrigin - leftOrigin, pivot.x, pivot.y);

		x = leftOrigin;
		y = upOrigin;

		onTransform.dispatch(asset);
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
					aPoint = new Point(gizmosHeight * sinus, gizmosHeight * cosinus);
					bPoint = new Point(gizmosWidth * cosinus, gizmosWidth * sinus);
				}
				else if (coef > 0)
				{
					aPoint = new Point(x, y);
					bPoint = new Point(gizmosWidth * cosinus - gizmosHeight * sinus,
						gizmosHeight * cosinus + gizmosWidth * sinus);
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
		newAngle = newAngle.toDegree().roundDecimal(2);

		if (e.stageY / scaleY - gizmoOffsetY >= 0)
		{
			// adjusts the angle if the mouse is under the pivot
			newAngle += 180;
		}

		asset.rotation = -newAngle;

		radianRotation = asset.rotation.toRadians();
		cosinus = Math.cos(radianRotation);
		sinus = Math.sin(radianRotation);

		asset.x = defaultX - pivot.x * cosinus + pivot.y * sinus;
		asset.y = defaultY - pivot.x * sinus - pivot.y * cosinus;
	}

	function event_dragPivot(e:MouseEvent):Void
	{
		var pivotX = (e.stageX / scaleX - gizmoOffsetX) * cosinus + (e.stageY / scaleY - gizmoOffsetY) * sinus;
		var pivotY = (e.stageY / scaleY - gizmoOffsetY) * cosinus - (e.stageX / scaleX - gizmoOffsetX) * sinus;

		// minimum & maximum positions
		pivotX = pivotX.bound(0, gizmosWidth);
		pivotY = pivotY.bound(0, gizmosHeight);

		// TODO group
		var kImage:KadabraImage = cast asset;
		kImage.pivotX = (pivotX / gizmosWidth).roundDecimal(2);
		kImage.pivotY = (pivotY / gizmosHeight).roundDecimal(2);
		pivot.setPivot(kImage.pivotX, kImage.pivotY);
		pivot.updatePos(gizmosWidth, gizmosHeight);

		onTransform.dispatch(asset);
		e.updateAfterEvent();
	}

	public function updateGizmos(upOrigin:Float, downOrigin:Float, leftOrigin:Float, rightOrigin:Float, pivotX:Float,
			pivotY:Float)
	{
		this.upOrigin = upOrigin;
		this.downOrigin = downOrigin;
		this.leftOrigin = leftOrigin;
		this.rightOrigin = rightOrigin;

		this.gizmosHeight = downOrigin - upOrigin;
		this.gizmosWidth = rightOrigin - leftOrigin;

		var ratio = this.gizmosHeight / this.gizmosWidth;

		this.pivot.setPivot(pivotX, pivotY);

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

		rotationGizmo.x = gizmosWidth / 2;
		rotationGizmo.y = -50;

		pivot.updatePos(gizmosWidth, gizmosHeight);

		graphics.clear();
		graphics.lineStyle(1, 0, 1);
		graphics.moveTo(0, 0);
		graphics.lineTo(gizmosWidth, 0);
		graphics.lineTo(gizmosWidth, gizmosHeight);
		graphics.lineTo(0, gizmosHeight);
		graphics.lineTo(0, 0);
		graphics.moveTo(gizmosWidth / 2, 0);
		graphics.lineTo(gizmosWidth / 2, -50);

		this.x = leftOrigin;
		this.y = upOrigin;
	}

	public function active(parent:Sprite, asset:KadabraAsset):Void
	{
		if (parent != null)
		{
			unactive();
			isActive = true;
			parent.addChild(this);
			this.asset = asset;
			InputPoll.onKeyDown.add(onKeyDown);
			this.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);
		}
	}

	public function unactive():Void
	{
		if (isActive)
			return;

		if (parent != null)
			parent.removeChild(this);

		isActive = false;

		InputPoll.onKeyDown.remove(onKeyDown);
		this.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, true);
	}
}
