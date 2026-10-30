using System;
using System.Collections.Generic;
using Microsoft.Maui.Graphics;

namespace DailyDriver.Features.Status;

public static class StatusPalette
{
	private const float TintAlpha = 0.16f;

	private static readonly Dictionary<string, Color> _colors = new Dictionary<string, Color>(StringComparer.OrdinalIgnoreCase)
	{
		["In Progress"] = Color.FromArgb("#34D399"),
		["To Do"] = Color.FromArgb("#5AA9F0"),
		["Backlog"] = Color.FromArgb("#8A9CB6"),
		["CODE REVIEW"] = Color.FromArgb("#FCD34D"),
		["In Preparation"] = Color.FromArgb("#22D3EE"),
		["In Refinement"] = Color.FromArgb("#A78BFA"),
		["Product Review"] = Color.FromArgb("#FB923C"),
		["Prioritized"] = Color.FromArgb("#F472B6"),
		["Rollout"] = Color.FromArgb("#A3E635"),
		["Epic"] = Color.FromArgb("#1273D4")
	};

	private static readonly Color _fallback = Color.FromArgb("#8A9CB6");

	public static Color Accent(string status)
	{
		Color value;
		return (status != null && _colors.TryGetValue(status, out value)) ? value : _fallback;
	}

	public static Color Tint(string status)
	{
		return Accent(status).WithAlpha(0.16f);
	}
}
