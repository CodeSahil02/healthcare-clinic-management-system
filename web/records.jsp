<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    // Ensure patient is logged in
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("patient")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String patientEmail = (String) session.getAttribute("email");
    String patientName = (String) session.getAttribute("user");

    // DB connection
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> records = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        PreparedStatement ps = con.prepareStatement(
            "SELECT doctorName, diagnosis, notes, createdAt FROM patient_records WHERE patientEmail=? ORDER BY createdAt DESC"
        );
        ps.setString(1, patientEmail);
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String,String> row = new HashMap<>();
            row.put("doctor", rs.getString("doctorName"));
            row.put("diagnosis", rs.getString("diagnosis"));
            row.put("notes", rs.getString("notes"));
            row.put("createdAt", rs.getString("createdAt"));
            records.add(row);
        }

        con.close();
    } catch (Exception e) {
        out.println("<p style='color:red'>Error loading records: " + e.getMessage() + "</p>");
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>My Medical Records</title>
    <link rel="stylesheet" href="styles.css">

    <style>
        body {
            background: #e8f5f3;
            font-family: Arial, sans-serif;
        }

        .page-title {
            text-align: center;
            margin-top: 30px;
            font-size: 28px;
            color: #063829;
            font-weight: bold;
        }

        .records-container {
            width: 90%;
            max-width: 900px;
            margin: 30px auto;
        }

        .record-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }

        .record-card h3 {
            margin-bottom: 10px;
            color: #063829;
        }

        .label {
            font-weight: bold;
            color: #063829;
        }

        .back-btn {
            display: inline-block;
            margin: 20px auto;
            padding: 10px 18px;
            background: #198754;
            color: white;
            border-radius: 6px;
            text-decoration: none;
        }
        .back-btn:hover {
            background: #146c43;
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
        <a href="patient_home.jsp">Home</a>
        <a href="appointments.jsp">Appointments</a>
        <a href="logout.jsp" class="login-btn">Logout</a>
    </div>
</div>

<h1 class="page-title">Your Medical Records</h1>

<div class="records-container">

    <% if (records.isEmpty()) { %>

        <div class="record-card">
            <p>No medical records found.</p>
        </div>

    <% } else { 
        for (Map<String,String> r : records) { %>

        <div class="record-card">
            <h3><%= r.get("doctor") %></h3>

            <p><span class="label">Diagnosis:</span> <%= r.get("diagnosis") %></p>
            <p><span class="label">Notes:</span> <%= r.get("notes") %></p>
            <p><span class="label">Date:</span> <%= r.get("createdAt") %></p>
        </div>

    <% }} %>

    <div style="text-align:center;">
        <a class="back-btn" href="patient_home.jsp">Back to Dashboard</a>
    </div>

</div>

<footer>
    © 2025 HealthCare Clinic. All Rights Reserved.
</footer>

</body>
</html>
