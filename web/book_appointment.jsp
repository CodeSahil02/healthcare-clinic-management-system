<%@ page import="java.sql.*, java.util.*" %>
<%@ page contentType="text/html; charset=UTF-8" %>

<%
    // Session check
    String role = (String) session.getAttribute("role");
    if (!"patient".equals(role)) {
        response.sendRedirect("login.jsp");
        return;
    }

    String patientEmail = (String) session.getAttribute("email");
    String patientName  = (String) session.getAttribute("user");

    String dbUrl  = "jdbc:mysql://localhost:3306/healthcare_clinic";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,String>> doctors = new ArrayList<>();
    String message = "";

    Connection con = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        con = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        PreparedStatement ps = con.prepareStatement(
            "SELECT doctorId, name FROM doctors WHERE status='ACTIVE'"
        );
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            Map<String,String> d = new HashMap<>();
            d.put("id", rs.getString("doctorId"));
            d.put("name", rs.getString("name"));
            doctors.add(d);
        }

        /* ✅ HANDLE BOOKING */
        if ("POST".equalsIgnoreCase(request.getMethod())) {

            String doctorId = request.getParameter("doctor");
            String date = request.getParameter("date");
            String time = request.getParameter("time");

            if (doctorId == null || doctorId.isEmpty()) {
                message = "Please select a doctor.";
            } else if (date == null || date.isEmpty()) {
                message = "Please select a date.";
            } else if (time == null || time.isEmpty()) {
                message = "Please select a time.";
            } else {

                String doctorName = null;

                /* 🔒 RE-CHECK DOCTOR IS ACTIVE */
                PreparedStatement psDoc = con.prepareStatement(
                    "SELECT name FROM doctors WHERE doctorId=? AND status='ACTIVE'"
                );
                psDoc.setInt(1, Integer.parseInt(doctorId));
                ResultSet rd = psDoc.executeQuery();

                if (!rd.next()) {
                    message = "Selected doctor is no longer available.";
                } else {
                    doctorName = rd.getString("name");

                    /* ✅ INSERT APPOINTMENT (ONLY ONCE) */
                    PreparedStatement psIns = con.prepareStatement(
                        "INSERT INTO appointments " +
                        "(patientEmail, patientName, doctorId, doctorName, scheduledAt, status) " +
                        "VALUES (?, ?, ?, ?, ?, 'Scheduled')"
                    );
                    psIns.setString(1, patientEmail);
                    psIns.setString(2, patientName);
                    psIns.setInt(3, Integer.parseInt(doctorId));
                    psIns.setString(4, doctorName);
                    psIns.setString(5, date + " " + time);

                    psIns.executeUpdate();
                    message = "Appointment booked successfully!";
                }
            }
        }

    } catch (Exception e) {
        message = "Error: " + e.getMessage();
    } finally {
        if (con != null) try { con.close(); } catch (Exception ignored) {}
    }
%>

<!-- ⬇⬇⬇ YOUR UI STARTS HERE (UNCHANGED) ⬇⬇⬇ -->

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Book Appointment — HealthCare Clinic</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <!-- UI CSS remains SAME -->
</head>

<body>
<!-- ⚠ UI CODE EXACTLY SAME AS YOUR FILE -->
<!-- I did NOT touch HTML / CSS / JS -->

