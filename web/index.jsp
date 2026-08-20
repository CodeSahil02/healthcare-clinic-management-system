<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    boolean loggedIn = (session.getAttribute("user") != null);
    String userName = (String) session.getAttribute("user");
%>

<!DOCTYPE html>
<html>
<head>
    <title>HealthCare Clinic - Home</title>
    <link rel="stylesheet" href="styles.css">

    <script>
        function loginRequired() {
            alert("Please login first to continue.");
        }
    </script>

    <style>
        .card .btn {
            display: inline-block;
            margin-top: 10px;
            padding: 10px 16px;
            background: #198754;
            color: white;
            border-radius: 6px;
            text-decoration: none;
            font-size: 14px;
            font-weight: bold;
            transition: 0.2s;
        }
        .card .btn:hover {
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
        <a href="index.jsp">Home</a>
        <a href="services.jsp">Services</a>
        <a href="about.jsp">About</a>
        <a href="contact.jsp">Contact</a>

        <% if (!loggedIn) { %>
            <a href="login.jsp" class="login-btn">Login</a>
        <% } else { %>
            <a href="appointments.jsp">My Appointments</a>
            <a href="logout.jsp" class="login-btn">Logout</a>
        <% } %>
    </div>
</div>

<!-- HERO SECTION -->
<div class="hero">
    <h1>Welcome <%= (loggedIn ? userName : "") %> to HealthCare Clinic</h1>
    <p>Your trusted place for appointments and quality medical care.</p>

    <% if (!loggedIn) { %>
        <a class="btn" href="javascript:loginRequired()">Book Appointment</a>
    <% } else { %>
        <a class="btn" href="book_appointment.jsp">Book Appointment</a>
    <% } %>
</div>

<!-- SERVICES SECTION -->
<h2 class="section-title">Our Services</h2>
<div class="container services">
    
    <!-- Card 1 -->
    <div class="card">
        <img src="icons/appointments.png">
        <h3>Online Appointments</h3>
        <p>Easily book consultations with our specialists.</p>

        <% if (!loggedIn) { %>
            <a class="btn" href="javascript:loginRequired()">Book Now</a>
        <% } else { %>
            <a class="btn" href="book_appointment.jsp">Book Now</a>
        <% } %>
    </div>

    <!-- Card 2 -->
    <div class="card">
        <img src="icons/doctor.png">
        <h3>Specialist Doctors</h3>
        <p>Meet our qualified and experienced doctors.</p>

        <!-- DOES NOT require login -->
        <a class="btn" href="doctors.jsp">View Doctors</a>
    </div>

    <!-- Card 3 -->
    <div class="card">
        <img src="icons/emr.png">
        <h3>Medical Records</h3>
        <p>Access your health history securely.</p>

        <% if (!loggedIn) { %>
            <a class="btn" href="javascript:loginRequired()">View Records</a>
        <% } else { %>
            <a class="btn" href="records.jsp">View Records</a>
        <% } %>
    </div>

</div>

<!-- CONTACT SECTION -->
<h2 class="section-title">Contact Us</h2>
<div class="contact-box">
    <p><strong>Address:</strong> Sector 7, Navi Mumbai</p>
    <p><strong>Email:</strong> healthcareclinic@gmail.com</p>
    <p><strong>Phone:</strong> +91 9876543210</p>
</div>

<footer>
    © 2025 HealthCare Clinic. All Rights Reserved.
</footer>

</body>
</html>
