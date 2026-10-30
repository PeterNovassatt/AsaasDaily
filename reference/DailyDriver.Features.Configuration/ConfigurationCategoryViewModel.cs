using System;
using System.Windows.Input;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Configuration;

public class ConfigurationCategoryViewModel : BaseViewModel
{
	private bool _isSelected;

	public string Name { get; set; }

	public bool IsSelected
	{
		get
		{
			return _isSelected;
		}
		set
		{
			SetProperty(ref _isSelected, value, "IsSelected");
		}
	}

	public ICommand SelectCommand { get; }

	public ConfigurationCategoryViewModel(string name, Action<string> onSelected)
	{
		//IL_0036: Unknown result type (might be due to invalid IL or missing references)
		//IL_0040: Expected Obj, but got Unknown
		Name = name;
		SelectCommand = (ICommand)new Command((Action)(() =>
		{
			onSelected(name);
		}));
	}
}
