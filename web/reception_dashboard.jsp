<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>

<%
    // Session + role check
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("receptionist")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String receptionistName = (String) session.getAttribute("user");
    String receptionistEmail = (String) session.getAttribute("email");

    // DB connection
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> todayAppointments = new ArrayList<>();
    String message = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");

        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);
             PreparedStatement ps = con.prepareStatement(
                "SELECT appointmentId, patientName, doctorName, scheduledAt, status " +
                "FROM appointments ORDER BY scheduledAt ASC LIMIT 200"
             );
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String,String> row = new HashMap<>();
                row.put("id", rs.getString("appointmentId"));
                row.put("patient", rs.getString("patientName"));
                row.put("doctor", rs.getString("doctorName"));
                row.put("time", rs.getString("scheduledAt"));
                row.put("status", rs.getString("status"));
                todayAppointments.add(row);
            }
        }

    } catch (Exception e) {
        message = e.getMessage();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Receptionist Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <style>
        :root {
            --bg1:#eaf7f3;
            --bg2:#f9fffd;
            --accent:#198754;
            --teal:#063829;
            --muted:#5a7d75;
            --card:#ffffff;
            --shadow:rgba(3,40,34,0.08);
        }

        body {
            margin:0;
            font-family: system-ui, Arial, sans-serif;
            background: linear-gradient(180deg,var(--bg1),var(--bg2));
            color:var(--teal);
        }

        /* NAVBAR */
        .navbar {
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:14px 4%;
            background:#fff;
            box-shadow:0 2px 8px var(--shadow);
        }
        .brand {
            display:flex;
            align-items:center;
            gap:10px;
            font-weight:800;
            color:var(--teal);
        }
        .brand-logo {
            width:42px;height:42px;border-radius:50%;background:var(--accent);display:grid;place-items:center;color:#fff;font-weight:900;
        }
        .btn-outline-danger {
            background:#fff;
            color:#b23a3a;
            border:1px solid rgba(178,58,58,0.15);
            padding:8px 12px;
            border-radius:8px;
            font-weight:700;
            cursor:pointer;
        }

        /* CONTAINER */
        .container { max-width:1100px; margin:25px auto; padding:0 18px 60px;}

        /* PROFILE BOX */
        .profile-box {
            background:#fff;
            display:flex;
            align-items:center;
            gap:14px;
            padding:16px;
            border-radius:14px;
            box-shadow:0 6px 18px var(--shadow);
            margin-bottom:22px;
        }
        .profile-pic {
            width:64px;height:64px;border-radius:12px;background:#eef4f2;display:grid;place-items:center;color:var(--accent);font-weight:900;
        }

        /* GRID ACTIONS */
        .grid { display:grid; grid-template-columns:repeat(3,1fr); gap:18px; margin-bottom:25px; }
        .dash-card {
            background:#fff;
            padding:20px;
            border-radius:14px;
            box-shadow:0 10px 25px var(--shadow);
            text-align:center;
            transition:0.2s;
        }
        .dash-card:hover {
            transform: translateY(-6px);
            box-shadow:0 20px 40px rgba(0,0,0,0.12);
        }
        .btn {
            display:inline-block;
            margin-top:10px;
            background:var(--accent);
            color:#fff;
            padding:10px 14px;
            border-radius:10px;
            font-weight:800;
            text-decoration:none;
        }

        /* TABLE */
        .card {
            background:#fff;
            padding:18px;
            border-radius:14px;
            box-shadow:0 10px 25px var(--shadow);
        }
        table {
            width:100%;
            border-collapse:collapse;
        }
        thead th {
            background:linear-gradient(#f6fdf8,#fbfffe);
            padding:12px;
            border-bottom:1px solid #ecf6f1;
            font-weight:800;
            color:var(--teal);
        }
        tbody td {
            padding:12px;
            border-bottom:1px solid #f1f6f4;
            color:#11392f;
        }

        .status-badge {
            padding:7px 12px;
            border-radius:20px;
            font-weight:800;
        }
        .Scheduled { background:#e7f7ef; color:var(--accent); }
        .InConsult { background:#fff1d6; color:#b38300; }
        .Completed { background:#e3f1ff; color:#0d6efd; }

        .action-btn {
            padding:7px 12px;
            border-radius:10px;
            background:#e9fbf6;
            color:var(--teal);
            font-weight:800;
            text-decoration:none;
            border:1px solid rgba(6,56,41,0.07);
        }

        @media(max-width:900px){ .grid{grid-template-columns:1fr;} }
    </style>
</head>

<body>

<!-- NAVBAR -->
<nav class="navbar">
    <div class="brand">
        <div class="brand-logo">HC</div>
        <div>
            <div>HealthCare Clinic</div>
            <small style="color:var(--muted);font-weight:700;">Receptionist Dashboard</small>
        </div>
    </div>

    <form action="logout.jsp" method="post">
        <button class="btn-outline-danger">Logout</button>
    </form>
</nav>

<div class="container">

    <!-- PROFILE -->
    <div class="profile-box">
        <div class="profile-pic">R</div>
        <div>
            <div style="font-weight:800;font-size:1.1rem;"><%= receptionistName %></div>
            <div style="color:var(--muted);font-weight:700;"><%= receptionistEmail %></div>
        </div>
    </div>

    <!-- QUICK ACTIONS -->
    <div class="grid">
        <div class="dash-card">
            <h5>Book Appointment</h5>
            <p>Book appointments for patients.</p>
            <a class="btn" href="reception_book.jsp">Open</a>
        </div>

        <div class="dash-card">
            <h5>Patient List</h5>
            <p>View all registered patients.</p>
            <a class="btn" href="view_patients.jsp">Open</a>
        </div>

        <div class="dash-card">
            <h5>Appointments</h5>
            <p>Manage appointments.</p>
            <a class="btn" href="manage_appointments.jsp">Open</a>
        </div>
    </div>

    <!-- APPOINTMENTS TABLE -->
    <div class="card">
        <h3>Appointments</h3>

        <% if (!message.equals("")) { %>
            <div style="padding:10px;background:#fff3cd;border-radius:8px;font-weight:800;color:#7a5b00;margin-bottom:12px;">
                <%= message %>
            </div>
        <% } %>

        <table>
            <thead>
                <tr>
                    <th>Patient</th>
                    <th>Doctor</th>
                    <th>Scheduled At</th>
                    <th>Status</th>
                    <th style="text-align:right;">Action</th>
                </tr>
            </thead>
            <tbody>
                <% if (todayAppointments.isEmpty()) { %>
                    <tr>
                        <td colspan="5" style="text-align:center;padding:20px;color:var(--muted);font-weight:800;">
                            No appointments available.
                        </td>
                    </tr>
                <% } else {
                    for (Map<String,String> a : todayAppointments) {
                        String status = a.get("status");
                        String badge = status.replaceAll("\\s+","");
                %>
                <tr>
                    <td><%= a.get("patient") %></td>
                    <td><%= a.get("doctor") %></td>
                    <td><%= a.get("time") %></td>
                    <td><span class="status-badge <%= badge %>"><%= status %></span></td>
                    <td style="text-align:right;">
                        <a class="action-btn" href="view_appointment.jsp?id=<%= a.get("id") %>">View</a>
                    </td>
                </tr>
                <% }} %>
            </tbody>
        </table>

    </div>

</div>

</body>
</html>
