using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.CompilerServices;

namespace DailyDriver;

public abstract class BaseViewModel : INotifyPropertyChanged
{
	private bool _isBusy;

	public bool IsBusy
	{
		get
		{
			return _isBusy;
		}
		set
		{
			SetProperty(ref _isBusy, value, "IsBusy");
		}
	}

	public event PropertyChangedEventHandler PropertyChanged;

	public void SetProperty<T>(ref T backingStore, T value, [CallerMemberName] string propertyName = "", Action onChanged = null)
	{
		if (!EqualityComparer<T>.Default.Equals(backingStore, value))
		{
			backingStore = value;
			onChanged?.Invoke();
			OnPropertyChanged(propertyName);
		}
	}

	protected virtual void OnPropertyChanged([CallerMemberName] string propertyName = null)
	{
		PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
	}
}
