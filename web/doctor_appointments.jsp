<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    /* ---------- ACCESS CONTROL ---------- */
    if (!"doctor".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String doctorName  = (String) session.getAttribute("user");
    String doctorEmail = (String) session.getAttribute("email");

    /* ---------- DB CONFIG ---------- */
    String dbUrl  = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    String message = "";
    String error   = "";

    int doctorId = -1;

    /* ---------- FETCH DOCTOR ID (CRITICAL) ---------- */
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            PreparedStatement ps = con.prepareStatement(
                "SELECT doctorId FROM doctors d " +
                "JOIN users u ON d.userId = u.id " +
                "WHERE u.email = ?"
            );
            ps.setString(1, doctorEmail);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                doctorId = rs.getInt("doctorId");
            } else {
                error = "Doctor profile not linked. Contact admin.";
            }
        }
    } catch (Exception e) {
        error = "Error loading doctor profile: " + e.getMessage();
    }

    /* ---------- HANDLE STATUS UPDATE ---------- */
    if (doctorId != -1 && "POST".equalsIgnoreCase(request.getMethod())) {

        String apptIdStr = request.getParameter("appointmentId");
        String action    = request.getParameter("action");

        try {
            int apptId = Integer.parseInt(apptIdStr);

            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

                /* VERIFY OWNERSHIP USING doctorId */
                PreparedStatement chk = con.prepareStatement(
                    "SELECT doctorId FROM appointments WHERE appointmentId=?"
                );
                chk.setInt(1, apptId);
                ResultSet rchk = chk.executeQuery();

                if (!rchk.next() || rchk.getInt("doctorId") != doctorId) {
                    error = "You are not authorized to modify this appointment.";
                } else {

                    String newStatus = null;
                    if ("inconsult".equalsIgnoreCase(action)) newStatus = "InConsult";
                    else if ("complete".equalsIgnoreCase(action)) newStatus = "Completed";
                    else if ("cancel".equalsIgnoreCase(action)) newStatus = "Cancelled";

                    if (newStatus == null) {
                        error = "Invalid action.";
                    } else {
                        PreparedStatement up = con.prepareStatement(
                            "UPDATE appointments SET status=? WHERE appointmentId=?"
                        );
                        up.setString(1, newStatus);
                        up.setInt(2, apptId);
                        up.executeUpdate();
                        message = "Appointment updated successfully.";
                    }
                }
            }
        } catch (Exception ex) {
            error = "Update failed: " + ex.getMessage();
        }
    }

    /* ---------- FETCH APPOINTMENTS ---------- */
    List<Map<String,String>> appts = new ArrayList<>();
    String dateFilter = request.getParameter("date");

    if (doctorId != -1) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

                String sql =
                    "SELECT appointmentId, patientName, patientEmail, scheduledAt, status " +
                    "FROM appointments WHERE doctorId=? ";

                if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                    sql += "AND DATE(scheduledAt)=? ";
                }
                sql += "ORDER BY scheduledAt ASC";

                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, doctorId);
                if (dateFilter != null && !dateFilter.trim().isEmpty()) {
                    ps.setString(2, dateFilter.trim());
                }

                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String,String> row = new HashMap<>();
                    row.put("id", rs.getString("appointmentId"));
                    row.put("patient", rs.getString("patientName"));
                    row.put("email", rs.getString("patientEmail"));
                    row.put("time", rs.getString("scheduledAt"));
                    row.put("status", rs.getString("status"));
                    appts.add(row);
                }
            }
        } catch (Exception ex) {
            error = "Error loading appointments: " + ex.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>My Appointments</title>
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <style>
        :root {
            --teal: #063829;
            --muted: #6b8b81;
            --accent: #198754;
            --danger: #b23a3a;
            --card: #fff;
            --bg: #f3fbf8;
        }
        * { box-sizing: border-box; }
        body { margin:0; font-family: Arial, sans-serif; background: linear-gradient(180deg,#eaf7f3,#fbfffe); color:var(--teal); -webkit-font-smoothing:antialiased; }
        .navbar { display:flex; justify-content:space-between; align-items:center; padding:14px 4%; background:#fff; box-shadow:0 2px 8px rgba(6,40,34,0.04); }
        .brand { font-weight:800; display:flex; gap:10px; align-items:center; }
        .brand-logo { width:36px;height:36px;border-radius:8px;background:var(--accent);color:#fff;display:grid;place-items:center;font-weight:900; }
        .container { max-width:1100px; margin:28px auto; padding:0 16px 60px; }
        .top { display:flex; justify-content:space-between; align-items:center; gap:12px; margin-bottom:18px; }
        h2 { margin:0; font-size:20px; }
        .muted { color:var(--muted); font-weight:700; }
        .card { background:var(--card); padding:18px; border-radius:12px; box-shadow: 0 10px 30px rgba(3,40,34,0.06); }
        .notice { margin:12px 0; padding:10px; border-radius:8px; font-weight:800; color:#0b4b33; background:#e8f8ef; }
        .error { margin:12px 0; padding:10px; border-radius:8px; font-weight:800; color:#6b1212; background:#fdecec; }
        .filters { display:flex; gap:12px; align-items:center; margin-bottom:12px; flex-wrap:wrap; }
        input[type="date"] { padding:10px; border-radius:8px; border:1px solid #dcefe8; }
        .btn { padding:10px 14px; background:var(--accent); color:#fff; border:none; border-radius:8px; font-weight:800; cursor:pointer; }
        .btn-ghost { padding:8px 12px; border-radius:8px; border:1px solid rgba(3,40,34,0.06); background:transparent; cursor:pointer; }
        table { width:100%; border-collapse:collapse; margin-top:8px; font-size:0.95rem; }
        thead th { text-align:left; padding:10px 12px; background:#f8fffb; border-bottom:1px solid #eef7f2; color:var(--teal); font-weight:800; }
        tbody td { padding:12px; border-bottom:1px dashed #eef7f2; color:#123b30; vertical-align:middle; }
        .status-badge { padding:6px 10px; border-radius:999px; font-weight:800; font-size:0.85rem; }
        .Scheduled { background:#e7f7ef; color:var(--accent); }
        .InConsult { background:#fff1d6; color:#b38300; }
        .Completed { background:#e3f1ff; color:#0d6efd; }
        .Cancelled { background:#f2e9ea; color:#a1201f; }
        .actions form { display:inline-block; margin:0 6px; }
        .actions button { padding:8px 10px; border-radius:8px; border:none; font-weight:800; cursor:pointer; }
        .btn-start { background:#f0b429; color:#4a2f00; } /* InConsult */
        .btn-complete { background:#0d6efd; color:#fff; }
        .btn-cancel { background:#b23a3a; color:#fff; }

        @media (max-width:720px) {
            .top { flex-direction:column; align-items:flex-start; }
            thead th, tbody td { padding:10px; font-size:0.92rem; }
            .actions form { display:block; margin-bottom:8px; }
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
                <h2>My Appointments</h2>
                <div class="muted">Manage your schedule</div>
            </div>
            <div>
                <a href="doctor_dashboard.jsp" class="btn-ghost" style="text-decoration:none;">← Dashboard</a>
            </div>
        </div>

        <div class="card">

            <% if (message != null && !message.isEmpty()) { %>
                <div class="notice"><%= message %></div>
            <% } %>
            <% if (error != null && !error.isEmpty()) { %>
                <div class="error"><%= error %></div>
            <% } %>

            <div class="filters">
                <form method="GET" style="display:flex; gap:8px; align-items:center; margin:0;">
                    <label class="muted" style="font-weight:800;">Date:</label>
                    <input type="date" name="date" value="<%= (dateFilter==null ? "" : dateFilter) %>" />
                    <button class="btn" type="submit">Filter</button>
                </form>

                <form method="GET" action="doctor_appointments.jsp" style="margin:0;">
                    <button class="btn-ghost" type="submit">Clear</button>
                </form>
            </div>

            <table>
                <thead>
                    <tr>
                        <th>Patient</th>
                        <th>Contact</th>
                        <th>Scheduled At</th>
                        <th>Status</th>
                        <th style="text-align:right;">Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (appts.isEmpty()) { %>
                        <tr>
                            <td colspan="5" style="text-align:center; padding:18px; color:var(--muted); font-weight:800;">No appointments found.</td>
                        </tr>
                    <% } else {
                        for (Map<String,String> a : appts) {
                            String status = a.get("status") == null ? "Scheduled" : a.get("status");
                    %>
                    <tr>
                        <td><strong><%= a.get("patient") %></strong></td>
                        <td><%= a.get("email") %></td>
                        <td><%= a.get("time") %></td>
                        <td><span class="status-badge <%= status.replace(" ", "") %>"><%= status %></span></td>
                        <td style="text-align:right;" class="actions">
                            <!-- Start consult -->
                            <% if (!"InConsult".equalsIgnoreCase(status)) { %>
                                <form method="POST" onsubmit="return confirm('Start consult for this patient?');" style="display:inline-block;">
                                    <input type="hidden" name="appointmentId" value="<%= a.get("id") %>" />
                                    <input type="hidden" name="action" value="inconsult" />
                                    <button type="submit" class="btn-start">Start</button>
                                </form>
                            <% } %>

                            <!-- Mark complete -->
                            <% if (!"Completed".equalsIgnoreCase(status)) { %>
                                <form method="POST" onsubmit="return confirm('Mark appointment as completed?');" style="display:inline-block;">
                                    <input type="hidden" name="appointmentId" value="<%= a.get("id") %>" />
                                    <input type="hidden" name="action" value="complete" />
                                    <button type="submit" class="btn-complete">Complete</button>
                                </form>
                            <% } %>

                            <!-- Cancel -->
                            <% if (!"Cancelled".equalsIgnoreCase(status) && !"Completed".equalsIgnoreCase(status)) { %>
                                <form method="POST" onsubmit="return confirm('Cancel this appointment?');" style="display:inline-block;">
                                    <input type="hidden" name="appointmentId" value="<%= a.get("id") %>" />
                                    <input type="hidden" name="action" value="cancel" />
                                    <button type="submit" class="btn-cancel">Cancel</button>
                                </form>
                            <% } %>

                            <!-- Open consult page -->
                            <a href="consult.jsp?id=<%= a.get("id") %>" style="margin-left:8px; font-weight:800; color:var(--muted);">Open</a>
                        </td>
                    </tr>
                    <%  } } %>
                </tbody>
            </table>

        </div>
    </main>

    <script>
        // nothing complicated required client-side; just keep small helpers if needed
    </script>
</body>
</html>
