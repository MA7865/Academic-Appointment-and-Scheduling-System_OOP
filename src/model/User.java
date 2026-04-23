package model;
public abstract class User {
    protected int id;
    protected String name;
    protected String email;
    protected String password;
    protected String role;

    public User(int id, String name, String email, String password, String role) {
        this.id = id;
        this.name = name;
        this.email = email;
        this.password = password;
        this.role = role;
    }

    public String getEmail() { return email; }
    public String getPassword() { return password; }
    public String getRole() { return role; }
    public String getName() { return name; }
}