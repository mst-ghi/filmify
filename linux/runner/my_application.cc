#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  GtkWindow* window;
  FlMethodChannel* window_channel;
  // Draggable top strip, in Flutter logical pixels, reported from Dart.
  GdkRectangle drag_rect;
  gboolean has_drag_rect;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Starts a window move on a top-strip press. Wayland only honors
// gtk_window_begin_move_drag while the press's implicit pointer grab is still
// active, so this must happen synchronously with the event — a deferred
// platform-channel call is silently ignored by the compositor.
//
// This runs as a signal emission hook rather than a g_signal_connect: the
// engine delivers pointer input through an internal event box inside the
// FlView, and its own press handler (connected first) consumes the signal, so
// a handler on the view itself never runs. Hooks observe the emission before
// any handler, regardless of which widget it lands on.
static gboolean window_press_hook(GSignalInvocationHint* /*hint*/,
                                  guint n_fparams,
                                  const GValue* fparams,
                                  gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (self->window == nullptr || n_fparams < 2 ||
      !G_VALUE_HOLDS(&fparams[1], GDK_TYPE_EVENT)) {
    return TRUE;
  }
  GtkWidget* widget = GTK_WIDGET(g_value_get_object(&fparams[0]));
  if (widget == nullptr ||
      gtk_widget_get_toplevel(widget) != GTK_WIDGET(self->window)) {
    return TRUE;
  }
  GdkEventButton* event =
      static_cast<GdkEventButton*>(g_value_get_boxed(&fparams[1]));
  if (event == nullptr) return TRUE;

  // GTK event coords are logical pixels relative to the widget under the
  // pointer — the event box spans the whole content area, so they line up
  // with the Dart-reported drag region.
  const double x = event->x;
  const double y = event->y;
  const GdkRectangle* r = &self->drag_rect;
  const gboolean hit = self->has_drag_rect && x >= r->x &&
                       x < r->x + r->width && y >= r->y &&
                       y < r->y + r->height;
  if (y < 80) {
    g_message("filmify: press %.1f,%.1f button=%u rect=%d,%d+%dx%d -> %s", x,
              y, event->button, r->x, r->y, r->width, r->height,
              hit ? "move" : "pass");
  }
  if (hit) {
    gtk_window_begin_move_drag(self->window, event->button, event->x_root,
                               event->y_root, event->time);
  }
  return TRUE;  // Keep the hook installed; never consume the event.
}

static double map_get_double(FlValue* map, const char* key) {
  FlValue* v = fl_value_lookup_string(map, key);
  if (v == nullptr) return 0.0;
  if (fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) {
    return fl_value_get_float(v);
  }
  if (fl_value_get_type(v) == FL_VALUE_TYPE_INT) {
    return static_cast<double>(fl_value_get_int(v));
  }
  return 0.0;
}

// Window chrome controls for the frameless build, driven from Dart via the
// 'filmify/window' method channel.
static void handle_window_method_call(FlMethodChannel* channel,
                                      FlMethodCall* call,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  const char* method = fl_method_call_get_name(call);
  GtkWindow* window = self->window;

  if (window == nullptr) {
    g_autoptr(FlMethodResponse) error = FL_METHOD_RESPONSE(
        fl_method_error_response_new("no-window", "Window not created",
                                     nullptr));
    fl_method_call_respond(call, error, nullptr);
    return;
  }

  if (g_strcmp0(method, "close") == 0) {
    gtk_window_close(window);
  } else if (g_strcmp0(method, "minimize") == 0) {
    gtk_window_iconify(window);
  } else if (g_strcmp0(method, "toggleMaximize") == 0) {
    if (gtk_window_is_maximized(window)) {
      gtk_window_unmaximize(window);
    } else {
      gtk_window_maximize(window);
    }
  } else if (g_strcmp0(method, "setDragRegion") == 0) {
    FlValue* args = fl_method_call_get_args(call);
    if (fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      self->drag_rect.x = (int)map_get_double(args, "x");
      self->drag_rect.y = (int)map_get_double(args, "y");
      self->drag_rect.width = (int)map_get_double(args, "width");
      self->drag_rect.height = (int)map_get_double(args, "height");
      self->has_drag_rect = TRUE;
      g_message("filmify: drag region %d,%d %dx%d", self->drag_rect.x,
                self->drag_rect.y, self->drag_rect.width,
                self->drag_rect.height);
    }
  } else {
    fl_method_call_respond_not_implemented(call, nullptr);
    return;
  }

  g_autoptr(FlMethodResponse) ok = FL_METHOD_RESPONSE(
      fl_method_success_response_new(fl_value_new_null()));
  fl_method_call_respond(call, ok, nullptr);
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void window_destroy_cb(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  self->window = nullptr;
}

static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;

  // ARGB visual + paintable window so the Dart-side rounded clip produces
  // genuinely rounded corners (the transparent corner pixels show the
  // desktop). Required on X11; harmless on Wayland where surfaces are ARGB.
  GdkScreen* screen = gdk_screen_get_default();
  GdkVisual* rgba_visual = gdk_screen_get_rgba_visual(screen);
  if (rgba_visual != nullptr) {
    gtk_widget_set_visual(GTK_WIDGET(window), rgba_visual);
  }
  gtk_widget_set_app_paintable(GTK_WIDGET(window), TRUE);

  // Frameless window: no GTK header bar / WM title bar — the app paints its
  // own chrome. The title is kept for the task switcher. Move the window with
  // WM shortcuts (Super+middle-drag or Alt+F7 on GNOME), close with Alt+F4.
  gtk_window_set_title(window, "Filmify");
  gtk_window_set_decorated(window, FALSE);

  gtk_window_set_default_size(window, 1200, 800);
  GdkGeometry min_size;
  min_size.min_width = 800;
  min_size.min_height = 600;
  gtk_window_set_geometry_hints(window, nullptr, &min_size, GDK_HINT_MIN_SIZE);
  g_signal_connect(window, "destroy", G_CALLBACK(window_destroy_cb), self);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Fully transparent: the app paints its own (rounded) background.
  gdk_rgba_parse(&background_color, "#00000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Window chrome channel + synchronous drag handling.
  g_signal_add_emission_hook(
      g_signal_lookup("button-press-event", GTK_TYPE_WIDGET), 0,
      window_press_hook, self, nullptr);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->window_channel = FL_METHOD_CHANNEL(g_object_ref_sink(
      fl_method_channel_new(
          fl_engine_get_binary_messenger(fl_view_get_engine(view)),
          "filmify/window", FL_METHOD_CODEC(codec))));
  fl_method_channel_set_method_call_handler(self->window_channel,
                                            handle_window_method_call, self,
                                            nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  g_clear_object(&self->window_channel);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
