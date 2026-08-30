package com.example.my_auto_guide;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetProvider;
import java.io.File;

public class VehicleStatusListWidgetProvider extends HomeWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.health_list_widget_layout);

            // Cargar las barras horizontales renderizadas por Flutter
            setWidgetImage(views, widgetData, R.id.img_list_aceite, "widget_list_aceite");
            setWidgetImage(views, widgetData, R.id.img_list_cadena, "widget_list_cadena");
            setWidgetImage(views, widgetData, R.id.img_list_filtro, "widget_list_filtro");
            setWidgetImage(views, widgetData, R.id.img_list_soat, "widget_list_soat");

            appWidgetManager.updateAppWidget(appWidgetId, views);
        }
    }

    private void setWidgetImage(RemoteViews views, SharedPreferences prefs, int imageViewId, String key) {
        String imagePath = prefs.getString(key, null);
        if (imagePath != null) {
            File imgFile = new File(imagePath);
            if (imgFile.exists()) {
                Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
                if (bitmap != null) {
                    views.setImageViewBitmap(imageViewId, bitmap);
                }
            }
        }
    }
}
