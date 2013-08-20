@isTest
public class SObjectWorkQueue_Batch_Test {
	
    @isTest
    private static void execute() {
        
        // Setup
        SObjectWorkQueue_Batch workerBatch = new SObjectWorkQueue_Batch();
        
        // Execute
        Test.startTest();
        Database.executeBatch(workerBatch);
        Test.stopTest();
        
        // Verify
        Boolean thisLineWillBeReached = true;
        System.assert(thisLineWillBeReached);
    }
    
    
    @isTest
    private static void startsOnNewWorkInOrderOfCreation() {
        
        // Setup
        List<SObjectWork__c> insertedRecords = insertWorkInSequence(3);
        
        // Execute
        SObjectWorkQueue_Batch workerBatch = new SObjectWorkQueue_Batch();
        List<SObjectWork__c> returnedRecords = workerBatch.start(null);       
         
        // Verify
        System.assertEquals(insertedRecords.size(), returnedRecords.size());
        
        for(Integer i=0; i<insertedRecords.size(); i++) {
            Id expectedId = insertedRecords.get(i).Id;
            Id actualId = returnedRecords.get(i).Id;
            
            System.assertEquals(expectedId, actualId);
        }
    }
    
    
    @isTest
    private static void failedWorkIsNotReturned() {
        
        // Setup
        final Integer NEW_RECORDS = 3;
        insertFailedWorkRecords(2);
        insertWorkInSequence(NEW_RECORDS);
        insertFailedWorkRecords(1);
        
        // Execute
        SObjectWorkQueue_Batch workerBatch = new SObjectWorkQueue_Batch();
        List<SObjectWork__c> returnedRecords = workerBatch.start(null);       
         
        // Verify
        System.assertEquals(NEW_RECORDS, returnedRecords.size());
        
        for(SObjectWork__c record : returnedRecords) {
            System.assertEquals(SObjectWork.State.QUEUED.name(), record.pkl_CurrentState__c);
        }
    }
    
    
    @isTest
    private static void restartsIfNewWorkExistOnFinish() {
        
        // Setup
        List<SObjectWork__c> oldWork = insertWorkInSequence(3);
        SObjectWorkQueue_Batch workerBatch = new SObjectWorkQueue_Batch();
        workerBatch.execute(null, oldWork);
        
        
        // Execute
        Test.startTest();
        List<SObjectWork__c> newWork = insertWorkInSequence(3);
        workerBatch.finish(null); 
        Test.stopTest();      
         
         
        // Verify
        Integer countNewWork = [SELECT COUNT() FROM SObjectWork__c WHERE pkl_CurrentState__c = :SObjectWork.State.QUEUED.name()];
        Boolean newWorkWasProcessedByRestartedBatch = (countNewWork == 0);
        System.assert(newWorkWasProcessedByRestartedBatch);
    }
    
    
    // TEST HELPER
    
    private static List<SObjectWork__c> insertWorkInSequence(Integer howMany) {
        List<SObjectWork__c> resultList = new List<SObjectWork__c>();
        
        
        for(Integer i=0; i<howMany; i++) {
            SObjectWork__c record = newSObjectWorkRecord();
            insert record;
            
            resultList.add(record);
        }
        
        return resultList;
    }
    
    
    private static List<SObjectWork__c> insertFailedWorkRecords(Integer howMany) {
        List<SObjectWork__c> resultList = new List<SObjectWork__c>();

        SObjectWork__c record = newSObjectWorkRecord();
        record.pkl_CurrentState__c = SObjectWork.State.FAILED.name();
        record.ltxt_FailedWithException__c = 'Exception text';
        record.txt_LastSuccessfulId__c = SObjectWorkTestHelper.createListOfSameIds(1).get(0);
        
        for(Integer i=0; i<howMany; i++) {
            resultList.add(record.clone());
        }
        insert resultList;
        
        return resultList;
    }

    
    private static SObjectWork__c newSObjectWorkRecord() {
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
        
        SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('SetAmount', 666);
        
        SObjectWork work = new SObjectWork.Builder(ids, processor).withParams(paramsMap).build();
        
        return SObjectWorkSerializer.toOneOrMoreSObjectRecords(work).get(0);
    }
}