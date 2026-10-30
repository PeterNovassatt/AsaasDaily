using System;
using System.Windows.Input;
using DailyDriver.Atlassian.Dtos.Project;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Configuration;

public class ConfigurationProjectViewModel : BaseViewModel
{
	private bool _isSelected;

	public string Key { get; set; }

	public string Name { get; set; }

	public string Category { get; set; }

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

	public ICommand ToggleCommand { get; }

	public ConfigurationProjectViewModel(AtlassianJiraProjectDTO project, Action onSelectionChanged)
	{
		//IL_0050: Unknown result type (might be due to invalid IL or missing references)
		//IL_005a: Expected Obj, but got Unknown
		ConfigurationProjectViewModel configurationProjectViewModel = this;
		Key = project.Key;
		Name = project.Name;
		Category = project.Category;
		ToggleCommand = (ICommand)new Command((Action)(() =>
		{
			configurationProjectViewModel.IsSelected = !configurationProjectViewModel.IsSelected;
			onSelectionChanged?.Invoke();
		}));
	}
}
