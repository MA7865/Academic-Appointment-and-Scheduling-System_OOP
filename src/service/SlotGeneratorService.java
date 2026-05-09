package service;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import model.TimeSlot;
import model.SlotTemplate;
import dao.TimeSlotDAO; 
import java.io.InputStreamReader;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import java.util.ArrayList;


public class SlotGeneratorService {

    private TimeSlotDAO slotDAO = new TimeSlotDAO();
    private Gson gson = new Gson();

    /**
     * Reads the common_slots.json from the resources folder.
     * This provides the "templates" for the UI to display as checkboxes.
     */
    public List<SlotTemplate> getAllTemplates() {
        try (InputStreamReader reader = new InputStreamReader(
                getClass().getClassLoader().getResourceAsStream("common_slots.json"))) {
            
            return gson.fromJson(reader, new TypeToken<List<SlotTemplate>>(){}.getType());
            
        } catch (Exception e) {
            System.err.println("Error loading JSON templates: " + e.getMessage());
            return new ArrayList<>();
        }
    }

    /**
     * Takes the templates selected by the professor and creates actual 
     * database entries for the upcoming week.
     */
    public boolean generateSingleSlot(SlotTemplate temp, int professorId) {
    DayOfWeek dow = DayOfWeek.valueOf(temp.getDay().toUpperCase());
    // Correctly targets May 11, 2026 for a Monday template
    LocalDate targetDate = LocalDate.now().with(TemporalAdjusters.nextOrSame(dow));
    LocalTime start = LocalTime.parse(temp.getStartTime());
    LocalTime end = LocalTime.parse(temp.getEndTime());

    // Check for duplicates here as well, just to be safe (Defensive Programming)
    if (slotDAO.isSlotDuplicate(professorId, targetDate, start)) {
        return false; 
    }

    TimeSlot newSlot = new TimeSlot(targetDate, professorId, start, end);
    return slotDAO.addSlot(newSlot);
}
}
