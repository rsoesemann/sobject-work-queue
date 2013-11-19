public class SObjectWorkQueue_Batch implements Database.Batchable<SObjectWork__c>, Database.Stateful {

	private SObjectWork__c failedRecord;
	private SObjectWork.LastSuccessfulId lastSuccessfulId = new SObjectWork.LastSuccessfulId();


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
        
        removeFinishedWorkFromQueue();
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
    		markAsDone(workRecord);
    	}
    	catch(Exception anyException) {
    		Database.rollback(sp);
    		markAsFailed(workRecord, anyException);
    	}
    }
    
    
    private void markAsInProgress(SObjectWork__c workRecord) {
    	workRecord.pkl_CurrentState__c = SObjectWork.State.PROCESSING.name();
    	update workRecord;	
    }
    
    
    private void completeWork(SObjectWork__c workRecord) {
        SObjectWork work = SObjectWorkDeserializer.toObject(workRecord);
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
    	String result = ex.getMessage() + '\n\n' + ex.getStackTraceString();
    	Integer maxLength = SObjectWorkSerializer.LTXT_FIELD_LENGTH;
    	
    	if(result.length() > maxLength) {
			result = result.abbreviate(maxLength);
    	}
    	
    	return result;
    }
    
    
    private void handleFailures(Database.BatchableContext context) {
    	
    	Boolean hadFailure = (failedRecord != null);

    	if(hadFailure) {
    		String org = UserInfo.getOrganizationName().trim().length() == 0 ? UserInfo.getOrganizationId() : UserInfo.getOrganizationName();
    		String user = UserInfo.getUserName().trim().length() == 0 ? UserInfo.getUserId() : UserInfo.getUserName();
    		
	        String title = String.format('{0} > {1} > {2} {3}', new List<String>{ org, user, failedRecord.txt_ProcessorClassName__c, failedRecord.pkl_CurrentState__c });
	        String urlToFailedWork = System.URL.getSalesforceBaseUrl().toExternalForm()+'/' + failedRecord.Id;
	        String body = String.format('{0} \n\n {1}', new List<String>{ urlToFailedWork, failedRecord.ltxt_FailedWithException__c });
	        
	        User triggeredByUser = [SELECT Name,Email FROM User WHERE Id = :UserInfo.getUserId()];
	        sendEmail(triggeredByUser.Email, title, body);
    	}
    }
    
    
    private void sendEmail(String toAddress, String title, String body) {
    	List<String> addressList = new List<String>{ toAddress };
    	 sendEmail(addressList, title, body);
    }
    
    
    private void sendEmail(List<String> toAddresses, String title, String body) {
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();  
    	mail.setToAddresses(toAddresses); 
    	mail.setSubject(title);  
        mail.setPlainTextBody(body);
         
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }
    
    
	private void removeFinishedWorkFromQueue() {
		List<SObjectWork__c> workMarkedAsDone = [SELECT Id FROM SObjectWork__c WHERE pkl_CurrentState__c = :SObjectWork.State.DONE.name()];
		delete workMarkedAsDone;
	}
}