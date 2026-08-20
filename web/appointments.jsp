<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Session check
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("patient")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String patientName = (String) session.getAttribute("user");
    String patientEmail = (String) session.getAttribute("email");

    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    String message = null;
    String adminError = null;
    String discoveredIdCol = null; // actual PK column name in DB (e.g., appointmentId)
    String discoveredNotesCol = null; // actual notes-like column name, if any

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            String schema = "healthcare_clinic";

            // 1) Determine an ID column to use (try commons, then PRIMARY)
            String idCandidates = "'id','appointment_id','appt_id','appointmentId','apptId','appointmentID','appointmentId'";
            String colQuery = "SELECT COLUMN_NAME FROM information_schema.COLUMNS " +
                              "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'appointments' AND COLUMN_NAME IN (" + idCandidates + ") LIMIT 1";
            try (PreparedStatement colCheck = con.prepareStatement(colQuery)) {
                colCheck.setString(1, schema);
                try (ResultSet cr = colCheck.executeQuery()) {
                    if (cr.next()) discoveredIdCol = cr.getString("COLUMN_NAME");
                }
            }
            if (discoveredIdCol == null) {
                String pkQuery = "SELECT COLUMN_NAME FROM information_schema.KEY_COLUMN_USAGE " +
                                 "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'appointments' AND CONSTRAINT_NAME = 'PRIMARY' LIMIT 1";
                try (PreparedStatement pk = con.prepareStatement(pkQuery)) {
                    pk.setString(1, schema);
                    try (ResultSet pr = pk.executeQuery()) {
                        if (pr.next()) discoveredIdCol = pr.getString("COLUMN_NAME");
                    }
                }
            }

            if (discoveredIdCol == null) {
                adminError = "Could not determine appointments primary-key column. Run: SHOW COLUMNS FROM appointments;";
            } else {
                // 2) Determine if a notes-like column exists (try common names)
                String notesCandidates = "'notes','note','remark','comments','notesText','description'";
                String notesQuery = "SELECT COLUMN_NAME FROM information_schema.COLUMNS " +
                                    "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'appointments' AND COLUMN_NAME IN (" + notesCandidates + ") LIMIT 1";
                try (PreparedStatement ncheck = con.prepareStatement(notesQuery)) {
                    ncheck.setString(1, schema);
                    try (ResultSet nr = ncheck.executeQuery()) {
                        if (nr.next()) discoveredNotesCol = nr.getString("COLUMN_NAME");
                    }
                }

                // 3) Handle cancel action using discoveredIdCol
                String action = request.getParameter("action");
                if ("cancel".equals(action)) {
                    String idStr = request.getParameter("id");
                    if (idStr == null) {
                        idStr = request.getParameter(discoveredIdCol);
                    }
                    if (idStr != null) {
                        try {
                            String updateSql = "UPDATE appointments SET status = 'Cancelled' WHERE " + discoveredIdCol + " = ? AND patientEmail = ? AND status = 'Scheduled'";
                            try (PreparedStatement pst = con.prepareStatement(updateSql)) {
                                pst.setObject(1, Integer.parseInt(idStr));
                                pst.setString(2, patientEmail);
                                int updated = pst.executeUpdate();
                                if (updated > 0) {
                                    message = "Appointment cancelled.";
                                } else {
                                    message = "Unable to cancel appointment. It may already be completed/cancelled or doesn't belong to you.";
                                }
                            }
                        } catch (NumberFormatException nfe) {
                            message = "Invalid appointment id.";
                        } catch (Exception e) {
                            message = "Error cancelling appointment: " + e.getMessage();
                        }
                    }
                }

                // 4) Build SELECT: alias PK as id and include notes AS notes (or NULL AS notes)
                String notesSelect = (discoveredNotesCol != null) ? discoveredNotesCol + " AS notes" : "NULL AS notes";
                String sql = "SELECT " + discoveredIdCol + " AS id, doctorName, scheduledAt, status, " + notesSelect +
                             " FROM appointments WHERE patientEmail = ? ORDER BY scheduledAt DESC";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, patientEmail);
                    try (ResultSet rs = ps.executeQuery()) {
                        // convert ResultSet to list for rendering
                        List<Map<String,String>> list = new ArrayList<>();
                        while (rs.next()) {
                            Map<String,String> row = new HashMap<>();
                            Object idObj = rs.getObject("id");
                            row.put("id", idObj == null ? "" : String.valueOf(idObj));
                            row.put("doctor", rs.getString("doctorName"));
                            row.put("time", rs.getString("scheduledAt"));
                            row.put("status", rs.getString("status"));
                            String notes = rs.getString("notes"); // will be null if not present
                            row.put("notes", notes == null ? "" : notes);
                            list.add(row);
                        }
                        request.setAttribute("appointmentsList", list);
                    }
                }
            }
        }
    } catch (Exception e) {
        out.println("<div style='color:red;'>Error preparing appointments: " + e.getMessage() + "</div>");
    }

    List<Map<String,String>> appointments = (List<Map<String,String>>) request.getAttribute("appointmentsList");
    if (appointments == null) appointments = new ArrayList<>();
