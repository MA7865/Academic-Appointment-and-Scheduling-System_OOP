package view;

import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.VBox;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import model.Student;

public class StudentView {

    public static Scene getScene(Student student) {
        Label title = new Label("Welcome, " + student.getFirstName());
        title.setFont(Font.font("Arial", FontWeight.BOLD, 18));

        Label placeholder = new Label("Student Dashboard - coming soon");
        placeholder.setFont(Font.font("Arial", 14));

        VBox layout = new VBox(10);
        layout.setAlignment(Pos.CENTER);
        layout.setPadding(new Insets(20));
        layout.getChildren().addAll(title, placeholder);

        return new Scene(layout, 800, 600);
    }
}
