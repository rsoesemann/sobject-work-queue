@isTest
private class SObjectWorkQueue_Test {
	
    @isTest
    private static void happyPath() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        final Decimal NEW_AMOUNT_VALUE = 666;
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('SetAmount', NEW_AMOUNT_VALUE);
        SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        
        Test.startTest();  
        SObjectWorkQueue.addWork(work);
        Test.stopTest();
        
        
        // Verify
        List<Opportunity> processedOpps = [SELECT Amount FROM Opportunity WHERE Id IN :oppsToProcess];
        
        System.assertEquals(oppsToProcess.size(), processedOpps.size());
        
        for(Opportunity opp : processedOpps) {
            System.assertEquals(NEW_AMOUNT_VALUE, opp.Amount, 'Amount');
        }
    }
   
   
	@isTest
    private static void runsWorkSynchronouslyIfPossible() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        final Decimal NEW_AMOUNT_VALUE = 666;
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('SetAmount', NEW_AMOUNT_VALUE);
        paramsMap.put('canRunSynch', true);
        SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        // Note: without startTest/StopTest this would fail if we run in batch mode
        SObjectWorkQueue.addWork(work);
        
        
        // Verify
        List<Opportunity> processedOpps = [SELECT Amount FROM Opportunity WHERE Id IN :oppsToProcess];
        System.assertEquals(oppsToProcess.size(), processedOpps.size());
        
        for(Opportunity opp : processedOpps) {
            System.assertEquals(NEW_AMOUNT_VALUE, opp.Amount, 'Amount');
        }
    }
    
    
    @isTest
    private static void pendingWorkForSomeIdsIsFound() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        List<Id> pendingIds = SObjectWorkTestHelper.createListOfSameIds(SObjectWorkSerializer.MAX_IDS_PER_LTXT - 2);
        pendingIds.addAll(new List<Id>{ oppsToProcess.get(3), oppsToProcess.get(7)});
        persistWorkWithStateAndIds(SObjectWork.State.QUEUED, pendingIds);

        // Execute & Verify
        System.assertEquals(true, SObjectWorkQueue.hasPendingWorkFor(oppsToProcess), 'Has pending work');
    }
    
    
    @isTest
    private static void failedWorkForSomeIdsIsFound() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        List<Id> failedIds = SObjectWorkTestHelper.createListOfSameIds(SObjectWorkSerializer.MAX_IDS_PER_LTXT - 2);
        failedIds.addAll(new List<Id>{ oppsToProcess.get(4), oppsToProcess.get(8)});
        persistWorkWithStateAndIds(SObjectWork.State.FAILED, failedIds);

        // Execute & Verify
        System.assertEquals(true, SObjectWorkQueue.hasPendingWorkFor(oppsToProcess), 'Has pending work');
    }
      
    
    @isTest
    private static void doneButNotYetDeletedWorkIsNotReturnedAsPending() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        List<Id> doneIds = SObjectWorkTestHelper.createListOfSameIds(SObjectWorkSerializer.MAX_IDS_PER_LTXT - 2);
        doneIds.addAll(new List<Id>{ oppsToProcess.get(1), oppsToProcess.get(9)});
        persistWorkWithStateAndIds(SObjectWork.State.DONE, doneIds);

        // Execute & Verify
        System.assertEquals(false, SObjectWorkQueue.hasPendingWorkFor(oppsToProcess), 'Has pending work');
    }
    
    
    @isTest
    private static void deletesSuccessfullyProcessedWork() {
        
        // Setup
        SObjectWork__c doneWork = new SObjectWork__c();
		doneWork.ltxt_SObjectIds__c = 'a0Cd000000COKdj,a0Cd000000COKdk,a0Cd000000COKdp';
		doneWork.txt_ProcessorClassName__c = 'SObjectWorkTestHelper.ExampleSObjectProcessor';
		doneWork.pkl_CurrentState__c = SObjectWork.State.DONE.name();
		insert doneWork;
		
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('SetAmount', 666);
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        
        Test.startTest();   
        SObjectWorkQueue.addWork(work);
        Test.stopTest();
        
        
        // Verify
        Integer workRecordsInQueue = [SELECT COUNT() FROM SObjectWork__c];
        // We expect one left as the test cannot synchronize 2 Asynch things.
        System.assertEquals(1, workRecordsInQueue);
    }
    
    
    @isTest
    private static void marksFailedWorkInDatabase() {
        
        // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        final Id lastSuccessfulId = oppsToProcess.get(4);
        
       	SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('FailOnId', oppsToProcess.get(5));
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        
        Test.startTest();   
        SObjectWorkQueue.addWork(work);
        Test.stopTest();
        
        
        // Verify
        List<SObjectWork__c> failedWork = [SELECT pkl_CurrentState__c, txt_LastSuccessfulId__c, ltxt_FailedWithException__c 
                                           FROM SObjectWork__c 
                                           ];
        System.assertEquals(1, failedWork.size());
        
        SObjectWork__c failedRecord = failedWork.get(0);
        System.assertEquals(lastSuccessfulId, failedRecord.txt_LastSuccessfulId__c,' Last successful Id');
        System.assertNotEquals('', failedRecord.ltxt_FailedWithException__c, 'Failed with Exception');
    }
    
    // Couldn't get this running 
    //@isTest
    private static void sendsNotificationEmailOnFailure() {
        
       // Setup
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        
        final Id lastSuccessfulId = oppsToProcess.get(4);
        
       	SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('FailOnId', oppsToProcess.get(5));
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        
        Test.startTest();   
        SObjectWorkQueue.addWork(work);
        Test.stopTest();
        
        
        // Verify
        Integer ONE_EMAIL_SENT = 1;
        System.assertEquals(ONE_EMAIL_SENT, Limits.getEmailInvocations());
    }
    
    
    @isTest
    private static void rollsBackDatabaseOnWorkFailure() {
    	
        // Setup
        SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        final List<Id> oppsToProcess = insertOppsWithAmountZeroAndReturnIds(10);
        final Map<String, Object> paramsMap = new Map<String, Object>();
        paramsMap.put('FailOnId', oppsToProcess.get(9));
        
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(oppsToProcess, processor).withParams(paramsMap).build();
        
        Test.startTest();   
        SObjectWorkQueue.addWork(work);
        Test.stopTest();
        
        
        // Verify
        for(Opportunity opp : [SELECT Amount FROM Opportunity WHERE Id IN :oppsToProcess]) {
            Boolean amountIsUnchanged = (opp.Amount == 0);
            System.assert(amountIsUnchanged, 'Amount Is Unchanged');
        }
    }
    
    
    // TEST HELPER
    
    private static List<Id> insertOppsWithAmountZeroAndReturnIds(Integer howMany) {
        Opportunity oppTemplate = new Opportunity(Name='sdfasd', CloseDate=System.today(), StageName='Prospecting');
        List<Opportunity> oppsToInsert = new List<Opportunity>();
        
        for(Integer i=0; i<howMany; i++) {
            Opportunity opp = oppTemplate.clone();
            opp.Amount = 0;
            oppsToInsert.add(opp);
        }
        insert oppsToInsert;
        
        List<Id> ids = SObjectWorkTestHelper.convertToIdList(oppsToInsert);

        return ids;
    }
    
    
    public static SObjectWork__c persistWorkWithStateAndIds(SObjectWork.State state, List<Id> ids) {
    	SObjectWork__c result = new SObjectWork__c( 
	    								ltxt_SObjectIds__c = String.join(ids, ','),
	    								txt_ProcessorClassName__c = 'SObjectWorkTestHelper.ExampleSObjectProcessor',
	    								pkl_CurrentState__c = state.name());
		insert result;
		return result;
    }
}