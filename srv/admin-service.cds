using { utility.spareparts as db } from '../db/schema';

service AdminService {
  entity SpareRequests as projection on db.SpareRequests;
  entity Parts as projection on db.Parts;
  entity IntegrationLogs as projection on db.IntegrationLogs;
  entity SupplierResponses as projection on db.SupplierResponses;

  action retryFailedRequest(
    request_ID : UUID,
    message    : String
  ) returns SpareRequests;

  action markAsManualReview(
    request_ID : UUID,
    message    : String
  ) returns SpareRequests;
}
