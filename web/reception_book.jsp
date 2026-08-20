<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Access control: receptionist only
    String role = (String) session.getAttribute("role");
    if (role == null || !role.equals("receptionist")) {
        response.sendRedirect("login.jsp");
        return;
    }

    String receptionistName = (String) session.getAttribute("user");
    String receptionistEmail = (String) session.getAttribute("email");

    // DB config
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> patients = new ArrayList<>();
    List<Map<String,String>> doctors = new ArrayList<>();
    String message = "";
    String err = "";

    // Load patients and doctors
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

            // Load patients from users table
            String psql = "SELECT id, name, email FROM users WHERE role = 'patient' ORDER BY name ASC";
            try (PreparedStatement ps = con.prepareStatement(psql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String,String> row = new HashMap<>();
                    row.put("id", rs.getString("id"));
                    row.put("name", rs.getString("name"));
                    row.put("email", rs.getString("email"));
                    patients.add(row);
                }
            }

            // Load doctors
            String dsql = "SELECT doctorId, name, specialization FROM doctors ORDER BY name ASC";
            try (PreparedStatement ps2 = con.prepareStatement(dsql);
                 ResultSet rd = ps2.executeQuery()) {
                while (rd.next()) {
                    Map<String,String> d = new HashMap<>();
                    d.put("id", rd.getString("doctorId"));
                    d.put("name", rd.getString("name"));
                    d.put("specialty", rd.getString("specialization"));
                    doctors.add(d);
                }
            }
        }
    } catch (Exception e) {
        err = "Error loading data: " + e.getMessage();
    }

    // Handle booking POST
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String patientEmail = request.getParameter("patientEmail");
        String patientName = request.getParameter("patientName");
        String doctorId = request.getParameter("doctor");
        String appointmentDate = request.getParameter("date");
        String appointmentTime = request.getParameter("time");

        // Basic validation
        if (patientEmail == null || patientEmail.trim().isEmpty()) {
            message = "Please select a patient.";
        } else if (doctorId == null || doctorId.trim().isEmpty()) {
            message = "Please select a doctor.";
        } else if (appointmentDate == null || appointmentDate.trim().isEmpty() ||
                   appointmentTime == null || appointmentTime.trim().isEmpty()) {
            message = "Please provide both date and time.";
        } else {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
                    // Resolve doctorName from doctorId (defensive)
                    String docName = "";
                    String docQuery = "SELECT name FROM doctors WHERE doctorId = ?";
                    try (PreparedStatement pd = con.prepareStatement(docQuery)) {
                        pd.setInt(1, Integer.parseInt(doctorId));
                        try (ResultSet rd = pd.executeQuery()) {
                            if (rd.next()) docName = rd.getString("name");
                        }
                    }

                    // Construct scheduledAt as "YYYY-MM-DD HH:MM:SS" (MySQL DATETIME format)
                    // appointmentTime is "HH:MM" from <input type="time">; append :00 for seconds
                    String scheduledAt = appointmentDate + " " + (appointmentTime.length() == 5 ? appointmentTime + ":00" : appointmentTime);

                    // Insert appointment
                    String ins = "INSERT INTO appointments (patientEmail, patientName, doctorId, doctorName, scheduledAt, status) VALUES (?, ?, ?, ?, ?, 'Scheduled')";
                    try (PreparedStatement pi = con.prepareStatement(ins)) {
                        pi.setString(1, patientEmail);
                        pi.setString(2, patientName);
                        pi.setString(3, doctorId);
                        pi.setString(4, docName);
                        pi.setString(5, scheduledAt);
                        int r = pi.executeUpdate();
                        if (r > 0) {
                            message = "Appointment booked successfully for " + patientName + " on " + scheduledAt + " with " + docName + ".";
                        } else {
                            message = "Failed to book appointment.";
                        }
                    }
                }
            } catch (Exception e) {
                message = "Error booking appointment: " + e.getMessage();
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Book Appointment — Receptionist</title>
    <meta name="viewport" content="width=device-width,initial-scale=1"/>
    <style>
        :root {
            --bg1: #eaf7f3;
            --bg2: #fbfffe;
            --teal: #063829;
            --muted: #6b8b81;
            --accent: #198754;
            --card: #fff;
            --shadow: rgba(3,40,34,0.08);
        }
        *{box-sizing:border-box;}
        body {
            margin:0;
            font-family: system-ui, -apple-system, "Segoe UI", Roboto, Arial;
            background: linear-gradient(180deg,var(--bg1),var(--bg2));
            color:var(--teal);
            -webkit-font-smoothing:antialiased;
        }
        .navbar {
            display:flex; justify-content:space-between; align-items:center;
            padding:14px 4%; background:#fff; box-shadow:0 2px 8px var(--shadow);
        }
        .brand { display:flex; gap:10px; align-items:center; font-weight:800; color:var(--teal); }
        .brand-logo { width:40px;height:40px;border-radius:999px;background:var(--accent);display:grid;place-items:center;color:#fff;font-weight:900; }
        .container { max-width:980px; margin:28px auto; padding:0 18px 60px; }
        .card { background:var(--card); padding:20px; border-radius:12px; box-shadow:0 10px 30px var(--shadow); }
        h2 { margin:0 0 12px 0; }
        .muted { color:var(--muted); font-weight:700; }

        form { display:grid; gap:14px; grid-template-columns: 1fr 360px; align-items:start; }
        @media(max-width:900px) { form { grid-template-columns: 1fr; } }

        label { font-weight:800; margin-bottom:6px; display:block; }
        select, input[type="date"], input[type="time"], input[type="text"] {
            width:100%; padding:10px; border-radius:8px; border:1px solid #dfeee7;
            font-size:14px; box-sizing:border-box;
        }
        .full { grid-column: 1 / -1; }

        .btn { padding:12px 16px; border-radius:10px; background:var(--accent); color:#fff; border:none; font-weight:900; cursor:pointer; }
        .btn-ghost { background:transparent; border:1px solid rgba(3,40,34,0.06); color:var(--teal); padding:10px 14px; border-radius:8px; font-weight:800; cursor:pointer; }

        .note { padding:10px; border-radius:8px; background:#fff7e9; color:#7a5b00; font-weight:800; }
        .success { padding:10px; border-radius:8px; background:#e8f8ef; color:#0b4b33; font-weight:800; }
        .error { padding:10px; border-radius:8px; background:#fdecec; color:#6b1212; font-weight:800; }

        .small { font-size:0.9rem; color:var(--muted); }

        .links { display:flex; gap:10px; }
    </style>
</head>
<body>

    <header class="navbar" role="banner">
        <div class="brand">
            <div class="brand-logo">HC</div>
            <div>
                <div>HealthCare Clinic</div>
                <div style="font-size:12px;color:var(--muted);font-weight:700;">Book appointment (Receptionist)</div>
            </div>
        </div>

        <div class="links" role="navigation" aria-label="Top actions">
            <a class="btn-ghost" href="reception_dashboard.jsp">← Dashboard</a>
            <form method="post" action="logout.jsp" style="margin:0;">
                <button class="btn-ghost" type="submit">Logout</button>
            </form>
        </div>
    </header>

    <main class="container">
        <div class="card">

            <h2>Book Appointment</h2>
            <p class="muted">Create an appointment for an existing patient.</p>

            <% if (err != null && !err.isEmpty()) { %>
                <div class="error"><%= err %></div>
            <% } %>

            <% if (message != null && !message.isEmpty()) { %>
                <div class="success"><%= message %></div>
            <% } %>

            <form method="POST" novalidate>
                <!-- left: inputs -->
                <div>
                    <div>
                        <label for="patientEmail">Select Patient</label>
                        <select id="patientEmail" name="patientEmail" required onchange="document.getElementById('patientName').value=this.options[this.selectedIndex].dataset.name;">
                            <option value="">-- Select patient --</option>
                            <% for (Map<String,String> p : patients) { %>
                                <option value="<%= p.get("email") %>" data-name="<%= p.get("name") %>"><%= p.get("name") %> — <%= p.get("email") %></option>
                            <% } %>
                        </select>
                    </div>

                    <div style="margin-top:8px;">
                        <label for="doctor">Select Doctor</label>
                        <select id="doctor" name="doctor" required>
                            <option value="">-- Select doctor --</option>
                            <% for (Map<String,String> d : doctors) { %>
                                <option value="<%= d.get("id") %>">Dr. <%= d.get("name") %> — <%= d.get("specialty") %></option>
                            <% } %>
                        </select>
                    </div>

                    <div style="display:flex; gap:12px; margin-top:12px;">
                        <div style="flex:1;">
                            <label for="date">Appointment Date</label>
                            <input type="date" id="date" name="date" required/>
                        </div>
                        <div style="width:170px;">
                            <label for="time">Appointment Time</label>
                            <input type="time" id="time" name="time" required/>
                        </div>
                    </div>

                </div>

                <!-- right: preview + submit -->
                <div>
                    <div style="background:#fafefb; border-radius:10px; padding:14px; border:1px solid #eef8f2;">
                        <div style="font-weight:800; margin-bottom:8px;">Preview</div>
                        <div class="small">Patient: <span id="previewPatient">—</span></div>
                        <div class="small" style="margin-top:6px;">Doctor: <span id="previewDoctor">—</span></div>
                        <div class="small" style="margin-top:6px;">Date & time: <span id="previewDT">—</span></div>
                    </div>

                    <input type="hidden" id="patientName" name="patientName" value=""/>

                    <div style="margin-top:14px; display:flex; gap:8px;">
                        <button class="btn" type="submit">Book Appointment</button>
                        <a class="btn-ghost" href="receptionist_dashboard.jsp">Cancel</a>
                    </div>

                    <div style="margin-top:12px;" class="small">Note: Bookings will be created with status <strong>Scheduled</strong>.</div>
                </div>

                <!-- full-width note area -->
                <div class="full">
                    <div style="margin-top:10px;">
                        <label for="note">Optional Note for Appointment (internal)</label>
                        <input type="text" id="note" name="note" placeholder="e.g. needs wheelchair access (this field is not currently persisted)" disabled />
                    </div>
                </div>
            </form>

        </div>
    </main>

    <script>
        // small client-side preview
        const patientSelect = document.getElementById('patientEmail');
        const doctorSelect = document.getElementById('doctor');
        const dateInput = document.getElementById('date');
        const timeInput = document.getElementById('time');

        function updatePreview() {
            const pOpt = patientSelect.options[patientSelect.selectedIndex];
            const dOpt = doctorSelect.options[doctorSelect.selectedIndex];
            document.getElementById('previewPatient').textContent = pOpt && pOpt.value ? (pOpt.dataset.name + ' — ' + pOpt.value) : '—';
            document.getElementById('previewDoctor').textContent = dOpt && dOpt.value ? dOpt.text : '—';
            const dt = (dateInput.value ? dateInput.value : '') + (timeInput.value ? (' ' + timeInput.value) : '');
            document.getElementById('previewDT').textContent = dt.trim() ? dt : '—';
            // update hidden patient name
            document.getElementById('patientName').value = pOpt && pOpt.dataset && pOpt.dataset.name ? pOpt.dataset.name : '';
        }

        [patientSelect, doctorSelect, dateInput, timeInput].forEach(el => {
            if (el) el.addEventListener('change', updatePreview);
        });

        // initialize preview
        updatePreview();
    </script>

</body>
</html>
