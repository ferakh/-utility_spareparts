using { utility.spareparts as db } from '../db/schema';

service IntegrationService {
  entity IntegrationLogs as projection on db.IntegrationLogs;
  entity SupplierResponses as projection on db.SupplierResponses;

  type RequestStatusUpdateResult {
    request_ID         : UUID;
    status             : String;
    externalReference  : String;
    message            : String;
  }

  action updateRequestStatus(
    request_ID        : UUID,
    status            : String,
    message           : String,
    externalReference : String
  ) returns RequestStatusUpdateResult;

  action receiveSupplierAcknowledgement(
    request_ID                   : UUID,
    supplierName                 : String,
    acknowledgementStatus        : String,
    message                      : String,
    externalAcknowledgementId    : String
  ) returns SupplierResponses;
}
