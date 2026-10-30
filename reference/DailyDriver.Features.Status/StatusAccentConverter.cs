using System;
using System.Globalization;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Status;

public class StatusAccentConverter : IValueConverter
{
	public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
	{
		return StatusPalette.Accent(value as string);
	}

	public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
	{
		throw new NotSupportedException();
	}
}
