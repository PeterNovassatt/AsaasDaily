using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Input;
using DailyDriver.Atlassian.Dtos.Issue;
using DailyDriver.Features.Charts;
using DailyDriver.Features.Configuration;
using DailyDriver.Features.Kanban;
using Microsoft.Maui.ApplicationModel;
using Microsoft.Maui.Controls;
using Microsoft.Maui.Graphics;
using Microsoft.Maui.Media;

namespace DailyDriver;

public class MainPageViewModel : BaseViewModel
{
	private ObservableCollection<PersonViewModel> _persons;

	private PersonViewModel _personTalking;

	private bool _hasPersonTalking;

	private bool _canDisplayOptions;

	private bool _isLoading;

	private bool _isNotConfigured;

	private bool _isSpeechEnabled;

	private ObservableCollection<AtlassianIssueDTO> _unassignedIssues;

	private bool _hasUnassignedIssues;

	private string _progressText;

	private double _progressFraction;

	private int _codeReviewCount;

	private int _inProgressCount;

	private int _unassignedCount;

	private int _todoCount;

	private int _flaggedCount;

	private string _flaggedSubtitle;

	private int _spokenCount;

	private string _personTotalLabel;

	private string _projectLabel;

	private IDrawable _statusDonut;

	private IDrawable _workloadBars;

	private ObservableCollection<KanbanColumnViewModel> _speakerColumns;

	private string _speakerCardsHeader;

	private bool _hasSpeakerCards;

	private bool _isRefreshingSpeaker;

	private int _boardIssueCount;

	private bool _isFinished;

	private bool _showContent;

	private PersonViewModel _nextPerson;

	private bool _hasNextPerson;

	private ObservableCollection<PersonViewModel> _remainingPersons;

	private bool _hasRemainingPersons;

	private string _nextButtonText = "Iniciar";

	private int _fontScaleLevel = 0;

	private const int MinFontScale = -3;

	private const int MaxFontScale = 3;

	private static readonly Dictionary<string, double> _baseFontSizes = new Dictionary<string, double>
	{
		["FsXs"] = 12.0,
		["FsSm"] = 13.0,
		["FsMd"] = 14.0,
		["FsTag"] = 15.0,
		["FsBase"] = 16.0,
		["FsBody"] = 17.0,
		["FsLg"] = 19.0,
		["FsXl"] = 21.0,
		["Fs2xl"] = 24.0,
		["FsIcon"] = 24.0,
		["Fs3xl"] = 28.0,
		["FsDisplay"] = 34.0,
		["Fs4xl"] = 40.0,
		["FsStat"] = 52.0,
		["Fs5xl"] = 46.0,
		["Fs6xl"] = 64.0,
		["FsJumbo"] = 68.0,
		["FsGiant"] = 84.0
	};

	private AtlassianConfigurationModel _atlassianConfigurationModel;

	private bool _isChangingSpeaker;

	private readonly List<PersonViewModel> _spokenHistory = new List<PersonViewModel>();

	private bool _canGoBack;

	private Locale _speechLocale;

	private bool _speechLocaleResolved;

	public ObservableCollection<PersonViewModel> Persons
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

	public PersonViewModel PersonTalking
	{
		get
		{
			return _personTalking;
		}
		set
		{
			SetProperty(ref _personTalking, value, "PersonTalking");
		}
	}

	public bool HasPersonTalking
	{
		get
		{
			return _hasPersonTalking;
		}
		set
		{
			SetProperty(ref _hasPersonTalking, value, "HasPersonTalking");
		}
	}

	public bool CanDisplayOptions
	{
		get
		{
			return _canDisplayOptions;
		}
		set
		{
			SetProperty(ref _canDisplayOptions, value, "CanDisplayOptions");
		}
	}

	public bool IsLoading
	{
		get
		{
			return _isLoading;
		}
		set
		{
			SetProperty(ref _isLoading, value, "IsLoading");
		}
	}

	public bool IsNotConfigured
	{
		get
		{
			return _isNotConfigured;
		}
		set
		{
			SetProperty(ref _isNotConfigured, value, "IsNotConfigured");
		}
	}

