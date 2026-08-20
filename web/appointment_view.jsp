<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    // SESSION + ROLE CHECK
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("patient")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String patientEmail = (String) session.getAttribute("email");
    String appointmentId = request.getParameter("id");

    String patientName = "";
    String doctorName = "";
    String scheduledAt = "";
    String status = "";

    String message = "";

    if (appointmentId != null && patientEmail != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true",
                "root",
                "10june2004"
            );

            // Patient can view ONLY their own appointment
            PreparedStatement ps = con.prepareStatement(
                "SELECT patientName, doctorName, scheduledAt, status " +
                "FROM appointments WHERE appointmentId=? AND patientEmail=?"
            );
            ps.setString(1, appointmentId);
            ps.setString(2, patientEmail);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                patientName = rs.getString("patientName");
                doctorName = rs.getString("doctorName");
                scheduledAt = rs.getString("scheduledAt");
                status = rs.getString("status");
            } else {
                message = "Appointment not found or access denied.";
            }

            rs.close();
            ps.close();
            con.close();

        } catch (Exception e) {
            message = e.getMessage();
        }
    } else {
        message = "Invalid request.";
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Appointment</title>

    <!-- OFFLINE CSS -->
    <style>
        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(180deg, #eef6ff, #ffffff);
            color: #1e293b;
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
            box-shadow: 0 10px 28px rgba(0,0,0,0.08);
        }

        h2 {
            margin-top: 0;
            margin-bottom: 20px;
            font-size: 1.4rem;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 10px;
        }

        .row {
            display: grid;
            grid-template-columns: 180px 1fr;
            gap: 14px;
            margin-bottom: 14px;
        }

        .label {
            font-weight: 700;
            color: #475569;
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

        .Scheduled { background: #ecfeff; color: #0369a1; }
        .InConsult { background: #fff7ed; color: #b45309; }
        .Completed { background: #ecfdf5; color: #047857; }
        .Cancelled { background: #fee2e2; color: #b91c1c; }

        .actions {
            margin-top: 30px;
        }

        .btn {
            padding: 10px 16px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 700;
            border: 1px solid #cbd5f5;
            color: #1d4ed8;
            background: #eff6ff;
            display: inline-block;
        }

        .error {
            background: #fee2e2;
            color: #7f1d1d;
            padding: 14px;
            border-radius: 10px;
            font-weight: 600;
        }

        @media (max-width: 600px) {
            .row {
                grid-template-columns: 1fr;
            }
            .label {
                margin-bottom: 4px;
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
        <h2>My Appointment Details</h2>

        <div class="row">
            <div class="label">Patient Name</div>
            <div class="value"><%= patientName %></div>
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
                <span class="badge <%= status.replaceAll("\\s+","") %>"><%= status %></span>
            </div>
        </div>

        <div class="actions">
            <a href="patient_home.jsp" class="btn">← Back to Dashboard</a>
        </div>
    </div>

    <% } %>

</div>
</body>
</html>
