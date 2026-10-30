using System.CodeDom.Compiler;
using System.Diagnostics.CodeAnalysis;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using DailyDriver.Atlassian.Dtos.Issue;
using Microsoft.Maui;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Controls.Xaml;

namespace DailyDriver;

[XamlFilePath("IssueCardView.xaml")]
[XamlCompilation(/*Could not decode attribute arguments.*/)]
public class IssueCardView : ContentView
{
	public static readonly BindableProperty TapCommandProperty = BindableProperty.Create("TapCommand", typeof(ICommand), typeof(IssueCardView), (object)null, (BindingMode)2, (ValidateValueDelegate)null, (BindingPropertyChangedDelegate)null, (BindingPropertyChangingDelegate)null, (CoerceValueDelegate)null, (CreateDefaultValueDelegate)null);

	private CancellationTokenSource _waveCts;

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private ContentView Root;

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	private Label FlagIcon;

	public ICommand TapCommand
	{
		get
		{
			return (ICommand)((BindableObject)this).GetValue(TapCommandProperty);
		}
		set
		{
			((BindableObject)this).SetValue(TapCommandProperty, (object)value);
		}
	}

	public IssueCardView()
	{
		InitializeComponent();
	}

	protected override void OnBindingContextChanged()
	{
		((ContentView)this).OnBindingContextChanged();
		if (((BindableObject)this).BindingContext is AtlassianIssueDTO { IsFlagged: not false })
		{
			StartWaveAnimation();
		}
		else
		{
			StopWaveAnimation();
		}
	}

	private async void StartWaveAnimation()
	{
		_waveCts?.Cancel();
		_waveCts = new CancellationTokenSource();
		CancellationToken token = _waveCts.Token;
		((VisualElement)FlagIcon).AnchorX = 0.1;
		((VisualElement)FlagIcon).AnchorY = 0.9;
		try
		{
			while (!token.IsCancellationRequested)
			{
				await ViewExtensions.RotateTo((VisualElement)(object)FlagIcon, 20.0, 130u, Easing.SinOut);
				if (token.IsCancellationRequested)
				{
					break;
				}
				await ViewExtensions.RotateTo((VisualElement)(object)FlagIcon, -8.0, 130u, Easing.SinInOut);
				if (token.IsCancellationRequested)
				{
					break;
				}
				await ViewExtensions.RotateTo((VisualElement)(object)FlagIcon, 14.0, 110u, Easing.SinInOut);
				if (token.IsCancellationRequested)
				{
					break;
				}
				await ViewExtensions.RotateTo((VisualElement)(object)FlagIcon, 0.0, 110u, Easing.SinIn);
				if (token.IsCancellationRequested)
				{
					break;
				}
				await Task.Delay(2000, token);
			}
		}
		catch (TaskCanceledException)
		{
		}
		finally
		{
			((VisualElement)FlagIcon).Rotation = 0.0;
			((VisualElement)FlagIcon).AnchorX = 0.5;
			((VisualElement)FlagIcon).AnchorY = 0.5;
		}
	}

	private void StopWaveAnimation()
	{
		_waveCts?.Cancel();
		_waveCts = null;
	}

	[GeneratedCode("Microsoft.Maui.Controls.SourceGen", "1.0.0.0")]
	[MemberNotNull("Root")]
	[MemberNotNull("FlagIcon")]
	private void InitializeComponent()
	{
		Extensions.LoadFromXaml<IssueCardView>(this, typeof(IssueCardView));
		Root = NameScopeExtensions.FindByName<ContentView>((Element)(object)this, "Root");
		FlagIcon = NameScopeExtensions.FindByName<Label>((Element)(object)this, "FlagIcon");
	}
}
