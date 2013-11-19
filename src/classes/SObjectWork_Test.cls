@isTest
private class SObjectWork_Test {

    @isTest
    private static void constructWithValidNonNullParams() {
        
        // Setup
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(ids, processor).withParam('SetAmount', 666).build();
        
        // Verify
        System.assertEquals(ids, work.recordIds);
        System.assertEquals(processor, work.processor);
        System.assertEquals(666, work.parameters.get('SetAmount'));
    }


    @isTest
    private static void constructWithEmptyParameterObject() {
        
        // Setup
        Boolean noExceptionIsThrown = true;
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(ids, processor).build();
        }
        catch(IllegalArgumentException e) {
        	noExceptionIsThrown = false;
        }
        
        // Verify
        System.assert(noExceptionIsThrown);
    }
    
    
    @isTest
    private static void constructFailsWhenPassedNullAsParameterObject() {
        
        // Setup
        Boolean expectedExceptionWasThrown = false;
        
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
		Map<String, Object> NULLMAP = null;
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(ids, processor).withParams(NULLMAP).build();
        }
        catch(IllegalArgumentException e) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown);
    }
    
        @isTest
    private static void constructFailsWhenPassedNullAsParameterValue() {
        
        // Setup
        Boolean expectedExceptionWasThrown = false;
        
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
		String NULLOBJECT = null;
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(ids, processor).withParam('key', NULLOBJECT).build();
        }
        catch(IllegalArgumentException e) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown);
    }
    
    @isTest
    private static void constructFailsWhenPassedNullAsParameterKey() {
        
        // Setup
        Boolean expectedExceptionWasThrown = false;
        
        List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
		String NULLOBJECT = null;
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(ids, processor).withParam(NULLOBJECT, 'value').build();
        }
        catch(IllegalArgumentException e) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown);
    }
        
    
    @isTest
    private static void constructWithNullIdsThrowsException() {
        
        // Setup
        Boolean expectedExceptionWasThrown = false;
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(null, processor).build();
        }
        catch(IllegalArgumentException iae) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown, 'Expected exception was not thrown.');
    }
        
    
    @isTest
    private static void constructWithEmptyIdListThrowsException() {
        
        // Setup
        Boolean expectedExceptionWasThrown = false;
        List<Id> emptyIdList = new List<Id>();
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(emptyIdList, processor).build();
        }
        catch(IllegalArgumentException iae) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown, 'Expected exception was not thrown.');
    }
    
    
    @isTest
    private static void constructWithNullProcessorThrowsException() {
        
        // Setup
       	Boolean expectedExceptionWasThrown = false;
       	List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
        
        // Execute
        try {
        	SObjectWork work = new SObjectWork.Builder(ids, null).build();
        }
        catch(IllegalArgumentException iae) {
        	expectedExceptionWasThrown = true;
        }
        
        // Verify
        System.assert(expectedExceptionWasThrown, 'Expected exception was not thrown.');
    }
        
    
    @isTest
    private static void wontStopOnErrorByDefault() {
        
        // Setup
       	List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(ids, processor).build();
        
        // Verify
        System.assertEquals(false, work.stopOnError, 'Stop on error');
    }
            
    
    @isTest
    private static void setStopOnError() {
        
        // Setup
       	List<Id> ids = SObjectWorkTestHelper.createListOfValidIds(2);
		SObjectProcessor processor = new SObjectWorkTestHelper.ExampleSObjectProcessor();
        
        // Execute
        SObjectWork work = new SObjectWork.Builder(ids, processor).shouldStopOnError().build();
        
        // Verify
        System.assertEquals(true, work.stopOnError, 'Stop on error');
    }
}