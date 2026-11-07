package dev.hyperstack;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final StringBuilder log = new StringBuilder();

    private TextView output;
    private ScrollView scroll;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        output = findViewById(R.id.output);
        scroll = findViewById(R.id.scroll);

        findViewById(R.id.btn_enable).setOnClickListener(v -> runAsset("enable.sh", "Turn on"));
        findViewById(R.id.btn_disable).setOnClickListener(v -> runAsset("disable.sh", "Turn off"));
        findViewById(R.id.btn_restart_launcher).setOnClickListener(v -> runAsset("restart_launcher.sh", "Restart Launcher"));
        findViewById(R.id.btn_systemui).setOnClickListener(v -> runAsset("systemui.sh", "Restart SystemUI"));
        findViewById(R.id.btn_check).setOnClickListener(v -> runAsset("check.sh", "System check"));
        findViewById(R.id.btn_copy).setOnClickListener(v -> copyLog());
        findViewById(R.id.btn_clear).setOnClickListener(v -> clearLog());

        runAsset("check.sh", "System check");
    }

    private void runAsset(final String assetName, final String label) {
        appendLog("== " + label + " ==");
        executor.execute(() -> {
            String script;
            try (InputStream in = getAssets().open(assetName)) {
                java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n;
                while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
                script = bos.toString(StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                appendLog("ERROR reading " + assetName + ": " + e);
                return;
            }

            RootShell.Result r = RootShell.runScript(script);
            String out = r.output == null ? "" : r.output.trim();
            appendLog(out.isEmpty() ? "(no output)" : out);

            if (r.output != null && r.output.contains("SUCCESS") && r.ok()) {
                ui.post(() -> Toast.makeText(this, R.string.done_toast, Toast.LENGTH_SHORT).show());
            }
        });
    }

    private void appendLog(final String text) {
        ui.post(() -> {
            String ts = new SimpleDateFormat("HH:mm:ss", Locale.US).format(new Date());
            log.append('[').append(ts).append("] ").append(text).append('\n').append('\n');
            output.setText(log.toString());
            scroll.post(() -> scroll.fullScroll(View.FOCUS_DOWN));
        });
    }

    private void copyLog() {
        ClipboardManager cm = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (cm != null) {
            cm.setPrimaryClip(ClipData.newPlainText("HyperStack log", log.toString()));
            Toast.makeText(this, R.string.copied, Toast.LENGTH_SHORT).show();
        }
    }

    private void clearLog() {
        log.setLength(0);
        output.setText("");
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdownNow();
    }
}
