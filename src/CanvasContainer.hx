import openfl.geom.Point;
import utils.KadabraUtils;
import openfl.ui.Keyboard;
import io.InputPoll;
import openfl.events.MouseEvent;
import openfl.ui.Mouse;
import openfl.events.Event;
import feathers.events.ScrollEvent;
import feathers.skins.RectangleSkin;
import feathers.controls.ScrollContainer;

class CanvasContainer extends ScrollContainer
{
	var rect:RectangleSkin;

	public var canvas:KadabraCanvas;

	var zoomValue = 1.;

	public function new()
	{
		super();

		canvas = new KadabraCanvas();

		rect = new RectangleSkin();
		rect.fill = KadabraUtils.CANVAS_FILL;

		if (canvas.background.width < 800)
		{
			rect.width = canvas.background.width * 3;
			canvas.x = canvas.background.width;
		}
		else
		{
			rect.width = canvas.background.width + 1600;
			canvas.x = 800;
		}

		if (canvas.background.height < 800)
		{
			rect.height = canvas.background.height * 3;
			canvas.y = canvas.background.height;
		}
		else
		{
			rect.height = canvas.background.height + 1600;
			canvas.y = 800;
		}
		rect.mouseEnabled = false;

		addChild(rect);
		addChild(canvas);
		scrollX = canvas.x;
		scrollY = canvas.y;

		canvas.scrollX = scrollX;
		canvas.scrollY = scrollY;

		addEventListener(ScrollEvent.SCROLL_COMPLETE, scrollUpdate);
		addEventListener(Event.ENTER_FRAME, scrollAuto);

		InputPoll.onMouseWheel.add(zoom);
	}

	function scrollUpdate(e:ScrollEvent):Void
	{
		canvas.scrollX = scrollX;
		canvas.scrollY = scrollY;
	}

	function scrollAuto(e:Event):Void
	{
		if (canvas.dragging)
		{
			scrollX += canvas.scrollSpeedX;
			scrollY += canvas.scrollSpeedY;

			if (scrollX < 0)
			{
				scrollX = 0;
			}
			else if (scrollX > maxScrollX)
			{
				scrollX = maxScrollX;
			}
			else
			{
				var i = 0;
				for (image in canvas.selectedImages)
				{
					image.x += canvas.scrollSpeedX;
					canvas.offsets[i * 2] -= canvas.scrollSpeedX;
					++i;
				}
			}

			if (scrollY <= 0)
			{
				scrollY = 0;
			}
			else if (scrollY >= maxScrollY)
			{
				scrollY = maxScrollY;
			}
			else
			{
				var i = 0;
				for (image in canvas.selectedImages)
				{
					image.y += canvas.scrollSpeedY;
					canvas.offsets[i * 2 + 1] -= canvas.scrollSpeedY;
					++i;
				}
			}

			canvas.scrollX = scrollX;
			canvas.scrollY = scrollY;
		}
	}

	function zoom(e:MouseEvent)
	{
		if (InputPoll.isKeyDown(Keyboard.CONTROL))
		{
			e.stopImmediatePropagation();

			// mouse position
			var pt = new Point(e.stageX, e.stageY);
			pt = rect.globalToLocal(pt);

			// zoom
			var preZoom = zoomValue;
			zoomValue += (e.delta / 1000);
			// max zoom
			if (zoomValue > 4)
				zoomValue = 4;
			// min zoom
			if (zoomValue < width / rect.width * rect.scaleX)
				zoomValue = width / rect.width * rect.scaleX;

			// scale
			canvas.scaleX = canvas.scaleY = rect.scaleX = rect.scaleY = zoomValue;

			// center scene
			canvas.x = (rect.width - canvas.width) * 0.5;
			canvas.y = (rect.height - canvas.height) * 0.5;
			// scroll to mouse position
			refreshViewPortBoundsForLayout();
			restrictedScrollX += (pt.x * zoomValue - pt.x * preZoom);
			restrictedScrollY += (pt.y * zoomValue - pt.y * preZoom);
			refreshScrollRect();
		} else if (InputPoll.isKeyDown(Keyboard.R))
		{
			e.stopImmediatePropagation();
			// temp ?
			resetZoom();
		}
	}

	function resetZoom()
	{
		zoomValue = 1.;
		rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = 1.;
		canvas.x = (rect.width - canvas.width) * 0.5;
		canvas.y = (rect.height - canvas.height) * 0.5;
		refreshViewPortBoundsForLayout();
		restrictedScrollX = maxScrollX / 2;
		restrictedScrollY = maxScrollY / 2;
	}

	function fitZoom()
	{
		if (rect.width < rect.height)
		{
			var newZoomValue = (width - scrollBarY.width) * zoomValue / rect.width;
			canvas.x *= (newZoomValue / zoomValue);
			canvas.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
		}
		else
		{
			var newZoomValue = (height - scrollBarX.height) * zoomValue / rect.height;
			canvas.x *= (newZoomValue / zoomValue);
			canvas.y *= (newZoomValue / zoomValue);
			zoomValue = newZoomValue;
			rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
		}
	}

	function onMouseUp(e:MouseEvent)
	{
		canvas.dragging = false;
	}
}
