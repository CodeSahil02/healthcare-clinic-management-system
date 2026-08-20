<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    if (!"admin".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    List<Map<String,String>> doctors = new ArrayList<>();
    List<Map<String,String>> doctorUsers = new ArrayList<>();

    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        /* USERS WITH ROLE = DOCTOR */
        PreparedStatement psUsers = con.prepareStatement(
            "SELECT id, name, email FROM users WHERE role='doctor'"
        );
        ResultSet ru = psUsers.executeQuery();
        while (ru.next()) {
            Map<String,String> u = new HashMap<>();
            u.put("id", ru.getString("id"));
            u.put("name", ru.getString("name"));
            u.put("email", ru.getString("email"));
            doctorUsers.add(u);
        }

        /* DOCTORS LIST */
        PreparedStatement ps = con.prepareStatement(
            "SELECT doctorId, name, specialization, yoe, fee, photo, status FROM doctors"
        );
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String,String> d = new HashMap<>();
            d.put("id", rs.getString("doctorId"));
            d.put("name", rs.getString("name"));
            d.put("spec", rs.getString("specialization"));
            d.put("yoe", rs.getString("yoe"));
            d.put("fee", rs.getString("fee"));
            d.put("photo", rs.getString("photo"));
            d.put("status", rs.getString("status"));
            doctors.add(d);
        }

        con.close();
    } catch (Exception e) {
        out.println(e.getMessage());
    }
%>

<!DOCTYPE html>
<html>
<head>
<title>Manage Doctors</title>

<style>
body{
    font-family:Arial, Helvetica, sans-serif;
    background:#eefaf6;
    margin:0;
    padding:20px;
}
.header{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:20px;
}
.back-btn{
    padding:8px 14px;
    background:#ffffff;
    border:1px solid #cde5dc;
    border-radius:8px;
    text-decoration:none;
    color:#063829;
    font-weight:700;
}
table{
    width:100%;
    border-collapse:collapse;
    background:white;
}
th,td{
    padding:10px;
    border-bottom:1px solid #ccc;
}
th{ background:#f2fbf8; }
img{
    width:50px;
    height:50px;
    border-radius:8px;
    object-fit:cover;
}
.status-active{ color:green; font-weight:700; }
.status-inactive{ color:red; font-weight:700; }
button{
    padding:6px 10px;
    font-weight:700;
    cursor:pointer;
}
</style>
</head>

<body>

<div class="header">
    <h2>Manage Doctors</h2>
    <a href="admin_dashboard.jsp" class="back-btn">← Back</a>
</div>

<!-- ADD DOCTOR -->
<form action="DoctorController" method="post" enctype="multipart/form-data">
    <input type="hidden" name="action" value="add">

    <select name="userId" required>
        <option value="">Select Doctor User</option>
        <% for (Map<String,String> u : doctorUsers) { %>
            <option value="<%= u.get("id") %>">
                <%= u.get("name") %> (<%= u.get("email") %>)
            </option>
        <% } %>
    </select>

    <input name="name" placeholder="Doctor Name" required>
    <input name="specialization" placeholder="Specialization" required>
    <input name="yoe" type="number" placeholder="YOE" required>
    <input name="fee" type="number" placeholder="Fee" required>
    <input type="file" name="photo">
    <button>Add</button>
</form>

<hr>

<table>
<tr>
    <th>Photo</th>
    <th>Name</th>
    <th>Specialization</th>
    <th>YOE</th>
    <th>Fee</th>
    <th>Status</th>
    <th>Actions</th>
</tr>

<% for (Map<String,String> d : doctors) { %>
<tr>
<form action="DoctorController" method="post" enctype="multipart/form-data">

<td>
    <% if (d.get("photo") != null && !d.get("photo").isEmpty()) { %>
        <img src="<%= d.get("photo") %>">
    <% } else { %> - <% } %>
</td>

<td><input name="name" value="<%= d.get("name") %>"></td>
<td><input name="specialization" value="<%= d.get("spec") %>"></td>
<td><input name="yoe" type="number" value="<%= d.get("yoe") %>"></td>
<td><input name="fee" type="number" value="<%= d.get("fee") %>"></td>

<td>
    <span class="<%= "ACTIVE".equals(d.get("status")) ? "status-active" : "status-inactive" %>">
        <%= d.get("status") %>
    </span>
</td>

<td>
    <input type="file" name="photo">
    <input type="hidden" name="existingPhoto" value="<%= d.get("photo") %>">
    <input type="hidden" name="doctorId" value="<%= d.get("id") %>">

    <button name="action" value="update">Update</button>

    <% if ("ACTIVE".equals(d.get("status"))) { %>
        <button name="action" value="deactivate">Deactivate</button>
    <% } else { %>
        <button name="action" value="activate">Activate</button>
    <% } %>
</td>

</form>
</tr>
<% } %>
</table>

</body>
</html>
