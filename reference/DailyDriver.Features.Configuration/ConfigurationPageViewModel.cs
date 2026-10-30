using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using DailyDriver.Atlassian.Dtos.Project;
using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Controls;

namespace DailyDriver.Features.Configuration;

public class ConfigurationPageViewModel : BaseViewModel
{
	private string _email;

	private string _apiToken;

	private bool _isLoadingProjects;

	private bool _isLoadingPersons;

	private List<ConfigurationProjectViewModel> _allProjects;

	private ObservableCollection<ConfigurationProjectViewModel> _projects;

	private bool _hasProjects;

	private string _searchText;

	private string _projectCount;

	private ObservableCollection<ConfigurationCategoryViewModel> _categories;

	private bool _hasCategories;

	private string _selectedCategory;

	private ObservableCollection<ConfigurationAtlassianPersonViewModel> _persons;

	private string _errorMessage;

	private bool _hasError;

	private readonly AtlassianConfigurationModel _atlassianConfigurationModel;

	private CancellationTokenSource _projectFetchToken;

	private CancellationTokenSource _personFetchToken;

	public string Email
	{
		get
		{
			return _email;
		}
		set
		{
			SetProperty(ref _email, value, "Email");
		}
	}

	public string ApiToken
	{
		get
		{
			return _apiToken;
		}
		set
		{
			SetProperty(ref _apiToken, value, "ApiToken");
		}
	}

	public bool IsLoadingProjects
	{
		get
		{
			return _isLoadingProjects;
		}
		set
		{
			SetProperty(ref _isLoadingProjects, value, "IsLoadingProjects");
		}
	}

	public bool IsLoadingPersons
	{
		get
		{
			return _isLoadingPersons;
		}
		set
		{
			SetProperty(ref _isLoadingPersons, value, "IsLoadingPersons");
		}
	}

	public ObservableCollection<ConfigurationProjectViewModel> Projects
	{
		get
		{
			return _projects;
		}
		set
		{
			SetProperty(ref _projects, value, "Projects");
		}
	}

	public bool HasProjects
	{
		get
		{
			return _hasProjects;
		}
		set
		{
			SetProperty(ref _hasProjects, value, "HasProjects");
		}
	}

	public string SearchText
	{
		get
		{
			return _searchText;
		}
		set
		{
			SetProperty(ref _searchText, value, "SearchText");
		}
	}

	public string ProjectCount
	{
		get
		{
			return _projectCount;
		}
		set
		{
			SetProperty(ref _projectCount, value, "ProjectCount");
		}
	}

	public ObservableCollection<ConfigurationCategoryViewModel> Categories
	{
		get
		{
			return _categories;
		}
		set
		{
			SetProperty(ref _categories, value, "Categories");
		}
	}

	public bool HasCategories
	{
		get
		{
			return _hasCategories;
		}
		set
		{
			SetProperty(ref _hasCategories, value, "HasCategories");
		}
	}

	public string SelectedCategory
	{
		get
		{
			return _selectedCategory;
		}
		set
		{
			SetProperty(ref _selectedCategory, value, "SelectedCategory");
		}
	}

	public ObservableCollection<ConfigurationAtlassianPersonViewModel> Persons
	{
		get
		{
			return _persons;
		}
		set
		{
			SetProperty(ref _persons, value, "Persons");
		}
	}

	public string ErrorMessage
	{
		get
		{
			return _errorMessage;
		}
		set
		{
			SetProperty(ref _errorMessage, value, "ErrorMessage");
		}
	}

	public bool HasError
	{
		get
		{
			return _hasError;
		}
		set
		{
			SetProperty(ref _hasError, value, "HasError");
		}
	}

	public ICommand SaveCommand { get; }

