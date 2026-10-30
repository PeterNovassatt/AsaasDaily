using System.CodeDom.Compiler;
using System.Diagnostics.CodeAnalysis;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Xaml;

namespace DailyDriver.Features.Configuration;

[XamlFilePath("Features/Configuration/ConfigurationPage.xaml")]
[XamlCompilation(/*Could not decode attribute arguments.*/)]
public class ConfigurationPage : ContentPage
{
	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private ContentPage Root;

	public ConfigurationPage()
	{
		InitializeComponent();
		((BindableObject)this).BindingContext = new ConfigurationPageViewModel();
	}

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	[MemberNotNull("Root")]
	private void InitializeComponent()
	{
		Extensions.LoadFromXaml<ConfigurationPage>(this, typeof(ConfigurationPage));
		Root = NameScopeExtensions.FindByName<ContentPage>((Element)(object)this, "Root");
	}
}
