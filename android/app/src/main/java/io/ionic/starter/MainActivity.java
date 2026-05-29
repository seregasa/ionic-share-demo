package io.ionic.starter;

import android.os.Bundle;
import com.demo.shareplugin.SharePreviewPlugin;
import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {
    @Override
    public void onCreate(Bundle savedInstanceState) {
        registerPlugin(SharePreviewPlugin.class);
        super.onCreate(savedInstanceState);
    }
}
