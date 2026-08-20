<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<%
    // Access control
    String role = (String) session.getAttribute("role");
    if (role == null || !(role.equals("receptionist") || role.equals("doctor") || role.equals("admin"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // ROLE-AWARE BACK PAGE
    String backPage = "login.jsp";
    if ("admin".equals(role)) {
        backPage = "admin_dashboard.jsp";
    } else if ("doctor".equals(role)) {
        backPage = "doctor_dashboard.jsp";
    } else if ("receptionist".equals(role)) {
        backPage = "reception_dashboard.jsp";
    }

    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    String query = request.getParameter("q");
    List<Map<String,Object>> rows = new ArrayList<>();
    List<String> columns = new ArrayList<>();
    String message = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

            String sql =
                "SELECT u.name, u.email, " +
                "COUNT(a.appointmentId) AS appointment_count " +
                "FROM users u " +
                "LEFT JOIN appointments a ON u.email = a.patientEmail " +
                "WHERE u.role = 'patient' ";

            if (query != null && !query.trim().isEmpty()) {
                sql += "AND (u.name LIKE ? OR u.email LIKE ?) ";
            }

            sql += "GROUP BY u.name, u.email " +
                   "ORDER BY u.name COLLATE utf8mb4_general_ci ASC " +
                   "LIMIT 1000";

            try (PreparedStatement ps = con.prepareStatement(sql)) {
                if (query != null && !query.trim().isEmpty()) {
                    String like = "%" + query.trim() + "%";
                    ps.setString(1, like);
                    ps.setString(2, like);
                }

                try (ResultSet rs = ps.executeQuery()) {
                    ResultSetMetaData md = rs.getMetaData();
                    int colCount = md.getColumnCount();

                    for (int i = 1; i <= colCount; i++) {
                        columns.add(md.getColumnLabel(i));
                    }

                    while (rs.next()) {
                        Map<String,Object> r = new LinkedHashMap<>();
                        for (String col : columns) {
                            r.put(col, rs.getObject(col));
                        }
                        rows.add(r);
                    }
                }
            }
        }
    } catch (Exception e) {
        message = "Error loading patients: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <title>Registered Patients</title>
    <meta name="viewport" content="width=device-width, initial-scale=1" />

    <style>
        :root{
            --bg1:#eefaf6;
            --card:#ffffff;
            --accent:#198754;
            --teal:#063829;
            --muted:#6b8b81;
            --shadow: rgba(3,40,34,0.06);
        }
        *{box-sizing:border-box;}
        body{
            margin:0;
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial;
            background: linear-gradient(180deg,var(--bg1),#fbfffd);
            color:var(--teal);
        }
        .navbar{
            display:flex;
            justify-content:space-between;
            align-items:center;
            padding:14px 4%;
            background:var(--card);
            box-shadow: 0 2px 8px var(--shadow);
        }
        .brand{
            display:flex;gap:10px;align-items:center;font-weight:800;
        }
        .brand-logo{
            width:40px;height:40px;border-radius:50%;
            background:var(--accent);display:grid;place-items:center;
            color:#fff;font-weight:900;
        }
        .container{
            max-width:1100px;margin:26px auto;padding:0 18px 60px;
        }
        .card{
            background:var(--card);
            padding:18px;
            border-radius:12px;
            box-shadow:0 10px 30px var(--shadow);
        }
        h2{margin:0 0 12px;}
        .muted{color:var(--muted);font-weight:700;}

        form.search{
            display:flex;gap:12px;align-items:center;margin-bottom:12px;
        }
        input[type="search"]{
            padding:10px;border-radius:8px;
            border:1px solid #e1efe7;width:320px;
        }
        button.btn{
            padding:10px 14px;border-radius:8px;
            border:none;background:var(--accent);
            color:#fff;font-weight:800;cursor:pointer;
        }
        button.ghost, a.ghost{
            padding:9px 12px;border-radius:8px;
            border:1px solid rgba(3,40,34,0.06);
            background:transparent;color:var(--teal);
            font-weight:800;cursor:pointer;
            text-decoration:none;
        }

        table{
            width:100%;border-collapse:collapse;
            margin-top:12px;font-size:0.96rem;
        }
        thead th{
            background:linear-gradient(#f8fffb,#fbfffe);
            padding:12px;text-align:left;
            border-bottom:1px solid #eef7f2;
            font-weight:800;
        }
        tbody td{
            padding:12px;border-bottom:1px solid #f1f6f4;
        }
        .empty{
            padding:24px;text-align:center;
            color:var(--muted);font-weight:800;
        }
        @media(max-width:720px){
            input[type="search"]{width:100%;}
        }
    </style>
</head>

<body>

<nav class="navbar">
    <div class="brand">
        <div class="brand-logo">HC</div>
        <div>
            <div>HealthCare Clinic</div>
            <small class="muted">Patients</small>
        </div>
    </div>

    <div>
        <a class="ghost" href="<%= backPage %>">← Back</a>
        <form style="display:inline-block;margin-left:8px;" method="post" action="logout.jsp">
            <button class="ghost" type="submit">Logout</button>
        </form>
    </div>
</nav>

<main class="container">
    <div class="card">
        <h2>Registered Patients</h2>
        <p class="muted">Patients with appointment count</p>

        <% if (!message.isEmpty()) { %>
            <div style="padding:10px;background:#fff7e9;border-radius:8px;color:#7a5b00;font-weight:800;margin-bottom:12px;">
                <%= message %>
            </div>
        <% } %>

        <form class="search" method="GET">
            <input type="search" name="q" placeholder="Search by name or email"
                   value="<%= query == null ? "" : query %>">
            <button class="btn" type="submit">Search</button>
            <a class="ghost" href="view_patients.jsp">Clear</a>
            <div style="margin-left:auto;font-weight:800;color:var(--muted);">
                Found: <%= rows.size() %>
            </div>
        </form>

        <div style="overflow:auto;">
            <table>
                <thead>
                    <tr>
                        <% for (String col : columns) { %>
                            <th><%= col.replace("_"," ").toUpperCase() %></th>
                        <% } %>
                    </tr>
                </thead>
                <tbody>
                    <% if (rows.isEmpty()) { %>
                        <tr>
                            <td colspan="<%= columns.size() %>" class="empty">No patients found.</td>
                        </tr>
                    <% } else {
                        for (Map<String,Object> r : rows) {
                    %>
                        <tr>
                            <% for (String col : columns) { %>
                                <td><%= r.get(col) == null ? "-" : r.get(col) %></td>
                            <% } %>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

</body>
</html>
