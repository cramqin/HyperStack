package dev.hyperstack;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

/**
 * Minimal helper for running a shell command through `su`.
 * No third-party root libraries required.
 */
final class RootShell {

    private RootShell() {}

    static final class Result {
        final int code;
        final String output;

        Result(int code, String output) {
            this.code = code;
            this.output = output;
        }

        boolean ok() {
            return code == 0;
        }
    }

    /** Run a command (single shell string) as root and capture combined stdout/stderr. */
    static Result run(String command) {
        return exec(new String[]{"su", "-c", command}, null);
    }

    /** Run `su -c "sh -s"` and feed the given script via stdin. */
    static Result runScript(String script) {
        return exec(new String[]{"su", "-c", "sh -s"}, script);
    }

    private static Result exec(String[] argv, String stdin) {
        Process process = null;
        try {
            ProcessBuilder pb = new ProcessBuilder(argv);
            pb.redirectErrorStream(true);
            process = pb.start();

            if (stdin != null) {
                try (OutputStream os = process.getOutputStream()) {
                    os.write(stdin.getBytes(StandardCharsets.UTF_8));
                    os.flush();
                }
            } else {
                try {
                    process.getOutputStream().close();
                } catch (Exception ignored) {
                }
            }

            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
            byte[] chunk = new byte[8192];
            int n;
            InputStream in = process.getInputStream();
            while ((n = in.read(chunk)) > 0) {
                buffer.write(chunk, 0, n);
            }
            int code = process.waitFor();
            return new Result(code, buffer.toString("UTF-8"));
        } catch (Exception e) {
            return new Result(-1, "su error: " + e);
        } finally {
            if (process != null) {
                process.destroy();
            }
        }
    }
}
