package com.example.tourist_safety_hub

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri

import es.antonborri.home_widget.HomeWidgetBackgroundIntent

/**
 * Implementation of App Widget functionality.
 */
class TourGuardWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // There may be multiple widgets active, so update all of them
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
}

internal fun updateAppWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int
) {
    // Construct the RemoteViews object
    val views = RemoteViews(context.packageName, R.layout.widget_layout)

    // Create an Intent to trigger background execution using the plugin helper
    val pendingIntent = HomeWidgetBackgroundIntent.getBroadcast(
        context,
        Uri.parse("tourguard://sos_background_trigger")
    )

    // Widgets allow click listeners on Views
    // We attach it to the root RelativeLayout (widget_root) so the whole widget is clickable
    views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

    // Instruct the widget manager to update the widget
    appWidgetManager.updateAppWidget(appWidgetId, views)
}
