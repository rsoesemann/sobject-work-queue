public class CreateRecordBatch implements Database.Batchable<Integer> {

    private SObject record;
    private Integer howMany;



    // CTOR

    public CreateRecordBatch(SObject record, Integer howMany) {
        this.record = record;
        this.howMany = howMany;
    }



    public List<Integer> start(Database.BatchableContext context) {
        List<Integer> result = new List<Integer>();

        for(Integer i=0; i<howMany; i++) {
            result.add(true);
        }

        return result;
    }

    public void execute(Database.BatchableContext context, List<Integer> scope) {
        List<SObject> records = new List<SObject>();

        for (Integer iteration : scope) {
            //record.Name = record.Name.removeEnd('' + (iteration - 1)) + iteration;
            records.add( record );
        }

        insert records;
    }


    public void finish(Database.BatchableContext context) {
        // Nothing to do here
    }
}