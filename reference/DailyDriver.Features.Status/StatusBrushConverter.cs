using System;
using System.Globalization;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Status;

public class StatusBrushConverter : IValueConverter
{
	public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
	{
		//IL_000b: Unknown result type (might be due to invalid IL or missing references)
		//IL_0011: Expected Obj, but got Unknown
		return (object)new SolidColorBrush(StatusPalette.Accent(value as string));
	}

	public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
	{
		throw new NotSupportedException();
	}
}
