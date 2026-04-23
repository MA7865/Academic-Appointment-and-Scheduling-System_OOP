package controller;
/* 
import javafx.fxml.FXML;
import javafx.scene.control.*;

import service.AuthService;
import dao.TimetableDAO;
import model.Timetable;

import java.util.Arrays;
import java.util.List;

public class TimetableController {

    @FXML
    private TextArea timetableArea;

    @FXML
    private Label statusLabel;

    private TimetableDAO timetableDAO = new TimetableDAO();

    @FXML
    public void handleUpload() {
        String input = timetableArea.getText();

        List<String> slots = Arrays.asList(input.split("\n"));

        // TEMP professor ID (replace with logged-in user later)
        Timetable timetable = new Timetable(1, slots);

        timetableDAO.saveTimetable(timetable);

        statusLabel.setText("Timetable uploaded!");
    }
}*/