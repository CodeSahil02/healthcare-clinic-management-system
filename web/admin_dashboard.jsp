<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    if (session.getAttribute("role") == null || !session.getAttribute("role").equals("admin")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String adminName = (String) session.getAttribute("user");
%>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <meta charset="UTF-8">

    <style>
        body {
            margin: 0;
            background: linear-gradient(180deg, #dff8ef 0%, #f7fffc 100%);
            font-family: Arial, Helvetica, sans-serif;
            color: #063829;
        }

        /* NAVBAR */
        .navbar {
            background: white;
            padding: 16px 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 4px 14px rgba(0,0,0,0.08);
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 12px;
            font-size: 1.1rem;
            font-weight: 800;
        }

        .brand-logo {
            width: 42px;
            height: 42px;
            border-radius: 12px;
            background: #198754;
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 900;
        }

        .btn-logout {
            padding: 8px 14px;
            border-radius: 8px;
            background: transparent;
            border: 1px solid #f1b3b8;
            color: #b02a37;
            font-weight: 700;
            text-decoration: none;
        }

        /* LAYOUT */
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px 60px;
        }

        /* PROFILE BOX */
        .profile-box {
            background: white;
            padding: 16px 20px;
            border-radius: 14px;
            margin-bottom: 26px;
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 6px 18px rgba(0,0,0,0.08);
        }

        .profile-pic {
            width: 55px;
            height: 55px;
            border-radius: 12px;
            background: #c8efe6;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 900;
        }

        /* DASHBOARD GRID */
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 20px;
        }

        .dash-card {
            background: white;
            padding: 26px;
            border-radius: 14px;
            text-align: center;
            box-shadow: 0 10px 25px rgba(0,0,0,0.08);
            transition: 0.3s ease;
        }

        .dash-card:hover {
            transform: translateY(-6px);
            box-shadow: 0 18px 35px rgba(0,0,0,0.12);
        }

        .icon-box {
            width: 58px;
            height: 58px;
            border-radius: 14px;
            background: #e8f5f3;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 26px;
            font-weight: 900;
            color: #198754;
            margin: 0 auto 14px;
        }

        .dash-card h4 {
            margin: 8px 0 6px;
        }

        .dash-card p {
            color: #5c7a75;
            font-size: 0.95rem;
        }

        .btn-open {
            display: inline-block;
            margin-top: 12px;
            padding: 8px 16px;
            border-radius: 8px;
            background: #198754;
            color: white;
            text-decoration: none;
            font-weight: 700;
        }
    </style>
</head>

<body>

<!-- NAVBAR -->
<div class="navbar">
    <div class="brand">
        <div class="brand-logo">HC</div>
        HealthCare Clinic – Admin Panel
    </div>

    <a href="logout.jsp" class="btn-logout">Logout</a>
</div>

<div class="container">

    <!-- PROFILE -->
    <div class="profile-box">
        <div class="profile-pic">A</div>
        <div>
            <div style="font-weight:800;">Welcome, Admin</div>
            <div style="color:#5c7a75;"><%= adminName %></div>
        </div>
    </div>

    <!-- DASHBOARD CARDS -->
    <div class="grid">

        <div class="dash-card">
            <div class="icon-box">🩺</div>
            <h4>Manage Doctors</h4>
            <p>Add, remove, or update doctor details.</p>
            <a href="manage_doctors.jsp" class="btn-open">Open</a>
        </div>

        <div class="dash-card">
            <div class="icon-box">👥</div>
            <h4>View Patients</h4>
            <p>View registered patient details.</p>
            <a href="view_patients.jsp" class="btn-open">Open</a>
        </div>

        <div class="dash-card">
            <div class="icon-box">⚙️</div>
            <h4>Manage Users</h4>
            <p>View, enable or disable system users.</p>
            <a href="manage_users.jsp" class="btn-open">Open</a>
        </div>

    </div>
</div>

</body>
</html>
