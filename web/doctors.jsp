<%@ page import="java.sql.*, java.util.*" %>
<%
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> doctors = new ArrayList<>();
    String error = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        PreparedStatement ps = con.prepareStatement(
            "SELECT doctorId, name, specialization, yoe, fee, photo FROM doctors WHERE status='ACTIVE'"
        );
        ResultSet rs = ps.executeQuery();

        while (rs.next()) {
            Map<String,String> d = new HashMap<>();
            d.put("id", rs.getString("doctorId"));
            d.put("name", rs.getString("name"));
            d.put("specialization", rs.getString("specialization"));
            d.put("yoe", rs.getString("yoe"));
            d.put("fee", rs.getString("fee"));
            d.put("photo", rs.getString("photo"));
            doctors.add(d);
        }
        con.close();

    } catch (Exception e) {
        error = "Error loading doctors: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Doctors List</title>
    <link rel="stylesheet" href="styles.css">

    <style>
        .doctors-container {
            width: 90%;
            margin: auto;
            margin-top: 30px;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
            gap: 20px;
        }

        .doctor-card {
            background: white;
            padding: 15px;
            border-radius: 12px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
            text-align: center;
        }

        .doctor-card img {
            width: 120px;
            height: 120px;
            border-radius: 10px;
            object-fit: cover;
            margin-bottom: 10px;
        }

        .doctor-card h3 {
            margin-bottom: 6px;
            color: #063829;
        }

        .doctor-card p {
            margin: 4px 0;
            color: #4a6f66;
        }

        .btn-view {
            display: inline-block;
            margin-top: 8px;
            padding: 8px 14px;
            background: #198754;
            color: white;
            text-decoration: none;
            border-radius: 6px;
        }
    </style>
</head>
<body>

<jsp:include page="navbar.jsp" />

<h2 class="section-title">Our Doctors</h2>

<% if (!error.equals("")) { %>
    <p style="text-align:center; color:red;"><%= error %></p>
<% } %>

<div class="doctors-container">

    <% for (Map<String,String> d : doctors) { %>
        <div class="doctor-card">
            <img src="<%= d.get("photo") %>" alt="Doctor">

            <h3><%= d.get("name") %></h3>
            <p><strong>Specialization:</strong> <%= d.get("specialization") %></p>
            <p><strong>Experience:</strong> <%= d.get("yoe") %> years</p>
            <p><strong>Fee:</strong> Rs. <%= d.get("fee") %></p>

            <a href="book_appointment.jsp?doctorId=<%= d.get("id") %>" class="btn-view">
                Book Appointment
            </a>
        </div>
    <% } %>

</div>

</body>
</html>
