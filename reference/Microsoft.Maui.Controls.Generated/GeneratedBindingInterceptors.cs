using System.CodeDom.Compiler;

namespace Microsoft.Maui.Controls.Generated;

[GeneratedCode("Microsoft.Maui.Controls.BindingSourceGen, Version=10.0.0.0, Culture=neutral, PublicKeyToken=null", "10.0.0.0")]
internal static class GeneratedBindingInterceptors
{
	private static bool ShouldUseSetter(BindingMode mode, BindableProperty bindableProperty)
	{
		//IL_0000: Unknown result type (might be due to invalid IL or missing references)
		//IL_0002: Invalid comparison between Unknown and I4
		//IL_0004: Unknown result type (might be due to invalid IL or missing references)
		//IL_0006: Invalid comparison between Unknown and I4
		//IL_0008: Unknown result type (might be due to invalid IL or missing references)
		//IL_000c: Unknown result type (might be due to invalid IL or missing references)
		//IL_0012: Invalid comparison between Unknown and I4
		//IL_0015: Unknown result type (might be due to invalid IL or missing references)
		//IL_001b: Invalid comparison between Unknown and I4
		return (int)mode == 3 || (int)mode == 1 || ((int)mode == 0 && ((int)bindableProperty.DefaultBindingMode == 3 || (int)bindableProperty.DefaultBindingMode == 1));
	}

	private static bool ShouldUseSetter(BindingMode mode)
	{
		//IL_0000: Unknown result type (might be due to invalid IL or missing references)
		//IL_0002: Invalid comparison between Unknown and I4
		//IL_0004: Unknown result type (might be due to invalid IL or missing references)
		//IL_0006: Invalid comparison between Unknown and I4
		//IL_0008: Unknown result type (might be due to invalid IL or missing references)
		//IL_000a: Invalid comparison between Unknown and I4
		return (int)mode == 3 || (int)mode == 1 || (int)mode == 0;
	}
}