	public bool IsSpeechEnabled
	{
		get
		{
			return _isSpeechEnabled;
		}
		set
		{
			SetProperty(ref _isSpeechEnabled, value, "IsSpeechEnabled");
		}
	}

	public ObservableCollection<AtlassianIssueDTO> UnassignedIssues
	{
		get
		{
			return _unassignedIssues;
		}
		set
		{
			SetProperty(ref _unassignedIssues, value, "UnassignedIssues");
		}
	}

	public bool HasUnassignedIssues
	{
		get
		{
			return _hasUnassignedIssues;
		}
		set
		{
			SetProperty(ref _hasUnassignedIssues, value, "HasUnassignedIssues");
		}
	}

	public string ProgressText
	{
		get
		{
			return _progressText;
		}
		set
		{
			SetProperty(ref _progressText, value, "ProgressText");
		}
	}

	public double ProgressFraction
	{
		get
		{
			return _progressFraction;
		}
		set
		{
			SetProperty(ref _progressFraction, value, "ProgressFraction");
		}
	}

	public int CodeReviewCount
	{
		get
		{
			return _codeReviewCount;
		}
		set
		{
			SetProperty(ref _codeReviewCount, value, "CodeReviewCount");
		}
	}

	public int InProgressCount
	{
		get
		{
			return _inProgressCount;
		}
		set
		{
			SetProperty(ref _inProgressCount, value, "InProgressCount");
		}
	}

	public int UnassignedCount
	{
		get
		{
			return _unassignedCount;
		}
		set
		{
			SetProperty(ref _unassignedCount, value, "UnassignedCount");
		}
	}

	public int TodoCount
	{
		get
		{
			return _todoCount;
		}
		set
		{
			SetProperty(ref _todoCount, value, "TodoCount");
		}
	}

	public int FlaggedCount
	{
		get
		{
			return _flaggedCount;
		}
		set
		{
			SetProperty(ref _flaggedCount, value, "FlaggedCount");
		}
	}

	public string FlaggedSubtitle
	{
		get
		{
			return _flaggedSubtitle;
		}
		set
		{
			SetProperty(ref _flaggedSubtitle, value, "FlaggedSubtitle");
		}
	}

	public int SpokenCount
	{
		get
		{
			return _spokenCount;
		}
		set
		{
			SetProperty(ref _spokenCount, value, "SpokenCount");
		}
	}

	public string PersonTotalLabel
	{
		get
		{
			return _personTotalLabel;
		}
		set
		{
			SetProperty(ref _personTotalLabel, value, "PersonTotalLabel");
		}
	}

	public string ProjectLabel
	{
		get
		{
			return _projectLabel;
		}
		set
		{
			SetProperty(ref _projectLabel, value, "ProjectLabel");
		}
	}

	public IDrawable StatusDonut
	{
		get
		{
			return _statusDonut;
		}
		set
		{
			SetProperty(ref _statusDonut, value, "StatusDonut");
		}
	}

	public IDrawable WorkloadBars
	{
		get
		{
			return _workloadBars;
		}
		set
		{
			SetProperty(ref _workloadBars, value, "WorkloadBars");
		}
	}

	public ObservableCollection<KanbanColumnViewModel> SpeakerColumns
	{
		get
		{
			return _speakerColumns;
		}
		set
		{
			SetProperty(ref _speakerColumns, value, "SpeakerColumns");
		}
	}

	public string SpeakerCardsHeader
	{
		get
		{
			return _speakerCardsHeader;
		}
		set
		{
			SetProperty(ref _speakerCardsHeader, value, "SpeakerCardsHeader");
		}
	}

	public bool HasSpeakerCards
	{
		get
		{
			return _hasSpeakerCards;
		}
		set
		{
			SetProperty(ref _hasSpeakerCards, value, "HasSpeakerCards");
		}
	}

	public bool IsRefreshingSpeaker
	{
		get
		{
			return _isRefreshingSpeaker;
		}
		set
		{
			SetProperty(ref _isRefreshingSpeaker, value, "IsRefreshingSpeaker");
		}
	}

	public bool IsFinished
	{
		get
		{
			return _isFinished;
		}
		set
		{
			SetProperty(ref _isFinished, value, "IsFinished");
		}
	}

	public bool ShowContent
	{
		get
		{
			return _showContent;
		}
		set
		{
			SetProperty(ref _showContent, value, "ShowContent");
		}
	}

