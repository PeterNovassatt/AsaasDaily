#define TRACE
using System;
using System.Diagnostics;
using System.Threading.Tasks;
using CommunityToolkit.Maui.Core.Extensions;
using Microsoft.Maui.Graphics;

namespace Microsoft.Maui.Controls;

internal static class ColorAnimationExtensions_SearchBar
{
	public static Task<bool> TextColorTo(this SearchBar element, Color color, uint rate = 16u, uint length = 250u, Easing? easing = null)
	{
		//IL_005b: Unknown result type (might be due to invalid IL or missing references)
		//IL_0060: Unknown result type (might be due to invalid IL or missing references)
		//IL_0085: Unknown result type (might be due to invalid IL or missing references)
		//IL_00aa: Unknown result type (might be due to invalid IL or missing references)
		//IL_00cf: Unknown result type (might be due to invalid IL or missing references)
		ArgumentNullException.ThrowIfNull(element, "element");
		ArgumentNullException.ThrowIfNull(color, "color");
		if (element == null)
		{
			throw new ArgumentException("Element must implement ITextStyle", "element");
		}
		if (((InputView)element).TextColor == null)
		{
			Color val = (((InputView)element).TextColor = Colors.Transparent);
		}
		TaskCompletionSource<bool> animationCompletionSource = new TaskCompletionSource<bool>();
		try
		{
			Animation val2 = new Animation();
			val2.Add(0.0, 1.0, GetRedTransformAnimation(element, color.Red));
			val2.Add(0.0, 1.0, GetGreenTransformAnimation(element, color.Green));
			val2.Add(0.0, 1.0, GetBlueTransformAnimation(element, color.Blue));
			val2.Add(0.0, 1.0, GetAlphaTransformAnimation(element, color.Alpha));
			val2.Commit((IAnimatable)(object)element, "TextColorTo", rate, length, easing, (Action<double, bool>)((double d, bool b) =>
			{
				animationCompletionSource.SetResult(result: true);
			}), (Func<bool>)null);
		}
		catch (ArgumentException ex)
		{
			Trace.WriteLine($"{ex.GetType().Name} thrown in {typeof(ColorAnimationExtensions_SearchBar).FullName}: {ex.Message}");
			animationCompletionSource.SetResult(result: false);
		}
		return animationCompletionSource.Task;
		static Animation GetAlphaTransformAnimation(SearchBar val3, float targetAlpha)
		{
			//IL_002e: Unknown result type (might be due to invalid IL or missing references)
			//IL_0034: Expected Obj, but got Unknown
			return new Animation((Action<double>)((double v) =>
			{
				((InputView)val3).TextColor = ((InputView)val3).TextColor.WithAlpha((float)v);
			}), (double)((InputView)val3).TextColor.Alpha, (double)targetAlpha, (Easing)null, (Action)null);
		}
		static Animation GetBlueTransformAnimation(SearchBar val3, float targetBlue)
		{
			//IL_002e: Unknown result type (might be due to invalid IL or missing references)
			//IL_0034: Expected Obj, but got Unknown
			return new Animation((Action<double>)((double v) =>
			{
				((InputView)val3).TextColor = ColorConversionExtensions.WithBlue(((InputView)val3).TextColor, v);
			}), (double)((InputView)val3).TextColor.Blue, (double)targetBlue, (Easing)null, (Action)null);
		}
		static Animation GetGreenTransformAnimation(SearchBar val3, float targetGreen)
		{
			//IL_002e: Unknown result type (might be due to invalid IL or missing references)
			//IL_0034: Expected Obj, but got Unknown
			return new Animation((Action<double>)((double v) =>
			{
				((InputView)val3).TextColor = ColorConversionExtensions.WithGreen(((InputView)val3).TextColor, v);
			}), (double)((InputView)val3).TextColor.Green, (double)targetGreen, (Easing)null, (Action)null);
		}
		static Animation GetRedTransformAnimation(SearchBar val3, float targetRed)
		{
			//IL_002e: Unknown result type (might be due to invalid IL or missing references)
			//IL_0034: Expected Obj, but got Unknown
			return new Animation((Action<double>)((double v) =>
			{
				((InputView)val3).TextColor = ColorConversionExtensions.WithRed(((InputView)val3).TextColor, v);
			}), (double)((InputView)val3).TextColor.Red, (double)targetRed, (Easing)null, (Action)null);
		}
	}
}
