package xyz.kaspernissen.validation;

public class ValidationRequest {
    private String name;
    
    public ValidationRequest() {}
    
    public ValidationRequest(String name) {
        this.name = name;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
}