public interface SObjectProcessor {
	String getFullClassName();
	void setRecordIds(List<Id> recordIds);
	void setParameters(Map<String, Object> parameterMap);
	Boolean canRunSynchronously();
	void process(SObjectWork.LastSuccessfulId lastSuccesfulId);
}