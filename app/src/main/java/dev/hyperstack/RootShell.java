package dev.hyperstack;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Locale;

/**
 * Minimal helper for running a shell command through `su`.
 *
 * KernelSU/Magisk `su` run in the caller's (app's) mount namespace by default, where other
 * apps' data dirs are masked. We must force the *global* mount namespace with `-M`, otherwise
 * `/data/user_de/0/com.miui.home/...` is invisible and every write silently fails.
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

    /** Run a command as root (global mount namespace) and capture combined stdout/stderr. */
    static Result run(String command) {
        Result r = exec(new String[]{"su", "-M", "-c", command}, null);
        if (mountMasterUnsupported(r)) {
            r = exec(new String[]{"su", "-c", command}, null);
        }
        return r;
    }

    /** Feed a script to `sh -s` as root (global mount namespace). */
    static Result runScript(String script) {
        Result r = exec(new String[]{"su", "-M", "-c", "sh -s"}, script);
        if (mountMasterUnsupported(r)) {
            r = exec(new String[]{"su", "-c", "sh -s"}, script);
        }
        return r;
    }

    private static boolean mountMasterUnsupported(Result r) {
        if (r == null || r.code == 0) return false;
        String o = r.output == null ? "" : r.output.toLowerCase(Locale.ROOT);
        return o.contains("usage: su") || o.contains("invalid option")
                || o.contains("unknown option") || o.contains("unrecognized option")
                || o.contains("illegal option");
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
                } catch (Exception ignored) {
                    // su may exit before reading stdin (e.g. unsupported -M); ignore.
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
            return new Result(-1, "ROOT_UNAVAILABLE: cannot run su (" + e.getMessage() + ")");
        } finally {
            if (process != null) {
                process.destroy();
            }
        }
    }
}
