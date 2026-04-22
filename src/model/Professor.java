package model;
public class Professor extends User {
    private String department;
    private String officeHours;

    public Professor(int id, String name, String email, String password,
                     String department, String officeHours) {

        super(id, name, email, password, "PROFESSOR");
        this.department = department;
        this.officeHours = officeHours;
    }
}