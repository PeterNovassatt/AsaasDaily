using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Maui.Graphics;

namespace DailyDriver.Features.Charts;

public class DonutChartDrawable : IDrawable
{
	private const float Thickness = 14f;

	private const float GapDegrees = 2f;

	public required List<(int Value, Color Color)> Slices { get; init; }

	public required Color TrackColor { get; init; }

	public required Color CenterTextColor { get; init; }

	public double CenterFontSize { get; init; } = 22.0;

	public void Draw(ICanvas canvas, RectF rect)
	{
		//IL_0073: Unknown result type (might be due to invalid IL or missing references)
		//IL_00d0: Unknown result type (might be due to invalid IL or missing references)
		//IL_014c: Unknown result type (might be due to invalid IL or missing references)
		float num = Math.Min(rect.Width, rect.Height);
		if (num <= 28f)
		{
			return;
		}
		float num2 = 7f;
		RectF val = new RectF(rect.X + (rect.Width - num) / 2f + num2, rect.Y + (rect.Height - num) / 2f + num2, num - 14f, num - 14f);
		canvas.StrokeSize = 14f;
		canvas.StrokeLineCap = (LineCap)0;
		int num3 = Slices.Sum(((int Value, Color Color) slice) => slice.Value);
		if (num3 == 0)
		{
			canvas.StrokeColor = TrackColor;
			CanvasExtensions.DrawEllipse(canvas, val);
			return;
		}
		float num4 = 90f;
		foreach (var (num5, strokeColor) in Slices)
		{
			if (num5 > 0)
			{
				float num6 = 360f * (float)num5 / (float)num3;
				float num7 = ((num6 > 4f) ? 2f : 0f);
				canvas.StrokeColor = strokeColor;
				CanvasExtensions.DrawArc(canvas, val, num4 - num7 / 2f, num4 - num6 + num7 / 2f, true, false);
				num4 -= num6;
			}
		}
		canvas.FontColor = CenterTextColor;
		canvas.FontSize = (float)CenterFontSize;
		canvas.DrawString(num3.ToString(), val.X, val.Y, val.Width, val.Height, (HorizontalAlignment)1, (VerticalAlignment)1, (TextFlow)0, 0f);
	}
}
