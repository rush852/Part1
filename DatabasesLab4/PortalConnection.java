
import java.sql.*; // JDBC stuff.
import java.util.Properties;

public class PortalConnection {

    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/Laboration_1";
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO Registrations VALUES (?,?)"
        );){
            ps.setString(1,student);
            ps.setString(2,courseCode);
            ps.executeUpdate();
           return "{\"success\":true\"}";
        } catch (SQLException e) {
            //e.printStackTrace();
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
        //We should use prepared statement here as well. But to be able to show an sql-injection we use createStatement instead
        String query = "DELETE FROM Registrations WHERE student = '" + student + "' AND " + "course = '" + courseCode + "'";
        try(Statement s = conn.createStatement();){
            int r = s.executeUpdate(query);
            if(r == 0){
                return "{\"success\":false, \"error\":\"student\"not\"registered\"}";
            }
            else {
            return "{\"success\":true\"}";
            }
        } catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        //"SELECT jsonb_build_object('student',idnr,'name',name) AS jsondata FROM BasicInformation WHERE idnr=?"
        try(PreparedStatement st = conn.prepareStatement(
                "SELECT (jsonb_build_object('student',idnr,'name',name,'login',login,'program',program,'branch',branch" +
                        ",'finished',(SELECT COALESCE(json_agg(jsonb_build_object('course',courses.name,'code',finishedcourses.course,'grade',finishedcourses.grade,'credits',finishedcourses.credits)),'{}') FROM finishedcourses,courses WHERE finishedcourses.student = ? AND courses.code = finishedcourses.course)" +
                        ",'registered',(SELECT COALESCE(json_agg(json_build_object('code',registrations.course,'course',courses.name,'status',status)),'{}') FROM registrations,courses WHERE student = ? AND courses.code = registrations.course)" +
                        ",'seminarCourses',seminarcourses,'mathCredits',mathcredits,'researchCredits',researchcredits,'totalCredits',totalcredits,'canGraduate',qualified))AS jsondata FROM basicinformation,pathtograduation WHERE basicinformation.idnr = ? AND pathtograduation.student = ?"
        );){

            st.setString(1, student);
            st.setString(2, student);
            st.setString(3, student);
            st.setString(4, student);

            ResultSet rs = st.executeQuery();

            if(rs.next())
                return rs.getString("jsondata");
            else
                return "{\"student\":\"does not exist :(\"}";

        }
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}