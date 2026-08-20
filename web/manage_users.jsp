<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String dbUrl  = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    String action = request.getParameter("action");
    String message = "";

    List<Map<String,String>> users = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        /* ===== ACTION HANDLER ===== */
        if (action != null) {

            if ("disable".equals(action)) {
                PreparedStatement ps = con.prepareStatement(
                    "UPDATE users SET role='disabled' WHERE id=?"
                );
                ps.setInt(1, Integer.parseInt(request.getParameter("id")));
                ps.executeUpdate();
                ps.close();
                message = "User disabled successfully.";
            }

            if ("enable".equals(action)) {
                PreparedStatement ps = con.prepareStatement(
                    "UPDATE users SET role=? WHERE id=?"
                );
                ps.setString(1, request.getParameter("newRole"));
                ps.setInt(2, Integer.parseInt(request.getParameter("id")));
                ps.executeUpdate();
                ps.close();
                message = "User enabled successfully.";
            }

            if ("changeRole".equals(action)) {
                PreparedStatement ps = con.prepareStatement(
                    "UPDATE users SET role=? WHERE id=?"
                );
                ps.setString(1, request.getParameter("newRole"));
                ps.setInt(2, Integer.parseInt(request.getParameter("id")));
                ps.executeUpdate();
                ps.close();
                message = "Role updated successfully.";
            }
        }

        /* ===== FETCH USERS ===== */
        PreparedStatement ps = con.prepareStatement(
            "SELECT id, name, email, role FROM users ORDER BY role, name"
        );
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String,String> u = new HashMap<>();
            u.put("id", rs.getString("id"));
            u.put("name", rs.getString("name"));
            u.put("email", rs.getString("email"));
            u.put("role", rs.getString("role"));
            users.add(u);
        }

        con.close();

    } catch (Exception e) {
        message = "Error: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Manage Users</title>
    <meta charset="UTF-8">

    <style>
        body{font-family:Arial;background:#eefaf6;color:#063829;margin:0}
        .container{max-width:1200px;margin:30px auto;padding:0 20px}

        /* TOP BAR */
        .top-bar{
            display:flex;
            justify-content:space-between;
            align-items:center;
            margin-bottom:16px;
        }

        .back-btn{
            text-decoration:none;
            padding:8px 14px;
            border-radius:8px;
            background:#ffffff;
            border:1px solid #cfe5dd;
            color:#063829;
            font-weight:700;
        }

        h2{margin:0}

        table{width:100%;border-collapse:collapse;background:#fff;border-radius:12px}
        th,td{padding:12px;border-bottom:1px solid #eee;text-align:left}
        th{background:#f7fffb}

        .badge{padding:4px 10px;border-radius:999px;font-weight:700;font-size:12px}
        .active{background:#e7f7ef;color:#198754}
        .disabled{background:#ffe4e6;color:#b91c1c}

        .btn{padding:6px 10px;border-radius:6px;border:none;font-weight:700;cursor:pointer}
        .danger{background:#dc3545;color:#fff}
        .success{background:#198754;color:#fff}
        .info{background:#0d6efd;color:#fff}

        select{padding:6px}

        .msg{
            background:#e7f7ef;
            padding:10px;
            border-radius:8px;
            margin-bottom:12px;
            font-weight:700;
        }
    </style>
</head>

<body>
<div class="container">

    <!-- TOP BAR -->
    <div class="top-bar">
        <h2>Manage Users</h2>
        <a href="admin_dashboard.jsp" class="back-btn">← Back to Dashboard</a>
    </div>

    <% if (!message.isEmpty()) { %>
        <div class="msg"><%= message %></div>
    <% } %>

    <table>
        <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
            <th>Actions</th>
        </tr>

        <% for (Map<String,String> u : users) {
            boolean disabled = "disabled".equalsIgnoreCase(u.get("role"));
        %>
        <tr>
            <td><%= u.get("name") %></td>
            <td><%= u.get("email") %></td>
            <td><%= disabled ? "-" : u.get("role") %></td>
            <td>
                <span class="badge <%= disabled ? "disabled" : "active" %>">
                    <%= disabled ? "Disabled" : "Active" %>
                </span>
            </td>
            <td>

                <!-- ENABLE / DISABLE -->
                <form method="post" style="display:inline;">
                    <input type="hidden" name="id" value="<%= u.get("id") %>">
                    <% if (!disabled) { %>
                        <button class="btn danger" name="action" value="disable">Disable</button>
                    <% } else { %>
                        <input type="hidden" name="newRole" value="patient">
                        <button class="btn success" name="action" value="enable">Enable</button>
                    <% } %>
                </form>

                <!-- CHANGE ROLE -->
                <form method="post" style="display:inline;">
                    <input type="hidden" name="id" value="<%= u.get("id") %>">
                    <select name="newRole">
                        <option>patient</option>
                        <option>doctor</option>
                        <option>receptionist</option>
                        <option>admin</option>
                    </select>
                    <button class="btn info" name="action" value="changeRole">Change</button>
                </form>

            </td>
        </tr>
        <% } %>
    </table>

</div>
</body>
</html>
