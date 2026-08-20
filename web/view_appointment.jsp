<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    // ROLE CHECK
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("receptionist")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String appointmentId = request.getParameter("id");

    String patientName = "";
    String patientEmail = "";
    String doctorName = "";
    String scheduledAt = "";
    String status = "";

    String message = "";

    if (appointmentId != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true",
                "root",
                "10june2004"
            );

            PreparedStatement ps = con.prepareStatement(
                "SELECT patientName, patientEmail, doctorName, scheduledAt, status " +
                "FROM appointments WHERE appointmentId=?"
            );
            ps.setString(1, appointmentId);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                patientName = rs.getString("patientName");
                patientEmail = rs.getString("patientEmail");
                doctorName = rs.getString("doctorName");
                scheduledAt = rs.getString("scheduledAt");
                status = rs.getString("status");
            } else {
                message = "Appointment not found.";
            }

            rs.close();
            ps.close();
            con.close();

        } catch (Exception e) {
            message = e.getMessage();
        }
    } else {
        message = "Invalid appointment ID.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>View Appointment</title>

    <!-- OFFLINE CSS -->
    <style>
        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(180deg, #eafaf3, #ffffff);
            color: #08302a;
        }

        .container {
            max-width: 900px;
            margin: 40px auto;
            padding: 0 16px;
        }

        .card {
            background: #ffffff;
            border-radius: 14px;
            padding: 26px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
        }

        h2 {
            margin-top: 0;
            margin-bottom: 20px;
            font-size: 1.4rem;
            border-bottom: 1px solid #e6e9e8;
            padding-bottom: 10px;
        }

        .row {
            display: grid;
            grid-template-columns: 200px 1fr;
            gap: 14px;
            margin-bottom: 14px;
        }

        .label {
            font-weight: 700;
            color: #355f55;
        }

        .value {
            font-size: 1rem;
        }

        .badge {
            display: inline-block;
            padding: 6px 12px;
            border-radius: 999px;
            font-weight: 700;
            font-size: 0.9rem;
        }

        .Scheduled { background: #e7f7ef; color: #198754; }
        .InConsult { background: #fff1d6; color: #b38300; }
        .Completed { background: #e3f1ff; color: #0d6efd; }
        .Cancelled { background: #ffeef0; color: #d6336c; }

        .actions {
            margin-top: 30px;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
        }

        .btn {
            padding: 10px 16px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 700;
            border: 1px solid transparent;
            cursor: pointer;
            display: inline-block;
        }

        .btn-back {
            background: #f3f5f4;
            color: #08302a;
            border-color: #d9dedb;
        }

        .btn-edit {
            background: #198754;
            color: white;
        }

        .error {
            background: #ffeef0;
            color: #7a1a2a;
            padding: 14px;
            border-radius: 10px;
            font-weight: 600;
        }

        @media (max-width: 600px) {
            .row {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>

<body>
<div class="container">

    <% if (message != null && !message.isEmpty()) { %>
        <div class="error"><%= message %></div>
    <% } else { %>

    <div class="card">
        <h2>Appointment Details</h2>

        <div class="row">
            <div class="label">Patient Name</div>
            <div class="value"><%= patientName %></div>
        </div>

        <div class="row">
            <div class="label">Patient Email</div>
            <div class="value"><%= patientEmail %></div>
        </div>

        <div class="row">
            <div class="label">Doctor</div>
            <div class="value"><%= doctorName %></div>
        </div>

        <div class="row">
            <div class="label">Scheduled At</div>
            <div class="value"><%= scheduledAt %></div>
        </div>

        <div class="row">
            <div class="label">Status</div>
            <div class="value">
                <span class="badge <%= status.replaceAll("\\s+","") %>">
                    <%= status %>
                </span>
            </div>
        </div>

        <div class="actions">
            <a href="reception_dashboard.jsp" class="btn btn-back">← Back</a>
            <a href="edit_appointment.jsp?id=<%= appointmentId %>" class="btn btn-edit">Edit Appointment</a>
        </div>
    </div>

    <% } %>

</div>
</body>
</html>
