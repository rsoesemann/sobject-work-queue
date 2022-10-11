@isTest
private class SObjectWorkSerializer_Test {
			
	@isTest
	private static void createsOneRecordWhenIdsFit() {
		
		// Setup
		final Integer FIT_INTO_FIELD = SObjectWorkSerializer.MAX_IDS_PER_LTXT;
		final List<Id> ids = SObjectWorkTestHelper.createListOfSameIds(FIT_INTO_FIELD);
	    SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
	    
		SObjectWork work = new SObjectWork.Builder(ids, processor).build();
		
		
		// Execute
		List<SObjectWork__c> records = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
		
		
		// Verify
		System.assertEquals(1, records.size(), 'SObjectWork__c records');
	}
	
		
	@isTest
	private static void createsMultipleRecordWhenIdsDontFit() {
		
		// Setup
		final Integer DONT_FIT_INTO_FIELD = SObjectWorkSerializer.MAX_IDS_PER_LTXT + 1;
		final List<Id> ids = SObjectWorkTestHelper.createListOfSameIds(DONT_FIT_INTO_FIELD);
	    SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
	    
		SObjectWork work = new SObjectWork.Builder(ids, processor).build();
		
		
		// Execute
		List<SObjectWork__c> records = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
		
		
		// Verify
		System.assertEquals(2, records.size(), 'SObjectWork__c records');
	}
	
	
	@isTest
	private static void recordIdsAreCorrectlySerialized() {
		
		// Setup
		final String idsAsString = 'a0Cd000000COKdj,a0Cd000000COKdk,a0Cd000000COKdp';
		final List<Id> ids = (List<Id>) idsAsString.split(',');
	    SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
	    
		SObjectWork work = new SObjectWork.Builder(ids, processor).build();
		
		
		// Execute
		List<SObjectWork__c> records = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
		
		
		// Verify
		System.assertEquals(1, records.size(), 'SObjectWork__c records');
		SObjectWork__c oneAndOnlyRecord = records.get(0);
		assertEqualsIgnoreCaseSafety(idsAsString, oneAndOnlyRecord.ltxt_SobjectIds__c);
	}
	
	
	@isTest
	private static void parametersAreCorrectlySerialized() {
		
		// Setup
		final List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(5);
	    SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
	    
	    Map<String, Object> originalParams = new Map<String, Object>();
		originalParams.put('Name', 'Robert');
		originalParams.put('Age', 36);
		originalParams.put('ContactId', SObjectWorkTestHelper.createListOfValidIds(1).get(0));
		
		SObjectWork work = new SObjectWork.Builder(ids, processor).withParams(originalParams).build();
		
		
		// Execute
		List<SObjectWork__c> records = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
        System.assertNotEquals(0, records.size());
		SObjectWork deserializedWork = SObjectWorkDeserializer.toObject(records.get(0));
		
		
		// Verify
		System.assertNotEquals(null, deserializedWork.parameters);
		
		Map<String, Object> deserializedParams = deserializedWork.parameters;
		for(String key : deserializedWork.parameters.keySet()) {
			System.assertEquals(originalParams.get(key), deserializedWork.parameters.get(key), 'Parameter ' + key);
		}
	}
	
	
	@isTest
	private static void sObjectParametersMustBeHandledManually() {
		
		// Setup
		final List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(5);
	    SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
	    
		Account a = new Account(Name='Acme Corp');
		insert a;
	    Map<String, Object> originalParams = new Map<String, Object>();
		originalParams.put('SObject', JSON.serialize(a));
		
		SObjectWork work = new SObjectWork.Builder(ids, processor).withParams(originalParams).build();
		
		
		// Execute
		List<SObjectWork__c> records = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
        System.assertNotEquals(0, records.size());
		SObjectWork deserializedWork = SObjectWorkDeserializer.toObject(records.get(0));
		
		
		// Verify
		System.assertNotEquals(null, deserializedWork.parameters);
		String aJSON = (String) deserializedWork.parameters.get('SObject');
		Account aRestored = (Account) JSON.deserialize(aJSON, Account.class);
		System.assertEquals(a.Name, aRestored.Name);
	}
	
	
    // TEST HELPER
    
    private static void assertEqualsIgnoreCaseSafety(String idCsv, String otherIdCsv) {
        List<Id> idList = idCsv.split(SObjectWorkSerializer.DELIMITER);
        List<Id> otherIdList = otherIdCsv.split(SObjectWorkSerializer.DELIMITER);
        System.assertEquals(idList.size(), otherIdList.size(), 'Id list length');
        for(Integer i=0; i<idList.size(); i++) {
         	System.assertEquals(idList.get(i), otherIdList.get(i), 'Id value');   
        }
    }
}