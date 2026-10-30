using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.Maui.Graphics;

namespace DailyDriver.Features.Charts;

public class BarChartDrawable : IDrawable
{
	private const float Radius = 3f;

	private const float Gap = 6f;

	private const float MinBarHeight = 3f;

	public required List<int> Values { get; init; }

	public required Color BarColor { get; init; }

	public required Color HighlightColor { get; init; }

	public int HighlightIndex { get; init; } = -1;

	public void Draw(ICanvas canvas, RectF rect)
	{
		if (Values.Count == 0)
		{
			return;
		}
		int num = Values.Max();
		if (num <= 0)
		{
			return;
		}
		float num2 = (rect.Width - 6f * (float)(Values.Count - 1)) / (float)Values.Count;
		if (!(num2 <= 0f))
		{
			for (int i = 0; i < Values.Count; i++)
			{
				float num3 = Math.Max(rect.Height * (float)Values[i] / (float)num, 3f);
				float num4 = rect.X + (float)i * (num2 + 6f);
				float num5 = rect.Y + rect.Height - num3;
				canvas.FillColor = ((i == HighlightIndex) ? HighlightColor : BarColor);
				canvas.FillRoundedRectangle(num4, num5, num2, num3, 3f);
			}
		}
	}
}
