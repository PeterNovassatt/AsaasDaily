using System.CodeDom.Compiler;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Xaml;

namespace DailyDriver.Features.Configuration;

[XamlFilePath("Features/Configuration/ConfigurationAtlassianPersonView.xaml")]
[XamlCompilation(/*Could not decode attribute arguments.*/)]
public class ConfigurationAtlassianPersonView : ContentView
{
	public ConfigurationAtlassianPersonView()
	{
		InitializeComponent();
	}

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private void InitializeComponent()
	{
		Extensions.LoadFromXaml<ConfigurationAtlassianPersonView>(this, typeof(ConfigurationAtlassianPersonView));
	}
}
