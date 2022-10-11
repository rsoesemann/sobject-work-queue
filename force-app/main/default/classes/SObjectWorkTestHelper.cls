public with sharing class SObjectWorkTestHelper {
    
    public static List<Id> createListOfValidIds(Integer howMany) {
        List<Id> ids = new List<Id>();
        
        List<Contact> arbitraryObjects = createContacts(howMany);
        insert arbitraryObjects;
        
        ids = convertToIdList(arbitraryObjects);
        
        return ids;
    }
    
    
    public static List<Id> createListOfSameIds(Integer howMany) {
        List<Id> ids = new List<Id>();
        
        Contact arbitraryObject =  createContacts(1).get(0);
        insert arbitraryObject;
        Id sameId = arbitraryObject.Id;
        
        for(Integer i=0; i<howMany; i++) {
            ids.add(sameId);
        }
        
        return ids;
    }
    
    
    public static List<Id> hugeAmountOfIds() {
    	List<Id> resultList = new List<Id>();
    	
    	Contact arbitraryObject = createContacts(1).get(0);
        insert arbitraryObject;
        Id id = arbitraryObject.Id;
        
        List<Id> hundredIds = new List<Id> {id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id,id};
        List<Id> thousandIds = new List<Id>();
        for(Integer i=0; i<10; i++) thousandIds.addAll(hundredIds.clone());
        for(Integer i=0; i<100; i++) resultList.addAll(thousandIds.clone());
        
        return resultList;
    }
    
    
    public static List<Id> convertToIdList(List<SObject> sobjects) {
        List<Id> ids = new List<Id>();
        
        for(SObject so : sobjects) {
            ids.add(so.Id);
        }
        
        return ids;
    }
    
    
    // PRIVATE METHODS
    
    private static List<Contact> createContacts(Integer howMany) {
    	List<Contact> results = new List<Contact>();
    	
    	Contact template = new Contact(FirstName='asd', LastName='adsfdfs');
    	for(Integer i=0; i<howMany; i++) {
    		results.add(template.clone());
    	}
    	
    	return results;
    }
    
    
    // Inner Classes
    
    public class ExampleSObjectProcessor implements SObjectProcessor {
        
        private List<Id> recordIds;
        private Id failOnId;
        private Decimal newAmountValue;
        private Boolean canRunSynch;
        private Boolean lockRecords;
        
        public void setRecordIds(List<Id> recordIds) {
            this.recordIds = recordIds;
        }
        
        public void setParameters(Map<String, Object> parameters) {
            failOnId = (Id) parameters.get('FailOnId');
            newAmountValue = (Decimal) parameters.get('SetAmount');
            canRunSynch = (Boolean) parameters.get('canRunSynch');
            lockRecords = (Boolean) parameters.get('lockRecords');
        }
        
        public void process(SObjectWork.LastSuccessfulId lastSuccessfulId) {
            List<Opportunity> oppsToBeProcessed = (lockRecords != null && lockRecords) ? [SELECT Amount FROM Opportunity WHERE Id IN :recordIds FOR UPDATE] 
                                                                : [SELECT Amount FROM Opportunity WHERE Id IN :recordIds];
            
            for(Opportunity opp : oppsToBeProcessed) {
                if(opp.Id == failOnId) {
                    Integer i = (Integer) opp.get('FIELD_THAT_DOESNT_EXIST');
                }
                
                opp.Amount = newAmountValue;
                lastSuccessfulId.set(opp.Id);
            }
            
            update oppsToBeProcessed;
        }
        
        public String getFullClassName() {
            return 'SObjectWorkTestHelper.ExampleSObjectProcessor'; 
        }
        
        public Boolean canRunSynchronously() {
            return (canRunSynch == null) ? false : canRunSynch;
        }
    }
}