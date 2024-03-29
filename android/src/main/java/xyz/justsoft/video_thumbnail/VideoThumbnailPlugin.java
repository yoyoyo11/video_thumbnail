package xyz.justsoft.video_thumbnail;

import android.content.ContentResolver;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.media.ExifInterface;
import android.media.MediaMetadataRetriever;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.provider.MediaStore;
import android.util.Log;

import java.io.FileInputStream;
import java.io.FileDescriptor;
import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.FileOutputStream;
import java.util.Map;
import java.util.HashMap;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * VideoThumbnailPlugin
 */
public class VideoThumbnailPlugin implements MethodCallHandler {
    private static String TAG = "ThumbnailPlugin";
    private static final int HIGH_QUALITY_MIN_VAL = 70;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "video_thumbnail");
        channel.setMethodCallHandler(new VideoThumbnailPlugin());
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        final Map<String, Object> args = call.arguments();

        try {
            final String video = (String) args.get("video");
            final int format = (int) args.get("format");
            final int maxhow = (int) args.get("maxhow");
            final int timeMs = (int) args.get("timeMs");
            final int quality = (int) args.get("quality");

            if (call.method.equals("file")) {
                final String path = (String) args.get("path");
                result.success(buildThumbnailFile(video, path, format, maxhow, timeMs, quality));
            } else if (call.method.equals("data")) {
                result.success(buildThumbnailData(video, format, maxhow, timeMs, quality));
            } else {
                result.notImplemented();
            }
        } catch (Exception e) {
            e.printStackTrace();
            result.error("exception", e.getMessage(), null);
        }
    }

    private static Bitmap.CompressFormat intToFormat(int format) {
        switch (format) {
        default:
        case 0:
            return Bitmap.CompressFormat.JPEG;
        case 1:
            return Bitmap.CompressFormat.PNG;
        case 2:
            return Bitmap.CompressFormat.WEBP;
        }
    }

    private static String formatExt(int format) {
        switch (format) {
        default:
        case 0:
            return new String("jpg");
        case 1:
            return new String("png");
        case 2:
            return new String("webp");
        }
    }

    private byte[] buildThumbnailData(String vidPath, int format, int maxhow, int timeMs, int quality) {
        Log.d(TAG, String.format("buildThumbnailData( format:%d, maxhow:%d, timeMs:%d, quality:%d )", format, maxhow,
                timeMs, quality));
        Bitmap bitmap = createVideoThumbnail(vidPath, maxhow, timeMs);
        if (bitmap == null)
            throw new NullPointerException();

        ByteArrayOutputStream stream = new ByteArrayOutputStream();
        bitmap.compress(intToFormat(format), quality, stream);
        bitmap.recycle();
        if (bitmap == null)
            throw new NullPointerException();
        return stream.toByteArray();
    }

    private String buildThumbnailFile(String vidPath, String path, int format, int maxhow, int timeMs, int quality) {
        Log.d(TAG, String.format("buildThumbnailFile( format:%d, maxhow:%d, timeMs:%d, quality:%d )", format, maxhow,
                timeMs, quality));
        final byte bytes[] = buildThumbnailData(vidPath, format, maxhow, timeMs, quality);
        final String ext = formatExt(format);
        final int i = vidPath.lastIndexOf(".");
        String fullpath = vidPath.substring(0, i + 1) + ext;

        if (path != null) {
            if (path.endsWith(ext)) {
                fullpath = path;
            } else {
                // try to save to same folder as the vidPath
                final int j = fullpath.lastIndexOf("/");

                if (path.endsWith("/")) {
                    fullpath = path + fullpath.substring(j + 1);
                } else {
                    fullpath = path + fullpath.substring(j);
                }
            }
        }

        try {
            FileOutputStream f = new FileOutputStream(fullpath);
            f.write(bytes);
            f.close();
            Log.d(TAG, String.format("buildThumbnailFile( written:%d )", bytes.length));
        } catch (java.io.IOException e) {
            e.getStackTrace();
            throw new RuntimeException(e);
        }
        return fullpath;
    }

    /**
     * Create a video thumbnail for a video. May return null if the video is corrupt
     * or the format is not supported.
     *
     * @param video      the URI of video
     * @param targetSize max width or height of the thumbnail
     */
    public static Bitmap createVideoThumbnail(String video, int targetSize, int timeMs) {
        Bitmap bitmap = null;
        MediaMetadataRetriever retriever = new MediaMetadataRetriever();
        try {
            Log.d(TAG, String.format("setDataSource: %s )", video));
            if (video.startsWith("file://") || video.startsWith("/")) {
                retriever.setDataSource(video);
            } else {
                retriever.setDataSource(video, new HashMap<String, String>());
            }

            if (targetSize != 0) {
                if (android.os.Build.VERSION.SDK_INT >= 27) {
                    // API Level 27
                    bitmap = retriever.getScaledFrameAtTime(timeMs * 1000, 0, targetSize, targetSize);
                } else {
                    bitmap = retriever.getFrameAtTime(timeMs * 1000);
                    if (bitmap != null) {
                        int width = bitmap.getWidth();
                        int height = bitmap.getHeight();
                        int max = Math.max(width, height);
                        float scale = (float) targetSize / max;
                        int w = Math.round(scale * width);
                        int h = Math.round(scale * height);
                        Log.d(TAG, String.format("original w:%d, h:%d, scale:%6.4f => %d, %d", width, height, scale, w,
                                h));
                        bitmap = Bitmap.createScaledBitmap(bitmap, w, h, true);
                    }
                }
            } else {
                bitmap = retriever.getFrameAtTime(timeMs * 1000);
            }
        } catch (IllegalArgumentException ex) {
            ex.printStackTrace();
        } catch (RuntimeException ex) {
            ex.printStackTrace();
        } finally {
            try {
                retriever.release();
            } catch (RuntimeException ex) {
                ex.printStackTrace();
            }
        }

        return bitmap;
    }
}