	public PersonViewModel NextPerson
	{
		get
		{
			return _nextPerson;
		}
		set
		{
			SetProperty(ref _nextPerson, value, "NextPerson");
		}
	}

	public bool HasNextPerson
	{
		get
		{
			return _hasNextPerson;
		}
		set
		{
			SetProperty(ref _hasNextPerson, value, "HasNextPerson");
		}
	}

	public ObservableCollection<PersonViewModel> RemainingPersons
	{
		get
		{
			return _remainingPersons;
		}
		set
		{
			SetProperty(ref _remainingPersons, value, "RemainingPersons");
		}
	}

	public bool HasRemainingPersons
	{
		get
		{
			return _hasRemainingPersons;
		}
		set
		{
			SetProperty(ref _hasRemainingPersons, value, "HasRemainingPersons");
		}
	}

	public string NextButtonText
	{
		get
		{
			return _nextButtonText;
		}
		set
		{
			SetProperty(ref _nextButtonText, value, "NextButtonText");
		}
	}

	public ICommand NextCommand { get; }

	public ICommand SkipCommand { get; }

	public ICommand PreviousCommand { get; }

	public ICommand ResetCommand { get; }

	public ICommand RemoveCommand { get; }

	public ICommand OpenCardCommand { get; }

	public ICommand RefreshSpeakerCommand { get; }

	public ICommand ToggleSpeechCommand { get; }

	public ICommand IncreaseFontScaleCommand { get; }

	public ICommand DecreaseFontScaleCommand { get; }

	public ICommand ResetFontScaleCommand { get; }

	public bool IsFontScaleDefault => _fontScaleLevel == 0;

	public bool CanDecreaseFontScale => _fontScaleLevel > -3;

	public bool CanIncreaseFontScale => _fontScaleLevel < 3;

	public Func<Task> SpeakerExitAnimation { get; set; }

	public Func<Task> SpeakerEnterAnimation { get; set; }

	public bool CanGoBack
	{
		get
		{
			return _canGoBack;
		}
		set
		{
			SetProperty(ref _canGoBack, value, "CanGoBack");
		}
	}

	public MainPageViewModel()
	{
		//IL_003e: Unknown result type (might be due to invalid IL or missing references)
		//IL_0048: Expected Obj, but got Unknown
		//IL_0055: Unknown result type (might be due to invalid IL or missing references)
		//IL_005f: Expected Obj, but got Unknown
		//IL_006c: Unknown result type (might be due to invalid IL or missing references)
		//IL_0076: Expected Obj, but got Unknown
		//IL_0083: Unknown result type (might be due to invalid IL or missing references)
		//IL_008d: Expected Obj, but got Unknown
		//IL_009a: Unknown result type (might be due to invalid IL or missing references)
		//IL_00a4: Expected Obj, but got Unknown
		//IL_00b1: Unknown result type (might be due to invalid IL or missing references)
		//IL_00bb: Expected Obj, but got Unknown
		//IL_00c8: Unknown result type (might be due to invalid IL or missing references)
		//IL_00d2: Expected Obj, but got Unknown
		//IL_00df: Unknown result type (might be due to invalid IL or missing references)
		//IL_00e9: Expected Obj, but got Unknown
		//IL_0137: Unknown result type (might be due to invalid IL or missing references)
		//IL_0141: Expected Obj, but got Unknown
		IsSpeechEnabled = AtlassianService.IsSpeechEnabled();
		ToggleSpeechCommand = (ICommand)new Command((Action)(() =>
		{
			IsSpeechEnabled = !IsSpeechEnabled;
		}));
		IncreaseFontScaleCommand = (ICommand)new Command((Action)(() =>
		{
			if (_fontScaleLevel < 3)
			{
				_fontScaleLevel++;
				ApplyFontScale();
			}
		}));
		DecreaseFontScaleCommand = (ICommand)new Command((Action)(() =>
		{
			if (_fontScaleLevel > -3)
			{
				_fontScaleLevel--;
				ApplyFontScale();
			}
		}));
		ResetFontScaleCommand = (ICommand)new Command((Action)(() =>
		{
			if (_fontScaleLevel != 0)
			{
				_fontScaleLevel = 0;
				ApplyFontScale();
			}
		}));
		ResetCommand = (ICommand)new Command((Action)(async () =>
		{
			await ResetPersons();
		}));
		NextCommand = (ICommand)new Command((Action)(async () =>
		{
			await ChangeSpeaker(markAsTalked: true);
		}));
		SkipCommand = (ICommand)new Command((Action)(async () =>
		{
			await ChangeSpeaker(markAsTalked: false);
		}));
		PreviousCommand = (ICommand)new Command((Action)(async () =>
		{
			await GoBackToPreviousSpeaker();
		}));
		RemoveCommand = (ICommand)new Command<PersonViewModel>((Action<PersonViewModel>)((PersonViewModel model) =>
		{
			if (model != null && Persons != null && Persons.Remove(model))
			{
				_spokenHistory.RemoveAll((PersonViewModel person) => person == model);
				CanGoBack = _spokenHistory.Count > 0;
				UpdateProgress();
				UpdateQueueViews();
				BuildWorkloadChart();
			}
		}));
		OpenCardCommand = (ICommand)new Command<AtlassianIssueDTO>((Action<AtlassianIssueDTO>)(async (AtlassianIssueDTO issue) =>
		{
			if (!string.IsNullOrEmpty(issue?.Key))
			{
				await Launcher.OpenAsync("https://asaasdev.atlassian.net/browse/" + issue.Key);
			}
		}));
		RefreshSpeakerCommand = (ICommand)new Command((Action)(async () =>
		{
			await RefreshSpeaker();
		}));
		UpdatePersons();
	}

