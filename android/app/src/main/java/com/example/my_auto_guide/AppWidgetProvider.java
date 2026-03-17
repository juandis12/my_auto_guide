package com.example.my_auto_guide;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.app.PendingIntent;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetLaunchIntent;
import es.antonborri.home_widget.HomeWidgetProvider;

public class AppWidgetProvider extends HomeWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);

            // Leer datos
            double distance = 0.0;
            try {
                long rawBits = widgetData.getLong("current_distance", Double.doubleToLongBits(0.0));
                distance = Double.longBitsToDouble(rawBits);
            } catch (ClassCastException e) {
                distance = widgetData.getFloat("current_distance", 0.0f);
            }

            boolean isTracking = widgetData.getBoolean("is_tracking", false);

            // Actualizar textos
            views.setTextViewText(R.id.widget_distance, String.format("%.2f", distance));
            
            // Estado visual
            if (isTracking) {
                views.setTextViewText(R.id.widget_button, "DETENER RECORRIDO");
                views.setTextViewText(R.id.widget_status_text, "Recorrido activo");
                views.setInt(R.id.widget_status_dot, "setBackgroundColor", 0xFF4CAF50); // Verde
            } else {
                views.setTextViewText(R.id.widget_button, "INICIAR RECORRIDO");
                views.setTextViewText(R.id.widget_status_text, "Listo para recorrer");
                views.setInt(R.id.widget_status_dot, "setBackgroundColor", 0xFF666666); // Gris
            }

            // Botón abre la app con deep link para auto-iniciar tracking
            PendingIntent startTrackingIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(
                context, MainActivity.class, Uri.parse("myAutoGuide://start_free_tracking"));
            views.setOnClickPendingIntent(R.id.widget_button, startTrackingIntent);

            // Contenedor abre la app normalmente
            PendingIntent launchIntent = HomeWidgetLaunchIntent.INSTANCE.getActivity(
                context, MainActivity.class, null);
            views.setOnClickPendingIntent(R.id.widget_container, launchIntent);

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }
}
