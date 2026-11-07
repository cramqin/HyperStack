package dev.hyperstack;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends AppCompatActivity {

    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private final Handler ui = new Handler(Looper.getMainLooper());

    private TextView output;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        output = findViewById(R.id.output);

        Button enable = findViewById(R.id.btn_enable);
        Button disable = findViewById(R.id.btn_disable);
        Button refresh = findViewById(R.id.btn_status);

        enable.setOnClickListener(v -> runAsset("enable.sh"));
        disable.setOnClickListener(v -> runAsset("disable.sh"));
        refresh.setOnClickListener(v -> runAsset("status.sh"));

        runAsset("status.sh");
    }

    private void runAsset(final String assetName) {
        output.setText("Running " + assetName + " ...\n");
        executor.execute(() -> {
            String script;
            try (InputStream in = getAssets().open(assetName)) {
                java.io.ByteArrayOutputStream bos = new java.io.ByteArrayOutputStream();
                byte[] buf = new byte[8192];
                int n;
                while ((n = in.read(buf)) > 0) bos.write(buf, 0, n);
                script = bos.toString(StandardCharsets.UTF_8.name());
            } catch (Exception e) {
                post("Failed to read asset " + assetName + ": " + e);
                return;
            }

            RootShell.Result r = RootShell.runScript(script);
            post(r.output);
        });
    }

    private void post(final String text) {
        ui.post(() -> output.setText(text));
        if (text != null && text.contains("SUCCESS")) {
            ui.post(() -> Toast.makeText(this, R.string.done_toast, Toast.LENGTH_SHORT).show());
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        executor.shutdownNow();
    }
}