	private async Task GoBackToPreviousSpeaker()
	{
		if (_isChangingSpeaker || _spokenHistory.Count == 0)
		{
			return;
		}
		_isChangingSpeaker = true;
		try
		{
			if (SpeakerExitAnimation != null)
			{
				await SpeakerExitAnimation();
			}
			List<PersonViewModel> spokenHistory = _spokenHistory;
			PersonViewModel previous = spokenHistory[spokenHistory.Count - 1];
			_spokenHistory.RemoveAt(_spokenHistory.Count - 1);
			previous.Talked = false;
			PersonTalking = previous;
			CanGoBack = _spokenHistory.Count > 0;
			await Task.Delay(16);
			if (SpeakerEnterAnimation != null)
			{
				await SpeakerEnterAnimation();
			}
			Announce();
		}
		finally
		{
			_isChangingSpeaker = false;
		}
	}

	private async Task ChangeSpeaker(bool markAsTalked)
	{
		if (_isChangingSpeaker || Persons == null)
		{
			return;
		}
		_isChangingSpeaker = true;
		try
		{
			if (markAsTalked || Persons.Any((PersonViewModel p) => !p.Talked && p != PersonTalking))
			{
				if (SpeakerExitAnimation != null)
				{
					await SpeakerExitAnimation();
				}
				PersonViewModel current = PersonTalking;
				if (markAsTalked && current != null)
				{
					current.Talked = true;
					_spokenHistory.Add(current);
					CanGoBack = true;
				}
				if (!markAsTalked && current != null)
				{
					Persons.Remove(current);
					Persons.Add(current);
				}
				PersonTalking = (markAsTalked ? Persons.FirstOrDefault((PersonViewModel p) => !p.Talked) : Persons.FirstOrDefault((PersonViewModel p) => !p.Talked && p != current));
				await Task.Delay(16);
				if (SpeakerEnterAnimation != null)
				{
					await SpeakerEnterAnimation();
				}
				Announce();
			}
		}
		finally
		{
			_isChangingSpeaker = false;
		}
	}

	private async Task Announce()
	{
		if (PersonTalking == null || !IsSpeechEnabled)
		{
			return;
		}
		if (!_speechLocaleResolved)
		{
			_speechLocale = (await TextToSpeech.Default.GetLocalesAsync()).FirstOrDefault((Locale locale) => locale.Language == "pt-BR");
			_speechLocaleResolved = true;
		}
		SpeechOptions options = new SpeechOptions
		{
			Pitch = 1.5f,
			Volume = 0.75f,
			Locale = _speechLocale
		};
		await TextToSpeech.SpeakAsync(PersonTalking.Name, options, default(CancellationToken));
	}

