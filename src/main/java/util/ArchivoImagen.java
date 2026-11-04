package util;
import java.io.*;
import javax.imageio.*;
import javax.imageio.stream.ImageInputStream;
import javax.servlet.http.Part;
public final class ArchivoImagen {
 public final byte[] datos; public final String tipo;
 private ArchivoImagen(byte[] d,String t) { datos=d;tipo=t; }
 public static ArchivoImagen leer(Part foto) throws Exception {
  if(foto==null || foto.getSize()==0 || foto.getSize()>5242880) throw new IllegalArgumentException("Selecciona una foto de hasta 5 MB.");
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        try (InputStream in = foto.getInputStream()) {
            byte[] bytes = new byte[8192]; int n;
            while ((n = in.read(bytes)) != -1) buffer.write(bytes, 0, n);
        }
        byte[] datos = buffer.toByteArray();
        String tipo;
        try (ImageInputStream input = ImageIO.createImageInputStream(new ByteArrayInputStream(datos))) {
            java.util.Iterator<ImageReader> lectores = ImageIO.getImageReaders(input);
            if (!lectores.hasNext()) throw new IllegalArgumentException("El archivo no es una imagen válida.");
            ImageReader lector = lectores.next();
            try {
                lector.setInput(input);
                String formato = lector.getFormatName().toLowerCase(java.util.Locale.ROOT);
                if (!java.util.Arrays.asList("jpeg", "png", "gif").contains(formato)) throw new IllegalArgumentException("Usa imágenes JPG, PNG o GIF.");
                if ((long) lector.getWidth(0) * lector.getHeight(0) > 40000000L) throw new IllegalArgumentException("La imagen supera los 40 megapíxeles.");
                tipo = "image/" + formato;
            } finally { lector.dispose(); }
        }

  return new ArchivoImagen(datos,tipo);
 }
}
