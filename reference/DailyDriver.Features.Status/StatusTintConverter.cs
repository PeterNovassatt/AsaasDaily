using System;
using System.Globalization;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Status;

public class StatusTintConverter : IValueConverter
{
	public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
	{
		return StatusPalette.Tint(value as string);
	}

	public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
	{
		throw new NotSupportedException();
	}
}
