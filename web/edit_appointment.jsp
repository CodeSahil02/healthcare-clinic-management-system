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
    String doctorName = "";
    String scheduledAt = "";
    String status = "";

    String message = "";
    String success = "";

    if (appointmentId == null) {
        message = "Invalid appointment ID.";
    }

    // DB CONFIG
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    // HANDLE UPDATE
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String newDateTime = request.getParameter("scheduledAt");
        String newStatus = request.getParameter("status");

        if (newDateTime != null && newStatus != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

                PreparedStatement ps = con.prepareStatement(
                    "UPDATE appointments SET scheduledAt=?, status=? WHERE appointmentId=?"
                );
                ps.setString(1, newDateTime);
                ps.setString(2, newStatus);
                ps.setString(3, appointmentId);

                int updated = ps.executeUpdate();
                if (updated > 0) {
                    success = "Appointment updated successfully.";
                } else {
                    message = "Update failed.";
                }

                ps.close();
                con.close();

            } catch (Exception e) {
                message = e.getMessage();
            }
        }
    }

    // LOAD APPOINTMENT DATA
    if (appointmentId != null) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

            PreparedStatement ps = con.prepareStatement(
                "SELECT patientName, doctorName, scheduledAt, status FROM appointments WHERE appointmentId=?"
            );
            ps.setString(1, appointmentId);

            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                patientName = rs.getString("patientName");
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
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Appointment</title>

    <!-- OFFLINE CSS -->
    <style>
        body {
            margin: 0;
            font-family: Arial, Helvetica, sans-serif;
            background: linear-gradient(180deg, #eafaf3, #ffffff);
            color: #08302a;
        }

        .container {
            max-width: 800px;
            margin: 40px auto;
            padding: 0 16px;
        }

        .card {
            background: white;
            padding: 26px;
            border-radius: 14px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.08);
        }

        h2 {
            margin-top: 0;
            border-bottom: 1px solid #e6e9e8;
            padding-bottom: 10px;
        }

        .row {
            margin-bottom: 16px;
        }

        .label {
            font-weight: 700;
            margin-bottom: 6px;
            display: block;
        }

        input, select {
            width: 100%;
            padding: 10px;
            border-radius: 8px;
            border: 1px solid #d9dedb;
            font-size: 14px;
        }

        .readonly {
            background: #f3f5f4;
        }

        .actions {
            margin-top: 24px;
            display: flex;
            gap: 12px;
        }

        .btn {
            padding: 10px 16px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 700;
            border: 1px solid transparent;
            cursor: pointer;
        }

        .btn-save {
            background: #198754;
            color: white;
        }

        .btn-back {
            background: #f3f5f4;
            color: #08302a;
            border-color: #d9dedb;
        }

        .success {
            background: #e7f7ef;
            color: #0f5132;
            padding: 12px;
            border-radius: 10px;
            margin-bottom: 16px;
            font-weight: 600;
        }

        .error {
            background: #ffeef0;
            color: #7a1a2a;
            padding: 12px;
            border-radius: 10px;
            margin-bottom: 16px;
            font-weight: 600;
        }
    </style>
</head>

<body>
<div class="container">

    <% if (!success.isEmpty()) { %>
        <div class="success"><%= success %></div>
    <% } %>

    <% if (!message.isEmpty()) { %>
        <div class="error"><%= message %></div>
    <% } %>

    <div class="card">
        <h2>Edit Appointment</h2>

        <form method="post">

            <div class="row">
                <label class="label">Patient Name</label>
                <input type="text" value="<%= patientName %>" readonly class="readonly">
            </div>

            <div class="row">
                <label class="label">Doctor</label>
                <input type="text" value="<%= doctorName %>" readonly class="readonly">
            </div>

            <div class="row">
                <label class="label">Date & Time</label>
                <input type="datetime-local" name="scheduledAt"
                       value="<%= scheduledAt != null ? scheduledAt.replace(" ", "T") : "" %>"
                       required>
            </div>

            <div class="row">
                <label class="label">Status</label>
                <select name="status" required>
                    <option value="Scheduled" <%= "Scheduled".equals(status) ? "selected" : "" %>>Scheduled</option>
                    <option value="Cancelled" <%= "Cancelled".equals(status) ? "selected" : "" %>>Cancelled</option>
                </select>
            </div>

            <div class="actions">
                <a href="view_appointment.jsp?id=<%= appointmentId %>" class="btn btn-back">← Back</a>
                <button type="submit" class="btn btn-save">Save Changes</button>
            </div>

        </form>
    </div>

</div>
</body>
</html>