	public ConfigurationPageViewModel()
	{
		//IL_004b: Unknown result type (might be due to invalid IL or missing references)
		//IL_0055: Expected Obj, but got Unknown
		_atlassianConfigurationModel = AtlassianService.GetConfiguration() ?? new AtlassianConfigurationModel();
		_email = _atlassianConfigurationModel.Email;
		_apiToken = _atlassianConfigurationModel.ApiToken;
		SaveCommand = (ICommand)new Command((Action)(() =>
		{
			try
			{
				if (string.IsNullOrEmpty(Email))
				{
					throw new Exception("E-mail é obrigatório");
				}
				if (string.IsNullOrEmpty(ApiToken))
				{
					throw new Exception("API Token é obrigatório");
				}
				if (Projects == null || !Projects.Any((ConfigurationProjectViewModel p) => p.IsSelected))
				{
					throw new Exception("Selecione ao menos um projeto");
				}
				if (Persons == null || !Persons.Any((ConfigurationAtlassianPersonViewModel p) => p.Checked))
				{
					throw new Exception("Selecione ao menos uma pessoa");
				}
				_atlassianConfigurationModel.Id = Guid.NewGuid().ToString();
				_atlassianConfigurationModel.Email = Email;
				_atlassianConfigurationModel.ApiToken = ApiToken;
				_atlassianConfigurationModel.Project = BuildSelectedProjectsString();
				AtlassianService.SaveConfiguration(_atlassianConfigurationModel);
				AtlassianService.CachePersonList(Persons.Select((ConfigurationAtlassianPersonViewModel p) => p.Person).ToList());
				Application.Current.MainPage.DisplayAlert("Sucesso", "Configuração salva", "Ok");
			}
			catch (Exception ex)
			{
				Application.Current.MainPage.DisplayAlert("Erro", ex.Message, "Ok");
			}
		}));
		LoadFromCache();
		if (!string.IsNullOrEmpty(Email) && !string.IsNullOrEmpty(ApiToken))
		{
			if (_allProjects == null || _allProjects.Count <= 0)
			{
				MainThread.InvokeOnMainThreadAsync((Func<Task>)FetchProjects);
			}
			else
			{
				Task.Run((Func<Task?>)RefreshProjectsInBackground);
			}
		}
	}

	private void LoadFromCache()
	{
		List<AtlassianJiraProjectDTO> list = AtlassianService.ListCachedProjects();
		if (list == null || list.Count == 0)
		{
			return;
		}
		HashSet<string> previouslySelected = _atlassianConfigurationModel.Project?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToHashSet(StringComparer.OrdinalIgnoreCase) ?? new HashSet<string>();
		_allProjects = list.Select((AtlassianJiraProjectDTO p) =>
		{
			ConfigurationProjectViewModel configurationProjectViewModel = new ConfigurationProjectViewModel(p, OnProjectSelectionChanged);
			if (previouslySelected.Contains(p.Key))
			{
				configurationProjectViewModel.IsSelected = true;
			}
			return configurationProjectViewModel;
		}).ToList();
		BuildCategories();
		ApplyProjectFilter();
		if (!_allProjects.Any((ConfigurationProjectViewModel p) => p.IsSelected))
		{
			return;
		}
		List<AtlassianPersonDTO> list2 = AtlassianService.ListCachedPersons();
		if (list2 != null && list2.Count > 0)
		{
			Persons = new ObservableCollection<ConfigurationAtlassianPersonViewModel>(from p in list2
				where p.Active
				select new ConfigurationAtlassianPersonViewModel(p));
		}
	}

	private async Task RefreshProjectsInBackground()
	{
		try
		{
			_atlassianConfigurationModel.Email = Email;
			_atlassianConfigurationModel.ApiToken = ApiToken;
			List<AtlassianJiraProjectDTO> freshProjects = new List<AtlassianJiraProjectDTO>();
			await foreach (AtlassianJiraProjectDTO p in AtlassianService.ListAccessibleProjects(_atlassianConfigurationModel))
			{
				freshProjects.Add(p);
			}
			if (freshProjects.Count == 0)
			{
				return;
			}
			AtlassianService.CacheProjectList(freshProjects);
			HashSet<string> freshKeys = freshProjects.Select((AtlassianJiraProjectDTO atlassianJiraProjectDTO) => atlassianJiraProjectDTO.Key).ToHashSet(StringComparer.OrdinalIgnoreCase);
			if (_allProjects?.Select((ConfigurationProjectViewModel configurationProjectViewModel) => configurationProjectViewModel.Key).ToHashSet(StringComparer.OrdinalIgnoreCase) == null)
			{
				new HashSet<string>();
			}
			if (_allProjects != null)
			{
				_allProjects = _allProjects.Where((ConfigurationProjectViewModel configurationProjectViewModel) => freshKeys.Contains(configurationProjectViewModel.Key)).ToList();
			}
			else
			{
				_allProjects = new List<ConfigurationProjectViewModel>();
			}
			foreach (AtlassianJiraProjectDTO p2 in freshProjects)
			{
				ConfigurationProjectViewModel existing = _allProjects.FirstOrDefault((ConfigurationProjectViewModel x) => string.Equals(x.Key, p2.Key, StringComparison.OrdinalIgnoreCase));
				if (existing == null)
				{
					_allProjects.Add(new ConfigurationProjectViewModel(p2, OnProjectSelectionChanged));
					continue;
				}
				existing.Name = p2.Name;
				existing.Category = p2.Category;
			}
			await MainThread.InvokeOnMainThreadAsync((Action)(() =>
			{
				BuildCategories();
				ApplyProjectFilter();
			}));
		}
		catch
		{
		}
	}

