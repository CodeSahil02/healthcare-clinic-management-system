<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%
    String message = "";

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String email = request.getParameter("email");
        String password = request.getParameter("password");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/healthcare_clinic"
                + "?useSSL=false"
                + "&verifyServerCertificate=false"
                + "&allowPublicKeyRetrieval=true"
                + "&serverTimezone=Asia/Kolkata",
                "root",
                "10june2004"
            );

            PreparedStatement ps = con.prepareStatement(
                "SELECT id, name, role FROM users WHERE email=? AND password=?"
            );
            ps.setString(1, email);
            ps.setString(2, password);

            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                int userId = rs.getInt("id");
                String role = rs.getString("role");
                String name = rs.getString("name");

                if ("disabled".equalsIgnoreCase(role)) {
                    message = "Your account is disabled. Please contact admin.";
                } else {

                    session.setAttribute("user", name);
                    session.setAttribute("email", email);
                    session.setAttribute("role", role);

                    if ("doctor".equalsIgnoreCase(role)) {
                        PreparedStatement ps2 = con.prepareStatement(
                            "SELECT doctorId FROM doctors WHERE userId=? AND status='ACTIVE'"
                        );
                        ps2.setInt(1, userId);
                        ResultSet rs2 = ps2.executeQuery();

                        if (rs2.next()) {
                            session.setAttribute("doctorId", rs2.getInt("doctorId"));
                        } else {
                            message = "Your doctor account is inactive. Please contact admin.";
                            con.close();
                            return;
                        }
                    }

                    if ("admin".equalsIgnoreCase(role)) {
                        response.sendRedirect("admin_dashboard.jsp");
                    } else if ("doctor".equalsIgnoreCase(role)) {
                        response.sendRedirect("doctor_dashboard.jsp");
                    } else if ("receptionist".equalsIgnoreCase(role)) {
                        response.sendRedirect("reception_dashboard.jsp");
                    } else {
                        response.sendRedirect("patient_home.jsp");
                    }

                    con.close();
                    return;
                }
            } else {
                message = "Invalid email or password!";
            }

            con.close();

        } catch (Exception e) {
            message = "Login error: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>Login - HealthCare Clinic</title>

    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            height: 100vh;
            display: flex;
            background: #f5f7f8;
        }

        .left-section {
            width: 50%;
            padding: 60px 80px;
            background: white;
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

        .logo {
            font-size: 24px;
            font-weight: bold;
            margin-bottom: 40px;
            color: #063829;
        }

        .welcome-title {
            font-size: 32px;
            font-weight: bold;
            color: #063829;
            margin-bottom: 10px;
        }

        .subtitle {
            color: #4f6f66;
            margin-bottom: 30px;
            font-size: 15px;
        }

        label {
            font-weight: bold;
            color: #063829;
            font-size: 14px;
        }

        input {
            width: 100%;
            padding: 12px;
            border-radius: 8px;
            border: 1px solid #cbdad5;
            margin-top: 6px;
            margin-bottom: 20px;
        }

        .error {
            background: #ffdfdf;
            padding: 10px;
            border-left: 4px solid #d9534f;
            border-radius: 6px;
            color: #a12828;
            margin-bottom: 15px;
        }

        .btn-login {
            width: 100%;
            padding: 14px;
            background: #055e52;
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            cursor: pointer;
            font-weight: bold;
            margin-top: 10px;
        }

        .btn-login:hover {
            background: #044c42;
        }

        .right-section {
            width: 50%;
            background: linear-gradient(135deg, #055e52, #0c7f72);
            padding: 80px;
            color: white;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        .right-title {
            font-size: 34px;
            font-weight: bold;
            margin-bottom: 20px;
        }

        .quote {
            font-size: 16px;
            margin-bottom: 30px;
            line-height: 1.6;
            opacity: 0.9;
        }

        .signup-text {
            margin-top: 20px;
            font-size: 14px;
        }

        .signup-text a {
            color: #055e52;
            font-weight: bold;
            text-decoration: none;
        }
    </style>
</head>

<body>

<div class="left-section">

    <!-- 🔙 BACK BUTTON -->
    <div class="top-nav">
        <a href="index.jsp" class="back-btn">← Back</a>
    </div>

    <div class="logo">HealthCare Clinic</div>

    <h2 class="welcome-title">Welcome Back!</h2>
    <p class="subtitle">Sign in to continue your healthcare journey.</p>

    <% if (!message.equals("")) { %>
        <div class="error"><%= message %></div>
    <% } %>

    <form method="POST">
        <label>Email</label>
        <input type="email" name="email" required>

        <label>Password</label>
        <input type="password" name="password" required>

        <button class="btn-login">Sign In</button>
    </form>

    <div class="signup-text">
        Don't have an account?
        <a href="register.jsp">Sign Up</a>
    </div>
</div>

<div class="right-section">
    <h2 class="right-title">Revolutionize Healthcare With Smarter Automation</h2>
    <p class="quote">
        “HealthCare Clinic has transformed the way we organize patient care.
        It's reliable, efficient, and ensures smooth clinic operations every day.”
    </p>
</div>

</body>
</html>