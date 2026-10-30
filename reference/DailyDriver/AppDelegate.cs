using Foundation;
using Microsoft.Maui;
using Microsoft.Maui.Hosting;

namespace DailyDriver;

[Register("AppDelegate")]
public class AppDelegate : MauiUIApplicationDelegate
{
	protected override MauiApp CreateMauiApp()
	{
		return MauiProgram.CreateMauiApp();
	}
}
