package com.jahfali.hermex_android

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FLAG_SECURE intentionally removed per owner directive.
        // GOAL_RC6_COMPREHENSIVE_REMEDIATION.md §G.25
    }
}
