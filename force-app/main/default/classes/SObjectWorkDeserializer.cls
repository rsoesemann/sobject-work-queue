// Note: Made abstract to enforce static nature
public abstract class SObjectWorkDeserializer {
    
    public static SObjectWork toObject(SObjectWork__c record) {
        List<Id> ids = convertToList(record.ltxt_SObjectIds__c);
        SObjectProcessor processor = getClassForName(record.txt_ProcessorClassName__c);
        Map<String, Object> paramMap = deserializeParameters(record.ltxt_ProcessorParamsAsJSON__c);

        SObjectWork result = (paramMap == null || paramMap.isEmpty()) ? new SObjectWork.Builder(ids, processor).build() 
    											  					  : new SObjectWork.Builder(ids, processor).withParams(paramMap).build();
        return result;
    }
    
    
    // PRIVATE METHODS
    
    private static List<Id> convertToList(String ids) {
    	List<Id> idList = null;
    	
    	// Throw exception if serialized id string is blank
    	Boolean idStringIsEmpty = ids == null || ids.trim() == '';
    	if(idStringIsEmpty) {
    		String message = 'No Ids in serialized work record found.';
           	throw new DeserializationException(message);
    	}
    	else {
    		List<String> stringList = ids.split(SObjectWorkSerializer.DELIMITER);
    	
	    	// Throw exception if at least on of the serialized ids cannot be casted to an Id
	    	try {
	    		idList = (List<Id>) stringList;
	    	}
	    	catch(Exception ex) {
	    		String message = String.format('Ids in serialized work could not be converted to valid Ids. Id String: {0}', new List<String>{ids});
	           	throw new DeserializationException(message, ex);
	    	}
    	}
    	
        return idList;
    }
    

    private static SObjectProcessor getClassForName(String processorClassName) {
        SObjectProcessor processor;
        
        // Throw exception if class name empty
        if(processorClassName == null || processorClassName.trim() == '') {
        	String message = String.format('Class with name {0} does not exist and could not be instantiated as Processor class.', new List<String>{processorClassName});
           	throw new DeserializationException(message);
        }
        
        try {
        	Type t = Type.forName(processorClassName);
        	processor = (SObjectProcessor) t.newInstance();
        }
        catch(Exception ex) {
        	String message = String.format('Could not cast class with name {0} to an SObjectProcessor.', new List<String>{processorClassName});
           	throw new DeserializationException(message, ex);
        }
        
        return processor;
    }
    
    
    private static Map<String, Object> deserializeParameters(String parameterJSON) {
    	Map<String, Object> parameters = null;
    	
    	if(parameterJSON != null && parameterJSON.trim().length() > 0) {
    		parameters = (Map<String, Object>) JSON.deserializeUntyped(parameterJSON);
    	}
    	
    	return parameters;
    }
    
    
    // INNER CLASSES
    
    public class DeserializationException extends Exception {}
}