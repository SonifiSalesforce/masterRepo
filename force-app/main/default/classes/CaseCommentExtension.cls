public with sharing class CaseCommentExtension {
	

    private final Case caseRec;
    public CaseComment comment {get; set;}


    public CaseCommentExtension(ApexPages.StandardController controller) {

       caseRec = (Case)controller.getRecord();

        comment = new CaseComment();

        comment.parentid = caseRec.id;
        comment.ispublished = true;

    }

 

    public PageReference addComment() {

        insert comment;

        comment = new CaseComment();

        comment.parentid = caseRec.id;

        return null;

    }  

}//end case comment extension