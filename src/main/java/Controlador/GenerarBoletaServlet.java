
package Controlador;

import com.itextpdf.text.BaseColor;
import com.itextpdf.text.Document;
import com.itextpdf.text.Element;
import com.itextpdf.text.Font;
import com.itextpdf.text.PageSize;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.Phrase;
import com.itextpdf.text.Rectangle;
import com.itextpdf.text.pdf.PdfPCell;
import com.itextpdf.text.pdf.PdfPTable;
import com.itextpdf.text.pdf.PdfWriter;

import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import modelo.CarritoItem;

@WebServlet("/generar-boleta")
public class GenerarBoletaServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession sesion = request.getSession();

        String usuarioNombre = (String) sesion.getAttribute("usuarioNombre");

        List<CarritoItem> carrito =
                (List<CarritoItem>) sesion.getAttribute("carrito_final");

        // Verificar que exista una compra
        if (carrito == null || carrito.isEmpty()) {
            response.sendRedirect("index.jsp");
            return;
        }

        // ============================
        // FECHA Y NÚMERO DE BOLETA
        // ============================

        Date fechaActual = new Date();

        String fechaArchivo =
                new SimpleDateFormat("yyyyMMdd_HHmmss").format(fechaActual);

        String fechaBoleta =
                new SimpleDateFormat("dd/MM/yyyy HH:mm:ss").format(fechaActual);

        String numeroBoleta =
                new SimpleDateFormat("yyyyMMddHHmmss").format(fechaActual);

        String nombreCliente =
                usuarioNombre != null ? usuarioNombre : "Cliente";

        String nombreArchivo =
                "Boleta_" +
                nombreCliente.replaceAll("[^a-zA-Z0-9]", "_") +
                "_" +
                fechaArchivo +
                ".pdf";

        response.setContentType("application/pdf");

        response.setHeader(
                "Content-Disposition",
                "attachment; filename=\"" + nombreArchivo + "\""
        );

        try {

            // ============================
            // DOCUMENTO
            // ============================

            Document document =
                    new Document(PageSize.A4, 40, 40, 40, 40);

            PdfWriter.getInstance(
                    document,
                    response.getOutputStream()
            );

            document.open();

            // ============================
            // FUENTES
            // ============================

            Font titulo = new Font(
                    Font.FontFamily.HELVETICA,
                    20,
                    Font.BOLD,
                    BaseColor.BLACK
            );

            Font subtitulo = new Font(
                    Font.FontFamily.HELVETICA,
                    10,
                    Font.NORMAL,
                    BaseColor.DARK_GRAY
            );

            Font encabezado = new Font(
                    Font.FontFamily.HELVETICA,
                    9,
                    Font.BOLD,
                    BaseColor.WHITE
            );

            Font normal = new Font(
                    Font.FontFamily.HELVETICA,
                    9,
                    Font.NORMAL,
                    BaseColor.BLACK
            );

            Font totalFont = new Font(
                    Font.FontFamily.HELVETICA,
                    12,
                    Font.BOLD,
                    BaseColor.BLACK
            );

            Font pie = new Font(
                    Font.FontFamily.HELVETICA,
                    9,
                    Font.ITALIC,
                    BaseColor.DARK_GRAY
            );

            // ============================
            // ENCABEZADO
            // ============================

            PdfPTable encabezadoEmpresa = new PdfPTable(2);

            encabezadoEmpresa.setWidthPercentage(100);

            encabezadoEmpresa.setWidths(new float[]{65, 35});

            PdfPCell empresa = new PdfPCell();

            empresa.setBorder(Rectangle.NO_BORDER);

            Paragraph nombreEmpresa =
                    new Paragraph("MINIMARKET", titulo);

            nombreEmpresa.setSpacingAfter(5);

            empresa.addElement(nombreEmpresa);

            empresa.addElement(
                    new Paragraph(
                            "Minimarket",
                            subtitulo
                    )
            );

            empresa.addElement(
                    new Paragraph(
                            "RUC: 00000000001",
                            subtitulo
                    )
            );

            empresa.addElement(
                    new Paragraph(
                            "Comprobante de venta",
                            subtitulo
                    )
            );

            encabezadoEmpresa.addCell(empresa);

            // ============================
            // DATOS DE BOLETA
            // ============================

            PdfPCell datosBoleta = new PdfPCell();

            datosBoleta.setBorder(Rectangle.BOX);
            datosBoleta.setPadding(8);

            Paragraph tipoBoleta =
                    new Paragraph(
                            "BOLETA DE VENTA",
                            new Font(
                                    Font.FontFamily.HELVETICA,
                                    12,
                                    Font.BOLD
                            )
                    );

            tipoBoleta.setAlignment(Element.ALIGN_CENTER);

            datosBoleta.addElement(tipoBoleta);

            Paragraph numero =
                    new Paragraph(
                            "N.º " + numeroBoleta,
                            normal
                    );

            numero.setAlignment(Element.ALIGN_CENTER);

            datosBoleta.addElement(numero);

            encabezadoEmpresa.addCell(datosBoleta);

            document.add(encabezadoEmpresa);

            document.add(
                    new Paragraph(" ")
            );

            // ============================
            // DATOS DEL CLIENTE
            // ============================

            PdfPTable datosCliente =
                    new PdfPTable(2);

            datosCliente.setWidthPercentage(100);

            datosCliente.setWidths(new float[]{25, 75});

            PdfPCell tituloCliente =
                    new PdfPCell(
                            new Phrase(
                                    "DATOS DEL CLIENTE",
                                    new Font(
                                            Font.FontFamily.HELVETICA,
                                            10,
                                            Font.BOLD
                                    )
                            )
                    );

            tituloCliente.setColspan(2);
            tituloCliente.setBackgroundColor(
                    new BaseColor(245, 124, 0)
            );
            tituloCliente.setPadding(6);

            datosCliente.addCell(tituloCliente);

            datosCliente.addCell(
                    new PdfPCell(
                            new Phrase(
                                    "Cliente:",
                                    new Font(
                                            Font.FontFamily.HELVETICA,
                                            9,
                                            Font.BOLD
                                    )
                            )
                    )
            );

            datosCliente.addCell(
                    new PdfPCell(
                            new Phrase(
                                    nombreCliente,
                                    normal
                            )
                    )
            );

            datosCliente.addCell(
                    new PdfPCell(
                            new Phrase(
                                    "Fecha:",
                                    new Font(
                                            Font.FontFamily.HELVETICA,
                                            9,
                                            Font.BOLD
                                    )
                            )
                    )
            );

            datosCliente.addCell(
                    new PdfPCell(
                            new Phrase(
                                    fechaBoleta,
                                    normal
                            )
                    )
            );

            document.add(datosCliente);

            document.add(
                    new Paragraph(" ")
            );

            // ============================
            // TABLA DE PRODUCTOS
            // ============================

            PdfPTable tabla =
                    new PdfPTable(5);

            tabla.setWidthPercentage(100);

            tabla.setWidths(
                    new float[]{35, 15, 12, 18, 20}
            );

            String[] columnas = {
                "Producto",
                "Precio",
                "Cant.",
                "Unidad",
                "Subtotal"
            };

            for (String columna : columnas) {

                PdfPCell celda =
                        new PdfPCell(
                                new Phrase(
                                        columna,
                                        encabezado
                                )
                        );

                celda.setBackgroundColor(
                        new BaseColor(55, 55, 55)
                );

                celda.setHorizontalAlignment(
                        Element.ALIGN_CENTER
                );

                celda.setVerticalAlignment(
                        Element.ALIGN_MIDDLE
                );

                celda.setPadding(7);

                tabla.addCell(celda);
            }

            // ============================
            // PRODUCTOS
            // ============================

            double total = 0;

            for (CarritoItem item : carrito) {

                double subtotal =
                        item.getSubtotal();

                total += subtotal;

                PdfPCell producto =
                        new PdfPCell(
                                new Phrase(
                                        item.getNombre(),
                                        normal
                                )
                        );

                producto.setPadding(6);

                tabla.addCell(producto);

                PdfPCell precio =
                        new PdfPCell(
                                new Phrase(
                                        "S/ " +
                                        String.format(
                                                "%.2f",
                                                item.getPrecio()
                                        ),
                                        normal
                                )
                        );

                precio.setHorizontalAlignment(
                        Element.ALIGN_RIGHT
                );

                precio.setPadding(6);

                tabla.addCell(precio);

                PdfPCell cantidad =
                        new PdfPCell(
                                new Phrase(
                                        String.valueOf(
                                                item.getCantidad()
                                        ),
                                        normal
                                )
                        );

                cantidad.setHorizontalAlignment(
                        Element.ALIGN_CENTER
                );

                cantidad.setPadding(6);

                tabla.addCell(cantidad);

                PdfPCell unidad =
                        new PdfPCell(
                                new Phrase(
                                        item.getUnidad(),
                                        normal
                                )
                        );

                unidad.setHorizontalAlignment(
                        Element.ALIGN_CENTER
                );

                unidad.setPadding(6);

                tabla.addCell(unidad);

                PdfPCell subtotalCelda =
                        new PdfPCell(
                                new Phrase(
                                        "S/ " +
                                        String.format(
                                                "%.2f",
                                                subtotal
                                        ),
                                        normal
                                )
                        );

                subtotalCelda.setHorizontalAlignment(
                        Element.ALIGN_RIGHT
                );

                subtotalCelda.setPadding(6);

                tabla.addCell(subtotalCelda);
            }

            document.add(tabla);

            document.add(
                    new Paragraph(" ")
            );

            // ============================
            // TOTAL
            // ============================

            PdfPTable resumen =
                    new PdfPTable(2);

            resumen.setWidthPercentage(40);

            resumen.setHorizontalAlignment(
                    Element.ALIGN_RIGHT
            );

            resumen.setWidths(
                    new float[]{55, 45}
            );

            PdfPCell textoTotal =
                    new PdfPCell(
                            new Phrase(
                                    "TOTAL A PAGAR:",
                                    totalFont
                            )
                    );

            textoTotal.setBorder(
                    Rectangle.NO_BORDER
            );

            textoTotal.setHorizontalAlignment(
                    Element.ALIGN_RIGHT
            );

            textoTotal.setPadding(7);

            resumen.addCell(textoTotal);

            PdfPCell valorTotal =
                    new PdfPCell(
                            new Phrase(
                                    "S/ " +
                                    String.format(
                                            "%.2f",
                                            total
                                    ),
                                    totalFont
                            )
                    );

            valorTotal.setBackgroundColor(
                    new BaseColor(255, 183, 77)
            );

            valorTotal.setHorizontalAlignment(
                    Element.ALIGN_RIGHT
            );

            valorTotal.setPadding(7);

            resumen.addCell(valorTotal);

            document.add(resumen);

            document.add(
                    new Paragraph(" ")
            );

            // ============================
            // PIE DE BOLETA
            // ============================

            Paragraph gracias =
                    new Paragraph(
                            "Gracias por su compra",
                            new Font(
                                    Font.FontFamily.HELVETICA,
                                    11,
                                    Font.BOLD
                            )
                    );

            gracias.setAlignment(
                    Element.ALIGN_CENTER
            );

            document.add(gracias);

            Paragraph mensaje =
                    new Paragraph(
                            "MINIMARKET  - Gracias por confiar en nosotros.",
                            pie
                    );

            mensaje.setAlignment(
                    Element.ALIGN_CENTER
            );

            document.add(mensaje);

            Paragraph generado =
                    new Paragraph(
                            "Documento generado electrónicamente",
                            pie
                    );

            generado.setAlignment(
                    Element.ALIGN_CENTER
            );

            document.add(generado);

            // ============================
            // CERRAR DOCUMENTO
            // ============================

            document.close();

        } catch (Exception e) {

            e.printStackTrace();

            if (!response.isCommitted()) {
                response.sendError(
                        HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                        "No se pudo generar la boleta."
                );
            }
        }
    }
}

