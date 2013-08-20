// Note: Made abstract to enforce static nature
public abstract class SObjectWorkSerializer {
    
    public static final Integer LTXT_FIELD_LENGTH;
    public static final String DELIMITER = ',';
    public static final Integer MAX_IDS_PER_LTXT;
   
    private static final String RECORD_OBJECT = 'SObjectWork__c';
    private static final String ID_FIELD_NAME = 'ltxt_SObjectIds__c';
    private static final Integer ID_LENGTH = 18;
    private static final Integer LENGTH_PER_ID;
    
    static {
        LENGTH_PER_ID = ID_LENGTH + DELIMITER.length();
        LTXT_FIELD_LENGTH = getMaxLengthOfIdField();
        MAX_IDS_PER_LTXT = maxIdsPerLongTextField();
    }
    
    
    public static List<SObjectWork__c> toOneOrMoreSObjectRecords(SObjectWork work) {
        List<SObjectWork__c> records = new List<SObjectWork__c>();
        
        for(List<Id> idChunk : chunkIdListToFitIntoTextField( work.recordIds )) {
        	
            SObjectWork__c newRecord = new SObjectWork__c();
            newRecord.pkl_CurrentState__c = SObjectWork.State.QUEUED.name();
            newRecord.ltxt_SObjectIds__c = toCommaSeperatedString(idChunk);
            newRecord.txt_ProcessorClassName__c = work.processor.getFullClassName();
            
            if(work.parameterObject != null) {
            	newRecord.ltxt_ProcessorParamsAsJSON__c = serializeForLongTxtField(work.parameterObject);
            }
            
            records.add(newRecord);
        }
        
        return records;
    }
    
    
    // PRIVATE METHODS
    
    private static String toCommaSeperatedString(List<Id> ids) {
        // SObjectWork constructor checks that ids is not null or empty
        return String.join(ids, DELIMITER);
    }
    
    
    private static List<List<Id>> chunkIdListToFitIntoTextField(List<Id> allIds) {
        List<List<Id>> chunks = new List<List<Id>>();
        
        Integer chunksNeeded = chunksNeededFor(allIds);
        
        for(Integer c=1; c<=chunksNeeded; c++) {
            // Note: allIds is modified in each call
            chunks.add( removeChunk(allIds) );
        }
        return chunks;
    }
    
    
    private static String serializeForLongTxtField(Object parameterObject) {
		String result = JSON.serialize(parameterObject);
		
		if(doesntFitInLongTxtField(result)) {
			String message = String.format('Parameter object is to big to to be serialized as JSON into Long Text field : {0}', new List<String>{ String.valueOf(parameterObject) });
			throw new SerializationException(message);
		}
		
		return result;
    }
    
    
    private static Boolean doesntFitInLongTxtField(String aString) {
    	return aString.length() > LTXT_FIELD_LENGTH;
    }
      
    
    private static Integer getMaxLengthOfIdField() {
        Schema.DescribeFieldResult field = SchemaCache.fieldDescribe(RECORD_OBJECT, ID_FIELD_NAME);
        return field.getLength();
    }
    
    
    private static Integer maxIdsPerLongTextField() {
        Decimal fieldLength = Decimal.valueOf(LTXT_FIELD_LENGTH);
       	Decimal result = fieldLength.divide(LENGTH_PER_ID, 4, RoundingMode.DOWN);
        return result.intValue();
    }
    
    
    private static Integer chunksNeededFor(List<Id> ids) {
        Decimal idCount = Decimal.valueOf(ids.size());
    	Decimal result = idCount.divide(MAX_IDS_PER_LTXT, 0, System.RoundingMode.UP);
        return result.intValue();
    }
    
    
    private static List<Id> removeChunk(List<Id> ids) {
        List<Id> chunk = new List<Id>();
        
        Boolean listCannotBeChunked = ids == null || ids.isEmpty();
        if(listCannotBeChunked) {
            return new List<Id>();
        }
    
        Integer chunkLength = Math.min(ids.size(), MAX_IDS_PER_LTXT);
        for(Integer i=0; i<chunkLength; i++) {
            chunk.add(ids.remove(0));
        }
        
        return chunk;
    }

    
    public class SerializationException extends Exception {}
}