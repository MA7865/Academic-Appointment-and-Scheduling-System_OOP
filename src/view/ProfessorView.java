package view;

import enums.AppointmentStatus;
import javafx.beans.property.SimpleStringProperty;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.Button;
import javafx.scene.control.ButtonBar;
import javafx.scene.control.ButtonType;
import javafx.scene.control.ComboBox;
import javafx.scene.control.DatePicker;
import javafx.scene.control.Dialog;
import javafx.scene.control.Label;
import javafx.scene.control.TableCell;
import javafx.scene.control.TableColumn;
import javafx.scene.control.TableView;
import javafx.scene.control.TextField;
import javafx.scene.control.cell.PropertyValueFactory;
import javafx.scene.layout.BorderPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.Region;
import javafx.scene.layout.StackPane;
import javafx.scene.layout.VBox;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.FontWeight;
import main.Main;
import model.Appointment;
import model.Professor;
import model.TimeSlot;
import model.WaitlistEntry;
import service.AppointmentService;
import service.TimeSlotService;

/**
 * ══════════════════════════════════════════════════════════════════════
 * ProfessorView — Dashboard for professor accounts
 *
 * Design language : Consistent "Obsidian Glass" dark theme.
 *                   Deep navy sidebar, semi-transparent cards,
 *                   indigo accent throughout.
 *
 * Sections:
 *   • Top bar       — gradient header with app name + welcome
 *   • Sidebar       — nav buttons with hover/active effects
 *   • Content area  — swaps between sub-views (pending, waitlist,
 *                     past slots, upcoming slots, generate slots)
 *
 * All colour constants are defined at the top so they mirror the
 * CSS variables in styles.css.  Java-side inline styles are used only
 * where JavaFX doesn't pick up the CSS class (e.g. on HBox/VBox
 * backgrounds that aren't scene nodes the stylesheet normally targets).
 * ══════════════════════════════════════════════════════════════════════
 */
public class ProfessorView {

    // ── COLOUR CONSTANTS (must match styles.css palette) ─────────────
    // Deep background — same as .root background-color
    private static final String BG_DARKEST   = "#0F1525";
    // Sidebar background — slightly lighter than main bg
    private static final String BG_SIDEBAR   = "#1B264F";
    // Card / glass surface
    private static final String BG_CARD      = "rgba(255,255,255,0.03)";
    // Primary accent
    private static final String INDIGO       = "#274690";
    // Lighter accent for hover / text
    private static final String INDIGO_LIGHT = "#576CA8";
    // Success green
    private static final String SUCCESS      = "#34D399";
    // Danger red
    private static final String DANGER       = "#F87171";
    // Amber for pending
    private static final String AMBER        = "#FBBF24";
    // Blue for waitlisted
    private static final String BLUE         = "#60A5FA";
    // Primary text
    private static final String TEXT_PRIMARY = "#E2E8F0";
    // Secondary / muted text
    private static final String TEXT_MUTED   = "#64748B";
    // Thin border for glass elements
    private static final String BORDER       = "rgba(255,255,255,0.07)";


    // ══════════════════════════════════════════════════════════════════
    // SCENE ENTRY POINT
    // ══════════════════════════════════════════════════════════════════