	private void UpdatePersons()
	{
		_atlassianConfigurationModel = AtlassianService.GetConfiguration();
		if (!AtlassianService.IsConfigured())
		{
			IsNotConfigured = true;
			return;
		}
		IsNotConfigured = false;
		MainThread.BeginInvokeOnMainThread((Action)(async () =>
		{
			await ResetPersons();
		}));
	}

	protected override void OnPropertyChanged(string propertyName = null)
	{
		base.OnPropertyChanged(propertyName);
		if (propertyName == "PersonTalking")
		{
			HasPersonTalking = PersonTalking != null;
			UpdateProgress();
			UpdateQueueViews();
			UpdateSpeakerCards();
			BuildWorkloadChart();
		}
		if (propertyName == "Persons")
		{
			UpdateProgress();
			UpdateQueueViews();
			BuildWorkloadChart();
		}
		if (propertyName == "IsSpeechEnabled")
		{
			AtlassianService.SaveSpeech(IsSpeechEnabled);
		}
		if (propertyName == "UnassignedIssues")
		{
			ObservableCollection<AtlassianIssueDTO> unassignedIssues = UnassignedIssues;
			HasUnassignedIssues = unassignedIssues != null && unassignedIssues.Count > 0;
		}
		if ((propertyName == "CanDisplayOptions" || propertyName == "IsFinished") ? true : false)
		{
			ShowContent = CanDisplayOptions && !IsFinished;
		}
	}

	private async Task ResetPersons()
	{
		if (IsLoading)
		{
			return;
		}
		List<AtlassianPersonDTO> cachedPersons = AtlassianService.ListCachedPersons();
		if (cachedPersons == null)
		{
			return;
		}
		IsLoading = true;
		CanDisplayOptions = false;
		PersonTalking = null;
		Persons = null;
		UnassignedIssues = null;
		_spokenHistory.Clear();
		CanGoBack = false;
		SpeakingOrderResult result = await AtlassianService.BuildSpeakingOrder(_atlassianConfigurationModel, cachedPersons);
		if ((object)result == null)
		{
			IsLoading = false;
			return;
		}
		List<PersonViewModel> personViewModels = result.Speakers.Select((SpeakingPersonEntry entry) => new PersonViewModel
		{
			Name = (entry.Person.Nickname ?? entry.Person.Name),
			AssigneeId = entry.Person.Id,
			Source = ImageSource.op_Implicit(entry.Person.AvatarUrl),
			Talked = false,
			Cards = entry.Issues
		}).ToList();
		Persons = new ObservableCollection<PersonViewModel>(personViewModels);
		if (result.UnassignedIssues.Count > 0)
		{
			UnassignedIssues = new ObservableCollection<AtlassianIssueDTO>(result.UnassignedIssues);
		}
		List<AtlassianIssueDTO> allIssues = result.Speakers.SelectMany((SpeakingPersonEntry s) => s.Issues).Concat(result.UnassignedIssues).ToList();
		List<AtlassianIssueDTO> boardIssues = allIssues.Where((AtlassianIssueDTO i) => !i.IsEpic).ToList();
		CodeReviewCount = Enumerable.Count(boardIssues, (AtlassianIssueDTO i) => string.Equals(i.Status, "CODE REVIEW", StringComparison.OrdinalIgnoreCase));
		InProgressCount = Enumerable.Count(boardIssues, (AtlassianIssueDTO i) => string.Equals(i.Status, "IN PROGRESS", StringComparison.OrdinalIgnoreCase));
		TodoCount = boardIssues.Count - CodeReviewCount - InProgressCount;
		FlaggedCount = Enumerable.Count(boardIssues, (AtlassianIssueDTO i) => i.IsFlagged);
		_boardIssueCount = boardIssues.Count;
		FlaggedSubtitle = $"de {_boardIssueCount}";
		UnassignedCount = result.UnassignedIssues.Count;
		ProjectLabel = _atlassianConfigurationModel?.Project ?? string.Empty;
		BuildStatusChart();
		BuildWorkloadChart();
		CanDisplayOptions = true;
		IsLoading = false;
	}

