<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    // ROLE CHECK
    String role = (String) session.getAttribute("role");
    if (role == null || !(role.equals("receptionist") || role.equals("admin"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    String search = request.getParameter("q");
    String statusFilter = request.getParameter("status");

    List<Map<String,String>> appointments = new ArrayList<>();
    String message = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        String sql =
            "SELECT appointmentId, patientName, patientEmail, doctorName, scheduledAt, status " +
            "FROM appointments WHERE 1=1 ";

        if (search != null && !search.trim().isEmpty()) {
            sql += "AND (patientName LIKE ? OR patientEmail LIKE ? OR doctorName LIKE ?) ";
        }

        if (statusFilter != null && !statusFilter.equals("all")) {
            sql += "AND status = ? ";
        }

        sql += "ORDER BY scheduledAt DESC LIMIT 500";

        PreparedStatement ps = con.prepareStatement(sql);

        int idx = 1;
        if (search != null && !search.trim().isEmpty()) {
            String like = "%" + search.trim() + "%";
            ps.setString(idx++, like);
            ps.setString(idx++, like);
            ps.setString(idx++, like);
        }
        if (statusFilter != null && !statusFilter.equals("all")) {
            ps.setString(idx++, statusFilter);
        }

        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,String> r = new HashMap<>();
            r.put("id", rs.getString("appointmentId"));
            r.put("patient", rs.getString("patientName"));
            r.put("email", rs.getString("patientEmail"));
            r.put("doctor", rs.getString("doctorName"));
            r.put("time", rs.getString("scheduledAt"));
            r.put("status", rs.getString("status"));
            appointments.add(r);
        }

        rs.close();
        ps.close();
        con.close();

    } catch (Exception e) {
        message = "Error loading appointments: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Appointments</title>

    <!-- OFFLINE CSS -->
    <style>
        body{
            margin:0;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(180deg,#eefaf6,#ffffff);
            color:#063829;
        }
        .container{
            max-width:1200px;
            margin:30px auto;
            padding:0 18px 60px;
        }
        .header{
            display:flex;
            justify-content:space-between;
            align-items:center;
            margin-bottom:18px;
        }
        h2{margin:0;}
        .btn{
            padding:8px 14px;
            border-radius:8px;
            font-weight:700;
            text-decoration:none;
            border:1px solid transparent;
            cursor:pointer;
        }
        .btn-back{
            background:#f3f5f4;
            color:#063829;
            border-color:#d9dedb;
        }
        .btn-primary{
            background:#198754;
            color:white;
        }

        .card{
            background:white;
            padding:18px;
            border-radius:12px;
            box-shadow:0 8px 24px rgba(0,0,0,0.06);
        }

        .filters{
            display:flex;
            gap:12px;
            flex-wrap:wrap;
            margin-bottom:12px;
        }
        input, select{
            padding:8px 10px;
            border-radius:8px;
            border:1px solid #dfeee8;
        }

        table{
            width:100%;
            border-collapse:collapse;
            margin-top:12px;
            font-size:14px;
        }
        th, td{
            padding:12px;
            border-bottom:1px solid #edf3f0;
            text-align:left;
        }
        th{
            background:#f7fffb;
            font-weight:800;
        }

        .badge{
            padding:5px 10px;
            border-radius:999px;
            font-size:12px;
            font-weight:700;
        }
        .Scheduled{background:#e7f7ef;color:#198754;}
        .InConsult{background:#fff1d6;color:#b38300;}
        .Completed{background:#e3f1ff;color:#0d6efd;}
        .Cancelled{background:#ffeef0;color:#d6336c;}

        .actions a{
            margin-right:8px;
            font-weight:700;
            text-decoration:none;
            color:#198754;
        }

        .empty{
            text-align:center;
            padding:20px;
            color:#6b8b81;
            font-weight:700;
        }
    </style>
</head>

<body>
<div class="container">

    <div class="header">
        <h2>Manage Appointments</h2>
        <a href="reception_dashboard.jsp" class="btn btn-back">← Back</a>
    </div>

    <div class="card">

        <% if (!message.isEmpty()) { %>
            <div style="background:#ffeef0;color:#7a1a2a;padding:10px;border-radius:8px;margin-bottom:12px;">
                <%= message %>
            </div>
        <% } %>

        <!-- FILTERS -->
        <form method="GET" class="filters">
            <input type="search" name="q" placeholder="Search patient / doctor / email"
                   value="<%= search == null ? "" : search %>">

            <select name="status">
                <option value="all">All Status</option>
                <option value="Scheduled" <%= "Scheduled".equals(statusFilter)?"selected":"" %>>Scheduled</option>
                <option value="InConsult" <%= "InConsult".equals(statusFilter)?"selected":"" %>>InConsult</option>
                <option value="Completed" <%= "Completed".equals(statusFilter)?"selected":"" %>>Completed</option>
                <option value="Cancelled" <%= "Cancelled".equals(statusFilter)?"selected":"" %>>Cancelled</option>
            </select>

            <button class="btn btn-primary" type="submit">Filter</button>
            <a href="manage_appointments.jsp" class="btn btn-back">Clear</a>

            <div style="margin-left:auto;font-weight:700;color:#6b8b81;">
                Total: <%= appointments.size() %>
            </div>
        </form>

        <!-- TABLE -->
        <div style="overflow:auto;">
            <table>
                <thead>
                    <tr>
                        <th>Patient</th>
                        <th>Email</th>
                        <th>Doctor</th>
                        <th>Date & Time</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <% if (appointments.isEmpty()) { %>
                    <tr>
                        <td colspan="6" class="empty">No appointments found.</td>
                    </tr>
                <% } else {
                    for (Map<String,String> a : appointments) {
                %>
                    <tr>
                        <td><%= a.get("patient") %></td>
                        <td><%= a.get("email") %></td>
                        <td><%= a.get("doctor") %></td>
                        <td><%= a.get("time") %></td>
                        <td>
                            <span class="badge <%= a.get("status").replaceAll("\\s+","") %>">
                                <%= a.get("status") %>
                            </span>
                        </td>
                        <td class="actions">
                            <a href="view_appointment.jsp?id=<%= a.get("id") %>">View</a>
                            <a href="edit_appointment.jsp?id=<%= a.get("id") %>">Edit</a>
                        </td>
                    </tr>
                <% } } %>
                </tbody>
            </table>
        </div>

    </div>
</div>
</body>
</html>