    /**
     * Builds the entire professor dashboard Scene.
     *
     * Layout structure:
     *   BorderPane
     *     top  → topBar (HBox)
     *     left → sidebar (VBox)
     *     center → contentArea (StackPane — swapped on nav click)
     */
    public static Scene getScene(Professor professor) {

        // ── TOP BAR ──────────────────────────────────────────────────
        // Gradient header matching the login view's indigo palette
        Label appTitle = new Label("⏰  SlotSync");
        appTitle.setFont(Font.font("Segoe UI", FontWeight.BOLD, 17));
        appTitle.setTextFill(Color.WHITE);
        // Subtle glow on the app title
        appTitle.setStyle(
            "-fx-effect: dropshadow(gaussian, rgba(7, 17, 41, 0.3), 8, 0, 0, 0);"
        );

        // "Prof." badge + name on the right
        Label welcomeLabel = new Label("Prof. " + professor.getFirstName());
        welcomeLabel.setFont(Font.font("Segoe UI", 13));
        welcomeLabel.setTextFill(Color.web(TEXT_PRIMARY));
        welcomeLabel.setStyle(
            "-fx-background-color: rgba(39,70,144,0.15);" +
            "-fx-border-color: rgba(39,70,144,0.25);" +
            "-fx-border-radius: 20;" +
            "-fx-background-radius: 20;" +
            "-fx-padding: 5 14;"
        );

        // Flexible spacer pushes welcome badge to the far right
        Region topSpacer = new Region();
        HBox.setHgrow(topSpacer, Priority.ALWAYS);

        HBox topBar = new HBox(10, appTitle, topSpacer, welcomeLabel);
        topBar.setPadding(new Insets(14, 28, 14, 28));
        topBar.setAlignment(Pos.CENTER_LEFT);
        // Gradient + bottom shadow = elevated header effect
        topBar.getStyleClass().add("top-bar");

        // ── SIDEBAR ───────────────────────────────────────────────────
        // Nav buttons + logout at the bottom
        Button pendingBtn   = createSidebarButton("📋  Pending Requests");
        Button waitlistBtn  = createSidebarButton("⏳  Waitlist Management");
        Button pastBtn      = createSidebarButton("🗂  Past Slots");
        Button upcomingBtn  = createSidebarButton("📅  Upcoming Slots");
        Button generateBtn  = createSidebarButton("✨  Generate Slots");
        Button logoutBtn    = createLogoutButton("🚪  Logout");

        // Spacer pushes logout to the very bottom of the sidebar
        Region sidebarSpacer = new Region();
        VBox.setVgrow(sidebarSpacer, Priority.ALWAYS);

        // ── Section label above nav group ──
        Label navLabel = createSidebarSectionLabel("NAVIGATION");

        VBox sidebar = new VBox(6,
            navLabel,
            pendingBtn, waitlistBtn, pastBtn, upcomingBtn, generateBtn,
            sidebarSpacer,
            logoutBtn
        );
        sidebar.setPadding(new Insets(20, 12, 20, 12));
        sidebar.setPrefWidth(230);
        sidebar.setMinWidth(180);
        sidebar.setMaxWidth(260);
        // Dark navy + right-side divider line
        sidebar.setStyle(
            "-fx-background-color: " + BG_SIDEBAR + ";" +
            "-fx-border-color: rgba(39,70,144,0.20);" +
            "-fx-border-width: 0 1 0 0;"
        );

        // ── CONTENT AREA ──────────────────────────────────────────────
        // StackPane that holds whichever sub-view is currently selected.
        // Default: show a welcome splash until user clicks a nav button.
        BorderPane contentArea = new BorderPane();
        contentArea.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        BorderPane.setMargin(contentArea, Insets.EMPTY);
        VBox welcome = buildWelcomeSplash(professor);
        welcome.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);

