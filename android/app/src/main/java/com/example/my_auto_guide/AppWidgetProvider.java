package com.example.my_auto_guide;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetProvider;

public class AppWidgetProvider extends HomeWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);

            // Obtener datos guardados desde Flutter
            float distance = (float) widgetData.getFloat("current_distance", 0.0f);
            boolean isTracking = widgetData.getBoolean("is_tracking", false);

            views.setTextViewText(R.id.widget_distance, String.format("%.2f km", distance));
            views.setTextViewText(R.id.widget_button, isTracking ? "Detener" : "Iniciar Recorrido");

            // Configurar acción del botón
            views.setOnClickPendingIntent(R.id.widget_button, 
                getPendingIntent(context, "toggle_tracking"));

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
