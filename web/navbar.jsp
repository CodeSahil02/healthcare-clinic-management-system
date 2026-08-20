<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    boolean loggedIn = (session.getAttribute("user") != null);
    String userName = (String) session.getAttribute("user");
%>

<!-- Simple reusable navbar -->
<div class="navbar" role="navigation">
    <div class="brand">
        <div class="brand-logo">HC</div>
        HealthCare Clinic
    </div>

    <div class="nav-links">
        <a href="index.jsp">Home</a>
        <a href="services.jsp">Services</a>
        <a href="doctors.jsp">Doctors</a>
        <a href="about.jsp">About</a>
        <a href="contact.jsp">Contact</a>

        <% if (!loggedIn) { %>
            <a href="login.jsp" class="login-btn">Login</a>
        <% } else { %>
            <span style="margin-left:10px; font-weight:600;">Hello, <%= userName %></span>
            <a href="logout.jsp" class="login-btn">Logout</a>
        <% } %>
    </div>
</div>