	protected override void OnPropertyChanged(string propertyName = null)
	{
		base.OnPropertyChanged(propertyName);
		if ((propertyName == "Email" || propertyName == "ApiToken") ? true : false)
		{
			QueueFetchProjects();
		}
		if (propertyName == "Projects")
		{
			ObservableCollection<ConfigurationProjectViewModel> projects = Projects;
			HasProjects = projects != null && projects.Count > 0;
		}
		if ((propertyName == "SearchText" || propertyName == "SelectedCategory") ? true : false)
		{
			ApplyProjectFilter();
		}
	}

	private void QueueFetchProjects()
	{
		if (string.IsNullOrEmpty(Email) || string.IsNullOrEmpty(ApiToken))
		{
			return;
		}
		Task.Run(async () =>
		{
			_projectFetchToken?.Cancel();
			_projectFetchToken = new CancellationTokenSource();
			await Task.Delay(600);
			if (!_projectFetchToken.IsCancellationRequested)
			{
				await MainThread.InvokeOnMainThreadAsync((Func<Task>)FetchProjects);
			}
		});
	}

	private async Task FetchProjects()
	{
		if (IsLoadingProjects)
		{
			return;
		}
		IsLoadingProjects = true;
		HasError = false;
		ErrorMessage = null;
		Projects = null;
		Persons = null;
		try
		{
			_atlassianConfigurationModel.Email = Email;
			_atlassianConfigurationModel.ApiToken = ApiToken;
			HashSet<string> previouslySelected = _atlassianConfigurationModel.Project?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToHashSet(StringComparer.OrdinalIgnoreCase) ?? new HashSet<string>();
			_allProjects = new List<ConfigurationProjectViewModel>();
			await foreach (AtlassianJiraProjectDTO project in AtlassianService.ListAccessibleProjects(_atlassianConfigurationModel))
			{
				ConfigurationProjectViewModel vm = new ConfigurationProjectViewModel(project, OnProjectSelectionChanged);
				if (previouslySelected.Contains(project.Key))
				{
					vm.IsSelected = true;
				}
				_allProjects.Add(vm);
			}
			List<AtlassianJiraProjectDTO> dtoList = _allProjects.Select((ConfigurationProjectViewModel configurationProjectViewModel) => new AtlassianJiraProjectDTO
			{
				Key = configurationProjectViewModel.Key,
				Name = configurationProjectViewModel.Name,
				Category = configurationProjectViewModel.Category
			}).ToList();
			if (dtoList.Count > 0)
			{
				AtlassianService.CacheProjectList(dtoList);
			}
			if (_allProjects.Count == 0)
			{
				ErrorMessage = "Não foi possível carregar os projetos. Verifique o e-mail e o API Token.";
				HasError = true;
				return;
			}
			BuildCategories();
			ApplyProjectFilter();
			if (_allProjects.Any((ConfigurationProjectViewModel p) => p.IsSelected))
			{
				_atlassianConfigurationModel.Project = BuildSelectedProjectsString();
				await FetchPersons();
			}
		}
		catch (Exception ex)
		{
			Exception ex2 = ex;
			ErrorMessage = "Erro ao carregar projetos: " + ex2.Message;
			HasError = true;
		}
		finally
		{
			IsLoadingProjects = false;
		}
	}

	private void OnProjectSelectionChanged()
	{
		_atlassianConfigurationModel.Project = BuildSelectedProjectsString();
		QueueFetchPersons();
	}

	private void QueueFetchPersons()
	{
		if (string.IsNullOrEmpty(_atlassianConfigurationModel.Project))
		{
			Persons = null;
			return;
		}
		Task.Run(async () =>
		{
			_personFetchToken?.Cancel();
			_personFetchToken = new CancellationTokenSource();
			await Task.Delay(300);
			if (!_personFetchToken.IsCancellationRequested)
			{
				await MainThread.InvokeOnMainThreadAsync((Func<Task>)FetchPersons);
			}
		});
	}

