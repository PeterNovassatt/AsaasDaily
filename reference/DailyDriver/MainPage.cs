using System;
using System.CodeDom.Compiler;
using System.Diagnostics.CodeAnalysis;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using DailyDriver.Features.Configuration;
using Microsoft.Maui;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Xaml;

namespace DailyDriver;

[XamlFilePath("MainPage.xaml")]
[XamlCompilation(/*Could not decode attribute arguments.*/)]
public class MainPage : ContentPage
{
	private const uint ExitDuration = 130u;

	private const uint EnterDuration = 260u;

	private const double SlideOffset = 26.0;

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private ContentPage Page;

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private Grid SpeakerStage;

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private Border NextPanel;

	public MainPage()
	{
		InitializeComponent();
		((BindableObject)this).BindingContext = new MainPageViewModel
		{
			SpeakerExitAnimation = AnimateStageOut,
			SpeakerEnterAnimation = AnimateStageIn
		};
	}

	private void ImageButton_OnClicked(object sender, EventArgs e)
	{
		((NavigableElement)Application.Current.MainPage).Navigation.PushAsync((Page)(object)new ConfigurationPage());
	}

	protected override void OnAppearing()
	{
		((Page)this).OnAppearing();
		(((BindableObject)this).BindingContext as MainPageViewModel).OnAppearing();
	}

	private Task AnimateStageOut()
	{
		InlineArray3<Task<bool>> buffer = default;
		buffer[0] = ViewExtensions.FadeTo((VisualElement)(object)SpeakerStage, 0.0, 130u, Easing.CubicIn);
		buffer[1] = ViewExtensions.TranslateTo((VisualElement)(object)SpeakerStage, -26.0, 0.0, 130u, Easing.CubicIn);
		buffer[2] = ViewExtensions.FadeTo((VisualElement)(object)NextPanel, 0.0, 130u, Easing.CubicIn);
		return Task.WhenAll<bool>(buffer);
	}

	private Task AnimateStageIn()
	{
		((VisualElement)SpeakerStage).TranslationX = 26.0;
		InlineArray3<Task<bool>> buffer = default;
		buffer[0] = ViewExtensions.FadeTo((VisualElement)(object)SpeakerStage, 1.0, 260u, Easing.CubicOut);
		buffer[1] = ViewExtensions.TranslateTo((VisualElement)(object)SpeakerStage, 0.0, 0.0, 260u, Easing.CubicOut);
		buffer[2] = ViewExtensions.FadeTo((VisualElement)(object)NextPanel, 1.0, 260u, Easing.CubicOut);
		return Task.WhenAll<bool>(buffer);
	}

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	[MemberNotNull("Page")]
	[MemberNotNull("SpeakerStage")]
	[MemberNotNull("NextPanel")]
	private void InitializeComponent()
	{
		Extensions.LoadFromXaml<MainPage>(this, typeof(MainPage));
		Page = NameScopeExtensions.FindByName<ContentPage>((Element)(object)this, "Page");
		SpeakerStage = NameScopeExtensions.FindByName<Grid>((Element)(object)this, "SpeakerStage");
		NextPanel = NameScopeExtensions.FindByName<Border>((Element)(object)this, "NextPanel");
	}
}
