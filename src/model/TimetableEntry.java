package model;

public class TimetableEntry {

    private String day;
    private String startTime;
    private String endTime;
    private boolean isBusy;

    public TimetableEntry(String day, String startTime, String endTime, boolean isBusy) {
        this.day = day;
        this.startTime = startTime;
        this.endTime = endTime;
        this.isBusy = isBusy;
    }

    public String getDay() { return day; }
    public String getStartTime() { return startTime; }
    public String getEndTime() { return endTime; }
    public boolean isBusy() { return isBusy; }
}