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
			if (rect.width >= width - scrollBarY.width && rect.width >= height - scrollBarX.height)
			{
				var newZoomValue = zoomValue + (e.delta / 100);
				if (newZoomValue <= 2)
				{
					canvas.x *= (newZoomValue / zoomValue);
					canvas.y *= (newZoomValue / zoomValue);
					zoomValue = newZoomValue;
					rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
				}
			}

			var contentWidth = width;
			if (maxScrollY > 0)
			{
				contentWidth -= scrollBarY.width;
			}
			if (rect.width < contentWidth)
			{
				var newZoomValue = contentWidth * zoomValue / rect.width;
				canvas.x *= (newZoomValue / zoomValue);
				canvas.y *= (newZoomValue / zoomValue);
				zoomValue = newZoomValue;
				rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
			}

			var contentHeight = height;
			if (maxScrollX > 0)
			{
				contentHeight -= scrollBarX.height;
			}
			if (rect.height < contentHeight)
			{
				var newZoomValue = contentHeight * zoomValue / rect.height;
				canvas.x *= (newZoomValue / zoomValue);
				canvas.y *= (newZoomValue / zoomValue);
				zoomValue = newZoomValue;
				rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
			}
		}
	}

	function resetZoom()
	{
		canvas.x /= zoomValue;
		canvas.y /= zoomValue;
		zoomValue = 1.;
		rect.scaleX = rect.scaleY = canvas.scaleX = canvas.scaleY = zoomValue;
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
