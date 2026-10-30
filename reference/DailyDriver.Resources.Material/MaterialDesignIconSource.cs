using Microsoft.Maui.Controls;

namespace DailyDriver.Resources.Material;

public class MaterialDesignIconSource : FontImageSource
{
	public const string FONT_FAMILY_NAME = "MaterialDesignIcons";

	public MaterialDesignIconSource()
	{
		((FontImageSource)this).FontFamily = "MaterialDesignIcons";
	}
}
