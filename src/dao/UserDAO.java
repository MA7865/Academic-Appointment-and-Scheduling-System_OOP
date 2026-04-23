package dao;

import java.sql.*;
import model.*;

public class UserDAO {

    public User getUserByEmail(String email) {

        Connection conn = DBConnection.getConnection();

        try {
            String query = """
                SELECT ue.user_id, ue.email, ud.password_hash, ud.role,
                       ud.first_name, ud.last_name,
                       s.year,
                       pd.department,
                       po.office_location
                FROM user_email ue
                JOIN user_details ud ON ue.user_id = ud.user_id
                LEFT JOIN student s ON ue.user_id = s.student_id
                LEFT JOIN professor_department pd ON ue.user_id = pd.professor_id
                LEFT JOIN professor_office po ON pd.professor_id = po.professor_id
                WHERE ue.email = ?
            """;

            PreparedStatement stmt = conn.prepareStatement(query);
            stmt.setString(1, email);

            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {

                int id = rs.getInt("user_id");
                String fullName = rs.getString("first_name") + " " + rs.getString("last_name");
                String password = rs.getString("password_hash");
                String role = rs.getString("role");

                if (role.equalsIgnoreCase("STUDENT")) {

                    return new Student(
                        id,
                        fullName,
                        email,
                        password,
                        rs.getInt("year"),
                        false   // clearance not in DB yet
                    );

                } else if (role.equalsIgnoreCase("PROFESSOR")) {

                    return new Professor(
                        id,
                        fullName,
                        email,
                        password,
                        rs.getString("department"),
                        rs.getString("office_location")
                    );
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return null;
    }
}