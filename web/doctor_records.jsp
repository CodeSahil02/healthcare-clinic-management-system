<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>
<%
    // ---------- Access control ----------
    if (session.getAttribute("role") == null || !session.getAttribute("role").equals("doctor")) {
        response.sendRedirect("login.jsp");
        return;
    }
    String doctorName = (String) session.getAttribute("user");
    String doctorEmail = (String) session.getAttribute("email");

    // ---------- DB config ----------
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    String message = "";
    List<Map<String,String>> records = new ArrayList<>();

    // Handle actions: add (POST) and delete (GET with action=delete&id=...)
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
    } catch (Exception e) {
        message = "JDBC driver error: " + e.getMessage();
    }

    // Delete action (GET)
    String action = request.getParameter("action");
    String delId = request.getParameter("id");
    if ("delete".equalsIgnoreCase(action) && delId != null) {
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            // ensure the record belongs to this doctor
            String ownerCheck = "SELECT doctorName FROM patient_records WHERE recordId = ?";
            try (PreparedStatement pc = con.prepareStatement(ownerCheck)) {
                pc.setInt(1, Integer.parseInt(delId));
                try (ResultSet rc = pc.executeQuery()) {
                    if (rc.next()) {
                        String owner = rc.getString("doctorName");
                        if (owner != null && owner.equals(doctorName)) {
                            String delSql = "DELETE FROM patient_records WHERE recordId = ?";
                            try (PreparedStatement pd = con.prepareStatement(delSql)) {
                                pd.setInt(1, Integer.parseInt(delId));
                                int d = pd.executeUpdate();
                                message = (d > 0) ? "Record deleted." : "Could not delete record.";
                            }
                        } else {
                            message = "You are not authorized to delete that record.";
                        }
                    } else {
                        message = "Record not found.";
                    }
                }
            }
        } catch (Exception e) {
            message = "Error deleting record: " + e.getMessage();
        }
    }

    // Add record (POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String patientEmail = request.getParameter("patientEmail");
        String diagnosis = request.getParameter("diagnosis");
        String notes = request.getParameter("notes");

        if (patientEmail == null || patientEmail.trim().isEmpty()) {
            message = "Patient email is required.";
        } else {
            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
                String insert = "INSERT INTO patient_records (patientEmail, doctorName, diagnosis, notes, createdAt) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
                try (PreparedStatement pi = con.prepareStatement(insert)) {
                    pi.setString(1, patientEmail.trim());
                    pi.setString(2, doctorName);
                    pi.setString(3, diagnosis == null ? "" : diagnosis.trim());
                    pi.setString(4, notes == null ? "" : notes.trim());
                    int r = pi.executeUpdate();
                    message = (r > 0) ? "Record added successfully." : "Failed to add record.";
                }
            } catch (Exception e) {
                message = "Error adding record: " + e.getMessage();
            }
        }
    }

    // Load current doctor's records
    try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
        String q = "SELECT recordId, patientEmail, diagnosis, notes, createdAt FROM patient_records WHERE doctorName = ? ORDER BY createdAt DESC";
        try (PreparedStatement ps = con.prepareStatement(q)) {
            ps.setString(1, doctorName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,String> row = new HashMap<>();
                    row.put("recordId", rs.getString("recordId"));
                    row.put("patientEmail", rs.getString("patientEmail"));
                    row.put("diagnosis", rs.getString("diagnosis"));
                    row.put("notes", rs.getString("notes"));
                    row.put("createdAt", rs.getString("createdAt"));
                    records.add(row);
                }
            }
        }
    } catch (Exception e) {
        if (message.isEmpty()) message = "Error loading records: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Doctor — Patient Records</title>
    <meta name="viewport" content="width=device-width,initial-scale=1"/>
    <style>
        :root {
            --teal: #063829;
            --muted: #6b8b81;
            --accent: #198754;
            --card: #fff;
            --bg: #f3fbf8;
        }
        body { margin:0; font-family: Arial, sans-serif; background: linear-gradient(180deg,#eaf7f3,#fbfffe); color:var(--teal); -webkit-font-smoothing:antialiased; }
        .navbar { display:flex; justify-content:space-between; align-items:center; padding:14px 4%; background:#fff; box-shadow:0 2px 8px rgba(6,40,34,0.04); }
        .brand { font-weight:800; display:flex; gap:10px; align-items:center; }
        .brand-logo { width:36px;height:36px;border-radius:8px;background:var(--accent);color:#fff;display:grid;place-items:center;font-weight:900; }
        .container { max-width:1100px; margin:28px auto; padding:0 16px 60px; }
        .top { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; }
        .card { background:var(--card); padding:18px; border-radius:12px; box-shadow: 0 10px 30px rgba(3,40,34,0.06); }
        h2 { margin:0 0 8px 0; font-size:20px; }
        .muted { color:var(--muted); font-weight:700; }
        .notice { margin:12px 0; padding:10px; border-radius:8px; font-weight:800; color:#0b4b33; background:#e8f8ef; }
        form .row { display:flex; gap:12px; margin-bottom:12px; }
        form label { display:block; font-weight:800; margin-bottom:6px; }
        input[type="email"], textarea { width:100%; padding:10px; border-radius:8px; border:1px solid #dcefe8; font-size:14px; box-sizing:border-box; }
        textarea { min-height:120px; resize:vertical; }
        .btn { padding:12px 16px; background:var(--accent); color:#fff; border:none; border-radius:10px; font-weight:900; cursor:pointer; }
        .small-btn { padding:8px 10px; border-radius:8px; border:1px solid rgba(25,135,84,0.12); background:transparent; color:var(--accent); font-weight:800; cursor:pointer; }
        table { width:100%; border-collapse:collapse; margin-top:12px; font-size:0.95rem; }
        thead th { text-align:left; padding:10px 12px; background:#f9fffb; border-bottom:1px solid #eef7f2; color:var(--teal); font-weight:800; }
        tbody td { padding:12px; border-bottom:1px dashed #eef7f2; color:#123b30; vertical-align:top; }
        .actions a { margin-left:8px; color: #b23a3a; font-weight:800; text-decoration:none; }
        @media (max-width:720px) {
            .top { flex-direction:column; align-items:flex-start; gap:12px; }
            form .row { flex-direction:column; }
        }
    </style>
</head>
<body>

    <header class="navbar">
        <div class="brand"><div class="brand-logo">HC</div>HealthCare Clinic</div>
        <div style="font-weight:800; color:var(--muted);">Dr. <%= doctorName %></div>
    </header>

    <main class="container">

        <div class="top">
            <div>
                <h2>Patient Records — My Entries</h2>
                <div class="muted">Records added by you (most recent first)</div>
            </div>
            <div>
                <a href="doctor_dashboard.jsp" class="small-btn" style="text-decoration:none;">← Dashboard</a>
            </div>
        </div>

        <div class="card">
            <% if (message != null && !message.isEmpty()) { %>
                <div class="notice"><%= message %></div>
            <% } %>

            <!-- ADD RECORD FORM -->
            <form method="POST" style="margin-bottom:18px;">
                <div style="display:flex; gap:12px; align-items:flex-start; flex-wrap:wrap;">
                    <div style="flex:1; min-width:240px;">
                        <label for="patientEmail">Patient Email</label>
                        <input type="email" id="patientEmail" name="patientEmail" placeholder="patient@example.com" required />
                    </div>
                    <div style="width:220px;">
                        <label>Doctor</label>
                        <input type="text" value="<%= doctorName %>" readonly style="background:#f3faf7; padding:10px; border-radius:8px; border:1px solid #e6f3ec;"/>
                    </div>
                </div>

                <div style="margin-top:12px;">
                    <label for="diagnosis">Diagnosis</label>
                    <textarea id="diagnosis" name="diagnosis" placeholder="Diagnosis summary..."></textarea>
                </div>

                <div style="margin-top:12px;">
                    <label for="notes">Notes / Prescription / Follow-up</label>
                    <textarea id="notes" name="notes" placeholder="Notes for patient, prescriptions, next steps..."></textarea>
                </div>

                <div style="margin-top:12px;">
                    <button class="btn" type="submit">Add Record</button>
                </div>
            </form>

            <!-- RECORDS TABLE -->
            <div style="margin-top:10px;">
                <table>
                    <thead>
                        <tr>
                            <th>Patient Email</th>
                            <th>Diagnosis</th>
                            <th>Notes</th>
                            <th>Created At</th>
                            <th style="text-align:right;">Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (records.isEmpty()) { %>
                            <tr>
                                <td colspan="5" style="text-align:center; padding:18px; color:var(--muted); font-weight:800;">No records yet.</td>
                            </tr>
                        <% } else {
                            for (Map<String,String> r : records) {
                        %>
                            <tr>
                                <td><a href="patient_records_view.jsp?email=<%= java.net.URLEncoder.encode(r.get("patientEmail"), "UTF-8") %>"><%= r.get("patientEmail") %></a></td>
                                <td><%= r.get("diagnosis") == null ? "" : r.get("diagnosis").replaceAll("\n","<br/>") %></td>
                                <td><%= r.get("notes") == null ? "" : r.get("notes").replaceAll("\n","<br/>") %></td>
                                <td><%= r.get("createdAt") %></td>
                                <td style="text-align:right;" class="actions">
                                    <!-- Edit could be implemented, for now view and delete -->
                                    <a href="patient_records_view.jsp?email=<%= java.net.URLEncoder.encode(r.get("patientEmail"), "UTF-8") %>">View</a>
                                    <a href="doctor_records.jsp?action=delete&id=<%= r.get("recordId") %>" onclick="return confirm('Delete this record?');" style="color:#b23a3a;">Delete</a>
                                </td>
                            </tr>
                        <%  }
                        } %>
                    </tbody>
                </table>
            </div>
        </div>

    </main>

</body>
</html>