        StackPane.setAlignment(welcome, Pos.CENTER);
        contentArea.setCenter(welcome);
        contentArea.getStyleClass().add("content-area");
        contentArea.setPrefSize(Double.MAX_VALUE, Double.MAX_VALUE);
        contentArea.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);

        // ── NAV BUTTON ACTIONS ────────────────────────────────────────
        // Each button replaces contentArea's single child with the new view.
        // setActiveSidebarButton() swaps the "active" visual style.

       pendingBtn.setOnAction(e -> {
    setActiveSidebarButton(pendingBtn,
        waitlistBtn, pastBtn, upcomingBtn, generateBtn);

    VBox view = buildPendingAppointmentsView(professor);
    view.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);

    contentArea.setCenter(view);
});
        waitlistBtn.setOnAction(e -> {
            setActiveSidebarButton(waitlistBtn,
                pendingBtn, pastBtn, upcomingBtn, generateBtn);
            VBox view = buildWaitlistManagementView(professor);
            view.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setPrefSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setCenter(view);
        });

        pastBtn.setOnAction(e -> {
            setActiveSidebarButton(pastBtn,
                pendingBtn, waitlistBtn, upcomingBtn, generateBtn);
            VBox view = buildPastWeekSlotsView(professor);
            view.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setPrefSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setCenter(view);
            });

        upcomingBtn.setOnAction(e -> {
            setActiveSidebarButton(upcomingBtn,
                pendingBtn, waitlistBtn, pastBtn, generateBtn);
            VBox view = buildUpcomingSlotsView(professor);
            view.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setPrefSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setCenter(view);
        });

        generateBtn.setOnAction(e -> {
            setActiveSidebarButton(generateBtn,
                pendingBtn, waitlistBtn, pastBtn, upcomingBtn);
            VBox view = buildGenerateSlotsView(professor);
            view.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setPrefSize(Double.MAX_VALUE, Double.MAX_VALUE);
            contentArea.setCenter(view);
        });

        logoutBtn.setOnAction(e -> Main.showLoginScreen());

        // ── ROOT LAYOUT ───────────────────────────────────────────────
        BorderPane root = new BorderPane();
        root.setTop(topBar);
        root.setLeft(sidebar);
        root.setCenter(contentArea);
        BorderPane.setMargin(contentArea, Insets.EMPTY);
        contentArea.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);

        Scene scene = new Scene(root, 1100, 700);
        scene.getStylesheets().add(
            ProfessorView.class.getResource("/styles.css").toExternalForm());
        return scene;
    }


    // ══════════════════════════════════════════════════════════════════
    // WELCOME SPLASH  (default content when no nav button is clicked)
    // ══════════════════════════════════════════════════════════════════

    /** Shown in the content area on first load — a simple greeting card. */
    private static VBox buildWelcomeSplash(Professor professor) {
        Label icon = new Label("👋");
        icon.setFont(Font.font(52));
        icon.setStyle(
            "-fx-effect: dropshadow(gaussian, rgba(39, 71, 144, 0.26), 16, 0, 0, 0);"
        );

        Label heading = new Label("Welcome back, Prof. " + professor.getFirstName() + "!");
        heading.setFont(Font.font("Segoe UI", FontWeight.BOLD, 24));
        heading.setTextFill(Color.web(TEXT_PRIMARY));

        Label sub = new Label("Choose a section from the sidebar to get started.");
        sub.setFont(Font.font("Segoe UI", 14));
        sub.setTextFill(Color.web(TEXT_MUTED));

        VBox splash = new VBox(14, icon, heading, sub);
        splash.setAlignment(Pos.CENTER);
        splash.setPadding(new Insets(60));
        splash.setStyle(
            "-fx-background-color: rgba(255,255,255,0.02);" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-radius: 14;" +
            "-fx-background-radius: 14;" +
            "-fx-effect: dropshadow(gaussian, rgba(0,0,0,0.30), 20, 0, 0, 6);"
        );
        return splash;
    }


    // ══════════════════════════════════════════════════════════════════
    // PENDING APPOINTMENTS
    // ══════════════════════════════════════════════════════════════════

    /**
     * Displays all PENDING appointments for this professor in a table.
     * Each row has a ComboBox allowing the professor to update the status.
     * On status change the row is removed from the pending list.
     */
    private static VBox buildPendingAppointmentsView(Professor professor){

        // ── Column: Appointment ID ──
        TableColumn<Appointment, Integer> idCol =
            new TableColumn<>("Appt ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("appointmentId"));
        idCol.setPrefWidth(70);

        // ── Column: Slot ID ──
        TableColumn<Appointment, Integer> slotCol =
            new TableColumn<>("Slot ID");
        slotCol.setCellValueFactory(new PropertyValueFactory<>("slotId"));
        slotCol.setPrefWidth(70);

        // ── Column: Reason ──
        TableColumn<Appointment, String> reasonCol = new TableColumn<>("Reason");
        reasonCol.setCellValueFactory(cellData ->
            new SimpleStringProperty(cellData.getValue().getReason().toString()));
        reasonCol.setPrefWidth(130);

        // ── Column: Status (colour-coded text) ──
        TableColumn<Appointment, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(cellData ->
            new SimpleStringProperty(cellData.getValue().getStatus().toString()));
        statusCol.setCellFactory(col -> buildStatusCell());
        statusCol.setPrefWidth(100);

        // ── Column: Booked At ──
        TableColumn<Appointment, String> createdCol =
            new TableColumn<>("Booked At");
        createdCol.setCellValueFactory(cellData ->
            new SimpleStringProperty(
                cellData.getValue().getCreatedAt().toString()));
        createdCol.setPrefWidth(140);

        // ── Column: Note ──
        TableColumn<Appointment, String> noteCol = new TableColumn<>("Note");
        noteCol.setCellValueFactory(cellData ->
            new SimpleStringProperty(cellData.getValue().getNote()));
        noteCol.setPrefWidth(140);

        // ── Column: Status Update ComboBox ──
        // Renders a styled dropdown in every row. On selection the service
        // is called and, if successful, the row is removed from the table.
        TableColumn<Appointment, AppointmentStatus> actionCol =
            new TableColumn<>("Update Status");
        actionCol.setPrefWidth(150);

        actionCol.setCellFactory(col -> new TableCell<>() {

            // ComboBox is created once per cell and reused
            private final ComboBox<AppointmentStatus> combo = new ComboBox<>();

            {
                // Populate with all possible statuses
                combo.getItems().addAll(
                    AppointmentStatus.PENDING,
                    AppointmentStatus.APPROVED,
                    AppointmentStatus.REJECTED,
                    AppointmentStatus.WAITLISTED
                );
                // Apply the global combo-box dark style
                styleComboBox(combo);

                combo.setOnAction(e -> {
                    Appointment appt = getTableView().getItems().get(getIndex());
                    AppointmentStatus selected = combo.getValue();

                    AppointmentService service = new AppointmentService();
                    boolean success = service.updateAppointmentStatus(
                        appt.getAppointmentId(), selected);

                    if (success) {
                        appt.setStatus(selected);
                        getTableView().refresh();
                        // Remove from pending list if no longer PENDING
                        if (selected != AppointmentStatus.PENDING) {
                            getTableView().getItems().remove(appt);
                        }
                    }
                });
            }

            @Override
            protected void updateItem(AppointmentStatus status, boolean empty) {
                super.updateItem(status, empty);
                if (empty) { setGraphic(null); }
                else        { combo.setValue(status); setGraphic(combo); }
            }
        });

        // ── Build & populate table ──
        TableView<Appointment> table = buildStyledTable();
        table.getColumns().addAll(
            idCol, slotCol, reasonCol, statusCol, createdCol, noteCol, actionCol);

        AppointmentService service = new AppointmentService();
        table.getItems().setAll(
            service.getPendingAppointmentsForProfessor(professor.getUserId()));

        return wrapInCard("📋  Pending Requests", table,
            table.getItems().size() + " pending appointment(s)");
    }


    // ══════════════════════════════════════════════════════════════════
    // PAST SLOTS (read-only)
    // ══════════════════════════════════════════════════════════════════

    /** Shows all past time slots in a read-only table. */
    private static VBox buildPastWeekSlotsView(Professor professor) {

        TableColumn<TimeSlot, Integer> idCol = new TableColumn<>("Slot ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("slotID"));
        idCol.setPrefWidth(70);

        TableColumn<TimeSlot, String> dateCol = new TableColumn<>("Date");
        dateCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getSlotDate().toString()));
        dateCol.setPrefWidth(120);

        TableColumn<TimeSlot, String> startCol = new TableColumn<>("Start");
        startCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getStartTime().toString()));
        startCol.setPrefWidth(100);

        TableColumn<TimeSlot, String> endCol = new TableColumn<>("End");
        endCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getEndTime().toString()));
        endCol.setPrefWidth(100);

        TableColumn<TimeSlot, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getStatus().toString()));
        statusCol.setCellFactory(col -> buildSlotStatusCell());
        statusCol.setPrefWidth(110);

        TableView<TimeSlot> table = buildStyledTable();
        table.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        VBox.setVgrow(table, Priority.ALWAYS);
        table.getColumns().addAll(idCol, dateCol, startCol, endCol, statusCol);

        TimeSlotService service = new TimeSlotService();
        table.getItems().setAll(
            service.getProfessorPastSlots(professor.getUserId()));

        return wrapInCard("🗂  Past Slots", table,
            table.getItems().size() + " past slot(s)");
    }


    // ══════════════════════════════════════════════════════════════════
    // UPCOMING SLOTS
    // ══════════════════════════════════════════════════════════════════

    /** Shows all future time slots. */
    private static VBox buildUpcomingSlotsView(Professor professor) {

        TableColumn<TimeSlot, Integer> idCol = new TableColumn<>("Slot ID");
        idCol.setCellValueFactory(new PropertyValueFactory<>("slotID"));
        idCol.setPrefWidth(70);

        TableColumn<TimeSlot, String> dateCol = new TableColumn<>("Date");
        dateCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getSlotDate().toString()));
        dateCol.setPrefWidth(120);

        TableColumn<TimeSlot, String> startCol = new TableColumn<>("Start");
        startCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getStartTime().toString()));
        startCol.setPrefWidth(100);

        TableColumn<TimeSlot, String> endCol = new TableColumn<>("End");
        endCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getEndTime().toString()));
        endCol.setPrefWidth(100);

        TableColumn<TimeSlot, String> statusCol = new TableColumn<>("Status");
        statusCol.setCellValueFactory(c ->
            new SimpleStringProperty(c.getValue().getStatus().toString()));
        statusCol.setCellFactory(col -> buildSlotStatusCell());
        statusCol.setPrefWidth(110);

        TableView<TimeSlot> table = buildStyledTable();
        table.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        VBox.setVgrow(table, Priority.ALWAYS);
        table.getColumns().addAll(idCol, dateCol, startCol, endCol, statusCol);

        TimeSlotService service = new TimeSlotService();
        table.getItems().setAll(
            service.getProfessorUpcomingSlots(professor.getUserId()));

        return wrapInCard("📅  Upcoming Slots", table,
            table.getItems().size() + " upcoming slot(s)");
    }


    // ══════════════════════════════════════════════════════════════════
    // WAITLIST MANAGEMENT
    // ══════════════════════════════════════════════════════════════════

    /**
     * Slot selector dropdown + waitlist table.
     * Selecting a slot from the ComboBox would load its waitlist entries.
     */
    private static VBox buildWaitlistManagementView(Professor professor) {

        // ── Slot selector ──
        Label slotLabel = new Label("Select Slot:");
        slotLabel.setFont(Font.font("Segoe UI", FontWeight.BOLD, 13));
        slotLabel.setTextFill(Color.web(INDIGO_LIGHT));

        ComboBox<TimeSlot> slotSelector = new ComboBox<>();
        slotSelector.setPromptText("Choose an upcoming slot…");
        slotSelector.setPrefWidth(300);
        slotSelector.setPrefHeight(40);
        styleComboBox(slotSelector);

        // Load upcoming slots into selector
        TimeSlotService timeSlotService = new TimeSlotService();
        slotSelector.getItems().addAll(
            timeSlotService.getProfessorUpcomingSlots(professor.getUserId()));

        HBox selectorRow = new HBox(12, slotLabel, slotSelector);
        selectorRow.setAlignment(Pos.CENTER_LEFT);
        selectorRow.setPadding(new Insets(12, 14, 12, 14));
        selectorRow.setStyle(
            "-fx-background-color: rgba(39,70,144,0.07);" +
            "-fx-border-color: rgba(39,70,144,0.15);" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;"
        );

        // ── Waitlist table ──
        TableView<WaitlistEntry> waitlistTable = buildStyledTable();
        waitlistTable.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        VBox.setVgrow(waitlistTable, Priority.ALWAYS);
        // (columns would be added here in a full implementation)

        // ── Info label shown when no slot selected ──
        Label placeholder = new Label("Select a slot above to view its waitlist.");
        placeholder.setTextFill(Color.web(TEXT_MUTED));
        placeholder.setFont(Font.font("Segoe UI", 14));

        // Container card
        VBox card = new VBox(18);
        card.getChildren().addAll(buildCardHeader("⏳  Waitlist Management", ""),
                                  selectorRow, placeholder, waitlistTable);
        card.setPadding(new Insets(24));
        applyCardStyle(card);
        return card;
    }


    // ══════════════════════════════════════════════════════════════════
    // GENERATE / MANAGE SLOTS
    // ══════════════════════════════════════════════════════════════════

    /**
     * Provides a "Manual Insert" button that opens the slot dialog.
     * Additional template/bulk-generation controls would live here.
     */
    private static VBox buildGenerateSlotsView(Professor professor) {

        // ── Manual insert button ──
        Button manualInsertBtn = new Button("＋  Manually Insert Custom Slot");
        manualInsertBtn.setFont(Font.font("Segoe UI", FontWeight.BOLD, 13));
        manualInsertBtn.setPrefHeight(44);
        manualInsertBtn.setPrefWidth(280);
        // Use the primary action button style from CSS
        manualInsertBtn.getStyleClass().add("action-button-primary");
        // Java-side style since inline-style overrides may be needed
        manualInsertBtn.setStyle(
            "-fx-background-color: linear-gradient(to right," + INDIGO + ",#576CA8);" +
            "-fx-text-fill: white;" +
            "-fx-font-size: 13;" +
            "-fx-font-weight: bold;" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-padding: 10 22;" +
            "-fx-effect: dropshadow(gaussian, rgba(39,70,144,0.30), 10, 0, 0, 3);"
        );

        manualInsertBtn.setOnMouseEntered(e -> manualInsertBtn.setStyle(
            "-fx-background-color: linear-gradient(to right,#576CA8,#7B93C4);" +
            "-fx-text-fill: white;" +
            "-fx-font-size: 13;" +
            "-fx-font-weight: bold;" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-padding: 10 22;" +
            "-fx-effect: dropshadow(gaussian, rgba(39,70,144,0.45), 14, 0, 0, 5);"
        ));
        manualInsertBtn.setOnMouseExited(e -> manualInsertBtn.setStyle(
            "-fx-background-color: linear-gradient(to right," + INDIGO + ",#576CA8);" +
            "-fx-text-fill: white;" +
            "-fx-font-size: 13;" +
            "-fx-font-weight: bold;" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-padding: 10 22;" +
            "-fx-effect: dropshadow(gaussian, rgba(39,70,144,0.30), 10, 0, 0, 3);"
        ));

        manualInsertBtn.setOnAction(e -> showManualInsertDialog(professor));

        // ── Description text ──
        Label desc = new Label(
            "Manually create a custom time slot for students to book.\n" +
            "Specify the date, start time, and end time.");
        desc.setTextFill(Color.web(TEXT_MUTED));
        desc.setFont(Font.font("Segoe UI", 13));
        desc.setWrapText(true);

        VBox card = new VBox(18);
        card.setFillWidth(true);
        card.getChildren().addAll(
            buildCardHeader("✨  Slot Management", "Create and manage your availability"),
            desc,
            manualInsertBtn
        );
        card.setPadding(new Insets(24));
        applyCardStyle(card);
        card.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        return card;
    }


    // ══════════════════════════════════════════════════════════════════
    // MANUAL SLOT DIALOG
    // ══════════════════════════════════════════════════════════════════

    /**
     * Opens a styled dialog with Date + Start/End time fields.
     * On "Save Slot" the dialog returns a new TimeSlot object.
     * (Saving to the DB is left to the calling controller / service.)
     */
    private static void showManualInsertDialog(Professor professor) {

        Dialog<TimeSlot> dialog = new Dialog<>();
        dialog.setTitle("New Time Slot");
        dialog.setHeaderText("Create a Custom Slot");

        // Apply dark theme to the dialog pane via CSS class
        dialog.getDialogPane().getStyleClass().add("dialog-pane");
        // Re-apply the stylesheet since dialogs get a new window
        dialog.getDialogPane().getStylesheets().add(
            ProfessorView.class.getResource("/styles.css").toExternalForm());

        ButtonType saveButtonType =
            new ButtonType("Save Slot", ButtonBar.ButtonData.OK_DONE);
        dialog.getDialogPane().getButtonTypes().addAll(saveButtonType, ButtonType.CANCEL);

        // ── Form layout ──
        GridPane grid = new GridPane();
        grid.setHgap(14);
        grid.setVgap(14);
        grid.setPadding(new Insets(20, 20, 10, 20));

        // Date picker
        Label dateLabel = styledDialogLabel("Date:");
        DatePicker datePicker = new DatePicker();
        datePicker.setPrefWidth(220);
        datePicker.setPrefHeight(40);
        datePicker.getStyleClass().add("date-picker");

        // Start time field
        Label startLabel = styledDialogLabel("Start Time:");
        TextField startTimeField = new TextField("09:00");
        startTimeField.setPrefWidth(220);
        startTimeField.setPrefHeight(40);
        styleDialogTextField(startTimeField);

        // End time field
        Label endLabel = styledDialogLabel("End Time:");
        TextField endTimeField = new TextField("09:30");
        endTimeField.setPrefWidth(220);
        endTimeField.setPrefHeight(40);
        styleDialogTextField(endTimeField);

        // Place labels in col 0, controls in col 1
        grid.add(dateLabel,      0, 0); grid.add(datePicker,    1, 0);
        grid.add(startLabel,     0, 1); grid.add(startTimeField, 1, 1);
        grid.add(endLabel,       0, 2); grid.add(endTimeField,   1, 2);

        dialog.getDialogPane().setContent(grid);

        // ── Result converter ──
        dialog.setResultConverter(btn -> {
            if (btn == saveButtonType) {
                return new TimeSlot(
                    datePicker.getValue(),
                    professor.getUserId(),
                    java.time.LocalTime.parse(startTimeField.getText()),
                    java.time.LocalTime.parse(endTimeField.getText())
                );
            }
            return null;
        });

        dialog.showAndWait();
        // The returned TimeSlot would be saved via TimeSlotService here
    }


    // ══════════════════════════════════════════════════════════════════
    // PRIVATE STYLE HELPERS
    // ══════════════════════════════════════════════════════════════════

    // ── Sidebar navigation button ─────────────────────────────────────
    /**
     * Creates a sidebar nav button with hover highlight.
     * Default: transparent background, muted text.
     * Hover: semi-transparent indigo pill.
     */
    private static Button createSidebarButton(String text) {
        Button btn = new Button(text);
        btn.setMaxWidth(Double.MAX_VALUE);
        btn.setPrefHeight(42);
        btn.setFont(Font.font("Segoe UI", 13));
        btn.setAlignment(Pos.CENTER_LEFT);
        btn.setStyle(buildSidebarBtnStyle(false));   // inactive style

        // Hover effects
        btn.setOnMouseEntered(e ->
            btn.setStyle(buildSidebarBtnStyle(true)));
        btn.setOnMouseExited(e ->
            btn.setStyle(buildSidebarBtnStyle(false)));
        

        return btn;
    }

    /** Builds the CSS string for a sidebar button's current state. */
    private static String buildSidebarBtnStyle(boolean hovered) {
        if (hovered) {
            return "-fx-background-color: rgba(39,70,144,0.20);" +
                   "-fx-text-fill: #8FA8D0;" +
                   "-fx-font-size: 13;" +
                   "-fx-font-weight: 600;" +
                   "-fx-padding: 10 16;" +
                   "-fx-background-radius: 8;" +
                   "-fx-cursor: hand;" +
                   "-fx-alignment: CENTER_LEFT;";
        } else {
            return "-fx-background-color: transparent;" +
                   "-fx-text-fill: #94A3B8;" +
                   "-fx-font-size: 13;" +
                   "-fx-font-weight: 600;" +
                   "-fx-padding: 10 16;" +
                   "-fx-background-radius: 8;" +
                   "-fx-cursor: hand;" +
                   "-fx-alignment: CENTER_LEFT;";
        }
    }

    /** Style for the "active" sidebar button (currently selected section). */
    private static String buildSidebarBtnActiveStyle() {
        return "-fx-background-color: rgba(39,70,144,0.30);" +
               "-fx-text-fill: " + INDIGO_LIGHT + ";" +
               "-fx-font-size: 13;" +
               "-fx-font-weight: bold;" +
               "-fx-padding: 10 16 10 13;" +    // 3px indent to make room for left border
               "-fx-background-radius: 8;" +
               "-fx-cursor: hand;" +
               "-fx-alignment: CENTER_LEFT;" +
               "-fx-border-color: " + INDIGO + " transparent transparent transparent;" +
               "-fx-border-width: 0 0 0 3;" +
               "-fx-border-radius: 0;";
    }

    /**
     * Updates sidebar button visual state:
     *   activeBtn → active style
     *   all others → inactive style
     */
    private static void setActiveSidebarButton(Button active, Button... others) {
        active.setStyle(buildSidebarBtnActiveStyle());
        // Re-attach hover handlers for the newly active button (optional UX choice)
        for (Button btn : others) {
            btn.setStyle(buildSidebarBtnStyle(false));
            btn.setOnMouseEntered(e -> btn.setStyle(buildSidebarBtnStyle(true)));
            btn.setOnMouseExited(e  -> btn.setStyle(buildSidebarBtnStyle(false)));
        }
    }

    // ── Logout button (danger-red tinted) ─────────────────────────────
    private static Button createLogoutButton(String text) {
        Button btn = new Button(text);
        btn.setMaxWidth(Double.MAX_VALUE);
        btn.setPrefHeight(42);
        btn.setFont(Font.font("Segoe UI", FontWeight.BOLD, 13));
        btn.setAlignment(Pos.CENTER_LEFT);
        btn.setStyle(
            "-fx-background-color: rgba(239,68,68,0.12);" +
            "-fx-text-fill: #FCA5A5;" +
            "-fx-padding: 10 16;" +
            "-fx-background-radius: 8;" +
            "-fx-border-color: rgba(239,68,68,0.22);" +
            "-fx-border-width: 1;" +
            "-fx-border-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-alignment: CENTER_LEFT;"
        );
        btn.setOnMouseEntered(e -> btn.setStyle(
            "-fx-background-color: rgba(239,68,68,0.22);" +
            "-fx-text-fill: #FECACA;" +
            "-fx-padding: 10 16;" +
            "-fx-background-radius: 8;" +
            "-fx-border-color: rgba(239,68,68,0.35);" +
            "-fx-border-width: 1;" +
            "-fx-border-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-alignment: CENTER_LEFT;" +
            "-fx-effect: dropshadow(gaussian, rgba(239,68,68,0.20), 6, 0, 0, 0);"
        ));
        btn.setOnMouseExited(e -> btn.setStyle(
            "-fx-background-color: rgba(239,68,68,0.12);" +
            "-fx-text-fill: #FCA5A5;" +
            "-fx-padding: 10 16;" +
            "-fx-background-radius: 8;" +
            "-fx-border-color: rgba(239,68,68,0.22);" +
            "-fx-border-width: 1;" +
            "-fx-border-radius: 8;" +
            "-fx-cursor: hand;" +
            "-fx-alignment: CENTER_LEFT;"
        ));
        return btn;
    }

    // ── Small uppercase section label in the sidebar ──────────────────
    private static Label createSidebarSectionLabel(String text) {
        Label lbl = new Label(text);
        lbl.setFont(Font.font("Segoe UI", FontWeight.BOLD, 10));
        lbl.setTextFill(Color.web("#475569"));
        lbl.setPadding(new Insets(14, 0, 4, 16));
        return lbl;
    }

    // ── Card header (title + subtitle row) ───────────────────────────
    private static VBox buildCardHeader(String title, String subtitle) {
        Label titleLabel = new Label(title);
        titleLabel.setFont(Font.font("Segoe UI", FontWeight.BOLD, 20));
        titleLabel.setTextFill(Color.web(TEXT_PRIMARY));

        VBox header = new VBox(4, titleLabel);

        if (subtitle != null && !subtitle.isEmpty()) {
            Label sub = new Label(subtitle);
            sub.setFont(Font.font("Segoe UI", 13));
            sub.setTextFill(Color.web(TEXT_MUTED));
            header.getChildren().add(sub);
        }

        return header;
        
    }

    // ── Wrap a table inside a full content card ───────────────────────
    /**
     * Convenience: creates the card VBox, adds header + table,
     * and returns the styled container.
     */
    private static VBox wrapInCard(String title, TableView<?> table, String subtitle) {
        VBox card = new VBox(16);
        card.getChildren().addAll(buildCardHeader(title, subtitle), table);
        card.setPadding(new Insets(24));
        applyCardStyle(card);
        VBox.setVgrow(table, Priority.ALWAYS);
        table.setMaxWidth(Double.MAX_VALUE);
        table.setMaxHeight(Double.MAX_VALUE);
        VBox.setVgrow(card, Priority.ALWAYS);
        card.setMaxWidth(Double.MAX_VALUE);
        card.setMaxHeight(Double.MAX_VALUE);
        return card;
    }

    // ── Apply the glass-card background style to any VBox ─────────────
    private static void applyCardStyle(VBox card) {
        card.setFillWidth(true);
        card.setStyle(
            "-fx-background-color: rgba(255,255,255,0.025);" +
            "-fx-border-color: " + BORDER + ";" +
            "-fx-border-width: 1;" +
            "-fx-border-radius: 14;" +
            "-fx-background-radius: 14;" +
            "-fx-effect: dropshadow(gaussian, rgba(0,0,0,0.35), 20, 0, 0, 6);"
        );
    }

    // ── Build a blank styled TableView ───────────────────────────────
    /** Returns an empty TableView with the global dark-table style applied. */
    private static <T> TableView<T> buildStyledTable() {
        TableView<T> table = new TableView<>();
        table.setMaxSize(Double.MAX_VALUE, Double.MAX_VALUE);
        VBox.setVgrow(table, Priority.ALWAYS);
        table.setColumnResizePolicy(TableView.CONSTRAINED_RESIZE_POLICY);
        // CSS in styles.css handles .table-view, .table-row-cell, etc.
        // The Java-side style below ensures the outer background is dark.
        table.setStyle(
            "-fx-background-color: transparent;" +
            "-fx-border-color: rgba(255,255,255,0.07);" +
            "-fx-border-radius: 10;" +
            "-fx-padding: 0;"
        );
        return table;
    }


    // ── Colour-coded status cell for Appointment tables ───────────────
    /**
     * Returns a TableCell that colours the status text based on value:
     *   APPROVED → green  |  REJECTED → red
     *   PENDING → amber   |  WAITLISTED → blue
     */
    private static TableCell<Appointment, String> buildStatusCell() {
        return new TableCell<>() {
            @Override
            protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty || item == null) {
                    setText(null); setStyle("");
                } else {
                    setText(item);
                    setStyle("-fx-font-weight: bold; -fx-text-fill: " + statusColor(item) + ";");
                }
            }
        };
    }

    // ── Colour-coded status cell for TimeSlot tables ──────────────────
    private static TableCell<TimeSlot, String> buildSlotStatusCell() {
        return new TableCell<>() {
            @Override
            protected void updateItem(String item, boolean empty) {
                super.updateItem(item, empty);
                if (empty || item == null) {
                    setText(null); setStyle("");
                } else {
                    setText(item);
                    setStyle("-fx-font-weight: bold; -fx-text-fill: " + slotStatusColor(item) + ";");
                }
            }
        };
    }

    /** Maps appointment status strings to their palette colour. */
    private static String statusColor(String status) {
        return switch (status) {
            case "APPROVED"   -> SUCCESS;
            case "REJECTED"   -> DANGER;
            case "PENDING"    -> AMBER;
            case "WAITLISTED" -> BLUE;
            default           -> TEXT_PRIMARY;
        };
    }

    /** Maps slot status strings to their palette colour. */
    private static String slotStatusColor(String status) {
        return switch (status) {
            case "AVAILABLE"   -> "#2DD4BF";   // Teal
            case "BOOKED"      -> INDIGO_LIGHT;
            case "CANCELLED"   -> DANGER;
            case "COMPLETED"   -> TEXT_MUTED;
            default            -> TEXT_PRIMARY;
        };
    }

    // ── Style a ComboBox with the dark-glass palette ──────────────────
    private static <T> void styleComboBox(ComboBox<T> combo) {
        combo.setStyle(
            "-fx-background-color: rgba(255,255,255,0.05);" +
            "-fx-border-color: rgba(87,108,168,0.25);" +
            "-fx-border-width: 1.5;" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;" +
            "-fx-text-fill: #CBD5E1;" +
            "-fx-font-size: 13;"
        );
    }

    // ── Dialog label style ────────────────────────────────────────────
    private static Label styledDialogLabel(String text) {
        Label lbl = new Label(text);
        lbl.setFont(Font.font("Segoe UI", FontWeight.BOLD, 13));
        lbl.setTextFill(Color.web(INDIGO_LIGHT));
        return lbl;
    }

    // ── Dialog text-field style ───────────────────────────────────────
    private static void styleDialogTextField(TextField tf) {
        tf.setStyle(
            "-fx-background-color: rgba(255,255,255,0.06);" +
            "-fx-border-color: rgba(87,108,168,0.30);" +
            "-fx-border-width: 1.5;" +
            "-fx-border-radius: 8;" +
            "-fx-background-radius: 8;" +
            "-fx-text-fill: #E2E8F0;" +
            "-fx-prompt-text-fill: #475569;" +
            "-fx-font-size: 13;" +
            "-fx-padding: 9 12;"
        );
    }
}
