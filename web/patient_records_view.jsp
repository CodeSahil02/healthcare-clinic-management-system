<%@ page import="java.sql.*, java.util.*, java.net.*" %>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // --- Access control ---
    Object roleObj = session.getAttribute("role");
    String role = roleObj == null ? null : roleObj.toString();
    String sessionEmail = (String) session.getAttribute("email");

    String requestedEmail = request.getParameter("email");
    if (requestedEmail == null || requestedEmail.trim().isEmpty()) {
        out.println("<p style='color:darkred; padding:18px; font-weight:800;'>Missing `email` parameter.</p>");
        return;
    }
    requestedEmail = requestedEmail.trim();

    // Only doctors or the patient themselves may view the records
    if (!"doctor".equals(role) && (sessionEmail == null || !sessionEmail.equalsIgnoreCase(requestedEmail))) {
        response.sendRedirect("login.jsp");
        return;
    }

    // DB config (same as your other pages)
    String dbUrl = "jdbc:mysql://localhost:3306/healthcare_clinic?useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "root";
    String dbPass = "10june2004";

    List<Map<String,Object>> records = new ArrayList<>();
    List<String> columns = new ArrayList<>();
    String message = "";
    boolean found = false;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {

            // Check if patient_records table exists
            String tableCheck = "SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'patient_records'";
            try (PreparedStatement tps = con.prepareStatement(tableCheck)) {
                tps.setString(1, "healthcare_clinic");
                try (ResultSet tr = tps.executeQuery()) {
                    if (tr.next() && tr.getInt(1) == 0) {
                        message = "No patient_records table found in database.";
                    }
                }
            }

            if (message.isEmpty()) {
                // --- detect which date-like column exists to use in ORDER BY ---
                String[] dateCandidates = new String[] {
                    "recordId", // intentionally first ignored; kept for reference
                    "recordDate", "record_date", "recorddate",
                    "createdAt", "created_at", "createdat",
                    "updatedAt", "updated_at", "updatedat",
                    "recorded_at", "date", "entry_date", "recordedDate"
                };
                String foundDateCol = null;
                String colQuery = "SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'patient_records' AND COLUMN_NAME = ?";
                try (PreparedStatement pc = con.prepareStatement(colQuery)) {
                    for (String cand : dateCandidates) {
                        pc.setString(1, "healthcare_clinic");
                        pc.setString(2, cand);
                        try (ResultSet rc = pc.executeQuery()) {
                            if (rc.next()) { foundDateCol = cand; break; }
                        }
                    }
                }

                // Build SELECT SQL safely (either with ORDER BY foundDateCol DESC or without ORDER BY)
                String sql;
                if (foundDateCol != null) {
                    sql = "SELECT * FROM patient_records WHERE patientEmail = ? ORDER BY " + foundDateCol + " DESC";
                } else {
                    sql = "SELECT * FROM patient_records WHERE patientEmail = ?";
                }

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, requestedEmail);
                    try (ResultSet rs = ps.executeQuery()) {
                        ResultSetMetaData md = rs.getMetaData();
                        int colCount = md.getColumnCount();
                        // collect column names
                        for (int i = 1; i <= colCount; i++) {
                            columns.add(md.getColumnLabel(i));
                        }
                        // collect rows
                        while (rs.next()) {
                            found = true;
                            Map<String,Object> row = new LinkedHashMap<>();
                            for (String col : columns) {
                                Object val = rs.getObject(col);
                                row.put(col, val);
                            }
                            records.add(row);
                        }
                    }
                }
            }
        }
    } catch (Exception e) {
        message = "Error loading records: " + e.getMessage();
    }
%>

