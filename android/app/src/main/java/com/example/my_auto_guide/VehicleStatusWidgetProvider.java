package com.example.my_auto_guide;

import android.appwidget.AppWidgetManager;
import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.widget.RemoteViews;
import es.antonborri.home_widget.HomeWidgetProvider;
import java.io.File;

public class VehicleStatusWidgetProvider extends HomeWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds, SharedPreferences widgetData) {
        for (int appWidgetId : appWidgetIds) {
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.health_widget_layout);

            // Cargar las imágenes renderizadas por Flutter
            setWidgetImage(views, widgetData, R.id.img_cadena, "widget_cadena");
            setWidgetImage(views, widgetData, R.id.img_filtro, "widget_filtro");
            setWidgetImage(views, widgetData, R.id.img_aceite, "widget_aceite");
            setWidgetImage(views, widgetData, R.id.img_soat, "widget_soat");
            setWidgetImage(views, widgetData, R.id.img_tecno, "widget_tecno");

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
