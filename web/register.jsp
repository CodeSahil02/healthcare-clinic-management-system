<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    String message = "";

    if (request.getMethod().equalsIgnoreCase("POST")) {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String role = "patient";

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/healthcare_clinic", "root", "10june2004"
            );

            PreparedStatement ps = con.prepareStatement(
                "INSERT INTO users(name, email, password, role) VALUES(?,?,?,?)"
            );

            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, password);
            ps.setString(4, role);

            int result = ps.executeUpdate();

            if (result > 0) {
                message = "Registration Successful! You can now login.";
            } else {
                message = "Registration failed.";
            }

            con.close();
        } catch (Exception e) {
            message = e.toString();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Register - HealthCare Clinic</title>

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: Arial, sans-serif;
        }

        body {
            height: 100vh;
            display: flex;
        }

        /* LEFT COLUMN */
        .left-panel {
            width: 50%;
            background: #ffffff;
            padding: 60px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
        }

        /* 🔙 TOP NAV BACK BUTTON */
        .top-nav {
            position: absolute;
            top: 25px;
            left: 30px;
        }

        .back-btn {
            text-decoration: none;
            font-weight: bold;
            color: #055e52;
            font-size: 14px;
            padding: 8px 14px;
            border-radius: 8px;
            transition: background 0.2s ease;
        }

        .back-btn:hover {
            background: #e6f3f0;
        }

        .title {
            font-size: 32px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #043d36;
        }

        .subtitle {
            color: #445e5b;
            margin-bottom: 30px;
        }

        label {
            font-size: 14px;
            font-weight: bold;
            color: #043d36;
        }

        input {
            width: 100%;
            padding: 12px;
            border: 1px solid #bcd4ce;
            border-radius: 6px;
            margin-top: 6px;
            margin-bottom: 18px;
        }

        .btn {
            padding: 12px;
            width: 100%;
            background: #055e52;
            color: white;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            font-weight: bold;
            cursor: pointer;
        }

        .btn:hover {
            background: #044c42;
        }

        .bottom-text {
            margin-top: 18px;
            text-align: center;
            font-size: 14px;
        }

        .bottom-text a {
            color: #055e52;
            font-weight: bold;
            text-decoration: none;
        }

        .message {
            background: #d4f8e3;
            padding: 12px;
            border-left: 4px solid #0b6b40;
            margin-bottom: 20px;
            border-radius: 4px;
            color: #0b6b40;
        }

        /* RIGHT COLUMN */
        .right-panel {
            width: 50%;
            background: linear-gradient(135deg, #005f56, #044c45);
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 80px;
        }

        .quote-title {
            font-size: 34px;
            font-weight: bold;
            line-height: 1.3;
            margin-bottom: 25px;
        }

        .quote {
            font-size: 18px;
            line-height: 1.6;
            opacity: 0.9;
            margin-bottom: 30px;
        }
    </style>
</head>

<body>

    <!-- LEFT SIDE FORM -->
    <div class="left-panel">

        <!-- 🔙 BACK BUTTON -->
        <div class="top-nav">
            <a href="index.jsp" class="back-btn">← Back</a>
        </div>

        <h1 class="title">Create an Account</h1>
        <p class="subtitle">Join HealthCare Clinic and manage your health easily.</p>

        <% if (!message.equals("")) { %>
            <div class="message"><%= message %></div>
        <% } %>

        <form method="POST">
            <label>Full Name</label>
            <input type="text" name="name" required>

            <label>Email</label>
            <input type="email" name="email" required>

            <label>Password</label>
            <input type="password" name="password" required>

            <button class="btn">Register</button>

            <div class="bottom-text">
                Already have an account?
                <a href="login.jsp">Login</a>
            </div>
        </form>
    </div>

    <!-- RIGHT SIDE DESIGN PANEL -->
    <div class="right-panel">
        <h2 class="quote-title">Smarter Digital Healthcare</h2>
        <p class="quote">
            "Our digital platform helps clinics streamline appointments,
            manage records, and improve patient experience efficiently."
        </p>
    </div>

</body>
</html>