	private async Task FetchPersons()
	{
		if (IsLoadingPersons)
		{
			return;
		}
		IsLoadingPersons = true;
		HasError = false;
		ErrorMessage = null;
		Persons = null;
		try
		{
			List<AtlassianPersonDTO> persons = await AtlassianService.ListActiveAssignees(_atlassianConfigurationModel);
			if (persons == null)
			{
				ErrorMessage = "Não foi possível carregar os membros. Verifique os projetos selecionados.";
				HasError = true;
				return;
			}
			if (persons.Count == 0)
			{
				ErrorMessage = "Nenhum assignee encontrado no sprint ativo destes projetos.";
				HasError = true;
				return;
			}
			AtlassianService.SaveConfiguration(_atlassianConfigurationModel);
			List<AtlassianPersonDTO> cachedPersons = AtlassianService.ListCachedPersons();
			Persons = new ObservableCollection<ConfigurationAtlassianPersonViewModel>(persons.Where((AtlassianPersonDTO p) => p.Active).Select((AtlassianPersonDTO person) =>
			{
				AtlassianPersonDTO atlassianPersonDTO = cachedPersons?.FirstOrDefault((AtlassianPersonDTO p) => p.Id == person.Id);
				if (atlassianPersonDTO != null)
				{
					person.Nickname = atlassianPersonDTO.Nickname;
					person.IsChecked = atlassianPersonDTO.IsChecked;
				}
				return new ConfigurationAtlassianPersonViewModel(person);
			}));
		}
		catch (TaskCanceledException)
		{
			ErrorMessage = "Tempo limite excedido. Tente novamente.";
			HasError = true;
		}
		catch (Exception ex2)
		{
			Exception ex3 = ex2;
			ErrorMessage = "Erro ao carregar membros: " + ex3.Message;
			HasError = true;
		}
		finally
		{
			IsLoadingPersons = false;
		}
	}

	private void BuildCategories()
	{
		List<string> list = (from c in (from p in _allProjects
				where !string.IsNullOrEmpty(p.Category)
				select p.Category).Distinct(StringComparer.OrdinalIgnoreCase)
			orderby c
			select c).ToList();
		HasCategories = list.Count > 0;
		if (HasCategories)
		{
			ConfigurationCategoryViewModel configurationCategoryViewModel = new ConfigurationCategoryViewModel("Todos", OnCategorySelected)
			{
				IsSelected = true
			};
			IEnumerable<ConfigurationCategoryViewModel> second = list.Select((string c) => new ConfigurationCategoryViewModel(c, OnCategorySelected));
			Categories = new ObservableCollection<ConfigurationCategoryViewModel>(new ConfigurationCategoryViewModel[1] { configurationCategoryViewModel }.Concat(second));
		}
	}

	private void OnCategorySelected(string name)
	{
		if (Categories == null)
		{
			return;
		}
		foreach (ConfigurationCategoryViewModel category in Categories)
		{
			category.IsSelected = category.Name == name;
		}
		SelectedCategory = ((name == "Todos") ? null : name);
	}

	private void ApplyProjectFilter()
	{
		if (_allProjects == null)
		{
			return;
		}
		IEnumerable<ConfigurationProjectViewModel> source = _allProjects;
		if (!string.IsNullOrEmpty(SelectedCategory))
		{
			source = source.Where((ConfigurationProjectViewModel p) => string.Equals(p.Category, SelectedCategory, StringComparison.OrdinalIgnoreCase));
		}
		if (!string.IsNullOrWhiteSpace(SearchText))
		{
			source = source.Where((ConfigurationProjectViewModel p) => p.Key.Contains(SearchText, StringComparison.OrdinalIgnoreCase) || p.Name.Contains(SearchText, StringComparison.OrdinalIgnoreCase));
		}
		List<ConfigurationProjectViewModel> list = source.ToList();
		Projects = new ObservableCollection<ConfigurationProjectViewModel>(list);
		ProjectCount = $"{list.Count} de {_allProjects.Count} projetos";
	}

	private string BuildSelectedProjectsString()
	{
		return string.Join(", ", _allProjects?.Where((ConfigurationProjectViewModel p) => p.IsSelected).Select((ConfigurationProjectViewModel p) => p.Key) ?? Array.Empty<string>());
	}
}
