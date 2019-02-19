package com.example;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.util.Log;
import android.view.View;

import com.example.aspectj.LogStub;
public class MainActivity extends Activity {
    @Override
    public void onBackPressed() {
        LogStub.__stopTrace__();
    }

    static Handler mHandler = new Handler();

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(new View(this));
        LogStub.__startTrace__();
        mHandler.post(new Runnable() {

            @Override
            public void run() {
                sayHello();
            }
        });
    }

    public void sayHello() {
        Log.e("huid", "----->sayHello");
        sayHello1();
        Log.e("huid", "<-----sayHello");
    }

    public void sayHello1() {
        Log.e("huid", "----->sayHello1");
        sayHello2();
        Log.e("huid", "<-----sayHello1");
    }

    public void sayHello2() {
        Log.e("huid", "----->sayHello2");
        Log.e("huid", "<-----sayHello2");
    }
}
