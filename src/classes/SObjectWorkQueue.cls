// Note: Made abstract to enforce static nature
public abstract class SObjectWorkQueue {
	
	private static final Integer SINGLE_WORK_PER_BATCH = 1;
	
	
	// PUBLIC METHODS
	
	public static void addWork(SObjectWork work) {
		
		abortIfContainsCorruptedRecords(work);
		
		if(canRunSynchronously(work)) {
			runSynchronously(work);
		}
		else {
			runAsynchronously(work);
		}
	}
	
	
	
	public static Set<Id> extractIdsWithPendingWork(SObjectWork work) {
		List<String> pending = new List<String>{ SObjectWork.State.QUEUED.name(), SObjectWork.State.PROCESSING.name() };
		return findIdsWithUnfinishedWork(work, pending);
	}
		
	
	public static Set<Id> extractIdsWithFailedWork(SObjectWork work) {
		List<String> failed = new List<String>{ SObjectWork.State.FAILED.name() };
		return findIdsWithUnfinishedWork(work, failed);
	}
	
	
	// PRIVATE STATIC 
	
	private static void abortIfContainsCorruptedRecords(SObjectWork work) {
		Set<Id> idsWithFailedWork = extractIdsWithFailedWork(work);
		
		if(idsWithFailedWork.size() > 0) {
			throw new DataInconsitencyException('This operation is currently not possible due to a data inconsitency. Please contact your administrator.');
		}
	}
	
	
	private static Set<Id> findIdsWithUnfinishedWork(SObjectWork work, List<String> states) {
        Set<Id> idsWithPendingWork = new Set<Id>();
        Set<Id> potentiallyConflictingIds = new Set<Id>(work.recordIds);
        
        // Compile Set of ids of all existing work records
        for(SObjectWork__c workRecord : [SELECT ltxt_SObjectIds__c
                                         FROM SObjectWork__c
                                         WHERE pkl_CurrentState__c IN :states]) {
            // Note: Written as an ugly one-liner to save code statements                             	
        	idsWithPendingWork.addAll( new Set<Id>( (List<Id>) workRecord.ltxt_SObjectIds__c.split(',') ) );                               
        }
        
        // If this set contains any of the requested ids return true
        potentiallyConflictingIds.retainAll(idsWithPendingWork);
        
        return potentiallyConflictingIds;
    }
    
    
	private static Boolean canRunSynchronously(SObjectWork work) {
		return extractIdsWithPendingWork(work).isEmpty() 
			   && work.processor.canRunSynchronously();
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
	
	
	// INNER CLASSES
	
	public class DataInconsitencyException extends Exception {}
}