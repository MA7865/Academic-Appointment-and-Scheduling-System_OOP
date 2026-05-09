package model;
/**
 * This class acts as a Data Transfer Object (DTO) 
 * to map the JSON data from common_slots.json.
 */
public class SlotTemplate {
    private String day;
    private String startTime;
    private String endTime;

    // Default constructor (Required by Gson)
    public SlotTemplate() {}

    public SlotTemplate(String day, String startTime, String endTime) {
        this.day = day;
        this.startTime = startTime;
        this.endTime = endTime;
    }

    // Getters and Setters
    public String getDay() { return day; }
    public void setDay(String day) { this.day = day; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }
}
