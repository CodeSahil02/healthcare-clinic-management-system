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

    List<Map<String,String>> appointments = new ArrayList<>();
    int recordsCount = 0, reportsCount = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        PreparedStatement ps = con.prepareStatement(
    "SELECT doctorName, scheduledAt, status " +
    "FROM appointments " +
    "WHERE patientEmail=? AND status <> 'Completed' " +
    "ORDER BY scheduledAt LIMIT 5"
);

        ps.setString(1, patientEmail);
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String,String> row = new HashMap<>();
            row.put("doctor", rs.getString("doctorName"));
            row.put("time", rs.getString("scheduledAt"));
            row.put("status", rs.getString("status"));
            appointments.add(row);
        }

        // Medical record count
        PreparedStatement ps2 = con.prepareStatement("SELECT COUNT(*) FROM patient_records WHERE patientEmail=?");
        ps2.setString(1, patientEmail);
        ResultSet r2 = ps2.executeQuery();
        if (r2.next()) recordsCount = r2.getInt(1);

        con.close();

    } catch (Exception e) {
        out.println("Error loading data: " + e.getMessage());
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Patient Dashboard</title>
    <link rel="stylesheet" href="styles.css">

    <style>
        body {
            background: #e8f5f3;
            font-family: Arial;
        }

        /* MAIN DASHBOARD WRAPPER */
        .dashboard-layout {
            width: 90%;
            max-width: 1200px;
            margin: 20px auto;
            display: flex;
            gap: 20px;
        }

        /* LEFT BIG AREA */
        .left-side {
            flex: 2;
        }

        /* RIGHT SMALL SIDE */
        .right-side {
            flex: 1;
        }

        /* HERO STYLE */
        .welcome-box {
            background: #c8efe6;
            padding: 25px;
            border-radius: 12px;
            margin-bottom: 20px;
        }

        /* CARD */
        .dash-card {
            background: white;
            padding: 18px;
            border-radius: 12px;
            margin-bottom: 20px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
        }

        .section-title {
            font-size: 22px;
            color: #063829;
            margin-bottom: 10px;
            font-weight: bold;
            text-align: left;
        }

        /* APPOINTMENTS TABLE */
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 12px;
        }
        th, td {
            padding: 10px;
            border-bottom: 1px solid #ddd;
            font-size: 14px;
        }
        th {
            background: #f3fdfa;
            color: #063829;
            text-align: left;
        }

        .status {
            padding: 5px 10px;
            border-radius: 6px;
            font-size: 12px;
            color: white;
        }

        .Scheduled { background: #198754; }
        .Completed { background: #1b68d1; }
        .InConsult { background: #d8a200; }

        /* QUICK LINKS */
        .quick-links a {
            display: block;
            padding: 10px;
            background: #e8f5f3;
            border-radius: 8px;
            margin-bottom: 10px;
            color: #063829;
            text-decoration: none;
            font-weight: 600;
        }
        .quick-links a:hover {
            background: #c8efe6;
        }

        /* PROFILE CARD */
        .profile-card {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .profile-img {
            width: 70px;
            height: 70px;
            border-radius: 10px;
            background: #ddd;
        }
        

    </style>
</head>

<body>

<!-- NAVBAR -->
<div class="navbar">
    <div class="brand">
        <div class="brand-logo">HC</div>
        HealthCare Clinic
    </div>

    <div class="nav-links">
        <a href="index.jsp">Home</a>
        <a href="appointments.jsp">Appointments</a>
        <a href="logout.jsp" class="login-btn">Logout</a>
    </div>
</div>

<!-- DASHBOARD MAIN -->
<div class="dashboard-layout">

    <!-- LEFT SIDE -->
    <div class="left-side">

        <!-- WELCOME -->
        <div class="welcome-box">
            <h2>Welcome, <%= patientName %>!</h2>
            <p>Here's your health overview.</p>
        </div>

        <!-- UPCOMING APPOINTMENTS -->
        <div class="dash-card">
            <h2 class="section-title">Upcoming Appointments</h2>

            <% if (appointments.isEmpty()) { %>
                <p>No appointments scheduled. <a href="book_appointment.jsp">Book Now</a></p>
            <% } else { %>

            <table>
                <tr>
                    <th>Doctor</th>
                    <th>Time</th>
                    <th>Status</th>
                </tr>

                <% for (Map<String,String> a : appointments) { %>
                    <tr>
                        <td><%= a.get("doctor") %></td>
                        <td><%= a.get("time") %></td>
                        <td>
                            <span class="status <%= a.get("status").replace(" ", "") %>">
                                <%= a.get("status") %>
                            </span>
                        </td>
                    </tr>
                <% } %>

            </table>
            <% } %>
        </div>

        <!-- HEALTH STATS -->
        <div class="dash-card">
            <h2 class="section-title">Your Health Stats</h2>
            <p><strong>Medical Records:</strong> <%= recordsCount %></p>
        </div>
    </div>

    <!-- RIGHT SIDE -->
    <div class="right-side">

        <!-- PROFILE -->
        <div class="dash-card profile-card">
            <div>
                <h4>Name: <%= patientName %></h4>
                <p style="color:#063829;">Email: <%= patientEmail %></p>
            </div>
        </div>

        <!-- QUICK LINKS -->
        <div class="dash-card">
            <h2 class="section-title">Quick Links</h2>
            <div class="quick-links">
                <a href="book_appointment.jsp">Book Appointment</a>
                <a href="appointments.jsp">View Appointments</a>
                <a href="records.jsp">View Records</a>
            </div>
        </div>

    </div>

</div>

<footer>
    © 2025 HealthCare Clinic. All Rights Reserved.
</footer>

</body>
</html>
