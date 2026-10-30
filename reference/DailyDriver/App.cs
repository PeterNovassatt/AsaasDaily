using System.CodeDom.Compiler;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Xaml;
using Microsoft.Maui.Graphics;

namespace DailyDriver;

[XamlFilePath("App.xaml")]
[XamlCompilation(/*Could not decode attribute arguments.*/)]
public class App : Application
{
	public App()
	{
		//IL_0015: Unknown result type (might be due to invalid IL or missing references)
		//IL_001a: Unknown result type (might be due to invalid IL or missing references)
		//IL_0030: Expected Obj, but got Unknown
		InitializeComponent();
		((Application)this).MainPage = (Page)new NavigationPage((Page)(object)new MainPage())
		{
			BarBackgroundColor = Color.FromArgb("#001074")
		};
	}

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private void InitializeComponent()
	{
		Extensions.LoadFromXaml<App>(this, typeof(App));
	}
}