	private async Task RefreshSpeaker()
	{
		PersonViewModel speaker = PersonTalking;
		if (speaker == null || IsRefreshingSpeaker)
		{
			return;
		}
		if (!string.IsNullOrEmpty(speaker.AssigneeId))
		{
			IsRefreshingSpeaker = true;
			try
			{
				try
				{
					List<AtlassianIssueDTO> fresh = await AtlassianService.ListIssuesForAssignee(_atlassianConfigurationModel, speaker.AssigneeId);
					if (fresh == null)
					{
						await Application.Current.MainPage.DisplayAlert("Atualizar", "Não foi possível recarregar os cards de " + speaker.Name + ".", "Ok");
						return;
					}
					HashSet<string> triggerKeys = (from card in speaker.Cards
						where card.IsTriggerCard
						select card.Key).ToHashSet();
					foreach (AtlassianIssueDTO issue in fresh)
					{
						issue.IsTriggerCard = triggerKeys.Contains(issue.Key);
					}
					int previousCodeReview = speaker.CodeReviewCount;
					int previousInProgress = speaker.InProgressCount;
					int previousFlagged = speaker.FlaggedCount;
					int previousTodo = speaker.TodoCards.Count;
					int previousBoardItems = previousCodeReview + previousInProgress + previousTodo;
					speaker.Cards = fresh;
					int currentTodo = speaker.TodoCards.Count;
					CodeReviewCount += speaker.CodeReviewCount - previousCodeReview;
					InProgressCount += speaker.InProgressCount - previousInProgress;
					FlaggedCount += speaker.FlaggedCount - previousFlagged;
					TodoCount += currentTodo - previousTodo;
					_boardIssueCount += speaker.CodeReviewCount + speaker.InProgressCount + currentTodo - previousBoardItems;
					FlaggedSubtitle = $"de {_boardIssueCount}";
					UpdateSpeakerCards();
					UpdateQueueViews();
					BuildStatusChart();
					BuildWorkloadChart();
				}
				catch (Exception ex)
				{
					await Application.Current.MainPage.DisplayAlert("Atualizar", "Erro ao recarregar: " + ex.Message, "Ok");
				}
				return;
			}
			finally
			{
				IsRefreshingSpeaker = false;
			}
		}
		await Application.Current.MainPage.DisplayAlert("Atualizar", "Esta pessoa não tem accountId do Jira.", "Ok");
	}

	private void UpdateSpeakerCards()
	{
		List<KanbanColumnViewModel> list = PersonTalking?.Columns ?? new List<KanbanColumnViewModel>();
		SpeakerColumns = new ObservableCollection<KanbanColumnViewModel>(list);
		HasSpeakerCards = list.Count > 0;
		SpeakerCardsHeader = ((PersonTalking == null) ? string.Empty : ("Quadro de " + PersonTalking.Name));
	}

	private void BuildStatusChart()
	{
		DonutChartDrawable donutChartDrawable = new DonutChartDrawable();
		int num = 3;
		List<(int, Color)> list = new List<(int, Color)>(num);
		CollectionsMarshal.SetCount(list, num);
		Span<(int, Color)> span = CollectionsMarshal.AsSpan(list);
		span[0] = (CodeReviewCount, Palette("ColorCodeReview", Colors.Gold));
		span[1] = (InProgressCount, Palette("ColorInProgress", Colors.MediumSeaGreen));
		span[2] = (TodoCount, Palette("StrokeStrong", Colors.DimGray));
		donutChartDrawable.Slices = list;
		donutChartDrawable.TrackColor = Palette("StrokeStrong", Colors.DimGray);
		donutChartDrawable.CenterTextColor = Palette("TextPrimary", Colors.White);
		donutChartDrawable.CenterFontSize = FontSize("Fs2xl", 24.0);
		StatusDonut = (IDrawable)(object)donutChartDrawable;
	}

	private void BuildWorkloadChart()
	{
		List<PersonViewModel> list = Persons?.ToList() ?? new List<PersonViewModel>();
		WorkloadBars = (IDrawable)(object)new BarChartDrawable
		{
			Values = list.Select((PersonViewModel p) => p.Cards.Count).ToList(),
			BarColor = Palette("StrokeStrong", Colors.DimGray),
			HighlightColor = Palette("BrandLight", Colors.MediumPurple),
			HighlightIndex = ((PersonTalking == null) ? (-1) : list.IndexOf(PersonTalking))
		};
	}