%>

<!DOCTYPE html>
<html>
<head>
    <title>Your Appointments - HealthCare Clinic</title>
    <link rel="stylesheet" href="styles.css">
    <style>
        body { background: #e8f5f3; font-family: Arial; }
        .container { width: 90%; max-width: 1100px; margin: 20px auto; }
        .topbar { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; }
        .brand { font-weight:700; color:#063829; }
        .dash-card { background: white; padding: 18px; border-radius: 12px; margin-bottom: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
        table { width:100%; border-collapse:collapse; margin-top:12px; }
        th, td { padding:10px; border-bottom:1px solid #ddd; font-size:14px; text-align:left; }
        th { background:#f3fdfa; color:#063829; }
        .status { padding:6px 10px; border-radius:6px; color:white; font-weight:600; font-size:13px; display:inline-block; }
        .Scheduled { background:#198754; }
        .Completed { background:#1b68d1; }
        .InConsult { background:#d8a200; color:#000; }
        .Cancelled { background:#6c757d; }
        .actions a, .actions form { display:inline-block; margin-right:8px; }
        .btn { padding:8px 12px; border-radius:8px; text-decoration:none; background:#c8efe6; color:#063829; font-weight:600; }
        .small { font-size:13px; color:#444; }
        .message { margin-bottom:12px; color: #0b662c; font-weight:700; }
    </style>

    <script>
        function confirmCancel(id, realParamName, realParamValue) {
            if (confirm('Are you sure you want to cancel this appointment?')) {
                var url = 'appointments.jsp?action=cancel&id=' + encodeURIComponent(id);
                if (realParamName && realParamValue) {
                    url += '&' + encodeURIComponent(realParamName) + '=' + encodeURIComponent(realParamValue);
                }
                window.location = url;
            }
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="topbar">
            <div class="brand">
                <div style="font-size:20px;">HealthCare Clinic</div>
                <div class="small">Appointments for <strong><%= patientName %></strong></div>
            </div>
            <div>
                <a class="btn" href="patient_home.jsp">Dashboard</a>
                <a class="btn" href="book_appointment.jsp">Book New Appointment</a>
                <a class="btn" href="logout.jsp">Logout</a>
            </div>
        </div>

        <% if (message != null) { %>
            <div class="message"><%= message %></div>
        <% } %>

        <% if (adminError != null) { %>
            <div style="color:darkred; font-weight:bold; margin-bottom:12px;"><%= adminError %></div>
        <% } %>

        <div class="dash-card">
            <h3 style="margin-top:0;">Your Appointments</h3>

            <% if (appointments.isEmpty()) { %>
                <p>No appointments found. You can <a href="book_appointment.jsp">book an appointment</a>.</p>
            <% } else { %>

                <table>
                    <tr>
                        <th>Doctor</th>
                        <th>Scheduled At</th>
                        <th>Notes</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>

                    <% for (Map<String,String> a : appointments) {
                        String id = a.get("id");
                        String doctor = a.get("doctor");
                        String time = a.get("time");
                        String status = a.get("status");
                        String notes = a.get("notes");
                    %>
                        <tr>
                            <td><%= doctor %></td>
                            <td><%= time %></td>
                            <td class="small"><%= notes == null || notes.isEmpty() ? "-" : notes %></td>
                            <td>
                                <span class="status <%= status.replace(" ", "") %>"><%= status %></span>
                            </td>
                            <td class="actions">
                                <% if ("Scheduled".equalsIgnoreCase(status)) { %>
                                    <a href="javascript:void(0);" class="btn" onclick="confirmCancel('<%= id %>', '<%= discoveredIdCol %>', '<%= id %>')">Cancel</a>
                                <% } else { %>
                                    <span class="small">No actions</span>
                                <% } %>

                                <a class="btn" href="appointment_view.jsp?id=<%= id %>&<%= discoveredIdCol %>=<%= id %>">View</a>
                            </td>
                        </tr>
                    <% } %>

                </table>

            <% } %>
        </div>

    </div>
</body>
</html>