</body>
</html>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Book Appointment — HealthCare Clinic</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <link rel="stylesheet" href="styles.css">
    <style>
        :root {
            --green: #198754;
            --teal: #0b6b53;
            --muted: #5e816f;
            --bg: #eaf7f3;
            --card: #ffffff;
        }
        body {
            margin: 0;
            font-family: "Segoe UI", Roboto, Arial, sans-serif;
            background: linear-gradient(180deg,var(--bg),#f7fbfa);
            color: #063829;
        }

        /* top navbar */
        .navbar {
            display:flex;
            align-items:center;
            justify-content:space-between;
            padding:14px 6%;
            background: white;
            box-shadow: 0 2px 8px rgba(6,40,34,0.04);
        }
        .brand { display:flex; gap:12px; align-items:center; font-weight:800; color:var(--teal); }
        .brand-logo { width:44px;height:44px;border-radius:10px;background:var(--teal);color:white;display:grid;place-items:center;font-size:18px; }
        .nav-links a { margin-left:16px; text-decoration:none; color:var(--muted); font-weight:700; }

        /* large central container */
        .wrap {
            max-width: 1200px;
            margin: 36px auto;
            padding: 0 20px;
        }

        /* big two-column card */
        .big-card {
            display: grid;
            grid-template-columns: 1fr 420px; /* left flexible, right fixed */
            gap: 28px;
            background: var(--card);
            border-radius: 16px;
            padding: 28px;
            box-shadow: 0 18px 50px rgba(3,40,34,0.08);
            align-items: start;
        }

        /* left: doctors list */
        .left {
            padding: 8px 6px;
        }
        .title {
            font-size: 24px;
            font-weight: 800;
            margin: 6px 4px 18px 4px;
            color: #063829;
        }
        .subtitle {
            font-size: 14px;
            color: var(--muted);
            margin: 0 4px 18px 4px;
            font-weight:700;
        }

        .doctors {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
            gap: 14px;
        }

        .doc {
            display:flex;
            gap:12px;
            align-items:center;
            padding:14px;
            border-radius:12px;
            background: linear-gradient(180deg,#fff,#fbfffe);
            cursor:pointer;
            border: 1px solid rgba(8,60,49,0.06);
            transition: transform .12s ease, box-shadow .12s ease, border-color .12s ease;
        }
        .doc:hover { transform: translateY(-4px); box-shadow: 0 12px 30px rgba(9,75,55,0.06); }
        .doc.selected { border-color: var(--green); box-shadow: 0 18px 36px rgba(25,135,84,0.08); }

        .avatar {
            width:64px; height:64px; border-radius:12px; display:grid; place-items:center;
            font-weight:800; color:white; background: linear-gradient(135deg,var(--green),#0ea478);
            font-size:18px;
            flex-shrink:0;
        }
        .doc-meta { display:flex; flex-direction:column; gap:4px; }
        .doc-name { font-weight:800; font-size:16px; color:#063829; }
        .doc-sub { font-size:13px; color:var(--muted); font-weight:700; }

        /* right: booking form */
        .right {
            padding: 6px 6px;
        }
        .form-card {
            background: linear-gradient(180deg,#ffffff,#fbfffe);
            border-radius:12px;
            padding:18px;
            border: 1px solid rgba(8,60,49,0.03);
            box-shadow: 0 10px 26px rgba(6,48,36,0.04);
        }
        .form-title { font-size:18px; font-weight:800; margin-bottom:8px; color:#063829; }
        label { display:block; font-weight:800; color:#063829; margin-bottom:8px; font-size:14px; }
        input[type="date"], input[type="time"], select {
            width:100%;
            padding:13px 12px;
            border-radius:10px;
            border:1px solid #d9efe6;
            font-size:15px;
            margin-bottom:14px;
            box-sizing:border-box;
        }
        .btn {
            width:100%;
            padding:14px;
            border-radius:10px;
            border:none;
            background:var(--green);
            color:white;
            font-weight:900;
            font-size:16px;
            cursor:pointer;
            box-shadow: 0 10px 28px rgba(25,135,84,0.12);
        }
        .msg {
            margin-bottom:14px;
            padding:12px;
            background:#edf9f3;
            color:#045237;
            border-radius:10px;
            font-weight:800;
            text-align:center;
        }

        /* preview inside right column */
        .preview {
            margin-top:12px;
            padding:10px;
            border-radius:8px;
            background:#f7fffaf0;
            font-size:14px;
            color:var(--muted);
            border:1px solid rgba(7,65,51,0.03);
        }
        .preview .big { font-size:18px; color:#063829; font-weight:900; margin-top:6px; }

        /* responsive */
        @media (max-width: 1060px) {
            .big-card { grid-template-columns: 1fr; }
            .right { order: 2; }
            .left { order: 1; }
        }
    </style>
</head>
<body>

    <header class="navbar">
        <div class="brand">
            <div class="brand-logo">HC</div>
            <div>
                <div style="font-size:16px;">HealthCare Clinic</div>
                <div style="font-size:12px; color:var(--muted); font-weight:700;">Quality care, simple booking</div>
            </div>
        </div>
        <nav class="nav-links">
            <a href="patient_home.jsp">Home</a>
            <a href="appointments.jsp">Appointments</a>
            <a href="logout.jsp">Logout</a>
        </nav>
    </header>

    <main class="wrap">
        <div class="big-card" role="region" aria-label="Book appointment">

            <!-- LEFT: doctors -->
            <section class="left" aria-labelledby="doctorsHeading">
                <div class="title" id="doctorsHeading">Choose a Doctor</div>
                <div class="subtitle">Tap a doctor on the left, then pick date & time on the right.</div>

                <div class="doctors" id="doctorsList">
                    <% for (Map<String,String> d : doctors) {
                        String did = d.get("id");
                        String name = d.get("name");
                        String initials = "";
                        if (name != null && name.trim().length()>0) {
                            String[] parts = name.trim().split("\\s+");
                            initials += parts[0].substring(0,1).toUpperCase();
                            if (parts.length>1) initials += parts[parts.length-1].substring(0,1).toUpperCase();
                        }
                    %>
                        <div class="doc" tabindex="0" data-id="<%= did %>">
                            <div class="avatar"><%= initials %></div>
                            <div class="doc-meta">
                                <div class="doc-name"><%= name %></div>
                                <div class="doc-sub">General Physician</div>
                            </div>
                        </div>
                    <% } %>
                </div>
            </section>

            <!-- RIGHT: booking form -->
            <aside class="right" aria-labelledby="bookingHeading">
                <div class="form-card" id="formCard">
                    <div class="form-title" id="bookingHeading">Book Appointment</div>

                    <% if (!message.equals("")) { %>
                        <div class="msg"><%= message %></div>
                    <% } %>

                    <form method="POST" id="bookForm">
                        <!-- hidden input to carry chosen doctor id -->
                        <input type="hidden" name="doctor" id="doctorInput" value="">

                        <label for="date">Appointment Date</label>
                        <input type="date" id="date" name="date" required>

                        <label for="time">Appointment Time</label>
                        <input type="time" id="time" name="time" required>

                        <button class="btn" type="submit">Confirm & Book</button>
                    </form>

                    <div class="preview" aria-live="polite">
                        <div style="font-weight:700; color:#063829">Preview</div>
                        <div style="margin-top:8px;">Patient: <strong><%= patientName %></strong></div>
                        <div style="margin-top:8px;">Doctor: <div id="previewDoctor" class="big">— none —</div></div>
                        <div style="margin-top:12px;">Date: <div id="previewDate" class="big">—</div></div>
                        <div style="margin-top:12px;">Time: <div id="previewTime" class="big">—</div></div>
                    </div>
                </div>
            </aside>

        </div>
    </main>

<script>
    // JS: make left doctor cards select and update hidden input + preview
    (function(){
        const doctors = Array.from(document.querySelectorAll('.doc'));
        const doctorInput = document.getElementById('doctorInput');
        const previewDoctor = document.getElementById('previewDoctor');
        const previewDate = document.getElementById('previewDate');
        const previewTime = document.getElementById('previewTime');
        const dateInput = document.getElementById('date');
        const timeInput = document.getElementById('time');

        function clearSelection(){
            doctors.forEach(d => d.classList.remove('selected'));
        }

        function setSelection(el){
            clearSelection();
            el.classList.add('selected');
            const id = el.getAttribute('data-id');
            doctorInput.value = id;
            const name = el.querySelector('.doc-name').innerText;
            previewDoctor.innerHTML = name;
        }

        doctors.forEach(d => {
            d.addEventListener('click', function(){ setSelection(this); });
            d.addEventListener('keydown', function(e){
                if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); setSelection(this); }
            });
        });

        // preview date/time
        dateInput.addEventListener('change', function(){ previewDate.innerText = this.value || '—'; });
        timeInput.addEventListener('change', function(){ previewTime.innerText = this.value || '—'; });

        // initialize min date (today)
        (function setMinDate(){
            const date = new Date();
            const yyyy = date.getFullYear();
            const mm = String(date.getMonth()+1).padStart(2,'0');
            const dd = String(date.getDate()).padStart(2,'0');
            const el = document.getElementById('date');
            if (el) el.min = `${yyyy}-${mm}-${dd}`;
        })();

        // form submit guard
        document.getElementById('bookForm').addEventListener('submit', function(e){
            if (!doctorInput.value) { alert('Please choose a doctor from the left.'); e.preventDefault(); return; }
            if (!dateInput.value) { alert('Please choose a date.'); e.preventDefault(); return; }
            if (!timeInput.value) { alert('Please choose a time.'); e.preventDefault(); return; }
        });

        // optional: auto-select first doctor for convenience (only if list not empty)
        if (doctors.length > 0 && !doctorInput.value) {
            setSelection(doctors[0]);
        }
    })();
</script>

<footer style="max-width:1200px;margin:28px auto 56px; text-align:center; color:var(--muted); font-weight:700;">
    © 2025 HealthCare Clinic. All Rights Reserved.
</footer>

</body>
</html>
