public with sharing class SObjectWork {
	
	public List<Id> recordIds { get; private set; }
	public SObjectProcessor processor { get; private set; }
	public Object parameterObject { get; private set; }
	public Boolean stopOnError { get; private set; }
	
	// Note: Made default constructor private to enforce use of Builder
	private SObjectWork() {}
	
	
    // INNER CLASSES
    
    public class Builder {
    	
    	private SObjectWork work;
    	
    	
    	public Builder(List<Id> recordIds, SObjectProcessor processor) {
    		
			if(recordIds == null) {
				throw new IllegalArgumentException('Id list cannot be null.');
			}
			if(recordIds.isEmpty()) {
				throw new IllegalArgumentException('Id list cannot be empty.');
			}
			if(processor == null) {
				throw new IllegalArgumentException('SObject Processor cannot be null.');
			}
			
    		work = new SObjectWork();
			work.processor = processor;
    		work.recordIds = recordIds;
			work.processor.setRecordIds(recordIds);
			work.stopOnError = false;
    	}
    	
    	
    	public Builder withParams(Object parameterObject) {
    		if(parameterObject == null) {
    			throw new IllegalArgumentException('Parameter object cannot be null.');
    		}
    		work.parameterObject = parameterObject;
			work.processor.setParameterObject(parameterObject);
			
    		return this;
    	}
    	
    	
    	public Builder shouldStopOnError() {
    		work.stopOnError = true;
    		return this;
    	}
    	
    	
    	public SObjectWork build() {
    		return work;
    	}
    }
    
    
    public class LastSuccessfulId {
        private Id id;
        
        public void set(Id id) {
        	this.id = id;
        }
        
        public Id get() {
        	return id;
        }
    }
    
    
    public enum State {
    	QUEUED, PROCESSING, FAILED, DONE
    }
}