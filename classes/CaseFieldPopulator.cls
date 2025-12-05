public without sharing class CaseFieldPopulator {
/*------------------------------------------------------------------------
    Author:        
    Company:       GITL
    Description:   Populate Area code(Default value) on Service Request from User's Area Code
    History
    29-08-2025   Initial Release
    ----------------------------------------------------------------------------*/
    public void populateServiceRequestDefaultsFromUserAreaCode(List<Case> newCaseRecords, Map<Id, Case> oldCaseRecordMap) {
        // Get the Record Type Id for "MHE Branch Query Register"
        Id mheBranchRtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(GlobalConstants.MHE_Branch_Query_Register).getRecordTypeId();
        
        // Exit if no new Case records
        if(newCaseRecords.isEmpty()) return;
        
        if(oldCaseRecordMap == null) {
            User runningUser = [
                SELECT Id, Area_Code__c 
                FROM User 
                WHERE Id = :UserInfo.getUserId() 
                LIMIT 1
            ];
            
            //Assign user area Code
            for(Case c : newCaseRecords) {
                 if(c.RecordTypeId == mheBranchRtId){
                    if(String.isBlank(c.Area_Code__c) && !String.isBlank(runningUser.Area_Code__c)) {
                    c.Area_Code__c = runningUser.Area_Code__c;
                	}
                }
            }
        }
    }
}