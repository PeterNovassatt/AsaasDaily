using System;
using System.Windows.Input;
using Microsoft.Maui;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Configuration;

public class ConfigurationAtlassianPersonViewModel : BaseViewModel
{
	private bool _checked;

	private string _nickname;

	private bool _isEditing;

	public AtlassianPersonDTO Person { get; set; }

	public string Name { get; set; }

	public string AvatarUrl { get; set; }

	public bool Checked
	{
		get
		{
			return _checked;
		}
		set
		{
			SetProperty(ref _checked, value, "Checked");
		}
	}

	public string Nickname
	{
		get
		{
			return _nickname;
		}
		set
		{
			SetProperty(ref _nickname, value, "Nickname");
		}
	}

	public ICommand TapCommand { get; set; }

	public ICommand EditCommand { get; set; }

	public ConfigurationAtlassianPersonViewModel(AtlassianPersonDTO person)
	{
		//IL_007e: Unknown result type (might be due to invalid IL or missing references)
		//IL_0088: Expected Obj, but got Unknown
		//IL_0096: Unknown result type (might be due to invalid IL or missing references)
		//IL_00a0: Expected Obj, but got Unknown
		ConfigurationAtlassianPersonViewModel configurationAtlassianPersonViewModel = this;
		Person = person;
		Name = person.Name;
		AvatarUrl = person.AvatarUrl;
		Nickname = person.Nickname;
		Checked = person.IsChecked;
		TapCommand = (ICommand)new Command((Action)(() =>
		{
			configurationAtlassianPersonViewModel.Checked = !configurationAtlassianPersonViewModel.Checked;
			configurationAtlassianPersonViewModel.Person.IsChecked = configurationAtlassianPersonViewModel.Checked;
		}));
		EditCommand = (ICommand)new Command((Action)(async () =>
		{
			if (!configurationAtlassianPersonViewModel._isEditing)
			{
				configurationAtlassianPersonViewModel._isEditing = true;
				string nickname = await Application.Current.MainPage.DisplayPromptAsync("Apelido", "Digite o apelido", "OK", "Cancel", (string)null, -1, (Keyboard)null, "");
				ConfigurationAtlassianPersonViewModel configurationAtlassianPersonViewModel2 = configurationAtlassianPersonViewModel;
				string nickname2 = (person.Nickname = (string.IsNullOrWhiteSpace(nickname) ? null : nickname));
				configurationAtlassianPersonViewModel2.Nickname = nickname2;
				configurationAtlassianPersonViewModel._isEditing = false;
			}
		}));
	}
}
