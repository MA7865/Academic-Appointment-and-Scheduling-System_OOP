package controller;
/* 
import javafx.fxml.FXML;
import javafx.scene.control.*;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

import service.AuthService;
import model.User;

public class LoginController {

    @FXML
    private TextField emailField;

    @FXML
    private PasswordField passwordField;

    @FXML
    private Label messageLabel;

    private AuthService authService = new AuthService();

    @FXML
    public void handleLogin() {
        String email = emailField.getText();
        String pass = passwordField.getText();

        User user = authService.login(email, pass);

        if (user != null) {
            messageLabel.setText("Login successful");

            try {
                FXMLLoader loader = new FXMLLoader(getClass().getResource("/view/timetable.fxml"));
                Scene scene = new Scene(loader.load());

                Stage stage = (Stage) emailField.getScene().getWindow();
                stage.setScene(scene);

            } catch (Exception e) {
                e.printStackTrace();
            }

        } else {
            messageLabel.setText("Invalid credentials");
        }
    }
}*/