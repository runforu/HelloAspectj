// -*- Mode: java; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*-
//
// Copyright (C) 2013 Opera Software ASA.  All rights reserved.
//
// This file is an original work developed by Opera Software ASA

package com.example.aspectj;

import android.os.Looper;
import android.os.Handler;
import android.util.Log;

import java.io.Closeable;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public aspect TimeProfiler {
    // TODO: Bind all static but non-final field in application context to avoid
    // NPE
    private static final String TAG = "TimeProfiler";
    private static int level = 0;
    private static final long STARTUP = System.currentTimeMillis();
    private static boolean sEnabled = false;
    private static final long MIN_DURATION = 0;
    private static final long MAX_TRACE_LEVEL = 8;

    private static StackItem sRoot;

    pointcut start():
        execution(* com.example.aspectj.LogStub.__startTrace__(..));

    after() : start() {
        startTrace();
    }

    pointcut stop():
        execution(* com.example.aspectj.LogStub.__stopTrace__(..));

    after() : stop() {
        stopTrace();
    }

    pointcut methodCalls():
        execution(* com.example..*(..)) && !within(com.example.aspectj.*);

    Object around() : methodCalls() {
        final String signature = thisJoinPointStaticPart.getSignature().toString();
        long start = (System.currentTimeMillis() - STARTUP);
        StackItem backup = null;
        if (canTrace()) {
            ++level;
            backup = sRoot;
            StackItem item = createStackItem(System.currentTimeMillis() - STARTUP);
            sRoot.mArray.put(item.mObject);
            // prepare correct stack item for sub call.
            sRoot = item;
        }
        try {
            return proceed();
        } finally {
            if (canTrace()) {
                --level;
                long end = (System.currentTimeMillis() - STARTUP);
                if (level < MAX_TRACE_LEVEL && (end - start) >= MIN_DURATION) {
                    // Add trace
                    completeCall(sRoot, end, end - start, signature);
                }
                sRoot = backup;
            }
        }
    }

    private static void startTrace() {
        assert Looper.getMainLooper() != null;
        // Runnable make sure we start on level 0
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            public void run() {
                long t = System.currentTimeMillis() - STARTUP;
                sRoot = createStackItem(t);
                sEnabled = true;
            }
        });
    }

    private static void stopTrace() {
        // Runnable make sure we stop on level 0
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            public void run() {
                long end = (System.currentTimeMillis() - STARTUP);
                completeCall(sRoot, end, end - sRoot.mStart, "root");
                sEnabled = false;
                OutputStream fos = null;
                try {
                    makePathWritable("/sdcard/log.json");
                    fos = new FileOutputStream(new File("/sdcard/log.json"));
                    fos.write(sRoot.mObject.toString(4).getBytes());
                    Log.e("huid", sRoot.mObject.toString(4));
                } catch (Exception e) {
                } finally {
                    close(fos);
                }
                
            }
        });
    }

    // Only work in main thread, do not care other thread performance.
    private static boolean canTrace() {
        return sEnabled && Looper.myLooper() == Looper.getMainLooper();
    }

    private static void completeCall(StackItem item, long end, long dur, String signature) {
        try {
            item.mObject.put("end", end);
            item.mObject.put("dur", dur);
            item.mObject.put("name", signature);
        } catch (Exception e) {
        }
    }

    private static StackItem createStackItem(long t) {
        JSONObject json = new JSONObject();
        JSONArray jarray = new JSONArray();
        try {
            json.put("child", jarray);
            json.put("start", t);
        } catch (Exception e) {
        }
        return new StackItem(json, jarray, t);
    }

    private static class StackItem {
        JSONObject mObject;
        JSONArray mArray;
        long mStart;

        StackItem(JSONObject o, JSONArray a, long t) {
            mObject = o;
            mArray = a;
            mStart = t;
        }
    }

    private static void makePathWritable(String path) {
        File f = new File(path);
        if (!f.exists() || !f.canWrite()) {
            File dir = f.getParentFile();
            f.delete();
            if (!dir.exists()) {
                dir.mkdirs();
            }
        }
    }

    private static void close(Closeable o) {
        if (o != null) {
            try {
                o.close();
            } catch (IOException t) {
            }
        }
    }
}
