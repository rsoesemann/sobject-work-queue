// Note: Made abstract to enforce static nature
public abstract class SObjectWorkQueue {
	
	private static final Integer SINGLE_WORK_PER_BATCH = 1;
	
	
	// PUBLIC METHODS
	
	public static void addWork(SObjectWork work) {
		
		if(canRunSynchronously(work)) {
			runSynchronously(work);
		}
		else {
			runAsynchronously(work);
		}
		
		// Cleanup work records marked as DONE in a future call to not reduce limits
		removeFinishedWorkFromQueue();
	}
	
	
	public static Boolean hasPendingWorkFor(List<Id> recordIds) {
        Set<Id> idsWithPendingWork = new Set<Id>();
        Set<Id> potentiallyConflictingIds = new Set<Id>(recordIds);
        
        // Compile Set of ids of all existing work records
        for(SObjectWork__c workRecord : [SELECT ltxt_SObjectIds__c
                                         FROM SObjectWork__c
                                         WHERE pkl_CurrentState__c <> :SObjectWork.State.DONE.name()]) {
            // Note: Written as an ugly one-liner to save code statements                             	
        	idsWithPendingWork.addAll( new Set<Id>( (List<Id>) workRecord.ltxt_SObjectIds__c.split(',') ) );                               
        }
		
        // If this set contains any of the requested ids return true
        potentiallyConflictingIds.retainAll(idsWithPendingWork);
        
        return potentiallyConflictingIds.size() > 0;
    }
	
	
	// PRIVATE STATIC 
    
	private static Boolean canRunSynchronously(SObjectWork work) {
		return !hasPendingWorkFor(work.recordIds) && work.processor.canRunSynchronously();
	}
    
	
	private static void runSynchronously(SObjectWork work) {
		SObjectWork.LastSuccessfulId lastSuccessfulId = new SObjectWork.LastSuccessfulId();
		
		work.processor.process(lastSuccessfulId);
	}
	
	
	private static void runAsynchronously(SObjectWork work) {
		persistWork(work);
			
		if(noQueueWorkerRunning()) {
			startQueueWorker();
		}
	}
	
	
	private static void persistWork(SObjectWork work) {
		List<SObjectWork__c> workRecords = SObjectWorkSerializer.toOneOrMoreSObjectRecords(work);
		insert workRecords;
	}
	
	
	private static Boolean noQueueWorkerRunning() {
		Integer runningWorker = [SELECT COUNT() 
				                 FROM AsyncApexJob
								 WHERE JobType = 'BatchApex'
								 AND ApexClass.Name = 'SObjectWorkQueue_Batch'
								 AND Status IN ('Processing', 'Preparing', 'Queued' )];
								 
		return (runningWorker == 0);
	}
	
	
	private static void startQueueWorker() {
		SObjectWorkQueue_Batch worker = new SObjectWorkQueue_Batch();
		Database.executeBatch(worker, SINGLE_WORK_PER_BATCH);
	}
	
	
	@future
	private static void removeFinishedWorkFromQueue() {
		List<SObjectWork__c> workMarkedAsDone = [SELECT Id FROM SObjectWork__c WHERE pkl_CurrentState__c = :SObjectWork.State.DONE.name()];
		delete workMarkedAsDone;
	}
}