/*  Author      : 
    Company     : GITL
    Description : Method to set amount value as per Area code
*/
public class ChargeTriggerHelper {
    public static void chargeAmountFieldPopulator(List<Charge__c> newCharges) {
        if (newCharges.isEmpty()) {
            return;
        }

        Set<Id> srIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<String> srTypes = new Set<String>();

        for (Charge__c ch : newCharges) {
            if (ch.Service_Request__c != null && ch.BU__c == 'Appliance' && ch.Account__c != null) {
                srIds.add(ch.Service_Request__c);
                accountIds.add(ch.Account__c);
            }
        }

        if (srIds.isEmpty() || accountIds.isEmpty()) {
            return;
        }

        // Query on Service Requests 
        Map<Id, Case> srMap = new Map<Id, Case>(
            [SELECT Id, AccountId,RecordType.Name, Service_Request_Type__c, SR_Closed_in_Hours__c,
            (SELECT Id, Franchisee__r.Owner.Area_Code__c FROM WorkOrders)
            FROM Case
            WHERE
            Id IN :srIds]
        );
    
        // Collect SR Types directly from srMap for Rate Master query
        for (Case sr : srMap.values()) {
            if (String.isNotBlank(sr.Service_Request_Type__c)) {
                srTypes.add(sr.Service_Request_Type__c);
            }
        }

        // Fetch Rate Master entries
        Map<String, Rate_Master_Entries__c> rateMasterMap = CreateChargesForPayable.getRateMasterEntriesMap(accountIds, 'APPL', srTypes, null);
        for (Charge__c ch : newCharges) {
            Case sr = srMap.get(ch.Service_Request__c);
            String areaCode;
    
            if (sr != null && sr.WorkOrders != null && !sr.WorkOrders.isEmpty()) {
                // Take first WorkOrder's Franchisee Owner Area Code
                areaCode = sr.WorkOrders[0].Franchisee__r.Owner.Area_Code__c;
            }
    
            if (areaCode == null || !('SY1'.equals(areaCode) || 'SY2'.equals(areaCode))) {
                continue;
            }
            
            // Parse SR Closed Hours safely
            Decimal srClosedHours = 0;
            if (String.isNotBlank(sr.SR_Closed_in_Hours__c)) {
                    List<String> parts = sr.SR_Closed_in_Hours__c.split(':');
                    if (!parts.isEmpty()) srClosedHours = Decimal.valueOf(parts[0]);
            }
			
            // Build Rate Master key
            String rateKey = String.join(new List<String>{
                (ch.Product_Category__c != null ? ch.Product_Category__c.toLowerCase() : ''),
                (ch.Product_Sub_Category__c !=null ? ch.Product_Sub_Category__c.toLowerCase() : ''),
                ch.Customer_Type__c,
                ch.Action_Code_Value__c,
                sr.Service_Request_Type__c,
                String.valueOf(ch.Account__c)
            }, ' ');

            Rate_Master_Entries__c rateEntry = rateMasterMap.get(rateKey);
            Decimal amount = ch.Amount__c;
            if (rateEntry != null) {
                if (srClosedHours > 168) {
                    amount = rateEntry.Fix_Rate_for_7_Days__c != null ? rateEntry.Fix_Rate_for_7_Days__c : amount;
                } else if (srClosedHours < 48) {
                    amount = rateEntry.Fix_Rate_for_48_hrs__c != null ? rateEntry.Fix_Rate_for_48_hrs__c : amount;
                }
            }

            ch.Amount__c = amount;
        }
    }
}