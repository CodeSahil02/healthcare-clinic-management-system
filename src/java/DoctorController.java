import java.io.*;
import java.nio.file.Paths;
import java.sql.*;
import javax.servlet.*;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/DoctorController")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024,
    maxFileSize = 5 * 1024 * 1024,
    maxRequestSize = 10 * 1024 * 1024
)
public class DoctorController extends HttpServlet {

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");

        String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic";
        String dbUser = "root";
        String dbPass = "10june2004";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

            /* ================= ADD ================= */
            if ("add".equals(action)) {

                Part photoPart = request.getPart("photo");
                String photoPath = null;

                if (photoPart != null && photoPart.getSize() > 0) {
                    String fileName = System.currentTimeMillis() + "_" +
                            Paths.get(photoPart.getSubmittedFileName()).getFileName();

                    String uploadDir = getServletContext().getRealPath("/") + "icons/doctors/";
                    File dir = new File(uploadDir);
                    if (!dir.exists()) dir.mkdirs();

                    photoPart.write(uploadDir + fileName);
                    photoPath = "icons/doctors/" + fileName;
                }

                PreparedStatement ps = con.prepareStatement(
                    "INSERT INTO doctors (name, specialization, yoe, fee, photo, userId, status) " +
                    "VALUES (?, ?, ?, ?, ?, ?, 'ACTIVE')"
                );
                ps.setString(1, request.getParameter("name"));
                ps.setString(2, request.getParameter("specialization"));
                ps.setInt(3, Integer.parseInt(request.getParameter("yoe")));
                ps.setInt(4, Integer.parseInt(request.getParameter("fee")));
                ps.setString(5, photoPath);
                ps.setInt(6, Integer.parseInt(request.getParameter("userId")));
                ps.executeUpdate();
                ps.close();
            }

            /* ================= UPDATE ================= */
            else if ("update".equals(action)) {

                String photoPath = request.getParameter("existingPhoto");
                Part photoPart = request.getPart("photo");

                if (photoPart != null && photoPart.getSize() > 0) {
                    String fileName = System.currentTimeMillis() + "_" +
                            Paths.get(photoPart.getSubmittedFileName()).getFileName();

                    String uploadDir = getServletContext().getRealPath("/") + "icons/doctors/";
                    File dir = new File(uploadDir);
                    if (!dir.exists()) dir.mkdirs();

                    photoPart.write(uploadDir + fileName);
                    photoPath = "icons/doctors/" + fileName;
                }

                PreparedStatement ps = con.prepareStatement(
                    "UPDATE doctors SET name=?, specialization=?, yoe=?, fee=?, photo=? WHERE doctorId=?"
                );
                ps.setString(1, request.getParameter("name"));
                ps.setString(2, request.getParameter("specialization"));
                ps.setInt(3, Integer.parseInt(request.getParameter("yoe")));
                ps.setInt(4, Integer.parseInt(request.getParameter("fee")));
                ps.setString(5, photoPath);
                ps.setInt(6, Integer.parseInt(request.getParameter("doctorId")));
                ps.executeUpdate();
                ps.close();
            }

            /* ================= ACTIVATE ================= */
            else if ("activate".equals(action)) {

                PreparedStatement ps = con.prepareStatement(
                    "UPDATE doctors SET status='ACTIVE' WHERE doctorId=?"
                );
                ps.setInt(1, Integer.parseInt(request.getParameter("doctorId")));
                ps.executeUpdate();
                ps.close();
            }

            /* ================= DEACTIVATE ================= */
            else if ("deactivate".equals(action)) {

                PreparedStatement ps = con.prepareStatement(
                    "UPDATE doctors SET status='INACTIVE' WHERE doctorId=?"
                );
                ps.setInt(1, Integer.parseInt(request.getParameter("doctorId")));
                ps.executeUpdate();
                ps.close();
            }

            con.close();

        } catch (Exception e) {
            e.printStackTrace();
        }

        response.sendRedirect("manage_doctors.jsp");
    }
}
