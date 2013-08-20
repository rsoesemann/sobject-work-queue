public interface SObjectProcessor {
	String getFullClassName();
	void setRecordIds(List<Id> recordIds);
	void setParameterObject(Object parameterObject);
	Boolean canRunSynchronously();
	void process(SObjectWork.LastSuccessfulId lastSuccesfulId);
}