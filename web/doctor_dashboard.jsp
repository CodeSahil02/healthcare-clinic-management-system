<%@ page import="java.sql.*, java.util.*" %>
<%
    if (!"doctor".equals(session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }

    String doctorName  = (String) session.getAttribute("user");
    String doctorEmail = (String) session.getAttribute("email");

    String dbUrl  = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Kolkata";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> todayAppointments = new ArrayList<>();
    String message = "";

    int doctorId = -1;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

            PreparedStatement pd = con.prepareStatement(
                "SELECT d.doctorId FROM doctors d " +
                "JOIN users u ON d.userId = u.id " +
                "WHERE u.email = ?"
            );
            pd.setString(1, doctorEmail);
            ResultSet rd = pd.executeQuery();

            if (rd.next()) {
                doctorId = rd.getInt("doctorId");

                PreparedStatement ps = con.prepareStatement(
                    "SELECT appointmentId, patientName, scheduledAt, status " +
                    "FROM appointments WHERE doctorId=? ORDER BY scheduledAt"
                );
                ps.setInt(1, doctorId);
                ResultSet rs = ps.executeQuery();

                while (rs.next()) {
                    Map<String,String> row = new HashMap<>();
                    row.put("id", rs.getString("appointmentId"));
                    row.put("patient", rs.getString("patientName"));
                    row.put("time", rs.getString("scheduledAt"));
                    row.put("status", rs.getString("status"));
                    todayAppointments.add(row);
                }
            } else {
                message = "Doctor profile not linked. Contact admin.";
            }
        }
    } catch (Exception e) {
        message = e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Doctor Dashboard</title>

<style>
*{box-sizing:border-box}
body{
    margin:0;
    font-family:Segoe UI,Arial,sans-serif;
    background:#eef7f5;
    color:#063829;
}

/* NAVBAR */
.navbar{
    display:flex;
    justify-content:space-between;
    align-items:center;
    padding:14px 24px;
    background:#ffffff;
    box-shadow:0 2px 8px rgba(0,0,0,.05);
}
.brand{
    display:flex;
    gap:12px;
    align-items:center;
    font-weight:800;
}
.brand-logo{
    width:44px;
    height:44px;
    background:#0b6b53;
    color:white;
    display:flex;
    align-items:center;
    justify-content:center;
    border-radius:10px;
    font-size:18px;
}
.btn-logout{
    background:#c0392b;
    color:white;
    border:none;
    padding:8px 14px;
    border-radius:6px;
    cursor:pointer;
    font-weight:700;
}

/* CONTAINER */
.container{
    max-width:1100px;
    margin:30px auto;
    padding:0 20px;
}

/* PROFILE */
.profile-box{
    background:white;
    padding:20px;
    border-radius:14px;
    display:flex;
    align-items:center;
    gap:18px;
    box-shadow:0 10px 30px rgba(0,0,0,.06);
}
.profile-pic{
    width:64px;
    height:64px;
    background:#0b6b53;
    color:white;
    border-radius:50%;
    display:flex;
    align-items:center;
    justify-content:center;
    font-size:24px;
    font-weight:800;
}
.profile-meta .name{
    font-size:20px;
    font-weight:800;
}
.profile-meta .email{
    font-size:14px;
    color:#5e816f;
    font-weight:700;
}

/* GRID */
.grid{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(240px,1fr));
    gap:20px;
    margin:30px 0;
}
.card{
    background:white;
    padding:20px;
    border-radius:14px;
    box-shadow:0 10px 28px rgba(0,0,0,.06);
}
.icon-box{
    font-size:26px;
}
.small-btn{
    display:inline-block;
    margin-top:10px;
    padding:8px 14px;
    background:#0b6b53;
    color:white;
    text-decoration:none;
    border-radius:6px;
    font-weight:700;
}

/* APPOINTMENTS */
.appointments{
    background:white;
    padding:20px;
    border-radius:14px;
    box-shadow:0 10px 28px rgba(0,0,0,.06);
}
table{
    width:100%;
    border-collapse:collapse;
    margin-top:10px;
}
th,td{
    padding:10px;
    border-bottom:1px solid #ddd;
    text-align:left;
}
th{
    background:#f2fbf8;
}
.status-badge{
    padding:4px 10px;
    border-radius:14px;
    font-size:12px;
    font-weight:800;
}
.Scheduled{background:#eafaf1;color:#1e7e34}
.InConsultation{background:#fff3cd;color:#856404}
.Completed{background:#d1ecf1;color:#0c5460}
</style>

</head>
<body>

<header class="navbar">
    <div class="brand">
        <div class="brand-logo">HC</div>
        <div>
            <div>HealthCare Clinic</div>
            <div style="font-size:12px;color:#6b8b81;">Doctor Dashboard</div>
        </div>
    </div>
    <form action="logout.jsp" method="post">
        <button class="btn-logout">Logout</button>
    </form>
</header>

<main class="container">

    <section class="profile-box">
        <div class="profile-pic"><%= doctorName.substring(0,1).toUpperCase() %></div>
        <div class="profile-meta">
            <div class="name"><%= doctorName %></div>
            <div class="email"><%= doctorEmail %></div>
        </div>
    </section>

    <section class="grid">
        <div class="card">
            <div class="icon-box"></div>
            <h4>Today's Appointments</h4>
            <p>Check and manage your schedule.</p>
            <a class="small-btn" href="doctor_appointments.jsp">View</a>
        </div>

        <div class="card">
            <div class="icon-box"></div>
            <h4>Patient Records</h4>
            <p>View and update patient medical records.</p>
            <a class="small-btn" href="doctor_records.jsp">Open</a>
        </div>
    </section>

    <section class="appointments">
        <h3>Upcoming Appointments</h3>

        <table>
            <tr>
                <th>Patient</th>
                <th>Time</th>
                <th>Status</th>
                <th>Action</th>
            </tr>

            <% if(todayAppointments.isEmpty()){ %>
            <tr>
                <td colspan="4" style="text-align:center;">No appointments</td>
            </tr>
            <% } else {
                for(Map<String,String> a : todayAppointments){ %>
            <tr>
                <td><%= a.get("patient") %></td>
                <td><%= a.get("time") %></td>
                <td><span class="status-badge <%= a.get("status").replace(" ","") %>"><%= a.get("status") %></span></td>
                <td><a href="consult.jsp?id=<%= a.get("id") %>">Open</a></td>
            </tr>
            <% }} %>
        </table>
    </section>

</main>

</body>
</html>