	private static Color Palette(string key, Color fallback)
	{
		Application current = Application.Current;
		object obj = default;
		Color result;
		if (current != null && current.Resources.TryGetValue(key, ref obj))
		{
			Color val = (Color)((obj is Color) ? obj : null);
			if (val != null)
			{
				result = val;
				goto IL_0029;
			}
		}
		result = fallback;
		goto IL_0029;
		IL_0029:
		return result;
	}

	private static double FontSize(string key, double fallback)
	{
		Application current = Application.Current;
		object obj = default;
		return (current != null && current.Resources.TryGetValue(key, ref obj) && obj is double num) ? num : fallback;
	}

	private void UpdateProgress()
	{
		int num = Persons?.Count ?? 0;
		ObservableCollection<PersonViewModel> persons = Persons;
		int num2 = ((persons != null) ? Enumerable.Count(persons, (PersonViewModel p) => p.Talked) : 0);
		ProgressText = ((num > 0) ? $"{num2} de {num} falaram" : string.Empty);
		ProgressFraction = ((num > 0) ? ((double)num2 / (double)num) : 0.0);
		IsFinished = num > 0 && num2 == num && PersonTalking == null;
		SpokenCount = num2;
		PersonTotalLabel = $"/ {num}";
	}

	private void UpdateQueueViews()
	{
		if (Persons == null)
		{
			NextPerson = null;
			HasNextPerson = false;
			RemainingPersons = null;
			HasRemainingPersons = false;
			NextButtonText = "Iniciar";
			return;
		}
		NextPerson = Persons.FirstOrDefault((PersonViewModel p) => !p.Talked && p != PersonTalking);
		HasNextPerson = NextPerson != null;
		List<PersonViewModel> list = Persons.Where((PersonViewModel p) => p != PersonTalking && p != NextPerson).ToList();
		int num = 2;
		foreach (PersonViewModel item in list)
		{
			item.PositionLabel = (item.Talked ? "✓" : num++.ToString());
		}
		SyncRemainingPersons(list);
		HasRemainingPersons = list.Count > 0;
		bool flag = PersonTalking == null && !Persons.Any((PersonViewModel p) => p.Talked);
		NextButtonText = (flag ? "Iniciar" : "Próximo");
	}

	private void SyncRemainingPersons(List<PersonViewModel> desired)
	{
		if (RemainingPersons == null)
		{
			RemainingPersons = new ObservableCollection<PersonViewModel>(desired);
			return;
		}
		for (int num = RemainingPersons.Count - 1; num >= 0; num--)
		{
			if (!desired.Contains(RemainingPersons[num]))
			{
				RemainingPersons.RemoveAt(num);
			}
		}
		for (int i = 0; i < desired.Count; i++)
		{
			int num2 = RemainingPersons.IndexOf(desired[i]);
			if (num2 < 0)
			{
				RemainingPersons.Insert(i, desired[i]);
			}
			else if (num2 != i)
			{
				RemainingPersons.Move(num2, i);
			}
		}
	}

	private void ApplyFontScale()
	{
		double num = Math.Pow(1.1, _fontScaleLevel);
		Application current = Application.Current;
		ResourceDictionary val = ((current != null) ? current.Resources : null);
		if (val == null)
		{
			return;
		}
		foreach (KeyValuePair<string, double> baseFontSize in _baseFontSizes)
		{
			val[baseFontSize.Key] = Math.Round(baseFontSize.Value * num, 1);
		}
		OnPropertyChanged("IsFontScaleDefault");
		OnPropertyChanged("CanDecreaseFontScale");
		OnPropertyChanged("CanIncreaseFontScale");
	}

	public void OnAppearing()
	{
		AtlassianConfigurationModel configuration = AtlassianService.GetConfiguration();
		if (configuration != null)
		{
			if (_atlassianConfigurationModel == null)
			{
				_atlassianConfigurationModel = configuration;
				UpdatePersons();
			}
			else if (configuration.Id != _atlassianConfigurationModel.Id)
			{
				_atlassianConfigurationModel = configuration;
				UpdatePersons();
			}
		}
	}
}
