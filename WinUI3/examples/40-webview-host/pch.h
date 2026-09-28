#pragma once

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <unknwn.h>
#include <restrictederrorinfo.h>
#include <hstring.h>

// <windows.h> defines GetCurrentTime as a macro, which collides with
// Windows::UI::Xaml::Storyboard::GetCurrentTime.
#undef GetCurrentTime

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Controls.Primitives.h>
#include <winrt/Microsoft.UI.Xaml.Data.h>
#include <winrt/Microsoft.UI.Xaml.Interop.h>
#include <winrt/Microsoft.UI.Xaml.Markup.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Microsoft.UI.Xaml.Navigation.h>
// AppWindow().MoveAndResize needs the Windowing projection in the PCH.
#include <winrt/Microsoft.UI.Windowing.h>
// WebView2: the XAML control lives in Microsoft.UI.Xaml.Controls; the Core
// side (events, settings, script) is its own namespace projected by WASDK.
#include <winrt/Microsoft.Web.WebView2.Core.h>

#include <string>

// Generated Files/XamlTypeInfo.g.cpp includes nothing but this header, yet it
// names every x:Class type, and the markup compiler emits a static_assert that
// points right here when one of them is still incomplete.
#include "App.xaml.h"
#include "MainWindow.xaml.h"