<%! 
    // Declaration: helper to test if column looks like a file/link
    private boolean isFileColumn(String colName) {
        String lower = colName == null ? "" : colName.toLowerCase();
        return lower.contains("file") || lower.contains("report") || lower.contains("path") || lower.contains("url") || lower.contains("document");
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Patient Records — <%= requestedEmail %></title>
    <meta name="viewport" content="width=device-width,initial-scale=1"/>
    <style>
        body { font-family: Arial, sans-serif; background: #f6fcfa; color: #063829; margin:0; padding:0; }
        .wrap { max-width:1100px; margin:28px auto; padding:0 16px 60px; }
        .top { display:flex; justify-content:space-between; align-items:center; margin-bottom:18px; }
        .back { color:#198754; text-decoration:none; font-weight:800; }
        .card { background:#fff; padding:18px; border-radius:12px; box-shadow:0 10px 30px rgba(3,40,34,0.06); }
        h2 { margin:0 0 8px 0; font-size:20px; }
        .muted { color:#6b8b81; font-weight:700; }
        .notice { margin:12px 0; padding:12px; background:#fff7e9; border-radius:8px; color:#7a5b00; font-weight:700; }
        table { width:100%; border-collapse:collapse; margin-top:12px; font-size:0.95rem; }
        thead th { text-align:left; padding:10px 12px; background:#f8fffb; border-bottom:1px solid #eef7f2; color:#063829; font-weight:800; }
        tbody td { padding:12px; border-bottom:1px dashed #eef7f2; vertical-align:top; color:#123b30; }
        .file-link { display:inline-block; padding:6px 10px; background:#e8f5f3; color:#063829; border-radius:8px; font-weight:800; text-decoration:none; }
        .empty { text-align:center; padding:28px; color:#6b8b81; font-weight:700; }
        .meta-row { margin-bottom:10px; font-weight:800; color:#094235; }
        @media (max-width:720px) {
            .top { flex-direction:column; align-items:flex-start; gap:12px; }
            thead th, tbody td { padding:10px; }
        }
    </style>
</head>
<body>
    <div class="wrap">

        <div class="top">
            <a class="back" href="<%= "doctor".equals(role) ? "doctor_dashboard.jsp" : "index.jsp" %>">← Back</a>
            <div>
                <div style="text-align:right;">
                    <div style="font-weight:900;">Patient Records</div>
                    <div class="muted"><%= requestedEmail %></div>
                </div>
            </div>
        </div>

        <div class="card">
            <h2>Medical Records for</h2>
            <div class="muted" style="margin-bottom:10px;"><%= requestedEmail %></div>

            <% if (!message.equals("")) { %>
                <div class="notice"><%= message %></div>
            <% } %>

            <% if (!found) { %>
                <div class="empty">No records found for this patient.</div>
            <% } else { %>

                <table role="table" aria-label="patient records">
                    <thead>
                        <tr>
                            <% for (String col : columns) { %>
                                <th><%= col %></th>
                            <% } %>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (Map<String,Object> r : records) { %>
                            <tr>
                                <% for (String col : columns) {
                                    Object v = r.get(col);
                                    String outVal = (v == null) ? "" : v.toString();
                                    if (isFileColumn(col) && outVal != null && !outVal.trim().isEmpty()) {
                                        // If value looks like a path or URL, render as link
                                        String href = outVal;
                                        boolean looksLikeUrl = href.startsWith("http://") || href.startsWith("https://") || href.startsWith("/");
                                %>
                                        <td>
                                            <a class="file-link" href="<%= looksLikeUrl ? href : ("files/" + URLEncoder.encode(href, "UTF-8")) %>" target="_blank" rel="noopener noreferrer">
                                                View / Download
                                            </a>
                                            <div style="margin-top:6px; color:#55786f; font-weight:700;"><%= outVal %></div>
                                        </td>
                                <%  } else { %>
                                        <td><%= outVal.replaceAll("\n","<br/>") %></td>
                                <%  }
                                   } %>
                            </tr>
                        <% } %>
                    </tbody>
                </table>

            <% } %>
        </div>

    </div>
</body>
</html>
