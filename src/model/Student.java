package model;
public class Student extends User {
    private int year;
    private boolean hasClearanceIssue;

    public Student(int id, String name, String email, String password,
                   int year, boolean hasClearanceIssue) {

        super(id, name, email, password, "STUDENT");
        this.year = year;
        this.hasClearanceIssue = hasClearanceIssue;
    }
}
