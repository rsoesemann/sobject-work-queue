public class SchemaCache {
	private static Map<String, Schema.SObjectType> OBJECTS;
    private static Map<String, Schema.DescribesObjectResult> OBJECT_DESCRIBES;
    private static Map<String, Map<String, Schema.SObjectField>> FIELDS;
    private static Map<String, Map<String, Schema.DescribeFieldResult>> FIELD_DESCRIBES;

	/**
	 * Returns a cached map of all objects
	 */
    public static Map<String, Schema.SObjectType> objectsMap() {
    	if(OBJECTS == null) {
            OBJECTS = Schema.getGlobalDescribe();
        }
        return OBJECTS;
    }
     
    /**
     * Returns a cached map of all object describes
     */    
    public static Map<String, Schema.DescribesObjectResult> objectDescribesMap() {
    	if(OBJECT_DESCRIBES == null) {
    		OBJECT_DESCRIBES = new Map<String, Schema.DescribesObjectResult>();
	    	for(String key :Schema.getGlobalDescribe().keySet()) {
	   			OBJECT_DESCRIBES.put(key, Schema.getGlobalDescribe().get(key).getDescribe());
	   		}
        }
        return OBJECT_DESCRIBES;
    }
    
    /**
     * Returns a map of all fields for a given SobjectName
     */
    public static Map<String, Schema.SObjectField> fieldsMap(String sobjectName) {
    	if(FIELDS == null) {
            FIELDS = new Map<String, Map<String, Schema.SObjectField>>();
        }
        if(object(sobjectName) != null && FIELDS.get(sobjectName) == null) {
        	FIELDS.put(sobjectName, object(sobjectName).getDescribe().fields.getMap());
        }
        return FIELDS.get(sobjectName);
    }
    
    /**
     * Returns a map of all field describes for a given SobjectName
     */
    public static Map<String, Schema.DescribeFieldResult> fieldDescribesMap(String sobjectName) {
    	if(FIELD_DESCRIBES == null) {
            FIELD_DESCRIBES = new Map<String, Map<String, Schema.DescribeFieldResult>>();
        }
        if(object(sobjectName) != null && FIELD_DESCRIBES.get(sobjectName) == null) {
        	Map<String, Schema.DescribeFieldResult> result = new Map<String, Schema.DescribeFieldResult>();
        	
        	for(String fieldName : fieldsMap(sobjectName).keySet()) {
        		result.put(fieldName, fieldsMap(sobjectName).get(fieldName).getDescribe());
        	}
        	FIELD_DESCRIBES.put(sobjectName, result);
        }
        return FIELD_DESCRIBES.get(sobjectName);
    }
    
    /**
     * Returns an object type for a given object name
     */
   	public static Schema.SObjectType object(String sobjectName) {
   		 Schema.SObjectType result = null;
   		
   		if(objectsMap().get(sobjectName) != null) {
   			result = objectsMap().get(sobjectName);
   		}
        return result;
    }

	/**
	 * Returns an Object Describe for a given object name
	 */
   	public static Schema.DescribesObjectResult objectDescribe(String sobjectName) {
   		Schema.DescribesObjectResult result = null;
   		
   		if(object(sobjectName) != null) {
   			result = object(sobjectName).getDescribe();
   		}
        return result;
    }
        
    /**
     * Returns a field for a given object name and field name
     */
   	public static Schema.SObjectField field(String sobjectName, String fieldName) {
   		Schema.SObjectField result = null;
   		
   		if(objectsMap().get(sobjectName) != null) {
   			result = fieldsMap(sobjectName).get(fieldName);
   		}
        return result;
    }
    
    /**
     * Returns a Field Describe for a given sobjectName and fieldName
     */ 
    public static Schema.DescribeFieldResult fieldDescribe(String sobjectName, String fieldName) {
    	Schema.DescribeFieldResult result = null;
    	
    	if(field(sobjectName, fieldName) != null) {
    		result = field(sobjectName, fieldName).getDescribe();
    	}
    	
    	return result;
    }
    
    public static Map<String, Schema.SObjectField> fields(String sobjectName) {
   		Map<String, Schema.SObjectField> result = null;
   		
   		if(objectsMap().get(sobjectName) != null) {
   			result = fieldsMap(sobjectName);
   		}
        return result;
    }
    
 
    
    /**
     * Returns a map of all field describes for a given sobjectName
     */ 
    public static Map<String, Schema.DescribeFieldResult> fieldDescribes(String sobjectName) {
   		Map<String, Schema.DescribeFieldResult> result = null;
   		
   		if(objectsMap().get(sobjectName) != null) {
   			result = fieldDescribesMap(sobjectName);
   		}
   		
        return result;
    }
}