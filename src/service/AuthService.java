package service;

import dao.UserDAO;
import model.User;

public class AuthService {

    private UserDAO userDAO = new UserDAO();

    public User login(String email, String password) {

        User user = userDAO.getUserByEmail(email);

        if (user != null && user.getPassword().equals(password)) {
            return user;
        }

        return null;
    }
}