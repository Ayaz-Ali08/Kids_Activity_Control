package com.example.kids_activity_control;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.List;
import java.util.Map;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.util.Base64;
import java.io.ByteArrayOutputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.kids_activity_control/usage_stats";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            UsageStatsHelper usageStatsHelper = new UsageStatsHelper(this);
                            PackageManager packageManager = getPackageManager();

                            switch (call.method) {
                                case "getUsageStatsList":
                                    List<Map<String, Object>> usageStatsList = usageStatsHelper.getUsageStatsList();
                                    JSONArray jsonArray = new JSONArray();
                                    for (Map<String, Object> usageStats : usageStatsList) {
                                        JSONObject jsonObject = new JSONObject(usageStats);

                                        // Get the package name
                                        String packageName = (String) usageStats.get("packageName");

                                        // Fetch the app icon and convert to base64 string
                                        try {
                                            ApplicationInfo appInfo = packageManager.getApplicationInfo(packageName, 0);
                                            Drawable appIcon = packageManager.getApplicationIcon(appInfo);
                                            jsonObject.put("appIcon", drawableToBase64(appIcon));
                                        } catch (PackageManager.NameNotFoundException e) {
                                            e.printStackTrace();
                                            try {
                                                jsonObject.put("appIcon", null);  // Set to null if icon not found
                                            } catch (JSONException jsonException) {
                                                jsonException.printStackTrace();
                                            }
                                        } catch (JSONException e) {
                                            e.printStackTrace();
                                        }

                                        jsonArray.put(jsonObject);
                                    }
                                    result.success(jsonArray.toString());
                                    break;
                                default:
                                    result.notImplemented();
                                    break;
                            }
                        }
                );
    }

    // Helper method to convert Drawable to Base64 string
    private String drawableToBase64(Drawable drawable) {
        if (drawable == null) {
            return null;
        }

        Bitmap bitmap = ((android.graphics.drawable.BitmapDrawable) drawable).getBitmap();
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();

        return Base64.encodeToString(byteArray, Base64.NO_WRAP);
    }
}
