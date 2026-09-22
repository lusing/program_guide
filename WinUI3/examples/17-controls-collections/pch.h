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
#include <winrt/Microsoft.UI.Composition.h>
#include <winrt/Microsoft.UI.Dispatching.h>
#include <winrt/Microsoft.UI.Xaml.h>
#include <winrt/Microsoft.UI.Xaml.Controls.h>
#include <winrt/Microsoft.UI.Xaml.Controls.Primitives.h>
#include <winrt/Microsoft.UI.Xaml.Data.h>
#include <winrt/Microsoft.UI.Xaml.Interop.h>
#include <winrt/Microsoft.UI.Xaml.Markup.h>
#include <winrt/Microsoft.UI.Xaml.Media.h>
#include <winrt/Microsoft.UI.Xaml.Navigation.h>
#include <winrt/Microsoft.UI.Xaml.Shapes.h>
#include <winrt/Microsoft.UI.Text.h>
#include <winrt/Microsoft.UI.Windowing.h>
#include <winrt/Windows.Graphics.h>

// Generated Files/XamlTypeInfo.g.cpp includes nothing but this header, yet it
// names every x:Class type, and the markup compiler emits a static_assert that
// points right here when one of them is still incomplete.
#include "App.xaml.h"
#include "MainWindow.xaml.h"
#include "HomePage.xaml.h"
#include "ListViewPage.xaml.h"
#include "GridViewPage.xaml.h"
#include "TreeViewPage.xaml.h"
#include "TablePage.xaml.h"
