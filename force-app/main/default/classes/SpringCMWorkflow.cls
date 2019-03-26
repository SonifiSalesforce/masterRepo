public class SpringCMWorkflow {
    public String Name {set;get;}
    public String Params {set;get;}
    public String Href {set;get;}
    public String Status {set;get;}
    public String Info {set;get;}

    public SpringCMWorkflow(String thename, String theparams) {
    	Name = thename;
    	Params = theparams;
    }
}