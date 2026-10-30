using System;
using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;
using Microsoft.Maui.Controls.Hosting;
using Microsoft.Maui.Hosting;

namespace DailyDriver;

public static class MauiProgram
{
	public static MauiApp CreateMauiApp()
	{
		MauiAppBuilder val = MauiApp.CreateBuilder(true);
		FontsMauiAppBuilderExtensions.ConfigureFonts(AppBuilderExtensions.UseMauiCommunityToolkit(AppHostBuilderExtensions.UseMauiApp<App>(val), (Action<Options>)null), (Action<IFontCollection>)((IFontCollection fonts) =>
		{
			FontCollectionExtensions.AddFont(fonts, "MaterialDesign.ttf", "MaterialDesignIcons");
			FontCollectionExtensions.AddFont(fonts, "OpenSans-Regular.ttf", "OpenSansRegular");
			FontCollectionExtensions.AddFont(fonts, "OpenSans-Semibold.ttf", "OpenSansSemibold");
		}));
		val.Logging.AddDebug();
		return val.Build();
	}
}
