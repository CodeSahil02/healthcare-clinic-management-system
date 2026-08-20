<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    // --- Session & param checks ---
    if (session.getAttribute("role") == null || !session.getAttribute("role").equals("doctor")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String doctorName = (String) session.getAttribute("user");
    String doctorEmail = (String) session.getAttribute("email");

    String idParam = request.getParameter("id");
    String idParam2 = request.getParameter("appointmentId");
    String apptIdStr = (idParam != null && !idParam.trim().isEmpty()) ? idParam : idParam2;

    if (apptIdStr == null || apptIdStr.trim().isEmpty()) {
        out.println("<p style='color:darkred; padding:20px;'>No appointment id provided.</p>");
        return;
    }

    int apptId = -1;
    try {
        apptId = Integer.parseInt(apptIdStr);
    } catch (NumberFormatException nfe) {
        out.println("<p style='color:darkred; padding:20px;'>Invalid appointment id.</p>");
        return;
    }

    // DB config
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    // Variables for display
    String patientName = "";
    String patientEmail = "";
    String scheduledAt = "";
    String status = "";
    boolean appointmentFound = false;
    String message = "";

    // On POST: handle update
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String newStatus = request.getParameter("status");
        String notesText = request.getParameter("notes");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

                // 1) Ensure appointment belongs to this doctor (by doctorName)
                String ownerCheck = "SELECT doctorName FROM appointments WHERE appointmentId = ?";
                try (PreparedStatement pc = con.prepareStatement(ownerCheck)) {
                    pc.setInt(1, apptId);
                    try (ResultSet rc = pc.executeQuery()) {
                        if (!rc.next() || rc.getString("doctorName") == null || !rc.getString("doctorName").equals(doctorName)) {
                            message = "You are not allowed to modify this appointment.";
                        } else {
                            // 2) Update status
                            String updateSql = "UPDATE appointments SET status = ? WHERE appointmentId = ?";
                            try (PreparedStatement up = con.prepareStatement(updateSql)) {
                                up.setString(1, newStatus);
                                up.setInt(2, apptId);
                                up.executeUpdate();
                            }

                            // 3) Store notes: if appointments.notes exists update it; otherwise use consult_notes table (create if missing).
                            boolean appointmentsHasNotes = false;
                            String colQuery = "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'notes'";
                            try (PreparedStatement cst = con.prepareStatement(colQuery)) {
                                cst.setString(1, "healthcare_clinic");
                                try (ResultSet cr = cst.executeQuery()) {
                                    if (cr.next()) appointmentsHasNotes = true;
                                }
                            }
                            if (appointmentsHasNotes) {
                                String upNotes = "UPDATE appointments SET notes = ? WHERE appointmentId = ?";
                                try (PreparedStatement pn = con.prepareStatement(upNotes)) {
                                    pn.setString(1, notesText);
                                    pn.setInt(2, apptId);
                                    pn.executeUpdate();
                                }
                            } else {
                                // create consult_notes table if not exists and upsert
                                String create = "CREATE TABLE IF NOT EXISTS consult_notes (" +
                                                "appointmentId INT PRIMARY KEY," +
                                                "notes TEXT," +
                                                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP" +
                                                ")";
                                try (Statement screate = con.createStatement()) {
                                    screate.execute(create);
                                }
                                // upsert
                                String upsert = "INSERT INTO consult_notes (appointmentId, notes) VALUES (?, ?) " +
                                                "ON DUPLICATE KEY UPDATE notes = VALUES(notes)";
                                try (PreparedStatement upn = con.prepareStatement(upsert)) {
                                    upn.setInt(1, apptId);
                                    upn.setString(2, notesText);
                                    upn.executeUpdate();
                                }
                            }
                            message = "Saved successfully.";
                        }
                    }
                }
            }
        } catch (Exception e) {
            message = "Error saving consult: " + e.getMessage();
        }
    }

    // Fetch appointment details for rendering (fresh)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            String sql = "SELECT appointmentId, patientName, patientEmail, scheduledAt, status FROM appointments WHERE appointmentId = ?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, apptId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        appointmentFound = true;
                        patientName = rs.getString("patientName");
                        patientEmail = rs.getString("patientEmail");
                        scheduledAt = rs.getString("scheduledAt");
                        status = rs.getString("status");
                    }
                }
            }

            // Load notes for display (if exist in appointments table prefer it else check consult_notes)
            String notesVal = "";
            if (appointmentFound) {
                boolean appointmentsHasNotes = false;
                String colQuery = "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'appointments' AND COLUMN_NAME = 'notes'";
                try (PreparedStatement cst = con.prepareStatement(colQuery)) {
                    cst.setString(1, "healthcare_clinic");
                    try (ResultSet cr = cst.executeQuery()) {
                        if (cr.next()) appointmentsHasNotes = true;
                    }
                }
                if (appointmentsHasNotes) {
                    String q = "SELECT notes FROM appointments WHERE appointmentId = ?";
                    try (PreparedStatement p = con.prepareStatement(q)) {
                        p.setInt(1, apptId);
                        try (ResultSet r = p.executeQuery()) {
                            if (r.next()) notesVal = r.getString("notes");
                        }
                    }
                } else {
                    // consult_notes table (if exists)
                    String checkTable = "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'consult_notes'";
                    try (PreparedStatement p = con.prepareStatement(checkTable)) {
                        p.setString(1, "healthcare_clinic");
                        try (ResultSet r = p.executeQuery()) {
                            if (r.next() && r.getInt(1) > 0) {
                                String q = "SELECT notes FROM consult_notes WHERE appointmentId = ?";
                                try (PreparedStatement pn = con.prepareStatement(q)) {
                                    pn.setInt(1, apptId);
                                    try (ResultSet rn = pn.executeQuery()) {
                                        if (rn.next()) notesVal = rn.getString("notes");
                                    }
                                }
                            }
                        }
                    }
                }
                request.setAttribute("existingNotes", notesVal == null ? "" : notesVal);
            }
        }
    } catch (Exception e) {
        message = (message.isEmpty() ? "" : message + " ") + "Error loading appointment: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Consult — Appointment #<%= apptId %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1"/>
    <style>
        body { font-family: Arial, sans-serif; background: #f3fbf8; color:#063829; margin:0; padding:0; }
        .wrap { max-width:900px; margin:32px auto; padding:0 16px 80px; }
        .top { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; }
        .back { color:#198754; text-decoration:none; font-weight:800; }
        .card { background:white; border-radius:12px; padding:18px; box-shadow:0 10px 30px rgba(3,40,34,0.06); }
        .grid { display:grid; grid-template-columns: 1fr 320px; gap:18px; align-items:start; }
        .meta { font-weight:700; margin-bottom:8px; }
        label { display:block; margin-top:12px; font-weight:800; }
        select, textarea, input[type="text"] { width:100%; padding:10px; border-radius:8px; border:1px solid #d7efe6; font-size:14px; box-sizing:border-box; }
        textarea { min-height:160px; resize:vertical; }
        .btn { display:inline-block; padding:12px 16px; background:#198754; color:white; border-radius:10px; border:none; font-weight:800; cursor:pointer; margin-top:12px; }
        .muted { color:#617f74; font-weight:700; }
        .status-badge { padding:6px 10px; border-radius:999px; font-weight:900; }
        .Scheduled { background:#e7f7ef; color:#198754; }
        .InConsult { background:#fff1d6; color:#b38300; }
        .Completed { background:#e3f1ff; color:#0d6efd; }
        .Cancelled { background:#f2e9ea; color:#a1201f; }
        .notice { margin:12px 0; padding:10px; background:#fff7e9; border-radius:8px; color:#7a5b00; font-weight:800; }
        @media(max-width:900px) { .grid { grid-template-columns: 1fr; } }
    </style>
</head>
<body>
    <div class="wrap">
        <div class="top">
            <a class="back" href="doctor_dashboard.jsp">← Back to Dashboard</a>
            <div>Appointment #: <strong><%= apptId %></strong></div>
        </div>

        <% if (!appointmentFound) { %>
            <div class="card">
                <p style="color:darkred; font-weight:800;">Appointment not found.</p>
            </div>
        <% } else { %>

        <div class="grid">

            <!-- LEFT: form -->
            <div class="card">
                <h3 style="margin-top:0;">Consultation</h3>

                <% if (message != null && !message.equals("")) { %>
                    <div class="notice"><%= message %></div>
                <% } %>

                <div class="meta">Patient: <span class="muted"><%= patientName %> &lt;<%= patientEmail %>&gt;</span></div>
                <div class="meta">Scheduled at: <span class="muted"><%= scheduledAt %></span></div>
                <div class="meta">Current status: <span class="status-badge <%= status.replace(" ", "") %>"><%= status %></span></div>

                <form method="POST">
                    <label for="status">Update Status</label>
                    <select id="status" name="status" required>
                        <option value="Scheduled" <%= "Scheduled".equalsIgnoreCase(status) ? "selected" : "" %>>Scheduled</option>
                        <option value="InConsult" <%= "InConsult".equalsIgnoreCase(status) || "In Consult".equalsIgnoreCase(status) ? "selected" : "" %>>InConsult</option>
                        <option value="Completed" <%= "Completed".equalsIgnoreCase(status) ? "selected" : "" %>>Completed</option>
                        <option value="Cancelled" <%= "Cancelled".equalsIgnoreCase(status) ? "selected" : "" %>>Cancelled</option>
                    </select>

                    <label for="notes">Consultation Notes</label>
                    <textarea id="notes" name="notes" placeholder="Write consultation summary, prescriptions, follow-up instructions..."><%= request.getAttribute("existingNotes") == null ? "" : (String)request.getAttribute("existingNotes") %></textarea>

                    <button class="btn" type="submit">Save</button>
                </form>
            </div>

            <!-- RIGHT: quick patient actions -->
            <div>
                <div class="card">
                    <h4 style="margin-top:0;">Quick actions</h4>
                    <p><strong>Patient:</strong> <br/><span class="muted"><%= patientName %> &lt;<%= patientEmail %>&gt;</span></p>
                    <p><strong>Open records:</strong></p>
                    <p><a href="patient_records_view.jsp?email=<%= java.net.URLEncoder.encode(patientEmail, "UTF-8") %>">View patient records</a></p>
                </div>
            </div>

        </div>
        <% } %>

    </div>
</body>
</html>
