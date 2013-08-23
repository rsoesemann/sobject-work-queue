public class SObjectWorkQueue_Batch implements Database.Batchable<SObjectWork__c>, Database.Stateful {

	private SObjectWork__c failedRecord;
	private SObjectWork.LastSuccessfulId lastSuccessfulId;


    public List<SObjectWork__c> start(Database.BatchableContext context) {
        return queryNewWork();
    }


    public void execute(Database.BatchableContext context, List<SObjectWork__c> scope) {
    	for(SObjectWork__c workRecord : scope) {
    		execute(workRecord);
    	}	
    }
    
    
    public void finish(Database.BatchableContext context) {
        handleFailures(context);
        
        if(hasNewWork()) {
        	restart();
        }
    }
    
    
    // PRIVATE RECORD
    
    private Boolean hasNewWork() {
        List<SObjectWork__c> newWork = queryNewWork();
    	return !newWork.isEmpty();   
    }
        
    
    private List<SObjectWork__c> queryNewWork() {
        List<SObjectWork__c> newWork = [SELECT ltxt_SObjectIds__c, txt_ProcessorClassName__c, txt_LastSuccessfulId__c, ltxt_FailedWithException__c, 
        									   pkl_CurrentState__c, ltxt_ProcessorParamsAsJSON__c
        								FROM SObjectWork__c 
        								WHERE pkl_CurrentState__c = :SObjectWork.State.QUEUED.name()
        								ORDER BY CreatedDate ASC];
        
        return newWork;
    }
    
    
    private void execute(SObjectWork__c workRecord) {
        
        Savepoint sp = Database.setSavepoint();
        
    	try {
    		markAsInProgress(workRecord);
    		completeWork(workRecord);	
    	}
    	catch(Exception anyException) {
    		Database.rollback(sp);
    		markAsFailed(workRecord, anyException);
    	}
    	markAsDone(workRecord);
    }
    
    
    private void markAsInProgress(SObjectWork__c workRecord) {
    	workRecord.pkl_CurrentState__c = SObjectWork.State.PROCESSING.name();
    	update workRecord;	
    }
    
    
    private void completeWork(SObjectWork__c workRecord) {
        SObjectWork work = SObjectWorkDeserializer.toObject(workRecord);
        lastSuccessfulId = new SObjectWork.LastSuccessfulId();
        
        work.processor.process(lastSuccessfulId);
    }

    
    private void restart() {
     	SObjectWorkQueue_Batch successor = new SObjectWorkQueue_Batch();
        Database.executeBatch(successor);
    }
    
    
    private void markAsFailed(SObjectWork__c workRecord, Exception ex) {
    	workRecord.pkl_CurrentState__c = SObjectWork.State.FAILED.name();
    	workRecord.txt_LastSuccessfulId__c = lastSuccessfulId.get();
    	workRecord.ltxt_FailedWithException__c = serializeException(ex);
    	workRecord.dtm_FailureTime__c = System.now();
    	update workRecord;
    	
    	failedRecord = workRecord;
    }
    
    
    private void markAsDone(SObjectWork__c workRecord) {
    	workRecord.pkl_CurrentState__c = SObjectWork.State.DONE.name();
    	update workRecord;
    }
    
    
    private String serializeException(Exception ex) {
    	String result = String.valueOf(ex);
    	Integer maxLength = SObjectWorkSerializer.LTXT_FIELD_LENGTH;
    	
    	if(result.length() > maxLength) {
			result = result.abbreviate(maxLength);
    	}
    	
    	return result;
    }
    
    
    private void handleFailures(Database.BatchableContext context) {
    	
    	Boolean hadFailure = (failedRecord != null);

    	if(hadFailure) {
	        String urlToFailedWork = System.URL.getSalesforceBaseUrl().toExternalForm()+'/' + failedRecord.Id;
	        String message = String.format('The following SObjectWork failed: {0}', new List<String>{urlToFailedWork});
	        
	        User triggeredByUser = [SELECT Name,Email FROM User WHERE Id = :UserInfo.getUserId()];
	        sendEmail(triggeredByUser.Email, message);
    	}
    }
    
    
    private void sendEmail(String toAddress, String message) {
    	List<String> addressList = new List<String>{ toAddress };
    	 sendEmail(addressList, message);
    }
    
    
    private void sendEmail(List<String> toAddresses, String message) {
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
    	mail.setToAddresses(toAddresses); 
    	mail.setSubject(message);  
        mail.setPlainTextBody(message);
         
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }
}